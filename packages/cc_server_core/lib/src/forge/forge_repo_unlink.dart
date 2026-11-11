import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/forge/forge_automation_tokens.dart';
import 'package:cc_server_core/src/forge/github_clients.dart';

/// Revokes and forgets the forge credentials [repo] held in [workspaceId]: it
/// was just unlinked there. Its cached GitHub grants are revoked upstream and
/// dropped, and its own GitLab or Bitbucket bot token is deleted.
Future<void> forgetUnlinkedRepo(
  String workspaceId,
  Repo repo, {
  required GitHubClients github,
  required ForgeAutomationTokens automationTokens,
}) async {
  if (repo.forge == ForgeHost.github && repo.hasForgeRemote) {
    await github.forgetRepo(workspaceId, repo.remoteOwner, repo.remoteName);
  }
  await automationTokens.forgetRepo(workspaceId, repo);
}
