import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SealRequest;
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/utils/single_flight.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_draft.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_reschedule.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:rhttp/rhttp.dart';
import 'package:uuid/uuid.dart';

/// The deterministic account id for one member's Google account in one
/// workspace. Embedding [userId] keeps two members who connect the same
/// Google email on distinct rows and distinct credentials.
String serverGoogleAccountId(
  String workspaceId,
  String email, {
  required String userId,
}) => 'google:$workspaceId:$userId:$email';

/// Recovers the workspace id embedded in a [serverGoogleAccountId], or null if
/// malformed. Workspace ids are UUIDs and emails contain no `:`, so the
/// workspace id is always the second `:`-separated segment.
String? _workspaceIdFromAccountId(String accountId) {
  final parts = accountId.split(':');
  if (parts.length < 3 || parts[0] != 'google' || parts[1].isEmpty) {
    return null;
  }
  return parts[1];
}

/// The member embedded in a [serverGoogleAccountId] (its third segment), or
/// empty.
String _userIdFromAccountId(String accountId) {
  final parts = accountId.split(':');
  return parts.length < 4 ? '' : parts[2];
}

/// The email embedded in a [serverGoogleAccountId] (its last segment), or
/// empty.
String _emailFromAccountId(String accountId) {
  final parts = accountId.split(':');
  return parts.length < 4 ? '' : parts.last;
}

/// Google Calendar credentials, keyed `google_<accountId>` in the server's
/// [FileSecretsStore], each a [ProviderToken] JSON.
///
/// An own-app credential holds its access and refresh tokens. A Connect
/// credential holds only its seal: [ProviderToken.encode] never writes the
/// access token of a sealed credential, which lives in the
/// [ServerGoogleTokenManager]'s memory instead.
class FileGoogleCredentialsStore {
  /// Creates a store over the server's shared secrets file.
  FileGoogleCredentialsStore(this._secrets);

  final FileSecretsStore _secrets;

  /// Namespaced so a credential can never collide with a device id.
  static String _key(String accountId) => 'google_$accountId';

  /// The stored value for [accountId], parsed or not; null when none is
  /// stored.
  Future<String?> raw(String accountId) => _secrets.readPsk(_key(accountId));

  /// The credential for [accountId], or null when none is stored or the
  /// stored value is not a [ProviderToken].
  Future<ProviderToken?> load(String accountId) async =>
      ProviderToken.tryParse(await raw(accountId));

  /// Persists [token] for [accountId].
  Future<void> save(String accountId, ProviderToken token) async {
    await _secrets.writePsk(_key(accountId), token.encode());
  }

  /// Removes [accountId]'s credential.
  Future<void> clear(String accountId) => _secrets.deletePsk(_key(accountId));

  /// Every account id holding a credential in [workspaceId].
  Future<List<String>> accountIdsIn(String workspaceId) async {
    final prefix = _key('google:$workspaceId:');
    return [
      for (final key in await _secrets.keysMatching(
        (key) => key.startsWith(prefix),
      ))
        key.substring('google_'.length),
    ];
  }

  /// Every account id holding a credential, in every workspace.
  Future<List<String>> allAccountIds() async => [
    for (final key in await _secrets.keysMatching(
      (key) => key.startsWith(_key('google:')),
    ))
      key.substring('google_'.length),
  ];

  /// True when [key] is a calendar credential of [workspaceId].
  static bool isWorkspaceSecret(String key, String workspaceId) =>
      key.startsWith(_key('google:$workspaceId:'));
}

/// Renews an expired Google credential for an account in a workspace.
typedef GoogleTokenRefresh =
    Future<RefreshOutcome> Function(ProviderToken expired, String workspaceId);

/// Loads, validates and refreshes the server's Google access tokens.
///
/// Access tokens live in memory; a sealed (Connect) credential has nothing
/// else to offer on disk. Refreshes are single-flighted per account so
/// concurrent Calendar requests share one network call — Connect seals are
/// single-use. Only [RefreshRejected] clears a credential (and calls
/// `onInvalidGrant`); [RefreshUnavailable] keeps everything and answers null
/// for this call, because an expired access token must never be sent.
class ServerGoogleTokenManager {
  /// Creates a [ServerGoogleTokenManager].
  ///
  /// `installId` is this server's current install id towards the given
  /// Connect base URL as the account's workspace sees it (empty when that
  /// workspace's Connect is off or another one: the seal is parked, never
  /// dropped); `ownClientId` the own Google client id a plain grant in a
  /// workspace must carry: the workspace's own client while it is on its own
  /// apps, the server's while it inherits a server on its own apps, null
  /// otherwise (it may throw [OwnAppIncomplete] for a half-configured
  /// server client).
  ServerGoogleTokenManager({
    required this._store,
    required this._refresh,
    required this._installId,
    required this._ownClientId,
    this._onInvalidGrant,
  });

