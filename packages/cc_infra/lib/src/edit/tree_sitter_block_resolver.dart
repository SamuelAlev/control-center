/// Tree-sitter [BlockResolver] for hashline edits: parse by path extension,
/// capture definition bodies, return the smallest span containing the anchor.
///
/// Semantic misses → null (caller handles). Missing natives throw
/// [TreeSitterUnavailable] (fail loud — no blind span guesses).
library;

import 'package:cc_domain/features/dispatch/domain/edit/hashline.dart';
import 'package:cc_natives/cc_natives.dart';

/// Resolves block anchors to syntactic-construct spans using tree-sitter.
///
/// Construct with a [TreeSitterParser] and a [TreeSitterLoader]. When the
/// loader reports the runtime is unavailable, or the grammar for the inferred
/// language cannot be loaded, [resolveBlock] throws [TreeSitterUnavailable].
class TreeSitterBlockResolver implements BlockResolver {
  /// Creates a [TreeSitterBlockResolver] backed by [_parser] and [_loader].
  TreeSitterBlockResolver({
    required this._parser,
    required this._loader,
  });

  final TreeSitterParser _parser;
  final TreeSitterLoader _loader;

  /// Extension (without leading dot, lowercased) → tree-sitter languageId.
  ///
  /// Covers the common languages the block resolver understands. An extension
  /// not listed here yields `null` from [resolveBlock] (the caller degrades to
  /// a re-read prompt rather than guessing a span).
  static const Map<String, String> _languageByExtension = {
    'dart': 'dart',
    'ts': 'typescript',
    'mts': 'typescript',
    'cts': 'typescript',
    'tsx': 'tsx',
    'js': 'javascript',
    'mjs': 'javascript',
    'cjs': 'javascript',
    'jsx': 'javascript',
    'py': 'python',
    'go': 'go',
    'rs': 'rust',
  };

  /// Per-language tree-sitter query capturing definition-body spans as `@block`.
  ///
  /// Each pattern is separated by a `;;;` line so the parser compiles and runs
  /// them independently — a node type the installed grammar rejects is skipped
  /// rather than failing the whole query (see `TreeSitterParser.parseMatches`).
  static const Map<String, String> _blockQueryByLanguage = {
    'dart': '''
(function_signature) @block
;;;
(method_signature) @block
;;;
(class_definition) @block
;;;
(mixin_declaration) @block
;;;
(extension_declaration) @block
;;;
(enum_declaration) @block
''',
    'typescript': '''
(function_declaration) @block
;;;
(method_definition) @block
;;;
(class_declaration) @block
;;;
(interface_declaration) @block
;;;
(enum_declaration) @block
;;;
(arrow_function) @block
''',
    'tsx': '''
(function_declaration) @block
;;;
(method_definition) @block
;;;
(class_declaration) @block
;;;
(interface_declaration) @block
;;;
(enum_declaration) @block
;;;
(arrow_function) @block
''',
    'javascript': '''
(function_declaration) @block
;;;
(method_definition) @block
;;;
(class_declaration) @block
;;;
(arrow_function) @block
''',
    'python': '''
(function_definition) @block
;;;
(class_definition) @block
''',
    'go': '''
(function_declaration) @block
;;;
(method_declaration) @block
;;;
(type_declaration) @block
''',
    'rust': '''
(function_item) @block
;;;
(impl_item) @block
;;;
(struct_item) @block
;;;
(enum_item) @block
;;;
(trait_item) @block
;;;
(mod_item) @block
''',
  };

  @override
  BlockSpan? resolveBlock({
    required String path,
    required String text,
    required int line,
  }) {
    final languageId = _languageIdForPath(path);
    if (languageId == null) {
      return null;
    }
    final querySource = _blockQueryByLanguage[languageId];
    if (querySource == null) {
      return null;
    }
    // A language we DO have a block query for but whose natives can't load is
    // a broken install (the runtime + grammars ship in the host bundle).
    if (!_loader.isAvailable) {
      throw TreeSitterUnavailable('libtree-sitter runtime not loaded');
    }
    if (_loader.grammarLib(languageId) == null) {
      throw TreeSitterUnavailable('grammar for "$languageId" not loaded');
    }

    try {
      final matches = _parser.parseMatches(
        languageId: languageId,
        source: text,
        querySource: querySource,
      );
      return _smallestContaining(matches, line);
    } on TreeSitterUnavailable {
      rethrow;
    } on Object {
      // A parse/FFI failure on THIS file is a semantic miss, not a broken
      // install — resolve to null so the caller re-prompts.
      return null;
    }
  }

  /// The languageId for [path]'s extension, or null when unrecognized.
  String? _languageIdForPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) {
      return null;
    }
    final ext = path.substring(dot + 1).toLowerCase();
    return _languageByExtension[ext];
  }

  /// The smallest captured `@block` span whose inclusive line range contains
  /// [line], or null when no captured block contains it.
  BlockSpan? _smallestContaining(List<QueryMatch> matches, int line) {
    BlockSpan? best;
    var bestSize = 1 << 62;
    for (final match in matches) {
      for (final capture in match) {
        final start = capture.startLine;
        final end = capture.endLine;
        if (start > line || end < line) {
          continue;
        }
        final size = end - start;
        if (size < bestSize) {
          bestSize = size;
          best = BlockSpan(startLine: start, endLine: end);
        }
      }
    }
    return best;
  }
}
