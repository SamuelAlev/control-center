import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline/outline_builder.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline/outline_expressions.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline/outline_lexer.dart';

// The recogniser's statements: `if`, loops, `switch`, `try`, and where a
// statement ends.

/// The recogniser: walks the bracket tree in source order and collects
/// [DraftNode]s, the statements here and the expressions and calls in
/// [OutlineExpressionWalker].
final class OutlineWalker extends OutlineExpressionWalker {
  /// Creates a walker over [src] spending from [work], building at most
  /// [maxNodes] nodes.
  OutlineWalker(super.src, super.work, {required super.maxNodes});

  final Map<List<OutlineItem>, List<int>> _stops = Map.identity();
  final Map<List<OutlineItem>, Map<int, int>> _statementEnds = Map.identity();

  @override
  void walk(List<OutlineItem> items, int from, int to, List<DraftNode> out) {
    enter();
    var i = from;
    while (i < to) {
      i = _step(items, i, to, out);
    }
    leave();
  }

  /// Handles the construct at [i]; returns the index after it.
  int _step(List<OutlineItem> items, int i, int to, List<DraftNode> out) {
    work.spend(1);
    final item = items[i];
    if (item.kind == OutlineKind.ident && !afterDot(items, i)) {
      final next = switch (item.text) {
        'if' => _if(items, i, to, out),
        'for' => _for(items, i, to, out),
        'while' => _while(items, i, to, out),
        'do' => _do(items, i, to, out),
        'switch' => _switch(items, i, to, out),
        'try' => _try(items, i, to, out),
        'function' || 'async' => functionKeyword(items, i, to, out),
        'tools' => toolCall(items, i, to, out),
        'Promise' => parallel(items, i, to, out),
        _ => -1,
      };
      if (next > i) {
        return next;
      }
    }
    if (item.kind == OutlineKind.ident) {
      final bound = binding(items, i, to, out);
      if (bound > i) {
        return bound;
      }
    }
    if (item.isGroup) {
      if (item.open == OutlineChar.paren) {
        final call = parenthesizedCall(items, i, to, out);
        if (call > i) {
          return call;
        }
        if (endsCallee(items, i)) {
          arguments(items, i, out);
          return i + 1;
        }
      }
      walk(item.children, 0, item.children.length, out);
      return i + 1;
    }
    if (item.isPunct('?')) {
      return conditional(items, i, to, out);
    }
    return i + 1;
  }

  // ----------------------------------------------------------- statements

  int _if(List<OutlineItem> items, int i, int to, List<DraftNode> out) {
    if (i + 2 >= to || !items[i + 1].isGroupOf(OutlineChar.paren)) {
      return -1;
    }
    final firstTest = items[i + 1];
    walk(firstTest.children, 0, firstTest.children.length, out);
    final arms = <DraftNode>[];
    var armStart = items[i].start;
    var test = firstTest;
    var kind = ScriptArmKind.ifArm;
    var s = i + 2;
    final List<DraftNode> pending = [];
    int next;
    while (true) {
      final e = _statementEnd(items, s, to);
      final children = [...pending, ...walked(items, s, e)];
      pending.clear();
      arms.add(
        node(DraftKind.arm, armStart, endOf(items, s, e, test.end), children)
          ..armKind = kind
          ..condition = innerText(test),
      );
      if (e < to && items[e].isIdent('else')) {
        if (e + 2 < to &&
            items[e + 1].isIdent('if') &&
            items[e + 2].isGroupOf(OutlineChar.paren)) {
          armStart = items[e].start;
          test = items[e + 2];
          pending.addAll(walked(test.children, 0, test.children.length));
          kind = ScriptArmKind.elseIfArm;
          s = e + 3;
          continue;
        }
        final elseEnd = _statementEnd(items, e + 1, to);
        arms.add(
          node(
            DraftKind.arm,
            items[e].start,
            endOf(items, e + 1, elseEnd, items[e].end),
            walked(items, e + 1, elseEnd),
          )..armKind = ScriptArmKind.elseArm,
        );
        next = elseEnd;
      } else {
        next = e;
      }
      break;
    }
    addBranch(ScriptBranchKind.ifChain, items[i].start, arms, out);
    return next;
  }

