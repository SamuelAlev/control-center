import 'dart:convert';

import 'package:cc_natives/src/code_index/ast_node.dart';

/// One structural match: the node that matched, plus what the metavariables
/// bound to.
class AstMatch {
  /// Creates an [AstMatch].
  const AstMatch({required this.node, required this.bindings});

  /// The matched node.
  final AstNode node;

  /// `$NAME` → the node it captured. A `$$$NAME` run is keyed `$$$NAME` and
  /// bound to a synthetic node spanning the whole run.
  final Map<String, AstNode> bindings;

  /// The text a metavariable captured, or null when it did not bind.
  String? operator [](String name) => bindings[name]?.text;
}

/// A metavariable in a pattern.
///
/// `$X` binds one node, `$$$X` binds a run of zero or more siblings, and `$_`
/// (or `$$$_`) is a wildcard that binds nothing — which matters, because two
/// occurrences of a NAMED metavariable in one pattern must capture equal text,
/// and two wildcards must not.
class _Meta {
  const _Meta(this.name, {required this.multi});

  final String name;
  final bool multi;

  bool get isWildcard => name == '_' || name.isEmpty;
}

/// Reads `$NAME` / `$$$NAME` out of a pattern node's text, or null when the
/// node is ordinary source.
///
/// **Why the whole node's text and not just a leaf.** Grammars wrap tokens
/// differently and unpredictably: in Dart an argument is
/// `argument → identifier`, so `log($$$ARGS)` puts the metavariable one level
/// below where the pattern's sibling list can see it. Requiring a leaf made
/// `$$$ARGS` invisible and the pattern matched only calls of exactly one
/// argument — the one arity a variadic is not for.
///
/// Matching on the node's ENTIRE text is safe because nothing else in a source
/// file is spelled exactly `$NAME`: a string containing it carries its quotes
/// in the node text, and an expression like `$X + 1` is several nodes by the
/// time this sees any of them.
_Meta? _metaOf(AstNode node) {
  final text = node.text.trim();
  if (text.length < 2 || text.codeUnitAt(0) != 0x24) {
    return null;
  }
  final multi = text.startsWith(r'$$$');
  final name = text.substring(multi ? 3 : 1);
  if (name.isEmpty && !multi) {
    return null;
  }
  for (var i = 0; i < name.length; i++) {
    final c = name.codeUnitAt(i);
    final ok =
        (c >= 0x41 && c <= 0x5A) || // A-Z
        (c >= 0x61 && c <= 0x7A) || // a-z
        (c >= 0x30 && c <= 0x39) || // 0-9
        c == 0x5F; // _
    if (!ok) {
      return null;
    }
  }
  return _Meta(name, multi: multi);
}

/// Structural search over a materialized tree.
///
/// **What makes this a matcher and not a regex with extra steps.** A pattern is
/// parsed by the SAME grammar as the searched source, so `foo(a, b)` matches a
/// call however it is spaced, commented or line-broken, and does not match the
/// same characters inside a string. And a metavariable repeated in one pattern
/// must capture equal text: `if ($X) dispose($X)` matches a guard that disposes
/// what it tested and does NOT match `if (a) dispose(b)`. That equality
/// constraint is the whole reason to have metavariables rather than wildcards,
/// and it is the property a textual search cannot express at all.
///
/// **Why the pattern is unwrapped before matching.** A pattern is parsed as a
/// whole source file, so `foo($X)` arrives as
/// `program → expression_statement → call_expression`. Matching that literally
/// would only ever find calls that are themselves whole statements. The
/// significant node is the deepest one that still spans the entire pattern
/// text, so the wrappers the grammar added to make it a valid file are
/// discarded — and only those, because the moment a node has two named
/// children the descent stops.
class AstPatternMatcher {
  /// Creates a matcher for [pattern], a tree parsed from pattern source.
  ///
  /// In [sequenceMode] the pattern's named CHILDREN are matched as a
  /// contiguous run of siblings anywhere in the subject, rather than the
  /// pattern node itself being matched. That is what makes `dispose($X)` find
  /// the call inside `log(dispose(a))` on grammars that have no
  /// `call_expression` node — see `CompiledAstPattern.sequenceMode`.
  AstPatternMatcher(AstNode pattern, {this.sequenceMode = false})
    : _pattern = sequenceMode ? pattern : significantNode(pattern);

  final AstNode _pattern;

  /// Whether the pattern matches a run of siblings rather than one node.
  final bool sequenceMode;

  /// The node the pattern actually asserts about.
  AstNode get pattern => _pattern;