  final FileGoogleCredentialsStore _store;
  final GoogleTokenRefresh _refresh;
  final Future<String?> Function(String connectOrigin, String workspaceId)
  _installId;
  final Future<String?> Function(String workspaceId) _ownClientId;
  final Future<void> Function(String accountId)? _onInvalidGrant;

  final Map<String, ProviderToken> _live = {};
  final SingleFlight<String, ProviderToken?> _inFlight = SingleFlight();

  /// Keeps a freshly minted [token] for [accountId] in memory (a sealed
  /// sign-in carries its first access token only here).
  void remember(String accountId, ProviderToken token) {
    if (token.accessToken.isNotEmpty) {
      _live[accountId] = token;
    }
  }

  /// Drops [accountId]'s in-memory token.
  void forget(String accountId) => _live.remove(accountId);

  /// A valid access token for [accountId], refreshing first if expired. Null
  /// when the account has no usable credential or the refresh could not run
  /// right now.
  Future<String?> accessTokenFor(String accountId) async {
    final stored = await _usable(accountId);
    if (stored == null) {
      return null;
    }
    final live = _live[accountId];
    if (live != null && !live.isExpired) {
      return live.accessToken;
    }
    if (!stored.isSealed && !stored.isExpired) {
      return stored.accessToken;
    }
    return (await _refreshOnce(accountId))?.accessToken;
  }

  /// Checks every credential in [workspaceId] against the app it uses now,
  /// dropping (and flagging for reconnect) the ones another app issued. Runs
  /// when the workspace changes its Google client or its Connect choice.
  Future<void> revalidateWorkspace(String workspaceId) async {
    for (final accountId in await _store.accountIdsIn(workspaceId)) {
      await _usable(accountId);
    }
  }

  /// Forces a refresh (after a 401) and returns the new access token.
  Future<String?> forceRefresh(String accountId) async {
    _live.remove(accountId);
    return (await _refreshOnce(accountId, force: true))?.accessToken;
  }

  Future<ProviderToken?> _refreshOnce(String accountId, {bool force = false}) =>
      _inFlight.run(accountId, () => _doRefresh(accountId, force: force));

  /// [force] (after a 401) reuses only a renewal another flight just made,
  /// never the stored access token Google refused.
  Future<ProviderToken?> _doRefresh(
    String accountId, {
    required bool force,
  }) async {
    // Re-read inside the flight: a renewal that settled just before this one
    // started is reused rather than refreshed again.
    final current = await _usable(accountId);
    final workspaceId = _workspaceIdFromAccountId(accountId);
    if (current == null || workspaceId == null) {
      return null;
    }
    final live = _live[accountId];
    if (live != null && !live.isExpired) {
      return live;
    }
    if (!force && !current.isSealed && !current.isExpired) {
      return current;
    }
    RefreshOutcome outcome;
    try {
      outcome = await _refresh(current, workspaceId);
    } on Object catch (e) {
      CcHostLog.warning(
        'calendar: refresh unavailable for $accountId (${errorKindOf(e)})',
      );
      outcome = const RefreshUnavailable();
    }
    // Compare-and-set: a disconnect or a new sign-in that landed while the
    // refresh was in the air wins over the older grant's outcome.
    final nowRaw = await _store.raw(accountId);
    final now = nowRaw == null ? null : ProviderToken.tryParse(nowRaw);
    if (now == null || !_sameGrant(now, current)) {
      return null;
    }
    switch (outcome) {
      case Refreshed(:final token):
        await _store.save(accountId, token);
        remember(accountId, token);
        return token;
      case RefreshRejected():
        CcHostLog.warning(
          'calendar: Google refused the grant for $accountId; it must be '
          'connected again',
        );
        await _drop(accountId);
        return null;
      case RefreshUnavailable():
        // Keep the credential; the next call tries again. Nobody is signed out
        // by an outage, and no expired token goes out meanwhile.
        _live.remove(accountId);
        return null;
    }
  }

