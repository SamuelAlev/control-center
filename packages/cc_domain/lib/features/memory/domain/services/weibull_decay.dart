import 'dart:math' as math;

import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';

/// Default half-life (hours) used when no per-type Weibull params apply.
const double defaultHalflifeHours = 168;

/// Per-type Weibull temporal-decay boost in `(0,1]`, ported from oh-my-pi
/// mnemopi `core/weibull.ts`.
///
/// Returns `exp(-((ageHours/eta)^k))` where `k`/`eta` come from [memoryType].
/// A just-created memory boosts ~1.0; an old one of a fast-decaying type (e.g.
/// [MemoryType.request], `eta`=72h) is heavily damped. A future timestamp
/// returns 1.0; a null timestamp returns 0.0.
///
/// When [halflifeHours] is supplied it overrides the per-type curve with a
/// plain exponential `exp(-ageHours/halflife)`.
double weibullBoost(
  DateTime? timestamp, {
  DateTime? now,
  MemoryType memoryType = MemoryType.unknown,
  double? halflifeHours,
}) {
  if (timestamp == null) {
    return 0;
  }
  final queryTime = now ?? DateTime.now();
  final ageHours =
      queryTime.difference(timestamp).inMicroseconds / Duration.microsecondsPerHour;
  if (ageHours < 0) {
    return 1;
  }
  if (halflifeHours != null) {
    if (halflifeHours <= 0) {
      return 0;
    }
    return math.exp(-ageHours / halflifeHours);
  }
  final eta = memoryType.eta;
  if (eta <= 0) {
    return 0;
  }
  return math.exp(-math.pow(ageHours / eta, memoryType.k).toDouble());
}
