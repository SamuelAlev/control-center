import 'dart:io';

/// Sanitizes the environment for sandboxed agent spawns.
///
/// Strips dangerous injection vectors (`LD_PRELOAD`, `DYLD_INSERT_LIBRARIES`,
/// …) that could bypass the sandbox by loading attacker-controlled shared
/// libraries into the sandboxed process before seatbelt/bwrap takes effect.
class EnvSanitizer {
  const EnvSanitizer();

  /// Prefixes whose presence is stripped from the environment unconditionally.
  /// Belt-and-suspenders with the explicit denylist — any `LD_*` or `DYLD_*`
  /// var is a dynamic-linker injection vector.
  static const List<String> dangerousPrefixes = [
    'LD_',
    'DYLD_',
  ];

  /// Explicit denylist of known-dangerous env vars.
  static const List<String> denylist = [
    'LD_PRELOAD',
    'LD_LIBRARY_PATH',
    'DYLD_INSERT_LIBRARIES',
    'DYLD_LIBRARY_PATH',
    'DYLD_FALLBACK_LIBRARY_PATH',
    'LD_AUDIT',
    'BASH_ENV',
    'ENV',
    'PERL5OPT',
    'PYTHONPATH',
    'NODE_OPTIONS',
    'NODE_EXTRA_CA_CERTS',
    'PERL_MM_OPT',
    'RUBYOPT',
    'GIT_SSH',
    'GIT_SSH_COMMAND',
  ];

  /// Returns a hardened copy of [env] with all dangerous keys removed.
  /// [preserve] keys (e.g. `PATH`) are never stripped even if they match a
  /// prefix rule.
  Map<String, String> harden(
    Map<String, String> env, {
    Set<String> preserve = const {'PATH', 'Path'},
  }) {
    final cleaned = <String, String>{};
    outer:
    for (final entry in env.entries) {
      final key = entry.key;
      final upperKey = key.toUpperCase();

      // Never strip preserved keys.
      for (final p in preserve) {
        if (key == p || upperKey == p.toUpperCase()) {
          cleaned[key] = entry.value;
          continue outer;
        }
      }

      // Strip by prefix.
      for (final prefix in dangerousPrefixes) {
        if (upperKey.startsWith(prefix)) {
          continue outer;
        }
      }

      // Strip by explicit name.
      if (denylist.contains(key) || denylist.contains(upperKey)) {
        continue outer;
      }

      cleaned[key] = entry.value;
    }
    return cleaned;
  }

  /// Convenience: harden `Platform.environment` merged with [extra].
  Map<String, String> hardenPlatform(Map<String, String> extra) {
    return harden(<String, String>{
      ...Platform.environment,
      ...extra,
    });
  }
}
