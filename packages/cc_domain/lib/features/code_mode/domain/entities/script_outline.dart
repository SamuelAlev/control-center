import 'package:collection/collection.dart';

const ListEquality<ScriptOutlineNode> _nodeListEquality =
    ListEquality<ScriptOutlineNode>();

const ListEquality<ScriptCallProperty> _propertyListEquality =
    ListEquality<ScriptCallProperty>();

/// A place in a script's text.
///
/// [line] and [column] are 1-based; [column] counts UTF-16 code units from
/// the start of the line. [offset] is the 0-based UTF-16 offset in the whole
/// text. Lines end at `\n`, `\r\n`, `\r`, U+2028 and U+2029.
final class ScriptPosition implements Comparable<ScriptPosition> {
  /// Creates a position. Throws [ArgumentError] when [line] or [column] is
  /// below one or [offset] is negative.
  ScriptPosition({
    required this.line,
    required this.column,
    required this.offset,
  }) {
    if (line < 1) {
      throw ArgumentError.value(line, 'line', 'must be at least 1');
    }
    if (column < 1) {
      throw ArgumentError.value(column, 'column', 'must be at least 1');
    }
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'must not be negative');
    }
  }

  /// The 1-based line.
  final int line;

  /// The 1-based column, in UTF-16 code units of the line.
  final int column;

  /// The 0-based UTF-16 offset in the script.
  final int offset;

  /// Orders by line, then column.
  @override
  int compareTo(ScriptPosition other) =>
      compareLineColumn(other.line, other.column);

  /// Compares this position with the line and column of another place:
  /// negative when this one comes first.
  int compareLineColumn(int otherLine, int otherColumn) =>
      line != otherLine ? line - otherLine : column - otherColumn;

  @override
  bool operator ==(Object other) =>
      other is ScriptPosition &&
      other.line == line &&
      other.column == column &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(line, column, offset);

  @override
  String toString() => '$line:$column';
}

/// A stretch of a script's text: from [start] up to, not including, [end].
final class ScriptSpan {
  /// Creates a span. Throws [ArgumentError] when [end] comes before [start].
  ScriptSpan({required this.start, required this.end}) {
    if (end.offset < start.offset || end.compareTo(start) < 0) {
      throw ArgumentError.value(end, 'end', 'must not come before $start');
    }
  }

  /// The first character.
  final ScriptPosition start;

  /// Just past the last character.
  final ScriptPosition end;

  /// Whether the character at [line] and [column] lies in this span.
  bool contains(int line, int column) =>
      start.compareLineColumn(line, column) <= 0 &&
      end.compareLineColumn(line, column) > 0;

  /// Whether [other] lies wholly in this span.
  bool containsSpan(ScriptSpan other) =>
      start.offset <= other.start.offset && other.end.offset <= end.offset;

  @override
  bool operator ==(Object other) =>
      other is ScriptSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start-$end';
}

/// One place in a script that contains a tool call, read off the script's
/// text by `parseScriptOutline`.
///
/// Nodes form a tree that holds only what contains a tool call. [id] is the
/// node's preorder index in its [ScriptOutline], so it is stable for a given
/// text.
sealed class ScriptOutlineNode {
  ScriptOutlineNode._({
    required this.id,
    required this.span,
    required List<ScriptOutlineNode> children,
  }) : children = List.unmodifiable(children) {
    if (id < 0) {
      throw ArgumentError.value(id, 'id', 'must not be negative');
    }
  }

  /// The node's preorder index in its outline.
  final int id;

  /// Where the node is in the script.
  final ScriptSpan span;

  /// The nodes inside this one, in source order (a call made inside another
  /// call's arguments comes before that call: it runs first).
  final List<ScriptOutlineNode> children;

  /// Whether the calls under this node can happen any number of times: a
  /// loop, a function literal passed to a call, or a named function.
  bool get repeats => false;

  bool _sameAs(ScriptOutlineNode other) =>
      other.runtimeType == runtimeType &&
      other.id == id &&
      other.span == span &&
      _nodeListEquality.equals(other.children, children);

  int get _baseHash => Object.hash(id, span, _nodeListEquality.hash(children));
}

/// One place a tool is called: `tools.NAME(…)`, `tools["NAME"](…)` or
/// `tools[expr](…)`.
///
/// [span] runs from the start of the callee (`tools`, or the parenthesis
/// around it) to the closing parenthesis of the arguments.
final class ScriptCallNode extends ScriptOutlineNode {
  /// Creates a call node.
  ScriptCallNode({
    required super.id,
    required super.span,
    required this.toolName,
    required this.argumentText,
    required List<ScriptCallProperty> properties,
  }) : properties = List.unmodifiable(properties),
       super._(children: const []) {
    if (toolName case final name? when name.isEmpty) {
      throw ArgumentError.value(name, 'toolName', 'must not be empty');
    }
    _checkText(argumentText, 'argumentText');
    if (properties.length > maxProperties) {
      throw ArgumentError.value(
        properties.length,
        'properties',
        'at most $maxProperties',
      );
    }
  }

