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
/// Presence flags only — the private key, client secret and background PAT
/// never leave the server.
class WorkspaceGitHubStatusView {
  /// Creates a [WorkspaceGitHubStatusView].
  const WorkspaceGitHubStatusView({
    required this.app,
    required this.mode,
    required this.hasBackgroundPat,
  });

  /// Decodes a `workspaceGitHub.status` payload.
  factory WorkspaceGitHubStatusView.fromJson(Map<String, dynamic> json) =>
      WorkspaceGitHubStatusView(
        app: ProviderAppStatusView.fromJson(json),
        mode: GithubAuthMode.fromWire(json['github_auth_mode'] as String?),
        hasBackgroundPat: json['has_background_pat'] as bool? ?? false,
      );

  /// App credentials for the workspace App (empty in inherit / PAT modes).
  final ProviderAppStatusView app;

  /// How this workspace authenticates to GitHub for background work.
  final GithubAuthMode mode;

  /// Whether a workspace background PAT is stored.
  final bool hasBackgroundPat;
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

/// Stores or clears this workspace's background GitHub PAT.
Future<void> setWorkspaceGitHubPat(WidgetRef ref, String token) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  await ref.read(rpcClientProvider).call('workspaceGitHub.setPat', {
    'token': token,
    ...overlayWorkspaceArgs(workspaceId),
  });
  ref.invalidate(workspaceGitHubStatusProvider);
}
