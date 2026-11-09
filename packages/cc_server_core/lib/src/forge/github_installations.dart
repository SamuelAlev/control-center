import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/forge/github_client_types.dart';
import 'package:cc_server_core/src/forge/github_lane_resolver.dart';
import 'package:cc_server_core/src/forge/github_minter.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';

/// Where a workspace's GitHub App is installed, how to install it, and the
/// bot it converses as.
final class GitHubInstallations {
  /// Creates the service.
  GitHubInstallations({
    required this.lanes,
    required this.connect,
    required this.seals,
    required this.rest,
    required this.humanToken,
    required this._now,
  });

  static const Duration _presenceTtl = Duration(minutes: 1);

  /// Lane and App resolution.
  final GitHubLaneResolver lanes;

  /// Connect.
  final ConnectClient connect;

  /// Stored seals.
  final GitHubSeals seals;

  /// The REST transport.
  final GitHubRest rest;

  /// The accountable human's own token in a workspace, or null.
  final Future<String?> Function(String workspaceId) humanToken;

  final DateTime Function() _now;

  final Map<String, ({GitHubBotPresence? presence, DateTime at})> _presence =
      {};

  /// The bot [workspaceId]'s automation converses as, and where its App is
  /// installed, or null when the workspace has no GitHub lane.
  ///
  /// An App lane reads its own installations. Connect cannot enumerate the
  /// shared App's installations for this server, so it lists the ones the
  /// workspace's accountable human can see (`GET /user/installations`).
  Future<GitHubBotPresence?> botPresence(String workspaceId) async {
    final now = _now();
    _presence.removeWhere((_, v) => now.difference(v.at) >= _presenceTtl);
    final cached = _presence[workspaceId];
    if (cached != null) {
      return cached.presence;
    }
    final presence = await _readPresence(workspaceId);
    _presence[workspaceId] = (presence: presence, at: _now());
    return presence;
  }

  /// Drops [workspaceId]'s cached presence (or every one).
  void forgetPresence([String? workspaceId]) =>
      workspaceId == null ? _presence.clear() : _presence.remove(workspaceId);

  Future<GitHubBotPresence?> _readPresence(String workspaceId) async {
    final lane = (await lanes.resolve(workspaceId)).lane;
    switch (lane) {
      case GitHubLane.none:
        return null;
      case GitHubLane.workspaceApp || GitHubLane.ownApp:
        final app = await lanes.appFor(workspaceId, lane);
        final info = await app?.botInfo();
        if (app == null || info == null || info.botLogin.isEmpty) {
          return null;
        }
        final installs = await app.installations();
        return GitHubBotPresence(
          botLogin: info.botLogin,
          slug: info.slug,
          owners: [
            for (final i in installs)
              if (i.account.isNotEmpty) i.account,
          ],
          suspendedOwners: {
            for (final i in installs)
              if (i.isSuspended) i.account.toLowerCase(),
          },
        );
      case GitHubLane.connect:
        final config = await lanes.connectGitHub();
        if (config == null) {
          return null;
        }
        final token = await humanToken(workspaceId);
        if (token == null) {
          return null;
        }
        final installs = await _userInstallations(token, config.appId);
        return GitHubBotPresence(
          botLogin: '${config.appSlug}[bot]',
          slug: config.appSlug,
          owners: [for (final i in installs) i.account],
          suspendedOwners: {
            for (final i in installs)
              if (i.suspended) i.account.toLowerCase(),
          },
        );
    }
  }

  Future<List<({String account, bool suspended})>> _userInstallations(
    String token,
    int appId,
  ) async {
    final response = await rest.send(
      'GET',
      '/user/installations',
      query: {'per_page': '100'},
      bearer: token,
    );
    final json = response.json;
    final list = json is Map ? json['installations'] : null;
    if (response.status != 200 || list is! List) {
      CcHostLog.warning(
        'github: listing installations failed (HTTP ${response.status})',
      );
      return const [];
    }
    return [
      for (final item in list)
        if (item is Map && item['app_id'] == appId)
          if (item['account'] case {
            'login': final String login,
          } when login.isNotEmpty)
            (account: login, suspended: item['suspended_at'] != null),
    ];
  }

