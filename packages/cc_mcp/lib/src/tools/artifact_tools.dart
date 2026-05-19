import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show ConcurrencyConflictException;
import 'package:cc_domain/core/domain/events/artifact_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_plain_text.dart';
import 'package:cc_domain/features/governance/domain/services/work_product_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:uuid/uuid.dart';

/// The block grammar, described once for both publishing tools.
///
/// Written for a weak local model: every kind on its own line, exact key names,
/// no prose between them. The "no HTML" sentence is load-bearing — the first
/// thing a model reaches for when asked to "make a nice report" is a table in
/// HTML, which the native renderer will never draw.
const String _blockGrammar =
    'An ordered list of typed blocks. Each block is an object with a "type" '
    'and that type\'s fields:\n'
    '- markdown: {text} — prose, headings, lists, links.\n'
    '- table: {columns: [{key, label, align?: left|center|right}], '
    'rows: [[cell, cell, ...], ...]} — cells are already-formatted text, one '
    'per column, in column order.\n'
    '- chart: {chartKind: bar|line|pie, series: [{label, points: '
    '[{x: "category", y: 12.5}, ...]}], title?, xLabel?, yLabel?} — x is a '
    'category label, y is a number. A pie chart draws the first series only.\n'
    '- mermaid: {source} — drawable diagram types: flowchart/graph, '
    'stateDiagram, classDiagram, erDiagram, sequenceDiagram, pie, timeline. '
    'Anything else renders as a code block.\n'
    '- code: {code, language?, title?, lineStart?} — title is conventionally '
    'the file path.\n'
    '- data: {json} — any JSON value, rendered as a collapsible tree.\n'
    'There is NO html block and markdown HTML is not rendered — use the typed '
    'blocks instead. Invalid blocks are dropped and reported back to you; the '
    'valid ones still publish.';

/// The JSON schema fragment for a `blocks` argument.
///
/// The `type` enum derives from [artifactBlockKinds] rather than repeating the
/// names, so a kind cannot exist in the decoder while staying invisible to the
/// model (or vice versa) — a round-trip test asserts the three projections of
/// that list agree.
Map<String, dynamic> _blocksSchema() => {
  'type': 'array',
  'description': _blockGrammar,
  'items': {
    'type': 'object',
    'properties': {
      'type': {'type': 'string', 'enum': artifactBlockKinds},
    },
    'required': ['type'],
  },
};

/// Publishes a typed block document into the conversation the agent is working
/// in, stored as a WorkProduct + its first revision.
///
/// The conversation + workspace are resolved server-side from the agent's active
/// run (the same resolution `submit_plan` / `exit_plan_mode` use), so an
/// artifact can only land in the room the agent is actually working in and can
/// never be aimed at another workspace.
///
/// Validation is deliberately LOOSE (see [ArtifactDocumentCodec]): a
/// slightly-off block is dropped with a precise error path echoed back in the
/// result, and the valid blocks still publish. Refusing the whole document
/// would cost the agent a full turn to re-derive content it already computed —
/// and in practice means the operator sees nothing at all.
///
/// Available in EVERY conversation mode. Publishing an artifact is a knowledge
/// write (like `propose_fact`), not a worktree mutation: it writes one local row
/// and posts one message, touches no filesystem, spawns no process, and reaches
/// no external system — hence no `ActionClass` and no approval prompt.
class PublishArtifactTool extends McpTool {
  /// Creates a [PublishArtifactTool].
  PublishArtifactTool({
    required AgentRunLogRepository runLogRepository,
    required WorkProductService workProducts,
    MessagingRepository? messaging,
    DomainEventBus? eventBus,
  }) : _runLogs = runLogRepository,
       _workProducts = workProducts,
       _messaging = messaging,
       _eventBus = eventBus;

  final AgentRunLogRepository _runLogs;
  final WorkProductService _workProducts;

  /// Posts the artifact bubble into the authoring conversation. Null skips it
  /// (the artifact still exists and is listed in the side panel).
  final MessagingRepository? _messaging;

  /// Publishes [ArtifactPublished]. Null skips it.
  final DomainEventBus? _eventBus;

  static const _uuid = Uuid();

  @override
  String get name => 'publish_artifact';

