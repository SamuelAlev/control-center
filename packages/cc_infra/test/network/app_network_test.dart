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
