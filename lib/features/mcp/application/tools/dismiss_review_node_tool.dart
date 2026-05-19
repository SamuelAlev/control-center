import 'dart:convert';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/repositories/review_channel_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:control_center/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:uuid/uuid.dart';

/// MCP tool that dismisses a review node finding.
///
/// Updates the node metadata to `status: 'dismissed'` and posts a thread
/// reply with the dismissal reason.
///
/// Learning-from-dismissal: when the optional memory collaborators are wired,
/// it also records a workspace-scoped suppression fact in the
/// `review-suppressions` domain so future reviewers can consult it via
/// `search_memory` and stop re-flagging a pattern the team rejected — the
/// persistent feedback loop that turns dismissals into precision. Recording is
/// best-effort: a memory failure never blocks the dismissal itself.
class DismissReviewNodeTool extends McpTool {
  /// Creates a new [DismissReviewNodeTool].
  ///
  /// [reviewChannels], [memoryFacts], and [resolveDomain] are optional; when
  /// all three are supplied, the dismissal is recorded as a suppression fact.
  DismissReviewNodeTool({
    required MessagingRepository repository,
    ReviewChannelRepository? reviewChannels,
    MemoryFactRepository? memoryFacts,
    ResolveOrCreateDomainUseCase? resolveDomain,
  })  : _repository = repository,
        _reviewChannels = reviewChannels,
        _memoryFacts = memoryFacts,
        _resolveDomain = resolveDomain;

  final MessagingRepository _repository;
  final ReviewChannelRepository? _reviewChannels;
  final MemoryFactRepository? _memoryFacts;
  final ResolveOrCreateDomainUseCase? _resolveDomain;

  /// Memory domain that collects dismissed-finding patterns.
  static const String suppressionDomain = 'review-suppressions';

  @override
  String get name => 'dismiss_review_node';

  @override
  String get description =>
      'Dismisses a review node finding. Updates the node status to '
      '"dismissed", posts a dismissal reason as a system message, and records '
      'a suppression fact so reviewers stop re-flagging this pattern on future '
      'PRs.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'channel_id': {
        'type': 'string',
        'description': 'The review channel ID.',
      },
      'node_message_id': {
        'type': 'string',
        'description': 'The message ID of the review node to dismiss.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'The ID of the agent dismissing the finding.',
      },
      'reason': {
        'type': 'string',
        'description': 'Reason for dismissing the finding.',
      },
    },
    'required': ['channel_id', 'node_message_id', 'agent_id', 'reason'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawChannelId = arguments['channel_id'];
    if (rawChannelId is! String) {
      return CallResult.error('Missing or invalid argument: channel_id (expected string)');
    }
    final rawNodeMessageId = arguments['node_message_id'];
    if (rawNodeMessageId is! String) {
      return CallResult.error('Missing or invalid argument: node_message_id (expected string)');
    }
    final rawAgentId = arguments['agent_id'];
    if (rawAgentId is! String) {
      return CallResult.error('Missing or invalid argument: agent_id (expected string)');
    }
    final rawReason = arguments['reason'];
    if (rawReason is! String) {
      return CallResult.error('Missing or invalid argument: reason (expected string)');
    }
    final channelId = rawChannelId;
    final nodeMessageId = rawNodeMessageId;
    final agentId = rawAgentId;
    final reason = rawReason;

    final messages = await _repository.getMessages(channelId);
    final target = messages.where((m) => m.id == nodeMessageId).firstOrNull;

    if (target == null) {
      return CallResult.error('Review node not found: $nodeMessageId');
    }

    final metadata = Map<String, dynamic>.from(target.metadata ?? {});
    metadata['status'] = 'dismissed';

    await _repository.updateMessage(nodeMessageId, metadata: metadata);

    await _repository.sendMessage(
      channelId: channelId,
      content: '❌ Agent `$agentId` dismissed this finding: $reason',
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
    );

    final suppressionRecorded = await _recordSuppression(
      channelId: channelId,
      node: target,
      reason: reason,
      agentId: agentId,
    );

    return CallResult.success(
      jsonEncode({
        'node_message_id': nodeMessageId,
        'status': 'dismissed',
        'dismissed_by': agentId,
        'reason': reason,
        'suppression_recorded': suppressionRecorded,
      }),
    );
  }

  /// Records the dismissal as a suppression fact. Returns whether a fact was
  /// written. Best-effort — swallows failures so the dismissal still succeeds.
  Future<bool> _recordSuppression({
    required String channelId,
    required ChannelMessage node,
    required String reason,
    required String agentId,
  }) async {
    final reviewChannels = _reviewChannels;
    final memoryFacts = _memoryFacts;
    final resolveDomain = _resolveDomain;
    if (reviewChannels == null || memoryFacts == null || resolveDomain == null) {
      return false;
    }

    try {
      final association = await reviewChannels.watchByChannel(channelId).first;
      if (association == null) {
        return false;
      }
      final workspaceId = association.workspaceId;
      final meta = node.metadata ?? const {};
      final filePath = meta['filePath'] is String ? meta['filePath'] as String : null;
      final findingSummary = node.content.trim().split('\n').first;
      final topic = filePath != null
          ? 'Dismissed finding in $filePath'
          : 'Dismissed finding: ${_truncate(findingSummary, 48)}';
      final content = StringBuffer()
        ..writeln('A reviewer dismissed a finding — do not re-flag this '
            'pattern on future PRs.')
        ..writeln()
        ..writeln('**Finding:** ${_truncate(findingSummary, 280)}');
      if (filePath != null) {
        content.writeln('**File:** `$filePath`');
      }
      content.writeln('**Dismissal reason:** ${reason.trim()}');

      final domain = await resolveDomain.execute(
        workspaceId: workspaceId,
        domainInput: suppressionDomain,
        domainLabel: 'Review suppressions',
        domainDescription:
            'Findings the team dismissed during review. Reviewers should '
            'consult these and avoid re-flagging the same patterns.',
        authorRole: AgentRole.reviewer,
      );

      // Light dedup: skip if an identical suppression for this topic exists.
      final existing = await memoryFacts.getActiveByTopic(workspaceId, topic);
      final body = content.toString().trim();
      final dup = existing.any(
        (f) => f.domain == domain.name && f.content.trim() == body,
      );
      if (dup) {
        return true;
      }

      final now = DateTime.now();
      await memoryFacts.upsert(
        MemoryFact(
          id: const Uuid().v4(),
          workspaceId: workspaceId,
          domain: domain.name,
          topic: topic,
          content: body,
          // Soft signal: a single dismissal suppresses with moderate
          // confidence; repeated dismissals reinforce via the verdict path.
          confidence: 0.7,
          authoredByAgentId: agentId,
          authoredByRole: AgentRole.reviewer,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return true;
    } catch (e, st) {
      AppLog.e('dismiss_review_node', 'failed to record suppression fact', e, st);
      return false;
    }
  }

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max).trimRight()}…';
}
