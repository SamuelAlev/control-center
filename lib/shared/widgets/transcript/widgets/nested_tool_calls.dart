import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_source.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/transcript/util/nested_calls.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_call_tree.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_pending_row.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_tree_opened.dart';
import 'package:flutter/widgets.dart';

/// The calls a script made, inside the row of the call that ran it, laid
/// over the script's structure ([ScriptCallTree]): what runs now, what is
/// queued, what repeated, what ran side by side and which branch was not
/// taken.
///
/// Each made call is drawn by [itemBuilder], which a surface points at the
/// very row it uses for a direct call, so an edit made from a script shows
/// the same diff a direct edit does. When the structure cannot be used (no
/// script text, a script the outline cannot follow, calls that do not say
/// where in the script they were made) the calls are a flat list in the
/// order made: a plain column while short, past [lazyThreshold] a bounded
/// region that builds only the rows in view. A script with no tool calls
/// shows nothing.
class NestedToolCalls extends StatelessWidget {
  /// Creates the list for the calls [script] made.
  const NestedToolCalls({
    super.key,
    required this.script,
    required this.calls,
    required this.ended,
    required this.codeFont,
    required this.itemBuilder,
  });

  /// Past this many calls the flat list scrolls inside [maxListHeight].
  static const int lazyThreshold = 24;

  /// The height of the scrolling region a long flat list gets.
  static const double maxListHeight = 400;

  /// The call that ran the script; its `code` input is the script.
  final ToolSegment script;

  /// The calls, in the order the script made them.
  final List<ToolSegment> calls;

  /// Whether the script has stopped: nothing it did not reach is queued.
  final bool ended;

  /// Mono font for the script's code.
  final String codeFont;

  /// Draws one call.
  final Widget Function(BuildContext context, ToolSegment call) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final code = script.inputs?['code'];
    final view = scriptRunViewOrFlat(
      source: code is String ? code : null,
      calls: [
        for (final call in calls)
          ScriptRunCall(
            payload: call,
            toolName: call.toolName,
            line: call.callSite?.line,
            column: call.callSite?.column,
            running: nestedCallStateOf(call) == NestedCallState.running,
            failed: switch (nestedCallStateOf(call)) {
              NestedCallState.running || NestedCallState.ok => false,
              _ => true,
            },
            startMs: call.startedAt.millisecondsSinceEpoch,
            endMs: call.durationMs == null
                ? null
                : call.startedAt.millisecondsSinceEpoch + call.durationMs!,
          ),
      ],
      ended: ended,
    );
    if (view != null && view.counts.total == 0) {
      return const SizedBox.shrink();
    }
    if (view == null && calls.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final label = CcTypography.caption.copyWith(
      color: t.textQuaternary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    final breakdown = [
      nestedCallBreakdown(l10n, NestedCallTally.of(calls)),
      if (view != null && view.counts.queued > 0)
        l10n.scriptCallsQueued(view.counts.queued),
      if (view != null && view.counts.skipped > 0)
        l10n.scriptCallsSkipped(view.counts.skipped),
    ].where((part) => part.isNotEmpty).join(' · ');
    final Widget list = view != null
        ? ScriptCallTree<ToolSegment>(
            view: view,
            scope: scriptTreeScope(script.toolCallId, script.startedAt),
            stateOf: nestedCallStateOf,
            // A transcript row does not say whether a person approved it.
            keepInSight: (_) => false,
            toolOf: (call) => call.toolName,
            toolLabel: scriptToolVerb,
            itemBuilder: itemBuilder,
            codeFont: codeFont,
          )
        : _flat(t);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: l10n.scriptToolCalls, style: label),
                  TextSpan(
                    text: '  $breakdown',
                    style: CcTypography.caption.copyWith(
                      color: t.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          list,
        ],
      ),
    );
  }

  Widget _flat(DesignSystemTokens t) {
    if (calls.length <= lazyThreshold) {
      return Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Keyed by position: call ids can repeat, and a script's calls
            // only ever grow at the end.
            for (var i = 0; i < calls.length; i++)
              KeyedSubtree(
                key: ValueKey(i),
                child: itemBuilder(context, calls[i]),
              ),
          ],
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: t.borderSecondary),
        ),
      ),
      child: SizedBox(
        height: maxListHeight,
        child: ListView.builder(
          primary: false,
          padding: EdgeInsets.zero,
          itemCount: calls.length,
          itemBuilder: (context, i) => KeyedSubtree(
            key: ValueKey(i),
            child: itemBuilder(context, calls[i]),
          ),
        ),
      ),
    );
  }
}

/// Every outcome in [tally] with a count, in a fixed order: `6 ok · 1 failed`.
String nestedCallBreakdown(AppLocalizations l10n, NestedCallTally tally) => [
  if (tally.running > 0) l10n.scriptCallsRunning(tally.running),
  if (tally.ok > 0) l10n.scriptCallsOk(tally.ok),
  if (tally.failed > 0) l10n.scriptCallsFailed(tally.failed),
  if (tally.denied > 0) l10n.scriptCallsDenied(tally.denied),
  if (tally.cancelled > 0) l10n.scriptCallsCancelled(tally.cancelled),
].join(' · ');

/// The collapsed row's summary: how many calls, and any that did not go
/// well (`7 calls · 1 failed`). Calls that completed are the expected case
/// and stay out of the line.
String nestedCallSummary(AppLocalizations l10n, NestedCallTally tally) => [
  l10n.scriptCallCount(tally.total),
  if (tally.failed > 0) l10n.scriptCallsFailed(tally.failed),
  if (tally.denied > 0) l10n.scriptCallsDenied(tally.denied),
  if (tally.cancelled > 0) l10n.scriptCallsCancelled(tally.cancelled),
].join(' · ');
