import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/src/calendar/calendar_sync_service.dart';
import 'package:cc_infra/src/calendar/google_device_auth_client.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/google_calendar_api_client.dart';
import 'package:cc_infra/src/network/network_constants.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// Builds the deterministic account id for a workspace + Google account email.
/// Mirrors the client's `googleAccountId` so a row connected here is keyed the
/// same way the rest of the system expects.
String serverGoogleAccountId(String workspaceId, String email) =>
    'google:$workspaceId:$email';

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

/// File-backed Google OAuth credential store for the headless server.
///
/// Stores one JSON map (`accountId` → credential blob) under the server's data
/// dir — the pure-Dart counterpart to the desktop's OS keychain. It sits beside
/// the SQLite database and inherits the same host-filesystem trust boundary;
/// writes are atomic (temp file + rename). This is the ONLY place the long-lived
/// refresh token lives — never on a client device.
class FileGoogleCredentialsStore {
  /// Creates a store rooted at [dataDir] (`google_credentials.json`).
  FileGoogleCredentialsStore({required String dataDir})
    : _file = File(p.join(dataDir, 'google_credentials.json'));

  final File _file;
  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _load() async => _cache ??= await _readFromDisk();

  Future<Map<String, dynamic>> _readFromDisk() async {
    if (!_file.existsSync()) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(await _file.readAsString());
      return decoded is Map ? decoded.cast<String, dynamic>() : {};
    } on Object {
      return <String, dynamic>{};
    }
  }

  Future<void> _flush() async {
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(_cache ?? const {}));
    await tmp.rename(_file.path);
    await _restrictPerms(_file);
  }

  /// Tightens the long-lived refresh-token file to owner-only (0600) where
  /// `chmod` exists (macOS/Linux; Windows ACLs out of scope). `writeAsString`
  /// honors the umask (often 0644), so enforce 0600 explicitly. Best-effort.
  Future<void> _restrictPerms(File f) async {
    if (Platform.isWindows) {
      return;
    }
    try {
      await Process.run('chmod', ['600', f.path]);
    } catch (_) {
      // Best-effort — credentials are still written; the host umask applies.
    }
  }

  /// Loads the credentials for [accountId], or null when none are stored.
  Future<GoogleServerCredentials?> load(String accountId) async {
    var map = await _load();
    if (!map.containsKey(accountId)) {
      // The `calendar connect` CLI writes this file from a SEPARATE process, so
      // a long-running server that cached it (often empty) at boot would miss a
      // freshly-connected account — its DB row is visible (SQLite is
      // cross-process) but its token would not be. Re-read from disk on a miss
      // so the next sync sweep picks it up without a server restart.
      map = _cache = await _readFromDisk();
    }
    final raw = map[accountId];
    if (raw is! Map) {
      return null;
    }
    return GoogleServerCredentials.fromJson(raw.cast<String, dynamic>());
  }

  /// Persists [creds] for [accountId].
  Future<void> save(String accountId, GoogleServerCredentials creds) async {
    (await _load())[accountId] = creds.toJson();
    await _flush();
  }

  /// Removes [accountId]'s credentials (disconnect).
  Future<void> clear(String accountId) async {
    (await _load()).remove(accountId);
    await _flush();
  }
}

/// Loads + refreshes the server's Google access tokens, single-flighting the
/// refresh per account so concurrent Calendar requests share one network call.
/// On a terminal `invalid_grant` it invokes the `onInvalidGrant` callback
/// (wired to flag the account for re-connect) — transient failures are simply
/// retried next tick.
class ServerGoogleTokenManager {
  /// Creates a [ServerGoogleTokenManager].
  ServerGoogleTokenManager({
    required FileGoogleCredentialsStore store,
    Future<void> Function(String accountId)? onInvalidGrant,
  }) : _store = store,
       _onInvalidGrant = onInvalidGrant;

