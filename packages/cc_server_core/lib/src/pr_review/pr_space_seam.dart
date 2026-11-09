import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart'
    show PrSourceRequest;
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart'
    show GitHubApiClient, LocalGitPrDiffSource, pullRequestFromGitHub;
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_bridge.dart'
    show DefaultAnswererResolver, EnsurePrReviewSpace;
import 'package:cc_server_core/src/pr_review/pr_merge_conflict_service.dart';

/// The PR room resolver, its default worker, and the merge-conflict service.
class PrSpaceSeam {
  /// Creates a [PrSpaceSeam].
  const PrSpaceSeam({
    required this.ensureSpace,
    required this.defaultAgent,
    required this.mergeConflicts,
  });

  /// Resolves the review space for a PR number.
  final EnsurePrReviewSpace ensureSpace;

  /// The seeded coordinator, for a space nobody has spoken in yet.
  final DefaultAnswererResolver defaultAgent;

  /// Null on a demo, which does not clone PRs or dispatch agents.
  final PrMergeConflictService? mergeConflicts;
}

/// One resolver for the PR's room, so a mention-started question, a conflict
/// fix and a UI-opened workbench agree about which space a PR lives in.
///
/// The conflict list is a `git merge-tree` on the GitHub PR clone, fetched on
/// the caller's credential (the boot-time token the diff fallback holds can
/// be expired, and cannot see a private repo only that person can).
PrSpaceSeam buildPrSpaceSeam({
  required bool enabled,
  required Future<String> Function({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
  })
  resolvePrExternalId,
  required Future<String?> Function({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String title,
  })
  ensureReviewSpace,
  required AgentRepository agents,
  required GitHubApiClient Function(String workspaceId, String owner) githubFor,
  required Future<Repo> Function(String workspaceId, String owner, String repo)
  resolveLinkedRepo,
  required ForgeCredentials credentials,
  required LocalGitPrDiffSource diffSource,
  required ConversationRepository conversations,
  required MessagingPort messaging,
  required MessagingRepository messagingRepository,
}) {
  Future<String?> ensureSpace({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String title,
  }) async {
    // Last-slash split: a GitLab `group/sub/project` is a real repo.
    final parts = splitRepoFullName(repoFullName);
    if (parts == null) {
      return null;
    }
    final prExternalId = await resolvePrExternalId(
      workspaceId: workspaceId,
      owner: parts.owner,
      repo: parts.name,
      prNumber: prNumber,
    );
    return ensureReviewSpace(
      workspaceId: workspaceId,
      repoFullName: repoFullName,
      prNumber: prNumber,
      prExternalId: prExternalId,
      title: title,
    );
  }

  Future<String?> defaultAgent(String workspaceId) async {
    final roster = await agents.watchByWorkspace(workspaceId).first;
    for (final agent in roster) {
      if (agent.role == AgentRole.ceo) {
        return agent.id;
      }
    }
    return null;
  }

  final mergeConflicts = !enabled
      ? null
      : PrMergeConflictService(
          refs: (workspaceId, owner, repo, prNumber) async {
            // The conflict flow reads the PR and checks out its refs through
            // GitHub; another forge's coordinate must not be looked up on
            // github.com, so it is refused by capability, not guessed at.
            final linked = await resolveLinkedRepo(workspaceId, owner, repo);
            final caps = kForgeCapabilities[linked.forge];
            if (caps == null ||
                !caps.has(ForgeCapability.mergeConflictResolution)) {
              throw ForgeUnsupportedError(
                linked.forge,
                ForgeCapability.mergeConflictResolution.name,
              );
            }
            final gh = await githubFor(
              workspaceId,
              owner,
            ).pr.getPullRequest(owner, repo, prNumber);
            if (gh == null) {
              return null;
            }
            final pr = pullRequestFromGitHub(gh, repoFullName: '$owner/$repo');
            return (title: pr.title, baseRef: pr.baseRef, headRef: pr.headRef);
          },
          conflictFiles:
              ({
                required workspaceId,
                required owner,
                required repo,
                required prNumber,
                required baseRef,
                required userId,
              }) async {
                final linked = await resolveLinkedRepo(
                  workspaceId,
                  owner,
                  repo,
                );
                // The person asking, on their own sign-in; nobody else's.
                final token = userId == null
                    ? null
                    : await credentials.personToken(
                        ForgeHost.github,
                        userId,
                        workspaceId: workspaceId,
                      );
                return diffSource.mergeConflictFiles(
                  PrSourceRequest(
                    prNumber: prNumber,
                    owner: owner,
                    repo: repo,
                    baseRef: baseRef,
                    headRef: '',
                    headSha: '',
                    changedFiles: 0,
                    workspaceId: workspaceId,
                    localCheckoutPath: linked.path,
                  ),
                  githubToken: token,
                );
              },
          ensureSpace: ensureSpace,
          defaultAgent: defaultAgent,
          conversations: conversations,
          messaging: messaging,
          messagingRepository: messagingRepository,
          onWarning: CcHostLog.warning,
        );

  return PrSpaceSeam(
    ensureSpace: ensureSpace,
    defaultAgent: defaultAgent,
    mergeConflicts: mergeConflicts,
  );
}
