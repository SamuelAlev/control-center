import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/transcript/util/nested_calls.dart';
import 'package:flutter/widgets.dart';

/// The localized word for a repeating or parallel group: `Loop`, `For each`,
/// `In parallel`, `Function`. Null for a branch or an arm, whose header is
/// its code alone.
String? scriptGroupKind(AppLocalizations l10n, ScriptOutlineNode node) =>
    switch (node) {
      ScriptLoopNode() => l10n.scriptGroupLoop,
      ScriptEachNode() => l10n.scriptGroupEach,
      ScriptParallelNode() => l10n.scriptGroupParallel,
      ScriptFunctionNode() => l10n.scriptGroupFunction,
      _ => null,
    };

/// The glyph of a group or arm header.
IconData scriptNodeIcon(ScriptOutlineNode node) => switch (node) {
  ScriptLoopNode() => AppIcons.repeat,
  ScriptEachNode() => AppIcons.list,
  ScriptParallelNode() => AppIcons.columns3,
  ScriptFunctionNode() => AppIcons.code,
  ScriptArmNode(kind: ScriptArmKind.catchArm || ScriptArmKind.finallyArm) =>
    AppIcons.cornerDownLeft,
  _ => AppIcons.gitBranch,
};

/// A group's calls by state, in a fixed order: `1 running · 4 ok · 1 failed ·
/// 3 queued`. How a made call ended is read from its payload by [stateOf].
String scriptGroupTally<T>(
  AppLocalizations l10n,
  ScriptRunGroup<T> group,
  NestedCallState Function(T call) stateOf,
) {
  var running = 0;
  var ok = 0;
  var failed = 0;
  var denied = 0;
  var cancelled = 0;
  for (final call in group.payloads) {
    switch (stateOf(call)) {
      case NestedCallState.running:
        running++;
      case NestedCallState.ok:
        ok++;
      case NestedCallState.failed:
        failed++;
      case NestedCallState.denied:
        denied++;
      case NestedCallState.cancelled:
        cancelled++;
    }
  }
  final counts = group.counts;
  return [
    if (running > 0) l10n.scriptCallsRunning(running),
    if (ok > 0) l10n.scriptCallsOk(ok),
    if (failed > 0) l10n.scriptCallsFailed(failed),
    if (denied > 0) l10n.scriptCallsDenied(denied),
    if (cancelled > 0) l10n.scriptCallsCancelled(cancelled),
    if (counts.queued > 0) l10n.scriptCallsQueued(counts.queued),
    if (counts.skipped > 0) l10n.scriptCallsSkipped(counts.skipped),
  ].join(' · ');
}

/// Whether a made call must stay in sight however long its group: it is
/// running (which includes waiting for a person), failed or was denied.
bool scriptCallMustShow(NestedCallState state) =>
    state == NestedCallState.running ||
    state == NestedCallState.failed ||
    state == NestedCallState.denied;
