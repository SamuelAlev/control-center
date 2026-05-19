import 'dart:convert';
import 'dart:ffi';

import 'package:cc_natives/src/code_index/tree_sitter_bindings.dart';
import 'package:cc_natives/src/code_index/tree_sitter_loader.dart';
import 'package:cc_natives/src/native_unavailable.dart';
import 'package:ffi/ffi.dart';

/// Thrown when the tree-sitter natives (the runtime or a grammar) are not
/// available. There is no degraded mode: a broken install must fail the caller
/// loudly rather than "index" every file to nothing. See
/// [NativeLibraryUnavailable].
class TreeSitterUnavailable implements NativeLibraryUnavailable {
  /// Creates a [TreeSitterUnavailable] with the given message.
  TreeSitterUnavailable(this.message);
  @override
  /// The error message.
  final String message;
  @override
  String toString() =>
      'TreeSitterUnavailable: $message (build the natives with '
      'scripts/natives/build_tree_sitter.sh, or rebuild the host bundle with '
      'them staged)';
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

  /// Compiled query cache, keyed by language id. Compiling the `;;;`-separated
  /// patterns costs more than parsing a typical file, and the sources are
  /// identical for every file of a language within a run — recompiling per
  /// file was the dominant native cost once parses moved to a long-lived
  /// worker. Invalidated when the query source changes (a dev editing a
  /// `.scm` mid-run).
  final Map<String, ({String source, List<Pointer<TSQuery>> patterns})>
  _queries = {};

  /// One reusable query cursor (`ts_query_cursor_exec` resets it per run)
  /// instead of a new/delete pair per pattern per file.
  Pointer<TSQueryCursor> _cursor = nullptr;

  /// How many `.scm` pattern compilations have happened on this instance.
  ///
  /// Test seam: the whole point of the cache is that this stays flat across
  /// files of the same language, and nothing else about it is observable from
  /// outside (the compiled handles are opaque native pointers).
  int get compileCount => _compileCount;
  int _compileCount = 0;

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
        .lookupFunction<
          Pointer<TSLanguage> Function(),
          TreeSitterLanguageLookup
        >('tree_sitter_$languageId');
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

  /// The compiled patterns for [languageId] + [querySource], from the cache
  /// when the source is unchanged, else compiled fresh (and the stale set
  /// freed). Patterns the grammar rejects (e.g. an unknown node type) are
  /// dropped rather than failing the whole query, so a partially-correct
  /// `.scm` still yields symbols.
  List<Pointer<TSQuery>> _compiledPatterns(
    String languageId,
    String querySource,
    TreeSitterBindings bindings,
    Pointer<TSLanguage> language,
  ) {
    final cached = _queries[languageId];
    if (cached != null && cached.source == querySource) {
      return cached.patterns;
    }
    if (cached != null) {
      for (final query in cached.patterns) {
        bindings.queryDelete(query);
      }
      _queries.remove(languageId);
    }
    final compiled = <Pointer<TSQuery>>[];
    final errorOffset = malloc<Uint32>();
    final errorType = malloc<Uint32>();
    try {
      for (final pattern in querySource.split(_patternSeparator)) {
        if (pattern.trim().isEmpty) {
          continue;
        }
        final queryPtr = pattern.toNativeUtf8();
        try {
          _compileCount++;
          final query = bindings.queryNew(
            language,
            queryPtr.cast<Char>(),
            queryPtr.length,
            errorOffset,
            errorType,
          );
          // Null → the grammar rejected this pattern; skip it.
          if (query != nullptr) {
            compiled.add(query);
          }
        } finally {
          malloc.free(queryPtr);
        }
      }
    } finally {
      malloc.free(errorOffset);
      malloc.free(errorType);
    }
    _queries[languageId] = (source: querySource, patterns: compiled);
    return compiled;
  }

  /// Parses [source] once, then runs each `;;;`-separated pattern in
  /// [querySource] independently (compiled once per language per instance —
  /// see [_compiledPatterns]). Throws only when the natives themselves are
  /// unavailable.
  List<QueryMatch> parseMatches({
    required String languageId,
    required String source,
    required String querySource,
  }) {
    final bindings = _requireBindings();
    final parser = _parser(languageId);
    final language = _language(languageId);
    final queries = _compiledPatterns(
      languageId,
      querySource,
      bindings,
      language,
    );

    final srcBytes = utf8.encode(source);
    final srcPtr = malloc<Uint8>(srcBytes.length + 1);
    final srcView = srcPtr.asTypedList(srcBytes.length + 1);
    srcView.setRange(0, srcBytes.length, srcBytes);
    srcView[srcBytes.length] = 0;

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
      if (_cursor == nullptr) {
        _cursor = bindings.queryCursorNew();
      }

      for (final query in queries) {
        bindings.queryCursorExec(_cursor, query, root);
        while (bindings.queryCursorNextMatch(_cursor, matchPtr)) {
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
      }
    } finally {
      if (tree != nullptr) {
        bindings.treeDelete(tree);
      }
      malloc.free(srcPtr);
      malloc.free(matchPtr);
    }
    return matches;
  }

  /// Frees cached parser, query, and cursor handles. Call before the isolate
  /// exits — these are native allocations an isolate's death does NOT
  /// reclaim.
  void dispose() {
    final bindings = _bindings;
    if (bindings != null) {
      for (final parser in _parsers.values) {
        bindings.parserDelete(parser);
      }
      for (final cached in _queries.values) {
        for (final query in cached.patterns) {
          bindings.queryDelete(query);
        }
      }
      if (_cursor != nullptr) {
        bindings.queryCursorDelete(_cursor);
        _cursor = nullptr;
      }
    }
    _parsers.clear();
    _languages.clear();
    _queries.clear();
  }
}