  /// The stored credential when it is still this server's to use; otherwise
  /// clears it (and flags the account) and returns null.
  Future<ProviderToken?> _usable(String accountId) async {
    final raw = await _store.raw(accountId);
    if (raw == null || raw.isEmpty) {
      _live.remove(accountId);
      return null;
    }
    final token = ProviderToken.tryParse(raw);
    final workspaceId = _workspaceIdFromAccountId(accountId);
    if (token == null || workspaceId == null) {
      // Unparseable, or keyed to no workspace: nothing here can renew it.
      await _drop(accountId);
      return null;
    }
    if (token.isSealed) {
      // A seal is bound to the install id it was minted for. A restored
      // backup or a rotated key can never open it; the workspace's Connect
      // being off or another one only makes it unusable for now.
      switch (sealStandingOf(
        sealInstallId: token.sealInstallId,
        currentInstallId: await _installId(token.connectOrigin, workspaceId),
      )) {
        case SealStanding.parked:
          _live.remove(accountId);
          return null;
        case SealStanding.dead:
          await _drop(accountId);
          return null;
        case SealStanding.usable:
          return token;
      }
    }
    final String? ownClientId;
    try {
      ownClientId = await _ownClientId(workspaceId);
    } on OwnAppIncomplete {
      // A half-edited own app is a setup error the operator is fixing, not a
      // reason to sign anyone out.
      return token;
    }
    if (ownClientId == null || ownClientId != token.appId) {
      // The own app that issued this grant is gone or was replaced.
      await _drop(accountId);
      return null;
    }
    return token;
  }

  static bool _sameGrant(ProviderToken a, ProviderToken b) => a.isSealed
      ? a.seal == b.seal
      : a.refreshToken == b.refreshToken && a.accessToken == b.accessToken;

  Future<void> _drop(String accountId) async {
    _live.remove(accountId);
    await _store.clear(accountId);
    try {
      await _onInvalidGrant?.call(accountId);
    } on Object catch (e, st) {
      CcHostLog.error('calendar: onInvalidGrant handler failed', e, st);
    }
  }
}

/// Builds a [GoogleCalendarApiClient] whose [RhttpClient] injects (and
/// refreshes) the per-account Bearer token from [tokens]. Each Calendar
/// request tags itself with the account id via [googleAccountIdExtraKey].
GoogleCalendarApiClient buildServerGoogleCalendarApiClient(
  ServerGoogleTokenManager tokens,
) {
  // The client's own URLs are absolute (they embed `googleCalendarApiBaseUrl`),
  // so no baseUrl is set here — rhttp concatenates baseUrl + url rather than
  // detecting absolute URLs.
  final httpClient = createHttpClient(
    interceptors: [_ServerGoogleAuthInterceptor(tokens)],
  );
  return GoogleCalendarApiClient(httpClient);
}

/// Attaches the per-account Bearer (refreshing proactively when expiring) and
/// retries once on a 401. Refreshes are single-flighted inside the
/// [ServerGoogleTokenManager].
class _ServerGoogleAuthInterceptor extends Interceptor {
  _ServerGoogleAuthInterceptor(this._tokens);

  final ServerGoogleTokenManager _tokens;

  static HttpRequest _withAuthorization(HttpRequest request, String token) =>
      request.copyWith(
        headers: (request.headers ?? HttpHeaders.empty).copyWithRaw(
          name: 'Authorization',
          value: 'Bearer $token',
        ),
      );

  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    final accountId = request.additionalData[googleAccountIdExtraKey];
    if (accountId is String && accountId.isNotEmpty) {
      try {
        final token = await _tokens.accessTokenFor(accountId);
        if (token != null && token.isNotEmpty) {
          return Interceptor.next(_withAuthorization(request, token));
        }
      } on Object catch (e) {
        CcHostLog.warning(
          'calendar: could not attach Google token: ${errorKindOf(e)}',
        );
      }
    }
    return Interceptor.next(request);
  }

  @override
  Future<InterceptorResult<RhttpException>> onError(
    RhttpException exception,
  ) async {
    final status = exception is RhttpStatusCodeException
        ? exception.statusCode
        : null;
    final request = exception.request;
    final accountId = request.additionalData[googleAccountIdExtraKey];
    final alreadyRetried = request.additionalData['googleAuthRetried'] == true;
    if (status == 401 &&
        accountId is String &&
        accountId.isNotEmpty &&
        !alreadyRetried) {
      final token = await _tokens.forceRefresh(accountId);
      if (token != null && token.isNotEmpty) {
        // Marked on the request BEFORE the copy so the retried attempt (which
        // runs the full interceptor chain again) carries the marker and cannot
        // loop on a second 401.
        request.additionalData['googleAuthRetried'] = true;
        try {
          final response = await _withAuthorization(request, token).send();
          return Interceptor.resolve(response);
        } on RhttpException catch (retryError) {
          return Interceptor.next(retryError);
        }
      }
    }
    return Interceptor.next(exception);
  }
}

