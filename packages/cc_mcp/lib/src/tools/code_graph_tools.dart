import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_tree_port.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_mcp/src/log/cc_mcp_log.dart';

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
  final linked = await workspaceRepository.isRepoLinkedToWorkspace(
    workspaceId,
    repoId,
  );
  if (!linked) {
    return CallResult.error(
      'Repository $repoId is not part of workspace $workspaceId.',
    );
  }
  return null;
}

/// Resolves the graph partition a code-graph call should search: the
/// conversation's isolated worktree partition when [conversationId] is set
/// and the conversation owns a worktree for [repoId], else null (the linked
/// checkout's partition).
///
/// An EMPTY worktree partition is the normal steady state, not a failure: a
/// worktree stores only its delta against the linked checkout, so a conversation
/// that has not diverged owns no rows at all. Resolving to the linked partition
/// there is both correct and cheaper — the merged read would return exactly the
/// base rows anyway. It also covers the genuinely-unbuilt cases (provisioning in
/// flight, natives missing, an older host with no watch service). Fails OPEN to
/// the linked partition on any error.
Future<String?> _effectiveCheckoutId({
  required CodeGraphTreePort? tree,
  required CodeGraphRepository repository,
  required String workspaceId,
  required String repoId,
  String? conversationId,
}) async {
  if (tree == null) {
    return null;
  }
  String? checkoutId;
  try {
    checkoutId = await tree.checkoutIdFor(
      workspaceId: workspaceId,
      repoId: repoId,
      conversationId: conversationId,
    );
  } on Object catch (e) {
    CcMcpLog.w('code_graph', 'checkout resolution failed for $repoId: $e');
    return null;
  }
  if (checkoutId == null) {
    return null;
  }
  try {
    final built = await repository.hasIndexedFiles(
      workspaceId,
      repoId,
      checkoutId: checkoutId,
    );
    return built ? checkoutId : null;
  } on Object catch (e) {
    CcMcpLog.w('code_graph', 'checkout partition probe failed for $repoId: $e');
    return null;
  }
}

/// Filters [symbols] down to the ones whose file still exists in the tree the
/// CALLER reads, and self-heals the graph as it goes.
///
/// The code graph is built from the workspace's linked checkout and is only
/// refreshed by a re-index, so it drifts: it happily returns symbols for files
/// that were renamed or deleted weeks ago. An agent then `read`s those paths,
/// gets "File not found", and retries — the loop this exists to stop.
///
/// Two distinct verdicts, deliberately not conflated:
/// * absent from the CALLER's tree → hidden from this answer (a conversation's
///   own repo copy may sit at another revision, where the file legitimately
///   does not exist);
/// * absent from the INDEXED tree → provably dead rows, pruned via the same
///   [CodeGraphRepository.deleteFiles] the incremental indexer uses, so the
///   graph converges through use instead of waiting for the next full index.
///
/// Fails OPEN: with no [tree] wired, an unresolvable tree, or any error, the
/// symbols are returned untouched. A stale answer beats an empty one.
Future<({List<CodeSymbol> live, int omitted})> _liveSymbols(
  List<CodeSymbol> symbols, {
  required CodeGraphTreePort? tree,
  required CodeGraphRepository repository,
  required String workspaceId,
  String? conversationId,
  String? checkoutId,
}) async {
  if (tree == null || symbols.isEmpty) {
    return (live: symbols, omitted: 0);
  }
  final pathsByRepo = <String, Set<String>>{};
  for (final symbol in symbols) {
    (pathsByRepo[symbol.repoId] ??= <String>{}).add(symbol.filePath);
  }
  final visible = <String, Set<String>>{};
  for (final entry in pathsByRepo.entries) {
    CodeGraphPathAudit? audit;
    try {
      audit = await tree.audit(
        workspaceId: workspaceId,
        repoId: entry.key,
        paths: entry.value.toList(),
        conversationId: conversationId,
        checkoutId: checkoutId,
      );
    } on Object catch (e) {
      CcMcpLog.w('code_graph', 'path audit failed for repo ${entry.key}: $e');
      audit = null;
    }
    if (audit == null) {
      visible[entry.key] = entry.value;
      continue;
    }
    visible[entry.key] = audit.presentForCaller;
    if (audit.goneFromIndexedTree.isNotEmpty) {
      try {
        await repository.deleteFiles(
          workspaceId,
          entry.key,
          audit.goneFromIndexedTree.toList(),
          checkoutId: checkoutId,
        );
        CcMcpLog.i(
          'code_graph',
          'pruned ${audit.goneFromIndexedTree.length} stale file(s) from the '
              'index of repo ${entry.key}',
        );
      } on Object catch (e) {
        CcMcpLog.w('code_graph', 'stale-row prune failed: $e');
      }
    }
  }
  final live = [
    for (final symbol in symbols)
      if (visible[symbol.repoId]?.contains(symbol.filePath) ?? true) symbol,
  ];
  return (live: live, omitted: symbols.length - live.length);
}

