import 'dart:io';

import 'package:control_center/core/domain/entities/review_channel_association.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/review_channel_repository.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/features/mcp/application/tools/dispatch_reviewers_tool.dart' show DispatchReviewersTool;
import 'package:control_center/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/features/pipelines/domain/ports/dispatch_reviewers_port.dart';
import 'package:control_center/features/pr_review/domain/services/reviewer_matching_service.dart';
import 'package:pool/pool.dart';

/// Implementation of [DispatchReviewersPort] extracted from
/// [DispatchReviewersTool]. Both the MCP tool and pipeline step bodies
/// call this service.
class DispatchReviewersService implements DispatchReviewersPort {
  /// Creates a [DispatchReviewersService].
  DispatchReviewersService({
    required AgentRepository agents,
    required MessagingRepository messaging,
    required ReviewChannelRepository reviewChannels,
    required MessagingPort messagingPort,
    required WorkspaceRepository workspaces,
    required WorkspaceFilesystemPort filesystemPort,
    ReviewerMatchingService? matching,
  })  : _agents = agents,
        _messaging = messaging,
        _reviewChannels = reviewChannels,
        _messagingPort = messagingPort,
        _workspaces = workspaces,
        _fs = filesystemPort,
        _matching = matching ?? const ReviewerMatchingService();

  final AgentRepository _agents;
  final MessagingRepository _messaging;
  final ReviewChannelRepository _reviewChannels;
  final MessagingPort _messagingPort;
  final WorkspaceRepository _workspaces;
  final WorkspaceFilesystemPort _fs;
  final ReviewerMatchingService _matching;

  @override
  Future<Map<String, dynamic>> dispatch({
    required String channelId,
    required String workspaceId,
    required List<Map<String, dynamic>> reviewers,
    int? concurrency,
  }) async {
    final workspaces = await _workspaces.watchAll().first;
    final workspace =
        workspaces.where((w) => w.id == workspaceId).firstOrNull;
    final effectiveConcurrency =
        concurrency ?? workspace?.reviewConcurrency ?? 3;

    final candidates = await _agents.watchByWorkspace(workspaceId).first;
    final existingParticipants = await _messaging.getParticipants(channelId);
    final existingAgentIds =
        existingParticipants.map((p) => p.agentId).toSet();

    final assoc = await _reviewChannels.watchByChannel(channelId).first;
    final prNumber = assoc?.prNumber;
    final repoFullName = assoc?.repoFullName ?? '';
    final repoPath = await _resolveRepoPath(workspaceId, channelId);

    final specs = <_Spec>[];
    final unmatched = <Map<String, dynamic>>[];
    for (final raw in reviewers) {
      final role = raw['role'];
      if (role is! String || role.isEmpty) continue;
      final scope = raw['scope'] is String ? raw['scope'] as String : null;
      final override = raw['prompt_override'] is String
          ? raw['prompt_override'] as String
          : null;
      final match = _matching.findBestMatch(candidates, role);
      if (match == null) {
        unmatched.add({'role': role, 'scope': ?scope});
        continue;
      }
      specs.add(_Spec(
        role: role,
        scope: scope,
        promptOverride: override,
        agentId: match.id,
        agentName: match.name,
        agentMdPath: match.agentMdPath,
      ));
    }

    final pool = Pool(effectiveConcurrency);
    final dispatched = <Map<String, dynamic>>[];
    try {
      await Future.wait(specs.map((spec) async {
        await pool.withResource(() async {
          if (!existingAgentIds.contains(spec.agentId)) {
            await _messaging.addParticipant(channelId, spec.agentId);
            existingAgentIds.add(spec.agentId);
          }
          await _messaging.sendMessage(
            channelId: channelId,
            content:
                '@${spec.agentName} you are on review duty as ${spec.role}.',
            senderId: 'system',
            senderType: 'agent',
            messageType: 'system',
          );
          final brief = spec.promptOverride ??
              _buildBrief(
                agentName: spec.agentName,
                role: spec.role,
                scope: spec.scope,
                prNumber: prNumber,
                repoFullName: repoFullName,
                localRepoPath: repoPath,
              );
          await _messagingPort.dispatchAgent(
            channelId: channelId,
            agentId: spec.agentId,
            prompt: brief,
            workspaceId: workspaceId,
          );
          dispatched.add({
            'role': spec.role,
            'agent_id': spec.agentId,
            'agent_name': spec.agentName,
          });
        });
      }));
    } finally {
      await pool.close();
    }

    if (dispatched.isNotEmpty &&
        assoc != null &&
        assoc.status == ReviewChannelStatus.requested) {
      await _reviewChannels.updateStatus(
        assoc.id,
        ReviewChannelStatus.inProgress,
      );
    }

    return {
      'channel_id': channelId,
      'concurrency': effectiveConcurrency,
      'dispatched': dispatched,
      'unmatched': unmatched,
    };
  }

  Future<String?> _resolveRepoPath(
    String workspaceId,
    String channelId,
  ) async {
    try {
      final convDir = await _fs.conversationDir(workspaceId, channelId);
      final repoDir = Directory('${convDir.path}/repo');
      if (repoDir.existsSync()) return repoDir.path;
    } catch (_) {}
    return null;
  }

  String _buildBrief({
    required String agentName,
    required String role,
    required String? scope,
    required int? prNumber,
    required String repoFullName,
    required String? localRepoPath,
  }) {
    final prRef = prNumber != null
        ? 'PR #$prNumber in $repoFullName'
        : 'the PR in $repoFullName';
    final scopeNote = scope != null
        ? '\nScope filter: $scope — focus your review on files matching this glob.\n'
        : '';
    final repoSection = localRepoPath != null
        ? '\nThe repository is cloned at $localRepoPath with the PR branch '
            'already checked out.\n'
        : '';
    return 'You have been assigned as the "$role" reviewer for $prRef.'
        '$scopeNote$repoSection\n'
        'Start by reading the diff with `read(path: "pr://$repoFullName/$prNumber?comments=0")` '
        'for metadata, then `read(path: "pr://$repoFullName/$prNumber/diff/all")` '
        'for the full diff.\n'
        'Focus on areas relevant to your expertise. '
        'Record findings using `add_review_node` with P0–P3 '
        'priority and a confidence score in `[0, 1]`.';
  }
}

class _Spec {
  _Spec({
    required this.role,
    required this.scope,
    required this.promptOverride,
    required this.agentId,
    required this.agentName,
    required this.agentMdPath,
  });
  final String role;
  final String? scope;
  final String? promptOverride;
  final String agentId;
  final String agentName;
  final String agentMdPath;
}