  /// The deepest descendant of [root] that still spans the whole pattern.
  static AstNode significantNode(AstNode root) {
    var node = root;
    while (true) {
      final named = node.namedChildren.toList();
      if (named.length != 1) {
        return node;
      }
      final only = named.first;
      // Stop as soon as the child is narrower than its parent: the parent is
      // then saying something (a `return`, an `await`) that the pattern meant.
      if (only.text.trim() != node.text.trim()) {
        return node;
      }
      node = only;
    }
  }

  /// Every node in [root]'s subtree that matches, outermost first.
  ///
  /// Nested matches are reported too — a pattern that matches an outer call and
  /// an inner one has genuinely found two sites, and silently dropping the
  /// inner one would make a rewrite incomplete in a way nobody could see.
  List<AstMatch> findAll(AstNode root, {int limit = 1000}) {
    final matches = <AstMatch>[];
    if (sequenceMode) {
      final patternChildren = _pattern.namedChildren.toList();
      if (patternChildren.isEmpty) {
        return matches;
      }
      for (final node in root.descendants) {
        if (matches.length >= limit) {
          break;
        }
        final subjects = node.namedChildren.toList();
        for (var start = 0; start < subjects.length; start++) {
          final bindings = <String, AstNode>{};
          final consumed = _matchRun(
            patternChildren,
            subjects,
            start,
            bindings,
          );
          if (consumed == null || consumed == 0) {
            continue;
          }
          final run = subjects.sublist(start, start + consumed);
          matches.add(AstMatch(node: _spanOf(run, node), bindings: bindings));
          // One match per starting position; overlapping runs from the same
          // node would report the same site twice.
          break;
        }
      }
      return matches;
    }
    for (final node in root.descendants) {
      if (matches.length >= limit) {
        break;
      }
      final bindings = <String, AstNode>{};
      if (_matchNode(_pattern, node, bindings)) {
        matches.add(AstMatch(node: node, bindings: bindings));
      }
    }
    return matches;
  }

  /// Matches [patterns] against [subjects] starting at [start], returning how
  /// many subjects it consumed, or null when it does not match there.
  ///
  /// Unlike [_matchSequence] this does NOT have to consume every subject: a
  /// run matches inside a longer sibling list, which is the whole point of
  /// sequence mode.
  int? _matchRun(
    List<AstNode> patterns,
    List<AstNode> subjects,
    int start,
    Map<String, AstNode> bindings,
  ) {
    for (var take = patterns.length; take <= subjects.length - start; take++) {
      final saved = Map<String, AstNode>.of(bindings);
      final window = subjects.sublist(start, start + take);
      if (_matchSequence(patterns, window, 0, 0, bindings)) {
        return take;
      }
      bindings
        ..clear()
        ..addAll(saved);
      // Without a variadic in the pattern, a wider window can never match, so
      // stop rather than retrying the same failure len(subjects) times.
      if (!patterns.any((p) {
        final m = _metaOf(p);
        return m != null && m.multi;
      })) {
        return null;
      }
    }
    return null;
  }

  /// A synthetic node spanning a matched run, so a rewrite has a byte range.
  static AstNode _spanOf(List<AstNode> run, AstNode parent) => AstNode(
    type: parent.type,
    isNamed: parent.isNamed,
    startByte: run.first.startByte,
    endByte: run.last.endByte,
    startLine: run.first.startLine,
    endLine: run.last.endLine,
    text: run.length == 1
        ? run.first.text
        : _sliceParent(parent, run.first.startByte, run.last.endByte),
    children: run,
  );

  /// The parent's own text for the run's byte range.
  ///
  /// Reconstructed from the parent rather than joined from the children,
  /// because the separators between siblings (`.`, `,`, whitespace) are
  /// anonymous tokens the run does not contain — joining would produce text
  /// that never appeared in the file.
  static String _sliceParent(AstNode parent, int startByte, int endByte) {
    final offset = startByte - parent.startByte;
    final length = endByte - startByte;
    final bytes = utf8.encode(parent.text);
    if (offset < 0 || offset + length > bytes.length) {
      return parent.text;
    }
    return utf8.decode(
      bytes.sublist(offset, offset + length),
      allowMalformed: true,
    );
  }

  bool _matchNode(
    AstNode pattern,
    AstNode subject,
    Map<String, AstNode> bindings,
  ) {
    final meta = _metaOf(pattern);
    if (meta != null && !meta.multi) {
      return _bind(meta, subject, bindings);
    }

    if (pattern.type != subject.type) {
      return false;
    }

    final patternChildren = pattern.namedChildren.toList();
    final subjectChildren = subject.namedChildren.toList();

    // A leaf pattern asserts its own text: `foo` matches the identifier `foo`
    // and not the identifier `bar`. Without this every identifier would match
    // every other one and the pattern would only constrain shape.
    if (patternChildren.isEmpty) {
      return pattern.text == subject.text;
    }

    return _matchSequence(patternChildren, subjectChildren, 0, 0, bindings);
  }

