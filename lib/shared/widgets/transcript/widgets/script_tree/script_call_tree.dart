import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_lines.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/transcript/util/nested_calls.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_hidden_calls.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_pending_row.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_tree_opened.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_tree_rows.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_tree_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A script's calls laid over its structure: the calls it made, drawn by
/// [itemBuilder] as the very rows a direct call gets, the calls it has not
/// reached as quiet rows worded like the rows they will become, and loops,
/// eaches, parallel groups, functions and branch arms as headers with their
/// rows under them ([scriptTreeLines] decides the lines and the folds).
///
/// Every line is keyed, so a queued row becomes the made row in place and
/// the list does not jump while the script runs. Groups the reader opens
/// stay open in [scriptTreeOpenedProvider] under [scope].
class ScriptCallTree<T> extends ConsumerWidget {
  /// Creates the tree for [view].
  const ScriptCallTree({
    super.key,
    required this.view,
    required this.scope,
    required this.stateOf,
    required this.keepInSight,
    required this.toolOf,
    required this.toolLabel,
    required this.itemBuilder,
    required this.codeFont,
  });

  /// The script's calls over its outline.
  final ScriptRunView<T> view;

  /// Which tree this is, for the groups the reader opened.
  final String scope;

  /// How a made call stands.
  final NestedCallState Function(T call) stateOf;

  /// Whether a made call stays in sight in a folded group for another reason
  /// than its state (running, failed and denied calls always do): a person
  /// or a standing approval let it run.
  final bool Function(T call) keepInSight;

  /// The tool a made call was made to, raw.
  final String? Function(T call) toolOf;

  /// A tool's name as the rows name it, for the hidden-calls control.
  final String Function(String tool) toolLabel;

  /// Draws a made call.
  final Widget Function(BuildContext context, T call) itemBuilder;

  /// Mono font for code.
  final String codeFont;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = _linesOf(ref, view, scope, stateOf, keepInSight, toolOf);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          KeyedSubtree(
            key: ValueKey(line.key),
            child: scriptTreeLine(
              context,
              ref,
              line,
              scope: scope,
              stateOf: stateOf,
              toolLabel: toolLabel,
              itemBuilder: itemBuilder,
              codeFont: codeFont,
            ),
          ),
      ],
    );
  }
}

/// [ScriptCallTree] as a sliver that builds only the lines in view, for a
/// page that lists thousands of calls.
class ScriptCallTreeSliver<T> extends ConsumerWidget {
  /// Creates the sliver for [view]; each line is wrapped by [wrap].
  const ScriptCallTreeSliver({
    super.key,
    required this.view,
    required this.scope,
    required this.stateOf,
    required this.keepInSight,
    required this.toolOf,
    required this.toolLabel,
    required this.itemBuilder,
    required this.codeFont,
    required this.wrap,
  });

  /// See [ScriptCallTree.view].
  final ScriptRunView<T> view;

  /// See [ScriptCallTree.scope].
  final String scope;

  /// See [ScriptCallTree.stateOf].
  final NestedCallState Function(T call) stateOf;

  /// See [ScriptCallTree.keepInSight].
  final bool Function(T call) keepInSight;

  /// See [ScriptCallTree.toolOf].
  final String? Function(T call) toolOf;

  /// See [ScriptCallTree.toolLabel].
  final String Function(String tool) toolLabel;

  /// See [ScriptCallTree.itemBuilder].
  final Widget Function(BuildContext context, T call) itemBuilder;

  /// See [ScriptCallTree.codeFont].
  final String codeFont;