  @override
  String get description =>
      'Publish a rich document into this conversation: an ordered list of '
      'typed blocks (markdown, tables, charts, mermaid diagrams, code, JSON) '
      'rendered natively in the chat and kept with revision history. Use it '
      'whenever the answer is a deliverable rather than a remark — a '
      'comparison table, a metrics chart, an architecture diagram, an audit '
      'report. Returns the artifact id; revise it later with revise_artifact.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'agent_id': {
        'type': 'string',
        'description': 'Your own agent id (resolves the active run).',
      },
      'title': {
        'type': 'string',
        'description': 'Short title shown on the artifact card.',
      },
      'artifact_type': {
        'type': 'string',
        'enum': ['plan', 'document', 'diff', 'report', 'note'],
        'description': 'Artifact kind (default document).',
      },
      'blocks': _blocksSchema(),
    },
    'required': ['workspace_id', 'agent_id', 'title', 'blocks'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final agentId = arguments['agent_id'];
    if (agentId is! String || agentId.isEmpty) {
      return CallResult.error('Missing or invalid argument: agent_id');
    }
    final title = arguments['title'];
    if (title is! String || title.trim().isEmpty) {
      return CallResult.error('Missing or invalid argument: title');
    }

    final context = await resolveArtifactRunContext(
      runLogs: _runLogs,
      agentId: agentId,
      workspaceId: workspaceId,
      verb: 'publish_artifact',
    );
    if (context.error != null) {
      return CallResult.error(context.error!);
    }
    final conversationId = context.conversationId!;

    final decoded = ArtifactDocumentCodec.decodeLoose(arguments['blocks']);
    if (decoded.document.isEmpty) {
      return CallResult.error(
        'No valid blocks — nothing was published:\n'
        '${decoded.errors.map((e) => '- $e').join('\n')}\n'
        'Fix these and call publish_artifact again.',
      );
    }
    final blocks = ArtifactDocumentCodec.assignBlockIds(
      decoded.document.blocks,
    );
    final document = ArtifactDocument(blocks: blocks);

    final product = await _workProducts.create(
      workspaceId: workspaceId,
      title: title.trim(),
      artifactType: WorkProductType.fromStorage(
        arguments['artifact_type'] is String
            ? arguments['artifact_type'] as String
            : null,
      ),
      agentId: agentId,
    );
    final revision = await _workProducts.addRevision(
      workspaceId: workspaceId,
      workProductId: product.id,
      content: document.toEnvelopeJsonString(),
      authorId: agentId,
      summary: 'Published ${_blocksLabel(blocks.length)}',
    );

    // Announce it in the room it was authored in. Best-effort: a messaging
    // failure must not lose an already-persisted artifact.
    final messaging = _messaging;
    if (messaging != null) {
      try {
        await messaging.sendMessage(
          workspaceId: workspaceId,
          channelId: context.channelId!,
          conversationId: conversationId,
          content:
              'Published an artifact: ${product.title} '
              '(${_blocksLabel(blocks.length)})',
          senderId: agentId,
          senderType: 'agent',
          messageType: 'artifact',
          // Ids only. The bubble watches the work-product row, so later
          // revisions re-render in place instead of adding feed churn.
          metadata: {'workProductId': product.id, 'revisionId': revision.id},
          id: _uuid.v4(),
        );
      } on Object catch (_) {
        // Swallowed on purpose — the artifact exists and the side panel has it.
      }
    }
    _eventBus?.publish(
      ArtifactPublished(
        workProductId: product.id,
        revisionId: revision.id,
        workspaceId: workspaceId,
        conversationId: conversationId,
        agentId: agentId,
        revisionNumber: revision.revisionNumber,
        blockCount: blocks.length,
        title: product.title,
        occurredAt: revision.createdAt,
      ),
    );

    return CallResult.success(
      jsonEncode({
        'work_product_id': product.id,
        'revision_id': revision.id,
        'revision_number': revision.revisionNumber,
        'block_count': blocks.length,
        'block_ids': [for (final b in blocks) b.id],
        'warnings': decoded.warnings,
        'block_errors': decoded.errors,
        'message': _publishMessage(decoded.errors, decoded.warnings),
      }),
    );
  }
}