  /// Matches a pattern child sequence against a subject one, with `$$$`
  /// absorbing a variable-length run.
  ///
  /// Backtracking is required and cannot be avoided by being clever: `$$$A, x,
  /// $$$B` has no greedy assignment that is right for every input, so a `$$$`
  /// tries every split from shortest up. Patterns are small, so the exponential
  /// worst case is bounded by the pattern the model wrote, not by file size.
  bool _matchSequence(
    List<AstNode> patterns,
    List<AstNode> subjects,
    int pi,
    int si,
    Map<String, AstNode> bindings,
  ) {
    if (pi == patterns.length) {
      return si == subjects.length;
    }
    final meta = _metaOf(patterns[pi]);
    if (meta != null && meta.multi) {
      // Shortest-first, so `$$$` prefers to absorb nothing — which makes an
      // anchored tail (`$$$, last`) match the way it reads.
      for (var take = 0; si + take <= subjects.length; take++) {
        final saved = Map<String, AstNode>.of(bindings);
        var ok = true;
        if (!meta.isWildcard) {
          final captured = subjects.sublist(si, si + take);
          ok = _bindMulti(meta.name, captured, bindings);
        }
        if (ok &&
            _matchSequence(patterns, subjects, pi + 1, si + take, bindings)) {
          return true;
        }
        bindings
          ..clear()
          ..addAll(saved);
      }
      return false;
    }

    if (si >= subjects.length) {
      return false;
    }
    final saved = Map<String, AstNode>.of(bindings);
    if (_matchNode(patterns[pi], subjects[si], bindings) &&
        _matchSequence(patterns, subjects, pi + 1, si + 1, bindings)) {
      return true;
    }
    bindings
      ..clear()
      ..addAll(saved);
    return false;
  }

  bool _bind(_Meta meta, AstNode subject, Map<String, AstNode> bindings) {
    if (meta.isWildcard) {
      return true;
    }
    final existing = bindings[meta.name];
    if (existing != null) {
      // The equality constraint. Compared on normalized text rather than on
      // node identity, because `$X` should unify `foo . bar` with `foo.bar`.
      return _normalize(existing.text) == _normalize(subject.text);
    }
    bindings[meta.name] = subject;
    return true;
  }

  bool _bindMulti(
    String name,
    List<AstNode> captured,
    Map<String, AstNode> bindings,
  ) {
    final key = r'$$$' + name;
    final text = captured.map((n) => n.text).join(', ');
    final existing = bindings[key];
    if (existing != null) {
      return _normalize(existing.text) == _normalize(text);
    }
    // Recorded as a synthetic node so callers get one uniform binding map; the
    // span covers the whole run, which is what a rewrite needs.
    bindings[key] = captured.isEmpty
        ? AstNode(
            type: '',
            isNamed: false,
            startByte: 0,
            endByte: 0,
            startLine: 0,
            endLine: 0,
            text: '',
            children: const [],
          )
        : AstNode(
            type: '',
            isNamed: false,
            startByte: captured.first.startByte,
            endByte: captured.last.endByte,
            startLine: captured.first.startLine,
            endLine: captured.last.endLine,
            text: text,
            children: captured,
          );
    return true;
  }

  static String _normalize(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Substitutes a match's bindings into a rewrite template.
///
/// `$X` and `$$$X` in [template] are replaced by what they captured. A
/// metavariable the pattern never bound is left verbatim: silently emitting an
/// empty string there would produce syntactically plausible code with a hole in
/// it, which is the worst possible failure for a rewrite nobody reviews
/// character by character.
String renderAstRewrite(String template, AstMatch match) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < template.length) {
    if (template.codeUnitAt(i) != 0x24) {
      buffer.writeCharCode(template.codeUnitAt(i));
      i++;
      continue;
    }
    final multi = template.startsWith(r'$$$', i);
    var j = i + (multi ? 3 : 1);
    final start = j;
    while (j < template.length) {
      final c = template.codeUnitAt(j);
      final ok =
          (c >= 0x41 && c <= 0x5A) ||
          (c >= 0x61 && c <= 0x7A) ||
          (c >= 0x30 && c <= 0x39) ||
          c == 0x5F;
      if (!ok) {
        break;
      }
      j++;
    }
    final name = template.substring(start, j);
    if (name.isEmpty) {
      buffer.write(template.substring(i, j == i ? i + 1 : j));
      i = j == i ? i + 1 : j;
      continue;
    }
    final key = multi ? r'$$$' + name : name;
    final bound = match.bindings[key];
    if (bound == null) {
      buffer.write(template.substring(i, j));
    } else {
      buffer.write(bound.text);
    }
    i = j;
  }
  return buffer.toString();
}
