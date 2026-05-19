import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_infra/cc_infra.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// [SlackApiClient]: the wire shape of the app-configuration calls, and how a
/// refusal is read back.
///
/// Both were bugs in production. Slack declares `manifest` as a JSON *string*,
/// so posting the object was refused before the schema was consulted; and the
/// reason for that refusal lives in `response_metadata`, which was not read, so
/// the user saw "Slack refused the app manifest." with nothing to act on.
void main() {
  late _RecordingAdapter adapter;
  late SlackApiClient client;

  setUp(() {
    adapter = _RecordingAdapter();
    client = SlackApiClient(
      dio: Dio()..httpClientAdapter = adapter,
      botToken: '',
    );
  });

  const manifest = {
    'display_information': {'name': 'Control Center'},
    'settings': {'socket_mode_enabled': true},
  };

  group('manifest argument encoding', () {
    test('create sends the manifest as a JSON string', () async {
      adapter.nextJson({'ok': true, 'app_id': 'A1'});

      await client.createApp(
        configAccessToken: 'xoxe.xoxp-1',
        manifest: manifest,
      );

      final sent = adapter.jsonBody(0);
      expect(sent['manifest'], isA<String>());
      expect(jsonDecode(sent['manifest'] as String), manifest);
    });

    test('validate and update send it the same way', () async {
      adapter
        ..nextJson({'ok': true, 'errors': const []})
        ..nextJson({'ok': true, 'permissions_updated': true});

      await client.validateManifest(
        configAccessToken: 'xoxe.xoxp-1',
        manifest: manifest,
        appId: 'A1',
      );
      await client.updateManifest(
        configAccessToken: 'xoxe.xoxp-1',
        appId: 'A1',
        manifest: manifest,
      );

      for (var i = 0; i < adapter.bodies.length; i++) {
        final body = adapter.jsonBody(i);
        expect(body['manifest'], isA<String>());
        expect(jsonDecode(body['manifest'] as String), manifest);
        expect(body['app_id'], 'A1');
      }
    });

    test(
      'the configuration token authorizes the call, not the bot token',
      () async {
        adapter.nextJson({'ok': true, 'app_id': 'A1'});

        await client.createApp(
          configAccessToken: 'xoxe.xoxp-1',
          manifest: manifest,
        );

        expect(
          adapter.requests.single.headers['Authorization'],
          'Bearer xoxe.xoxp-1',
        );
      },
    );
  });

  group('token rotation', () {
    test(
      'posts form-encoded, because it carries no Authorization header',
      () async {
        adapter.nextJson({
          'ok': true,
          'token': 'xoxe.xoxp-new',
          'refresh_token': 'xoxe-2',
        });

        final rotated = await client.rotateConfigToken('xoxe-1-abc');

        // Slack parses a JSON body only for calls authenticated through the
        // header; as JSON this one arrives with no arguments and is refused for
        // the very field it is carrying.
        expect(
          adapter.requests.single.headers.containsKey('Authorization'),
          isFalse,
        );
        expect(
          adapter.requests.single.contentType,
          Headers.formUrlEncodedContentType,
        );
        expect(adapter.bodies.single, contains('refresh_token=xoxe-1-abc'));
        expect(rotated.accessToken, 'xoxe.xoxp-new');
        expect(rotated.refreshToken, 'xoxe-2');
      },
    );
  });

  group('streaming and blocks', () {
    // These calls ride the bot token, and Slack only reads a JSON body from a
    // header-authenticated call — so the payloads under test here are JSON.
    late SlackApiClient bot;

    setUp(
      () => bot = SlackApiClient(
        dio: Dio()..httpClientAdapter = adapter,
        botToken: 'xoxb-1',
      ),
    );

    test('a stream can be opened in a task display mode', () async {
      adapter.nextJson({'ok': true, 'ts': '950.1', 'channel': 'C1'});

      await bot.startStream(
        channel: 'C1',
        threadTs: '1.1',
        taskDisplayMode: 'timeline',
      );

      final sent = adapter.jsonBody(0);
      expect(sent['task_display_mode'], 'timeline');
      expect(sent['thread_ts'], '1.1');
    });

    test('a stream without a display mode does not mention one', () async {
      adapter.nextJson({'ok': true, 'ts': '950.1', 'channel': 'C1'});

      await bot.startStream(channel: 'C1', threadTs: '1.1');

      // Absent, not null: an unset field must not become an argument Slack has
      // to interpret.
      expect(adapter.jsonBody(0).containsKey('task_display_mode'), isFalse);
    });

    test('typed chunks and plain text travel on separate calls', () async {
      const handle = SlackStreamHandle(channel: 'C1', ts: '950.1');
      adapter
        ..nextJson({'ok': true})
        ..nextJson({'ok': true})
        ..nextJson({'ok': true});

      await bot.appendStream(handle: handle, markdownText: '**bold**');
      await bot.appendStream(
        handle: handle,
        chunks: [
          {'type': 'task_update', 'id': 't1', 'title': 'Thinking…'},
        ],
      );
      await bot.appendStream(
        handle: handle,
        chunks: [
          {'type': 'markdown_text', 'text': 'The answer.'},
        ],
      );

      final text = adapter.jsonBody(0);
      expect(text['markdown_text'], '**bold**');
      expect(text.containsKey('chunks'), isFalse);
      final chunks = adapter.jsonBody(1);
      expect(chunks.containsKey('markdown_text'), isFalse);
      expect((chunks['chunks'] as List).single, {
        'type': 'task_update',
        'id': 't1',
        'title': 'Thinking…',
      });
      final answer = adapter.jsonBody(2);
      expect(answer.containsKey('markdown_text'), isFalse);
      expect((answer['chunks'] as List).single, {
        'type': 'markdown_text',
        'text': 'The answer.',
      });
    });

    test('markdown_text and chunks together are refused before Slack', () {
      const handle = SlackStreamHandle(channel: 'C1', ts: '950.1');
      expect(
        () => bot.appendStream(
          handle: handle,
          markdownText: 'The answer.',
          chunks: [
            {'type': 'plan_update', 'title': 'Yo wassup?'},
          ],
        ),
        throwsArgumentError,
      );
    });

    test('blocks ride alongside the notification text', () async {
      adapter.nextJson({'ok': true, 'ts': '900.1'});

      await bot.postMessage(
        channel: 'C1',
        text: 'Filed CC-1',
        blocks: [
          {'type': 'task_card', 'task_id': 't1'},
        ],
      );

      final sent = adapter.jsonBody(0);
      // The text is what a push notification reads, so it survives blocks.
      expect(sent['text'], 'Filed CC-1');
      expect((sent['blocks'] as List).single, {
        'type': 'task_card',
        'task_id': 't1',
      });
    });

    test('a command reply can carry blocks', () async {
      adapter.nextJson({'ok': true});

      await bot.respondToCommand(
        'https://hooks.slack.test/commands/Tr1',
        text: 'Filed CC-1',
        blocks: [
          {'type': 'task_card', 'task_id': 't1'},
        ],
      );

      final sent = adapter.jsonBody(0);
      expect(sent['response_type'], 'ephemeral');
      expect(sent['blocks'] as List, hasLength(1));
    });
  });

  group('refusals', () {
    test('reads the errors array the schema check returns', () async {
      adapter.nextJson({
        'ok': false,
        'error': 'invalid_manifest',
        'errors': [
          {
            'message': 'Interactivity requires Socket Mode enabled',
            'pointer': '/settings/interactivity',
          },
          {'message': 'something else'},
        ],
      });

      await expectLater(
        client.createApp(configAccessToken: 'xoxe.xoxp-1', manifest: manifest),
        throwsA(
          isA<SlackApiException>().having((e) => e.details, 'details', const [
            '/settings/interactivity: Interactivity requires Socket Mode enabled',
            'something else',
          ]),
        ),
      );
    });

    test('reads response_metadata, the only place invalid_arguments explains '
        'itself', () async {
      adapter.nextJson({
        'ok': false,
        'error': 'invalid_arguments',
        'response_metadata': {
          'messages': ['[ERROR] must be a string [json-pointer:/manifest]'],
        },
      });

      await expectLater(
        client.createApp(configAccessToken: 'xoxe.xoxp-1', manifest: manifest),
        throwsA(
          isA<SlackApiException>().having((e) => e.details, 'details', [
            '[ERROR] must be a string [json-pointer:/manifest]',
          ]),
        ),
      );
    });
  });
}

/// Records what was actually put on the wire, which is the point of this suite.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  /// Request bodies verbatim — the encoding is what is under test, so they are
  /// not decoded on the way in.
  final List<String> bodies = [];
  final List<Object> _queued = [];

  void nextJson(Object body) => _queued.add(body);

  Map<String, dynamic> jsonBody(int index) =>
      Map<String, dynamic>.from(jsonDecode(bodies[index]) as Map);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final raw = requestStream == null
        ? const <int>[]
        : await requestStream.expand((chunk) => chunk).toList();
    bodies.add(raw.isEmpty ? '' : utf8.decode(raw));
    final body = _queued.isEmpty ? const {'ok': true} : _queued.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: const {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