  /// The link that installs [workspaceId]'s GitHub App, opened by [userId].
  ///
  /// On Connect the link carries a ticket that binds the new installation to
  /// this server (Connect verifies the installer before it records the
  /// binding). An own App needs no binding: it belongs to this server.
  Future<Uri> installLink(String workspaceId, String userId) async {
    final lane = (await lanes.resolve(workspaceId)).lane;
    switch (lane) {
      case GitHubLane.none:
        throw const GitHubScopeRefused(
          GitHubRefusal.notConfigured,
          'This workspace has no GitHub App to install.',
        );
      case GitHubLane.connect:
        final seal = await seals.sealFor(userId, workspaceId);
        final started = await connect.githubInstallStart(
          SealRequest(seal: seal.seal, workspaceId: seal.scope),
        );
        await seals.adopt(userId, seal.scope, started.updatedSeal);
        return started.installUrl;
      case GitHubLane.workspaceApp || GitHubLane.ownApp:
        final slug = (await (await lanes.appFor(
          workspaceId,
          lane,
        ))?.botInfo())?.slug;
        if (slug == null || slug.isEmpty) {
          throw const GitHubScopeRefused(
            GitHubRefusal.providerUnavailable,
            'GitHub did not answer for this App. Test its settings first.',
          );
        }
        return Uri.https('github.com', '/apps/$slug/installations/new');
    }
  }

  /// The installations [workspaceId]'s App has that [userId] may see.
  ///
  /// On Connect that is the installations the person can see on GitHub,
  /// each saying whether it is bound to this server and whether the person
  /// can bind it. An own App lists every installation; all are this
  /// server's. The `github.installations` op narrows either list to the
  /// accounts owning this workspace's linked repositories.
  Future<List<GitHubInstallationView>> installationsFor(
    String workspaceId,
    String userId,
  ) async {
    final lane = (await lanes.resolve(workspaceId)).lane;
    switch (lane) {
      case GitHubLane.none:
        return const [];
      case GitHubLane.connect:
        final seal = await seals.sealFor(userId, workspaceId);
        final listed = await connect.githubInstallations(
          SealRequest(seal: seal.seal, workspaceId: seal.scope),
        );
        await seals.adopt(userId, seal.scope, listed.updatedSeal);
        return listed.installations;
      case GitHubLane.workspaceApp || GitHubLane.ownApp:
        final app = await lanes.appFor(workspaceId, lane);
        if (app == null) {
          return const [];
        }
        return [
          for (final i in await app.installations(refresh: true))
            GitHubInstallationView(
              installationId: i.id,
              accountId: i.accountId,
              accountLogin: i.account,
              targetType: i.targetType,
              boundHere: true,
              suspended: i.isSuspended,
              callerIsAdmin: false,
            ),
        ];
    }
  }

  /// Binds an installation of Connect's shared App that already exists (an
  /// organization installed it on GitHub directly) to this server. Connect
  /// checks that [userId] administers the account.
  Future<void> authorizeServer(
    String workspaceId,
    String userId,
    int installationId,
  ) async {
    if ((await lanes.resolve(workspaceId)).lane != GitHubLane.connect) {
      throw const GitHubScopeRefused(
        GitHubRefusal.invalidRequest,
        'Only the shared Connect App needs authorizing; this workspace uses '
        'its own.',
      );
    }
    final seal = await seals.sealFor(userId, workspaceId);
    final ack = await connect.githubAuthorizeServer(
      GitHubAuthorizeServerRequest(
        seal: seal.seal,
        workspaceId: seal.scope,
        installationId: installationId,
      ),
    );
    await seals.adopt(userId, seal.scope, ack.updatedSeal);
    _presence.remove(workspaceId);
  }
}
