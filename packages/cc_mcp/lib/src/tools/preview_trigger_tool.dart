import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/trigger_preview_service.dart';

/// `preview_trigger` — read-only "which runs would start" dry-run.
///
/// Given a hypothetical event (type + payload) it reports, per workspace
/// trigger, whether a run would be enqueued and why, plus whether that run
/// hands off to an agent/human (`handoff_supported`). Consulted before
/// committing a create / assign / status change so the user sees "N runs would
/// start" up front.
class PreviewTriggerTool extends McpTool {
  /// Creates a [PreviewTriggerTool].
  PreviewTriggerTool({
    required PipelineTriggerRepository triggerRepository,
    required PipelineTemplateRepository templateRepository,
  }) : _triggers = triggerRepository,
       _templates = templateRepository;

  final PipelineTriggerRepository _triggers;
  final PipelineTemplateRepository _templates;
  final TriggerPreviewService _preview = const TriggerPreviewService();

  @override
  String get name => 'preview_trigger';

  @override
  String get description =>
      'Dry-runs which pipeline runs a hypothetical event would start in a '
      'workspace, without committing anything. Returns a per-trigger verdict '
      '(will it enqueue + why) and a total count.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace to preview against.',
      },
      'event_type': {
        'type': 'string',
        'description':
            'The candidate event type (e.g. TicketAssigned, '
            'PullRequestStatusChanged).',
      },
      'payload': {
        'type': 'object',
        'description':
            'The candidate event payload, matched against each trigger\'s '
            'filter. Optional; defaults to an empty payload.',
      },
    },
    'required': ['workspace_id', 'event_type'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final eventType = arguments['event_type'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (eventType is! String) {
      return CallResult.error('Missing or invalid argument: event_type');
    }
    final rawPayload = arguments['payload'];
    final payload = rawPayload is Map<String, dynamic>
        ? rawPayload
        : <String, dynamic>{};

    final triggers = await _triggers.forWorkspace(workspaceId);
    final templates = await _templates.forWorkspace(workspaceId);
    final preview = _preview.preview(
      eventType: eventType,
      payload: payload,
      triggers: triggers,
      templates: templates,
    );

    return CallResult.success(
      jsonEncode({
        'event_type': preview.eventType,
        'will_enqueue_count': preview.willEnqueueCount,
        'runs': [
          for (final item in preview.items)
            {
              'trigger_id': item.triggerId,
              'template_id': item.templateId,
              'template_name': item.templateName,
              'will_enqueue': item.willEnqueue,
              'reason': item.reason,
              'handoff_supported': item.handoffSupported,
            },
        ],
      }),
    );
  }
}
