import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/value_objects/github_auth_mode.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/providers/provider_apps_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// This workspace's GitHub identity as the server reports it.
///
/// Presence flags only — the private key and client secret never leave the
/// server.
class WorkspaceGitHubStatusView {
  /// Creates a [WorkspaceGitHubStatusView].
  const WorkspaceGitHubStatusView({required this.app, required this.mode});

  /// Decodes a `workspaceGitHub.status` payload.
  factory WorkspaceGitHubStatusView.fromJson(Map<String, dynamic> json) =>
      WorkspaceGitHubStatusView(
        app: ProviderAppStatusView.fromJson(json),
        mode: GithubAuthMode.fromWire(json['github_auth_mode'] as String?),
      );

  /// App credentials for the workspace App (empty in inherit mode).
  final ProviderAppStatusView app;

  /// Whether the workspace inherits the server's GitHub lane or has its own
  /// App.
  final GithubAuthMode mode;
}

/// The current workspace's GitHub identity, or null when the card should not
/// render (demo, non-admin, or an older server).
final workspaceGitHubStatusProvider =
    FutureProvider<WorkspaceGitHubStatusView?>((ref) async {
      if (ref.watch(isDemoServerProvider)) {
        return null;
      }
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return null;
      }
      final role = ref.watch(myWorkspaceRoleProvider(workspaceId));
      if (role == null || !role.isAdmin) {
        return null;
      }
      try {
        final data = await ref
            .watch(rpcClientProvider)
            .call('workspaceGitHub.status', overlayWorkspaceArgs(workspaceId));
        return WorkspaceGitHubStatusView.fromJson(data);
      } on Object {
        return null;
      }
    });

/// Saves one field of this workspace's GitHub App credentials.
Future<void> saveWorkspaceGitHubApp(
  WidgetRef ref,
  Map<String, String> fields,
) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  await ref.read(rpcClientProvider).call('workspaceGitHub.save', {
    ...fields,
    ...overlayWorkspaceArgs(workspaceId),
  });
  ref.invalidate(workspaceGitHubStatusProvider);
}

/// Asks GitHub whether this workspace's App credentials actually work.
Future<WorkspaceGitHubStatusView> testWorkspaceGitHubApp(WidgetRef ref) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  final data = await ref.read(rpcClientProvider).call(
    'workspaceGitHub.test',
    overlayWorkspaceArgs(workspaceId),
  );
  ref.invalidate(workspaceGitHubStatusProvider);
  return WorkspaceGitHubStatusView.fromJson(data);
}

/// The GitHub App setup ops (manifest, install link, installations).
final githubAppSetupProvider = Provider<RemoteGitHubAppSetup>(
  (ref) => RemoteGitHubAppSetup(ref.watch(rpcClientProvider)),
);

/// The installations a workspace's GitHub lane can see. Never completes
/// with an error: a failure reads as "none yet".
final githubInstallationsProvider =
    FutureProvider.family<List<GitHubInstallationView>, String>((
      ref,
      workspaceId,
    ) async {
      try {
        return await ref
            .watch(githubAppSetupProvider)
            .installations(workspaceId: workspaceId);
      } on Object {
        return const [];
      }
    });
