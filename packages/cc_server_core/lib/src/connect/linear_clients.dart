import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_domain/cc_domain.dart' show NeedsSignInException;
import 'package:cc_domain/core/utils/single_flight.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_infra/cc_infra.dart' show createHttpClient;
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/linear_sign_in_lane.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart'
    show errorKindOf;
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:rhttp/rhttp.dart';

/// Renews one Linear grant ([slot] is the workspace for `linear_app`).
typedef LinearGrantRefresh =
    Future<RefreshOutcome> Function(
      ConnectOAuthLane lane,
      ProviderToken token, {
      String? slot,
    });

/// Every Linear credential this server uses, and who it acts as.
///
/// * [personAuthorization]: a member's own Linear sign-in (`linear` lane),
///   for actions that member takes. No sign-in, no credential:
///   [requirePersonAuthorization] and [personHttp] refuse with
///   `NeedsSignInException` (lane `linear`). A workspace that overrides the
///   server's Connect choice reads the member's grant from its own slot,
///   never the global one.
/// * [appAuthorization]: the workspace's Control Center app actor
///   (`linear_app`, `actor=app`) for ticket sync, pipelines and agents, so
///   automated issues and comments appear as Control Center. Without one, a
///   service API key: the workspace's own while it is on its own apps, the
///   server's `LINEAR_API_KEY` only while it inherits a server on its own
///   apps; nothing else.
///
/// In a workspace on its own apps, a grant issued to any other client id is
/// cleared on read: it answers "sign in again", never as the other app.
///
/// OAuth tokens are sent as `Bearer <token>`, an API key raw. Expiring
/// tokens refresh on use; [refreshAging] renews grants older than twenty
/// days so a refresh token never idles out (Linear's expire after thirty).
class LinearClients {
  /// Creates the clients.
  LinearClients({
    required this._people,
    required this._workspaces,
    required this._apps,
    required this._workspaceApps,
    required this._route,
    required this._refresh,
    this._revoke,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final UserCredentialsStore _people;
  final LinearAppGrants _workspaces;
  final ProviderAppSettings _apps;
  final WorkspaceProviderAppSettings _workspaceApps;
  final Future<ConnectRoute> Function(String? workspaceId) _route;
  final LinearGrantRefresh _refresh;
  final Future<void> Function(String accessToken)? _revoke;
  final DateTime Function() _now;

  /// How old a grant may get before the daily sweep renews it.
  static const Duration refreshAge = Duration(days: 20);

  final SingleFlight<String, ProviderToken?> _refreshing = SingleFlight();

  /// Renewed grants whose write failed, by grant key, with the stored grant
  /// they replace (`parent`). Linear rotates refresh tokens, so the renewed
  /// grant is the only one that still works: it is served from here and
  /// written again on the next use, until a new sign-in replaces `parent`.
  final Map<String, ({ProviderToken parent, ProviderToken token})> _unsaved =
      {};
  final Map<String, RhttpClient> _appHttp = {};
  final Map<String, RhttpClient> _personHttp = {};

  /// `Bearer <token>` for [userId]'s own Linear sign-in as seen from
  /// [workspaceId], or null.
  Future<String?> personAuthorization(String userId, String workspaceId) async {
    final slot = (await _route(workspaceId)).workspaceSlot ? workspaceId : null;
    final token = await _live(
      'person:$userId@${slot ?? ''}',
      read: () => _readOwned(
        workspaceId,
        () => _people.ticketToken(
          userId,
          TicketProvider.linear,
          workspaceId: slot,
        ),
        clear: () => _people.clearTicketToken(
          userId,
          TicketProvider.linear,
          workspaceId: slot,
        ),
      ),
      write: (t) => _people.setTicketToken(
        userId,
        TicketProvider.linear,
        t,
        workspaceId: slot,
      ),
      clear: () => _people.clearTicketToken(
        userId,
        TicketProvider.linear,
        workspaceId: slot,
      ),
      lane: ConnectOAuthLane.linear,
      slot: slot,
    );
    return token == null ? null : 'Bearer ${token.accessToken}';
  }

  /// The credential automation in [workspaceId] writes to Linear with: the
  /// workspace's app actor, else a service API key (the workspace's own on
  /// its own apps, the server's while it inherits a server on its own
  /// apps), else null.
  Future<String?> appAuthorization(String workspaceId) async {
    if (workspaceId.isEmpty) {
      return null;
    }
    final token = await _live(
      'app:$workspaceId',
      read: () => _readOwned(
        workspaceId,
        () => _workspaces.read(workspaceId),
        clear: () => _workspaces.delete(workspaceId),
      ),
      write: (t) => _workspaces.write(workspaceId, t),
      clear: () => _workspaces.delete(workspaceId),
      lane: ConnectOAuthLane.linearApp,
      slot: workspaceId,
    );
    if (token != null) {
      return 'Bearer ${token.accessToken}';
    }
    final route = await _route(workspaceId);
    final key = route.workspaceOwnApps
        ? await _workspaceApps.linearApiKey(workspaceId)
        : route.serverOwnApps
        ? await _apps.linearApiKey()
        : '';
    return key.isEmpty ? null : key;
  }

  /// A GraphQL client for automation in [workspaceId]. The credential is read
  /// per request; without one the request goes out unauthenticated and Linear
  /// refuses it, which the sync surfaces as an error.
  RhttpClient appHttp(String workspaceId) => _appHttp.putIfAbsent(
    workspaceId,
    () => _client(() => appAuthorization(workspaceId)),
  );

  /// [personAuthorization], or [NeedsSignInException] (lane `linear`) when
  /// [userId] has no usable Linear sign-in in [workspaceId]: an action a
  /// person takes never goes out unauthenticated or as anyone else.
  Future<String> requirePersonAuthorization(
    String userId,
    String workspaceId,
  ) async {
    final value = userId.isEmpty
        ? null
        : await personAuthorization(userId, workspaceId);
    if (value == null) {
      throw NeedsSignInException(
        ConnectOAuthLane.linear.wire,
        'Sign in to Linear to do this as yourself.',
      );
    }
    return value;
  }

  /// A GraphQL client acting as [userId] in [workspaceId]. Without their own
  /// Linear sign-in a request fails locally with [NeedsSignInException]
  /// (wrapped by rhttp in an `RhttpInterceptorException`, which the RPC
  /// mapper unwraps); nothing is sent.
  RhttpClient personHttp(String userId, String workspaceId) =>
      _personHttp.putIfAbsent(
        '$userId@$workspaceId',
        () => _client(() => requirePersonAuthorization(userId, workspaceId)),
      );

  /// Drops (and revokes, best effort) every member's Linear grant kept in
  /// [workspaceId]'s own slot, leaving its app actor alone. Runs when the
  /// server's choice changed and the workspace no longer owns a slot: its
  /// members' global grants apply there now, and the slot is never read.
  Future<void> resetPersonSlot(String workspaceId) async {
    final removed = await _people.clearWorkspaceTicketTokens(
      workspaceId,
      TicketProvider.linear,
    );
    final revoke = _revoke;
    if (revoke == null) {
      return;
    }
    for (final token in removed) {
      if (token.accessToken.isNotEmpty) {
        await revoke(token.accessToken);
      }
    }
  }

  /// Drops every Linear grant [workspaceId]'s previous app issued: its app
  /// actor and its members' grants in its own slot, revoked upstream best
  /// effort. Runs when the workspace's own Linear app or its Connect choice
  /// changes; the global grants of people who also sign in elsewhere are
  /// untouched.
  Future<void> resetWorkspace(String workspaceId) async {
    final removed = [
      ?await _workspaces.read(workspaceId),
      ...await _people.clearWorkspaceTicketTokens(
        workspaceId,
        TicketProvider.linear,
      ),
    ];
    await _workspaces.delete(workspaceId);
    final revoke = _revoke;
    if (revoke == null) {
      return;
    }
    for (final token in removed) {
      if (token.accessToken.isNotEmpty) {
        await revoke(token.accessToken);
      }
    }
  }

  /// The stored grant from [read], unless [workspaceId] is on its own apps
  /// and the grant was issued to another client: then it is cleared.
  Future<ProviderToken?> _readOwned(
    String workspaceId,
    Future<ProviderToken?> Function() read, {
    required Future<void> Function() clear,
  }) async {
    final token = await read();
    if (token == null) {
      return null;
    }
    final expected = (await _route(workspaceId)).workspaceOwnApps
        ? await _workspaceApps.ownClientId(
            workspaceId,
            WorkspaceAppProvider.linear,
          )
        : null;
    if (expected != null && expected != token.appId) {
      forgeAudit(ForgeAuditEvent.grantCleared, {
        'lane': 'linear',
        'workspace_id': workspaceId,
        'reason': 'app_changed',
      });
      await clear();
      return null;
    }
    return token;
  }

  RhttpClient _client(Future<String?> Function() authorization) =>
      createHttpClient(
        baseUrl: linearGraphQlEndpoint.toString(),
        interceptors: [
          SimpleInterceptor(
            beforeRequest: (request) async {
              final value = await authorization();
              if (value == null) {
                return Interceptor.next(request);
              }
              return Interceptor.next(
                request.copyWith(
                  headers: (request.headers ?? HttpHeaders.empty).copyWithRaw(
                    name: 'Authorization',
                    value: value,
                  ),
                ),
              );
            },
          ),
        ],
      );

  /// Renews every stored Linear grant obtained more than [refreshAge] ago (or
  /// at an unknown time). Returns how many were renewed. A workspace grant is
  /// renewed only while [isLiveWorkspace] says its workspace is still
  /// registered and not deleted: a deleted workspace's grant is never kept
  /// alive.
  Future<int> refreshAging({
    required Future<bool> Function(String workspaceId) isLiveWorkspace,
  }) async {
    var renewed = 0;
    bool aging(ProviderToken token) {
      final at = token.issuedAt;
      return at == null || _now().difference(at) >= refreshAge;
    }

    for (final workspaceId in await _workspaces.workspaces()) {
      final token = await _workspaces.read(workspaceId);
      if (token == null ||
          !aging(token) ||
          !await isLiveWorkspace(workspaceId)) {
        continue;
      }
      final fresh = await _renew(
        'app:$workspaceId',
        token,
        read: () => _workspaces.read(workspaceId),
        write: (t) => _workspaces.write(workspaceId, t),
        clear: () => _workspaces.delete(workspaceId),
        lane: ConnectOAuthLane.linearApp,
        slot: workspaceId,
      );
      if (fresh != null) {
        renewed++;
      }
    }
    for (final (:workspaceId, :userId) in await _people.workspaceTicketSlots(
      TicketProvider.linear,
    )) {
      final token = await _people.ticketToken(
        userId,
        TicketProvider.linear,
        workspaceId: workspaceId,
      );
      if (token == null ||
          !aging(token) ||
          !await isLiveWorkspace(workspaceId)) {
        continue;
      }
      final fresh = await _renew(
        'person:$userId@$workspaceId',
        token,
        read: () => _people.ticketToken(
          userId,
          TicketProvider.linear,
          workspaceId: workspaceId,
        ),
        write: (t) => _people.setTicketToken(
          userId,
          TicketProvider.linear,
          t,
          workspaceId: workspaceId,
        ),
        clear: () => _people.clearTicketToken(
          userId,
          TicketProvider.linear,
          workspaceId: workspaceId,
        ),
        lane: ConnectOAuthLane.linear,
        slot: workspaceId,
      );
      if (fresh != null) {
        renewed++;
      }
    }
    for (final userId in await _people.ticketUsers(TicketProvider.linear)) {
      final token = await _people.ticketToken(userId, TicketProvider.linear);
      if (token == null || !aging(token)) {
        continue;
      }
      final fresh = await _renew(
        'person:$userId@',
        token,
        read: () => _people.ticketToken(userId, TicketProvider.linear),
        write: (t) => _people.setTicketToken(userId, TicketProvider.linear, t),
        clear: () => _people.clearTicketToken(userId, TicketProvider.linear),
        lane: ConnectOAuthLane.linear,
        slot: null,
      );
      if (fresh != null) {
        renewed++;
      }
    }
    return renewed;
  }

  Future<ProviderToken?> _live(
    String key, {
    required Future<ProviderToken?> Function() read,
    required Future<void> Function(ProviderToken token) write,
    required Future<void> Function() clear,
    required ConnectOAuthLane lane,
    required String? slot,
  }) async {
    final onDisk = await read();
    final token = _effective(key, onDisk);
    if (token == null) {
      return null;
    }
    if (!identical(token, onDisk)) {
      await _save(key, onDisk!, token, write, lane);
    }
    if (!token.isExpired) {
      return token;
    }
    return _renew(
      key,
      token,
      read: read,
      write: write,
      clear: clear,
      lane: lane,
      slot: slot,
    );
  }

  /// The grant in force for [key]: a renewed one whose write failed while
  /// [onDisk] is still the grant it replaced, else [onDisk].
  ProviderToken? _effective(String key, ProviderToken? onDisk) {
    final kept = _unsaved[key];
    if (onDisk == null || kept == null || !_sameGrant(kept.parent, onDisk)) {
      _unsaved.remove(key);
      return onDisk;
    }
    return kept.token;
  }

  /// Writes the renewed [token] (replacing [parent], the stored grant); on
  /// failure keeps it in memory to serve and write again on the next use.
  Future<void> _save(
    String key,
    ProviderToken parent,
    ProviderToken token,
    Future<void> Function(ProviderToken token) write,
    ConnectOAuthLane lane,
  ) async {
    try {
      await write(token);
      _unsaved.remove(key);
    } on Object catch (e) {
      _unsaved[key] = (parent: parent, token: token);
      forgeAudit(ForgeAuditEvent.grantPersistFailed, {
        'lane': lane.wire,
        'reason': errorKindOf(e),
        'kept_in_memory': true,
      }, token: token.accessToken);
    }
  }

  /// One refresh per grant at a time: Linear rotates refresh tokens, so two
  /// concurrent refreshes would burn the grant.
  ///
  /// The flight re-reads the stored grant before spending its refresh token:
  /// a caller that read [token] just before another renewal settled finds
  /// the renewed grant instead of replaying the rotated-out refresh token.
  /// The result is written (or the grant cleared) only while the stored
  /// grant is still the one refreshed, so a sign-in that landed meanwhile
  /// wins.
  Future<ProviderToken?> _renew(
    String key,
    ProviderToken token, {
    required Future<ProviderToken?> Function() read,
    required Future<void> Function(ProviderToken token) write,
    required Future<void> Function() clear,
    required ConnectOAuthLane lane,
    required String? slot,
  }) => _refreshing.run(key, () async {
    final stored = _effective(key, await read());
    if (stored == null) {
      return null;
    }
    if (!_sameGrant(stored, token)) {
      return stored.isExpired ? null : stored;
    }
    final outcome = await _refresh(lane, stored, slot: slot);
    final onDisk = await read();
    final current = _effective(key, onDisk);
    if (current == null) {
      return null;
    }
    if (!_sameGrant(current, stored)) {
      return current.isExpired ? null : current;
    }
    switch (outcome) {
      case Refreshed(:final token):
        await _save(key, onDisk!, token, write, lane);
        return token;
      case RefreshRejected():
        forgeAudit(ForgeAuditEvent.grantCleared, {
          'lane': lane.wire,
          'workspace_id': slot,
          'reason': 'refresh_rejected',
        });
        _unsaved.remove(key);
        await clear();
        return null;
      case RefreshUnavailable():
        // Keep the grant; an unexpired access token still works.
        return stored.isExpired ? null : stored;
    }
  });

  static bool _sameGrant(ProviderToken a, ProviderToken b) =>
      a.refreshToken == b.refreshToken && a.accessToken == b.accessToken;
}
