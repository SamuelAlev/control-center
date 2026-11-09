import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart' show createHttpClient;
import 'package:cc_server_core/src/connect/linear_sign_in_lane.dart';
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
///   for actions that member takes. No sign-in, no credential: the caller
///   refuses with "Sign in to Linear". A workspace on its own Linear app
///   reads the member's grant from its own slot, never the global one.
/// * [appAuthorization]: the workspace's Control Center app actor
///   (`linear_app`, `actor=app`) for ticket sync, pipelines and agents, so
///   automated issues and comments appear as Control Center. The operator
///   may instead configure a service `LINEAR_API_KEY` (a workspace on its
///   own app: only its own key); nothing else.
///
/// In a workspace on its own app, a grant issued to any other client id is
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
    required this._refresh,
    this._revoke,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final UserCredentialsStore _people;
  final LinearAppGrants _workspaces;
  final ProviderAppSettings _apps;
  final WorkspaceProviderAppSettings _workspaceApps;
  final LinearGrantRefresh _refresh;
  final Future<void> Function(String accessToken)? _revoke;
  final DateTime Function() _now;

  /// How old a grant may get before the daily sweep renews it.
  static const Duration refreshAge = Duration(days: 20);

  final Map<String, Future<ProviderToken?>> _refreshing = {};
  final Map<String, RhttpClient> _appHttp = {};
  final Map<String, RhttpClient> _personHttp = {};

  /// `Bearer <token>` for [userId]'s own Linear sign-in as seen from
  /// [workspaceId], or null.
  Future<String?> personAuthorization(String userId, String workspaceId) async {
    final slot =
        await _workspaceApps.ownsApp(workspaceId, WorkspaceAppProvider.linear)
        ? workspaceId
        : null;
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
  /// workspace's app actor, else its service API key (the workspace's own
  /// when it uses its own app, else the server's), else null.
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
    final key =
        await _workspaceApps.linearApiKey(workspaceId) ??
        await _apps.linearApiKey();
    return key.isEmpty ? null : key;
  }

  /// A GraphQL client for automation in [workspaceId]. The credential is read
  /// per request; without one the request goes out unauthenticated and Linear
  /// refuses it, which the sync surfaces as an error.
  RhttpClient appHttp(String workspaceId) => _appHttp.putIfAbsent(
    workspaceId,
    () => _client(() => appAuthorization(workspaceId)),
  );

  /// A GraphQL client acting as [userId] in [workspaceId].
  RhttpClient personHttp(String userId, String workspaceId) =>
      _personHttp.putIfAbsent(
        '$userId@$workspaceId',
        () => _client(() => personAuthorization(userId, workspaceId)),
      );

  /// Drops every Linear grant [workspaceId]'s previous app issued: its app
  /// actor and its members' grants in its own slot, revoked upstream best
  /// effort. Runs when the workspace changes or leaves its own Linear app;
  /// the global grants of people who also sign in elsewhere are untouched.
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

  /// The stored grant from [read], unless [workspaceId] uses its own Linear
  /// app and the grant was issued to another client: then it is cleared.
  Future<ProviderToken?> _readOwned(
    String workspaceId,
    Future<ProviderToken?> Function() read, {
    required Future<void> Function() clear,
  }) async {
    final token = await read();
    if (token == null) {
      return null;
    }
    final expected = await _workspaceApps.ownClientId(
      workspaceId,
      WorkspaceAppProvider.linear,
    );
    if (expected != null && expected != token.appId) {
      CcHostLog.info(
        'linear: a grant in workspace $workspaceId came from another app; '
        'sign in again',
      );
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
  /// at an unknown time). Returns how many were renewed.
  Future<int> refreshAging() async {
    var renewed = 0;
    bool aging(ProviderToken token) {
      final at = token.issuedAt;
      return at == null || _now().difference(at) >= refreshAge;
    }

    for (final workspaceId in await _workspaces.workspaces()) {
      final token = await _workspaces.read(workspaceId);
      if (token == null || !aging(token)) {
        continue;
      }
      final fresh = await _renew(
        'app:$workspaceId',
        token,
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
      if (token == null || !aging(token)) {
        continue;
      }
      final fresh = await _renew(
        'person:$userId@$workspaceId',
        token,
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
    final token = await read();
    if (token == null) {
      return null;
    }
    if (!token.isExpired) {
      return token;
    }
    return _renew(
      key,
      token,
      write: write,
      clear: clear,
      lane: lane,
      slot: slot,
    );
  }

  /// One refresh per grant at a time: Linear rotates refresh tokens, so two
  /// concurrent refreshes would burn the grant.
  Future<ProviderToken?> _renew(
    String key,
    ProviderToken token, {
    required Future<void> Function(ProviderToken token) write,
    required Future<void> Function() clear,
    required ConnectOAuthLane lane,
    required String? slot,
  }) {
    final inflight = _refreshing[key];
    if (inflight != null) {
      return inflight;
    }
    final future = () async {
      final outcome = await _refresh(lane, token, slot: slot);
      switch (outcome) {
        case Refreshed(:final token):
          await write(token);
          return token;
        case RefreshRejected():
          CcHostLog.info('linear: ${lane.wire} grant refused; sign in again');
          await clear();
          return null;
        case RefreshUnavailable():
          // Keep the grant; an unexpired access token still works.
          return token.isExpired ? null : token;
      }
    }();
    _refreshing[key] = future;
    return future.whenComplete(() => _refreshing.remove(key));
  }
}
