import 'package:cc_domain/cc_domain.dart' show NotFoundException, RepoOpKind;
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart' show userToWire;
import 'package:cc_server_core/src/identity/workspace_profile.dart';

/// Workspace overlay for Workspace → Profile (`identity.updateWorkspaceProfile`).
///
/// Name, email and git author in THIS workspace. Empty fields inherit the
/// global `users` row. Handle, SSO and devices stay on the account. Injected
/// via `extraOps` so `remote_rpc_catalog.dart` does not grow.
List<RepoOp> buildIdentityWorkspaceProfileOps({
  required UserRepository? users,
  required WorkspaceMembershipRepository? members,
}) {
  if (users == null || members == null) {
    return const [];
  }
  return [
    RepoOp(
      name: 'identity.updateWorkspaceProfile',
      kind: RepoOpKind.mutate,
      handler: (ctx) async {
        String? optional(String key) {
          final value = ctx.args[key];
          return value is String && value.isNotEmpty ? value : null;
        }

        bool clear(String key) {
          if (!ctx.args.containsKey(key)) {
            return false;
          }
          final value = ctx.args[key];
          return value is! String || value.isEmpty;
        }

        await members.updateProfileOverlay(
          ctx.workspaceId!,
          ctx.userId,
          displayName: optional('display_name'),
          clearDisplayName: clear('display_name'),
          email: optional('email'),
          clearEmail: clear('email'),
          gitAuthorName: optional('git_author_name'),
          clearGitAuthorName: clear('git_author_name'),
          gitAuthorEmail: optional('git_author_email'),
          clearGitAuthorEmail: clear('git_author_email'),
        );
        final user = await users.getById(ctx.userId);
        if (user == null) {
          throw const NotFoundException('User not found');
        }
        final member = await members.getMember(ctx.workspaceId!, ctx.userId);
        return {
          'user': userToWire(
            applyMemberOverlay(user, member),
            includeOnboarding: true,
          ),
        };
      },
    ),
  ];
}