  final FileGoogleCredentialsStore _store;
  final Future<void> Function(String accountId)? _onInvalidGrant;

  final Map<String, Future<GoogleServerCredentials?>> _inFlight = {};

  /// A valid access token for [accountId], refreshing first if expired. Null
  /// when the account has no usable credentials.
  Future<String?> accessTokenFor(String accountId) async {
    var creds = await _store.load(accountId);
    if (creds == null) {
      return null;
    }
    if (creds.isExpired()) {
      creds = await _refresh(accountId) ?? creds;
    }
    return creds.accessToken.isEmpty ? null : creds.accessToken;
  }

  /// Forces a refresh (used after a 401) and returns the new access token.
  Future<String?> forceRefresh(String accountId) async =>
      (await _refresh(accountId))?.accessToken;

  Future<GoogleServerCredentials?> _refresh(String accountId) {
    // Block body (not an arrow): `Map.remove` returns the stored future, so an
    // arrow whenComplete would make the refresh await itself — a deadlock.
    return _inFlight[accountId] ??= _doRefresh(accountId).whenComplete(() {
      _inFlight.remove(accountId);
    });
  }

  Future<GoogleServerCredentials?> _doRefresh(String accountId) async {
    final current = await _store.load(accountId);
    if (current == null || current.refreshToken.isEmpty) {
      return null;
    }
    if (current.clientId.isEmpty) {
      CcHostLog.warning(
        'calendar: $accountId has no stored OAuth client id; cannot refresh '
        '(reconnect the account)',
      );
      return null;
    }
    try {
      // Refresh with the client the account was connected under (a workspace
      // may hold accounts connected via different Google projects).
      final auth = GoogleDeviceAuthClient(
        clientId: current.clientId,
        clientSecret: current.clientSecret,
      );
      final refreshed = await auth.refresh(current);
      await _store.save(accountId, refreshed);
      return refreshed;
    } on GoogleOAuthException catch (e) {
      CcHostLog.warning('calendar: token refresh failed for $accountId: ${e.message}');
      if (e.kind == GoogleOAuthFailureKind.invalidGrant) {
        try {
          await _onInvalidGrant?.call(accountId);
        } on Object catch (e, st) {
          CcHostLog.error('calendar: onInvalidGrant handler failed', e, st);
        }
      }
      return null;
    }
  }
}

/// Builds a [GoogleCalendarApiClient] whose [Dio] injects (and refreshes) the
/// per-account Bearer token from [tokens]. Each Calendar request tags itself
/// with the account id via [googleAccountIdExtraKey].
GoogleCalendarApiClient buildServerGoogleCalendarApiClient(
  ServerGoogleTokenManager tokens,
) {
  final dio = createDio(baseUrl: googleCalendarApiBaseUrl);
  dio.interceptors.add(_ServerGoogleAuthInterceptor(tokens, dio));
  return GoogleCalendarApiClient(dio);
}

/// Attaches the per-account Bearer (refreshing proactively when expiring) and
/// retries once on a 401. Refreshes are single-flighted inside the
/// [ServerGoogleTokenManager].
class _ServerGoogleAuthInterceptor extends QueuedInterceptor {
  _ServerGoogleAuthInterceptor(this._tokens, this._dio);

  final ServerGoogleTokenManager _tokens;
  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accountId = options.extra[googleAccountIdExtraKey] as String?;
    if (accountId != null) {
      try {
        final token = await _tokens.accessTokenFor(accountId);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } on Object catch (e) {
        CcHostLog.warning('calendar: could not attach Google token: $e');
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final accountId =
        err.requestOptions.extra[googleAccountIdExtraKey] as String?;
    final alreadyRetried =
        err.requestOptions.extra['googleAuthRetried'] == true;
    if (status == 401 && accountId != null && !alreadyRetried) {
      final token = await _tokens.forceRefresh(accountId);
      if (token != null && token.isNotEmpty) {
        final request = err.requestOptions;
        request.extra['googleAuthRetried'] = true;
        request.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _dio.fetch<dynamic>(request);
          handler.resolve(response);
          return;
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        }
      }
    }
    handler.next(err);
  }
}

