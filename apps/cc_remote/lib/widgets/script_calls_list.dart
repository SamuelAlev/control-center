import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_source.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/script_calls.dart';
import 'package:cc_remote/widgets/script_tree.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The calls a script made, inside the row of the call that ran it, under a
/// "Tool calls" caption and their tally.
///
/// Under a [script] whose calls say where they were made, they are laid over
/// its structure ([PhoneScriptTree]), with what it has not reached yet as
/// queued rows. Otherwise (no script text, an outline the parser cannot
/// follow, calls with no site) they are a flat list in call order, keyed by
/// position since call ids can repeat; past [lazyThreshold] that list
/// scrolls inside a bounded region. A script with no tool calls shows
/// nothing.
class PhoneScriptCalls extends StatelessWidget {
  /// Creates the list.
  const PhoneScriptCalls({
    super.key,
    required this.script,
    required this.calls,
    required this.ended,
    required this.rowBuilder,
  });

  /// Past this many calls the flat list scrolls inside [maxListHeight].
  static const int lazyThreshold = 24;

  /// The height of that region.
  static const double maxListHeight = 400;

  /// The `repl` call that ran the script, or null for calls under any other
  /// parent (always the flat list).
  final ToolSegment? script;

  /// The calls, with their transcript positions, in the order made.
  final List<PhoneScriptCall> calls;

  /// Whether the script has stopped: nothing it did not reach is queued.
  final bool ended;

  /// Draws a made call.
  final Widget Function(PhoneScriptCall call) rowBuilder;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final code = script?.inputs?['code'];
    final view = script == null
        ? null
        : scriptRunViewOrFlat<PhoneScriptCall>(
            source: code is String ? code : null,
            calls: [
              for (final entry in calls)
                ScriptRunCall(
                  payload: entry,
                  toolName: entry.$2.toolName,
                  line: entry.$2.callSite?.line,
                  column: entry.$2.callSite?.column,
                  running:
                      nestedCallStateOf(entry.$2) == NestedCallState.running,
                  failed: switch (nestedCallStateOf(entry.$2)) {
                    NestedCallState.running || NestedCallState.ok => false,
                    _ => true,
                  },
                  startMs: entry.$2.startedAt.millisecondsSinceEpoch,
                  endMs: entry.$2.durationMs == null
                      ? null
                      : entry.$2.startedAt.millisecondsSinceEpoch +
                            entry.$2.durationMs!,
                ),
            ],
            ended: ended,
          );
    if (view == null ? calls.isEmpty : view.counts.total == 0) {
      return const SizedBox.shrink();
    }
    Widget row(PhoneScriptCall entry) => Padding(
      key: ValueKey(entry.$1),
      padding: const EdgeInsets.only(top: 6),
      child: rowBuilder(entry),
    );
    final tally = NestedCallTally.of([for (final (_, call) in calls) call]);
    final breakdown = [
      if (tally.running > 0) l10n.scriptCallsRunning(tally.running),
      if (tally.ok > 0) l10n.scriptCallsOk(tally.ok),
      if (tally.failed > 0) l10n.scriptCallsFailed(tally.failed),
      if (tally.denied > 0) l10n.scriptCallsDenied(tally.denied),
      if (tally.cancelled > 0) l10n.scriptCallsCancelled(tally.cancelled),
      if (view != null && view.counts.queued > 0)
        l10n.scriptCallsQueued(view.counts.queued),
      if (view != null && view.counts.skipped > 0)
        l10n.scriptCallsSkipped(view.counts.skipped),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: l10n.scriptToolCalls,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: t.fgTertiary,
                  ),
                ),
                TextSpan(
                  text: '  $breakdown',
                  style: TextStyle(fontSize: 10, color: t.textTertiary),
                ),
              ],
            ),
          ),
          if (view != null)
            PhoneScriptTree(
              view: view,
              // Call ids repeat across turns; the start time tells them apart.
              scope:
                  '${script!.toolCallId}@'
                  '${script!.startedAt.microsecondsSinceEpoch}',
              rowBuilder: row,
            )
          else if (calls.length <= lazyThreshold)
            for (final call in calls) row(call)
          else
            SizedBox(
              height: maxListHeight,
              child: ListView.builder(
                primary: false,
                padding: EdgeInsets.zero,
                itemCount: calls.length,
                itemBuilder: (context, i) => row(calls[i]),
              ),
            ),
        ],
      ),
    );
  }
}