  int _for(List<OutlineItem> items, int i, int to, List<DraftNode> out) {
    var k = i + 1;
    if (k < to && items[k].isIdent('await')) {
      k++;
    }
    if (k >= to || !items[k].isGroupOf(OutlineChar.paren) || k + 1 >= to) {
      return -1;
    }
    final header = items[k];
    final parts = header.children;
    var semicolon = -1;
    var ofOrIn = false;
    work.spend(parts.length);
    for (var j = 0; j < parts.length; j++) {
      if (parts[j].isPunct(';')) {
        semicolon = j;
        break;
      }
      if (parts[j].isIdent('of') || parts[j].isIdent('in')) {
        ofOrIn = true;
      }
    }
    final ScriptLoopKind kind;
    final loopChildren = <DraftNode>[];
    if (semicolon >= 0) {
      kind = ScriptLoopKind.forClassic;
      walk(parts, 0, semicolon, out);
      walk(parts, semicolon + 1, parts.length, loopChildren);
    } else {
      kind = parts.any((p) => p.isIdent('of'))
          ? ScriptLoopKind.forOf
          : (ofOrIn ? ScriptLoopKind.forIn : ScriptLoopKind.forClassic);
      walk(parts, 0, parts.length, out);
    }
    final bodyStart = k + 1;
    final bodyEnd = _statementEnd(items, bodyStart, to);
    walk(items, bodyStart, bodyEnd, loopChildren);
    _addLoop(
      kind,
      items[i].start,
      header,
      items,
      bodyStart,
      bodyEnd,
      loopChildren,
      out,
    );
    return bodyEnd;
  }

  void _addLoop(
    ScriptLoopKind kind,
    int start,
    OutlineItem header,
    List<OutlineItem> items,
    int bodyStart,
    int bodyEnd,
    List<DraftNode> children,
    List<DraftNode> out,
  ) {
    if (children.isEmpty) {
      return;
    }
    final bodyFrom = bodyEnd > bodyStart ? items[bodyStart].start : header.end;
    final bodyTo = endOf(items, bodyStart, bodyEnd, header.end);
    out.add(
      node(DraftKind.loop, start, bodyTo, children)
        ..loopKind = kind
        ..text = innerText(header)
        ..bodyStart = bodyFrom
        ..bodyEnd = bodyTo,
    );
  }

  int _while(List<OutlineItem> items, int i, int to, List<DraftNode> out) {
    if (i + 2 >= to || !items[i + 1].isGroupOf(OutlineChar.paren)) {
      return -1;
    }
    final header = items[i + 1];
    final children = walked(header.children, 0, header.children.length);
    final bodyStart = i + 2;
    final bodyEnd = _statementEnd(items, bodyStart, to);
    walk(items, bodyStart, bodyEnd, children);
    _addLoop(
      ScriptLoopKind.whileLoop,
      items[i].start,
      header,
      items,
      bodyStart,
      bodyEnd,
      children,
      out,
    );
    return bodyEnd;
  }

  int _do(List<OutlineItem> items, int i, int to, List<DraftNode> out) {
    final bodyStart = i + 1;
    if (bodyStart >= to) {
      return -1;
    }
    final bodyEnd = _statementEnd(items, bodyStart, to);
    if (bodyEnd + 1 >= to ||
        !items[bodyEnd].isIdent('while') ||
        !items[bodyEnd + 1].isGroupOf(OutlineChar.paren)) {
      return -1;
    }
    final header = items[bodyEnd + 1];
    final children = walked(items, bodyStart, bodyEnd);
    walk(header.children, 0, header.children.length, children);
    var next = bodyEnd + 2;
    if (next < to && items[next].isPunct(';')) {
      next++;
    }
    if (children.isNotEmpty) {
      out.add(
        node(DraftKind.loop, items[i].start, header.end, children)
          ..loopKind = ScriptLoopKind.doWhile
          ..text = innerText(header)
          ..bodyStart = items[bodyStart].start
          ..bodyEnd = items[bodyEnd - 1].end,
      );
    }
    return next;
  }

