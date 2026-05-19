import 'dart:convert';
import 'dart:typed_data';

import 'package:control_center/core/domain/ports/embedding_port.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/features/code_graph/domain/entities/code_symbol.dart';
import 'package:control_center/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

/// Workspace-isolation guard for the repo-scoped code-graph tools. A repo may
/// be linked to several workspaces, so every tool requires the caller's
/// `workspace_id` and we reject access unless [repoId] is actually linked to
/// it. The underlying repository is itself workspace-partitioned (every query
/// is scoped by `workspaceId`); this check turns a cross-workspace lookup into
/// an explicit denial rather than silently empty results. Returns an error
/// [CallResult] to short-circuit `run`, or `null` when access is allowed.
Future<CallResult?> _denyUnlessRepoInWorkspace(
  WorkspaceRepository workspaceRepository,
  String workspaceId,
  String repoId,
) async {
  final linked =
      await workspaceRepository.isRepoLinkedToWorkspace(workspaceId, repoId);
  if (!linked) {
    return CallResult.error(
      'Repository $repoId is not part of workspace $workspaceId.',
    );
  }
  return null;
}

Map<String, dynamic> _symbolJson(CodeSymbol s, {int? depth}) => {
  'id': s.id,
  'name': s.name,
  'qualifiedName': s.qualifiedName,
  'kind': s.kind.name,
  'filePath': s.filePath,
  'startLine': s.startLine,
  'endLine': s.endLine,
  if (s.signature.isNotEmpty) 'signature': s.signature,
  'depth': ?depth,
};

/// Ranked symbol search over a repository's indexed code graph (BM25 + vector
/// + RRF, mirroring `search_memory`).
class SearchCodeTool extends McpTool {
  /// Creates a [SearchCodeTool].
  SearchCodeTool({
    required CodeGraphRepository repository,
    required WorkspaceRepository workspaceRepository,
    EmbeddingPort? embeddingService,
  }) : _repository = repository,
       _workspaceRepository = workspaceRepository,
       _embeddingService = embeddingService;

  final CodeGraphRepository _repository;
  final WorkspaceRepository _workspaceRepository;
  final EmbeddingPort? _embeddingService;

  @override
  String get name => 'search_code';

  @override
  String get description =>
      'Searches indexed code symbols (functions, classes, methods, fields) in '
      'a repository by name, signature, and doc comment. Hybrid BM25 + '
      'semantic by default. Returns ranked symbols with file:line.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace ID the repository belongs to.',
      },
      'repo_id': {
        'type': 'string',
        'description': 'The repository ID to search within.',
      },
      'query': {'type': 'string', 'description': 'Search query.'},
      'mode': {
        'type': 'string',
        'enum': ['keyword', 'semantic', 'hybrid'],
        'description': 'Search mode. Default: hybrid.',
      },
    },
    'required': ['workspace_id', 'repo_id', 'query'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final repoId = arguments['repo_id'];
    final query = arguments['query'];
    final mode = arguments['mode'] as String? ?? 'hybrid';
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (repoId is! String) {
      return CallResult.error('Missing repo_id');
    }
    if (query is! String) {
      return CallResult.error('Missing query');
    }
    final denied = await _denyUnlessRepoInWorkspace(
      _workspaceRepository,
      workspaceId,
      repoId,
    );
    if (denied != null) {
      return denied;
    }

    Float32List? queryEmbedding;
    final embedder = _embeddingService;
    if (mode != 'keyword' && embedder != null && embedder.isReady) {
      try {
        queryEmbedding = await embedder.embed(query);
      } catch (_) {}
    }

    final symbols = await _repository.search(
      workspaceId,
      repoId,
      query,
      queryEmbedding: mode == 'keyword' ? null : queryEmbedding,
    );
    return CallResult.success(
      jsonEncode({'symbols': symbols.map(_symbolJson).toList()}),
    );
  }
}

/// Looks up code symbols by exact name within a repository.
class CodeSymbolTool extends McpTool {
  /// Creates a [CodeSymbolTool].
  CodeSymbolTool({
    required CodeGraphRepository repository,
    required WorkspaceRepository workspaceRepository,
  }) : _repository = repository,
       _workspaceRepository = workspaceRepository;

  final CodeGraphRepository _repository;
  final WorkspaceRepository _workspaceRepository;

  @override
  String get name => 'code_symbol';

  @override
  String get description =>
      'Looks up code symbols by exact name within a repository (e.g. a class '
      'or function name). Returns matches with file:line and signature.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace ID the repository belongs to.',
      },
      'repo_id': {'type': 'string', 'description': 'The repository ID.'},
      'name': {'type': 'string', 'description': 'Exact symbol name.'},
    },
    'required': ['workspace_id', 'repo_id', 'name'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final repoId = arguments['repo_id'];
    final symbolName = arguments['name'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (repoId is! String) {
      return CallResult.error('Missing repo_id');
    }
    if (symbolName is! String) {
      return CallResult.error('Missing name');
    }
    final denied = await _denyUnlessRepoInWorkspace(
      _workspaceRepository,
      workspaceId,
      repoId,
    );
    if (denied != null) {
      return denied;
    }
    final symbols = await _repository.getByName(workspaceId, repoId, symbolName);
    return CallResult.success(
      jsonEncode({'symbols': symbols.map(_symbolJson).toList()}),
    );
  }
}