/// Periodically syncs every workspace's connected Google Calendar into the
/// server's database — the server-owned counterpart to the desktop's in-process
/// sync. Thin clients never sync; they just read the events this writes via the
/// `calendar.watch*` RPC surface.
///
/// Reuses the cc_infra [CalendarSyncService] (which encodes the fetch + upsert +
/// deletion-reconcile), driving it once per workspace per tick by pointing its
/// `activeWorkspaceId` at the workspace currently being swept.
class ServerCalendarSync {
  /// Creates a [ServerCalendarSync].
  ServerCalendarSync({
    required this._calendarRepository,
    required this._apiClient,
    required this._workspaceRepository,
    this._interval = const Duration(minutes: 2),
  });

  final CalendarRepository _calendarRepository;
  final GoogleCalendarApiClient _apiClient;
  final WorkspaceRepository _workspaceRepository;
  final Duration _interval;

  /// The workspace the current sweep is on; read by [_sync]'s `activeWorkspaceId`.
  /// A sweep visits workspaces strictly sequentially, so a single field is safe.
  String? _currentWorkspaceId;

  /// One reused [CalendarSyncService] whose target workspace is repointed before
  /// each per-workspace `refreshNow`. Built lazily so the closure can capture
  /// the instance's [_currentWorkspaceId].
  late final CalendarSyncService _sync = CalendarSyncService(
    apiClient: _apiClient,
    repository: _calendarRepository,
    activeWorkspaceId: () => _currentWorkspaceId,
  );

  Timer? _timer;
  bool _ticking = false;

  /// Starts the periodic sweep (runs an immediate sweep too).
  void start() {
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(_interval, (_) => unawaited(_tick()));
    unawaited(_tick());
  }

  Future<void> _tick() async {
    if (_ticking) {
      return; // a sweep is already running; skip this tick
    }
    _ticking = true;
    try {
      final workspaces = await _workspaceRepository.watchAll().first;
      for (final w in workspaces) {
        _currentWorkspaceId = w.id;
        try {
          await _sync.refreshNow();
        } on Object catch (e) {
          CcHostLog.warning('calendar: sync failed for workspace ${w.id}: $e');
        }
      }
    } on Object catch (e) {
      CcHostLog.warning('calendar: sync sweep failed: $e');
    } finally {
      _currentWorkspaceId = null;
      _ticking = false;
    }
  }

  /// Syncs a single [workspaceId] now — e.g. right after a sign-in, so the
  /// new account's events appear without waiting for the next sweep. Skips if a
  /// full sweep is already running (which will include it).
  Future<void> syncWorkspace(String workspaceId) async {
    if (_ticking) {
      return;
    }
    _ticking = true;
    _currentWorkspaceId = workspaceId;
    try {
      await _sync.refreshNow();
    } on Object catch (e) {
      CcHostLog.warning('calendar: sync failed for workspace $workspaceId: $e');
    } finally {
      _currentWorkspaceId = null;
      _ticking = false;
    }
  }

  /// On-demand range load for [workspaceId] (the client navigated outside the
  /// rolling sync window). Delegates to the underlying service, which is keyed
  /// by the explicit workspace id and dedups in-flight/covered ranges itself, so
  /// it is safe to run concurrently with a sweep.
  Future<void> ensureRangeLoaded(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) => _sync.ensureRangeLoaded(workspaceId, from, to);

  /// Stops the sweep and disposes the underlying sync service.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _sync.dispose();
  }
}

/// Connects and disconnects a workspace's Google Calendar accounts.
///
/// Connecting is the tail of a browser sign-in (`oauth.begin {lane:
/// google}`, see `GoogleSignInLane`): this stores the credential and upserts
/// the `CalendarAccount` row the sync and the `calendar.*` reads use.
class CalendarAccountService {
  /// Creates a [CalendarAccountService]. [_onConnected] (optional) fires after
  /// a successful connect so the caller can kick an immediate sync.
  CalendarAccountService({
    required this._store,
    required this._tokens,
    required this._calendarRepository,
    this._onConnected,
  });

  final FileGoogleCredentialsStore _store;
  final ServerGoogleTokenManager _tokens;
  final CalendarRepository _calendarRepository;
  final Future<void> Function(String workspaceId)? _onConnected;