/// Replaces an artifact's content with a new revision (full replacement).
///
/// Per-block edit operations are deliberately deferred: a revision is the v1
/// increment model, which keeps history honest (every published state is
/// recoverable via `restoreRevision`) and keeps the tool contract small enough
/// for a weak model to hit on the first try.
///
/// Posts NO second channel message — the artifact bubble watches the
/// work-product row, so the existing card re-renders with the new revision. It
/// publishes [ArtifactRevised] instead, which is the lane notifications and the
/// side panel listen on.
class ReviseArtifactTool extends McpTool {
  /// Creates a [ReviseArtifactTool].
  ReviseArtifactTool({
    required AgentRunLogRepository runLogRepository,
    required WorkProductService workProducts,
    required WorkProductRepository repository,
    DomainEventBus? eventBus,
  }) : _runLogs = runLogRepository,
       _workProducts = workProducts,
       _repository = repository,
       _eventBus = eventBus;

  final AgentRunLogRepository _runLogs;
  final WorkProductService _workProducts;
  final WorkProductRepository _repository;
  final DomainEventBus? _eventBus;

  @override
  String get name => 'revise_artifact';

  @override
  String get description =>
      'Replace a published artifact\'s blocks with a new revision. The '
      'existing card in the conversation re-renders in place and the previous '
      'revision stays recoverable. Supply the FULL block list — a revision '
      'replaces the document, it does not patch it.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'agent_id': {
        'type': 'string',
        'description': 'Your own agent id (resolves the active run).',
      },
      'work_product_id': {
        'type': 'string',
        'description': 'The artifact id returned by publish_artifact.',
      },
      'blocks': _blocksSchema(),
      'summary': {
        'type': 'string',
        'description': 'One line on what changed (shown in the history).',
      },
    },
    'required': ['workspace_id', 'agent_id', 'work_product_id', 'blocks'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final agentId = arguments['agent_id'];
    if (agentId is! String || agentId.isEmpty) {
      return CallResult.error('Missing or invalid argument: agent_id');
    }
    final productId = arguments['work_product_id'];
    if (productId is! String || productId.isEmpty) {
      return CallResult.error('Missing or invalid argument: work_product_id');
    }

    final context = await resolveArtifactRunContext(
      runLogs: _runLogs,
      agentId: agentId,
      workspaceId: workspaceId,
      verb: 'revise_artifact',
    );
    if (context.error != null) {
      return CallResult.error(context.error!);
    }

    // Workspace-scoped read: a work product owned by another workspace is
    // simply not found, so an id guessed or carried across rooms leaks nothing.
    final product = await _repository.getById(workspaceId, productId);
    if (product == null) {
      return CallResult.error('Artifact $productId not found.');
    }

    final decoded = ArtifactDocumentCodec.decodeLoose(arguments['blocks']);
    if (decoded.document.isEmpty) {
      return CallResult.error(
        'No valid blocks — the artifact was left unchanged:\n'
        '${decoded.errors.map((e) => '- $e').join('\n')}\n'
        'Fix these and call revise_artifact again.',
      );
    }
    // Ids already spent by earlier revisions are reserved, so a new block never
    // inherits a retired block's id: an id identifies the same block for the
    // artifact's whole history, which is what makes per-block anchors possible.
    final blocks = ArtifactDocumentCodec.assignBlockIds(
      decoded.document.blocks,
      reserved: await _spentBlockIds(workspaceId, productId),
    );
    final document = ArtifactDocument(blocks: blocks);

    final summary = arguments['summary'];
    final WorkProductRevision revision;
    try {
      revision = await _workProducts.addRevision(
        workspaceId: workspaceId,
        workProductId: productId,
        content: document.toEnvelopeJsonString(),
        // Optimistic concurrency against the head we just read: a human
        // restoring a revision mid-run must not be silently clobbered.
        baseRevisionId: product.currentRevisionId,
        authorId: agentId,
        summary: summary is String && summary.trim().isNotEmpty
            ? summary.trim()
            : 'Revised to ${_blocksLabel(blocks.length)}',
      );
    } on ConcurrencyConflictException catch (e) {
      return CallResult.error(
        '${e.message}\nRe-read it with get_artifact and revise again.',
      );
    }

    _eventBus?.publish(
      ArtifactRevised(
        workProductId: productId,
        revisionId: revision.id,
        workspaceId: workspaceId,
        conversationId: context.conversationId!,
        agentId: agentId,
        revisionNumber: revision.revisionNumber,
        blockCount: blocks.length,
        summary: revision.summary,
        occurredAt: revision.createdAt,
      ),
    );

    return CallResult.success(
      jsonEncode({
        'work_product_id': productId,
        'revision_id': revision.id,
        'revision_number': revision.revisionNumber,
        'block_count': blocks.length,
        'block_ids': [for (final b in blocks) b.id],
        'warnings': decoded.warnings,
        'block_errors': decoded.errors,
        'message': _publishMessage(decoded.errors, decoded.warnings),
      }),
    );
  }

  /// Every block id any revision of [productId] has ever used.
  Future<Set<String>> _spentBlockIds(
    String workspaceId,
    String productId,
  ) async {
    final revisions = await _repository.getRevisions(workspaceId, productId);
    final spent = <String>{};
    for (final revision in revisions) {
      final document = ArtifactDocument.tryParseContent(revision.content);
      if (document != null) {
        spent.addAll(ArtifactDocumentCodec.blockIdsOf(document.blocks));
      }
    }
    return spent;
  }
}

