import 'dart:convert';

/// Well-known capability keys the scheduler matches jobs against (PRD 20 §6).
///
/// A capability key is a stable string so a job's `requiredCaps`/`preferredCaps`
/// and a worker's advertised key set are compared by simple set membership —
/// deterministic, explainable, no fuzzy matching.
abstract final class FleetCaps {
  /// A Flutter SDK is installed (PRD 18 golden-render axis).
  static const String flutter = 'flutter';

  /// ML/GPU capacity (meetings ML, diarization).
  static const String ml = 'ml';

  /// Host OS key: Linux.
  static const String linux = 'linux';

  /// Host OS key: macOS.
  static const String macos = 'macos';

  /// Host OS key: Windows.
  static const String windows = 'windows';

  /// CPU arch key: 64-bit ARM.
  static const String arm64 = 'arm64';

  /// CPU arch key: 64-bit x86.
  static const String x64 = 'x64';

  /// An OS-level sandbox backend is available for isolated execution.
  static const String sandbox = 'sandbox';

  /// The worker opts into throwaway parallel capacity (PRD 21 eval batches).
  static const String parallel = 'parallel';

  /// The machine stays up independent of a client (laptop-lid problem).
  static const String alwaysOn = 'always-on';

  /// Every well-known key (for validation / UI listing).
  static const Set<String> all = <String>{
    flutter,
    ml,
    linux,
    macos,
    windows,
    arm64,
    x64,
    sandbox,
    parallel,
    alwaysOn,
  };
}

/// The declared capabilities of a fleet worker (PRD 20 §1).
///
/// Pure value object: a worker advertises this at pairing and heartbeat and
/// the scheduler derives the worker's [keys] set from it. Equality is by value
/// so a job routed against the same fleet routes identically (determinism).
class WorkerCapabilities {
  /// Creates a [WorkerCapabilities].
  const WorkerCapabilities({
    required this.os,
    required this.arch,
    required this.cores,
    required this.ramMb,
    this.hasFlutter = false,
    this.hasMl = false,
    this.alwaysOn = false,
    this.acceptsParallel = false,
    this.sandboxBackends = const {},
    this.extra = const {},
  });

  /// Parses from a JSON map (tolerant of missing fields).
  factory WorkerCapabilities.fromJson(Map<String, dynamic> json) =>
      WorkerCapabilities(
        os: (json['os'] as String?) ?? 'unknown',
        arch: (json['arch'] as String?) ?? 'unknown',
        cores: (json['cores'] as num?)?.toInt() ?? 1,
        ramMb: (json['ramMb'] as num?)?.toInt() ?? 0,
        hasFlutter: json['hasFlutter'] as bool? ?? false,
        hasMl: json['hasMl'] as bool? ?? false,
        alwaysOn: json['alwaysOn'] as bool? ?? false,
        acceptsParallel: json['acceptsParallel'] as bool? ?? false,
        sandboxBackends: ((json['sandboxBackends'] as List?) ?? const [])
            .cast<String>()
            .toSet(),
        extra: ((json['extra'] as List?) ?? const []).cast<String>().toSet(),
      );

  /// Parses from a JSON string, returning an unknown default on empty input.
  factory WorkerCapabilities.fromJsonString(String source) {
    if (source.trim().isEmpty) {
      return const WorkerCapabilities(
        os: 'unknown',
        arch: 'unknown',
        cores: 1,
        ramMb: 0,
      );
    }
    return WorkerCapabilities.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  /// Host OS (`macos`/`linux`/`windows`).
  final String os;

  /// CPU architecture (`arm64`/`x64`).
  final String arch;

  /// Logical CPU cores.
  final int cores;

  /// Total RAM in megabytes.
  final int ramMb;

  /// A Flutter SDK is installed.
  final bool hasFlutter;

  /// ML/GPU capacity is available.
  final bool hasMl;

  /// The machine is always-on (survives a client disconnect / laptop lid).
  final bool alwaysOn;

  /// The worker opts into throwaway parallel batch capacity.
  final bool acceptsParallel;

  /// Available OS sandbox backends (e.g. `native-macos`, `native-linux`).
  final Set<String> sandboxBackends;

  /// Arbitrary extra capability tags the operator can pin jobs to.
  final Set<String> extra;

  /// The full set of capability keys this worker satisfies. The scheduler
  /// matches a job's required/preferred keys against exactly this set.
  Set<String> get keys {
    final result = <String>{arch};
    if (os == FleetCaps.macos) {
      result.add(FleetCaps.macos);
    } else if (os == FleetCaps.linux) {
      result.add(FleetCaps.linux);
    } else if (os == FleetCaps.windows) {
      result.add(FleetCaps.windows);
    }
    if (hasFlutter) {
      result.add(FleetCaps.flutter);
    }
    if (hasMl) {
      result.add(FleetCaps.ml);
    }
    if (alwaysOn) {
      result.add(FleetCaps.alwaysOn);
    }
    if (acceptsParallel) {
      result.add(FleetCaps.parallel);
    }
    if (sandboxBackends.isNotEmpty) {
      result.add(FleetCaps.sandbox);
    }
    result.addAll(extra);
    return result;
  }

  /// Serializes to a stable JSON map.
  Map<String, dynamic> toJson() => {
    'os': os,
    'arch': arch,
    'cores': cores,
    'ramMb': ramMb,
    'hasFlutter': hasFlutter,
    'hasMl': hasMl,
    'alwaysOn': alwaysOn,
    'acceptsParallel': acceptsParallel,
    'sandboxBackends': sandboxBackends.toList()..sort(),
    'extra': extra.toList()..sort(),
  };

  /// Serializes to a stable JSON string.
  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is WorkerCapabilities &&
      other.os == os &&
      other.arch == arch &&
      other.cores == cores &&
      other.ramMb == ramMb &&
      other.hasFlutter == hasFlutter &&
      other.hasMl == hasMl &&
      other.alwaysOn == alwaysOn &&
      other.acceptsParallel == acceptsParallel &&
      _setEq(other.sandboxBackends, sandboxBackends) &&
      _setEq(other.extra, extra);

  @override
  int get hashCode => Object.hash(
    os,
    arch,
    cores,
    ramMb,
    hasFlutter,
    hasMl,
    alwaysOn,
    acceptsParallel,
    Object.hashAllUnordered(sandboxBackends),
    Object.hashAllUnordered(extra),
  );

  static bool _setEq(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
