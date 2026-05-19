import 'package:cc_domain/features/github_status/domain/entities/github_service_status.dart';
import 'package:cc_infra/src/git/github_status_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake Dio — stubs getUri with configurable response/error.
// ---------------------------------------------------------------------------
class _FakeDio extends Fake implements Dio {
  Object? _nextResult;

  void stubResponse(Response<Map<String, dynamic>> response) {
    _nextResult = response;
  }

  void stubError(Object error) {
    _nextResult = error;
  }

  @override
  Future<Response<T>> getUri<T>(
    Uri uri, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final result = _nextResult;
    if (result is Exception) {
      throw result;
    }
    final r = (result as Response?) ??
        Response(requestOptions: RequestOptions(path: ''));
    return r as Response<T>;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Map<String, dynamic> _baseResponse({
  String? indicator = 'none',
  String description = 'All Systems Operational',
  List<dynamic>? components,
  List<dynamic>? incidents,
}) {
  final statusBlock = <String, dynamic>{
    'description': description,
  };
  if (indicator != null) {
    statusBlock['indicator'] = indicator;
  }
  return {
    'status': statusBlock,
    'components': ?components,
    'incidents': ?incidents,
  };
}

Map<String, dynamic> _component({
  String id = 'c1',
  String name = 'Git Operations',
  String? status = 'operational',
  int position = 1,
}) {
  return {
    'id': id,
    'name': name,
    'position': position,
    'status': ?status,
  };
}

Map<String, dynamic> _incident({
  String id = 'i1',
  String name = 'Degraded API',
  String status = 'investigating',
  String shortlink = 'https://githubstatus.com/incidents/1',
  String createdAt = '2024-06-01T12:00:00Z',
  String updatedAt = '2024-06-01T14:00:00Z',
}) {
  return {
    'id': id,
    'name': name,
    'status': status,
    'shortlink': shortlink,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late _FakeDio dio;
  late GitHubStatusService service;

  Response<Map<String, dynamic>> response(Map<String, dynamic> data) {
    return Response<Map<String, dynamic>>(
      data: data,
      requestOptions: RequestOptions(path: ''),
    );
  }

  setUp(() {
    dio = _FakeDio();
    service = GitHubStatusService(dio);
  });

  // ── Status polling ────────────────────────────────────────────────────

  group('fetch (status polling)', () {
    test('returns parsed status from full API response', () async {
      dio.stubResponse(response(_baseResponse(
        indicator: 'none',
        description: 'All Systems Operational',
        components: [
          _component(id: 'c1', name: 'Git Operations', position: 1),
          _component(id: 'c2', name: 'API Requests', position: 2),
        ],
        incidents: [
          _incident(id: 'inc1', name: 'Slow API'),
        ],
      )));

      final result = await service.fetch();

      expect(result.indicator, GitHubStatusIndicator.none);
      expect(result.description, 'All Systems Operational');
      expect(result.components, hasLength(2));
      expect(result.components[0].id, 'c1');
      expect(result.components[1].id, 'c2');
      expect(result.incidents, hasLength(1));
      expect(result.incidents[0].id, 'inc1');
      expect(result.incidents[0].name, 'Slow API');
      expect(result.incidents[0].status, 'investigating');
      expect(result.incidents[0].shortlink, 'https://githubstatus.com/incidents/1');
      expect(result.incidents[0].createdAt, DateTime.utc(2024, 6, 1, 12, 0, 0));
      expect(result.incidents[0].updatedAt, DateTime.utc(2024, 6, 1, 14, 0, 0));
    });

    test('returns minimal status when response has no components or incidents',
        () async {
      dio.stubResponse(response(_baseResponse(
        indicator: 'none',
        description: 'OK',
      )));

      final result = await service.fetch();

      expect(result.indicator, GitHubStatusIndicator.none);
      expect(result.description, 'OK');
      expect(result.components, isEmpty);
      expect(result.incidents, isEmpty);
    });

    test('handles null response data', () async {
      dio.stubResponse(Response<Map<String, dynamic>>(
        data: null,
        requestOptions: RequestOptions(path: ''),
      ));

      final result = await service.fetch();

      expect(result.indicator, GitHubStatusIndicator.unknown);
      expect(result.description, 'Unknown status');
      expect(result.components, isEmpty);
      expect(result.incidents, isEmpty);
    });

    test('handles missing status block', () async {
      dio.stubResponse(response(<String, dynamic>{}));

      final result = await service.fetch();

      expect(result.indicator, GitHubStatusIndicator.unknown);
      expect(result.description, 'Unknown status');
    });
  });

  // ── Parse responses ───────────────────────────────────────────────────

  group('parse responses', () {
    group('indicator parsing', () {
      for (final entry in <MapEntry<String, GitHubStatusIndicator>>[
        const MapEntry('none', GitHubStatusIndicator.none),
        const MapEntry('minor', GitHubStatusIndicator.minor),
        const MapEntry('major', GitHubStatusIndicator.major),
        const MapEntry('critical', GitHubStatusIndicator.critical),
        const MapEntry('maintenance', GitHubStatusIndicator.maintenance),
      ]) {
        test('maps "$entry.key" → ${entry.value}', () async {
          dio.stubResponse(response(_baseResponse(
            indicator: entry.key,
            description: '',
          )));

          final result = await service.fetch();

          expect(result.indicator, entry.value);
        });
      }
    });

    test('unknown indicator string falls back to GitHubStatusIndicator.unknown',
        () async {
      dio.stubResponse(response(_baseResponse(
        indicator: 'bogus_value',
        description: '',
      )));

      final result = await service.fetch();

      expect(result.indicator, GitHubStatusIndicator.unknown);
    });

    test('null indicator string falls back to GitHubStatusIndicator.unknown',
        () async {
      dio.stubResponse(response(_baseResponse(
        indicator: null,
        description: '',
      )));

      final result = await service.fetch();

      expect(result.indicator, GitHubStatusIndicator.unknown);
    });

    group('component parsing', () {
      test('filters out only_show_if_degraded components', () async {
        dio.stubResponse(response(_baseResponse(
          components: [
            _component(id: 'c1', name: 'Visible', position: 1),
            {
              'id': 'c2',
              'name': 'HiddenByDegradedFlag',
              'status': 'operational',
              'position': 2,
              'only_show_if_degraded': true,
            },
          ],
        )));

        final result = await service.fetch();

        expect(result.components, hasLength(1));
        expect(result.components[0].id, 'c1');
      });

      test('filters out "Visit www.githubstatus.com" component', () async {
        dio.stubResponse(response(_baseResponse(
          components: [
            _component(id: 'c1', name: 'Real Component', position: 1),
            {
              'id': 'footer',
              'name': 'Visit www.githubstatus.com for more information',
              'status': 'operational',
              'position': 999,
            },
          ],
        )));

        final result = await service.fetch();

        expect(result.components, hasLength(1));
        expect(result.components[0].id, 'c1');
      });

      test('sorts components by position', () async {
        dio.stubResponse(response(_baseResponse(
          components: [
            _component(id: 'c3', name: 'Third', position: 30),
            _component(id: 'c1', name: 'First', position: 10),
            _component(id: 'c2', name: 'Second', position: 20),
          ],
        )));

        final result = await service.fetch();

        expect(result.components, hasLength(3));
        expect(result.components[0].id, 'c1');
        expect(result.components[1].id, 'c2');
        expect(result.components[2].id, 'c3');
      });

      test('maps component status strings', () async {
        dio.stubResponse(response(_baseResponse(
          components: [
            _component(id: 'c1', name: 'Op', status: 'operational'),
            _component(id: 'c2', name: 'Deg', status: 'degraded_performance'),
            _component(id: 'c3', name: 'PO', status: 'partial_outage'),
            _component(id: 'c4', name: 'MO', status: 'major_outage'),
            _component(id: 'c5', name: 'Maint', status: 'under_maintenance'),
            _component(id: 'c6', name: 'Unk', status: 'bogus'),
            _component(id: 'c7', name: 'NullSt', status: null),
          ],
        )));

        final result = await service.fetch();

        expect(result.components[0].status, GitHubComponentStatus.operational);
        expect(
            result.components[1].status, GitHubComponentStatus.degradedPerformance);
        expect(result.components[2].status, GitHubComponentStatus.partialOutage);
        expect(result.components[3].status, GitHubComponentStatus.majorOutage);
        expect(
            result.components[4].status, GitHubComponentStatus.underMaintenance);
        expect(result.components[5].status, GitHubComponentStatus.unknown);
        expect(result.components[6].status, GitHubComponentStatus.unknown);
      });

      test('handles missing fields in component', () async {
        dio.stubResponse(response(_baseResponse(
          components: [
            <String, dynamic>{},
          ],
        )));

        final result = await service.fetch();

        expect(result.components, hasLength(1));
        expect(result.components[0].id, '');
        expect(result.components[0].name, '');
        expect(result.components[0].status, GitHubComponentStatus.unknown);
        expect(result.components[0].position, 0);
      });

      test('filters non-map elements from raw components list', () async {
        dio.stubResponse(response(_baseResponse(
          components: [
            'not a map',
            42,
            _component(id: 'c1', name: 'Valid'),
          ],
        )));

        final result = await service.fetch();

        expect(result.components, hasLength(1));
        expect(result.components[0].id, 'c1');
      });
    });

    group('incident parsing', () {
      test('parses valid incidents', () async {
        dio.stubResponse(response(_baseResponse(
          incidents: [
            _incident(
              id: 'inc1',
              name: 'Incident Alpha',
              status: 'investigating',
              shortlink: 'https://githubstatus.com/incidents/1',
              createdAt: '2024-06-01T12:00:00Z',
              updatedAt: '2024-06-01T14:30:00Z',
            ),
          ],
        )));

        final result = await service.fetch();

        expect(result.incidents, hasLength(1));
        final i = result.incidents[0];
        expect(i.id, 'inc1');
        expect(i.name, 'Incident Alpha');
        expect(i.status, 'investigating');
        expect(i.shortlink, 'https://githubstatus.com/incidents/1');
      });

      test('null shortlink falls back to default URL', () async {
        dio.stubResponse(response(_baseResponse(
          incidents: [
            {
              'id': 'inc1',
              'name': 'No Link Incident',
              'status': 'resolved',
              'shortlink': null,
              'created_at': '2024-01-01T00:00:00Z',
              'updated_at': '2024-01-01T00:00:00Z',
            },
          ],
        )));

        final result = await service.fetch();

        expect(result.incidents[0].shortlink, 'https://www.githubstatus.com/');
      });

      test('handles missing fields in incident', () async {
        dio.stubResponse(response(_baseResponse(
          incidents: [
            <String, dynamic>{},
          ],
        )));

        final result = await service.fetch();

        expect(result.incidents, hasLength(1));
        final i = result.incidents[0];
        expect(i.id, '');
        expect(i.name, '');
        expect(i.status, '');
        expect(i.shortlink, 'https://www.githubstatus.com/');
        expect(i.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
        expect(i.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
      });

      test('filters non-map elements from raw incidents list', () async {
        dio.stubResponse(response(_baseResponse(
          incidents: [
            'not a map',
            _incident(id: 'i1'),
          ],
        )));

        final result = await service.fetch();

        expect(result.incidents, hasLength(1));
        expect(result.incidents[0].id, 'i1');
      });
    });

    group('date parsing', () {
      test('parses valid ISO 8601 date strings', () async {
        dio.stubResponse(response(_baseResponse(
          incidents: [
            _incident(
              createdAt: '2024-06-01T12:00:00Z',
              updatedAt: '2024-06-02T08:30:45.123Z',
            ),
          ],
        )));

        final result = await service.fetch();

        expect(
            result.incidents[0].createdAt, DateTime.utc(2024, 6, 1, 12, 0, 0));
        expect(result.incidents[0].updatedAt,
            DateTime.utc(2024, 6, 2, 8, 30, 45, 123));
      });

      test('unparseable date string returns epoch', () async {
        dio.stubResponse(response(_baseResponse(
          incidents: [
            _incident(createdAt: 'not-a-date', updatedAt: 'garbage'),
          ],
        )));

        final result = await service.fetch();

        expect(result.incidents[0].createdAt,
            DateTime.fromMillisecondsSinceEpoch(0));
        expect(result.incidents[0].updatedAt,
            DateTime.fromMillisecondsSinceEpoch(0));
      });

      test('null date returns epoch', () async {
        dio.stubResponse(response(_baseResponse(
          incidents: [
            {
              'id': 'i1',
              'name': 'N',
              'status': 'N',
              'shortlink': 'https://x',
              'created_at': null,
              'updated_at': null,
            },
          ],
        )));

        final result = await service.fetch();

        expect(result.incidents[0].createdAt,
            DateTime.fromMillisecondsSinceEpoch(0));
        expect(result.incidents[0].updatedAt,
            DateTime.fromMillisecondsSinceEpoch(0));
      });

      test('non-string date value returns epoch', () async {
        dio.stubResponse(response(_baseResponse(
          incidents: [
            {
              'id': 'i1',
              'name': 'N',
              'status': 'N',
              'shortlink': 'https://x',
              'created_at': 42,
              'updated_at': true,
            },
          ],
        )));

        final result = await service.fetch();

        expect(result.incidents[0].createdAt,
            DateTime.fromMillisecondsSinceEpoch(0));
        expect(result.incidents[0].updatedAt,
            DateTime.fromMillisecondsSinceEpoch(0));
      });
    });

    test('fetchedAt is close to now', () async {
      final before = DateTime.now();
      dio.stubResponse(response(_baseResponse()));

      final result = await service.fetch();
      final after = DateTime.now();

      expect(
        result.fetchedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch),
      );
      expect(
        result.fetchedAt.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch),
      );
    });
  });

  // ── Error handling ────────────────────────────────────────────────────

  group('error handling', () {
    test('propagates DioException on connection error', () async {
      dio.stubError(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
        message: 'Connection refused',
      ));

      expect(
        () => service.fetch(),
        throwsA(isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionError,
        )),
      );
    });

    test('propagates DioException on timeout', () async {
      dio.stubError(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.receiveTimeout,
      ));

      expect(
        () => service.fetch(),
        throwsA(isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.receiveTimeout,
        )),
      );
    });

    test('propagates DioException on cancel', () async {
      dio.stubError(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.cancel,
      ));

      expect(
        () => service.fetch(),
        throwsA(isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        )),
      );
    });

    test('propagates non-Dio exceptions', () async {
      dio.stubError(Exception('Unexpected error'));

      expect(
        () => service.fetch(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'toString',
          contains('Unexpected error'),
        )),
      );
    });
  });
}
