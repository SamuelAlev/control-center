import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline/outline_builder.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline/outline_lexer.dart';

// The recogniser's expressions and calls: tool calls and their arguments,
// callbacks, `Promise` combinators, function literals, conditionals, where
// an expression ends, and the text of a range. [OutlineWalker] adds the
// statements.

/// How deep statement and expression recognition may recurse inside one
/// bracket level (`if (a) if (b) …`, `a ? b : c ? d : …`).
const int _maxRecursion = 256;

/// Words that never end a callee: a group after them is not a call's
/// arguments.
const Set<String> outlineNotCallees = {
  'if',
  'for',
  'while',
  'switch',
  'catch',
  'with',
  'return',
  'typeof',
  'void',
  'delete',
  'await',
  'yield',
  'in',
  'of',
  'instanceof',
  'new',
  'throw',
  'case',
  'do',
  'else',
  'function',
};

// Words after which a line break never ends the statement.
const Set<String> _continuingWords = {
  'await',
  'typeof',
  'void',
  'delete',
  'new',
  'in',
  'of',
  'instanceof',
  'case',
  'extends',
};

const Map<String, ScriptParallelKind> _parallelKinds = {
  'all': ScriptParallelKind.all,
  'allSettled': ScriptParallelKind.allSettled,
  'race': ScriptParallelKind.race,
  'any': ScriptParallelKind.any,
};

/// A function literal found at some position.
final class OutlineFunction {
  /// Creates the literal.
  OutlineFunction({
    required this.isAsync,
    required this.parameters,
    required this.body,
    required this.bodyFrom,
    required this.bodyTo,
    required this.end,
  });

  /// Whether it is `async`.
  final bool isAsync;

  /// Its parameters as text.
  final String parameters;

  /// The items the body walks over: a block's children, or the sibling
  /// items of an expression body.
  final List<OutlineItem> body;

  /// Where the body starts in [body].
  final int bodyFrom;

  /// Where the body ends in [body].
  final int bodyTo;

  /// The index just past the literal in its sibling list.
  final int end;
}

/// The recogniser's shared state and its expressions and calls: walks the
/// bracket tree and collects [DraftNode]s. [walk] is the statements'.
abstract class OutlineExpressionWalker {
  /// Creates a walker over [src] spending from [work], building at most
  /// [maxNodes] nodes.
  OutlineExpressionWalker(this.src, this.work, {required this.maxNodes});

  /// The script.
  final String src;

  /// The parse's budget.
  final OutlineWork work;

  /// The most nodes the walk builds.
  final int maxNodes;

  int _depth = 0;
  int _nodes = 0;
  final Map<List<OutlineItem>, List<int>> _colons = Map.identity();

  /// A new node; throws [OutlineBail] past [maxNodes].
  DraftNode node(DraftKind kind, int start, int end, List<DraftNode> children) {
    if (++_nodes > maxNodes) {
      throw const OutlineBail(ScriptOutlineFailure.tooManyNodes);
    }
    return DraftNode(kind, start, end, children);
  }

  /// Goes one level deeper; throws [OutlineBail] past the recursion bound.
  void enter() {
    if (++_depth > _maxRecursion) {
      throw const OutlineBail(ScriptOutlineFailure.tooDeep);
    }
  }

  /// Comes back from [enter].
  void leave() => _depth--;

  /// Walks `items[from..to)` in source order, adding what it finds to [out].
  void walk(List<OutlineItem> items, int from, int to, List<DraftNode> out);

  /// What [walk] finds in `items[from..to)`.
  List<DraftNode> walked(List<OutlineItem> items, int from, int to) {
    final out = <DraftNode>[];
    walk(items, from, to, out);
    return out;
  }

  /// Whether `items[i]` follows a `.` or `?.`.
  bool afterDot(List<OutlineItem> items, int i) =>
      i > 0 && (items[i - 1].isPunct('.') || items[i - 1].isPunct('?.'));