/// Periodically syncs every workspace's connected Google Calendar into the
/// server's database — the server-owned counterpart to the desktop's in-process
/// sync. Thin clients never sync; they just read the events this writes via the
/// `calendar.watch*` RPC surface.
///
/// Reuses the cc_infra [CalendarSyncService] (which encodes the fetch + upsert +
/// deletion-reconcile + event publish), driving it once per workspace per tick
/// by pointing its `activeWorkspaceId` at the workspace currently being swept.
class ServerCalendarSync {
  /// Creates a [ServerCalendarSync].
  ServerCalendarSync({
    required CalendarRepository calendarRepository,
    required GoogleCalendarApiClient apiClient,
    required WorkspaceRepository workspaceRepository,
    required DomainEventBus eventBus,
    Duration interval = const Duration(minutes: 7),
  }) : _calendarRepository = calendarRepository,
       _apiClient = apiClient,
       _workspaceRepository = workspaceRepository,
       _eventBus = eventBus,
       _interval = interval;

  final CalendarRepository _calendarRepository;
  final GoogleCalendarApiClient _apiClient;
  final WorkspaceRepository _workspaceRepository;
  final DomainEventBus _eventBus;
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
    eventBus: _eventBus,
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

  /// Syncs a single [workspaceId] now — e.g. right after a GUI connect, so the
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

/// Runs the headless **device-code** OAuth flow to connect a Google account to
/// [workspaceId], storing the refresh token server-side and upserting the
/// `CalendarAccount` row the sync + RPC reads use.
///
/// Prints the user code + verification URL via [log] (the caller wires it to
/// stdout) and blocks until the user approves on another device or the code
/// expires. Throws [GoogleOAuthException] on denial/timeout/missing config.
Future<void> connectGoogleCalendar({
  required CcServerConfig config,
  required String workspaceId,
  required void Function(String line) log,
}) async {
  if (!config.googleCalendarConfigured) {
    throw const GoogleOAuthException(
      'Google client id is not configured. Set CC_GOOGLE_OAUTH_CLIENT_ID (and '
      'CC_GOOGLE_OAUTH_CLIENT_SECRET) before connecting a calendar.',
      kind: GoogleOAuthFailureKind.missingClientId,
    );
  }

  final db = AppDatabase(
    openServerDatabase(dataDir: config.dataDir),
    onWarn: (tag, message) => CcHostLog.warning('$tag: $message'),
    onError: (tag, message) => CcHostLog.error('$tag: $message'),
  );
  try {
    // Validate the target workspace exists so we never strand an account on a
    // bogus id; list the real ones to help if it doesn't.
    final workspaceRepository = DaoWorkspaceRepository(db.workspaceDao);
    final workspaces = await workspaceRepository.watchAll().first;
    if (!workspaces.any((w) => w.id == workspaceId)) {
      final listing = workspaces.isEmpty
          ? '(none — create one first)'
          : workspaces.map((w) => '  ${w.id}  ${w.name}').join('\n');
      throw ArgumentError(
        'No workspace "$workspaceId" in ${config.dataDir}. Available:\n$listing',
      );
    }

    final auth = GoogleDeviceAuthClient(
      clientId: config.googleClientId,
      clientSecret: config.googleClientSecret,
    );
    final code = await auth.requestDeviceCode();
    log('');
    log('To connect Google Calendar:');
    log('  1. On any device, open: ${code.verificationUrl}');
    log('  2. Enter this code:     ${code.userCode}');
    log('');
    log('Waiting for approval (the code expires shortly)…');

    final creds = await auth.pollForToken(code);
    final email = creds.accountEmail;
    if (email.isEmpty) {
      throw const GoogleOAuthException(
        'Could not determine the connected account email (no id_token).',
        code: 'no_account_email',
      );
    }

    final accountId = serverGoogleAccountId(workspaceId, email);
    await FileGoogleCredentialsStore(dataDir: config.dataDir).save(accountId, creds);
    await DaoCalendarRepository(db.calendarDao).upsertAccount(
      CalendarAccount(
        id: accountId,
        workspaceId: workspaceId,
        providerId: 'google',
        accountEmail: email,
      ),
    );
    log('');
    log('Connected $email to workspace $workspaceId.');
    log('The server will sync this calendar on its next sweep.');
  } finally {
    await db.close();
  }
}

/// The pending device-authorization a GUI connect is waiting on.
class _PendingConnect {
  _PendingConnect({
    required this.workspaceId,
    required this.auth,
    required this.code,
  });

