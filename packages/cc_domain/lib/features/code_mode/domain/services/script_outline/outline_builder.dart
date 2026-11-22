import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';

// The last stage of the outline parser: the nodes the recogniser collects,
// and the outline they become.

/// What a [DraftNode] becomes.
enum DraftKind { call, loop, each, parallel, branch, arm, function }

/// A node while the outline is built; [freezeOutline] turns it into a
/// [ScriptOutlineNode] with its preorder id.
final class DraftNode {
  /// Creates a node of [kind] over `[start, end)` holding [children].
  DraftNode(this.kind, this.start, this.end, this.children);

  /// What it becomes.
  final DraftKind kind;

  /// Its first offset.
  final int start;

  /// The offset after it.
  final int end;

  /// The nodes inside it.
  final List<DraftNode> children;

  /// A call's static tool name.
  String? toolName;

  /// A call's argument text, a loop's header, an each node's callee or
  /// a function's name.
  String text = '';

  /// A call's properties.
  List<ScriptCallProperty> properties = const [];

  /// An arm's condition.
  String? condition;

  /// A function's parameters.
  String parameters = '';

  /// Whether an each node's function is `async`.
  bool isAsync = false;

  /// A loop body's first offset.
  int bodyStart = 0;

  /// The offset after a loop's body.
  int bodyEnd = 0;

  /// A loop's kind.
  ScriptLoopKind? loopKind;

  /// A parallel group's kind.
  ScriptParallelKind? parallelKind;

  /// A branch's kind.
  ScriptBranchKind? branchKind;

  /// An arm's kind.
  ScriptArmKind? armKind;
}

/// The outline of [top], the nodes of [src]: preorder ids and positions.
ScriptOutline freezeOutline(String src, List<DraftNode> top) =>
    _Freezer(src).outline(top);

/// Turns [DraftNode]s into [ScriptOutlineNode]s with preorder ids and positions.
final class _Freezer {
  _Freezer(String src) : _lineStarts = _lineStartsOf(src);

  final List<int> _lineStarts;
  int _next = 0;

  static List<int> _lineStartsOf(String src) {
    final starts = <int>[0];
    final n = src.length;
    for (var i = 0; i < n; i++) {
      final c = src.codeUnitAt(i);
      if (c == 0x0D) {
        if (i + 1 < n && src.codeUnitAt(i + 1) == 0x0A) {
          i++;
        }
        starts.add(i + 1);
      } else if (c == 0x0A || c == 0x2028 || c == 0x2029) {
        starts.add(i + 1);
      }
    }
    return starts;
  }

  ScriptPosition _position(int offset) {
    var lo = 0;
    var hi = _lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return ScriptPosition(
      line: lo + 1,
      column: offset - _lineStarts[lo] + 1,
      offset: offset,
    );
  }

  ScriptSpan _span(int start, int end) =>
      ScriptSpan(start: _position(start), end: _position(end));

  ScriptOutline outline(List<DraftNode> top) =>
      ScriptOutline(nodes: [for (final node in top) _freeze(node)]);

  ScriptOutlineNode _freeze(DraftNode n) {
    final id = _next++;
    final span = _span(n.start, n.end);
    final children = n.kind == DraftKind.call
        ? const <ScriptOutlineNode>[]
        : [for (final child in n.children) _freeze(child)];
    return switch (n.kind) {
      DraftKind.call => ScriptCallNode(
        id: id,
        span: span,
        toolName: n.toolName,
        argumentText: n.text,
        properties: n.properties,
      ),
      DraftKind.loop => ScriptLoopNode(
        id: id,
        span: span,
        children: children,
        kind: n.loopKind!,
        label: n.text,
        bodySpan: _span(n.bodyStart, n.bodyEnd),
      ),
      DraftKind.each => ScriptEachNode(
        id: id,
        span: span,
        children: children,
        callee: n.text,
        parameters: n.parameters,
        isAsync: n.isAsync,
      ),
      DraftKind.parallel => ScriptParallelNode(
        id: id,
        span: span,
        children: children,
        kind: n.parallelKind!,
      ),
      DraftKind.branch => ScriptBranchNode(
        id: id,
        span: span,
        arms: children.cast<ScriptArmNode>(),
        kind: n.branchKind!,
      ),
      DraftKind.arm => ScriptArmNode(
        id: id,
        span: span,
        children: children,
        kind: n.armKind!,
        condition: n.condition,
      ),
      DraftKind.function => ScriptFunctionNode(
        id: id,
        span: span,
        children: children,
        name: n.text,
        parameters: n.parameters,
      ),
    };
  }
}
