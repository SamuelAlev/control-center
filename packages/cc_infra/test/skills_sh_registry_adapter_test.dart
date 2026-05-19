import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_infra/src/skills/skills_sh_registry_adapter.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Regression coverage for the skills.sh search + resolve routes. Stubs the
/// transport so the test pins both the request shape (path + query params)
/// and the response mapping without dialing the network.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body) : status = 200;

  final String body;
  final int status;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    // `content-type: application/json` so Dio decodes the body into a Map.
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter whose handler can throw per-request, so we can exercise the
/// DioException → NetworkException mapping.
class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.error);
  final Object Function(RequestOptions) error;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw error(options);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(HttpClientAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://skills.sh/api'))
      ..httpClientAdapter = adapter;

void main() {
  group('SkillsShRegistryAdapter.search', () {
    test('hits /skills with q and limit', () async {
      final adapter = _RecordingAdapter('{"query":"dart","skills":[]}');
      final dio = _dio(adapter);

      await SkillsShRegistryAdapter(dio).search('dart', limit: 10);

      final req = adapter.lastRequest!;
      expect(req.path, '/skills', reason: 'skills.sh search route is /skills');
      expect(req.queryParameters['q'], 'dart');
      expect(req.queryParameters['limit'], 10);
    });

    test('parses the skills.sh `/api/skills` response shape', () async {
      // Field names the adapter maps: slug, name, author, install_count.
      final adapter = _RecordingAdapter(
        '{"query":"dart","skills":['
        '{"slug":"dart-add-unit-test",'
        '"name":"dart-add-unit-test",'
        '"author":"dart-lang/skills",'
        '"install_count":9374}]}',
      );
      final dio = _dio(adapter);

      final results = await SkillsShRegistryAdapter(dio).search('dart');

      expect(results, hasLength(1));
      final listing = results.single;
      expect(listing.slug, 'dart-add-unit-test');
      expect(listing.name, 'dart-add-unit-test');
      expect(listing.author, 'dart-lang/skills');
      expect(listing.installCount, 9374);
    });

    test('returns an empty list when the skills array is empty', () async {
      final adapter = _RecordingAdapter('{"query":"nope","skills":[]}');
      final dio = _dio(adapter);

      final results = await SkillsShRegistryAdapter(dio).search('nope');
      expect(results, isEmpty);
    });

    test('returns empty list when response is not a Map with a List', () async {
      // Top-level non-map (a bare array) should yield [].
      final adapter = _RecordingAdapter('["not", "a", "map"]');
      final dio = _dio(adapter);
      final results = await SkillsShRegistryAdapter(dio).search('x');
      expect(results, isEmpty);
    });

    test('returns empty list when skills field is not a List', () async {
      final adapter = _RecordingAdapter('{"skills":"not-a-list"}');
      final dio = _dio(adapter);
      final results = await SkillsShRegistryAdapter(dio).search('x');
      expect(results, isEmpty);
    });

    test('drops non-map entries in the skills array', () async {
      final adapter = _RecordingAdapter(
        '{"skills":["str", {"slug":"a","name":"a"}, 42, null]}',
      );
      final dio = _dio(adapter);
      final results = await SkillsShRegistryAdapter(dio).search('x');
      expect(results, hasLength(1));
      expect(results.single.slug, 'a');
    });

    test('falls back to name when slug is missing and vice versa', () async {
      final adapter = _RecordingAdapter(
        '{"skills":['
        '{"name":"only-name"},'
        '{"slug":"only-slug"}'
        ']}',
      );
      final dio = _dio(adapter);
      final results = await SkillsShRegistryAdapter(dio).search('x');
      expect(results, hasLength(2));
      expect(results[0].slug, 'only-name');
      expect(results[1].name, 'only-slug');
    });

    test('prefers author over publisher and maps verified flag', () async {
      final adapter = _RecordingAdapter(
        '{"skills":[{"slug":"x","name":"x",'
        '"publisher":"pub","author":"auth","verified":true,"version":"1.0",'
        '"description":"d"}]}',
      );
      final dio = _dio(adapter);
      final results = await SkillsShRegistryAdapter(dio).search('x');
      final l = results.single;
      // author is read before publisher.
      expect(l.author, 'auth');
      expect(l.verifiedPublisher, isTrue);
      expect(l.version, '1.0');
      expect(l.description, 'd');
    });

    test('falls back to publisher when author missing', () async {
      final adapter = _RecordingAdapter(
        '{"skills":[{"slug":"x","name":"x","publisher":"pub"}]}',
      );
      final dio = _dio(adapter);
      final results = await SkillsShRegistryAdapter(dio).search('x');
      expect(results.single.author, 'pub');
    });

    test('maps a DioException to NetworkException', () async {
      final dio = _dio(
        _ThrowingAdapter(
          (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 500,
              data: 'boom',
            ),
          ),
        ),
      );
      await expectLater(
        SkillsShRegistryAdapter(dio).search('x'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('rethrows cancel exceptions unchanged', () async {
      final dio = _dio(
        _ThrowingAdapter(
          (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          ),
        ),
      );
      await expectLater(
        SkillsShRegistryAdapter(dio).search('x'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('SkillsShRegistryAdapter.resolve', () {
    test('hits /skills/{slug} and parses the files map', () async {
      final adapter = _RecordingAdapter(
        '{"slug":"x","version":"1.2.3","publisher":"p","files":{'
        '"SKILL.md":"# X","refs.md":"- a"},'
        '"verified":true}',
      );
      final dio = _dio(adapter);

      final resolved = await SkillsShRegistryAdapter(dio).resolve('x');

      expect(adapter.lastRequest!.path, '/skills/x');
      expect(resolved.slug, 'x');
      expect(resolved.version, '1.2.3');
      expect(resolved.publisher, 'p');
      expect(resolved.verifiedPublisher, isTrue);
      expect(resolved.files['SKILL.md'], '# X');
      expect(resolved.files['refs.md'], '- a');
    });

    test('passes version query parameter when provided', () async {
      final adapter = _RecordingAdapter('{"files":{"SKILL.md":"x"}}');
      final dio = _dio(adapter);

      await SkillsShRegistryAdapter(dio).resolve('x', version: '2.0.0');

      expect(adapter.lastRequest!.queryParameters['version'], '2.0.0');
    });

    test('omits version query parameter when null', () async {
      final adapter = _RecordingAdapter('{"files":{"SKILL.md":"x"}}');
      final dio = _dio(adapter);

      await SkillsShRegistryAdapter(dio).resolve('x');

      expect(
        adapter.lastRequest!.queryParameters.containsKey('version'),
        isFalse,
      );
    });

    test('uses content field as SKILL.md when files absent', () async {
      final adapter = _RecordingAdapter('{"content":"# single file body"}');
      final dio = _dio(adapter);

      final resolved = await SkillsShRegistryAdapter(dio).resolve('x');

      expect(resolved.files, {'SKILL.md': '# single file body'});
    });

    test('falls back to author when publisher missing', () async {
      final adapter = _RecordingAdapter(
        '{"author":"auth","files":{"SKILL.md":"x"}}',
      );
      final dio = _dio(adapter);

      final resolved = await SkillsShRegistryAdapter(dio).resolve('x');

      expect(resolved.publisher, 'auth');
    });

    test('uses passed version when response omits it', () async {
      final adapter = _RecordingAdapter('{"files":{"SKILL.md":"x"}}');
      final dio = _dio(adapter);

      final resolved = await SkillsShRegistryAdapter(
        dio,
      ).resolve('x', version: '9.9');

      expect(resolved.version, '9.9');
    });

    test('drops non-string file values', () async {
      final adapter = _RecordingAdapter(
        '{"files":{"SKILL.md":"keep","binary":42,"refs":"ok"}}',
      );
      final dio = _dio(adapter);

      final resolved = await SkillsShRegistryAdapter(dio).resolve('x');

      expect(resolved.files, {'SKILL.md': 'keep', 'refs': 'ok'});
    });

    test(
      'throws NetworkException (bad shape) when response is not a Map',
      () async {
        final adapter = _RecordingAdapter('["not", "a", "map"]');
        final dio = _dio(adapter);

        await expectLater(
          SkillsShRegistryAdapter(dio).resolve('x'),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test('throws NetworkException (empty bundle) when no content', () async {
      final adapter = _RecordingAdapter('{"slug":"x"}');
      final dio = _dio(adapter);

      await expectLater(
        SkillsShRegistryAdapter(dio).resolve('x'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('maps a DioException to NetworkException', () async {
      final dio = _dio(
        _ThrowingAdapter(
          (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 404,
              data: 'missing',
            ),
          ),
        ),
      );
      await expectLater(
        SkillsShRegistryAdapter(dio).resolve('x'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('rethrows cancel exceptions unchanged', () async {
      final dio = _dio(
        _ThrowingAdapter(
          (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          ),
        ),
      );
      await expectLater(
        SkillsShRegistryAdapter(dio).resolve('x'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
