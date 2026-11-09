import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectErrorCode, ConnectException;
import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart'
    show RepoOp, RepoOpContext, ServerAuthority;
import 'package:cc_server_core/src/catalog/sign_in_ops.dart'
    show providerOAuthHttpOrigin;
import 'package:cc_server_core/src/connect/connect_error_messages.dart';
import 'package:cc_server_core/src/connect/github_manifest_service.dart';
import 'package:cc_server_core/src/forge/github_clients.dart';

/// GitHub App setup: create this server's own App from a manifest
/// (`github.manifest.begin`, server owner), install a workspace's App
/// (`github.install.begin`, workspace admin), list what it is installed on
/// among the accounts owning this workspace's linked GitHub repositories
/// (`github.installations`, member) and bind an organization's existing
/// installation of Connect's shared App to this server
/// (`github.authorizeServer`, workspace admin; Connect checks the person
/// administers the organization).
///
/// Empty when there is no GitHub surface (demo).
List<RepoOp> buildGitHubAppOps({
  required GitHubClients? clients,
  required GitHubManifestService? manifest,
  required String pairingServerUrl,
  required RepoRepository repos,
}) {
  if (clients == null) {
    return const [];
  }

  Future<Map<String, Object?>> guarded(
    Future<Map<String, Object?>> Function() body,
  ) async {
    try {
      return await body();
    } on GitHubScopeRefused catch (e) {
      throw switch (e.code) {
        GitHubRefusal.needsSignIn ||
        GitHubRefusal.accessDenied => AuthException(e.message),
        _ => ValidationException(e.message),
      };
    } on ConnectException catch (e) {
      final message = connectErrorMessage(
        e.code,
        ConnectErrorContext.githubSetup,
      );
      throw switch (e.code) {
        ConnectErrorCode.needsSignIn ||
        ConnectErrorCode.accessDenied ||
        ConnectErrorCode.notAdmin ||
        ConnectErrorCode.installBlocked => AuthException(message),
        ConnectErrorCode.notInstalled => NotFoundException(message),
        _ => ValidationException(message),
      };
    }
  }

  return [
    if (manifest != null)
      RepoOp(
        name: 'github.manifest.begin',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        serverAuthority: ServerAuthority.serverOwner,
        handler: (ctx) async {
          final org = ctx.args['organization'];
          // The owner's own GitHub account, when they are signed in: a
          // personal app GitHub reports under anyone else is refused.
          final signedIn = await clients.credentials.storedCredential(
            ForgeHost.github,
            ctx.userId,
          );
          final url = manifest.begin(
            origin: providerOAuthHttpOrigin(pairingServerUrl),
            organization: org is String ? org : '',
            ownerAccountId: int.tryParse(signedIn?.token.accountId ?? ''),
          );
          return {'url': url.toString()};
        },
      ),
    RepoOp(
      name: 'github.install.begin',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.admin,
      handler: (ctx) => guarded(() async {
        final url = await clients.installLink(_workspace(ctx), ctx.userId);
        return {'url': url.toString()};
      }),
    ),
    RepoOp(
      name: 'github.installations',
      kind: RepoOpKind.read,
      handler: (ctx) => guarded(() async {
        // Only the organizations and users this workspace's repositories
        // live under: a person's other installations (and, for the server's
        // own App, other workspaces' organizations) are none of its business.
        final owners = {
          for (final repo in await repos.getAll(_workspace(ctx)))
            if (repo.forge == ForgeHost.github && repo.hasForgeRemote)
              repo.remoteOwner.toLowerCase(),
        };
        final views = [
          for (final view in await clients.installationsFor(
            _workspace(ctx),
            ctx.userId,
          ))
            if (owners.contains(view.accountLogin.toLowerCase())) view,
        ];
        return {
          'lane': (await clients.laneFor(_workspace(ctx))).wire,
          'installations': [for (final view in views) view.toJson()],
        };
      }),
    ),
    RepoOp(
      name: 'github.authorizeServer',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.admin,
      requiredArgs: const ['installation_id'],
      handler: (ctx) => guarded(() async {
        final raw = ctx.args['installation_id'];
        final id = raw is int ? raw : int.tryParse('$raw');
        if (id == null || id <= 0) {
          throw const ValidationException(
            'Missing or invalid argument: installation_id',
          );
        }
        await clients.authorizeServer(_workspace(ctx), ctx.userId, id);
        return {'authorized': true};
      }),
    ),
  ];
}

String _workspace(RepoOpContext ctx) {
  final id = ctx.workspaceId;
  if (id == null || id.isEmpty) {
    throw const NotFoundException('Missing or invalid argument: workspace_id');
  }
  return id;
}