/// Lists the symbols that call/depend on a given symbol (incoming edges).
class CodeCallersTool extends McpTool {
  /// Creates a [CodeCallersTool].
  CodeCallersTool({required CodeGraphRepository repository})
    : _repository = repository;

  final CodeGraphRepository _repository;

  @override
  String get name => 'code_callers';

  @override
  String get description =>
      'Lists the symbols that call or depend on a given symbol (incoming '
      'edges). Pass a symbol_id from search_code or code_symbol.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': "The workspace ID the symbol's repository belongs to.",
      },
      'symbol_id': {
        'type': 'string',
        'description': 'The symbol ID (from search_code / code_symbol).',
      },
      'limit': {
        'type': 'integer',
        'description': 'Max results to return (default 50).',
      },
    },
    'required': ['workspace_id', 'symbol_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final symbolId = arguments['symbol_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (symbolId is! String) {
      return CallResult.error('Missing symbol_id');
    }
    final denied =
        await _denyUnlessSymbolInWorkspace(_repository, workspaceId, symbolId);
    if (denied != null) {
      return denied;
    }
    final limit = arguments['limit'] is int ? arguments['limit'] as int : 50;
    final symbols = await _repository.callers(workspaceId, symbolId, limit: limit);
    return CallResult.success(
      jsonEncode({'callers': symbols.map(_symbolJson).toList()}),
    );
  }
}

/// Lists the symbols a given symbol calls/depends on (outgoing edges).
class CodeCalleesTool extends McpTool {
  /// Creates a [CodeCalleesTool].
  CodeCalleesTool({required CodeGraphRepository repository})
    : _repository = repository;

  final CodeGraphRepository _repository;

  @override
  String get name => 'code_callees';

  @override
  String get description =>
      'Lists the symbols a given symbol calls or depends on (outgoing edges). '
      'Pass a symbol_id from search_code or code_symbol.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': "The workspace ID the symbol's repository belongs to.",
      },
      'symbol_id': {
        'type': 'string',
        'description': 'The symbol ID (from search_code / code_symbol).',
      },
      'limit': {
        'type': 'integer',
        'description': 'Max results to return (default 50).',
      },
    },
    'required': ['workspace_id', 'symbol_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final symbolId = arguments['symbol_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (symbolId is! String) {
      return CallResult.error('Missing symbol_id');
    }
    final denied =
        await _denyUnlessSymbolInWorkspace(_repository, workspaceId, symbolId);
    if (denied != null) {
      return denied;
    }
    final limit = arguments['limit'] is int ? arguments['limit'] as int : 50;
    final symbols = await _repository.callees(workspaceId, symbolId, limit: limit);
    return CallResult.success(
      jsonEncode({'callees': symbols.map(_symbolJson).toList()}),
    );
  }
}

/// Computes the transitive impact radius (reverse dependencies) of a symbol.
class CodeImpactTool extends McpTool {
  /// Creates a [CodeImpactTool].
  CodeImpactTool({required CodeGraphRepository repository})
    : _repository = repository;

  final CodeGraphRepository _repository;

  @override
  String get name => 'code_impact';

  @override
  String get description =>
      'Computes the transitive impact radius of a symbol — everything that '
      'directly or indirectly depends on it, up to a depth. Use before editing '
      'to gauge blast radius.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': "The workspace ID the symbol's repository belongs to.",
      },
      'symbol_id': {'type': 'string', 'description': 'The symbol ID.'},
      'depth': {
        'type': 'integer',
        'description': 'Max hops to traverse (1-6, default 2).',
      },
    },
    'required': ['workspace_id', 'symbol_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final symbolId = arguments['symbol_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (symbolId is! String) {
      return CallResult.error('Missing symbol_id');
    }
    final denied =
        await _denyUnlessSymbolInWorkspace(_repository, workspaceId, symbolId);
    if (denied != null) {
      return denied;
    }
    final depthArg = arguments['depth'];
    final depth = depthArg is int ? depthArg : 2;
    final subgraph = await _repository.impactRadius(
      workspaceId,
      symbolId,
      depth: depth,
    );
    final root = subgraph.root;
    return CallResult.success(
      jsonEncode({
        'root': root == null ? null : _symbolJson(root, depth: 0),
        'impacted': subgraph.nodes
            .map((s) => _symbolJson(s, depth: subgraph.depthById[s.id]))
            .toList(),
        'edgeCount': subgraph.edges.length,
      }),
    );
  }
}

/// Workspace-isolation guard for the symbol-scoped tools (callers/callees/
/// impact), which take a `symbol_id` rather than a `repo_id`. The repository's
/// `getById` is itself workspace-partitioned, so a symbol from another
/// workspace resolves to `null` — surfaced here as an explicit denial rather
/// than empty graph results. Returns an error [CallResult] to short-circuit
/// `run`, or `null` when the symbol exists in [workspaceId].
Future<CallResult?> _denyUnlessSymbolInWorkspace(
  CodeGraphRepository repository,
  String workspaceId,
  String symbolId,
) async {
  final symbol = await repository.getById(workspaceId, symbolId);
  if (symbol == null) {
    return CallResult.error(
      'Symbol $symbolId not found in workspace $workspaceId.',
    );
  }
  return null;
}
