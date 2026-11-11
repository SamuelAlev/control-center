import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/src/detection/adapter_detection_service.dart';
import 'package:test/test.dart';

/// Exercises [AdapterDetectionService] — the filesystem probe that resolves a
/// registered adapter's CLI binary via `resolveBinaryPath` and reads its
/// `--version`. Covers the built-in harness short-circuit (always found, no
/// binary), the found path (a real `git` binary), the not-found path, and that
/// only the registry decides what runs.
void main() {
  const service = AdapterDetectionService();

  const git = Adapter(
    id: 'git-cli',
    name: 'Git',
    description: 'git CLI',
    cliName: 'git',
    transport: AdapterTransport.claudeCli,
  );
  const missing = Adapter(
    id: 'mystery',
    name: 'Mystery',
    description: 'does not exist',
    cliName: 'definitely-not-installed-cli-xyz',
    transport: AdapterTransport.claudeCli,
  );

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
    const registered = AdapterDetectionService(registry: [git, missing]);

    test('finds a real CLI (git) and reports a version string', () async {
      final res = await registered.detectOne(git);
      expect(res.status, DetectionStatus.found);
      expect(res.version, isNotEmpty);
    });

    test('reports notFound for a binary that is not installed', () async {
      final res = await registered.detectOne(missing);
      expect(res.status, DetectionStatus.notFound);
      expect(res.version, isNull);
      expect(res.path, isNull);
    });
  });

  group('AdapterDetectionService.detectOne — the registry decides', () {
    late List<String> resolved;
    late List<String> started;
    late AdapterDetectionService probing;

    setUp(() {
      resolved = [];
      started = [];
      probing = AdapterDetectionService(
        registry: const [git],
        resolve: (binary) async {
          resolved.add(binary);
          return '/usr/bin/$binary';
        },
        run: (executable, args) async {
          started.add(executable);
          return ProcessResult(0, 0, 'v1', '');
        },
      );
    });

    test('an unknown adapter is refused before anything starts', () async {
      await expectLater(
        probing.detectOne(
          const Adapter(
            id: 'evil',
            name: 'Evil',
            description: 'client-chosen binary',
            cliName: 'touch',
            transport: AdapterTransport.claudeCli,
          ),
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'unknown_adapter',
          ),
        ),
      );
      expect(resolved, isEmpty);
      expect(started, isEmpty);
    });

    test(
      'a registered id runs the registry binary, not the sent one',
      () async {
        final res = await probing.detectOne(
          const Adapter(
            id: 'git-cli',
            name: 'Git',
            description: 'git CLI',
            cliName: 'touch',
            transport: AdapterTransport.claudeCli,
          ),
        );
        expect(res.status, DetectionStatus.found);
        expect(res.adapter.cliName, 'git');
        expect(resolved, ['git']);
        expect(started, ['/usr/bin/git']);
      },
    );
  });
}
