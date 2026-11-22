import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:collection/collection.dart';

/// More made calls than this in one group, and its middle folds away.
const int scriptFoldAbove = 8;

/// The made calls a folded group keeps at its start.
const int scriptFoldKeepFirst = 2;

/// The made calls a folded group keeps at its end.
const int scriptFoldKeepLast = 3;

/// How many hidden calls one press of a group's hidden-calls control shows.
const int scriptFoldStep = 100;

/// How many levels a client steps a line in. Deeper lines (a script can
/// nest groups up to the parser's recursion bound) are drawn at this depth,
/// so a row stays readable and costs the same however deep it sits.
const int scriptTreeMaxIndent = 8;

/// The fold key of the calls listed after the tree.
const String scriptUnattachedFoldKey = 'unattached';

/// One line of a script's call tree, in reading order, with how deep it sits.
///
/// A client draws the lines one after another, indenting each by [depth]:
/// a column for a short tree, a lazily built list for a long one. [key] is
/// stable while the script runs, so a queued line becomes its made line in
/// place.
sealed class ScriptTreeLine<T> {
  const ScriptTreeLine({required this.key, required this.depth});

  /// Stable identity of the line.
  final String key;

  /// How many groups the line sits inside.
  final int depth;
}

/// A call the script made. Its row's `arm` is the branch arm it was made in, shown
/// under it when the arm itself is folded into a repeating group.
final class ScriptTreeMadeLine<T> extends ScriptTreeLine<T> {
  /// Creates the line for [row].
  const ScriptTreeMadeLine({
    required super.key,
    required super.depth,
    required this.row,
  });

  /// The made row; its payload is non-null.
  final ScriptRunRow<T> row;

  /// The call.
  T get call => row.payload as T;
}

/// A call the script has not made: queued, or skipped.
final class ScriptTreePendingLine<T> extends ScriptTreeLine<T> {
  /// Creates the line for [row].
  const ScriptTreePendingLine({
    required super.key,
    required super.depth,
    required this.row,
  });

  /// The pending row; its site is non-null.
  final ScriptRunRow<T> row;

  /// The call node it stands for.
  ScriptCallNode get site => row.site!;
}

/// The header of a loop, each, parallel group, function or branch arm.
final class ScriptTreeHeaderLine<T> extends ScriptTreeLine<T> {
  /// Creates the header of [group].
  const ScriptTreeHeaderLine({
    required super.key,
    required super.depth,
    required this.group,
  });

  /// The group.
  final ScriptRunGroup<T> group;
}

/// The control that opens [count] calls folded out of the group [foldKey],
/// and says what they are ([byTool]).
final class ScriptTreeHiddenLine<T> extends ScriptTreeLine<T> {
  /// Creates the control.
  const ScriptTreeHiddenLine({
    required super.key,
    required super.depth,
    required this.foldKey,
    required this.count,
    required this.byTool,
  });

  /// The group to open.
  final String foldKey;

  /// How many made calls it hides.
  final int count;

  /// The hidden calls by tool, the rarest first (ties in the order first
  /// hidden), so the one call that differs from a thousand others shows.
  /// The counts add up to [count]; a call whose tool is unknown counts
  /// under null.
  final List<({String? tool, int count})> byTool;
}

/// The hairline where a new iteration of a repeating group starts.
final class ScriptTreeRuleLine<T> extends ScriptTreeLine<T> {
  /// Creates the rule.
  const ScriptTreeRuleLine({required super.key, required super.depth});
}

/// The caption over the calls that could not be placed in the script.
final class ScriptTreeUnplacedLine<T> extends ScriptTreeLine<T> {
  /// Creates the caption.
  const ScriptTreeUnplacedLine({required super.key, required super.depth});
}

