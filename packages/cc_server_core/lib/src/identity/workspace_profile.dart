import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';

/// Applies a workspace member's profile overlay onto the global [User].
///
/// Null overlay fields inherit the account row. Handle, SSO and onboarding
/// stay on [User] and are never taken from membership.
User applyMemberOverlay(User user, WorkspaceMember? member) {
  if (member == null) {
    return user;
  }
  String? pick(String? overlay, String? fallback) {
    final trimmed = overlay?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallback;
    }
    return trimmed;
  }

  return user.copyWith(
    displayName: pick(member.displayName, user.displayName) ?? user.displayName,
    email: pick(member.email, user.email),
    gitAuthorName: pick(member.gitAuthorName, user.gitAuthorName),
    gitAuthorEmail: pick(member.gitAuthorEmail, user.gitAuthorEmail),
  );
}

/// Resolves the git author identity for [userId] in [workspaceId].
///
/// Overlay first, then the global [User] row, then display name / noreply.
/// There is no fallback to anybody else: a run nobody requested commits as
/// Control Center ([resolveAgentCommitIdentity]), never as the server owner.
Future<({String name, String email})?> resolveWorkspaceGitIdentity({
  required UserRepository users,
  required WorkspaceMembershipRepository members,
  required String userId,
  String? workspaceId,
}) async {
  final user = await users.getById(userId);
  if (user == null) {
    return null;
  }
  WorkspaceMember? member;
  if (workspaceId != null && workspaceId.isNotEmpty) {
    member = await members.getMember(workspaceId, userId);
  }
  final overlaid = applyMemberOverlay(user, member);
  return (
    name: overlaid.effectiveGitAuthorName,
    email: overlaid.effectiveGitAuthorEmail,
  );
}

/// The commit identity of an agent run [userId] asked for in [workspaceId]
/// (null [userId]: nobody did).
///
/// * The owner's own runs commit as the owner and may use the host key.
/// * Another member's runs are authored by them — as their GitHub noreply
///   address when [githubAccount] knows their GitHub sign-in, else their
///   workspace git identity — and committed by Control Center, unsigned.
/// * Unrequested runs are Control Center throughout, unsigned.
///
/// Null when [userId] names no user.
Future<AgentCommitIdentity?> resolveAgentCommitIdentity({
  required UserRepository users,
  required WorkspaceMembershipRepository members,
  required String ownerUserId,
  required Future<GitHubUser?> Function(String userId, String? workspaceId)
  githubAccount,
  String? userId,
  String? workspaceId,
}) async {
  if (userId == null || userId.isEmpty) {
    return AgentCommitIdentity.unrequested();
  }
  final human = await resolveWorkspaceGitIdentity(
    users: users,
    members: members,
    userId: userId,
    workspaceId: workspaceId,
  );
  if (human == null) {
    return null;
  }
  if (userId == ownerUserId) {
    return AgentCommitIdentity.owner(name: human.name, email: human.email);
  }
  final account = await githubAccount(userId, workspaceId);
  return AgentCommitIdentity.member(
    name: human.name,
    email: account == null || account.login.isEmpty
        ? human.email
        : AgentCommitIdentity.githubNoreply(
            accountId: account.id,
            login: account.login,
          ),
  );
}