  int _switch(List<OutlineItem> items, int i, int to, List<DraftNode> out) {
    if (i + 2 >= to ||
        !items[i + 1].isGroupOf(OutlineChar.paren) ||
        !items[i + 2].isGroupOf(OutlineChar.brace)) {
      return -1;
    }
    final discriminant = items[i + 1];
    walk(discriminant.children, 0, discriminant.children.length, out);
    final body = items[i + 2].children;
    work.spend(body.length);
    final starts = <int>[
      for (var j = 0; j < body.length; j++)
        if ((body[j].isIdent('case') || body[j].isIdent('default')) &&
            !afterDot(body, j))
          j,
    ];
    final arms = <DraftNode>[];
    for (var c = 0; c < starts.length; c++) {
      final clause = starts[c];
      final clauseEnd = c + 1 < starts.length ? starts[c + 1] : body.length;
      final isCase = body[clause].isIdent('case');
      final colon = _colonAfter(body, clause + 1, clauseEnd);
      if (colon < 0) {
        continue;
      }
      final children = <DraftNode>[
        if (isCase) ...walked(body, clause + 1, colon),
        ...walked(body, colon + 1, clauseEnd),
      ];
      arms.add(
        node(
            DraftKind.arm,
            body[clause].start,
            endOf(body, colon, clauseEnd, body[colon].end),
            children,
          )
          ..armKind = isCase ? ScriptArmKind.caseArm : ScriptArmKind.defaultArm
          ..condition = isCase ? text(body, clause + 1, colon) : null,
      );
    }
    if (arms.isNotEmpty) {
      addBranch(
        ScriptBranchKind.switchCases,
        items[i].start,
        arms,
        out,
        end: items[i + 2].end,
      );
    }
    return i + 3;
  }

  /// The `:` that ends a `case` value in `items[from..to)`, skipping those
  /// of conditional expressions, or -1.
  int _colonAfter(List<OutlineItem> items, int from, int to) {
    var questions = 0;
    for (var j = from; j < to; j++) {
      work.spend(1);
      if (items[j].isPunct('?')) {
        questions++;
      } else if (items[j].isPunct(':')) {
        if (questions == 0) {
          return j;
        }
        questions--;
      }
    }
    return -1;
  }

  int _try(List<OutlineItem> items, int i, int to, List<DraftNode> out) {
    if (i + 1 >= to || !items[i + 1].isGroupOf(OutlineChar.brace)) {
      return -1;
    }
    final block = items[i + 1];
    walk(block.children, 0, block.children.length, out);
    var k = i + 2;
    final arms = <DraftNode>[];
    if (k < to && items[k].isIdent('catch')) {
      final catchStart = items[k].start;
      String? parameter;
      if (k + 1 < to && items[k + 1].isGroupOf(OutlineChar.paren)) {
        parameter = innerText(items[k + 1]);
        k++;
      }
      if (k + 1 < to && items[k + 1].isGroupOf(OutlineChar.brace)) {
        final body = items[k + 1];
        arms.add(
          node(
              DraftKind.arm,
              catchStart,
              body.end,
              walked(body.children, 0, body.children.length),
            )
            ..armKind = ScriptArmKind.catchArm
            ..condition = parameter,
        );
        k += 2;
      }
    }
    if (k + 1 < to &&
        items[k].isIdent('finally') &&
        items[k + 1].isGroupOf(OutlineChar.brace)) {
      final body = items[k + 1];
      arms.add(
        node(
          DraftKind.arm,
          items[k].start,
          body.end,
          walked(body.children, 0, body.children.length),
        )..armKind = ScriptArmKind.finallyArm,
      );
      k += 2;
    }
    if (arms.isNotEmpty) {
      addBranch(ScriptBranchKind.tryCatch, items[i].start, arms, out);
    }
    return k;
  }

