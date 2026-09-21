import 'dart:async';

import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_server_core/src/skill_quarantine_guard.dart';

/// One boot-time re-verification of installed skills (PRD 23 §6).
///
/// Re-scans on disk; updates quarantine state before agents run. Idempotent per boot.
class SkillReVerifyService {
  /// Creates a [SkillReVerifyService].
  SkillReVerifyService({
    required this._workspaces,
    required this._bundles,
    this._quarantineGuard,
    this._onError,
  });

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