/// Lists the workspace's artifacts (newest first) so an agent can find one to
/// read or revise.
class ListArtifactsTool extends McpTool {
  /// Creates a [ListArtifactsTool].
  ListArtifactsTool({required WorkProductRepository repository})
    : _repository = repository;

  final WorkProductRepository _repository;

  /// Default page size — enough to find a recent artifact, small enough that a
  /// busy workspace does not flood the agent's context.
  static const int defaultLimit = 30;

  @override
  String get name => 'list_artifacts';

  @override
  String get description =>
      'Lists this workspace\'s artifacts (newest first) with their id, title, '
      'type, and revision count. Read one with get_artifact. Artifacts share '
      'storage with work products, so documents saved by other tools appear '
      'here too — get_artifact reports which are block documents.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'artifact_type': {
        'type': 'string',
        'enum': ['plan', 'document', 'diff', 'report', 'note'],
        'description': 'Optional kind filter.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Max rows (default $defaultLimit).',
      },
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final typeFilter = arguments['artifact_type'] is String
        ? WorkProductType.fromStorage(arguments['artifact_type'] as String)
        : null;
    // Tolerant: a model that quotes the number ("30") gets the default rather
    // than an argument-type error on a read-only listing.
    final raw = arguments['limit'];
    final limit = raw is num ? raw.toInt() : defaultLimit;

    var products = await _repository.watchByWorkspace(workspaceId).first;
    if (typeFilter != null) {
      products = products.where((p) => p.artifactType == typeFilter).toList();
    }
    final page = products.take(limit < 1 ? defaultLimit : limit).toList();
    return CallResult.success(
      jsonEncode({
        'artifacts': [for (final p in page) _productJson(p)],
        'count': page.length,
        'total': products.length,
      }),
    );
  }
}

/// Returns one artifact's decoded blocks, plus its revision history.
class GetArtifactTool extends McpTool {
  /// Creates a [GetArtifactTool].
  GetArtifactTool({required WorkProductRepository repository})
    : _repository = repository;

  final WorkProductRepository _repository;

  @override
  String get name => 'get_artifact';

  @override
  String get description =>
      'Returns an artifact\'s blocks AND a readable text rendering (the head '
      'revision by default, or '
      'revision_id) plus its revision history. Use it before revise_artifact '
      'so your replacement keeps the parts you did not mean to change.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'work_product_id': {'type': 'string', 'description': 'Artifact id.'},
      'revision_id': {
        'type': 'string',
        'description': 'Read a specific revision instead of the head.',
      },
    },
    'required': ['workspace_id', 'work_product_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final productId = arguments['work_product_id'];
    if (productId is! String || productId.isEmpty) {
      return CallResult.error('Missing or invalid argument: work_product_id');
    }
    final product = await _repository.getById(workspaceId, productId);
    if (product == null) {
      return CallResult.error('Artifact $productId not found.');
    }
    final revisions = await _repository.getRevisions(workspaceId, productId);

    final requested = arguments['revision_id'];
    final WorkProductRevision? revision;
    if (requested is String && requested.isNotEmpty) {
      revision = revisions.where((r) => r.id == requested).firstOrNull;
      if (revision == null) {
        return CallResult.error(
          'Revision $requested does not belong to artifact $productId.',
        );
      }
    } else {
      revision =
          revisions
              .where((r) => r.id == product.currentRevisionId)
              .firstOrNull ??
          revisions.firstOrNull;
    }

    final document = revision == null
        ? null
        : ArtifactDocument.tryParseContent(revision.content);
    return CallResult.success(
      jsonEncode({
        ..._productJson(product),
        'revision_id': revision?.id,
        'revision_number': revision?.revisionNumber,
        // A work product written by `save_work_product_revision` holds plain
        // markdown, not blocks. Say so instead of pretending it decoded to
        // nothing.
        'format': document != null
            ? ArtifactDocument.formatVersion
            : (revision == null ? null : 'text'),
        'blocks': document == null
            ? null
            : [for (final b in document.blocks) b.toJson()],
        // A readable rendering alongside the typed blocks. This is what a READING
        // agent actually wants: it costs a fraction of the tokens and needs no
        // knowledge of the block schema, so one agent can consume another's
        // artifact without a second resolution path (the `artifact://` URI the
        // spec sketched would have been sugar over exactly this).
        'text': document == null
            ? revision?.content
            : artifactDocumentToPlainText(document),
        'content': document == null ? revision?.content : null,
        'revisions': [
          for (final r in revisions)
            {
              'id': r.id,
              'revision_number': r.revisionNumber,
              'summary': r.summary,
              'author_id': r.authorId,
              'created_at': r.createdAt.toIso8601String(),
            },
        ],
      }),
    );
  }
}