  final String workspaceId;
  final GoogleDeviceAuthClient auth;
  final GoogleDeviceCode code;
}

/// What `calendar.beginConnect` hands back to the GUI: the user code + URL to
/// display, plus an opaque [handle] the GUI polls with.
class CalendarConnectBegin {
  /// Creates a [CalendarConnectBegin].
  const CalendarConnectBegin({
    required this.handle,
    required this.userCode,
    required this.verificationUrl,
    required this.intervalSeconds,
    required this.expiresInSeconds,
  });

  /// Opaque handle for the pending flow (passed back to `calendar.pollConnect`).
  final String handle;

  /// The short code the user enters at [verificationUrl].
  final String userCode;

  /// Where the user approves the request.
  final String verificationUrl;

  /// Minimum seconds the GUI should wait between polls.
  final int intervalSeconds;

  /// Seconds until the device code expires.
  final int expiresInSeconds;
}

/// The status of a GUI connect poll.
enum CalendarConnectStatus {
  /// Not yet approved — keep polling.
  pending,

  /// Approved + stored; [CalendarConnectPoll.accountEmail] is set.
  connected,

  /// The user denied the request.
  denied,

  /// The device code expired before approval — restart the flow.
  expired,

  /// The handle is unknown (expired/cleared/never existed).
  unknown,
}

/// What `calendar.pollConnect` hands back.
class CalendarConnectPoll {
  /// Creates a [CalendarConnectPoll].
  const CalendarConnectPoll(this.status, {this.accountEmail});

  /// The poll status.
  final CalendarConnectStatus status;

  /// The connected account email, set iff [status] is
  /// [CalendarConnectStatus.connected].
  final String? accountEmail;
}

/// Drives the GUI device-code connect over RPC: [begin] (returns a code + URL),
/// [poll] (one Google poll per call), [disconnect]. The client id + secret are
/// supplied by the caller (the connect form) and stored per account so the sync
/// can refresh later. Pending flows live in memory keyed by an opaque handle — a
/// short-lived connect is fine to lose on a server restart (just re-initiate).
class CalendarConnectService {
  /// Creates a [CalendarConnectService]. [onConnected] (optional) fires after a
  /// successful connect so the caller can kick an immediate sync.
  CalendarConnectService({
    required FileGoogleCredentialsStore store,
    required CalendarRepository calendarRepository,
    Future<void> Function(String workspaceId)? onConnected,
  }) : _store = store,
       _calendarRepository = calendarRepository,
       _onConnected = onConnected;

  final FileGoogleCredentialsStore _store;
  final CalendarRepository _calendarRepository;
  final Future<void> Function(String workspaceId)? _onConnected;
  final Map<String, _PendingConnect> _pending = {};
  final Random _random = Random.secure();

