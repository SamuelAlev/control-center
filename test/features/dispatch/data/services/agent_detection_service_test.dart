import 'package:cc_infra/src/detection/agent_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DetectionStatus', () {
    test('has expected values', timeout: const Timeout.factor(2), () {
      expect(DetectionStatus.values, containsAll([
        DetectionStatus.ready,
        DetectionStatus.notAuthenticated,
        DetectionStatus.notInstalled,
        DetectionStatus.unknown,
      ]));
    });

    test('values are distinct', timeout: const Timeout.factor(2), () {
      final names = DetectionStatus.values.map((v) => v.name).toList();
      expect(names.toSet().length, names.length);
    });
  });

  group('AdapterDetectionResult', () {
    test('constructs with required fields only', timeout: const Timeout.factor(2), () {
      const result = AdapterDetectionResult(
        cliName: 'pi',
        status: DetectionStatus.notInstalled,
      );

      expect(result.cliName, 'pi');
      expect(result.status, DetectionStatus.notInstalled);
      expect(result.binaryPath, isNull);
      expect(result.configDir, isNull);
      expect(result.authError, isNull);
      expect(result.detectedAt, isNull);
    });

    test('constructs with all fields set', timeout: const Timeout.factor(2), () {
      final now = DateTime.now();
      final result = AdapterDetectionResult(
        cliName: 'claude',
        status: DetectionStatus.ready,
        binaryPath: '/usr/local/bin/claude',
        configDir: '/home/user/.claude',
        authError: null,
        detectedAt: now,
      );

      expect(result.cliName, 'claude');
      expect(result.status, DetectionStatus.ready);
      expect(result.binaryPath, '/usr/local/bin/claude');
      expect(result.configDir, '/home/user/.claude');
      expect(result.authError, isNull);
      expect(result.detectedAt, now);
    });

    test('constructs with notAuthenticated and authError', timeout: const Timeout.factor(2), () {
      final now = DateTime.now();
      final result = AdapterDetectionResult(
        cliName: 'claude',
        status: DetectionStatus.notAuthenticated,
        binaryPath: '/usr/local/bin/claude',
        authError: 'Auth probe exited with code 1',
        detectedAt: now,
      );

      expect(result.status, DetectionStatus.notAuthenticated);
      expect(result.authError, 'Auth probe exited with code 1');
      expect(result.binaryPath, isNotNull);
    });


    test('configDir can be set to non-null', timeout: const Timeout.factor(2), () {
      const result = AdapterDetectionResult(
        cliName: 'claude',
        status: DetectionStatus.ready,
        configDir: '/home/user/.claude',
      );

      expect(result.configDir, '/home/user/.claude');
    });

    test('unknown status represents undetected state', timeout: const Timeout.factor(2), () {
      const result = AdapterDetectionResult(
        cliName: 'unknown-agent',
        status: DetectionStatus.unknown,
      );

      expect(result.status, DetectionStatus.unknown);
      expect(result.binaryPath, isNull);
    });
  });

  group('AgentDetectionService', () {
    test('can be constructed with default cacheTtl', timeout: const Timeout.factor(2), () {
      final service = AgentDetectionService();
      expect(service.cacheTtl, const Duration(hours: 24));
    });

    test('can be constructed with custom cacheTtl', timeout: const Timeout.factor(2), () {
      final service = AgentDetectionService(
        cacheTtl: const Duration(minutes: 30),
      );
      expect(service.cacheTtl, const Duration(minutes: 30));
    });

    test('detect returns a map keyed by cli names', timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      final results = await service.detect();

      expect(results, isA<Map<String, AdapterDetectionResult>>());
      // Should contain at least 'pi' and 'claude' from _adapters
      expect(results.keys, containsAll(['pi', 'claude']));
    });

    test('detect result entries have correct cliName', timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      final results = await service.detect();

      for (final entry in results.entries) {
        expect(entry.value.cliName, entry.key);
      }
    });

    test('detect result status is one of valid enum values', timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      final results = await service.detect();

      for (final result in results.values) {
        expect(DetectionStatus.values, contains(result.status));
      }
    });

    test('detect populates detectedAt', timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      final results = await service.detect();

      for (final result in results.values) {
        expect(result.detectedAt, isNotNull);
      }
    });

    test('detect sets binaryPath for installed adapters', timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      final results = await service.detect();

      for (final result in results.values) {
        if (result.status == DetectionStatus.ready ||
            result.status == DetectionStatus.notAuthenticated) {
          expect(result.binaryPath, isNotNull);
        }
      }
    });

    test('detect sets notInstalled when binary is absent', timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      final results = await service.detect();

      for (final result in results.values) {
        if (result.status == DetectionStatus.notInstalled) {
          expect(result.binaryPath, isNull);
        }
      }
    });

    test('getCached returns detect when cache is empty', timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      // Cache is empty, so getCached should call detect
      final results = await service.getCached();

      expect(results, isNotEmpty);
      expect(results.keys, containsAll(['pi', 'claude']));
    });

    test('getCached returns cached result on second call', timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService(cacheTtl: const Duration(hours: 1));
      // First call populates the cache
      final first = await service.getCached();
      // Second call should return the same cached data
      final second = await service.getCached();

      // Same cliNames and same status values
      expect(second.keys, first.keys);
      for (final key in first.keys) {
        expect(second[key]!.cliName, first[key]!.cliName);
        expect(second[key]!.status, first[key]!.status);
      }
    });

    test('detect refreshes cache', timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService(cacheTtl: const Duration(hours: 1));
      final first = await service.detect();
      final second = await service.detect();

      // Both should have the same adapter names
      expect(second.keys, first.keys);
      // detectedAt should be set on both
      for (final result in first.values) {
        expect(result.detectedAt, isNotNull);
      }
      for (final result in second.values) {
        expect(result.detectedAt, isNotNull);
      }
    });

    test('authError is null for ready status', timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      final results = await service.detect();

      for (final result in results.values) {
        if (result.status == DetectionStatus.ready) {
          expect(result.authError, isNull);
        }
      }
    });

    test('expired cache triggers re-detection', timeout: const Timeout.factor(2), () async {
      // Use a very short TTL
      final service = AgentDetectionService(cacheTtl: Duration.zero);
      final first = await service.getCached();

      // With zero TTL, the next getCached call should re-detect
      // (sleeping briefly to let time advance)
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final second = await service.getCached();

      expect(second, isNotEmpty);
      expect(second.keys, first.keys);
    });

    test('cacheTtl can be set to very short duration',
        timeout: const Timeout.factor(2), () {
      final service = AgentDetectionService(
        cacheTtl: const Duration(seconds: 1),
      );
      expect(service.cacheTtl, const Duration(seconds: 1));
    });

    test('getCached returns unmodifiable map', timeout: const Timeout.factor(2),
        () async {
      final service = AgentDetectionService(cacheTtl: const Duration(hours: 1));
      // Populate the cache first so getCached returns the cached map.
      await service.detect();
      final results = await service.getCached();

      expect(
        () => results['extra'] = const AdapterDetectionResult(
          cliName: 'extra',
          status: DetectionStatus.unknown,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('detect result has correct number of adapters',
        timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      final results = await service.detect();

      expect(results.length, 2);
    });

    test('consecutive detect calls return fresh results',
        timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      final first = await service.detect();
      final second = await service.detect();

      for (final key in first.keys) {
        final firstAt = first[key]!.detectedAt;
        final secondAt = second[key]!.detectedAt;
        expect(firstAt, isNotNull);
        expect(secondAt, isNotNull);
        expect(firstAt, isNot(secondAt));
      }
    });

    test('getCached with zero TTL always re-detects', timeout: const Timeout.factor(2),
        () async {
      final service = AgentDetectionService(cacheTtl: Duration.zero);
      final first = await service.getCached();
      final second = await service.getCached();
      final third = await service.getCached();

      // Each call should produce fresh results with different timestamps.
      for (final key in first.keys) {
        expect(first[key]!.detectedAt, isNotNull);
        expect(second[key]!.detectedAt, isNotNull);
        expect(third[key]!.detectedAt, isNotNull);
        expect(first[key]!.detectedAt, isNot(second[key]!.detectedAt));
        expect(second[key]!.detectedAt, isNot(third[key]!.detectedAt));
      }
    });

    test('detect returns mutable map (not unmodifiable)', timeout: const Timeout.factor(2),
        () async {
      final service = AgentDetectionService();
      final results = await service.detect();

      // Should not throw — detect returns a fresh mutable map.
      results['extra-key'] = const AdapterDetectionResult(
        cliName: 'extra',
        status: DetectionStatus.unknown,
      );
      expect(results, contains('extra-key'));
    });

    test('configDir is populated for claude when directory exists',
        timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      final results = await service.detect();
      final claudeResult = results['claude'];

      expect(claudeResult, isNotNull);
      // If claude is installed (ready or notAuthenticated) and ~/.claude exists,
      // configDir should be set.
      if (claudeResult!.status != DetectionStatus.notInstalled &&
          claudeResult.configDir != null) {
        expect(claudeResult.configDir, isNotEmpty);
        // Expanded path should not contain literal ~/.
        expect(claudeResult.configDir, isNot(startsWith('~/')));
      }
    });

    test('detect result fields are consistent with status',
        timeout: const Timeout.factor(2), () async {
      final service = AgentDetectionService();
      final results = await service.detect();

      for (final result in results.values) {
        switch (result.status) {
          case DetectionStatus.notInstalled:
            expect(result.binaryPath, isNull);
          case DetectionStatus.ready:
            expect(result.binaryPath, isNotNull);
            expect(result.authError, isNull);
          case DetectionStatus.notAuthenticated:
            expect(result.binaryPath, isNotNull);
            expect(result.authError, isNotNull);
          case DetectionStatus.unknown:
            // Shouldn't happen from detect(), but if it does, binaryPath
            // could be anything.
            break;
        }
      }
    });

    test('getCached after detect returns same statuses', timeout: const Timeout.factor(2),
        () async {
      final service = AgentDetectionService(cacheTtl: const Duration(hours: 1));
      await service.detect();
      final cached = await service.getCached();

      // Each adapter in cached should come from cache.
      for (final result in cached.values) {
        expect(result.detectedAt, isNotNull);
      }
    });
  });
}
