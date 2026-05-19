import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/src/detection/adapter_detection_service.dart';
import 'package:test/test.dart';

/// Exercises [AdapterDetectionService] — the filesystem probe that resolves a
/// CLI binary via `resolveBinaryPath` and reads its `--version`. Covers the
/// built-in harness short-circuit (always found, no binary), the found path
/// (a real `git` binary) and the not-found path (a bogus cliName).
void main() {
  const service = AdapterDetectionService();

  group('AdapterDetectionService.detectOne — harness short-circuit', () {
    test(
      'built-in harness adapter is always found with no binary path',
      () async {
        final res = await service.detectOne(
          predefinedAdapters.firstWhere(
            (a) => a.transport == AdapterTransport.harness,
          ),
        );
        expect(res.status, DetectionStatus.found);
        expect(res.version, 'built-in');
        expect(res.path, isNull);
        expect(res.capabilities, isNotNull);
      },
    );
  });

  group('AdapterDetectionService.detectOne — real binary', () {
    test('finds a real CLI (git) and reports a version string', () async {
      // Build an adapter whose cliName is `git` (resolves on the test host).
      const adapter = Adapter(
        id: 'git-cli',
        name: 'Git',
        description: 'git CLI',
        cliName: 'git',
        transport: AdapterTransport.structuredCli,
      );
      final res = await service.detectOne(adapter);
      expect(res.status, DetectionStatus.found);
      expect(res.version, isNotEmpty);
      // capabilitiesForAdapter returns null for unknown ids — that's fine.
    });

    test('reports notFound for a binary that is not installed', () async {
      const adapter = Adapter(
        id: 'mystery',
        name: 'Mystery',
        description: 'does not exist',
        cliName: 'definitely-not-installed-cli-xyz',
        transport: AdapterTransport.structuredCli,
      );
      final res = await service.detectOne(adapter);
      expect(res.status, DetectionStatus.notFound);
      expect(res.version, isNull);
      expect(res.path, isNull);
    });
  });
}