/// The `staleOmitted` / `note` fields appended when verification hid symbols, so
/// an empty or thinned result reads as "the index is behind" rather than "this
/// code does not exist".
Map<String, dynamic> _staleNote(int omitted) => omitted == 0
    ? const {}
    : {
        'staleOmitted': omitted,
        'note':
            '$omitted indexed symbol(s) omitted: their files no longer exist '
            'in your working copy, so the code index is stale for them. '
            'Use search_files / search to find the current location.',
      };

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
    CodeGraphTreePort? tree,
  }) : _repository = repository,
       _workspaceRepository = workspaceRepository,
       _embeddingService = embeddingService,
       _tree = tree;

  final CodeGraphRepository _repository;
  final WorkspaceRepository _workspaceRepository;
  final EmbeddingPort? _embeddingService;
  final CodeGraphTreePort? _tree;

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
      // Injected from the trusted call scope, never asked of the model: it
      // selects which working copy results are verified against.
      'conversation_id': {
        'type': 'string',
        'description':
            'Filled in automatically for agent callers; results are verified '
            "against that conversation's working copy.",
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

    final conversationId = arguments['conversation_id'] as String?;
    final checkoutId = await _effectiveCheckoutId(
      tree: _tree,
      repository: _repository,
      workspaceId: workspaceId,
      repoId: repoId,
      conversationId: conversationId,
    );

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
      checkoutId: checkoutId,
    );
    final verified = await _liveSymbols(
      symbols,
      tree: _tree,
      repository: _repository,
      workspaceId: workspaceId,
      conversationId: conversationId,
      checkoutId: checkoutId,
    );
    return CallResult.success(
      jsonEncode({
        'symbols': verified.live.map(_symbolJson).toList(),
        ..._staleNote(verified.omitted),
      }),
    );
  }
}

/// Looks up code symbols by exact name within a repository.
class CodeSymbolTool extends McpTool {
  /// Creates a [CodeSymbolTool].
  CodeSymbolTool({
    required CodeGraphRepository repository,
    required WorkspaceRepository workspaceRepository,
    CodeGraphTreePort? tree,
  }) : _repository = repository,
       _workspaceRepository = workspaceRepository,
       _tree = tree;

  final CodeGraphRepository _repository;
  final WorkspaceRepository _workspaceRepository;
  final CodeGraphTreePort? _tree;

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
      'conversation_id': {
        'type': 'string',
        'description':
            'Filled in automatically for agent callers; results are verified '
            "against that conversation's working copy.",
      },
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
    final conversationId = arguments['conversation_id'] as String?;
    final checkoutId = await _effectiveCheckoutId(
      tree: _tree,
      repository: _repository,
      workspaceId: workspaceId,
      repoId: repoId,
      conversationId: conversationId,
    );
    final symbols = await _repository.getByName(
      workspaceId,
      repoId,
      symbolName,
      checkoutId: checkoutId,
    );
    final verified = await _liveSymbols(
      symbols,
      tree: _tree,
      repository: _repository,
      workspaceId: workspaceId,
      conversationId: conversationId,
      checkoutId: checkoutId,
    );
    return CallResult.success(
      jsonEncode({
        'symbols': verified.live.map(_symbolJson).toList(),
        ..._staleNote(verified.omitted),
      }),
    );
  }
}

/// Lists the symbols that call/depend on a given symbol (incoming edges).
class CodeCallersTool extends McpTool {
  /// Creates a [CodeCallersTool].
  CodeCallersTool({
    required CodeGraphRepository repository,
    CodeGraphTreePort? tree,
  }) : _repository = repository,
       _tree = tree;