  /// Places a line on the page (its gutter).
  final Widget Function(Widget line) wrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = _linesOf(ref, view, scope, stateOf, keepInSight, toolOf);
    return SliverList.builder(
      itemCount: lines.length,
      findChildIndexCallback: (key) {
        if (key case ValueKey<String>(:final value)) {
          final i = lines.indexWhere((line) => line.key == value);
          return i < 0 ? null : i;
        }
        return null;
      },
      itemBuilder: (context, i) => KeyedSubtree(
        key: ValueKey(lines[i].key),
        child: wrap(
          scriptTreeLine(
            context,
            ref,
            lines[i],
            scope: scope,
            stateOf: stateOf,
            toolLabel: toolLabel,
            itemBuilder: itemBuilder,
            codeFont: codeFont,
          ),
        ),
      ),
    );
  }
}

List<ScriptTreeLine<T>> _linesOf<T>(
  WidgetRef ref,
  ScriptRunView<T> view,
  String scope,
  NestedCallState Function(T call) stateOf,
  bool Function(T call) keepInSight,
  String? Function(T call) toolOf,
) => scriptTreeLines(
  view: view,
  mustShow: (call) => scriptCallMustShow(stateOf(call)) || keepInSight(call),
  toolOf: toolOf,
  revealed:
      ref.watch(scriptTreeOpenedProvider.select((o) => o[scope])) ?? const {},
);

/// One line of a script call tree, indented to its depth.
Widget scriptTreeLine<T>(
  BuildContext context,
  WidgetRef ref,
  ScriptTreeLine<T> line, {
  required String scope,
  required NestedCallState Function(T call) stateOf,
  required String Function(String tool) toolLabel,
  required Widget Function(BuildContext context, T call) itemBuilder,
  required String codeFont,
}) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final l10n = AppLocalizations.of(context);
  final Widget body = switch (line) {
    ScriptTreeMadeLine<T>(:final row) =>
      row.arm == null
          ? itemBuilder(context, line.call)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                itemBuilder(context, line.call),
                ScriptArmCaption(
                  code: scriptArmCode(row.arm!),
                  codeFont: codeFont,
                ),
              ],
            ),
    ScriptTreePendingLine<T>(:final site, :final row) => ScriptPendingRow(
      site: site,
      state: row.state,
      codeFont: codeFont,
    ),
    ScriptTreeHeaderLine<T>(:final group) => _header(
      l10n,
      group,
      stateOf,
      codeFont,
    ),
    ScriptTreeHiddenLine<T>(:final foldKey, :final count, :final byTool) =>
      ScriptHiddenCallsButton(
        count: count,
        tools: scriptHiddenTools(l10n, byTool, toolLabel),
        onPressed: () =>
            ref.read(scriptTreeOpenedProvider.notifier).open(scope, foldKey),
      ),
    ScriptTreeRuleLine<T>() => const ScriptIterationRule(),
    ScriptTreeUnplacedLine<T>() => Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xxs,
      ),
      child: Text(
        l10n.scriptCallsUnplaced,
        style: CcTypography.caption.copyWith(
          color: t.textTertiary,
          fontSize: 10,
        ),
      ),
    ),
  };
  return ScriptTreeIndent(depth: line.depth, child: body);
}

Widget _header<T>(
  AppLocalizations l10n,
  ScriptRunGroup<T> group,
  NestedCallState Function(T call) stateOf,
  String codeFont,
) {
  final node = group.node;
  final notReached =
      group.counts.made == 0 &&
      (group.state == ScriptStepState.queued ||
          group.state == ScriptStepState.skipped);
  final alarm = group.payloads.any((call) {
    final state = stateOf(call);
    return state == NestedCallState.failed || state == NestedCallState.denied;
  });
  return ScriptGroupHeader(
    icon: scriptNodeIcon(node),
    kind: scriptGroupKind(l10n, node),
    code: node is ScriptArmNode ? scriptArmCode(node) : scriptGroupCode(node),
    trailing: node is ScriptArmNode && notReached
        ? scriptPendingWord(l10n, group.state)!
        : scriptGroupTally(l10n, group, stateOf),
    state: group.state,
    alarm: alarm,
    codeFont: codeFont,
  );
}
