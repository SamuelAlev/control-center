import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/providers/provider_apps_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One provider's workspace app as the server reports it.
///
/// Presence flags only: client secrets and keys never leave the server, so
/// this class has nowhere to put them. Whether the app is USED is the
/// workspace's Connect choice (own apps), not a per-provider switch.
class WorkspaceProviderAppView {
  /// Creates a [WorkspaceProviderAppView].
  const WorkspaceProviderAppView({
    required this.provider,
    this.clientId = '',
    this.hasClientSecret = false,
    this.hasApiKey = false,
    this.hasAppKey = false,
    this.state = ProviderAppState.none,
    this.redirectUris = const [],
    this.error = '',
  });

  /// Decodes one `workspaceProviderApps.list` entry.
  factory WorkspaceProviderAppView.fromJson(Map<String, dynamic> json) =>
      WorkspaceProviderAppView(
        provider: json['provider'] as String? ?? '',
        clientId: json['client_id'] as String? ?? '',
        hasClientSecret: json['has_client_secret'] as bool? ?? false,
        hasApiKey: json['has_api_key'] as bool? ?? false,
        hasAppKey: json['has_app_key'] as bool? ?? false,
        state: ProviderAppState.fromWire(json['state']),
        redirectUris: [
          for (final uri in (json['redirect_uris'] as List? ?? const []))
            if (uri is String && uri.isNotEmpty) uri,
        ],
        error: json['error'] as String? ?? '',
      );

  /// The provider's wire id (`google`, `linear`, `klipy`).
  final String provider;

  /// The OAuth client id (not a secret).
  final String clientId;

  /// Whether a client secret is stored (Google).
  final bool hasClientSecret;

  /// Whether a service API key is stored (Linear, optional).
  final bool hasApiKey;

  /// Whether an app key is stored (Klipy).
  final bool hasAppKey;

  /// How complete the workspace's own app is; `partial` is a setup error
  /// while the workspace uses its own apps.
  final ProviderAppState state;

  /// The callback URLs the workspace's app must register, verbatim.
  final List<String> redirectUris;

  /// What to fix, or empty.
  final String error;
}

/// The active workspace's own provider apps, or empty when the card should
/// not render (demo, non-admin, or no workspace).
final workspaceProviderAppsProvider =
    FutureProvider<List<WorkspaceProviderAppView>>((ref) async {
      if (ref.watch(isDemoServerProvider)) {
        return const [];
      }
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return const [];
      }
      final role = ref.watch(myWorkspaceRoleProvider(workspaceId));
      if (role == null || !role.isAdmin) {
        return const [];
      }
      try {
        final data = await ref.watch(rpcClientProvider).call(
          'workspaceProviderApps.list',
          {'workspace_id': workspaceId},
        );
        return [
          for (final entry
              in (data['apps'] as List? ?? const [])
                  .whereType<Map<String, dynamic>>())
            WorkspaceProviderAppView.fromJson(entry),
        ];
      } on Object {
        return const [];
      }
    });

/// Saves fields of the active workspace's own [provider] app. A field not in
/// [fields] is left alone; an empty string clears it.
Future<void> saveWorkspaceProviderApp(
  WidgetRef ref,
  String provider,
  Map<String, String> fields,
) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return;
  }
  await ref.read(rpcClientProvider).call('workspaceProviderApps.save', {
    'workspace_id': workspaceId,
    'provider': provider,
    ...fields,
  });
  ref
    ..invalidate(workspaceProviderAppsProvider)
    ..invalidate(oauthLanesProvider(workspaceId));
}
