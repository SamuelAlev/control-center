import 'package:cc_worker/cc_worker.dart';
import 'package:test/test.dart';

/// `cc_worker`'s first tests.
///
/// The binary's argument handling lived entirely in `bin/`, where nothing can
/// reach it — which is how "the PSK is a CLI argument" and "every lease offer
/// starts immediately" both went unexamined. The resolution logic now lives in
/// `lib/` precisely so these can exist.
void main() {
  group('resolveWorkerPsk', () {
    test('prefers a file over the environment and the flag', () {
      final psk = resolveWorkerPsk(
        pskFile: '/keys/worker.psk',
        pskFlag: 'from-flag',
        environment: const {'CC_WORKER_PSK': 'from-env'},
        readFile: (_) => 'from-file\n',
      );
      expect(psk, 'from-file');
    });

    test('reads the first non-empty line and trims it', () {
      final psk = resolveWorkerPsk(
        pskFile: '/keys/worker.psk',
        readFile: (_) => '\n\n   secret-key   \nignored\n',
      );
      expect(psk, 'secret-key');
    });

    test('prefers the environment over the flag', () {
      final psk = resolveWorkerPsk(
        pskFlag: 'from-flag',
        environment: const {'CC_WORKER_PSK': 'from-env'},
      );
      expect(psk, 'from-env');
    });

    test('accepts the flag but reports it as an insecure source', () {
      final warnings = <String>[];
      final psk = resolveWorkerPsk(
        pskFlag: 'from-flag',
        onInsecureSource: warnings.add,
      );
      expect(psk, 'from-flag');
      expect(warnings, hasLength(1));
      expect(warnings.single, contains('ps'));
    });

    test('no source at all resolves to null (loopback dev server)', () {
      expect(resolveWorkerPsk(), isNull);
      expect(resolveWorkerPsk(pskFlag: ''), isNull);
    });

    test(
      'an empty or unreadable psk file is a usage error, not a silent null',
      () {
        expect(
          () => resolveWorkerPsk(
            pskFile: '/keys/empty',
            readFile: (_) => '\n  \n',
          ),
          throwsA(
            isA<WorkerCliException>().having((e) => e.exitCode, 'exitCode', 66),
          ),
        );
        expect(
          () => resolveWorkerPsk(
            pskFile: '/keys/missing',
            readFile: (_) => throw const FormatException('nope'),
          ),
          throwsA(isA<WorkerCliException>()),
        );
      },
    );
  });

  group('parseMaxJobs', () {
    test('defaults when absent', () {
      expect(parseMaxJobs(null), 4);
      expect(parseMaxJobs(''), 4);
      expect(parseMaxJobs(null, fallback: 2), 2);
    });

    test('parses a positive integer', () {
      expect(parseMaxJobs('1'), 1);
      expect(parseMaxJobs('16'), 16);
    });

    test('refuses zero, negatives and non-numbers', () {
      for (final bad in ['0', '-1', 'lots', '2.5']) {
        expect(
          () => parseMaxJobs(bad),
          throwsA(
            isA<WorkerCliException>().having((e) => e.exitCode, 'exitCode', 64),
          ),
          reason: '"$bad" must not become a job ceiling',
        );
      }
    });
  });

  group('WorkerConfig', () {
    test('carries a bounded job ceiling by default', () {
      const config = WorkerConfig(
        serverUrl: 'wss://host/rpc',
        name: 'w1',
        deviceId: 'd1',
      );
      expect(config.maxJobs, greaterThan(0));
    });
  });
}
