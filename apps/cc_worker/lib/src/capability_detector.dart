import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';

/// Detects this host's [WorkerCapabilities] by inspecting the platform.
///
/// Best-effort: probes that are cheap and reliable (OS, core count) are exact;
/// the rest (arch, RAM, whether a Flutter SDK is installed) degrade to a safe
/// default rather than failing. A dedicated `cc_worker` always advertises
/// [WorkerCapabilities.alwaysOn] and [WorkerCapabilities.acceptsParallel].
Future<WorkerCapabilities> detectCapabilities() async {
  final os = _detectOs();
  final arch = await _detectArch();
  final ramMb = await _detectRamMb(os);
  final hasFlutter = await _detectFlutter();
  final sandboxBackends = <String>{};
  if (os == 'macos') {
    sandboxBackends.add('native-macos');
  } else if (os == 'linux') {
    sandboxBackends.add('native-linux');
  }
  return WorkerCapabilities(
    os: os,
    arch: arch,
    cores: Platform.numberOfProcessors,
    ramMb: ramMb,
    hasFlutter: hasFlutter,
    alwaysOn: true,
    acceptsParallel: true,
    sandboxBackends: sandboxBackends,
  );
}

/// Maps [Platform] to the OS keys the scheduler matches on (`macos`/`linux`/
/// `windows`), or `unknown` on an unsupported host.
String _detectOs() {
  if (Platform.isMacOS) {
    return 'macos';
  }
  if (Platform.isLinux) {
    return 'linux';
  }
  if (Platform.isWindows) {
    return 'windows';
  }
  return 'unknown';
}

/// Resolves the CPU arch (`arm64`/`x64`), preferring the fast `Platform.version`
/// token and falling back to `uname -m` (POSIX) or `PROCESSOR_ARCHITECTURE`
/// (Windows).
Future<String> _detectArch() async {
  final fromVersion = _archFromVersionString(Platform.version);
  if (fromVersion != null) {
    return fromVersion;
  }
  if (Platform.isWindows) {
    final env =
        Platform.environment['PROCESSOR_ARCHITECTURE']?.toLowerCase() ?? '';
    if (env.contains('arm')) {
      return 'arm64';
    }
    if (env.contains('64')) {
      return 'x64';
    }
    return 'unknown';
  }
  try {
    final result = await Process.run('uname', const <String>['-m']);
    if (result.exitCode == 0 && result.stdout is String) {
      return _normalizeArch((result.stdout as String).trim());
    }
  } catch (_) {
    // `uname` unavailable — fall through to the unknown default.
  }
  return 'unknown';
}

/// Extracts and normalizes the arch token from a `Platform.version` string such
/// as `3.5.0 (stable) (...) on "macos_arm64"`.
String? _archFromVersionString(String version) {
  final match = RegExp(r'on "[a-z]+_([a-z0-9]+)"').firstMatch(version);
  if (match == null) {
    return null;
  }
  return _normalizeArch(match.group(1) ?? '');
}

/// Folds the many spellings of an arch onto the two well-known keys.
String _normalizeArch(String raw) {
  final value = raw.toLowerCase();
  if (value == 'arm64' || value == 'aarch64') {
    return 'arm64';
  }
  if (value == 'x64' || value == 'x86_64' || value == 'amd64') {
    return 'x64';
  }
  return value.isEmpty ? 'unknown' : value;
}

/// Best-effort total RAM in megabytes; returns 0 when it cannot be probed.
Future<int> _detectRamMb(String os) async {
  try {
    if (os == 'macos') {
      final result = await Process.run('sysctl', const <String>['-n', 'hw.memsize']);
      if (result.exitCode == 0 && result.stdout is String) {
        final bytes = int.tryParse((result.stdout as String).trim());
        if (bytes != null) {
          return bytes ~/ (1024 * 1024);
        }
      }
    } else if (os == 'linux') {
      final meminfo = File('/proc/meminfo');
      if (meminfo.existsSync()) {
        final line = const LineSplitter()
            .convert(meminfo.readAsStringSync())
            .firstWhere((l) => l.startsWith('MemTotal:'), orElse: () => '');
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          final kb = int.tryParse(match.group(1) ?? '');
          if (kb != null) {
            return kb ~/ 1024;
          }
        }
      }
    }
  } catch (_) {
    // RAM detection is non-fatal — a 0 simply means "unreported".
  }
  return 0;
}

/// Returns whether a Flutter SDK is reachable, trying a bare `flutter` first
/// then `fvm flutter`. Short and defensive — any failure means "no".
Future<bool> _detectFlutter() async {
  const invocations = <List<String>>[
    <String>['flutter', '--version'],
    <String>['fvm', 'flutter', '--version'],
  ];
  for (final invocation in invocations) {
    try {
      final result = await Process.run(
        invocation.first,
        invocation.sublist(1),
        runInShell: true,
      ).timeout(const Duration(seconds: 12));
      if (result.exitCode == 0) {
        return true;
      }
    } catch (_) {
      // Not on PATH, non-zero exit, or timed out — try the next invocation.
    }
  }
  return false;
}
