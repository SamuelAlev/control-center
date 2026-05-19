import 'dart:typed_data';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._type);
  final DioExceptionType _type;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(requestOptions: options, type: _type);
  }

  @override
  void close({bool force = false}) {}
}

/// Answers every request with a fixed status and body. `retry-after: 0` keeps
/// `RetryInterceptor`'s attempts instant — the test asserts on what is LOGGED
/// across all of them, not on how long they take.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this._status, this._body);
  final int _status;
  final String _body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    _body,
    _status,
    headers: {
      'retry-after': ['0'],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  final records = <(CcInfraLogLevel, String)>[];

  setUp(() {
    records.clear();
    CcInfraLog.sink = (level, message, [error, stackTrace]) {
      records.add((level, message));
    };
  });

  tearDown(() {
    CcInfraLog.sink = null;
    CcInfraLog.level = CcInfraLogLevel.info;
  });

  group('createDio error logging', () {
    test('a cancelled request is never logged as an error', () async {
      CcInfraLog.level = CcInfraLogLevel.debug;
      final dio = createDio()
        ..httpClientAdapter = _StubAdapter(DioExceptionType.cancel);

      await expectLater(
        dio.get<void>('https://example.com/x'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );

      // Cancellation is a subscriber standing down, not a failure: nothing
      // at warning/error, only the debug-tier line keeping the "→" request
      // log symmetric.
      expect(
        records.where(
          (r) =>
              r.$1 == CcInfraLogLevel.warning || r.$1 == CcInfraLogLevel.error,
        ),
        isEmpty,
      );
      expect(
        records.where(
          (r) => r.$1 == CcInfraLogLevel.debug && r.$2.contains('cancelled'),
        ),
        hasLength(1),
      );
    });

    test('a cancellation is silent at the default (info) level', () async {
      final dio = createDio()
        ..httpClientAdapter = _StubAdapter(DioExceptionType.cancel);

      await expectLater(
        dio.get<void>('https://example.com/x'),
        throwsA(isA<DioException>()),
      );

      expect(records, isEmpty);
    });

    test(
      'a status the caller declared expected is not logged as an error',
      () async {
        CcInfraLog.level = CcInfraLogLevel.debug;
        final dio = createDio()
          ..httpClientAdapter = _StatusAdapter(
            429,
            '{"code":"resource_exhausted"}',
          );

        await expectLater(
          dio.get<void>(
            'https://example.com/usages',
            options: Options(extra: expectStatuses(const [429])),
          ),
          throwsA(isA<DioException>()),
        );

        // Kimi answers a spent plan with a 429 the caller reads as state, so the
        // lane where real failures land stays clean — the exchange is still
        // visible at debug.
        expect(
          records.where(
            (r) =>
                r.$1 == CcInfraLogLevel.warning ||
                r.$1 == CcInfraLogLevel.error,
          ),
          isEmpty,
        );
        expect(
          records.where(
            (r) => r.$1 == CcInfraLogLevel.debug && r.$2.contains('HTTP 429'),
          ),
          isNotEmpty,
        );
      },
    );

    test('an UNdeclared status is still logged as an error', () async {
      final dio = createDio()..httpClientAdapter = _StatusAdapter(500, 'boom');

      await expectLater(
        // 429 declared, 500 not: the marker is a per-status opt-out, not a
        // blanket "never log this request".
        dio.get<void>(
          'https://example.com/usages',
          options: Options(extra: expectStatuses(const [429])),
        ),
        throwsA(isA<DioException>()),
      );

      expect(records.where((r) => r.$1 == CcInfraLogLevel.error), isNotEmpty);
    });

    test('a real network failure is still logged at error level', () async {
      final dio = createDio()
        ..httpClientAdapter = _StubAdapter(DioExceptionType.connectionError);

      await expectLater(
        dio.get<void>('https://example.com/x'),
        throwsA(isA<DioException>()),
      );

      expect(records.where((r) => r.$1 == CcInfraLogLevel.error), hasLength(1));
    });
  });
}
