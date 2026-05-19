import 'dart:async';

import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';

/// Periodically re-scans installed skills whose recorded verdict is stale — i.e.
/// produced under an older static-rules version — against the current rules
/// (PRD 23 §6 continuous re-verification). When the rules tighten, a skill that
/// previously passed is re-examined and either cleared or quarantined, so a
/// newly-recognized malicious pattern in already-installed content surfaces
/// without waiting for a reinstall.
///
/// CROSS-WORKSPACE BY DESIGN: the sweep enumerates every workspace (a startup/
/// maintenance reconciler, like the orphan-run reaper). Each per-workspace
/// re-scan and lock rewrite is scoped to one `workspaceId` via [SkillBundlePort]
/// — no cross-workspace data is read or mixed.
///
/// Best-effort: mirrors `DatabaseRetentionService` — an immediate first run plus
/// a periodic tick, and any single workspace's failure is reported via the
/// `onError` callback and never thrown into the caller.
class SkillReVerifyService {
  /// Creates a [SkillReVerifyService].
  SkillReVerifyService({
    required WorkspaceRepository workspaces,
    required SkillBundlePort bundles,
    this.interval = const Duration(hours: 6),
    void Function(String message)? onError,
  }) : _workspaces = workspaces,
       _bundles = bundles,
       _onError = onError;

  final WorkspaceRepository _workspaces;
  final SkillBundlePort _bundles;

  /// Cadence of the re-verification sweep.
  final Duration interval;

  final void Function(String message)? _onError;
  Timer? _timer;

  /// Starts the periodic sweep (immediate first run on the next event-loop tick
  /// so construction stays synchronous).
  void start() {
    _timer?.cancel();
    unawaited(Future<void>.microtask(runOnce));
    _timer = Timer.periodic(interval, (_) => unawaited(runOnce()));
  }

  /// Stops the periodic sweep.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Runs one re-verification pass across every workspace. Returns the total
  /// number of skills re-scanned. Never throws.
  Future<int> runOnce() async {
    var total = 0;
    try {
      final all = await _workspaces.watchAll().first;
      for (final ws in all) {
        try {
          total += (await _bundles.reVerify(ws.id)).length;
        } catch (e) {
          _onError?.call('skill re-verify for workspace ${ws.id} failed: $e');
        }
      }
    } catch (e) {
      _onError?.call('skill re-verify sweep failed: $e');
    }
    return total;
  }
}
