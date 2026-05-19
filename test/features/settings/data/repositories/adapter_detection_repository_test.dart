import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDetectionService implements AdapterDetectionService {
  final Map<String, DetectedAdapter> _results = {};

  void stub(String cliName, DetectedAdapter result) =>
      _results[cliName] = result;

  @override
  Future<DetectedAdapter> detectOne(Adapter adapter) async =>
      _results[adapter.cliName] ?? DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.notFound,
      );
}

void main() {
  late _FakeDetectionService service;
  late AdapterDetectionRepository repo;

  setUp(() {
    service = _FakeDetectionService();
    repo = AdapterDetectionRepository(service);
  });

  const claudeAdapter = Adapter(
    id: 'claude',
    name: 'Claude Code',
    description: 'Anthropic Claude Code CLI',
    cliName: 'claude',
  );

  const piAdapter = Adapter(
    id: 'pi',
    name: 'Pi',
    description: 'pi AI CLI',
    cliName: 'pi',
  );

  group('detectOne', () {
    test('returns DetectedAdapter from service', () async {
      service.stub(
        'claude',
        const DetectedAdapter(
          adapter: claudeAdapter,
          status: DetectionStatus.found,
          version: '1.0.0',
          path: '/usr/bin/claude',
        ),
      );

      final result = await repo.detectOne(claudeAdapter);
      expect(result.status, DetectionStatus.found);
      expect(result.version, '1.0.0');
      expect(result.path, '/usr/bin/claude');
    });

    test('returns notFound when service returns notFound', () async {
      service.stub(
        'claude',
        const DetectedAdapter(adapter: claudeAdapter, status: DetectionStatus.notFound),
      );

      final result = await repo.detectOne(claudeAdapter);
      expect(result.status, DetectionStatus.notFound);
    });
  });

  group('detectAll', () {
    test('detects multiple adapters', () async {
      service.stub('claude', const DetectedAdapter(
        adapter: claudeAdapter, status: DetectionStatus.found, path: '/a/claude',
      ));
      service.stub('pi', const DetectedAdapter(
        adapter: piAdapter, status: DetectionStatus.found, path: '/a/pi',
      ));

      final results = await repo.detectAll([claudeAdapter, piAdapter]);
      expect(results.length, 2);
      expect(results[0].status, DetectionStatus.found);
      expect(results[1].status, DetectionStatus.found);
    });

    test('handles empty list', () async {
      final results = await repo.detectAll([]);
      expect(results, isEmpty);
    });

    test('handles mixed results', () async {
      service.stub('claude', const DetectedAdapter(
        adapter: claudeAdapter, status: DetectionStatus.found,
      ));
      service.stub('pi', const DetectedAdapter(
        adapter: piAdapter, status: DetectionStatus.notFound,
      ));

      final results = await repo.detectAll([claudeAdapter, piAdapter]);
      expect(results.length, 2);
      expect(results[0].status, DetectionStatus.found);
      expect(results[1].status, DetectionStatus.notFound);
    });
  });
}
