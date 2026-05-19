import 'dart:io';

import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/services/slugify.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pipelines/domain/ports/dispatch_reviewers_port.dart';
import 'package:cc_domain/features/pr_review/domain/services/reviewer_matching_service.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

/// Implementation of [DispatchReviewersPort] extracted from the
/// `dispatch_reviewers` MCP tool. Both the MCP tool and pipeline step bodies
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
  }) : _agents = agents,
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

  /// Dispatches reviewers to a review channel, matching agents by role.
  @override
  Future<Map<String, dynamic>> dispatch({
    required String channelId,
    required String workspaceId,
    required List<Map<String, dynamic>> reviewers,
    int? concurrency,
  }) async {
    final workspace = await _workspaces.getById(workspaceId);
    final effectiveConcurrency =
        concurrency ?? workspace?.reviewConcurrency ?? 3;

    final candidates = await _agents.watchByWorkspace(workspaceId).first;
    final existingParticipants = await _messaging.getParticipants(
      workspaceId,
      channelId,
    );
    final existingAgentIds = {
      for (final p in existingParticipants)
        if (!p.isUser) p.principalId,
    };

    final assoc = await _reviewChannels
        .watchByChannel(workspaceId, channelId)
        .first;
    final prNumber = assoc?.prNumber;
    final repoFullName = assoc?.repoFullName ?? '';
    final repoPath = await _resolveRepoPath(
      workspaceId,
      channelId,
      repoFullName,
    );

    final specs = <_Spec>[];
    final unmatched = <Map<String, dynamic>>[];
    for (final raw in reviewers) {
      final role = raw['role'];
      if (role is! String || role.isEmpty) {
        continue;
      }
      final scope = raw['scope'] is String ? raw['scope'] as String : null;
      final override = raw['prompt_override'] is String
          ? raw['prompt_override'] as String
          : null;
      final match = _matching.findBestMatch(candidates, role);
      if (match == null) {
        unmatched.add({'role': role, 'scope': ?scope});
        continue;
      }
      specs.add(
        _Spec(
          role: role,
          scope: scope,
          promptOverride: override,
          agentId: match.id,
          agentName: match.name,
          agentMdPath: match.agentMdPath,
        ),
      );
    }

    final pool = Pool(effectiveConcurrency);
    final dispatched = <Map<String, dynamic>>[];
    try {
      await Future.wait(
        specs.map((spec) async {
          await pool.withResource(() async {
            if (!existingAgentIds.contains(spec.agentId)) {
              await _messaging.addParticipant(
                workspaceId,
                channelId,
                spec.agentId,
              );
              existingAgentIds.add(spec.agentId);
            }
            await _messaging.sendMessage(
              workspaceId: workspaceId,
              channelId: channelId,
              content:
                  '@${spec.agentName} you are on review duty as ${spec.role}.',
              senderId: 'system',
              senderType: 'agent',
              messageType: 'system',
            );
            final brief =
                spec.promptOverride ??
                _buildBrief(
                  agentName: spec.agentName,
                  role: spec.role,
                  scope: spec.scope,
                  prNumber: prNumber,
                  repoFullName: repoFullName,
                  localRepoPath: repoPath,
                );
            await _messagingPort.dispatchAgent(
              workspaceId: workspaceId,
              channelId: channelId,
              agentId: spec.agentId,
              prompt: brief,
            );
            dispatched.add({
              'role': spec.role,
              'agent_id': spec.agentId,
              'agent_name': spec.agentName,
            });
          });
        }),
      );
    } finally {
      await pool.close();
    }

    if (dispatched.isNotEmpty &&
        assoc != null &&
        assoc.status == ReviewChannelStatus.requested) {
      await _reviewChannels.updateStatus(
        workspaceId,
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

  /// Resolves the PR's isolated worktree inside the conversation workspace:
  /// `<convDir>/repos/<slug>` (the provisioner's layout — there is no
  /// singular `repo/` dir). Prefers the worktree matching [repoFullName]'s
  /// repo name; falls back to the only worktree when exactly one exists.
  Future<String?> _resolveRepoPath(
    String workspaceId,
    String channelId,
    String repoFullName,
  ) async {
    try {
      final convDir = await _fs.conversationDir(workspaceId, channelId);
      final reposDir = Directory('$convDir/repos');
      if (!reposDir.existsSync()) {
        return null;
      }
      final worktrees = reposDir
          .listSync(followLinks: false)
          .whereType<Directory>()
          .toList();
      if (worktrees.isEmpty) {
        return null;
      }
      final repoName = repoFullName.contains('/')
          ? repoFullName.split('/').last
          : repoFullName;
      final slug = slugify(repoName);
      for (final dir in worktrees) {
        if (slug.isNotEmpty && p.basename(dir.path) == slug) {
          return dir.path;
        }
      }
      if (worktrees.length == 1) {
        return worktrees.single.path;
      }
    } catch (e) {
      CcInfraLog.warning(
        'dispatch_reviewers: repo path resolve failed for $channelId: $e',
      );
    }
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
        'Start by inspecting the checked-out worktree with harness `read` / '
        '`bash` (`git diff`, `git show`); use `list_pull_requests` if you need '
        'catalog metadata.\n'
        'Focus on areas relevant to your expertise. Before flagging, use '
        '`code_impact` / `code_callers` to gauge a changed symbol\'s '
        'cross-file blast radius, and `search_memory` (domain '
        '`review-suppressions`) to avoid re-flagging patterns the team has '
        'already dismissed.\n'
        'Record findings using `add_review_node`, ALWAYS with `file_path` + '
        '`line_number` (so they post as inline GitHub comments), plus a '
        'P0–P3 priority and a confidence score in `[0, 1]`.';
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
