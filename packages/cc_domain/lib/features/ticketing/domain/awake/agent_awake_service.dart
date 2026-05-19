import 'dart:async';

import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/ticketing/domain/awake/agent_awake_policy.dart';
import 'package:cc_domain/features/ticketing/domain/awake/sleep_blocker_port.dart';

/// Keeps the OS awake while agents are working by toggling a [SleepBlockerPort]
/// off the [AgentAwakePolicy] decision.
///
/// Re-evaluates whenever the agent registry signals a change and on a periodic
/// tick (so a run that crosses the staleness boundary releases the machine even
/// with no further events). Holds the assertion only while the decision is true,
/// releasing it the moment the last agent goes idle.
class AgentAwakeService {
  /// Creates an [AgentAwakeService].
  ///
  /// [readSignals] returns the current per-agent liveness; [isEnabled] reads the
  /// `keepComputerAwakeWhileAgentsRun` setting; [changes] (optional) fires when
  /// the registry changes; [pollInterval] re-checks the staleness window.
  AgentAwakeService({
    required SleepBlockerPort blocker,
    required List<AgentAwakeSignal> Function() readSignals,
    required bool Function() isEnabled,
    Stream<void>? changes,
    AgentAwakePolicy policy = const AgentAwakePolicy(),
    Duration pollInterval = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _blocker = blocker,
       _readSignals = readSignals,
       _isEnabled = isEnabled,
       _changes = changes,
       _policy = policy,
       _pollInterval = pollInterval,
       _now = now ?? DateTime.now;

  final SleepBlockerPort _blocker;
  final List<AgentAwakeSignal> Function() _readSignals;
  final bool Function() _isEnabled;
  final Stream<void>? _changes;
  final AgentAwakePolicy _policy;
  final Duration _pollInterval;
  final DateTime Function() _now;

  StreamSubscription<void>? _sub;
  Timer? _timer;
  bool _held = false;

  /// Whether the sleep assertion is currently held.
  bool get isHolding => _held;

  /// Begins watching agent activity and toggling the blocker.
  void start() {
    _sub = _changes?.listen((_) => unawaited(evaluate()));
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(evaluate()));
    unawaited(evaluate());
  }

  /// Re-evaluates the policy and toggles the blocker if the decision changed.
  Future<void> evaluate() async {
    final shouldHold = _policy.shouldKeepAwake(
      signals: _readSignals(),
      now: _now(),
      enabled: _isEnabled(),
    );
    if (shouldHold == _held) {
      return;
    }
    try {
      if (shouldHold) {
        await _blocker.begin('Agents are working');
        _held = true;
      } else {
        await _blocker.end();
        _held = false;
      }
    } on Object catch (e, st) {
      CcDomainLog.error('AgentAwakeService: blocker toggle failed', e, st);
    }
  }

  /// Stops watching and releases the assertion.
  Future<void> dispose() async {
    await _sub?.cancel();
    _timer?.cancel();
    if (_held) {
      try {
        await _blocker.end();
      } on Object {
        // Best-effort release on teardown.
      }
      _held = false;
    }
  }
}
