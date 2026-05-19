import 'dart:convert';

import 'package:cc_natives/src/code_index/ast_node.dart';
import 'package:cc_natives/src/code_index/tree_sitter_parser.dart';

/// A pattern, parsed and reduced to what it actually asserts.
class CompiledAstPattern {
  /// Creates a [CompiledAstPattern].
  const CompiledAstPattern({
    required this.node,
    required this.sequenceMode,
    required this.context,
  });

  /// In node mode, the node to match. In [sequenceMode], a synthetic node
  /// whose named children are the run to match.
  final AstNode node;

  /// Whether the pattern matches a RUN OF SIBLINGS rather than a single node.
  ///
  /// True exactly when no single node spans the fragment — which is the honest
  /// test for "this is not a complete node of the language". `dispose($X)` is
  /// one such fragment: several grammars (Dart's among them) have no
  /// `call_expression` node at all, so a call is an identifier followed by a
  /// selector — two siblings inside whatever encloses them. Matching the
  /// enclosing statement instead would find `dispose(a);` and miss
  /// `log(dispose(a))`, which is the same call in the place people most want to
  /// find it.
  final bool sequenceMode;

  /// The scaffold the pattern parsed in, for diagnostics.
  final String context;
}

/// Scaffolds tried in order, `%s` marking where the pattern goes.
///
/// **Why a ladder rather than one context.** A pattern is a fragment, and a
/// grammar only defines what a whole FILE is. There is no context in which
/// every fragment parses correctly: a statement needs a function body, an
/// expression needs somewhere to be a value, a member needs a class, and a
/// declaration needs top level. So each candidate is parsed and checked, and
/// the first that accepts the fragment without an `ERROR` across it wins.
const Map<String, List<String>> _contexts = {
  'dart': [
    '%s',
    'void _ccPattern() { %s }',
    'void _ccPattern() { var _ccValue = %s; }',
    'class _CcPattern { %s }',
  ],
  'javascript': [
    '%s',
    'function _ccPattern() { %s }',
    'function _ccPattern() { let _ccValue = %s; }',
    'class _CcPattern { %s }',
  ],
  'typescript': [
    '%s',
    'function _ccPattern() { %s }',
    'function _ccPattern() { let _ccValue = %s; }',
    'class _CcPattern { %s }',
  ],
  'tsx': [
    '%s',
    'function _ccPattern() { %s }',
    'function _ccPattern() { let _ccValue = %s; }',
    'class _CcPattern { %s }',
  ],
  'php': [
    '<?php %s',
    '<?php function _ccPattern() { %s }',
    r'<?php $_ccValue = %s;',
    '<?php class _CcPattern { %s }',
  ],
};

/// The scaffolds for [languageId], falling back to the bare one.
List<String> astPatternContexts(String languageId) =>
    _contexts[languageId] ?? const ['%s'];

/// Whether the top-level scaffold may be tried for [pattern].
///
/// **This guard is the difference between finding calls and finding nothing.**
/// `dispose($X)` parsed at top level is a perfectly valid Dart FUNCTION
/// SIGNATURE — a declaration named `dispose` taking a parameter `$X` — with no
/// `ERROR` anywhere to give it away. A matcher built on that parse looks for
/// declarations, finds no calls, and reports "no matches" for a pattern that
/// was never being interpreted the way it reads.
///
/// The rule is a property of the pattern text, not a guess about the grammar: a
/// fragment that does not close with `}` or `;` is an expression, and an
/// expression is never the declaration a top-level parse would make of it.
bool _mayParseBare(String pattern) =>
    pattern.endsWith('}') || pattern.endsWith(';');

/// Parses [pattern] in the first scaffold that accepts it.
///
/// Returns null when no scaffold does — a real answer, not a degradation: a
/// fragment no context accepts is one the model mistyped, and searching for it
/// anyway would report "no matches" for a pattern that was never valid.
CompiledAstPattern? compileAstPattern({
  required TreeSitterParser parser,
  required String languageId,
  required String pattern,
}) {
  final trimmed = pattern.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final patternBytes = utf8.encode(trimmed).length;
  final allowBare = _mayParseBare(trimmed);

  for (final context in astPatternContexts(languageId)) {
    final marker = context.indexOf('%s');
    if (marker < 0) {
      continue;
    }
    final isBare = context.trim() == '%s' || context.trim() == '<?php %s';
    if (isBare && !allowBare) {
      continue;
    }
    // Every scaffold is ASCII, so its prefix length in bytes is its length in
    // code units — the pattern is the only part that may not be.
    final start = utf8.encode(context.substring(0, marker)).length;
    final end = start + patternBytes;
    final tree = parser.parseTree(
      languageId: languageId,
      source: context.replaceFirst('%s', trimmed),
    );
    if (tree == null) {
      continue;
    }

    // An ERROR across the fragment means this scaffold gave the grammar
    // nowhere valid to put it.
    var errored = false;
    AstNode? exact;
    AstNode? container;
    for (final node in tree.descendants) {
      if (node.type == 'ERROR' &&
          node.startByte < end &&
          node.endByte > start) {
        errored = true;
        break;
      }
      if (node.startByte == start && node.endByte == end) {
        // Pre-order, so a later hit is deeper: keep descending past the
        // wrappers (`program`, a bare block) that share the fragment's span.
        exact = node;
      } else if (node.startByte <= start && node.endByte >= end) {
        if (container == null ||
            (node.endByte - node.startByte) <
                (container.endByte - container.startByte)) {
          container = node;
        }
      }
    }
    if (errored) {
      continue;
    }

    if (exact != null) {
      return CompiledAstPattern(
        node: exact,
        sequenceMode: false,
        context: context,
      );
    }
    if (container == null) {
      continue;
    }
    // No single node spans the fragment, so what the pattern names is the run
    // of the container's children that lies inside it — NOT the container,
    // whose span includes the scaffold's own `var _ccValue =` and would match
    // variable definitions rather than calls.
    final run = [
      for (final child in container.namedChildren)
        if (child.startByte >= start && child.endByte <= end) child,
    ];
    if (run.isEmpty) {
      continue;
    }
    return CompiledAstPattern(
      node: AstNode(
        type: container.type,
        isNamed: container.isNamed,
        startByte: start,
        endByte: end,
        startLine: run.first.startLine,
        endLine: run.last.endLine,
        text: trimmed,
        children: run,
      ),
      sequenceMode: true,
      context: context,
    );
  }
  return null;
}