  /// Stores [token] as [userId]'s Google account [email] in [workspaceId] and
  /// returns the account id. Reconnecting the same account replaces its
  /// credential and clears a "needs reauth" flag.
  Future<String> connect({
    required String workspaceId,
    required String userId,
    required String email,
    required ProviderToken token,
  }) async {
    if (workspaceId.isEmpty || userId.isEmpty || email.isEmpty) {
      throw const AuthException(
        'A calendar account needs a workspace, a member and an email.',
      );
    }
    final accountId = serverGoogleAccountId(workspaceId, email, userId: userId);
    await _store.save(accountId, token);
    _tokens.remember(accountId, token);
    await _calendarRepository.upsertAccount(
      CalendarAccount(
        id: accountId,
        workspaceId: workspaceId,
        userId: userId,
        providerId: 'google',
        accountEmail: email,
      ),
    );
    // Kick an immediate sync (don't block the sign-in on the network
    // round-trip) so the new account's events appear right away.
    final onConnected = _onConnected;
    if (onConnected != null) {
      unawaited(onConnected(workspaceId));
    }
    return accountId;
  }

  /// The members holding a calendar credential for the Google account
  /// [googleSub] (its immutable `sub`), in any workspace.
  Future<Set<String>> holdersOf(String googleSub) async {
    final holders = <String>{};
    for (final accountId in await _store.allAccountIds()) {
      final token = await _store.load(accountId);
      final userId = _userIdFromAccountId(accountId);
      if (token?.accountId == googleSub && userId.isNotEmpty) {
        holders.add(userId);
      }
    }
    return holders;
  }

  /// Disconnects [accountId] from [workspaceId]: deletes the account row (which
  /// cascades its events) and clears the stored credential.
  Future<void> disconnect({
    required String workspaceId,
    required String accountId,
    String? userId,
  }) async {
    // Isolation: the account id embeds its workspace.
    if (_workspaceIdFromAccountId(accountId) != workspaceId) {
      throw const WorkspaceMismatchException(
        'That calendar account belongs to a different workspace.',
      );
    }
    if (userId != null && userId.isNotEmpty) {
      final accounts = await _calendarRepository.getAccounts(workspaceId);
      for (final account in accounts) {
        if (account.id == accountId &&
            account.userId.isNotEmpty &&
            account.userId != userId) {
          throw const AuthException(
            'That calendar account belongs to a different user.',
          );
        }
      }
    }
    await _calendarRepository.deleteAccount(workspaceId, accountId);
    await _store.clear(accountId);
    _tokens.forget(accountId);
  }

  /// Every stored grant the Connect at [connectOrigin] sealed, with the
  /// workspace it is held in.
  Future<List<SealRequest>> connectSeals(String connectOrigin) async {
    final seals = <SealRequest>[];
    for (final accountId in await _store.allAccountIds()) {
      final workspaceId = _workspaceIdFromAccountId(accountId);
      final token = await _store.load(accountId);
      if (workspaceId != null &&
          token != null &&
          token.isSealed &&
          token.connectOrigin == connectOrigin) {
        seals.add(SealRequest(seal: token.seal, workspaceId: workspaceId));
      }
    }
    return seals;
  }

  /// Disconnects the calendar accounts of a person who left: [userId]'s in
  /// [workspaceId], [userId]'s in every workspace when [workspaceId] is null,
  /// or everyone's in [workspaceId] when [userId] is null. Deletes each
  /// account row (and with it its events, so nobody is shown them) and
  /// credential, and returns the credentials so the caller can revoke them.
  Future<List<ProviderToken>> disconnectWhere({
    String? userId,
    String? workspaceId,
  }) async {
    assert(userId != null || workspaceId != null, 'disconnect whom?');
    final accountIds = <String>{
      ...workspaceId == null
          ? await _store.allAccountIds()
          : await _store.accountIdsIn(workspaceId),
      // An account flagged for reconnect has a row and no credential.
      if (workspaceId != null)
        for (final account in await _calendarRepository.getAccounts(
          workspaceId,
        ))
          if (account.providerId == 'google') account.id,
    };
    final removed = <ProviderToken>[];
    for (final accountId in accountIds) {
      final workspace = _workspaceIdFromAccountId(accountId);
      if (workspace == null ||
          (userId != null && _userIdFromAccountId(accountId) != userId)) {
        continue;
      }
      final token = await _store.load(accountId);
      await _calendarRepository.deleteAccount(workspace, accountId);
      await _store.clear(accountId);
      _tokens.forget(accountId);
      if (token != null) {
        removed.add(token);
      }
    }
    return removed;
  }

