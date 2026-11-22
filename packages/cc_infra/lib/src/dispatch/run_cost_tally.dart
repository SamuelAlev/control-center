import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/usage_scope.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';

/// A run's spend as its usage reports state it, folded the way the stream
/// processor folds them: an absolute [UsageScope.runCumulative] snapshot
/// replaces the total (last reading wins), and additive reports
/// ([UsageScope.request], [UsageScope.turn]) sum.
///
/// The dispatch session keeps one so that a run it ends itself (a person's
/// stop, the silence watchdog, a server shutdown) settles with what it spent
/// rather than with the empty cost its row holds until the run completes.
class RunCostTally {
  RunCost? _cumulative;
  RunCost _summed = RunCost.zero;
  bool _reported = false;

  /// Folds one usage report in.
  void add(UsageEvent event) {
    _reported = true;
    final reported = event.usage.toCost(durationMs: event.durationMs);
    if (event.scope == UsageScope.runCumulative) {
      _cumulative = reported.copyWith(
        durationMs: reported.durationMs ?? _cumulative?.durationMs,
      );
      return;
    }
    _summed = _summed + reported;
  }

  /// The run's spend so far, or null when no usage was reported (the run's
  /// row then keeps whatever its own writer recorded).
  RunCost? get total => _reported ? (_cumulative ?? _summed) : null;
}
