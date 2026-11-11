import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';

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
/// There is no fallback to anybody else. Agent commits never use this: they
/// name the agent and credit only a forge-verified address
/// (`AgentCommitIdentities`).
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
