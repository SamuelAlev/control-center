import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:test/test.dart';

/// `--code-mode-max-processes` and `--code-mode-max-heap-mb` are the server
/// owner's caps for scripts. Neither is reachable over RPC: they are read
/// once, here, from argv or the environment, and a value the server does not
/// accept stops it at start.
void main() {
  CcServerConfig resolve(
    List<String> args, [
    Map<String, String> env = const {},
  ]) => CcServerConfig.resolve(args, environment: env);

  group('--code-mode-max-processes', () {
    test('defaults to the domain cap for this machine', () {
      expect(
        resolve(const []).codeModeMaxProcesses,
        CodeModeLimits.defaultServerProcessCap(Platform.numberOfProcessors),
      );
    });

    test('takes a value from the flag or the environment', () {
      expect(
        resolve(const ['--code-mode-max-processes', '3']).codeModeMaxProcesses,
        3,
      );
      expect(
        resolve(const ['--code-mode-max-processes=7']).codeModeMaxProcesses,
        7,
      );
      expect(
        resolve(const [], const {
          'CC_SERVER_CODE_MODE_MAX_PROCESSES': '5',
        }).codeModeMaxProcesses,
        5,
      );
    });

    test('a value outside its range or not a number stops the boot', () {
      const range = CcServerConfig.codeModeMaxProcessesRange;
      for (final value in ['0', '-4', '100000', 'lots', '2.5']) {
        expect(
          () => resolve(['--code-mode-max-processes', value]),
          throwsA(
            isA<CodeModeFlagInvalid>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('--code-mode-max-processes'),
                contains('from ${range.min} to ${range.max}'),
              ),
            ),
          ),
          reason: value,
        );
      }
      expect(
        () => resolve(const [], const {
          'CC_SERVER_CODE_MODE_MAX_PROCESSES': 'many',
        }),
        throwsA(isA<CodeModeFlagInvalid>()),
      );
    });
  });

  group('--code-mode-max-heap-mb', () {
    test('defaults to the domain ceiling', () {
      expect(
        resolve(const []).codeModeMaxHeapBytes,
        CodeModeLimits.heap.ceiling,
      );
    });

    test('takes a value in MiB from the flag or the environment', () {
      expect(
        resolve(const ['--code-mode-max-heap-mb', '128']).codeModeMaxHeapBytes,
        128 * 1024 * 1024,
      );
      expect(
        resolve(const [], const {
          'CC_SERVER_CODE_MODE_MAX_HEAP_MB': '64',
        }).codeModeMaxHeapBytes,
        64 * 1024 * 1024,
      );
    });

    test('a value outside its range or not a number stops the boot', () {
      for (final value in ['0', '15', '1025', 'big']) {
        expect(
          () => resolve(['--code-mode-max-heap-mb', value]),
          throwsA(isA<CodeModeFlagInvalid>()),
          reason: value,
        );
      }
    });
  });

  test('a refused value reaches the terminal escaped and bounded: ESC, '
      'OSC, BEL, CR and LF in every position a value is echoed (review 6, '
      'finding 5)', () {
    const raw = {
      'ESC': ('\x1B[2Joff', r'\u{001B}[2Joff'),
      'OSC': ('\x1B]0;pwned\x07off', r'\u{001B}]0;pwned\u{0007}off'),
      'BEL': ('of\x07f', r'of\u{0007}f'),
      'CR': ('of\rforged', r'of\u{000D}forged'),
      'LF': ('of\nINFO forged', r'of\u{000A}INFO forged'),
    };
    for (final MapEntry(key: what, value: (value, shown)) in raw.entries) {
      for (final (args, env) in [
        (['--code-mode-max-processes', '1$value'], const <String, String>{}),
        (<String>[], {'CC_SERVER_CODE_MODE_MAX_HEAP_MB': '1$value'}),
        (['--code-mode-max-heap-mb=1$value'], const <String, String>{}),
      ]) {
        expect(
          () => resolve(args, env),
          throwsA(
            isA<CodeModeFlagInvalid>().having(
              (e) => e.message,
              'message',
              allOf(
                contains(shown),
                isNot(matches(RegExp(r'[\x00-\x1F\x7F]'))),
              ),
            ),
          ),
          reason: '$what in ${args.isEmpty ? env.keys.single : args.first}',
        );
      }
    }
    // A value of any length is echoed in at most 80 characters; a letter
    // outside ASCII is kept as it is.
    expect(
      () => resolve(['--code-mode-max-processes', '\u00F6${'\x1B' * 100000}']),
      throwsA(
        isA<CodeModeFlagInvalid>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('"\u00F6\\u{001B}'),
            contains('\u2026"'),
            hasLength(lessThan(1000)),
          ),
        ),
      ),
    );
  });
}