  /// Every (workspace, member) holding a calendar account or credential, in
  /// the [workspaceIds] given or in any workspace by credential.
  Future<Set<({String workspaceId, String userId})>> holders(
    Iterable<String> workspaceIds,
  ) async => {
    for (final accountId in await _store.allAccountIds())
      if (_workspaceIdFromAccountId(accountId) case final workspaceId?)
        (workspaceId: workspaceId, userId: _userIdFromAccountId(accountId)),
    for (final workspaceId in workspaceIds)
      for (final account in await _calendarRepository.getAccounts(workspaceId))
        (workspaceId: workspaceId, userId: account.userId),
  };
}

/// The person's own Google Calendar writes: answering an invitation,
/// creating an event and deleting one.
///
/// Every write runs on the host's OAuth token for one connected account (the
/// thin client holds none) and is refused unless that account is the
/// caller's own sign-in in this workspace: a member never answers, books or
/// cancels on a colleague's calendar. Each write then updates the local copy
/// so the change shows before the next sync.
class ServerCalendarWrites {
  /// Creates a [ServerCalendarWrites].
  ServerCalendarWrites({
    required CalendarRepository calendarRepository,
    required this._apiClient,
    Uuid? uuid,
    DateTime Function()? clock,
  }) : _repository = calendarRepository,
       _uuid = uuid ?? const Uuid(),
       _clock = clock ?? DateTime.now;

  final CalendarRepository _repository;
  final GoogleCalendarApiClient _apiClient;
  final Uuid _uuid;
  final DateTime Function() _clock;

  /// The answers Google accepts for `responseStatus`.
  static const Set<String> responses = {'accepted', 'declined', 'tentative'};

  /// Sends [responseStatus] (`accepted` / `declined` / `tentative`) for the
  /// local event [eventId] in [workspaceId].
  Future<void> respond({
    required String workspaceId,
    required String userId,
    required String eventId,
    required String responseStatus,
  }) async {
    if (!responses.contains(responseStatus)) {
      throw ValidationException('Unknown RSVP answer: $responseStatus');
    }
    final event = await _ownEvent(workspaceId, userId, eventId);
    // PATCH replaces the attendees array, so send the full list with only the
    // self attendee's status changed.
    final attendees = <Map<String, dynamic>>[
      for (final a in event.attendees)
        <String, dynamic>{
          'email': a.email,
          if (a.displayName != null) 'displayName': a.displayName,
          'responseStatus': a.self
              ? responseStatus
              : (a.responseStatus ?? 'needsAction'),
        },
    ];
    await _apiClient.patchEventResponse(
      accountId: event.accountId,
      calendarId: event.calendarId,
      eventId: event.externalEventId,
      attendees: attendees,
    );
    final updated = <CalendarAttendee>[
      for (final a in event.attendees)
        if (a.self)
          CalendarAttendee(
            email: a.email,
            displayName: a.displayName,
            responseStatus: responseStatus,
            self: true,
            organizer: a.organizer,
          )
        else
          a,
    ];
    await _repository.upsertEvents([event.copyWith(attendees: updated)]);
  }

  /// Creates [draft] on its calendar and returns the stored event's local id.
  ///
  /// The calendar must be one the account may write to. Guests are emailed
  /// their invitation by Google.
  Future<String> create({
    required String workspaceId,
    required String userId,
    required CalendarEventDraft draft,
  }) async {
    await _ownAccount(workspaceId, userId, draft.accountId);
    await _writableCalendar(workspaceId, draft.accountId, draft.calendarId);
    final created = await _apiClient.insertEvent(
      accountId: draft.accountId,
      calendarId: draft.calendarId,
      event: googleEventResource(draft, requestId: _uuid.v4()),
      withConference: draft.addConference,
    );
    if (created.id.isEmpty) {
      throw const ValidationException('Google did not return the new event.');
    }
    await _repository.upsertEvents([
      calendarEventFromGoogle(
        created,
        id: _uuid.v4(),
        workspaceId: workspaceId,
        accountId: draft.accountId,
        calendarId: draft.calendarId,
        now: _clock(),
      ),
    ]);
    // The upsert keeps the id of a row a concurrent sync stored first, so
    // read the id back rather than trusting the one just minted.
    final stored = await _repository
        .watchEventsInRange(
          workspaceId,
          created.start.resolved,
          created.end.resolved.add(const Duration(seconds: 1)),
        )
        .first;
    for (final event in stored) {
      if (event.accountId == draft.accountId &&
          event.externalEventId == created.id) {
        return event.id;
      }
    }
    throw const NotFoundException('The new calendar event was not stored.');
  }