  /// Starts a device-code flow for [workspaceId] with the supplied client.
  Future<CalendarConnectBegin> begin({
    required String workspaceId,
    required String clientId,
    required String clientSecret,
  }) async {
    if (clientId.isEmpty || clientSecret.isEmpty) {
      throw const GoogleOAuthException(
        'A Google client id and secret are required to connect.',
        kind: GoogleOAuthFailureKind.missingClientId,
      );
    }
    final auth = GoogleDeviceAuthClient(
      clientId: clientId,
      clientSecret: clientSecret,
    );
    final code = await auth.requestDeviceCode();
    final handle = _newHandle();
    _pending[handle] = _PendingConnect(
      workspaceId: workspaceId,
      auth: auth,
      code: code,
    );
    return CalendarConnectBegin(
      handle: handle,
      userCode: code.userCode,
      verificationUrl: code.verificationUrl,
      intervalSeconds: code.interval.inSeconds,
      expiresInSeconds: code.expiresAt.difference(DateTime.now()).inSeconds,
    );
  }

  /// Polls the pending flow [handle] once. On success stores the tokens + the
  /// `CalendarAccount` row and clears the pending entry.
  Future<CalendarConnectPoll> poll({
    required String workspaceId,
    required String handle,
  }) async {
    final pending = _pending[handle];
    if (pending == null) {
      return const CalendarConnectPoll(CalendarConnectStatus.unknown);
    }
    // Isolation: a handle belongs only to the workspace that began it.
    if (pending.workspaceId != workspaceId) {
      throw const WorkspaceMismatchException(
        'This calendar connect attempt belongs to a different workspace.',
      );
    }
    final outcome = await pending.auth.pollOnce(pending.code);
    switch (outcome.status) {
      case GoogleDevicePollStatus.pending:
      case GoogleDevicePollStatus.slowDown:
        return const CalendarConnectPoll(CalendarConnectStatus.pending);
      case GoogleDevicePollStatus.denied:
        _pending.remove(handle);
        return const CalendarConnectPoll(CalendarConnectStatus.denied);
      case GoogleDevicePollStatus.expired:
        _pending.remove(handle);
        return const CalendarConnectPoll(CalendarConnectStatus.expired);
      case GoogleDevicePollStatus.connected:
        _pending.remove(handle);
        final creds = outcome.credentials!;
        final email = creds.accountEmail;
        if (email.isEmpty) {
          throw const GoogleOAuthException(
            'Could not determine the connected account email (no id_token).',
            code: 'no_account_email',
          );
        }
        final accountId = serverGoogleAccountId(workspaceId, email);
        await _store.save(accountId, creds);
        await _calendarRepository.upsertAccount(
          CalendarAccount(
            id: accountId,
            workspaceId: workspaceId,
            providerId: 'google',
            accountEmail: email,
          ),
        );
        // Kick an immediate sync (don't block the poll response on the network
        // round-trip) so the new account's events appear right away.
        final onConnected = _onConnected;
        if (onConnected != null) {
          unawaited(onConnected(workspaceId));
        }
        return CalendarConnectPoll(
          CalendarConnectStatus.connected,
          accountEmail: email,
        );
    }
  }

  /// Disconnects [accountId] from [workspaceId]: deletes the account row (which
  /// cascades its events) and clears the stored tokens.
  Future<void> disconnect({
    required String workspaceId,
    required String accountId,
  }) async {
    // Isolation: the account id embeds its workspace.
    if (_workspaceIdFromAccountId(accountId) != workspaceId) {
      throw const WorkspaceMismatchException(
        'That calendar account belongs to a different workspace.',
      );
    }
    await _calendarRepository.deleteAccount(workspaceId, accountId);
    await _store.clear(accountId);
  }

