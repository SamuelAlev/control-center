import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_lines.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_text.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/script_calls.dart';
import 'package:cc_remote/widgets/script_hidden_calls.dart';
import 'package:cc_remote/widgets/script_tree_rows.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A made call on the phone: its position in the transcript and its segment.
typedef PhoneScriptCall = (int, ToolSegment);

/// How far the reader opened the long groups on the phone, by tree scope,
/// then by group key: how many of the group's hidden calls are shown. Held
/// above the rows so an opened group survives the script row closing and
/// reopening, the turn scrolling away and back, and streaming rebuilds. In
/// memory, bounded to [maxScopes] trees.
class PhoneScriptTreeOpened extends Notifier<Map<String, Map<String, int>>> {
  /// How many trees keep their opened groups.
  static const int maxScopes = 128;

  @override
  Map<String, Map<String, int>> build() => const {};

  /// Shows [scriptFoldStep] more hidden calls of the group [key] of the
  /// tree [scope].
  void open(String scope, String key) {
    final current = state[scope] ?? const <String, int>{};
    final next = {
      for (final entry in state.entries)
        if (entry.key != scope) entry.key: entry.value,
      scope: {...current, key: (current[key] ?? 0) + scriptFoldStep},
    };
    while (next.length > maxScopes) {
      next.remove(next.keys.first);
    }
    state = next;
  }
}

/// See [PhoneScriptTreeOpened].
final phoneScriptTreeOpenedProvider =
    NotifierProvider<PhoneScriptTreeOpened, Map<String, Map<String, int>>>(
      PhoneScriptTreeOpened.new,
    );

/// A script's calls laid over its structure, in the phone's compact style:
/// made calls are the very rows a direct call gets ([rowBuilder]), calls not
/// yet reached are quiet rows worded like the rows they become, and loops,
/// eaches, parallel groups, functions and branch arms are headers over their
/// rows. Lines and folds come from [scriptTreeLines], as on the desktop.
///
/// Lines are keyed, so a queued row becomes the made row in place.
class PhoneScriptTree extends ConsumerWidget {
  /// Creates the tree for [view].
  const PhoneScriptTree({
    super.key,
    required this.view,
    required this.scope,
    required this.rowBuilder,
  });

  /// The script's calls over its outline.
  final ScriptRunView<PhoneScriptCall> view;

  /// Which tree this is, for the groups the reader opened.
  final String scope;

  /// Draws a made call.
  final Widget Function(PhoneScriptCall call) rowBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = scriptTreeLines(
      view: view,
      // A transcript row does not say whether a person approved it.
      mustShow: (call) => switch (nestedCallStateOf(call.$2)) {
        NestedCallState.running ||
        NestedCallState.failed ||
        NestedCallState.denied => true,
        _ => false,
      },
      toolOf: (call) => call.$2.toolName,
      revealed:
          ref.watch(
            phoneScriptTreeOpenedProvider.select((opened) => opened[scope]),
          ) ??
          const {},
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          KeyedSubtree(
            key: ValueKey(line.key),
            child: _indent(context, line.depth, _line(context, ref, line)),
          ),
      ],
    );
  }

  Widget _line(
    BuildContext context,
    WidgetRef ref,
    ScriptTreeLine<PhoneScriptCall> line,
  ) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return switch (line) {
      ScriptTreeMadeLine(:final row) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rowBuilder(line.call),
          if (row.arm case final arm?)
            PhoneScriptArmCaption(code: scriptArmCode(arm)),
        ],
      ),
      ScriptTreePendingLine(:final site, :final row) => PhoneScriptPendingRow(
        site: site,
        state: row.state,
      ),
      ScriptTreeHeaderLine(:final group) => PhoneScriptGroupHeader(
        node: group.node,
        state: group.state,
        trailing:
            group.node is ScriptArmNode &&
                group.counts.made == 0 &&
                group.state != ScriptStepState.running
            ? phoneScriptPendingWord(l10n, group.state) ?? ''
            : _tally(l10n, group),
      ),
      ScriptTreeHiddenLine(:final foldKey, :final count, :final byTool) =>
        PhoneScriptHiddenCalls(
          count: count,
          tools: phoneScriptHiddenTools(l10n, byTool),
          onPressed: () => ref
              .read(phoneScriptTreeOpenedProvider.notifier)
              .open(scope, foldKey),
        ),
      ScriptTreeRuleLine() => Padding(
        padding: const EdgeInsetsDirectional.only(start: 10, top: 6),
        child: SizedBox(height: 1, child: ColoredBox(color: t.borderSecondary)),
      ),
      ScriptTreeUnplacedLine() => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          l10n.scriptCallsUnplaced,
          style: TextStyle(fontSize: 11, color: t.textTertiary),
        ),
      ),
    };
  }

  /// One guide hairline per group the line sits in, mirrored with the text;
  /// at most [scriptTreeMaxIndent] of them.
  Widget _indent(BuildContext context, int depth, Widget child) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    var out = child;
    for (var i = 0; i < depth && i < scriptTreeMaxIndent; i++) {
      out = Container(
        margin: const EdgeInsetsDirectional.only(start: 6),
        padding: const EdgeInsetsDirectional.only(start: 8),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: t.borderSecondary),
          ),
        ),
        child: out,
      );
    }
    return out;
  }

  String _tally(AppLocalizations l10n, ScriptRunGroup<PhoneScriptCall> group) {
    final tally = NestedCallTally.of([
      for (final (_, call) in group.payloads) call,
    ]);
    final counts = group.counts;
    return [
      if (tally.running > 0) l10n.scriptCallsRunning(tally.running),
      if (tally.ok > 0) l10n.scriptCallsOk(tally.ok),
      if (tally.failed > 0) l10n.scriptCallsFailed(tally.failed),
      if (tally.denied > 0) l10n.scriptCallsDenied(tally.denied),
      if (tally.cancelled > 0) l10n.scriptCallsCancelled(tally.cancelled),
      if (counts.queued > 0) l10n.scriptCallsQueued(counts.queued),
      if (counts.skipped > 0) l10n.scriptCallsSkipped(counts.skipped),
    ].join(' · ');
  }
}
