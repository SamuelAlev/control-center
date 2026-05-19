import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// [SlackManifestService]: manifest composition and the rotation contract.
///
/// The two things worth pinning are the two that are expensive to get wrong: a
/// manifest that drops what the user configured in Slack and a rotation whose
/// replacement token is not persisted (which permanently un-manages the app).
void main() {
  group('buildManifest', () {
    const profile = _profile;

    test('asserts Socket Mode, the scopes and the bot events', () {
      final manifest = SlackManifestService.buildManifest(profile: profile);
      final settings = manifest['settings'] as Map<String, dynamic>;
      expect(settings['socket_mode_enabled'], isTrue);
      final events =
          (settings['event_subscriptions']
                  as Map<String, dynamic>)['bot_events']
              as List;
      expect(events, containsAll(SlackManifestService.requiredBotEvents));
      final scopes =
          ((manifest['oauth_config'] as Map<String, dynamic>)['scopes']
                  as Map<String, dynamic>)['bot']
              as List;
      expect(scopes, containsAll(SlackManifestService.requiredScopes));
      final features = manifest['features'] as Map<String, dynamic>;
      expect(
        (features['agent_view'] as Map<String, dynamic>)['agent_description'],
        'Mention me.',
      );
      // The agent experience is the Messages tab, so a DM-able bot needs it.
      expect(
        (features['app_home'] as Map<String, dynamic>)['messages_tab_enabled'],
        isTrue,
      );
    });

    test('keeps what the user configured in Slack', () {
      final manifest = SlackManifestService.buildManifest(
        profile: profile,
        base: {
          'display_information': {
            'name': 'Old name',
            'background_color': '#101010',
          },
          'features': {
            'slash_commands': [
              {'command': '/standup', 'description': 'Run standup'},
            ],
          },
          'oauth_config': {
            'scopes': {
              'bot': ['reactions:write'],
            },
          },
          'outgoing_domains': ['example.com'],
        },
      );
      // Unmodelled fields survive verbatim.
      expect(manifest['outgoing_domains'], ['example.com']);
      expect(
        (manifest['display_information'] as Map)['background_color'],
        '#101010',
      );
      // A scope somebody added is never subtracted.
      final scopes =
          ((manifest['oauth_config'] as Map)['scopes'] as Map)['bot'] as List;
      expect(scopes, contains('reactions:write'));
      expect(scopes, contains('chat:write'));
      // Someone else's slash command stays; ours is (re)written.
      final commands =
          (manifest['features'] as Map)['slash_commands'] as List<dynamic>;
      expect(
        commands.map((c) => (c as Map)['command']),
        containsAll(['/standup', '/cc']),
      );
    });

    test('renaming the command replaces ours instead of adding a second', () {
      final base = SlackManifestService.buildManifest(profile: profile);
      final renamed = SlackManifestService.buildManifest(
        profile: profile.copyWith(command: 'ops'),
        base: base,
      );
      final commands = (renamed['features'] as Map)['slash_commands'] as List;
      expect(commands.map((c) => (c as Map)['command']), ['/ops']);
    });

    test('an app on the legacy assistant_view is not migrated behind the '
        'user’s back', () {
      final manifest = SlackManifestService.buildManifest(
        profile: profile.copyWith(agentDescription: 'Reworded.'),
        base: {
          'features': {
            'assistant_view': {'assistant_description': 'Old wording.'},
          },
        },
      );
      final features = manifest['features'] as Map<String, dynamic>;
      // Switching to agent_view is irreversible in Slack, so a description edit
      // must not perform it.
      expect(features.containsKey('agent_view'), isFalse);
      expect(
        (features['assistant_view'] as Map)['assistant_description'],
        'Reworded.',
      );
    });

    test('drops the request urls Socket Mode cannot coexist with', () {
      final manifest = SlackManifestService.buildManifest(
        profile: profile,
        base: {
          'settings': {
            'event_subscriptions': {
              'request_url': 'https://example.com/slack/events',
            },
            'interactivity': {
              'is_enabled': true,
              'request_url': 'https://example.com/slack/actions',
            },
          },
        },
      );
      final settings = manifest['settings'] as Map<String, dynamic>;
      expect(
        (settings['event_subscriptions'] as Map).containsKey('request_url'),
        isFalse,
      );
      expect(
        (settings['interactivity'] as Map).containsKey('request_url'),
        isFalse,
      );
    });
  });

  group('manifestCreateUrl', () {
    test('carries the same manifest createApp would send', () {
      final url = Uri.parse(SlackManifestService.manifestCreateUrl(_profile));

      expect(url.origin + url.path, SlackManifestService.appsConsoleUrl);
      expect(url.queryParameters['new_app'], '1');
      // The deep link is the credential-free path to the identical app, so the
      // manifest must not be a reduced version of the one the token path sends.
      expect(
        jsonDecode(url.queryParameters['manifest_json']!),
        SlackManifestService.buildManifest(profile: _profile),
      );
    });

    test('the pre-filled app is a Socket Mode app', () {
      final url = Uri.parse(SlackManifestService.manifestCreateUrl(_profile));
      final manifest =
          jsonDecode(url.queryParameters['manifest_json']!)
              as Map<String, dynamic>;
      final settings = manifest['settings'] as Map<String, dynamic>;

      // Without this the bridge has nothing to connect to and the user would
      // have to fix it in Slack by hand — the one thing the link exists to avoid.
      expect(settings['socket_mode_enabled'], isTrue);
      expect(
        (settings['event_subscriptions'] as Map)['bot_events'],
        containsAll(SlackManifestService.requiredBotEvents),
      );
    });

    test('percent-encodes so a space is not a plus', () {
      final url = SlackManifestService.manifestCreateUrl(
        _profile.copyWith(appName: 'Team bot'),
      );

      // Slack reads this parameter from a browser navigation, which does not
      // form-decode: a `+` would reach it literally and land inside the name.
      expect(url, contains('Team%20bot'));
      expect(url, isNot(contains('+')));
      final manifest =
          jsonDecode(Uri.parse(url).queryParameters['manifest_json']!)
              as Map<String, dynamic>;
      expect((manifest['display_information'] as Map)['name'], 'Team bot');
    });

    test('refuses a profile Slack would reject at the far end', () {
      // The user would otherwise land on a Slack error page with no idea which
      // field was wrong.
      expect(
        () => SlackManifestService.manifestCreateUrl(
          _profile.copyWith(appName: 'x' * 36),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('profileFromManifest', () {
    test('reads a hand-made app tolerantly', () {
      final profile = SlackManifestService.profileFromManifest({
        'display_information': {'name': 'My bot', 'description': 'Does things'},
        'features': {
          'bot_user': {'display_name': 'mybot'},
          'slash_commands': [
            {'command': '/team'},
          ],
        },
      });
      expect(profile.appName, 'My bot');
      expect(profile.botDisplayName, 'mybot');
      expect(profile.command, 'team');
      // No agent view in the manifest means the DM experience is off.
      expect(profile.agentEnabled, isFalse);
    });

    test('an empty manifest yields a usable profile instead of throwing', () {
      final profile = SlackManifestService.profileFromManifest(const {});
      expect(profile.command, 'cc');
      expect(profile.agentEnabled, isFalse);
    });
  });

  group('token rotation', () {
    test(
      'persists the new refresh token before using the access token',
      () async {
        final adapter = _SlackStubAdapter()
          ..reply('tooling.tokens.rotate', {
            'token': 'xoxe.xoxp-access',
            'refresh_token': 'xoxe-2',
          })
          ..reply('apps.manifest.validate', const {})
          ..reply('apps.manifest.create', {'app_id': 'A1'});
        final store = _TokenStore('xoxe-1');
        final service = _service(adapter, store);

        final created = await service.createApp(_profile);

        expect(created.appId, 'A1');
        // Slack invalidated `xoxe-1` when it answered, so the replacement has to
        // be stored — and stored before the manifest calls ride on it.
        expect(store.token, 'xoxe-2');
        expect(store.writes, ['xoxe-2']);
        expect(
          adapter.calls.indexOf('tooling.tokens.rotate'),
          lessThan(adapter.calls.indexOf('apps.manifest.create')),
        );
        expect(created.configRefreshToken, 'xoxe-2');
      },
    );

    test(
      'hands off to the app settings page, not Slack’s authorize url',
      () async {
        final adapter = _SlackStubAdapter()
          ..reply('tooling.tokens.rotate', {
            'token': 'xoxe.xoxp-access',
            'refresh_token': 'xoxe-2',
          })
          ..reply('apps.manifest.validate', const {})
          ..reply('apps.manifest.create', {
            'app_id': 'A1',
            'oauth_authorize_url':
                'https://slack.com/oauth/v2/authorize?client_id=1',
          });

        final created = await _service(
          adapter,
          _TokenStore('xoxe-1'),
        ).createApp(_profile);

        // Slack's own url is the distribution flow and dead-ends on a
        // `redirect_uri` a Socket Mode app cannot declare.
        expect(
          created.installPageUrl,
          'https://api.slack.com/apps/A1/install-on-team',
        );
      },
    );

    test('a failed write fails the operation', () async {
      final adapter = _SlackStubAdapter()
        ..reply('tooling.tokens.rotate', {
          'token': 'xoxe.xoxp-access',
          'refresh_token': 'xoxe-2',
        });
      final store = _TokenStore('xoxe-1', failWrites: true);
      final service = _service(adapter, store);

      // Losing the replacement token un-manages the app forever, so this must
      // never be swallowed as "the manifest call worked".
      await expectLater(
        service.createApp(_profile),
        throwsA(isA<StateError>()),
      );
      expect(adapter.calls, ['tooling.tokens.rotate']);
    });

    test(
      'a missing token is an actionable refusal, not a Slack round trip',
      () async {
        final adapter = _SlackStubAdapter();
        final service = _service(adapter, _TokenStore(null));

        await expectLater(
          service.profile('A1'),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              contains('app configuration token'),
            ),
          ),
        );
        expect(adapter.calls, isEmpty);
      },
    );

    test('Slack’s manifest complaints reach the caller', () async {
      final adapter = _SlackStubAdapter()
        ..reply('tooling.tokens.rotate', {
          'token': 'xoxe.xoxp-access',
          'refresh_token': 'xoxe-2',
        })
        ..reply('apps.manifest.export', {'manifest': const {}})
        ..reply('apps.manifest.validate', {
          'ok': false,
          'error': 'invalid_manifest',
          'errors': [
            {
              'message': 'is too long',
              'pointer': '/features/bot_user/display_name',
            },
          ],
        });
      final service = _service(adapter, _TokenStore('xoxe-1'));

      await expectLater(
        service.updateProfile(appId: 'A1', profile: _profile),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            allOf(contains('display_name'), contains('is too long')),
          ),
        ),
      );
    });

    test(
      'a rotation Slack refuses is not reported as a manifest problem',
      () async {
        final adapter = _SlackStubAdapter()
          ..reply('tooling.tokens.rotate', {
            'ok': false,
            'error': 'invalid_arguments',
            'response_metadata': {
              'messages': ['[ERROR] missing required field: refresh_token'],
            },
          });
        final service = _service(adapter, _TokenStore('xoxe-1'));

        // The dialog sends people to the screen the message names, so a token
        // call that failed must not be described as the manifest being wrong.
        await expectLater(
          service.createApp(_profile),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('tooling.tokens.rotate'),
                contains('refresh_token'),
                isNot(contains('manifest')),
              ),
            ),
          ),
        );
      },
    );

    test('an argument refusal Slack explains only in response_metadata reaches '
        'the caller too', () async {
      final adapter = _SlackStubAdapter()
        ..reply('tooling.tokens.rotate', {
          'token': 'xoxe.xoxp-access',
          'refresh_token': 'xoxe-2',
        })
        ..reply('apps.manifest.validate', {
          'ok': false,
          'error': 'invalid_arguments',
          'response_metadata': {
            'messages': ['[ERROR] must be a string [json-pointer:/manifest]'],
          },
        });
      final service = _service(adapter, _TokenStore('xoxe-1'));

      // `invalid_arguments` on its own reads as "your manifest is wrong" and
      // is not: the actionable half is the one Slack buries.
      await expectLater(
        service.createApp(_profile),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('json-pointer:/manifest'),
          ),
        ),
      );
    });
  });

  group('ChatBotProfile', () {
    test('normalizes a command the way Slack would accept it', () {
      expect(ChatBotProfile.normalizeCommand('/CC Ops'), 'ccops');
      expect(ChatBotProfile.normalizeCommand('  '), 'cc');
      expect(ChatBotProfile.normalizeCommand('a' * 40).length, 32);
    });

    test('validates the lengths Slack enforces', () {
      expect(
        () => _profile.copyWith(appName: 'x' * 36).validate(),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile.copyWith(botDisplayName: '').validate(),
        throwsA(isA<ValidationException>()),
      );
      expect(_profile.validate, returnsNormally);
    });
  });
}

