import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_natives/cc_natives.dart';

/// Symbols + edges extracted from a single source file.
class ExtractionResult {
  /// Constructs an [ExtractionResult].
  const ExtractionResult({required this.symbols, required this.edges});

  /// Empty result with no symbols or edges.
  const ExtractionResult.empty() : symbols = const [], edges = const [];

  /// Extracted code symbols.
  final List<CodeSymbol> symbols;
  /// Extracted code edges.
  final List<CodeEdge> edges;
}

/// Language-agnostic extractor driven by tree-sitter query capture names (see
/// `assets/code_index/queries/*.scm`). Pure and isolate-safe: give it a parsed
/// match set (via [TreeSitterParser]) and it maps captures to [CodeSymbol] /
/// [CodeEdge]. Adding a language requires only a new `.scm` + grammar lib.
class CodeExtractor {
  /// Creates a [CodeExtractor].
  const CodeExtractor();

  /// Parses source and extracts symbols and edges.
  ExtractionResult extract({
    required String workspaceId,
    required String repoId,
    required String filePath,
    required String source,
    required String languageId,
    required String querySource,
    required TreeSitterParser parser,
  }) {
    final List<QueryMatch> matches;
    try {
      matches = parser.parseMatches(
        languageId: languageId,
        source: source,
        querySource: querySource,
      );
    } on TreeSitterUnavailable {
      return const ExtractionResult.empty();
    }
    return extractFromMatches(
      workspaceId: workspaceId,
      repoId: repoId,
      filePath: filePath,
      languageId: languageId,
      matches: matches,
    );
  }

  /// Pure mapping from tree-sitter query [matches] to symbols + edges — no
  /// native dependency. Exposed for unit testing the capture-name contract.
  ExtractionResult extractFromMatches({
    required String workspaceId,
    required String repoId,
    required String filePath,
    required String languageId,
    required List<QueryMatch> matches,
  }) {
    final defs = _collectDefinitions(matches);
    final symbols = _buildSymbols(workspaceId, repoId, filePath, languageId, defs);
    final edges = _buildEdges(workspaceId, repoId, filePath, matches, defs);
    return ExtractionResult(symbols: symbols, edges: edges);
  }

  // --- Pass 1: definitions -------------------------------------------------

  List<_Def> _collectDefinitions(List<QueryMatch> matches) {
    final defs = <_Def>[];
    for (final match in matches) {
      QueryCapture? defCapture;
      final byName = <String, QueryCapture>{};
      for (final capture in match) {
        byName[capture.name] = capture;
        if (capture.name.endsWith('.def')) {
          defCapture = capture;
        }
      }
      if (defCapture == null) {
        continue;
      }
      final prefix = defCapture.name.substring(
        0,
        defCapture.name.length - '.def'.length,
      );
      final kind = _kindForPrefix(prefix);
      if (kind == null) {
        continue;
      }
      final nameCapture = byName['$prefix.name'];
      final name = (nameCapture != null && nameCapture.text.isNotEmpty)
          ? nameCapture.text
          : '<anonymous>';
      defs.add(
        _Def(
          kind: kind,
          name: name,
          startLine: defCapture.startLine,
          endLine: defCapture.endLine,
          startByte: defCapture.startByte,
          endByte: defCapture.endByte,
        ),
      );
    }
    // Outer ranges first (smaller start, then larger end) for parent lookup.
    defs.sort(
      (a, b) => a.startByte != b.startByte
          ? a.startByte.compareTo(b.startByte)
          : b.endByte.compareTo(a.endByte),
    );
    return defs;
  }

  List<CodeSymbol> _buildSymbols(
    String workspaceId,
    String repoId,
    String filePath,
    String languageId,
    List<_Def> defs,
  ) {
    final symbols = <CodeSymbol>[];
    for (final def in defs) {
      final parent = _innermostContainer(defs, def);
      final qualifiedName = parent != null
          ? '${parent.qualifiedName}.${def.name}'
          : def.name;
      def.qualifiedName = qualifiedName;
      def.symbolId = codeSymbolId(workspaceId, repoId, filePath, qualifiedName);
      symbols.add(
        CodeSymbol(
          id: def.symbolId!,
          workspaceId: workspaceId,
          repoId: repoId,
          kind: def.kind,
          name: def.name,
          qualifiedName: qualifiedName,
          filePath: filePath,
          language: languageId,
          startLine: def.startLine,
          endLine: def.endLine,
          parentName: parent?.qualifiedName,
        ),
      );
    }
    return symbols;
  }

  // --- Pass 2: edges -------------------------------------------------------