  /// The index after the statement that starts at [from].
  int _statementEnd(List<OutlineItem> items, int from, int to) {
    if (from >= to) {
      return to;
    }
    // Nested statements (`if (a) if (b) …`) ask for the same ends again
    // from each level; each is found once.
    final memo = _statementEnds.putIfAbsent(items, () => {});
    final key = from * (items.length + 1) + to;
    if (memo[key] case final known?) {
      return known;
    }
    final end = _statementEndOnce(items, from, to);
    memo[key] = end;
    return end;
  }

  int _statementEndOnce(List<OutlineItem> items, int from, int to) {
    work.spend(1);
    enter();
    try {
      final item = items[from];
      if (item.isGroupOf(OutlineChar.brace)) {
        return from + 1;
      }
      if (item.kind == OutlineKind.ident) {
        final structural = _structuralEnd(items, from, to);
        if (structural > from) {
          return structural;
        }
      }
      final stop = _stopsOf(items)[from + 1];
      return stop < to ? stop : to;
    } finally {
      leave();
    }
  }

  /// For each index `j` of [items], the first index at or after `j` where a
  /// statement can end (after a `;`, at a template's next part, at a line
  /// break that ends it), or the list's length. Found once per list, so
  /// finding a statement's end costs the same wherever it starts.
  List<int> _stopsOf(List<OutlineItem> items) => _stops.putIfAbsent(items, () {
    work.spend(items.length + 1);
    final n = items.length;
    final stops = List<int>.filled(n + 1, n);
    for (var j = n - 1; j >= 1; j--) {
      final current = items[j];
      final ends =
          items[j - 1].isPunct(';') ||
          current.kind == OutlineKind.templateMiddle ||
          (current.nl && lineBreakEnds(items[j - 1], current));
      stops[j] = ends ? j : stops[j + 1];
    }
    return stops;
  });

  int _structuralEnd(List<OutlineItem> items, int from, int to) {
    bool parenAt(int k) => k < to && items[k].isGroupOf(OutlineChar.paren);
    bool braceAt(int k) => k < to && items[k].isGroupOf(OutlineChar.brace);
    switch (items[from].text) {
      case 'if':
        if (!parenAt(from + 1)) {
          return -1;
        }
        final e = _statementEnd(items, from + 2, to);
        if (e < to && items[e].isIdent('else')) {
          return _statementEnd(items, e + 1, to);
        }
        return e;
      case 'for':
        var k = from + 1;
        if (k < to && items[k].isIdent('await')) {
          k++;
        }
        return parenAt(k) ? _statementEnd(items, k + 1, to) : -1;
      case 'while' || 'with':
        return parenAt(from + 1) ? _statementEnd(items, from + 2, to) : -1;
      case 'do':
        final e = _statementEnd(items, from + 1, to);
        if (e < to && items[e].isIdent('while') && parenAt(e + 1)) {
          final next = e + 2;
          return next < to && items[next].isPunct(';') ? next + 1 : next;
        }
        return e;
      case 'switch':
        return parenAt(from + 1) && braceAt(from + 2) ? from + 3 : -1;
      case 'try':
        if (!braceAt(from + 1)) {
          return -1;
        }
        var k = from + 2;
        if (k < to && items[k].isIdent('catch')) {
          k++;
          if (parenAt(k)) {
            k++;
          }
          if (braceAt(k)) {
            k++;
          }
        }
        if (k < to && items[k].isIdent('finally') && braceAt(k + 1)) {
          k += 2;
        }
        return k;
      case 'function' || 'async':
        // An arrow is an expression statement; only a declaration ends
        // structurally.
        if (!startsFunctionKeyword(items, from, to)) {
          return -1;
        }
        final fn = functionLiteral(items, from, to);
        if (fn == null || fn.body == items) {
          return -1;
        }
        return fn.end;
      default:
        // A label: `outer: for (…) …`.
        if (from + 2 < to &&
            items[from + 1].isPunct(':') &&
            !outlineNotCallees.contains(items[from].text)) {
          return _statementEnd(items, from + 2, to);
        }
        return -1;
    }
  }
}
