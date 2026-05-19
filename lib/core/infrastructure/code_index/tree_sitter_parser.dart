import 'dart:convert';
import 'dart:ffi';

import 'package:control_center/core/infrastructure/code_index/tree_sitter_bindings.dart';
import 'package:control_center/core/infrastructure/code_index/tree_sitter_loader.dart';
import 'package:ffi/ffi.dart';

/// Thrown when the tree-sitter natives are not available.
class TreeSitterUnavailable implements Exception {
/// Creates a [TreeSitterUnavailable] with the given message.
  TreeSitterUnavailable(this.message);
/// The error message.
  final String message;
  @override
  String toString() => 'TreeSitterUnavailable: $message';
}

/// A single capture from a tree-sitter query match: the capture [name]
/// (e.g. `class.name`), the matched source [text], and its 1-based line span
/// plus UTF-8 byte span (used for parent/containment resolution).
class QueryCapture {
/// Creates a [QueryCapture] with the given metadata.
  const QueryCapture({
    required this.name,
    required this.text,
    required this.startLine,
    required this.endLine,
    required this.startByte,
    required this.endByte,
  });

/// The capture name from the query pattern.
  final String name;
/// The matched source text.
  final String text;
/// 1-based start line of the matched range.
  final int startLine;
/// 1-based end line of the matched range.
  final int endLine;
/// Start byte offset in the source (UTF-8).
  final int startByte;
/// End byte offset in the source (UTF-8).
  final int endByte;
}

/// One query match — the set of captures produced by a single pattern match.
typedef QueryMatch = List<QueryCapture>;

/// Parses source with tree-sitter and runs a `.scm` query, returning the
/// matches grouped (so `@x.def` / `@x.name` captures from the same pattern stay
/// together). Holds native handles, so it must live and die inside one
/// isolate.
class TreeSitterParser {
/// Creates a [TreeSitterParser] backed by the given loader.
  TreeSitterParser(this._loader);

  final TreeSitterLoader _loader;
  TreeSitterBindings? _bindings;
  final Map<String, Pointer<TSLanguage>> _languages = {};
  final Map<String, Pointer<TSParser>> _parsers = {};

  /// Separator between independently-compiled query patterns (a `;;;` line).
  static final RegExp _patternSeparator = RegExp(
    r'^\s*;;;\s*$',
    multiLine: true,
  );

/// Whether the tree-sitter runtime is available.
  bool get isAvailable => _loader.isAvailable;

  TreeSitterBindings _requireBindings() {
    final runtime = _loader.runtimeLib;
    if (runtime == null) {
      throw TreeSitterUnavailable('libtree-sitter runtime not loaded');
    }
    return _bindings ??= TreeSitterBindings(runtime);
  }

  Pointer<TSLanguage> _language(String languageId) {
    final cached = _languages[languageId];
    if (cached != null) {
      return cached;
    }
    final lib = _loader.grammarLib(languageId);
    if (lib == null) {
      throw TreeSitterUnavailable('grammar for "$languageId" not loaded');
    }
    final lookup = lib
        .lookupFunction<Pointer<TSLanguage> Function(),
            TreeSitterLanguageLookup>('tree_sitter_$languageId');
    final lang = lookup();
    _languages[languageId] = lang;
    return lang;
  }

  Pointer<TSParser> _parser(String languageId) {
    final cached = _parsers[languageId];
    if (cached != null) {
      return cached;
    }
    final bindings = _requireBindings();
    final parser = bindings.parserNew();
    final ok = bindings.parserSetLanguage(parser, _language(languageId));
    if (!ok) {
      bindings.parserDelete(parser);
      throw TreeSitterUnavailable(
        'failed to set language "$languageId" (grammar/runtime ABI mismatch)',
      );
    }
    _parsers[languageId] = parser;
    return parser;
  }

