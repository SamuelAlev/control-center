import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, RepoOpKind;
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_oauth_service.dart';

/// Resolves the workspace overlay for unscoped credential and OAuth calls.
/// A workspace must exist before consulting its membership database.
Future<String?> checkedOverlayWorkspaceId(
  RepoOpContext ctx, {
  required WorkspaceRepository workspaces,
  WorkspaceMembershipRepository? members,
}) async {
  final raw = ctx.args['workspace_id'];
  final id = raw is String && raw.isNotEmpty ? raw : ctx.workspaceId;
  if (id == null || id.isEmpty) {
    return null;
  }
  if (await workspaces.getById(id) == null) {
    throw const NotFoundException('Workspace not found');
  }
  if (members != null && await members.getMember(id, ctx.userId) == null) {
    throw const AuthException('Not a member of this workspace');
  }
  return id;
}

/// HTTP origin advertised for OAuth redirects and app settings.
String providerOAuthHttpOrigin(String rpcUrl) {
  if (rpcUrl.isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(rpcUrl);
  if (uri == null || uri.host.isEmpty) {
    return '';
  }
  final scheme = uri.scheme == 'wss' || uri.scheme == 'https'
      ? 'https'
      : 'http';
  return Uri(scheme: scheme, host: uri.host, port: uri.port).toString();
}

/// Provider discovery, device-attempt status, and sign-in are scoped to the
/// authenticated caller. Omitted together when OAuth is unavailable (demo).
List<RepoOp> buildProviderOAuthOps({
  required ProviderOAuthService? providerOAuth,
  required WorkspaceRepository workspaces,
  required WorkspaceMembershipRepository members,
  required String pairingServerUrl,
}) {
  if (providerOAuth == null) {
    return const [];
  }
  return [
    // Configured providers offer sign-in; others offer a token field.
    RepoOp(
      name: 'oauth.providers',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final available = await providerOAuth.availableProviders(
          workspaceId: await checkedOverlayWorkspaceId(
            ctx,
            workspaces: workspaces,
            members: members,
          ),
        );
        final origin = providerOAuthHttpOrigin(pairingServerUrl);
        return {
          'providers': [
            for (final provider in available)
              {
                'provider': provider.wire,
                // Device flow needs no callback URL.
                'flow': ProviderOAuthService.usesDeviceFlow(provider)
                    ? 'device'
                    : 'redirect',
                'redirect_uri':
                    origin.isEmpty ||
                        ProviderOAuthService.usesDeviceFlow(provider)
                    ? ''
                    : providerOAuthRedirectUri(
                        origin,
                        provider.wire,
                      ).toString(),
              },
          ],
        };
      },
    ),
    RepoOp(
      name: 'oauth.status',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['login_id'],
      handler: (ctx) async => {
        'status': providerOAuth
            .deviceLoginStatus(
              loginId: ctx.args['login_id'] as String,
              userId: ctx.userId,
              workspaceId: await checkedOverlayWorkspaceId(
                ctx,
                workspaces: workspaces,
                members: members,
              ),
            )
            .name,
      },
    ),
    // The user comes from the authenticated session, never client arguments.
    RepoOp(
      name: 'oauth.begin',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['provider'],
      handler: (ctx) async {
        final provider = ProviderApp.fromWire(ctx.args['provider'] as String?);
        if (provider == null) {
          throw const NotFoundException(
            'Missing or invalid argument: provider',
          );
        }
        if (ProviderOAuthService.usesDeviceFlow(provider)) {
          final prompt = await providerOAuth.beginDeviceLogin(
            provider: provider,
            userId: ctx.userId,
            workspaceId: await checkedOverlayWorkspaceId(
              ctx,
              workspaces: workspaces,
              members: members,
            ),
          );
          return prompt.toJson();
        }
        final origin = providerOAuthHttpOrigin(pairingServerUrl);
        if (origin.isEmpty) {
          throw const AuthException(
            'This server does not advertise a reachable URL, so a sign-in '
            'has nowhere to come back to.',
          );
        }
        final url = await providerOAuth.beginLogin(
          provider: provider,
          userId: ctx.userId,
          redirectUri: providerOAuthRedirectUri(origin, provider.wire),
          workspaceId: await checkedOverlayWorkspaceId(
            ctx,
            workspaces: workspaces,
            members: members,
          ),
        );
        return {'mode': 'redirect', 'url': url.toString()};
      },
    ),
  ];
}