  /// Adds a branch of [arms] when one of them holds a node; otherwise gives
  /// their nodes back.
  void addBranch(
    ScriptBranchKind kind,
    int start,
    List<DraftNode> arms,
    List<DraftNode> out, {
    int? end,
  }) {
    if (arms.any((arm) => arm.children.isNotEmpty)) {
      out.add(
        node(DraftKind.branch, start, end ?? arms.last.end, arms)
          ..branchKind = kind,
      );
    } else {
      _nodes -= arms.length;
    }
  }

  /// The end offset of `items[from..to)`, or [fallback] when it is empty.
  int endOf(List<OutlineItem> items, int from, int to, int fallback) =>
      to > from ? items[to - 1].end : fallback;

  // ---------------------------------------------------------------- calls

  /// `tools.NAME(…)`, `tools?.NAME(…)`, `tools[…](…)`, `tools.NAME?.(…)`.
  int toolCall(List<OutlineItem> items, int i, int to, List<DraftNode> out) {
    final callee = _toolsMember(items, i, to);
    if (callee == null) {
      return -1;
    }
    var k = callee.$2;
    if (k < to && items[k].isPunct('?.')) {
      k++;
    }
    if (k >= to || !items[k].isGroupOf(OutlineChar.paren)) {
      return -1;
    }
    _addCall(items[i].start, items[k], callee.$1, out);
    return k + 1;
  }

  /// Matches `tools` followed by a member at [i]: the static name (or null)
  /// and the index after the member, or null when there is none.
  (String?, int)? _toolsMember(List<OutlineItem> items, int i, int to) {
    if (!items[i].isIdent('tools')) {
      return null;
    }
    final k = i + 1;
    if (k + 1 < to &&
        (items[k].isPunct('.') || items[k].isPunct('?.')) &&
        items[k + 1].kind == OutlineKind.ident) {
      return (items[k + 1].text, k + 2);
    }
    if (k + 1 < to &&
        items[k].isPunct('?.') &&
        items[k + 1].isGroupOf(OutlineChar.bracket)) {
      return (_staticName(items[k + 1]), k + 2);
    }
    if (k < to && items[k].isGroupOf(OutlineChar.bracket)) {
      return (_staticName(items[k]), k + 1);
    }
    return null;
  }

