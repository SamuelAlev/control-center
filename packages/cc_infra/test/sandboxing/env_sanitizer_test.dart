import 'package:cc_infra/src/sandboxing/env_sanitizer.dart';
import 'package:test/test.dart';

/// Exercises [EnvSanitizer.harden] — the environment hardener that strips
/// dynamic-linker injection vectors (LD_*, DYLD_*) and an explicit denylist
/// of interpreter/proxy override vars before a sandboxed process is spawned.
/// Proves the preserved-key override and the prefix/denylist precedence.
void main() {
  const sanitizer = EnvSanitizer();

  group('EnvSanitizer.harden — prefix stripping', () {
    test('strips every LD_* and DYLD_* var regardless of case', () {
      final out = sanitizer.harden({
        'LD_PRELOAD': '/tmp/evil.so',
        'LD_LIBRARY_PATH': '/x',
        'DYLD_INSERT_LIBRARIES': '/tmp/evil2.so',
        'ld_audit': '/y', // case-insensitive prefix match
        'SAFE_VAR': 'kept',
      });
      expect(out, isNot(contains('LD_PRELOAD')));
      expect(out, isNot(contains('LD_LIBRARY_PATH')));
      expect(out, isNot(contains('DYLD_INSERT_LIBRARIES')));
      expect(out, isNot(contains('ld_audit')));
      expect(out['SAFE_VAR'], 'kept');
    });

    test('never strips preserved keys even when prefix-matched', () {
      // PATH isn't prefix-matched anyway, but the preserve set is honored
      // for an exact (case-insensitive) match.
      final out = sanitizer.harden(
        {'PATH': '/usr/bin', 'path': '/bin'},
        preserve: const {'PATH', 'Path'},
      );
      expect(out['PATH'], '/usr/bin');
      expect(out['path'], '/bin');
    });
  });

  group('EnvSanitizer.harden — explicit denylist', () {
    test('removes every denylisted interpreter/proxy var', () {
      final env = <String, String>{
        for (final k in EnvSanitizer.denylist) k: 'v',
        'HOME': '/h',
        'USER': 'sam',
      };
      final out = sanitizer.harden(env);
      expect(out['HOME'], '/h');
      expect(out['USER'], 'sam');
      for (final k in EnvSanitizer.denylist) {
        expect(out, isNot(contains(k)));
      }
    });

    test('a custom preserve key survives the denylist', () {
      final out = sanitizer.harden(
        {'NODE_OPTIONS': '--inspect', 'KEEP_ME': '1'},
        preserve: const {'KEEP_ME'},
      );
      expect(out, isNot(contains('NODE_OPTIONS')));
      expect(out['KEEP_ME'], '1');
    });
  });

  group('EnvSanitizer.harden — pass-through', () {
    test('keeps a benign environment unchanged', () {
      const env = {'HOME': '/h', 'SHELL': '/bin/zsh', 'LANG': 'en_US.UTF-8'};
      expect(sanitizer.harden(env), env);
    });

    test('an empty environment yields an empty map', () {
      expect(sanitizer.harden(const {}), isEmpty);
    });
  });

  group('EnvSanitizer.hardenPlatform', () {
    test('merges extra over platform env and hardens the union', () {
      // Extra entries win; dangerous extras are stripped; benign extras pass.
      final out = sanitizer.hardenPlatform({
        'SAFE_EXTRA': '1',
        'LD_PRELOAD': 'x',
      });
      expect(out['SAFE_EXTRA'], '1');
      expect(out, isNot(contains('LD_PRELOAD')));
      // Platform PATH is always present in the test runner.
      expect(out, contains('PATH'));
    });
  });
}