  /// Moves the local event to [move]'s times on Google, then stores what
  /// Google kept under the same local id. Only an event of the caller's own
  /// with no guests, or one they organize, may move
  /// ([CalendarEventReschedule.allowedFor]); guests are told of the new time.
  Future<void> move({
    required String workspaceId,
    required String userId,
    required CalendarEventReschedule move,
  }) async {
    final event = await _ownEvent(workspaceId, userId, move.eventId);
    await _writableCalendar(workspaceId, event.accountId, event.calendarId);
    if (!CalendarEventReschedule.allowedFor(event)) {
      throw const ValidationException(
        'Only the organizer can move an event with guests.',
      );
    }
    Map<String, String> when(DateTime value) => move.isAllDay
        ? {'date': CalendarEventDraft.dateOnly(value)}
        : {'dateTime': value.toUtc().toIso8601String()};
    final moved = await _apiClient.patchEventTimes(
      accountId: event.accountId,
      calendarId: event.calendarId,
      eventId: event.externalEventId,
      start: when(move.start),
      end: when(move.end),
    );
    await _repository.upsertEvents([
      calendarEventFromGoogle(
        moved,
        id: event.id,
        workspaceId: workspaceId,
        accountId: event.accountId,
        calendarId: event.calendarId,
        now: _clock(),
      ),
    ]);
  }

  /// Deletes the local event [eventId] on Google, then locally. An
  /// organizer's delete cancels it for every guest; a guest's delete takes it
  /// off their own calendar. A recurring event loses only this occurrence.
  Future<void> delete({
    required String workspaceId,
    required String userId,
    required String eventId,
  }) async {
    final event = await _ownEvent(workspaceId, userId, eventId);
    await _writableCalendar(workspaceId, event.accountId, event.calendarId);
    await _apiClient.deleteEvent(
      accountId: event.accountId,
      calendarId: event.calendarId,
      eventId: event.externalEventId,
    );
    await _repository.deleteEventsByExternalIds(
      workspaceId: workspaceId,
      accountId: event.accountId,
      calendarId: event.calendarId,
      externalIds: {event.externalEventId},
    );
  }

  /// The local event [eventId], refused unless its account is [userId]'s.
  /// The lookup is workspace-scoped, so a foreign id is simply not found.
  Future<CalendarEvent> _ownEvent(
    String workspaceId,
    String userId,
    String eventId,
  ) async {
    final event = await _repository.watchEventById(workspaceId, eventId).first;
    if (event == null) {
      throw const NotFoundException('Calendar event not found');
    }
    await _ownAccount(workspaceId, userId, event.accountId);
    return event;
  }

  /// Refuses [accountId] unless it is [userId]'s connected account in
  /// [workspaceId].
  Future<void> _ownAccount(
    String workspaceId,
    String userId,
    String accountId,
  ) async {
    if (_workspaceIdFromAccountId(accountId) != workspaceId) {
      throw const WorkspaceMismatchException(
        'That calendar account belongs to a different workspace.',
      );
    }
    final accounts = await _repository.getAccounts(workspaceId);
    for (final account in accounts) {
      if (account.id != accountId) {
        continue;
      }
      if (userId.isEmpty || account.userId != userId) {
        throw const AuthException(
          'That calendar account belongs to a different user.',
        );
      }
      return;
    }
    throw const NotFoundException('Calendar account not found');
  }

  /// Refuses a calendar the account may only read (a subscribed or shared
  /// calendar), before Google is asked.
  Future<void> _writableCalendar(
    String workspaceId,
    String accountId,
    String calendarId,
  ) async {
    final sources = await _repository
        .watchSources(workspaceId, accountId)
        .first;
    for (final source in sources) {
      if (source.id == calendarId) {
        if (source.writable) {
          return;
        }
        break;
      }
    }
    throw const ValidationException(
      'That calendar does not accept new or deleted events.',
    );
  }
}

