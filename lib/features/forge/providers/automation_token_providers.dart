import 'package:cc_domain/core/domain/value_objects/forge_automation_token.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The forges that take an automation token: GitHub automation rides the
/// GitHub App instead.
const List<ForgeHost> automationTokenForges = [
  ForgeHost.gitlab,
  ForgeHost.bitbucket,
];

/// Whether the reader administers `workspaceId` on a real server: the only
/// people who see or change automation tokens (the server enforces it too).
final canManageAutomationTokensProvider = Provider.family<bool, String>((
  ref,
  workspaceId,
) {
  if (ref.watch(isDemoServerProvider)) {
    return false;
  }
  return ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;
});

/// The GitLab and Bitbucket automation tokens stored for `workspaceId`, as
/// descriptions (never the tokens). Empty for anyone who cannot manage them.
final automationTokensProvider =
    FutureProvider.family<List<ForgeAutomationToken>, String>((
      ref,
      workspaceId,
    ) async {
      if (!ref.watch(canManageAutomationTokensProvider(workspaceId))) {
        return const [];
      }
      final data = await ref.watch(rpcClientProvider).call(
        'forge.listAutomationTokens',
        {'workspace_id': workspaceId},
      );
      return ForgeAutomationToken.listOf(data['tokens']);
    });

/// Stores [token] as [workspaceId]'s automation token for [forge]: for
/// [repoId] when given, else for the workspace. The server checks it with
/// the forge first and refuses one that is not a bot token or cannot read
/// the repository. Answers the covered repositories it cannot read.
Future<List<String>> saveAutomationToken(
  WidgetRef ref, {
  required String workspaceId,
  required ForgeHost forge,
  required String token,
  String? repoId,
}) async {
  final data = await ref
      .read(rpcClientProvider)
      .call('forge.setAutomationToken', {
        'workspace_id': workspaceId,
        'forge': forge.wire,
        'token': token,
        'repo_id': ?repoId,
      });
  ref.invalidate(automationTokensProvider(workspaceId));
  return [
    for (final name in data['unreadable_repos'] as List? ?? const [])
      if (name is String) name,
  ];
}

/// Removes [workspaceId]'s automation token for [forge] ([repoId]'s own, or
/// the workspace's). Automation left without one pauses.
Future<void> clearAutomationToken(
  WidgetRef ref, {
  required String workspaceId,
  required ForgeHost forge,
  String? repoId,
}) async {
  await ref.read(rpcClientProvider).call('forge.clearAutomationToken', {
    'workspace_id': workspaceId,
    'forge': forge.wire,
    'repo_id': ?repoId,
  });
  ref.invalidate(automationTokensProvider(workspaceId));
}