  /// The most properties a call node carries; later ones are dropped.
  static const int maxProperties = 16;

  /// The name the script calls the tool by (the identifier after `tools.`),
  /// or null when the script computes it.
  final String? toolName;

  /// The arguments' source text, whitespace collapsed and cut at
  /// [ScriptOutline.maxTextLength].
  final String argumentText;

  /// The top-level properties of the argument when the call passes a single
  /// object literal (`{ path: "a", file }`), in source order; empty for any
  /// other argument. Spread, computed and method properties are left out.
  final List<ScriptCallProperty> properties;

  /// The property named [key], or null.
  ScriptCallProperty? property(String key) {
    for (final p in properties) {
      if (p.key == key) {
        return p;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ScriptCallNode &&
      _sameAs(other) &&
      other.toolName == toolName &&
      other.argumentText == argumentText &&
      _propertyListEquality.equals(other.properties, properties);

  @override
  int get hashCode => Object.hash(
    _baseHash,
    toolName,
    argumentText,
    _propertyListEquality.hash(properties),
  );
}

/// One property of a call's object-literal argument, as written.
///
/// A shorthand property (`{ file }`) reads as `file: file`. [value] is the
/// literal's value when the property's value is a plain literal (a string
/// without substitutions, a number, `true`, `false`), so a client can show
/// it as the call will see it; otherwise null, and [source] is all there is.
final class ScriptCallProperty {
  /// Creates a property. Throws [ArgumentError] when [key] is empty, when
  /// [key] or [source] is longer than [ScriptOutline.maxTextLength], or when
  /// [value] is not a [String], [num] or [bool].
  ScriptCallProperty({required this.key, required this.source, this.value}) {
    if (key.isEmpty) {
      throw ArgumentError.value(key, 'key', 'must not be empty');
    }
    _checkText(key, 'key');
    _checkText(source, 'source');
    if (value != null && value is! String && value is! num && value is! bool) {
      throw ArgumentError.value(
        value,
        'value',
        'must be a String, num or bool',
      );
    }
    if (value case final String text) {
      _checkText(text, 'value');
    }
  }

  /// The property's name.
  final String key;

  /// The value's source text, whitespace collapsed and cut at
  /// [ScriptOutline.maxTextLength].
  final String source;

  /// The literal's value, or null when the value is an expression. A string
  /// is cut like [source].
  final Object? value;

  /// Whether the value is a plain literal.
  bool get isLiteral => value != null;

  @override
  bool operator ==(Object other) =>
      other is ScriptCallProperty &&
      other.key == key &&
      other.source == source &&
      other.value == value;

  @override
  int get hashCode => Object.hash(key, source, value);

  @override
  String toString() => '$key: $source';
}

/// The kinds of loop statement.
enum ScriptLoopKind {
  /// `for (init; test; update)`.
  forClassic,

  /// `for (x of xs)`, also `for await`.
  forOf,

  /// `for (k in object)`.
  forIn,

  /// `while (test)`.
  whileLoop,

  /// `do … while (test)`.
  doWhile,
}

/// A loop statement with a call inside.
///
/// Its [children] are the calls of the test and update parts of the header
/// (for a classic `for`, `while` and `do … while`), then the body's. The
/// initialiser of a classic `for` and the iterated value of `for … of` and
/// `for … in` run once, so their calls sit before the loop, not in it.
final class ScriptLoopNode extends ScriptOutlineNode {
  /// Creates a loop node.
  ScriptLoopNode({
    required super.id,
    required super.span,
    required super.children,
    required this.kind,
    required this.label,
    required this.bodySpan,
  }) : super._() {
    _checkText(label, 'label');
    if (!span.containsSpan(bodySpan)) {
      throw ArgumentError.value(bodySpan, 'bodySpan', 'must lie in $span');
    }
  }

  /// Which loop statement.
  final ScriptLoopKind kind;

  /// The header between the parentheses (for `do … while`, the test),
  /// whitespace collapsed and cut at [ScriptOutline.maxTextLength].
  final String label;

  /// Where the body is: the header's calls lie outside it.
  final ScriptSpan bodySpan;

  @override
  bool get repeats => true;

  @override
  bool operator ==(Object other) =>
      other is ScriptLoopNode &&
      _sameAs(other) &&
      other.kind == kind &&
      other.label == label &&
      other.bodySpan == bodySpan;

  @override
  int get hashCode => Object.hash(_baseHash, kind, label, bodySpan);
}

/// A function literal passed to a call (`files.map(async (f) => …)`,
/// `forEach`, `then`, …) whose body contains a call.
///
/// [span] is the whole call the literal is passed to, from the start of
/// [callee] to the closing parenthesis.
final class ScriptEachNode extends ScriptOutlineNode {
  /// Creates an each node.
  ScriptEachNode({
    required super.id,
    required super.span,
    required super.children,
    required this.callee,
    required this.parameters,
    required this.isAsync,
  }) : super._() {
    _checkText(callee, 'callee');
    _checkText(parameters, 'parameters');
  }

  /// The text of what the literal is passed to (`files.map`), whitespace
  /// collapsed and cut at [ScriptOutline.maxTextLength].
  final String callee;

  /// The literal's parameter list as written, without the parentheses.
  final String parameters;

  /// Whether the literal is `async`: its calls can then interleave across
  /// invocations even when nothing awaits them together.
  final bool isAsync;

  @override
  bool get repeats => true;

  @override
  bool operator ==(Object other) =>
      other is ScriptEachNode &&
      _sameAs(other) &&
      other.callee == callee &&
      other.parameters == parameters &&
      other.isAsync == isAsync;

  @override
  int get hashCode => Object.hash(_baseHash, callee, parameters, isAsync);
}

/// The `Promise` combinators that run their inputs together.
enum ScriptParallelKind {
  /// `Promise.all`.
  all,

  /// `Promise.allSettled`.
  allSettled,

  /// `Promise.race`.
  race,

  /// `Promise.any`.
  any,
}

/// `Promise.all`, `allSettled`, `race` or `any` over calls.
///
/// Its [children] are the calls and [ScriptEachNode]s found in its
/// argument.
final class ScriptParallelNode extends ScriptOutlineNode {
  /// Creates a parallel node.
  ScriptParallelNode({
    required super.id,
    required super.span,
    required super.children,
    required this.kind,
  }) : super._();

  /// Which combinator.
  final ScriptParallelKind kind;

  @override
  bool operator ==(Object other) =>
      other is ScriptParallelNode && _sameAs(other) && other.kind == kind;

  @override
  int get hashCode => Object.hash(_baseHash, kind);
}

/// The kinds of construct that choose between arms.
enum ScriptBranchKind {
  /// `if` / `else if` / `else`.
  ifChain,

  /// `switch` with `case` and `default` clauses.
  switchCases,

  /// `test ? a : b`.
  conditional,

  /// `try` with `catch` and/or `finally`. The `try` body is not an arm: its
  /// calls sit inline before this node.
  tryCatch;

  /// Whether taking one arm means the others are not taken. A `switch`
  /// clause may fall through into the next, which still ran.
  bool get exclusive => this != ScriptBranchKind.tryCatch;
}

/// An `if` chain, a `switch`, a conditional expression or a `try` with at
/// least one arm that contains a call. Every arm is listed, also those with
/// no call, so a view can say which were not taken.
final class ScriptBranchNode extends ScriptOutlineNode {
  /// Creates a branch node. Throws [ArgumentError] when [arms] is empty.
  ScriptBranchNode({
    required super.id,
    required super.span,
    required List<ScriptArmNode> arms,
    required this.kind,
  }) : super._(children: arms) {
    if (arms.isEmpty) {
      throw ArgumentError.value(arms, 'arms', 'must not be empty');
    }
  }

  /// Which construct.
  final ScriptBranchKind kind;

  /// The arms, in source order.
  List<ScriptArmNode> get arms => children.cast<ScriptArmNode>();

  @override
  bool operator ==(Object other) =>
      other is ScriptBranchNode && _sameAs(other) && other.kind == kind;

  @override
  int get hashCode => Object.hash(_baseHash, kind);
}

/// The kinds of arm a [ScriptBranchNode] has.
enum ScriptArmKind {
  /// The first arm of an `if` chain.
  ifArm,

  /// An `else if` arm.
  elseIfArm,

  /// The final `else`.
  elseArm,

  /// A `case` clause.
  caseArm,

  /// The `default` clause.
  defaultArm,

  /// The arm after `?` of a conditional expression.
  conditionalThen,

  /// The arm after `:` of a conditional expression.
  conditionalElse,

  /// A `catch` clause.
  catchArm,

  /// A `finally` clause.
  finallyArm,
}

/// One arm of a [ScriptBranchNode].
///
/// The calls in an `else if` test sit in its arm (they run only when the arms
/// before it were not taken); those in the first `if` test sit before the
/// branch.
final class ScriptArmNode extends ScriptOutlineNode {
  /// Creates an arm node.
  ScriptArmNode({
    required super.id,
    required super.span,
    required super.children,
    required this.kind,
    required this.condition,
  }) : super._() {
    if (condition case final text?) {
      _checkText(text, 'condition');
    }
  }

  /// Which arm.
  final ScriptArmKind kind;

  /// The arm's test, whitespace collapsed and cut at
  /// [ScriptOutline.maxTextLength]: the `if` / `else if` test, the `case`
  /// value, the conditional's test (on its first arm only) or the `catch`
  /// parameter. Null when there is none.
  final String? condition;

  @override
  bool operator ==(Object other) =>
      other is ScriptArmNode &&
      _sameAs(other) &&
      other.kind == kind &&
      other.condition == condition;

  @override
  int get hashCode => Object.hash(_baseHash, kind, condition);
}

/// A function declaration, or a function literal bound to a name
/// (`const f = async (x) => …`, `f = function …`, `{ f: (x) => … }`), whose
/// body contains a call. Its calls belong to it wherever it is called from.
final class ScriptFunctionNode extends ScriptOutlineNode {
  /// Creates a function node.
  ScriptFunctionNode({
    required super.id,
    required super.span,
    required super.children,
    required this.name,
    required this.parameters,
  }) : super._() {
    _checkText(name, 'name');
    _checkText(parameters, 'parameters');
  }

  /// The function's name.
  final String name;

  /// The parameter list as written, without the parentheses.
  final String parameters;

  @override
  bool get repeats => true;

  @override
  bool operator ==(Object other) =>
      other is ScriptFunctionNode &&
      _sameAs(other) &&
      other.name == name &&
      other.parameters == parameters;

  @override
  int get hashCode => Object.hash(_baseHash, name, parameters);
}

/// Why a script has no outline.
enum ScriptOutlineFailure {
  /// Longer than any script the runner accepts.
  tooLong,

  /// A string, template literal, regular expression or block comment that
  /// does not end.
  unterminated,

  /// Brackets that do not match.
  unbalanced,

  /// Nested deeper than the parser follows.
  tooDeep,

  /// More nodes than a view can use.
  tooManyNodes,

  /// More work than the parser spends on a text of its length.
  tooComplex,
}

/// What a script will do, read off its text: a tree of the places that
/// contain tool calls, or [failure] when the text could not be followed.
final class ScriptOutline {
  /// Creates a parsed outline. Throws [ArgumentError] when the node ids are
  /// not the preorder indices 0, 1, 2, ….
  ScriptOutline({required List<ScriptOutlineNode> nodes})
    : this._(List.unmodifiable(nodes), null, _preorderCount(nodes));

  /// An outline for a script that could not be followed.
  ScriptOutline.unparsed(ScriptOutlineFailure failure)
    : this._(const [], failure, 0);

  ScriptOutline._(this.nodes, this.failure, this.nodeCount);

  /// The longest text a node carries (argument, label, condition, callee,
  /// parameters); longer text is cut and ends with `…`.
  static const int maxTextLength = 120;

  /// The top-level nodes, in source order. Empty when [unparsed].
  final List<ScriptOutlineNode> nodes;

  /// Why there is no outline, or null when the script was parsed.
  final ScriptOutlineFailure? failure;

  /// The number of nodes in the tree.
  final int nodeCount;

  /// Whether the script could not be followed: a view then lists its calls
  /// flat.
  bool get unparsed => failure != null;

  /// Every node, in preorder: `all[n].id == n`.
  late final List<ScriptOutlineNode> all = List.unmodifiable(_preorder(nodes));

  /// Every call node, in preorder.
  late final List<ScriptCallNode> calls = List.unmodifiable(
    all.whereType<ScriptCallNode>(),
  );

  @override
  bool operator ==(Object other) =>
      other is ScriptOutline &&
      other.failure == failure &&
      _nodeListEquality.equals(other.nodes, nodes);

  @override
  int get hashCode => Object.hash(failure, _nodeListEquality.hash(nodes));
}

int _preorderCount(List<ScriptOutlineNode> nodes) {
  var next = 0;
  for (final node in _preorder(nodes)) {
    if (node.id != next) {
      throw ArgumentError.value(
        node.id,
        'nodes',
        'node ids must be preorder indices; expected $next',
      );
    }
    next++;
  }
  return next;
}

List<ScriptOutlineNode> _preorder(List<ScriptOutlineNode> nodes) {
  final out = <ScriptOutlineNode>[];
  void walk(ScriptOutlineNode node) {
    out.add(node);
    node.children.forEach(walk);
  }

  nodes.forEach(walk);
  return out;
}

void _checkText(String text, String name) {
  if (text.length > ScriptOutline.maxTextLength) {
    throw ArgumentError.value(
      text.length,
      name,
      'must be at most ${ScriptOutline.maxTextLength} characters',
    );
  }
}