  String _newHandle() {
    final bytes = List<int>.generate(18, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

/// Server-side RSVP: writes the connected user's response to a Google Calendar
/// invitation on the host's OAuth token (the thin client holds none), then
/// optimistically upserts the local event so the choice shows before the next
/// sync. The thin client drives this over the `calendar.rsvp` op.
class ServerCalendarRsvp {
  /// Creates a [ServerCalendarRsvp].
  ServerCalendarRsvp({
    required CalendarRepository calendarRepository,
    required GoogleCalendarApiClient apiClient,
  }) : _repository = calendarRepository,
       _apiClient = apiClient;

  final CalendarRepository _repository;
  final GoogleCalendarApiClient _apiClient;

  /// Sends [responseStatus] (`accepted` / `declined` / `tentative`) for the
  /// local event [eventId] in [workspaceId]. Throws [NotFoundException] if the
  /// event is unknown to the workspace (also the cross-workspace guard: the
  /// lookup is workspace-scoped, so a foreign id is simply not found).
  Future<void> respond({
    required String workspaceId,
    required String eventId,
    required String responseStatus,
  }) async {
    final event = await _repository.watchEventById(workspaceId, eventId).first;
    if (event == null) {
      throw const NotFoundException('Calendar event not found');
    }
    // PATCH replaces the attendees array, so send the full list with only the
    // self attendee's status changed.
    final attendees = <Map<String, dynamic>>[
      for (final a in event.attendees)
        <String, dynamic>{
          'email': a.email,
          if (a.displayName != null) 'displayName': a.displayName,
          'responseStatus':
              a.self ? responseStatus : (a.responseStatus ?? 'needsAction'),
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
}

/// The server-side calendar wiring: the periodic [sync] sweep, the GUI
/// [connect] service, and the [rsvp] writer, sharing ONE credential store (so a
/// freshly-connected account is immediately visible to the sync's token
/// manager — separate store instances cache the on-disk map independently and
/// would diverge).
class ServerCalendar {
  /// Creates a [ServerCalendar].
  ServerCalendar({
    required this.sync,
    required this.connect,
    required this.rsvp,
  });

  /// The periodic per-workspace sync sweep.
  final ServerCalendarSync sync;

  /// The GUI device-code connect service (backs the `calendar.*Connect` ops).
  final CalendarConnectService connect;

  /// The RSVP writer (backs the `calendar.rsvp` op).
  final ServerCalendarRsvp rsvp;
}

/// Builds the server-side calendar [ServerCalendar.sync] + [ServerCalendar.connect]
/// over a shared credential store under [dataDir]. The token manager flags an
/// account for re-connect on a dead refresh token. The sync runs unconditionally
/// (it no-ops until an account is connected) — connecting is a runtime action
/// (GUI or CLI), not build-time config.
ServerCalendar buildServerCalendar({
  required CalendarRepository calendarRepository,
  required WorkspaceRepository workspaceRepository,
  required DomainEventBus eventBus,
  required String dataDir,
}) {
  final store = FileGoogleCredentialsStore(dataDir: dataDir);
  final tokens = ServerGoogleTokenManager(
    store: store,
    onInvalidGrant: (accountId) async {
      final workspaceId = _workspaceIdFromAccountId(accountId);
      if (workspaceId == null) {
        return;
      }
      try {
        final now = DateTime.now();
        await calendarRepository.markNeedsReauth(workspaceId, accountId, now);
        eventBus.publish(
          CalendarAuthExpired(
            workspaceId: workspaceId,
            accountEmail: '',
            occurredAt: now,
          ),
        );
      } on Object catch (e) {
        CcHostLog.warning('calendar: could not flag $accountId for reauth: $e');
      }
    },
  );
  final apiClient = buildServerGoogleCalendarApiClient(tokens);
  final sync = ServerCalendarSync(
    calendarRepository: calendarRepository,
    apiClient: apiClient,
    workspaceRepository: workspaceRepository,
    eventBus: eventBus,
  );
  return ServerCalendar(
    sync: sync,
    connect: CalendarConnectService(
      store: store,
      calendarRepository: calendarRepository,
      // After a GUI connect, sync that workspace immediately (same process, so
      // the shared store already has the new token).
      onConnected: sync.syncWorkspace,
    ),
    rsvp: ServerCalendarRsvp(
      calendarRepository: calendarRepository,
      apiClient: apiClient,
    ),
  );
}
