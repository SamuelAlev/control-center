import 'dart:convert';

import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_domain/features/governance/domain/services/work_product_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

Map<String, dynamic> _productJson(WorkProduct w) => {
  'id': w.id,
  'title': w.title,
  'artifact_type': w.artifactType.name,
  'ticket_id': w.ticketId,
  'agent_id': w.agentId,
  'current_revision_id': w.currentRevisionId,
  'updated_at': w.updatedAt.toIso8601String(),
};

/// Creates a durable, versioned work-product artifact (plan, document, …).
class CreateWorkProductTool extends McpTool {
  /// Creates a [CreateWorkProductTool].
  CreateWorkProductTool({required WorkProductService service})
    : _service = service;

  final WorkProductService _service;

  @override
  String get name => 'create_work_product';

  @override
  String get description =>
      'Creates a durable deliverable artifact (plan, document, diff, report, '
      'or note) attached to a task. Add content with save_work_product_revision.';

  @override
  bool get requiresApproval => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'title': {'type': 'string', 'description': 'Artifact title.'},
      'artifact_type': {
        'type': 'string',
        'enum': ['plan', 'document', 'diff', 'report', 'note'],
        'description': 'Artifact kind (default document).',
      },
      'ticket_id': {'type': 'string', 'description': 'Owning task id.'},
      'agent_id': {'type': 'string', 'description': 'Authoring agent id.'},
    },
    'required': ['workspace_id', 'title'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final title = arguments['title'];
    if (title is! String) {
      return CallResult.error('Missing or invalid argument: title');
    }
    final product = await _service.create(
      workspaceId: workspaceId,
      title: title,
      artifactType: WorkProductType.fromStorage(
        arguments['artifact_type'] as String?,
      ),
      ticketId: arguments['ticket_id'] as String?,
      agentId: arguments['agent_id'] as String?,
    );
    return CallResult.success(jsonEncode(_productJson(product)));
  }
}

/// Saves a new revision of a work product (optimistic concurrency on the base).
class SaveWorkProductRevisionTool extends McpTool {
  /// Creates a [SaveWorkProductRevisionTool].
  SaveWorkProductRevisionTool({required WorkProductService service})
    : _service = service;

  final WorkProductService _service;

  @override
  String get name => 'save_work_product_revision';

  @override
  String get description =>
      'Saves a new version of a work product. Pass base_revision_id (the '
      'revision you edited from) to be rejected if someone else has revised it '
      'in the meantime.';

  @override
  bool get requiresApproval => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'work_product_id': {'type': 'string', 'description': 'Artifact id.'},
      'content': {'type': 'string', 'description': 'Full revision content.'},
      'base_revision_id': {
        'type': 'string',
        'description': 'Revision this edit is based on (concurrency check).',
      },
      'agent_id': {'type': 'string', 'description': 'Authoring agent id.'},
      'summary': {'type': 'string', 'description': 'What changed.'},
    },
    'required': ['workspace_id', 'work_product_id', 'content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final productId = arguments['work_product_id'];
    if (productId is! String) {
      return CallResult.error('Missing or invalid argument: work_product_id');
    }
    final content = arguments['content'];
    if (content is! String) {
      return CallResult.error('Missing or invalid argument: content');
    }
    final revision = await _service.addRevision(
      workspaceId: workspaceId,
      workProductId: productId,
      content: content,
      baseRevisionId: arguments['base_revision_id'] as String?,
      authorId: arguments['agent_id'] as String?,
      summary: arguments['summary'] as String?,
    );
    return CallResult.success(
      jsonEncode({
        'revision_id': revision.id,
        'work_product_id': revision.workProductId,
        'revision_number': revision.revisionNumber,
      }),
    );
  }
}

/// Lists work products in a workspace, optionally filtered by task.
class ListWorkProductsTool extends McpTool {
  /// Creates a [ListWorkProductsTool].
  ListWorkProductsTool({required WorkProductRepository repository})
    : _repository = repository;

  final WorkProductRepository _repository;

  @override
  String get name => 'list_work_products';

  @override
  String get description =>
      'Lists work products for a workspace, optionally filtered to one task '
      '(ticket_id).';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'ticket_id': {'type': 'string', 'description': 'Optional task filter.'},
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final ticketId = arguments['ticket_id'];
    final products = ticketId is String
        ? await _repository.forTicket(workspaceId, ticketId)
        : await _repository.watchByWorkspace(workspaceId).first;
    return CallResult.success(
      jsonEncode({
        'work_products': products.map(_productJson).toList(),
        'count': products.length,
      }),
    );
  }
}

/// Returns a work product with its full revision history.
class GetWorkProductTool extends McpTool {
  /// Creates a [GetWorkProductTool].
  GetWorkProductTool({required WorkProductRepository repository})
    : _repository = repository;

  final WorkProductRepository _repository;

  @override
  String get name => 'get_work_product';

  @override
  String get description =>
      'Returns a work product with its revision history (newest first), '
      'including each revision\'s content.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'work_product_id': {'type': 'string', 'description': 'Artifact id.'},
    },
    'required': ['workspace_id', 'work_product_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final productId = arguments['work_product_id'];
    if (productId is! String) {
      return CallResult.error('Missing or invalid argument: work_product_id');
    }
    final product = await _repository.getById(workspaceId, productId);
    if (product == null) {
      return CallResult.error('Work product $productId not found.');
    }
    final revisions = await _repository.getRevisions(workspaceId, productId);
    return CallResult.success(
      jsonEncode({
        ..._productJson(product),
        'revisions': [
          for (final r in revisions)
            {
              'id': r.id,
              'revision_number': r.revisionNumber,
              'content': r.content,
              'summary': r.summary,
              'author_id': r.authorId,
              'created_at': r.createdAt.toIso8601String(),
            },
        ],
      }),
    );
  }
}