  List<CodeEdge> _buildEdges(
    String workspaceId,
    String repoId,
    String filePath,
    List<QueryMatch> matches,
    List<_Def> defs,
  ) {
    // Intra-file resolution index: simple name → symbol id (first wins).
    final byName = <String, String>{};
    for (final def in defs) {
      byName.putIfAbsent(def.name, () => def.symbolId!);
    }
    final fileNodeId = codeFileNodeId(workspaceId, repoId, filePath);
    final edges = <CodeEdge>[];
    final seen = <String>{};

    void addEdge({
      required String source,
      required CodeEdgeKind kind,
      required String rawTarget,
    }) {
      if (rawTarget.isEmpty) {
        return;
      }
      final resolvedId = byName[rawTarget];
      final targetKey = resolvedId ?? rawTarget;
      final id = codeEdgeId(workspaceId, repoId, source, targetKey, kind.name);
      if (!seen.add(id)) {
        return;
      }
      edges.add(
        CodeEdge(
          id: id,
          workspaceId: workspaceId,
          repoId: repoId,
          sourceSymbolId: source,
          sourceFilePath: filePath,
          kind: kind,
          targetSymbolId: resolvedId,
          targetName: resolvedId == null ? rawTarget : null,
        ),
      );
    }

    for (final match in matches) {
      for (final capture in match) {
        switch (capture.name) {
          case 'extends.name':
            addEdge(
              source: _containerAt(defs, capture.startByte) ?? fileNodeId,
              kind: CodeEdgeKind.extendsType,
              rawTarget: capture.text,
            );
          case 'implements.name':
            addEdge(
              source: _containerAt(defs, capture.startByte) ?? fileNodeId,
              kind: CodeEdgeKind.implementsType,
              rawTarget: capture.text,
            );
          case 'mixesin.name':
            addEdge(
              source: _containerAt(defs, capture.startByte) ?? fileNodeId,
              kind: CodeEdgeKind.mixesIn,
              rawTarget: capture.text,
            );
          case 'call.name':
            addEdge(
              source: _callableAt(defs, capture.startByte) ?? fileNodeId,
              kind: CodeEdgeKind.calls,
              rawTarget: capture.text,
            );
          case 'import.uri':
            addEdge(
              source: fileNodeId,
              kind: CodeEdgeKind.imports,
              rawTarget: _cleanUri(capture.text),
            );
        }
      }
    }
    return edges;
  }

  // --- Helpers -------------------------------------------------------------

  /// Innermost OTHER container def whose byte range strictly contains [def].
  _Def? _innermostContainer(List<_Def> defs, _Def def) {
    _Def? best;
    for (final candidate in defs) {
      if (identical(candidate, def) || !_isContainer(candidate.kind)) {
        continue;
      }
      if (candidate.startByte <= def.startByte &&
          candidate.endByte >= def.endByte &&
          !(candidate.startByte == def.startByte &&
              candidate.endByte == def.endByte)) {
        if (best == null ||
            (candidate.endByte - candidate.startByte) <
                (best.endByte - best.startByte)) {
          best = candidate;
        }
      }
    }
    return best;
  }

  /// Innermost container (class/mixin/extension/enum) symbol id containing
  /// [byte].
  String? _containerAt(List<_Def> defs, int byte) =>
      _innermostMatching(defs, byte, _isContainer);

  /// Innermost callable (function/method/getter/setter/constructor) symbol id
  /// containing [byte].
  String? _callableAt(List<_Def> defs, int byte) =>
      _innermostMatching(defs, byte, _isCallable);

  String? _innermostMatching(
    List<_Def> defs,
    int byte,
    bool Function(CodeSymbolKind) predicate,
  ) {
    _Def? best;
    for (final def in defs) {
      if (!predicate(def.kind)) {
        continue;
      }
      if (def.startByte <= byte && def.endByte >= byte) {
        if (best == null ||
            (def.endByte - def.startByte) < (best.endByte - best.startByte)) {
          best = def;
        }
      }
    }
    return best?.symbolId;
  }

  bool _isContainer(CodeSymbolKind kind) =>
      kind == CodeSymbolKind.classKind ||
      kind == CodeSymbolKind.mixin ||
      kind == CodeSymbolKind.extension ||
      kind == CodeSymbolKind.enumKind;

  bool _isCallable(CodeSymbolKind kind) =>
      kind == CodeSymbolKind.function ||
      kind == CodeSymbolKind.method ||
      kind == CodeSymbolKind.getter ||
      kind == CodeSymbolKind.setter ||
      kind == CodeSymbolKind.constructor;

  CodeSymbolKind? _kindForPrefix(String prefix) {
    switch (prefix) {
      case 'class':
        return CodeSymbolKind.classKind;
      case 'mixin':
        return CodeSymbolKind.mixin;
      case 'extension':
        return CodeSymbolKind.extension;
      case 'enum':
        return CodeSymbolKind.enumKind;
      case 'function':
        return CodeSymbolKind.function;
      case 'method':
        return CodeSymbolKind.method;
      case 'getter':
        return CodeSymbolKind.getter;
      case 'setter':
        return CodeSymbolKind.setter;
      case 'constructor':
        return CodeSymbolKind.constructor;
      case 'field':
        return CodeSymbolKind.field;
      case 'variable':
        return CodeSymbolKind.variable;
      case 'typedef':
        return CodeSymbolKind.typedefKind;
    }
    return null;
  }

  String _cleanUri(String raw) {
    var s = raw.trim();
    if (s.length >= 2) {
      final first = s[0];
      final last = s[s.length - 1];
      if ((first == "'" || first == '"') && first == last) {
        s = s.substring(1, s.length - 1);
      }
    }
    return s;
  }
}

/// Mutable scratch record used during extraction (qualifiedName + symbolId are
/// filled once parent containment is resolved).
class _Def {
  _Def({
    required this.kind,
    required this.name,
    required this.startLine,
    required this.endLine,
    required this.startByte,
    required this.endByte,
  });

  final CodeSymbolKind kind;
  final String name;
  final int startLine;
  final int endLine;
  final int startByte;
  final int endByte;
  String qualifiedName = '';
  String? symbolId;
}