const _profile = ChatBotProfile(
  appName: 'Control Center',
  botDisplayName: 'control-center',
  description: 'Agents from Slack.',
  agentDescription: 'Mention me.',
  command: 'cc',
);

SlackManifestService _service(_SlackStubAdapter adapter, _TokenStore store) =>
    SlackManifestService(
      api: SlackApiClient(
        dio: Dio()..httpClientAdapter = adapter,
        botToken: '',
      ),
      readRefreshToken: store.read,
      writeRefreshToken: store.write,
    );

/// The persistence seam, with a read-back guarantee (the real one writes the
/// workspace's credentials file) and an optional write failure.
class _TokenStore {
  _TokenStore(this.token, {this.failWrites = false});

  String? token;
  final bool failWrites;
  final List<String> writes = [];

  Future<String?> read() async => token;

  Future<void> write(String value) async {
    if (failWrites) {
      throw StateError('disk full');
    }
    writes.add(value);
    token = value;
  }
}

/// Answers Slack Web API calls from a per-method script, recording the order.
class _SlackStubAdapter implements HttpClientAdapter {
  final List<String> calls = [];
  final Map<String, Map<String, dynamic>> _replies = {};

  void reply(String method, Map<String, dynamic> body) =>
      _replies[method] = body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final method = options.path.split('/').last;
    calls.add(method);
    final scripted = _replies[method] ?? const <String, dynamic>{};
    return ResponseBody.fromString(
      jsonEncode({'ok': true, ...scripted}),
      200,
      headers: const {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