  /// Parses [source] once, then compiles and runs each `;;;`-separated pattern
  /// in [querySource] independently. Patterns the installed grammar rejects
  /// (e.g. an unknown node type) are skipped rather than failing the whole
  /// query, so a partially-correct `.scm` still yields symbols. Throws only
  /// when the natives themselves are unavailable.
  List<QueryMatch> parseMatches({
    required String languageId,
    required String source,
    required String querySource,
  }) {
    final bindings = _requireBindings();
    final parser = _parser(languageId);
    final language = _language(languageId);

    final srcBytes = utf8.encode(source);
    final srcPtr = malloc<Uint8>(srcBytes.length + 1);
    final srcView = srcPtr.asTypedList(srcBytes.length + 1);
    srcView.setRange(0, srcBytes.length, srcBytes);
    srcView[srcBytes.length] = 0;

    final errorOffset = malloc<Uint32>();
    final errorType = malloc<Uint32>();
    final matchPtr = malloc<TSQueryMatch>();

    Pointer<TSTree> tree = nullptr;
    final matches = <QueryMatch>[];
    try {
      tree = bindings.parserParseString(
        parser,
        nullptr,
        srcPtr.cast<Char>(),
        srcBytes.length,
      );
      if (tree == nullptr) {
        return matches;
      }
      final root = bindings.treeRootNode(tree);

      for (final pattern in querySource.split(_patternSeparator)) {
        if (pattern.trim().isEmpty) {
          continue;
        }
        final queryPtr = pattern.toNativeUtf8();
        Pointer<TSQuery> query = nullptr;
        Pointer<TSQueryCursor> cursor = nullptr;
        try {
          query = bindings.queryNew(
            language,
            queryPtr.cast<Char>(),
            queryPtr.length,
            errorOffset,
            errorType,
          );
          // Null → the grammar rejected this pattern; skip it.
          if (query == nullptr) {
            continue;
          }
          cursor = bindings.queryCursorNew();
          bindings.queryCursorExec(cursor, query, root);
          while (bindings.queryCursorNextMatch(cursor, matchPtr)) {
            final match = matchPtr.ref;
            final captures = <QueryCapture>[];
            for (var i = 0; i < match.captureCount; i++) {
              final capture = match.captures[i];
              final node = capture.node;
              final lengthPtr = malloc<Uint32>();
              final namePtr = bindings.queryCaptureNameForId(
                query,
                capture.index,
                lengthPtr,
              );
              final name = namePtr == nullptr
                  ? ''
                  : namePtr.cast<Utf8>().toDartString(length: lengthPtr.value);
              malloc.free(lengthPtr);

              final startByte = bindings.nodeStartByte(node);
              final endByte = bindings.nodeEndByte(node);
              final startPoint = bindings.nodeStartPoint(node);
              final endPoint = bindings.nodeEndPoint(node);
              final text = (startByte <= endByte && endByte <= srcBytes.length)
                  ? utf8.decode(
                      srcBytes.sublist(startByte, endByte),
                      allowMalformed: true,
                    )
                  : '';
              captures.add(
                QueryCapture(
                  name: name,
                  text: text,
                  startLine: startPoint.row + 1,
                  endLine: endPoint.row + 1,
                  startByte: startByte,
                  endByte: endByte,
                ),
              );
            }
            matches.add(captures);
          }
        } finally {
          if (cursor != nullptr) {
            bindings.queryCursorDelete(cursor);
          }
          if (query != nullptr) {
            bindings.queryDelete(query);
          }
          malloc.free(queryPtr);
        }
      }
    } finally {
      if (tree != nullptr) {
        bindings.treeDelete(tree);
      }
      malloc.free(srcPtr);
      malloc.free(errorOffset);
      malloc.free(errorType);
      malloc.free(matchPtr);
    }
    return matches;
  }

  /// Frees cached parser handles. Call before the isolate exits.
  void dispose() {
    final bindings = _bindings;
    if (bindings != null) {
      for (final parser in _parsers.values) {
        bindings.parserDelete(parser);
      }
    }
    _parsers.clear();
    _languages.clear();
  }
}