  /// The tool name in `[ "name" ]`, or null when it is computed.
  String? _staticName(OutlineItem group) {
    if (group.children.length != 1) {
      return null;
    }
    final token = group.children.single;
    if (token.kind != OutlineKind.string &&
        token.kind != OutlineKind.templateFull) {
      return null;
    }
    final name = src.substring(token.start + 1, token.end - 1);
    return name.isEmpty || name.contains(r'\') ? null : name;
  }

  void _addCall(
    int start,
    OutlineItem args,
    String? name,
    List<DraftNode> out,
  ) {
    // Calls inside the arguments run first.
    walk(args.children, 0, args.children.length, out);
    out.add(
      node(DraftKind.call, start, args.end, const [])
        ..toolName = name
        ..text = innerText(args)
        ..properties = _properties(args),
    );
  }

  /// The properties of `({ … })`: the argument when it is a single object
  /// literal. Spread (`...x`), computed (`[k]: v`) and method properties
  /// are skipped; a shorthand `{ file }` reads as `file: file`.
  List<ScriptCallProperty> _properties(OutlineItem args) {
    final items = args.children;
    if (items.length != 1 || !items.single.isGroupOf(OutlineChar.brace)) {
      return const [];
    }
    final body = items.single.children;
    final out = <ScriptCallProperty>[];
    var from = 0;
    while (from < body.length && out.length < ScriptCallNode.maxProperties) {
      var to = from;
      while (to < body.length && !body[to].isPunct(',')) {
        to++;
      }
      work.spend(to - from + 1);
      if (_property(body, from, to) case final property?) {
        out.add(property);
      }
      from = to + 1;
    }
    return out;
  }

  ScriptCallProperty? _property(List<OutlineItem> items, int from, int to) {
    if (from >= to) {
      return null;
    }
    final head = items[from];
    final String key;
    if (head.kind == OutlineKind.ident) {
      key = head.text!;
    } else if (head.kind == OutlineKind.string) {
      key = _stringValue(head) ?? '';
    } else if (head.kind == OutlineKind.number) {
      key = src.substring(head.start, head.end);
    } else {
      return null;
    }
    if (key.isEmpty || key.length > ScriptOutline.maxTextLength) {
      return null;
    }
    if (to == from + 1) {
      return head.kind == OutlineKind.ident
          ? ScriptCallProperty(key: key, source: key)
          : null;
    }
    if (!items[from + 1].isPunct(':') || from + 2 >= to) {
      return null;
    }
    final valueFrom = from + 2;
    return ScriptCallProperty(
      key: key,
      source: text(items, valueFrom, to),
      value: valueFrom + 1 == to ? _literal(items[valueFrom]) : null,
    );
  }

  /// The value of a plain literal token, or null for anything else.
  Object? _literal(OutlineItem token) {
    switch (token.kind) {
      case OutlineKind.string:
      case OutlineKind.templateFull:
        final value = _stringValue(token);
        return value == null ? null : _cut(value);
      case OutlineKind.number:
        return num.tryParse(src.substring(token.start, token.end));
      case OutlineKind.ident:
        return switch (token.text) {
          'true' => true,
          'false' => false,
          _ => null,
        };
    }
    return null;
  }

  /// A string or substitution-free template literal's content with the
  /// common escapes resolved, or null when it uses one this does not know.
  String? _stringValue(OutlineItem token) {
    work.spend(token.end - token.start);
    final raw = src.substring(token.start + 1, token.end - 1);
    if (!raw.contains(r'\')) {
      return raw;
    }
    final out = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
      if (c != r'\') {
        out.write(c);
        continue;
      }
      if (++i >= raw.length) {
        return null;
      }
      switch (raw[i]) {
        case 'n':
          out.write('\n');
        case 't':
          out.write('\t');
        case r'\':
        case "'":
        case '"':
        case '`':
          out.write(raw[i]);
        default:
          return null;
      }
    }
    return out.toString();
  }

  /// `(tools.NAME)(…)` and `(tools[…])?.(…)`.
  int parenthesizedCall(
    List<OutlineItem> items,
    int i,
    int to,
    List<DraftNode> out,
  ) {
    final inner = items[i].children;
    if (inner.isEmpty) {
      return -1;
    }
    final member = _toolsMember(inner, 0, inner.length);
    if (member == null || member.$2 != inner.length) {
      return -1;
    }
    var k = i + 1;
    if (k < to && items[k].isPunct('?.')) {
      k++;
    }
    if (k >= to || !items[k].isGroupOf(OutlineChar.paren)) {
      return -1;
    }
    _addCall(items[i].start, items[k], member.$1, out);
    return k + 1;
  }

  /// Whether the group at [i] holds a call's arguments: the item before it
  /// can end a callee.
  bool endsCallee(List<OutlineItem> items, int i) {
    if (i == 0) {
      return false;
    }
    var previous = items[i - 1];
    if (previous.isPunct('?.') && i >= 2) {
      previous = items[i - 2];
    }
    if (previous.kind == OutlineKind.ident) {
      return !outlineNotCallees.contains(previous.text) ||
          afterDot(items, i - 1);
    }
    return previous.isGroupOf(OutlineChar.paren) ||
        previous.isGroupOf(OutlineChar.bracket);
  }

  /// The start index of the callee chain that ends just before the
  /// arguments at [args] (`files.map`, `tools.a().then`, `x[0].forEach`).
  int _calleeStart(List<OutlineItem> items, int args) {
    var s = args - 1;
    if (s > 0 && items[s].isPunct('?.')) {
      s--;
    }
    var steps = 0;
    while (s > 0 && steps++ < 32) {
      work.spend(1);
      final previous = items[s - 1];
      if ((previous.isPunct('.') || previous.isPunct('?.')) && s >= 2) {
        s -= 2;
        continue;
      }
      final current = items[s];
      if ((current.isGroupOf(OutlineChar.paren) ||
              current.isGroupOf(OutlineChar.bracket)) &&
          ((previous.kind == OutlineKind.ident &&
                  !outlineNotCallees.contains(previous.text)) ||
              previous.isGroupOf(OutlineChar.paren) ||
              previous.isGroupOf(OutlineChar.bracket))) {
        s--;
        continue;
      }
      break;
    }
    return s;
  }

  /// The arguments of a call that is not a tool call: a function literal
  /// with a call in its body becomes an each node, the rest is walked.
  void arguments(List<OutlineItem> items, int argsIndex, List<DraftNode> out) {
    final args = items[argsIndex];
    final calleeStart = _calleeStart(items, argsIndex);
    // `new Promise((resolve) => …)` runs its function once, now.
    final constructed =
        calleeStart > 0 && items[calleeStart - 1].isIdent('new');
    final children = args.children;
    var a = 0;
    while (a <= children.length) {
      var b = a;
      while (b < children.length && !children[b].isPunct(',')) {
        b++;
      }
      work.spend(b - a + 1);
      if (a < b) {
        final fn = constructed ? null : functionLiteral(children, a, b);
        if (fn != null) {
          final body = walked(fn.body, fn.bodyFrom, fn.bodyTo);
          if (body.isNotEmpty) {
            out.add(
              node(DraftKind.each, items[calleeStart].start, args.end, body)
                ..text = text(items, calleeStart, argsIndex)
                ..parameters = fn.parameters
                ..isAsync = fn.isAsync,
            );
          }
          walk(children, fn.end, b, out);
        } else {
          walk(children, a, b, out);
        }
      }
      a = b + 1;
    }
  }

  /// `Promise.all(…)`, `allSettled`, `race`, `any`.
  int parallel(List<OutlineItem> items, int i, int to, List<DraftNode> out) {
    if (i + 3 >= to) {
      return -1;
    }
    if (!(items[i + 1].isPunct('.') || items[i + 1].isPunct('?.')) ||
        items[i + 2].kind != OutlineKind.ident) {
      return -1;
    }
    final kind = _parallelKinds[items[i + 2].text];
    final args = items[i + 3];
    if (kind == null || !args.isGroupOf(OutlineChar.paren)) {
      return -1;
    }
    final children = walked(args.children, 0, args.children.length);
    if (children.isNotEmpty) {
      out.add(
        node(DraftKind.parallel, items[i].start, args.end, children)
          ..parallelKind = kind,
      );
    }
    return i + 4;
  }

  // ------------------------------------------------------------ functions

  /// A function literal starting at [a], ending at or before [b]:
  /// `async`? `function` `*`? name? `(…)` `{…}`, `async`? `(…)` `=>` body,
  /// or `async`? name `=>` body.
  OutlineFunction? functionLiteral(List<OutlineItem> items, int a, int b) {
    var k = a;
    var isAsync = false;
    if (k + 1 < b && items[k].isIdent('async') && !items[k + 1].nl) {
      final next = items[k + 1];
      if (next.isIdent('function') ||
          (k + 2 < b &&
              (next.isGroupOf(OutlineChar.paren) ||
                  next.kind == OutlineKind.ident) &&
              items[k + 2].isPunct('=>'))) {
        isAsync = true;
        k++;
      }
    }
    if (k < b && items[k].isIdent('function')) {
      k++;
      if (k < b && items[k].isPunct('*')) {
        k++;
      }
      if (k < b && items[k].kind == OutlineKind.ident) {
        k++;
      }
      if (k + 1 < b &&
          items[k].isGroupOf(OutlineChar.paren) &&
          items[k + 1].isGroupOf(OutlineChar.brace)) {
        final body = items[k + 1];
        return OutlineFunction(
          isAsync: isAsync,
          parameters: innerText(items[k]),
          body: body.children,
          bodyFrom: 0,
          bodyTo: body.children.length,
          end: k + 2,
        );
      }
      return null;
    }
    final String parameters;
    if (k + 1 < b &&
        items[k].isGroupOf(OutlineChar.paren) &&
        items[k + 1].isPunct('=>')) {
      parameters = innerText(items[k]);
    } else if (k + 1 < b &&
        items[k].kind == OutlineKind.ident &&
        items[k + 1].isPunct('=>')) {
      parameters = _cut(items[k].text!);
    } else {
      return null;
    }
    k += 2;
    if (k >= b) {
      return null;
    }
    if (items[k].isGroupOf(OutlineChar.brace)) {
      final body = items[k];
      return OutlineFunction(
        isAsync: isAsync,
        parameters: parameters,
        body: body.children,
        bodyFrom: 0,
        bodyTo: body.children.length,
        end: k + 1,
      );
    }
    final end = _expressionEnd(items, k, b);
    return OutlineFunction(
      isAsync: isAsync,
      parameters: parameters,
      body: items,
      bodyFrom: k,
      bodyTo: end,
      end: end,
    );
  }

  /// A function declaration or expression starting at `function` or
  /// `async`. Named: a function node. Anonymous and not passed to a call
  /// (`(async function () { … })()`): its calls are walked inline.
  int functionKeyword(
    List<OutlineItem> items,
    int i,
    int to,
    List<DraftNode> out,
  ) {
    if (!startsFunctionKeyword(items, i, to)) {
      // An arrow not bound to a name (or no function at all): walk it
      // inline, without finding where its body ends.
      return -1;
    }
    final fn = functionLiteral(items, i, to);
    if (fn == null) {
      return -1;
    }
    var k = i;
    if (items[k].isIdent('async')) {
      k++;
    }
    k++;
    if (items[k].isPunct('*')) {
      k++;
    }
    final named = items[k].kind == OutlineKind.ident;
    if (named) {
      final body = walked(fn.body, fn.bodyFrom, fn.bodyTo);
      if (body.isNotEmpty) {
        out.add(
          node(DraftKind.function, items[i].start, items[fn.end - 1].end, body)
            ..text = _cut(items[k].text!)
            ..parameters = fn.parameters,
        );
      }
    } else {
      walk(fn.body, fn.bodyFrom, fn.bodyTo, out);
    }
    return fn.end;
  }

  /// Whether `items[i]` starts `function` or `async function`.
  bool startsFunctionKeyword(List<OutlineItem> items, int i, int to) =>
      items[i].isIdent('function') ||
      (items[i].isIdent('async') &&
          i + 1 < to &&
          !items[i + 1].nl &&
          items[i + 1].isIdent('function'));

  /// `name = <function literal>` and `name: <function literal>`.
  int binding(List<OutlineItem> items, int i, int to, List<DraftNode> out) {
    if (i + 2 >= to ||
        !(items[i + 1].isPunct('=') || items[i + 1].isPunct(':')) ||
        outlineNotCallees.contains(items[i].text)) {
      return -1;
    }
    final fn = functionLiteral(items, i + 2, to);
    if (fn == null) {
      return -1;
    }
    final body = walked(fn.body, fn.bodyFrom, fn.bodyTo);
    if (body.isNotEmpty) {
      out.add(
        node(DraftKind.function, items[i].start, items[fn.end - 1].end, body)
          ..text = _cut(items[i].text!)
          ..parameters = fn.parameters,
      );
    }
    return fn.end;
  }

  // -------------------------------------------------------- conditionals

  /// `test ? a : b` at the `?` at [q].
  int conditional(List<OutlineItem> items, int q, int to, List<DraftNode> out) {
    final colon = _colonFor(items, q);
    if (colon < 0 || colon >= to) {
      return q + 1;
    }
    final end = _expressionEnd(items, colon + 1, to);
    final then = walked(items, q + 1, colon);
    final otherwise = walked(items, colon + 1, end);
    if (then.isEmpty && otherwise.isEmpty) {
      return end;
    }
    final testStart = _testStart(items, q);
    final arms = [
      node(
          DraftKind.arm,
          items[q].start,
          items[colon - 1 > q ? colon - 1 : q].end,
          then,
        )
        ..armKind = ScriptArmKind.conditionalThen
        ..condition = text(items, testStart, q),
      node(
        DraftKind.arm,
        items[colon].start,
        endOf(items, colon + 1, end, items[colon].end),
        otherwise,
      )..armKind = ScriptArmKind.conditionalElse,
    ];
    final start = testStart < q ? items[testStart].start : items[q].start;
    addBranch(ScriptBranchKind.conditional, start, arms, out);
    return end;
  }

  /// The `:` that pairs with the `?` at [q], or -1. Pairs are found once per
  /// sibling list, with a stack, so a run of `?` stays linear.
  int _colonFor(List<OutlineItem> items, int q) {
    final pairs = _colons.putIfAbsent(items, () {
      work.spend(items.length);
      final found = List<int>.filled(items.length, -1);
      final open = <int>[];
      for (var j = 0; j < items.length; j++) {
        final item = items[j];
        if (item.isPunct('?')) {
          open.add(j);
        } else if (item.isPunct(':')) {
          if (open.isNotEmpty) {
            found[open.removeLast()] = j;
          }
        } else if (item.isPunct(';') ||
            item.kind == OutlineKind.templateMiddle) {
          open.clear();
        }
      }
      return found;
    });
    return pairs[q];
  }

  /// The index where the test of the conditional at [q] starts.
  int _testStart(List<OutlineItem> items, int q) {
    var j = q;
    var steps = 0;
    while (j > 0 && steps++ < 32) {
      work.spend(1);
      final previous = items[j - 1];
      if (previous.kind == OutlineKind.punct) {
        final op = previous.text!;
        if (op == ',' ||
            op == ';' ||
            op == '=>' ||
            op == ':' ||
            op == '?' ||
            (op.endsWith('=') &&
                op != '==' &&
                op != '===' &&
                op != '!=' &&
                op != '!==' &&
                op != '<=' &&
                op != '>=')) {
          break;
        }
      }
      if (previous.kind == OutlineKind.templateMiddle ||
          previous.isIdent('return') ||
          previous.isIdent('throw') ||
          previous.isIdent('yield') ||
          previous.isIdent('case')) {
        break;
      }
      if (items[j].nl && lineBreakEnds(previous, items[j])) {
        break;
      }
      j--;
    }
    return j;
  }

  /// Where the expression starting at [from] ends: at a `,` or `;`, a `:`
  /// that does not close a `?`, a template's next part, or a line break
  /// that ends the statement.
  int _expressionEnd(List<OutlineItem> items, int from, int to) {
    final ends = _endsOf(items);
    var end = ends.hard[from];
    final broken = from + 1 < ends.lineBreak.length
        ? ends.lineBreak[from + 1]
        : items.length;
    if (broken < end) {
      end = broken;
    }
    if (ends.colon[from] < end) {
      end = ends.colon[from];
    }
    return end < to ? end : to;
  }

  final Map<
    List<OutlineItem>,
    ({List<int> hard, List<int> lineBreak, List<int> colon})
  >
  _ends = Map.identity();

  /// For each index of [items], found once per list so that finding where an
  /// expression ends costs the same wherever it starts: the first index at
  /// or after it holding a `,`, `;` or a template's next part (`hard`); the
  /// first holding a line break that ends a statement (`lineBreak`); and the
  /// first `:` that closes no `?` opened at or after it (`colon`). With `d`
  /// the count of `?` minus `:` before an index, that `:` is the first one
  /// after it at which `d` is the same again.
  ({List<int> hard, List<int> lineBreak, List<int> colon}) _endsOf(
    List<OutlineItem> items,
  ) => _ends.putIfAbsent(items, () {
    final n = items.length;
    work.spend(2 * n + 1);
    final hard = List<int>.filled(n + 1, n);
    final lineBreak = List<int>.filled(n + 1, n);
    final colon = List<int>.filled(n + 1, n);
    final depth = List<int>.filled(n + 1, 0);
    for (var j = 0; j < n; j++) {
      final item = items[j];
      depth[j + 1] =
          depth[j] +
          (item.isPunct('?')
              ? 1
              : item.isPunct(':')
              ? -1
              : 0);
    }
    final nextColonAt = <int, int>{};
    for (var j = n - 1; j >= 0; j--) {
      final item = items[j];
      hard[j] =
          item.isPunct(',') ||
              item.isPunct(';') ||
              item.kind == OutlineKind.templateMiddle
          ? j
          : hard[j + 1];
      lineBreak[j] = j > 0 && item.nl && lineBreakEnds(items[j - 1], item)
          ? j
          : lineBreak[j + 1];
      if (item.isPunct(':')) {
        nextColonAt[depth[j]] = j;
      }
      colon[j] = nextColonAt[depth[j]] ?? n;
    }
    return (hard: hard, lineBreak: lineBreak, colon: colon);
  });

  /// Whether a line break between [previous] and [next] ends a statement.
  bool lineBreakEnds(OutlineItem previous, OutlineItem next) {
    if (previous.kind == OutlineKind.punct &&
        previous.text != '++' &&
        previous.text != '--') {
      return false;
    }
    if (previous.kind == OutlineKind.ident &&
        _continuingWords.contains(previous.text)) {
      return false;
    }
    if (next.isGroup) {
      return next.open == OutlineChar.brace;
    }
    if (next.kind == OutlineKind.punct) {
      return next.text == '++' ||
          next.text == '--' ||
          next.text == '!' ||
          next.text == '~';
    }
    return next.kind != OutlineKind.templateFull &&
        next.kind != OutlineKind.templateMiddle;
  }

  // ----------------------------------------------------------------- text

  /// The text between a group's brackets, collapsed and cut.
  String innerText(OutlineItem group) =>
      text(group.children, 0, group.children.length);

  /// The text of `items[from..to)`, whitespace collapsed (comments drop out
  /// with it) and cut at [ScriptOutline.maxTextLength].
  String text(List<OutlineItem> items, int from, int to) {
    final buffer = StringBuffer();
    var last = -1;
    var space = false;

    bool emit(int start, int end) {
      if (last >= 0 && start > last && buffer.isNotEmpty && !space) {
        buffer.write(' ');
        space = true;
      }
      for (var i = start; i < end; i++) {
        final c = src.codeUnitAt(i);
        if (isOutlineSpace(c) || isOutlineLineTerminator(c)) {
          if (!space && buffer.isNotEmpty) {
            buffer.write(' ');
            space = true;
          }
        } else {
          buffer.writeCharCode(c);
          space = false;
        }
        if (buffer.length > ScriptOutline.maxTextLength) {
          work.spend(i - start + 1);
          return false;
        }
      }
      work.spend(end - start + 1);
      last = end;
      return true;
    }

    bool visit(List<OutlineItem> list, int a, int b) {
      for (var i = a; i < b; i++) {
        final item = list[i];
        if (item.isGroup) {
          if (!emit(item.start, item.openEnd) ||
              !visit(item.children, 0, item.children.length) ||
              !emit(item.closeStart, item.end)) {
            return false;
          }
        } else if (!emit(item.start, item.end)) {
          return false;
        }
      }
      return true;
    }

    visit(items, from, to);
    return _cut(buffer.toString().trimRight());
  }
}

/// [text] cut at [ScriptOutline.maxTextLength], ending with `…` when cut.
String _cut(String text) {
  if (text.length <= ScriptOutline.maxTextLength) {
    return text;
  }
  var end = ScriptOutline.maxTextLength - 1;
  final c = text.codeUnitAt(end - 1);
  if (c >= 0xD800 && c <= 0xDBFF) {
    end--;
  }
  return '${text.substring(0, end)}…';
}
