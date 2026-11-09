import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_server_core/src/catalog/sign_in_ops.dart'
    show providerOAuthHttpOrigin;
import 'package:cc_server_core/src/connect/sign_in_service.dart'
    show providerOAuthRedirectUri;
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';

/// The callback URLs a workspace's own [provider] app must register, under
/// this server's HTTP [origin]: the same string the sign-in sends. Linear has
/// a second lane for the workspace's app actor; Klipy signs nobody in.
List<String> workspaceAppRedirectUris(
  String origin,
  WorkspaceAppProvider provider,
) {
  if (origin.isEmpty) {
    return const [];
  }
  return switch (provider) {
    WorkspaceAppProvider.google => [
      providerOAuthRedirectUri(origin, 'google').toString(),
    ],
    WorkspaceAppProvider.linear => [
      providerOAuthRedirectUri(origin, 'linear').toString(),
      providerOAuthRedirectUri(origin, 'linear_app').toString(),
    ],
    WorkspaceAppProvider.klipy => const [],
  };
}

/// A workspace's own Google, Linear and Klipy apps
/// (`workspaceProviderApps.*`).
///
/// Admin of the bound workspace (the dispatcher checks the workspace exists
/// and the caller's role before the handler runs). Secrets are write-only:
/// what comes back is presence flags. Empty when the host wires no
/// [WorkspaceProviderAppSettings] (demo, tests).
List<RepoOp> buildWorkspaceProviderAppOps({
  required WorkspaceProviderAppSettings? apps,
  required String pairingServerUrl,
}) {
  if (apps == null) {
    return const [];
  }

  WorkspaceAppProvider providerOf(RepoOpContext ctx) {
    final provider = WorkspaceAppProvider.fromWire(ctx.args['provider']);
    if (provider == null) {
      throw const NotFoundException('Missing or invalid argument: provider');
    }
    return provider;
  }

  Map<String, Object?> wire(WorkspaceProviderAppStatus status) => {
    ...status.toJson(),
    'redirect_uris': workspaceAppRedirectUris(
      providerOAuthHttpOrigin(pairingServerUrl),
      status.provider,
    ),
  };

  return [
    RepoOp(
      name: 'workspaceProviderApps.list',
      kind: RepoOpKind.read,
      minRole: WorkspaceRole.admin,
      handler: (ctx) async => {
        'apps': [
          for (final status in await apps.statuses(ctx.workspaceId!))
            wire(status),
        ],
      },
    ),
    RepoOp(
      name: 'workspaceProviderApps.setMode',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.admin,
      requiredArgs: ['provider', 'mode'],
      handler: (ctx) async {
        final mode = WorkspaceAppMode.fromWire(ctx.args['mode']);
        if (mode == null) {
          throw const ValidationException(
            'mode must be "inherit" or "own".',
          );
        }
        return wire(
          await apps.setMode(ctx.workspaceId!, providerOf(ctx), mode),
        );
      },
    ),
    RepoOp(
      name: 'workspaceProviderApps.save',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.admin,
      requiredArgs: ['provider'],
      handler: (ctx) async {
        final provider = providerOf(ctx);
        // A field the form did not send is left alone; an empty string
        // clears it, so the form never has to re-send a secret it was never
        // shown.
        final fields = <String, String>{
          for (final field in WorkspaceProviderAppSettings.fieldsOf(provider))
            if (ctx.args[field] case final String value) field: value,
        };
        return wire(await apps.save(ctx.workspaceId!, provider, fields));
      },
    ),
  ];
}
