import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_domain/features/plan_studio/domain/services/playbook_instantiator.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/tools/propose_orchestration_tool.dart';
import 'package:uuid/uuid.dart';

/// Saves a plan as a named, versioned, parameterized playbook (PRD 17 §10).
class CreatePlaybookTool extends McpTool {
  /// Creates a [CreatePlaybookTool].
  CreatePlaybookTool({
    required PlaybookRepository playbooks,
    required OrchestrationRepository orchestrations,
  }) : _playbooks = playbooks,
       _orchestrations = orchestrations;

  final PlaybookRepository _playbooks;
  final OrchestrationRepository _orchestrations;

  static const _uuid = Uuid();

  @override
  String get name => 'create_playbook';

  @override
  String get description =>
      'Save a plan as a reusable playbook: a named, versioned template with '
      'typed parameters. Use {{param}} placeholders in the stored plan\'s '
      'goal/titles/descriptions/prompts and declare every placeholder in '
      'params. Source the plan from an existing orchestration '
      '(orchestration_id) or pass a full proposal. Saving over an existing '
      'name bumps its version.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'name': {
        'type': 'string',
        'description': 'Playbook name (unique per workspace).',
      },
      'description': {'type': 'string'},
      'params': {
        'type': 'array',
        'description':
            'Typed parameters: [{name, type: string|enumeration|repoRef|'
            'agentRef, description, required, default?, choices[]}].',
        'items': {'type': 'object'},
      },
      'orchestration_id': {
        'type': 'string',
        'description': 'Source the stored plan from this orchestration.',
      },
      'proposal': {
        'type': 'object',
        'description':
            'Full proposal JSON (same shape as propose_orchestration) — '
            'used when orchestration_id is not set.',
      },
    },
    'required': ['workspace_id', 'name'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final name = arguments['name'];
    if (name is! String || name.trim().isEmpty) {
      return CallResult.error('Missing or invalid argument: name');
    }

    OrchestrationProposal? source;
    final orchestrationId = arguments['orchestration_id'] as String?;
    if (orchestrationId != null && orchestrationId.isNotEmpty) {
      final orchestration = await _orchestrations.getById(
        workspaceId,
        orchestrationId,
      );
      if (orchestration == null) {
        return CallResult.error('Orchestration $orchestrationId not found.');
      }
      source = orchestration.proposal;
    } else if (arguments['proposal'] is Map) {
      try {
        source = OrchestrationProposal.fromJson(
          (arguments['proposal'] as Map).cast<String, dynamic>(),
        );
      } on Object catch (e) {
        return CallResult.error('Could not parse the proposal: $e');
      }
    }
    if (source == null) {
      return CallResult.error('Provide either orchestration_id or a proposal.');
    }

    final List<PlaybookParam> params;
    try {
      params = (arguments['params'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => PlaybookParam.fromJson(m.cast<String, dynamic>()))
          .toList();
    } on Object catch (e) {
      return CallResult.error('Could not parse params: $e');
    }

    // Every placeholder in the stored plan must be a declared parameter —
    // an undeclared one would fail every future instantiation.
    final placeholders = PlaybookInstantiator.placeholdersIn(source);
    final declared = params.map((p) => p.name).toSet();
    final undeclared = placeholders.difference(declared);
    if (undeclared.isNotEmpty) {
      return CallResult.error(
        'Undeclared placeholders in the stored plan: '
        '${undeclared.map((n) => '{{$n}}').join(', ')}. Declare them in '
        'params or remove them.',
      );
    }

    final now = DateTime.now();
    final existing = await _playbooks.getByName(workspaceId, name.trim());
    final playbook = existing == null
        ? Playbook(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            name: name.trim(),
            description: arguments['description'] as String? ?? '',
            params: params,
            sourceProposal: source,
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            description:
                arguments['description'] as String? ?? existing.description,
            params: params,
            sourceProposal: source,
            version: existing.version + 1,
            updatedAt: now,
          );
    await _playbooks.upsert(playbook);

    return CallResult.success(
      jsonEncode({
        'playbook_id': playbook.id,
        'name': playbook.name,
        'version': playbook.version,
        'params': [for (final p in playbook.params) p.name],
      }),
    );
  }
}

/// Instantiates a playbook against new parameters and proposes the resulting
/// plan for approval (PRD 17 §10) — a fresh orchestration proposal opens in
/// Plan Studio; nothing runs until the operator approves.
class RunPlaybookTool extends McpTool {
  /// Creates a [RunPlaybookTool]. Delegates the propose half to
  /// [ProposeOrchestrationTool] so validation, ticket parking, the proposal
  /// message, revision recording, and events stay one code path.
  RunPlaybookTool({
    required PlaybookRepository playbooks,
    required ProposeOrchestrationTool propose,
  }) : _playbooks = playbooks,
       _propose = propose;

  final PlaybookRepository _playbooks;
  final ProposeOrchestrationTool _propose;

  @override
  String get name => 'run_playbook';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

  @override
  String get description =>
      'Instantiate a saved playbook with parameter values, producing a fresh '
      'plan that the operator reviews and approves in Plan Studio. Nothing '
      'executes until approval. Identify the playbook by id or name.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'playbook_id': {'type': 'string'},
      'name': {
        'type': 'string',
        'description': 'Playbook name (when playbook_id is not set).',
      },
      'ticket_id': {
        'type': 'string',
        'description': 'The anchor ticket the plan is proposed against.',
      },
      'args': {
        'type': 'object',
        'description': 'Parameter values, keyed by parameter name.',
      },
      'agent_id': {'type': 'string'},
    },
    'required': ['workspace_id', 'ticket_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final ticketId = arguments['ticket_id'];
    if (ticketId is! String || ticketId.isEmpty) {
      return CallResult.error('Missing or invalid argument: ticket_id');
    }

    Playbook? playbook;
    final playbookId = arguments['playbook_id'] as String?;
    if (playbookId != null && playbookId.isNotEmpty) {
      playbook = await _playbooks.getById(workspaceId, playbookId);
    } else if (arguments['name'] is String) {
      playbook = await _playbooks.getByName(
        workspaceId,
        arguments['name'] as String,
      );
    }
    if (playbook == null) {
      return CallResult.error('Playbook not found — pass playbook_id or name.');
    }

    final args = <String, String>{};
    if (arguments['args'] is Map) {
      (arguments['args'] as Map).forEach((k, v) {
        if (k is String && v != null) {
          args[k] = v.toString();
        }
      });
    }
    final instantiation = PlaybookInstantiator.instantiate(playbook, args);
    if (!instantiation.isValid) {
      return CallResult.error(
        'Playbook instantiation failed:\n'
        '${instantiation.errors.map((e) => '- $e').join('\n')}',
      );
    }

    final proposalJson = instantiation.proposal!.toJson();
    return _propose.run({
      'workspace_id': workspaceId,
      'ticket_id': ticketId,
      'agent_id': arguments['agent_id'],
      'goal': proposalJson['goal'],
      'roles': proposalJson['roles'],
      'sub_tickets': proposalJson['subTickets'],
      'research': proposalJson['research'],
      'discussion': proposalJson['discussion'],
      'synthesis': proposalJson['synthesis'],
      'budget': proposalJson['budget'],
      'drift_policy': proposalJson['driftPolicy'],
    });
  }
}
