import 'dart:async';

import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_server_core/src/skill_quarantine_guard.dart';

/// ONE boot-time re-verification pass over installed skills (PRD 23 §6).
///
/// Continuous re-verification is EVENT-DRIVEN — no periodic sweep: every
/// gated write (marketplace install/update, editor save) publishes
/// `SkillUpdated`, and the skills-dir watcher publishes it for out-of-band
/// edits, so a changed skill is re-scanned within seconds, not at the next
/// tick. See `SkillWatchService` and the `skill_analysis` pipeline trigger.
///
/// The one case events cannot see is a RULES UPGRADE: when a newer server
/// ships a higher `kSkillRulesVersion`, every installed skill's recorded
/// verdict predates the tightened rules and deserves one re-examination —
/// content that used to pass may now be quarantined. That happens exactly at
/// server startup after an upgrade, so this pass runs ONCE there (a no-op in
/// steady state: nothing is rules-stale, nothing drifted) and enforces any
/// quarantine it f andby detaching the skill from its agents.
///
/// CROSS-WORKSPACE BY DESIGN: the pass enumerates every workspace (a startup
/// reconciler, like the orphan-run reaper). Each per-workspace re-scan and
/// lock rewrite is scoped to one `workspaceId` via [SkillBundlePort] — no
/// cross-workspace data is read or mixed.
///
/// Best-effort: any single workspace's failure is reported via the `onError`
/// callback and never thrown into the caller.
class SkillReVerifyService {
  /// Creates a [SkillReVerifyService].
  SkillReVerifyService({
    required WorkspaceRepository workspaces,
    required SkillBundlePort bundles,
    SkillQuarantineGuard? quarantineGuard,
    void Function(String message)? onError,
  }) : _workspaces = workspaces,
       _bundles = bundles,
       _quarantineGuard = quarantineGuard,
       _onError = onError;

  final WorkspaceRepository _workspaces;
  final SkillBundlePort _bundles;

  /// Enforces sweep-produced quarantines by detaching the skill from its
  /// agents (PRD 23 §6). Optional so tests/disabled configurations can omit
  /// it.
  final SkillQuarantineGuard? _quarantineGuard;

  final void Function(String message)? _onError;

  /// Runs the boot pass on the next event-loop tick (so construction stays
  /// synchronous). There is deliberately no timer — see the class doc.
  void start() {
    unawaited(Future<void>.microtask(runOnce));
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
          // A pass can flip a verdict to quarantine — enforce it immediately
          // rather than waiting for the next dispatch/link sync.
          await _quarantineGuard?.detachQuarantined(ws.id);
        } catch (e) {
          _onError?.call('skill re-verify for workspace ${ws.id} failed: $e');
        }
      }
    } catch (e) {
      _onError?.call('skill re-verify pass failed: $e');
    }
    return total;
  }
}
