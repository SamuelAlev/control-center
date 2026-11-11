import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/forge/github_client_types.dart';
import 'package:cc_server_core/src/forge/github_lane_resolver.dart';
import 'package:cc_server_core/src/forge/github_minter.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';
import 'package:meta/meta.dart';

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
        final config = await lanes.connectGitHub(
          await connect.targetFor(workspaceId),
        );
        if (config == null) {
          return null;
        }
        final token = await humanToken(workspaceId);
        if (token == null) {
          return null;
        }
        final installs = await userInstallations(token, config.appId);
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

  /// The installations of App [appId] the bearer of [token] can see,
  /// every page of them (up to [_maxInstallationPages] of 100).
  @visibleForTesting
  Future<List<({String account, bool suspended})>> userInstallations(
    String token,
    int appId,
  ) async {
    final out = <({String account, bool suspended})>[];
    for (var page = 1; page <= _maxInstallationPages; page++) {
      final response = await rest.send(
        'GET',
        '/user/installations',
        query: {'per_page': '100', 'page': '$page'},
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
      out.addAll([
        for (final item in list)
          if (item is Map && item['app_id'] == appId)
            if (item['account'] case {
              'login': final String login,
            } when login.isNotEmpty)
              (account: login, suspended: item['suspended_at'] != null),
      ]);
      final total = json is Map ? json['total_count'] : null;
      if (list.length < 100 || (total is int && page * 100 >= total)) {
        break;
      }
    }
    return out;
  }

  static const int _maxInstallationPages = 10;

  /// The link that installs [workspaceId]'s GitHub App.
  ///
  /// Nothing is bound on the way: once an account installs the App, any
  /// server a member of it signs in on may mint (each token is the member's
  /// own, clamped to their role). Connect's App is named by its signed
  /// config's slug; an own App by GitHub's answer for it.
  Future<Uri> installLink(String workspaceId) async {
    final lane = (await lanes.resolve(workspaceId)).lane;
    switch (lane) {
      case GitHubLane.none:
        throw const GitHubScopeRefused(
          GitHubRefusal.notConfigured,
          'This workspace has no GitHub App to install.',
        );
      case GitHubLane.connect:
        final config = await lanes.connectGitHub(
          await connect.targetFor(workspaceId),
        );
        final slug = config?.appSlug ?? '';
        if (slug.isEmpty) {
          throw const GitHubScopeRefused(
            GitHubRefusal.providerUnavailable,
            'Control Center Connect did not name its GitHub App. Test the '
            'Connect settings first.',
          );
        }
        return Uri.https('github.com', '/apps/$slug/installations/new');
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
  /// On Connect that is the installations the person can see on GitHub; an
  /// own App lists every installation. Either way every listed installation
  /// is usable from this server. The `github.installations` op narrows either list to the
  /// accounts owning this workspace's linked repositories.
  ///
  /// An own App's listing is the App client's cached one (renewed when it
  /// lapses or the App changes); [refresh] asks GitHub afresh.
  Future<List<GitHubInstallationView>> installationsFor(
    String workspaceId,
    String userId, {
    bool refresh = false,
  }) async {
    final lane = (await lanes.resolve(workspaceId)).lane;
    switch (lane) {
      case GitHubLane.none:
        return const [];
      case GitHubLane.connect:
        final target = await connect.targetFor(workspaceId);
        final seal = await seals.sealFor(userId, workspaceId, target);
        final listed = await connect.githubInstallations(
          target,
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
          for (final i in await app.installations(refresh: refresh))
            GitHubInstallationView(
              installationId: i.id,
              accountId: i.accountId,
              accountLogin: i.account,
              targetType: i.targetType,
              suspended: i.isSuspended,
            ),
        ];
    }
  }
}