  final CodeGraphRepository _repository;
  final CodeGraphTreePort? _tree;

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
      'conversation_id': {
        'type': 'string',
        'description':
            'Filled in automatically for agent callers; results are verified '
            "against that conversation's working copy.",
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
    final denied = await _denyUnlessSymbolInWorkspace(
      _repository,
      workspaceId,
      symbolId,
    );
    if (denied != null) {
      return denied;
    }
    final limit = arguments['limit'] is int ? arguments['limit'] as int : 50;
    final conversationId = arguments['conversation_id'] as String?;
    // The symbol resolved above carries the repo, which is what the checkout
    // lookup needs; traversal MUST be scoped to it or a worktree's edges into
    // the base partition surface other conversations' callers.
    final checkoutId = await _effectiveCheckoutId(
      tree: _tree,
      repository: _repository,
      workspaceId: workspaceId,
      repoId: (await _repository.getById(workspaceId, symbolId))?.repoId ?? '',
      conversationId: conversationId,
    );
    final symbols = await _repository.callers(
      workspaceId,
      symbolId,
      limit: limit,
      checkoutId: checkoutId,
    );
    final verified = await _liveSymbols(
      symbols,
      tree: _tree,
      repository: _repository,
      workspaceId: workspaceId,
      conversationId: conversationId,
      checkoutId: checkoutId,
    );
    return CallResult.success(
      jsonEncode({
        'callers': verified.live.map(_symbolJson).toList(),
        ..._staleNote(verified.omitted),
      }),
    );
  }
}

/// Lists the symbols a given symbol calls/depends on (outgoing edges).
class CodeCalleesTool extends McpTool {
  /// Creates a [CodeCalleesTool].
  CodeCalleesTool({
    required CodeGraphRepository repository,
    CodeGraphTreePort? tree,
  }) : _repository = repository,
       _tree = tree;

  final CodeGraphRepository _repository;
  final CodeGraphTreePort? _tree;

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
      'conversation_id': {
        'type': 'string',
        'description':
            'Filled in automatically for agent callers; results are verified '
            "against that conversation's working copy.",
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
    final denied = await _denyUnlessSymbolInWorkspace(
      _repository,
      workspaceId,
      symbolId,
    );
    if (denied != null) {
      return denied;
    }
    final limit = arguments['limit'] is int ? arguments['limit'] as int : 50;
    final conversationId = arguments['conversation_id'] as String?;
    // The symbol resolved above carries the repo, which is what the checkout
    // lookup needs; traversal MUST be scoped to it or a worktree's edges into
    // the base partition surface other conversations' callers.
    final checkoutId = await _effectiveCheckoutId(
      tree: _tree,
      repository: _repository,
      workspaceId: workspaceId,
      repoId: (await _repository.getById(workspaceId, symbolId))?.repoId ?? '',
      conversationId: conversationId,
    );
    final symbols = await _repository.callees(
      workspaceId,
      symbolId,
      limit: limit,
      checkoutId: checkoutId,
    );
    final verified = await _liveSymbols(
      symbols,
      tree: _tree,
      repository: _repository,
      workspaceId: workspaceId,
      conversationId: conversationId,
      checkoutId: checkoutId,
    );
    return CallResult.success(
      jsonEncode({
        'callees': verified.live.map(_symbolJson).toList(),
        ..._staleNote(verified.omitted),
      }),
    );
  }
}

/// Computes the transitive impact radius (reverse dependencies) of a symbol.
class CodeImpactTool extends McpTool {
  /// Creates a [CodeImpactTool].
  CodeImpactTool({
    required CodeGraphRepository repository,
    CodeGraphTreePort? tree,
  }) : _repository = repository,
       _tree = tree;

  final CodeGraphRepository _repository;
  final CodeGraphTreePort? _tree;

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
      'conversation_id': {
        'type': 'string',
        'description':
            'Filled in automatically for agent callers; results are verified '
            "against that conversation's working copy.",
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
    final denied = await _denyUnlessSymbolInWorkspace(
      _repository,
      workspaceId,
      symbolId,
    );
    if (denied != null) {
      return denied;
    }
    final depthArg = arguments['depth'];
    final depth = depthArg is int ? depthArg : 2;
    final conversationId = arguments['conversation_id'] as String?;
    final checkoutId = await _effectiveCheckoutId(
      tree: _tree,
      repository: _repository,
      workspaceId: workspaceId,
      repoId: (await _repository.getById(workspaceId, symbolId))?.repoId ?? '',
      conversationId: conversationId,
    );
    final subgraph = await _repository.impactRadius(
      workspaceId,
      symbolId,
      depth: depth,
      checkoutId: checkoutId,
    );
    final root = subgraph.root;
    // The root is reported as-is (the caller named its symbol_id and the guard
    // above resolved it); only the impact set is verified, since that is what
    // the agent goes on to open.
    final verified = await _liveSymbols(
      subgraph.nodes,
      tree: _tree,
      repository: _repository,
      workspaceId: workspaceId,
      conversationId: conversationId,
      checkoutId: checkoutId,
    );
    return CallResult.success(
      jsonEncode({
        'root': root == null ? null : _symbolJson(root, depth: 0),
        'impacted': verified.live
            .map((s) => _symbolJson(s, depth: subgraph.depthById[s.id]))
            .toList(),
        'edgeCount': subgraph.edges.length,
        ..._staleNote(verified.omitted),
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