/// The conversation + workspace an artifact tool call belongs to, or the error
/// to hand back verbatim.
class ArtifactRunContext {
  /// Creates an [ArtifactRunContext].
  const ArtifactRunContext({this.channelId, this.conversationId, this.error});

  /// The channel owning [conversationId], or null when [error] is set. Carried
  /// separately because a side conversation ("parenthesis") has its own id: a
  /// message posted with the conversation id as the channel id would land in the
  /// wrong stream.
  final String? channelId;

  /// The resolved conversation, or null when [error] is set.
  final String? conversationId;

  /// The rejection message, or null on success.
  final String? error;
}

/// Resolves the conversation an agent's active run is working in, rejecting a
/// cross-workspace run and a run with no conversation.
///
/// Shared by both publishing tools so the isolation checks cannot drift apart:
/// the workspace comes from the RUN, never from the caller's claim alone, and a
/// mismatch is denied loudly rather than silently retargeted.
Future<ArtifactRunContext> resolveArtifactRunContext({
  required AgentRunLogRepository runLogs,
  required String agentId,
  required String workspaceId,
  required String verb,
}) async {
  final run = await runLogs.activeRunForAgent(workspaceId, agentId);
  if (run == null) {
    return ArtifactRunContext(
      error:
          'No active run found for agent $agentId — $verb publishes into '
          'the conversation your current run is working in.',
    );
  }
  if (run.workspaceId != workspaceId) {
    return const ArtifactRunContext(
      error: 'The active run belongs to a different workspace.',
    );
  }
  final conversationId = run.conversationId ?? run.channelId;
  if (conversationId == null || conversationId.isEmpty) {
    return const ArtifactRunContext(
      error:
          'Your active run is not tied to a conversation — an artifact '
          'needs one to be published into.',
    );
  }
  return ArtifactRunContext(
    // The main conversation's id equals its channel's id, so a run that only
    // recorded a conversation still addresses the right channel.
    channelId: run.channelId ?? conversationId,
    conversationId: conversationId,
  );
}

Map<String, dynamic> _productJson(WorkProduct w) => {
  'id': w.id,
  'title': w.title,
  'artifact_type': w.artifactType.name,
  'agent_id': w.agentId,
  'ticket_id': w.ticketId,
  'current_revision_id': w.currentRevisionId,
  'updated_at': w.updatedAt.toIso8601String(),
};

String _blocksLabel(int count) => '$count ${count == 1 ? 'block' : 'blocks'}';

String _publishMessage(List<String> errors, List<String> warnings) {
  if (errors.isEmpty && warnings.isEmpty) {
    return 'The artifact is live in the conversation.';
  }
  final parts = <String>['The artifact is live in the conversation.'];
  if (errors.isNotEmpty) {
    parts.add(
      '${errors.length} block(s) were DROPPED as invalid — see '
      'block_errors; call revise_artifact with them fixed.',
    );
  }
  if (warnings.isNotEmpty) {
    parts.add('${warnings.length} block(s) render degraded — see warnings.');
  }
  return parts.join(' ');
}