/// The Google event resource for [draft]. [requestId] makes the Meet request
/// idempotent when [CalendarEventDraft.addConference] asks for one.
Map<String, dynamic> googleEventResource(
  CalendarEventDraft draft, {
  required String requestId,
}) {
  Map<String, String> when(DateTime value) => draft.isAllDay
      ? {'date': CalendarEventDraft.dateOnly(value)}
      : {'dateTime': value.toUtc().toIso8601String()};
  return {
    'summary': draft.title,
    'start': when(draft.start),
    'end': when(draft.end),
    'location': ?draft.location,
    'description': ?draft.description,
    if (draft.attendeeEmails.isNotEmpty)
      'attendees': [
        for (final email in draft.attendeeEmails) {'email': email},
      ],
    if (draft.addConference)
      'conferenceData': {
        'createRequest': {
          'requestId': requestId,
          'conferenceSolutionKey': {'type': 'hangoutsMeet'},
        },
      },
  };
}

/// The server-side calendar wiring: the periodic [sync] sweep, the
/// [accounts] connect/disconnect service and the person's [writes], sharing ONE
/// token manager (so a freshly connected account's in-memory access token is
/// what the sync uses).
class ServerCalendar {
  /// Creates a [ServerCalendar].
  ServerCalendar({
    required this.tokens,
    required this.sync,
    required this.accounts,
    required this.writes,
  });

  /// The shared token manager.
  final ServerGoogleTokenManager tokens;

  /// The periodic per-workspace sync sweep.
  final ServerCalendarSync sync;

  /// Account connect (from the Google sign-in lane) and disconnect (the
  /// `calendar.disconnect` op).
  final CalendarAccountService accounts;

  /// RSVP, create and delete (back the `calendar.rsvp`, `calendar.createEvent`
  /// and `calendar.deleteEvent` ops).
  final ServerCalendarWrites writes;

  /// Starts the sync sweep.
  void start() => sync.start();
}

/// Builds the server-side calendar over the shared [secrets] store.
///
/// Refreshes go through [signIn] (own app against Google, or the Connect that
/// sealed the grant); [connect] supplies each workspace's route and the
/// install id a seal must match, [apps] the server's own Google client and
/// [workspaceApps] a workspace's own. A refused grant flags the account for
/// reconnect. The sync runs unconditionally (it no-ops until an account is
/// connected).
ServerCalendar buildServerCalendar({
  required CalendarRepository calendarRepository,
  required WorkspaceRepository workspaceRepository,
  required DomainEventBus eventBus,
  required FileSecretsStore secrets,
  required ProviderSignInService signIn,
  required ConnectClient connect,
  required ProviderAppSettings apps,
  required WorkspaceProviderAppSettings workspaceApps,
}) {
  final store = FileGoogleCredentialsStore(secrets);
  final tokens = ServerGoogleTokenManager(
    store: store,
    refresh: (token, workspaceId) => signIn.refresh(
      ConnectOAuthLane.google,
      token,
      slot: workspaceId,
      workspaceId: workspaceId,
    ),
    installId: (origin, workspaceId) =>
        connect.installIdFor(origin, workspaceId: workspaceId),
    ownClientId: (workspaceId) async {
      final route = await connect.routeFor(workspaceId);
      if (route.workspaceOwnApps) {
        final id = await workspaceApps.ownClientId(
          workspaceId,
          WorkspaceAppProvider.google,
        );
        return id.isEmpty ? null : id;
      }
      return route.serverOwnApps
          ? (await apps.oauthCredentials(ProviderApp.google))?.clientId
          : null;
    },
    onInvalidGrant: (accountId) async {
      final workspaceId = _workspaceIdFromAccountId(accountId);
      if (workspaceId == null) {
        return;
      }
      try {
        final now = DateTime.now();
        // Publish once per expiry, not on every sweep that finds it.
        if (await calendarRepository.markNeedsReauth(
          workspaceId,
          accountId,
          now,
        )) {
          eventBus.publish(
            CalendarAuthExpired(
              workspaceId: workspaceId,
              accountEmail: _emailFromAccountId(accountId),
              occurredAt: now,
            ),
          );
        }
      } on Object catch (e) {
        CcHostLog.warning(
          'calendar: could not flag $accountId for reauth: '
          '${errorKindOf(e)}',
        );
      }
    },
  );
  final apiClient = buildServerGoogleCalendarApiClient(tokens);
  final sync = ServerCalendarSync(
    calendarRepository: calendarRepository,
    apiClient: apiClient,
    workspaceRepository: workspaceRepository,
  );
  return ServerCalendar(
    tokens: tokens,
    sync: sync,
    accounts: CalendarAccountService(
      store: store,
      tokens: tokens,
      calendarRepository: calendarRepository,
      // After a sign-in, sync that workspace immediately.
      onConnected: sync.syncWorkspace,
    ),
    writes: ServerCalendarWrites(
      calendarRepository: calendarRepository,
      apiClient: apiClient,
    ),
  );
}