/// [view] as lines.
///
/// A group with more than [scriptFoldAbove] made calls directly in it folds
/// its middle, keeping the first [scriptFoldKeepFirst] and the last
/// [scriptFoldKeepLast] made calls, every call for which [mustShow] holds
/// (running, waiting for a person, failed, denied), and for each of those
/// in the folded middle the call that started its iteration, so a failure
/// says which item it was. Each run of hidden calls becomes one
/// [ScriptTreeHiddenLine], which tallies them by [toolOf]. [revealed] holds, per group key, how many of
/// its hidden calls the reader has asked to see (a multiple of
/// [scriptFoldStep]): they come back from the top of the hidden calls, and
/// the control stays under them with the count still hidden. A branch is
/// drawn as its arms only.
List<ScriptTreeLine<T>> scriptTreeLines<T>({
  required ScriptRunView<T> view,
  required bool Function(T call) mustShow,
  required String? Function(T call) toolOf,
  required Map<String, int> revealed,
}) {
  final out = <ScriptTreeLine<T>>[];

  void list(List<ScriptRunNode<T>> nodes, String? foldKey, int depth) {
    final keep = _kept(nodes, foldKey, revealed, mustShow);
    var hidden = 0;
    var shown = 0;
    // Insertion order is the order first hidden.
    final tools = <String?, int>{};
    void flush() {
      if (hidden == 0) {
        return;
      }
      final order = tools.keys.toList();
      final byTool = [
        for (final tool in order) (tool: tool, count: tools[tool]!),
      ];
      mergeSort(byTool, compare: (a, b) => a.count.compareTo(b.count));
      out.add(
        ScriptTreeHiddenLine(
          key: '$foldKey#hidden$shown',
          depth: depth,
          foldKey: foldKey!,
          count: hidden,
          byTool: List.unmodifiable(byTool),
        ),
      );
      hidden = 0;
      tools.clear();
    }

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (keep != null && !keep[i]) {
        hidden++;
        final tool = toolOf((node as ScriptRunRow<T>).payload as T);
        tools[tool] = (tools[tool] ?? 0) + 1;
        continue;
      }
      flush();
      if (node is ScriptRunRow<T> && node.startsIteration && shown > 0) {
        out.add(ScriptTreeRuleLine(key: '${node.key}#iteration', depth: depth));
      }
      switch (node) {
        case ScriptRunRow<T>(made: true):
          out.add(ScriptTreeMadeLine(key: node.key, depth: depth, row: node));
        case ScriptRunRow<T>():
          out.add(
            ScriptTreePendingLine(key: node.key, depth: depth, row: node),
          );
        case ScriptRunGroup<T>(node: ScriptBranchNode()):
          for (final arm in node.children.whereType<ScriptRunGroup<T>>()) {
            out.add(
              ScriptTreeHeaderLine(key: arm.key, depth: depth, group: arm),
            );
            list(arm.children, arm.key, depth + 1);
          }
        case ScriptRunGroup<T>():
          out.add(
            ScriptTreeHeaderLine(key: node.key, depth: depth, group: node),
          );
          list(node.children, node.key, depth + 1);
      }
      shown++;
    }
    flush();
  }

  list(view.nodes, null, 0);
  if (view.unattached.isNotEmpty) {
    if (view.nodes.isNotEmpty) {
      out.add(
        const ScriptTreeUnplacedLine(key: 'unattached#caption', depth: 0),
      );
    }
    list(view.unattached, scriptUnattachedFoldKey, 0);
  }
  return out;
}

/// Which of [nodes] stay in sight, or null when the list does not fold.
List<bool>? _kept<T>(
  List<ScriptRunNode<T>> nodes,
  String? foldKey,
  Map<String, int> revealed,
  bool Function(T call) mustShow,
) {
  if (foldKey == null) {
    return null;
  }
  var made = 0;
  for (final node in nodes) {
    if (node is ScriptRunRow<T> && node.made) {
      made++;
    }
  }
  if (made <= scriptFoldAbove) {
    return null;
  }
  final keep = List<bool>.filled(nodes.length, true);
  final alarms = <int>[];
  var ordinal = -1;
  for (var i = 0; i < nodes.length; i++) {
    final node = nodes[i];
    if (node is! ScriptRunRow<T> || !node.made) {
      continue;
    }
    ordinal++;
    if (ordinal < scriptFoldKeepFirst || ordinal >= made - scriptFoldKeepLast) {
      continue;
    }
    if (mustShow(node.payload as T)) {
      alarms.add(i);
      continue;
    }
    keep[i] = false;
  }
  // A call kept in the folded middle brings the call its iteration began
  // with, when that is another call.
  for (final i in alarms) {
    for (var j = i; j >= 0; j--) {
      final node = nodes[j];
      if (node is ScriptRunRow<T> && node.startsIteration) {
        keep[j] = true;
        break;
      }
    }
  }
  // The calls the reader asked for, from the top of the hidden ones.
  var reveal = revealed[foldKey] ?? 0;
  for (var i = 0; i < keep.length && reveal > 0; i++) {
    if (!keep[i]) {
      keep[i] = true;
      reveal--;
    }
  }
  return keep.contains(false) ? keep : null;
}
