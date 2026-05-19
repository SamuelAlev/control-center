import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show ChatDeepLinks, CodeServerService;
import 'package:cc_mcp/cc_mcp.dart' show McpRequestHandler;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/favicon_transcode.dart';
import 'package:cc_server_core/src/identity/oidc_service.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:cc_server_core/src/image_resize.dart';
import 'package:cc_server_core/src/media_cache.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/relay/paired_peer_auth.dart';
import 'package:cc_server_core/src/remote_event_forwarder.dart';
import 'package:cc_server_core/src/server_mcp_control.dart';
import 'package:path/path.dart' as p;

// Server diagnostics route through cc_host's pluggable log sink (the desktop
// installs an AppLog sink via installCcHostLogging(); the headless server a
// stdout sink), so this file needs no Flutter logger.
void _e(String m, [Object? err, StackTrace? st]) =>
    CcHostLog.error('LocalRpcServer: $m', err, st);
void _i(String m) => CcHostLog.info('LocalRpcServer: $m');
void _w(String m) => CcHostLog.warning('LocalRpcServer: $m');

/// Resolves the on-disk playable audio file for a meeting, validating that it
/// belongs to [workspaceId]. Returns null when the meeting is unknown, kept no
/// audio, or its files are gone. Used by [LocalRpcServer]'s `/meeting/audio`
/// endpoint to stream a recorded meeting's mixed WAV to a thin client for
/// playback (the byte path; the waveform/duration metadata travels over RPC).
typedef MeetingAudioResolver =
    Future<File?> Function({
      required String workspaceId,
      required String meetingId,
    });

/// Resolves the on-disk logo image file for [workspaceId] (the persisted
/// `Workspace.logoPath`). Returns null when the workspace has no logo or its
/// file is gone. Used by [LocalRpcServer]'s `/workspace/logo` endpoint to serve
/// the logo to a thin client — the file lives on the SERVER's disk, never the
/// client's, so a workspace mark renders identically on desktop, web, and
/// remote (mirroring `/meeting/audio`).
typedef WorkspaceLogoResolver =
    Future<File?> Function({required String workspaceId});

/// Resolves the upstream file URL for one variant of a catalogued font family.
///
/// Returns null when [family] is not in the host's font catalogue, which is what
/// makes `/proxy/font` a closed surface: a client names a family and a variant,
/// never a URL, so this route cannot be pointed at an arbitrary host the way a
/// URL-taking proxy can. The resolver SNAPS [weight]/[subset] to what the family
/// actually offers and always yields a Skia-decodable format (`ttf`) — the
/// reason fonts cannot be fetched by the client at all (see
/// `FontsourceCatalogService`).
typedef FontFileResolver =
    Future<Uri?> Function({
      required String family,
      required int weight,
      required bool italic,
      required String subset,
    });

/// Opens a continuous MP3 byte stream for a soundscape `(workspaceId, mood)`.
/// Attaching a listener joins (or lazily creates) the shared generative session
/// on the host; cancelling the subscription detaches. Returns null when the host
/// has no soundscape engine (e.g. the MP3 encoder dylib is absent) — the route
/// then 404s and the client hides audio. Wired to `SoundscapeHub` by the runtime.
typedef SoundscapeStreamResolver =
    Stream<List<int>>? Function({
      required String workspaceId,
      required String mood,
    });

/// Builds a live HLS media playlist (`.m3u8`) for a soundscape `(workspaceId,
/// mood)`. [segmentQuery] is echoed into each segment URI so one signed target
/// authorizes the playlist and every segment. Returns null when unavailable.
typedef SoundscapePlaylistResolver =
    String? Function({
      required String workspaceId,
      required String mood,
      required String segmentQuery,
    });

/// Resolves one HLS segment's MP3 bytes by index. Returns null when the segment
/// has aged out of the sliding window or the host has no engine.
typedef SoundscapeSegmentResolver =
    List<int>? Function({
      required String workspaceId,
      required String mood,
      required int index,
    });

/// Handles an inbound webhook POST to `/webhooks/<token>`, returning the HTTP
/// status and response body. Wired to the `WebhookDeliveryService` by the
/// server runtime; null on a host without webhook support (the route 404s).
typedef WebhookRequestHandler =
    Future<({int status, String body})> Function({
      required String token,
      required Map<String, String> headers,
      required String body,
    });

/// Handles an inbound vendor ticket-sync webhook POST to
/// `/api/webhooks/tickets/<vendor>?ws=<workspaceId>`. Wired to the
/// `TicketSyncWebhookHandler` by the server runtime; null on a host without
/// ticket sync (the route 404s). The HMAC signature is the gate (the workspace
/// id in the query only routes).
typedef TicketWebhookRequestHandler =
    Future<({int status, String body})> Function({
      required String vendor,
      required String? workspaceId,
      required Map<String, String> headers,
      required String body,
    });

/// Looks up a live code-server session by its capability `sessionId` for the
/// `/proxy/vscode/<sid>/*` reverse proxy. Returns null for an unknown / expired
/// / foreign-workspace session (the proxy then denies with 403). Wired by the
/// server runtime to [CodeServerService.lookup]; null on a host that does not
/// run code-server (the route then 404s).
typedef CodeServerSessionResolver =
    CodeServerSession? Function(String sessionId);

/// Records a bridge-extension "open this file as an app tab" report for the
/// code-server addressed by capability `sessionId`. Wired by the runtime to
/// [CodeServerService.reportOpen]; null on a host that does not run code-server.
typedef CodeServerOpenReporter =
    void Function(String sessionId, String absPath, int? line);

/// Records a bridge-extension "this file's dirty state changed" report for the
/// code-server addressed by capability `sessionId`. Wired by the runtime to
/// [CodeServerService.reportDirty]; null on a host that does not run code-server.
typedef CodeServerDirtyReporter =
    void Function(String sessionId, String absPath, bool dirty);

/// Resolves the reverse command stream for the code-server addressed by
/// capability `sessionId` — the `{cmd, …}` maps relayed to the bridge extension
/// over `/proxy/vscode/<sid>/__cc_commands__` (SSE). Wired by the runtime to
/// [CodeServerService.commandStream]; null on a host that does not run
/// code-server.
typedef CodeServerCommandStreamResolver =
    Stream<Map<String, Object?>> Function(String sessionId);

/// A WebSocket JSON-RPC server — the **reachable-server** transport.
///
/// Where the WebRTC path (`RemoteControlServer`) reaches a desktop behind NAT
/// via a broker, this server is dialed directly: a client opens `wss://…/rpc`
/// on the LAN / Tailnet / VPS, or `ws://localhost:<port>` for a same-origin web
/// build. It is the server a headless `cc_server` runs, and the one the desktop
/// starts in "act as server" (LOCAL+serve) mode. The same paired-device PSK
/// authenticates each connection and the same shared `RpcDispatcher` +
/// `RemoteRpcSession` handle the RPC — TLS replaces DTLS as the channel guard.
///
/// Security posture (matches the plan's § Security):
///  * **Loopback or TLS.** Binding any non-loopback interface requires a
///    `SecurityContext`; otherwise `start` throws rather than expose plaintext.
///  * **Origin allow-list.** Browser `Origin` headers are checked against
///    `allowedOrigins` (loopback always allowed) — never reflected.
///  * **PSK challenge.** A connection must prove PSK possession (mutual HMAC
///    challenge) for an `active` device before any RPC is dispatched.
/// Whether [uri] points at an address the media proxy must refuse: loopback,
/// link-local (incl. the 169.254.169.254 cloud-metadata endpoint), the GCP
/// `metadata.google.internal` name, or RFC-1918 / IPv6 unique-local private
/// ranges. IP literals are checked directly; bare `localhost` is refused by
/// name. Defence-in-depth behind the PSK signature — and, critically, this is
/// re-run on every redirect hop so an authorised signed URL cannot 3xx its way
/// to an internal address.
///
/// A bare hostname (not an IP literal) returns `false`: the proxy resolves it
/// at connect time and the PSK signature is the trust boundary. DNS-rebinding
/// to an internal IP is a residual risk documented in FINDINGS §1.
bool isBlockedProxyTarget(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host.isEmpty) {
    return true;
  }
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host == 'metadata.google.internal') {
    return true;
  }
  final addr = InternetAddress.tryParse(host);
  if (addr == null) {
    return false; // A hostname; the PSK signature is the trust boundary.
  }
  if (addr.isLoopback || addr.isLinkLocal || addr.isMulticast) {
    return true;
  }
  final raw = addr.rawAddress;
  if (addr.type == InternetAddressType.IPv4) {
    final a = raw[0];
    final b = raw[1];
    if (a == 0 || a == 10 || a == 127) {
      return true;
    }
    if (a == 172 && b >= 16 && b <= 31) {
      return true;
    }
    if (a == 192 && b == 168) {
      return true;
    }
    return false;
  }
  // IPv6 unique-local (fc00::/7) or unspecified (::). Loopback (::1) and
  // link-local (fe80::/10) are already caught by the isLoopback/isLinkLocal
  // check above. IPv4-mapped (::ffff:a.b.c.d) smuggles a private IPv4
  // literal past the IPv4 branch, so re-check its embedded v4 (defense-in-
  // depth behind the PSK signature).
  if (raw[0] == 0xfc || raw[0] == 0xfd || addr.address == '::') {
    return true;
  }
  if (raw.length >= 16 && raw[10] == 0xff && raw[11] == 0xff) {
    final a = raw[12];
    final b = raw[13];
    if (a == 0 ||
        a == 10 ||
        a == 127 ||
        (a == 169 && b == 254) ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168)) {
      return true;
    }
  }
  return false;
}

/// Reads a singleton header that a malformed upstream may send more than
/// once — `headers.value()` throws [HttpException] on multiple values, so
/// take the first instead of failing the whole fetch.
String? firstUpstreamHeaderValue(HttpHeaders headers, String name) {
  final values = headers[name];
  return (values == null || values.isEmpty) ? null : values.first;
}

/// The upstream's combined `Cache-Control` value. It is list-valued per
/// RFC 9111 §5.2 and some origins (e.g. news.ycombinator.com) send it as
/// several header lines — `headers.value()` throws [HttpException] on those,
/// so comma-join (the spec-defined combination) instead.
String? upstreamCacheControlValue(HttpHeaders headers) =>
    headers[HttpHeaders.cacheControlHeader]?.join(', ');

/// Result of [LocalRpcServer._openUpstream]: the final response after the
/// SSRF-checked redirect walk, a revalidation `304`, or a failure carrying
/// the status the proxy should answer with.
sealed class _UpstreamOpen {
  const _UpstreamOpen();
}

/// The upstream answered with a real response; [finalUri] is the URI it came
/// from after redirects (used for extension sniffing).
final class _UpstreamOk extends _UpstreamOpen {
  const _UpstreamOk(this.response, this.finalUri);

  /// The open upstream response, unread.
  final HttpClientResponse response;

  /// The URI that produced [response].
  final Uri finalUri;
}

/// A conditional request was answered `304 Not Modified`.
final class _UpstreamNotModified extends _UpstreamOpen {
  const _UpstreamNotModified();
}

/// The fetch failed; [statusCode] is what the proxy should answer with.
final class _UpstreamError extends _UpstreamOpen {
  const _UpstreamError(this.statusCode);

  /// The HTTP status to relay to the client.
  final int statusCode;
}

/// Whether an MCP request from [remote] may be answered. Fail-closed: a
/// tokenless MCP surface serves loopback clients only (the standalone
/// listener's historical exposure); off-host clients require a configured
/// bearer token. A null [remote] (no connection info) is treated as off-host.
bool mcpRemoteClientAllowed({
  required InternetAddress? remote,
  required bool hasToken,
}) => hasToken || (remote?.isLoopback ?? false);

/// The in-process RPC server: binds repo-RPC catalog ops + MCP tools to the
class LocalRpcServer implements McpHostServer {
  /// Creates a [LocalRpcServer].
  LocalRpcServer({
    required this.dispatcher,
    required this.devicesDao,
    required this.secrets,
    required this.eventBus,
    required this.workspaceResolver,
    this.repoOps,
    this.watchQueries,
    this.workspaceExists,
    this.meetingAudio,
    this.workspaceLogo,
    this.fontFile,
    this.soundscapeStream,
    this.soundscapePlaylist,
    this.soundscapeSegment,
    this.webhookHandler,
    this.ticketWebhookHandler,
    this.codeServerLookup,
    this.codeServerReport,
    this.codeServerReportDirty,
    this.codeServerCommandStream,
    this.codeGraphStatus,
    this.inviteRedeemer,
    this.oidc,
    this.identity,
    RemoteRateLimiterPool? rateLimiters,
    this.address,
    this.port = 9030,
    this.securityContext,
    this.allowInsecureBind = false,
    this.allowedOrigins = const <String>{},
    this.webRoot,
    this.mediaCacheDir,
    this.fontCacheDir,
    this.onRunningChanged,
  }) : rateLimiters = rateLimiters ?? RemoteRateLimiterPool();

  /// The server's Ed25519 identity (PRD 15 §9). When present, the auth
  /// handshake signs each client's nonce (TOFU fingerprint pinning) and
  /// `/healthz` reports the server id + fingerprint so resolvers can verify
  /// which server answered at an address. Null only in minimal test setups.
  final ServerIdentity? identity;

  /// Repo-RPC dispatcher exposed to connected clients (`repo/call` / `op/list`).
  final RepoOpDispatcher? repoOps;

  /// Reactive watch-query registry (`sub/subscribe`).
  final WatchQueryRegistry? watchQueries;

  /// Resolves a meeting's playable audio file for the `/meeting/audio` byte
  /// endpoint. Null on a host with no meeting audio capability — the route then
  /// 404s (the client falls back to no playback).
  final MeetingAudioResolver? meetingAudio;

  /// Resolves a workspace's persisted logo file for the `/workspace/logo`
  /// endpoint. Null on a host with no workspace-logo capability — the route
  /// then 404s (the client falls back to the workspace initial).
  final WorkspaceLogoResolver? workspaceLogo;

  /// Resolves one variant of a catalogued font family to its upstream file URL
  /// for the `/proxy/font` endpoint. Null on a host with no font catalogue — the
  /// route then 404s (clients keep their bundled and system fonts).
  final FontFileResolver? fontFile;

  /// Opens the continuous MP3 stream for a soundscape `(workspaceId, mood)` over
  /// `/soundscape/stream`. Null on a host with no soundscape engine — the route
  /// then 404s (the client hides audio).
  final SoundscapeStreamResolver? soundscapeStream;

  /// Builds the HLS playlist for a soundscape over `/soundscape/playlist.m3u8`.
  /// Null on a host with no engine — the route then 404s.
  final SoundscapePlaylistResolver? soundscapePlaylist;

  /// Resolves one HLS segment's bytes over `/soundscape/seg`. Null on a host
  /// with no engine — the route then 404s.
  final SoundscapeSegmentResolver? soundscapeSegment;

  /// Handles inbound `/webhooks/<token>` POSTs (signature verification, dedup,
  /// dispatch). Null on a host without webhook support — the route then 404s.
  final WebhookRequestHandler? webhookHandler;

  /// Handles inbound `/api/webhooks/tickets/<vendor>` POSTs (vendor ticket
  /// sync). Null on a host without ticket sync — the route then 404s.
  final TicketWebhookRequestHandler? ticketWebhookHandler;

  /// Looks up a live code-server session for the `/proxy/vscode/<sid>/*`
  /// reverse proxy (capability authz). Null on a host that does not run
  /// code-server — the route then 404s.
  final CodeServerSessionResolver? codeServerLookup;

  /// Snapshot of the background code-graph indexer for the `/healthz`
  /// `codeGraph` block ("is it still indexing?" — the operational question a
  /// slow host raises). Null on a host without code-graph indexing — the
  /// field is then omitted. Must be cheap and synchronous (pure in-memory).
  final Map<String, Object?> Function()? codeGraphStatus;

  /// Receives bridge-extension open-file reports POSTed to
  /// `/proxy/vscode/<sid>/__cc_open__` (authorized by the same capability the
  /// proxy checks). Null on a host without code-server.
  final CodeServerOpenReporter? codeServerReport;

  /// Receives bridge-extension dirty-state reports POSTed to the same
  /// `__cc_open__` endpoint with `{type:'dirty', path, dirty}`. Null on a host
  /// without code-server.
  final CodeServerDirtyReporter? codeServerReportDirty;

  /// Resolves the reverse command SSE stream served at
  /// `/proxy/vscode/<sid>/__cc_commands__`. Null on a host without code-server.
  final CodeServerCommandStreamResolver? codeServerCommandStream;

  /// Handles `POST /invites/redeem` — the pre-auth invite redemption that
  /// JIT-provisions a user and mints their first device credential. The
  /// one-time invite code in the body is the proof. Null on a host without
  /// identity wiring — the route then 404s.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)?
  inviteRedeemer;

  /// Optional OIDC single sign-on (`GET /oidc/login` + `/oidc/callback`).
  /// Null (the default) leaves the routes absent — SSO is never required.
  final OidcService? oidc;

  /// Per-user shared rate limiters: every session a user opens draws from
  /// one budget.
  final RemoteRateLimiterPool rateLimiters;

  /// Shared RPC dispatcher (one instance app-wide).
  final RpcDispatcher dispatcher;

  /// Paired-device metadata DAO, from the server-global database: a device is
  /// paired with the server, not with one workspace, and survives a workspace
  /// being deleted.
  final PairedDeviceDao devicesDao;

  /// Per-device PSK secure store.
  final PairedDeviceSecretsPort secrets;

  /// Domain event bus for push.
  final DomainEventBus eventBus;

  /// Resolves the workspaces a client may switch between.
  final RemoteWorkspaceResolver workspaceResolver;

  /// Registry existence gate forwarded to each session's
  /// [SubscriptionManager]: a workspace-scoped subscription naming an
  /// unregistered workspace is refused before its handler opens (and thereby
  /// CREATES) that workspace's database file. The `repo/call` gate lives on
  /// [repoOps] itself.
  final WorkspaceExistsChecker? workspaceExists;

  /// Interface to bind. Defaults to loopback (the safe same-origin/localhost
  /// case). Pass `InternetAddress.anyIPv4` only together with [securityContext].
  final InternetAddress? address;

  /// TCP port to listen on.
  final int port;

  /// TLS context. Required for any non-loopback [address] unless
  /// [allowInsecureBind] is set; optional for loopback (a browser treats
  /// `http://localhost` as a secure context already).
  final SecurityContext? securityContext;

  /// Opt-in escape hatch to bind a non-loopback address over PLAINTEXT (no
  /// [securityContext]). Off by default — the server fails closed rather than
  /// expose unencrypted RPC. Set it ONLY when a TLS-terminating reverse proxy
  /// (Caddy / Traefik / nginx / Cloudflare Tunnel) sits in front and cc_server
  /// speaks plaintext on a trusted private network — the standard containerised
  /// topology, where TLS is the proxy's job. [start] logs a loud warning so an
  /// accidental public plaintext bind is never silent. Ignored when a
  /// [securityContext] is present (TLS always wins).
  final bool allowInsecureBind;

  /// Browser origins permitted to connect cross-origin (e.g. a Cloudflare-hosted
  /// web build). Loopback origins are always allowed; a null origin (native
  /// client) is allowed. Anything else not listed is rejected — never reflected.
  final Set<String> allowedOrigins;

  /// Optional directory whose static files are served (the web bundle) for any
  /// path other than `/rpc`. When null, non-RPC requests get 404.
  final String? webRoot;

  /// Directory of the persistent `/proxy/media` disk cache ([MediaCache]).
  /// Null disables caching (minimal test setups) — the proxy then fetches
  /// upstream on every request, its original behavior.
  final String? mediaCacheDir;

  /// Directory of the persistent `/proxy/font` disk cache. Kept separate from
  /// [mediaCacheDir] so avatar/favicon churn cannot evict the handful of font
  /// files the UI is actively rendering with, and vice versa. Null disables
  /// caching — every request then re-fetches upstream.
  final String? fontCacheDir;

  MediaCache? _mediaCacheInstance;

  /// The lazily-built media cache, or null when [mediaCacheDir] is unset.
  MediaCache? get _mediaCache => _mediaCacheInstance ??= mediaCacheDir == null
      ? null
      : (MediaCache(dir: Directory(mediaCacheDir!))..startPeriodicSweep());

  MediaCache? _fontCacheInstance;

  /// The lazily-built font cache, or null when [fontCacheDir] is unset. Fonts
  /// are ordinary immutable byte assets, so [MediaCache]'s TTL/revalidate/
  /// single-flight behavior applies unchanged; only the directory differs.
  MediaCache? get _fontCache => _fontCacheInstance ??= fontCacheDir == null
      ? null
      : (MediaCache(dir: Directory(fontCacheDir!))..startPeriodicSweep());

  /// Callback when running state changes.
  void Function({required bool running})? onRunningChanged;

  HttpServer? _server;
  DateTime? _startedAt;
  final Set<_WsSession> _sessions = {};
  StreamSubscription<List<PairedDevicesTableData>>? _deviceWatch;

  /// Whether the server is bound and listening.
  @override
  bool get isRunning => _server != null;

  /// The bound port (after [start]), or the configured [port] before.
  @override
  int get boundPort => _server?.port ?? port;

  /// Whether this listener terminates TLS in-process (`--tls-cert`/`--tls-key`).
  /// When true, server-spawned agent CLIs cannot reach the mounted MCP surface
  /// over loopback (the host cert never validates against 127.0.0.1), so
  /// `ServerMcpControl` keeps a plaintext loopback companion for dispatch.
  @override
  bool get tlsInProcess => securityContext != null;

  /// The mounted MCP request handler (`/mcp` + `/sse` routes), or null when
  /// the MCP surface is stopped. Set by `ServerMcpControl` — the field is read
  /// per request, so toggling MCP never rebinds this listener.
  @override
  set mcpHandler(McpRequestHandler? handler) => _mcpHandler = handler;

  McpRequestHandler? _mcpHandler;

  /// Binds and begins serving. Throws [StateError] if a non-loopback bind is
  /// requested without TLS (fail closed rather than serve plaintext remotely).
  Future<void> start() async {
    if (_server != null) {
      return;
    }
    final addr = address ?? InternetAddress.loopbackIPv4;
    final isLoopback = addr.isLoopback;
    if (!isLoopback && securityContext == null) {
      if (!allowInsecureBind) {
        throw StateError(
          'Refusing to bind non-loopback address $addr without TLS. '
          'Provide a SecurityContext (self-signed pinned cert / Let\'s Encrypt / '
          'Tailscale cert), set allowInsecureBind (only behind a TLS-terminating '
          'reverse proxy), or bind loopback only.',
        );
      }
      _w(
        'SECURITY: binding $addr over PLAINTEXT (allowInsecureBind). Only safe '
        'behind a TLS-terminating reverse proxy on a trusted network — never '
        'expose this port directly to the public internet.',
      );
    }
    final server = securityContext != null
        ? await HttpServer.bindSecure(addr, port, securityContext!)
        : await HttpServer.bind(addr, port);
    _server = server;
    _startedAt = DateTime.now();
    server.listen(
      _handle,
      onError: (Object e, StackTrace st) {
        _e('LocalRpcServer accept error: $e', e, st);
      },
    );
    _i(
      'LocalRpcServer listening on '
      '${securityContext != null ? 'wss' : 'ws'}://${addr.host}:${server.port} '
      '(web bundle: ${webRoot ?? 'none'})',
    );
    // Live revocation: revoking a device (or deleting its row) must terminate
    // its open sessions within seconds, not on next reconnect. Mirror the
    // relay host's reconcile: watch the device table and drop any live
    // session whose device left the active set.
    _deviceWatch = devicesDao.watchAll().listen((rows) {
      final active = {
        for (final row in rows)
          if (row.status == PairedDeviceStatus.active) row.id,
      };
      for (final session in _sessions.toList()) {
        if (!active.contains(session.deviceId)) {
          _w('Dropping live session for revoked device ${session.deviceId}');
          unawaited(_drop(session));
        }
      }
    });
    onRunningChanged?.call(running: true);
  }

  /// Stops the server and tears down every live session.
  Future<void> stop() async {
    final server = _server;
    _server = null;
    _startedAt = null;
    await _deviceWatch?.cancel();
    _deviceWatch = null;
    for (final s in _sessions.toList()) {
      await s.dispose();
    }
    _sessions.clear();
    if (server != null) {
      await server.close(force: true);
    }
    _mediaCacheInstance?.close();
    _mediaCacheInstance = null;
    onRunningChanged?.call(running: false);
    _i('LocalRpcServer stopped');
  }

  /// Best-effort fan-out of a JSON-RPC notification to every live session.
  /// Used by the host's shutdown sequence to stream `server/shutdown_progress`
  /// to connected thin clients before the socket closes. A closed or unwritable
  /// session is skipped — fire-and-forget, never throws.
  void broadcast(String method, Map<String, dynamic> params) {
    final frame = JsonRpcNotification(method: method, params: params).toJson();
    for (final session in _sessions.toList()) {
      unawaited(session.transport.send(frame).catchError((Object _) {}));
    }
  }

  Future<void> _handle(HttpRequest request) async {
    if (request.uri.path == '/rpc') {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response.statusCode = HttpStatus.upgradeRequired;
        await request.response.close();
        return;
      }
      if (!_originAllowed(request.headers.value('origin'))) {
        _w(
          'Rejecting WS upgrade — origin not allowed: '
          '${request.headers.value('origin')}',
        );
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        return;
      }
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        unawaited(_onSocket(socket, request.connectionInfo?.remoteAddress));
      } catch (e) {
        _w('WS upgrade failed: $e');
      }
      return;
    }
    if (request.uri.path == '/healthz') {
      await _serveHealth(request);
      return;
    }
    if (request.uri.path == '/invites/redeem') {
      await _serveInviteRedeem(request);
      return;
    }
    if (request.uri.path == '/oidc/login') {
      await _serveOidcLogin(request);
      return;
    }
    if (request.uri.path == '/oidc/callback') {
      await _serveOidcCallback(request);
      return;
    }
    if (request.uri.path.startsWith('${ChatDeepLinks.pathPrefix}/')) {
      await _serveOpenLink(request);
      return;
    }
    if (request.uri.path == '/proxy/media') {
      await _serveMediaProxy(request);
      return;
    }
    if (request.uri.path == '/proxy/font') {
      await _serveFontProxy(request);
      return;
    }
    if (request.uri.path.startsWith('/proxy/vscode/')) {
      await _serveCodeServerProxy(request);
      return;
    }
    if (request.uri.path == '/meeting/audio') {
      await _serveMeetingAudio(request);
      return;
    }
    if (request.uri.path == '/workspace/logo') {
      await _serveWorkspaceLogo(request);
      return;
    }
    if (request.uri.path == '/soundscape/stream') {
      await _serveSoundscapeStream(request);
      return;
    }
    if (request.uri.path == '/soundscape/playlist.m3u8') {
      await _serveSoundscapePlaylist(request);
      return;
    }
    if (request.uri.path == '/soundscape/seg') {
      await _serveSoundscapeSegment(request);
      return;
    }
    if (request.uri.path.startsWith('/api/webhooks/tickets/')) {
      await _serveTicketWebhook(request);
      return;
    }
    if (request.uri.path.startsWith('/webhooks/')) {
      await _serveWebhook(request);
      return;
    }
    if (request.uri.path == '/mcp' || request.uri.path == '/sse') {
      await _serveMcp(request);
      return;
    }
    await _serveStatic(request);
  }

  /// Routes the MCP Streamable HTTP transport (`/mcp`, `/sse`) to the mounted
  /// [McpRequestHandler] — the single-port topology: MCP rides the same
  /// listener as `/rpc` + the HTTP endpoints instead of a port of its own.
  /// 404s while the MCP surface is stopped (no handler mounted).
  ///
  /// Fail-closed guard: a tokenless MCP surface never answers OFF-HOST
  /// clients. The pre-unification standalone MCP listener bound loopback-only,
  /// and mounting on a LAN/Tailscale/TLS listener must not silently widen
  /// that exposure — configure a bearer token (`mcp.setToken`) to serve MCP
  /// beyond this host. With a token set, the handler's own auth check gates
  /// every request regardless of origin.
  Future<void> _serveMcp(HttpRequest request) async {
    final handler = _mcpHandler;
    if (handler == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    if (!mcpRemoteClientAllowed(
      remote: request.connectionInfo?.remoteAddress,
      hasToken: handler.hasToken,
    )) {
      _w(
        'Rejecting MCP request from '
        '${request.connectionInfo?.remoteAddress ?? 'unknown'} — no bearer '
        'token configured (set one via mcp.setToken to serve MCP off-host)',
      );
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write(
          jsonEncode({
            'error':
                'MCP requires a bearer token to answer non-loopback '
                'clients (mcp.setToken)',
          }),
        );
      await request.response.close();
      return;
    }
    await handler.handle(request);
  }

  /// Liveness / status endpoint (`GET /healthz`). Unauthenticated by design —
  /// it reports only non-sensitive operational facts (status, uptime, live
  /// connection count, bound port, build identity) so an external monitor,
  /// load balancer, or the desktop supervisor can probe the server without a
  /// paired-device PSK. The `version`/`gitSha` pair is the stale-binary
  /// signal: the desktop compares it against its own build identity (a
  /// mismatch means the spawned prebuilt binary is older than the app), and
  /// self-hosters compare it against the latest published release.
  Future<void> _serveHealth(HttpRequest request) async {
    final res = request.response;
    // CORS: /healthz is the reachability probe the WEB client's resolver
    // fetches cross-origin (PRD 15 §8). It is unauthenticated, carries no
    // credentials, and reveals only liveness + the PUBLIC server identity
    // (the fingerprint is what clients pin — publishing it is the point), so
    // a wildcard origin is safe and required.
    res.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    if (request.method != 'GET' && request.method != 'HEAD') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    final started = _startedAt;
    final uptimeSeconds = started == null
        ? 0
        : DateTime.now().difference(started).inSeconds;
    final identity = this.identity;
    res
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.set('Cache-Control', 'no-store')
      ..write(
        jsonEncode({
          'status': 'ok',
          'uptimeSeconds': uptimeSeconds,
          'connections': _sessions.length,
          'port': _server?.port ?? port,
          // Build/compat identity (non-sensitive; CI-stamped consts — see
          // packages/cc_domain/lib/src/build_info.dart). `schemaVersion` is
          // the WORKSPACE database schema (global.db stays at its own v1);
          // `catalogVersion` is the repo-RPC op catalog the server speaks.
          'version': BuildInfo.buildVersion,
          'gitSha': BuildInfo.buildGitSha,
          'schemaVersion': WorkspaceDatabase.currentSchemaVersion,
          if (repoOps != null)
            'catalogVersion': repoOps!.registry.catalogVersion,
          if (identity != null) ...{
            'serverId': identity.serverId,
            'serverName': identity.serverName,
            'fingerprint': identity.fingerprint,
          },
          'insecure': securityContext == null && allowInsecureBind,
          if (codeGraphStatus != null) 'codeGraph': codeGraphStatus!(),
        }),
      );
    await res.close();
  }

  /// Handles `POST /invites/redeem` — the only pre-auth identity endpoint.
  /// The one-time invite code in the JSON body is the proof of admission; a
  /// valid code JIT-provisions the user, records membership, and mints the
  /// device credential the new client then authenticates with. Failures are
  /// deliberately generic (no invite-existence oracle).
  Future<void> _serveInviteRedeem(HttpRequest request) async {
    final res = request.response;
    final redeem = inviteRedeemer;
    if (redeem == null) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    if (request.method != 'POST') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    try {
      final body = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('body must be a JSON object');
      }
      final result = await redeem(decoded);
      res
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..headers.set('Cache-Control', 'no-store')
        ..write(jsonEncode(result));
    } catch (e) {
      _w('invite redemption failed: $e');
      res
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Invite is invalid or expired'}));
    }
    await res.close();
  }

  /// `GET /open/workspaces/<ws>/(channels|tickets)/<id>` — hands a reader from a
  /// link back into the desktop app.
  ///
  /// It exists because chat products (Slack among them) only accept `http(s)` in
  /// a message link, so `control-center://…` can never be linked directly. This
  /// page is the one hop that converts one into the other: it navigates to the
  /// deep link on load and shows a button for the browsers that require a
  /// gesture before handing off to an external scheme.
  ///
  /// Deliberately inert: it reads no database, resolves nothing, and reveals
  /// nothing — the ids in the URL are echoed into a deep link and nowhere else,
  /// and the app the link opens does its own authorization. The only input
  /// handling that matters is the shape check: anything but a plain id is a 404,
  /// so the page cannot be used to bounce a visitor somewhere else.
  Future<void> _serveOpenLink(HttpRequest request) async {
    final res = request.response;
    if (request.method != 'GET' && request.method != 'HEAD') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    // ['open', 'workspaces', <ws>, <kind>, <id>]
    final segments = request.uri.pathSegments;
    const kinds = {'channels', 'tickets'};
    final valid =
        segments.length == 5 &&
        segments[1] == 'workspaces' &&
        kinds.contains(segments[3]) &&
        ChatDeepLinks.isSafeId(segments[2]) &&
        ChatDeepLinks.isSafeId(segments[4]);
    if (!valid) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    final target =
        'control-center://workspaces/${segments[2]}/${segments[3]}/'
        '${segments[4]}';
    res
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..headers.set('Cache-Control', 'no-store')
      // A page whose entire job is to leave for another scheme has nothing to
      // gain from being framed or referred onward.
      ..headers.set('X-Frame-Options', 'DENY')
      ..headers.set('Referrer-Policy', 'no-referrer')
      ..write(_openLinkPage(target));
    await res.close();
  }

  /// The bounce page: attempt the hand-off immediately, and stay readable when
  /// the browser refuses to do it without a click (or the app is not installed).
  static String _openLinkPage(String target) =>
      '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Opening Control Center…</title>
<style>
  :root { color-scheme: light dark; }
  body {
    margin: 0; min-height: 100vh; display: grid; place-items: center;
    font: 15px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui,
      sans-serif;
    background: #fbfbfa; color: #1c1b1a;
  }
  @media (prefers-color-scheme: dark) {
    body { background: #141413; color: #f5f4f2; }
    a.button { background: #f5f4f2; color: #141413; }
  }
  main { text-align: center; padding: 2rem; max-width: 30rem; }
  h1 { font-size: 1.125rem; font-weight: 600; margin: 0 0 .5rem; }
  p { margin: 0 0 1.5rem; opacity: .7; }
  a.button {
    display: inline-block; padding: .625rem 1rem; border-radius: .5rem;
    background: #1c1b1a; color: #fbfbfa; text-decoration: none;
    font-weight: 500;
  }
</style>
</head>
<body>
<main>
  <h1>Opening Control Center…</h1>
  <p>If nothing happened, Control Center may not be running on this machine.</p>
  <a class="button" href="$target">Open Control Center</a>
</main>
<script>location.replace(${jsonEncode(target)});</script>
</body>
</html>
''';

  /// `GET /oidc/login` — starts an SSO login by redirecting the browser to
  /// the issuer's authorization endpoint (state + PKCE held server-side).
  Future<void> _serveOidcLogin(HttpRequest request) async {
    final res = request.response;
    final sso = oidc;
    if (sso == null || !sso.config.enabled) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    try {
      final authorizationUrl = await sso.beginLogin(
        redirectUri: _oidcRedirectUri(request),
      );
      res
        ..statusCode = HttpStatus.found
        ..headers.set('Location', authorizationUrl.toString())
        ..headers.set('Cache-Control', 'no-store');
    } catch (e) {
      _w('OIDC login start failed: $e');
      res.statusCode = HttpStatus.badGateway;
    }
    await res.close();
  }

  /// `GET /oidc/callback` — completes the SSO login: exchanges the code,
  /// JIT-provisions the user, mints their device credential, and bounces the
  /// browser to the web client with the credential in the URL FRAGMENT (the
  /// same `s`/`i`/`k` form the web boot already reads; fragments never reach
  /// a server log).
  Future<void> _serveOidcCallback(HttpRequest request) async {
    final res = request.response;
    final sso = oidc;
    if (sso == null || !sso.config.enabled) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    try {
      final result = await sso.handleCallback(
        requestUri: request.uri,
        redirectUri: _oidcRedirectUri(request),
      );
      final origin = _requestOrigin(request);
      final fragment = base64Url
          .encode(
            utf8.encode(
              jsonEncode({'s': origin, 'i': result.deviceId, 'k': result.psk}),
            ),
          )
          .replaceAll('=', '');
      res
        ..statusCode = HttpStatus.found
        ..headers.set('Location', '/#$fragment')
        ..headers.set('Cache-Control', 'no-store');
    } catch (e) {
      _w('OIDC callback failed: $e');
      res
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.html
        ..write(
          '<html><body>Sign-in failed. Close this tab and try again.'
          '</body></html>',
        );
    }
    await res.close();
  }

  /// This server's own `/oidc/callback` URL as the issuer must call it.
  Uri _oidcRedirectUri(HttpRequest request) =>
      Uri.parse('${_requestOrigin(request)}/oidc/callback');

  String _requestOrigin(HttpRequest request) {
    final scheme = securityContext != null ? 'https' : 'http';
    final host =
        request.headers.value('host') ?? 'localhost:${_server?.port ?? port}';
    return '$scheme://$host';
  }

  /// Handles an inbound `POST /api/webhooks/tickets/<vendor>?ws=<workspaceId>`:
  /// reads the body + headers and delegates to [ticketWebhookHandler] (HMAC
  /// verification, parse, apply to the sync engine). The HMAC signature is the
  /// gate; the `ws` query only routes to the workspace's vendor config.
  Future<void> _serveTicketWebhook(HttpRequest request) async {
    final res = request.response;
    if (request.method != 'POST') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    final handler = ticketWebhookHandler;
    if (handler == null) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    // /api/webhooks/tickets/<vendor>
    final segments = request.uri.pathSegments;
    final vendor = segments.length >= 4 ? segments[3] : '';
    if (vendor.isEmpty) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    final workspaceId = request.uri.queryParameters['ws'];
    const maxBodyBytes = 1024 * 1024;
    final chunks = <int>[];
    await for (final chunk in request) {
      chunks.addAll(chunk);
      if (chunks.length > maxBodyBytes) {
        res.statusCode = HttpStatus.requestEntityTooLarge;
        await res.close();
        return;
      }
    }
    final body = utf8.decode(chunks, allowMalformed: true);
    final headers = <String, String>{};
    request.headers.forEach((name, values) {
      headers[name] = values.join(',');
    });
    try {
      final result = await handler(
        vendor: vendor,
        workspaceId: workspaceId,
        headers: headers,
        body: body,
      );
      res.statusCode = result.status;
      res.write(result.body);
    } on Object catch (e, st) {
      _e('ticket webhook handler failed', e, st);
      res.statusCode = HttpStatus.internalServerError;
      res.write('internal error');
    }
    await res.close();
  }

  /// Handles an inbound `POST /webhooks/<token>`: reads the body + headers and
  /// delegates to [webhookHandler] (signature verification, dedup, dispatch).
  /// The token is a per-trigger secret carried in the path; the handler resolves
  /// the workspace from it, so this route is intentionally unauthenticated at
  /// the transport layer (the HMAC signature is the gate).
  Future<void> _serveWebhook(HttpRequest request) async {
    final res = request.response;
    if (request.method != 'POST') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    final handler = webhookHandler;
    if (handler == null) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    final token = request.uri.pathSegments.length >= 2
        ? request.uri.pathSegments[1]
        : '';
    if (token.isEmpty) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    // Cap the body to guard against abusive payloads.
    const maxBodyBytes = 1024 * 1024;
    final chunks = <int>[];
    await for (final chunk in request) {
      chunks.addAll(chunk);
      if (chunks.length > maxBodyBytes) {
        res.statusCode = HttpStatus.requestEntityTooLarge;
        await res.close();
        return;
      }
    }
    final body = utf8.decode(chunks, allowMalformed: true);
    final headers = <String, String>{};
    request.headers.forEach((name, values) {
      headers[name] = values.join(',');
    });
    try {
      final result = await handler(token: token, headers: headers, body: body);
      res.statusCode = result.status;
      res.write(result.body);
    } on Object catch (e, st) {
      _e('webhook handler failed', e, st);
      res.statusCode = HttpStatus.internalServerError;
      res.write('internal error');
    }
    await res.close();
  }

  /// Streams a recorded meeting's mixed audio (`mixed.wav`) to a thin client for
  /// playback, with HTTP Range support so the player can seek.
  ///
  /// This is the byte path; the scrubber waveform + duration travel separately
  /// over the `meeting.audioClip` RPC. Both web and desktop play through this URL
  /// (built by `MediaProxyConfig.meetingAudioUrl`), so playback works the same
  /// whether the server is loopback-local or a remote instance — the file never
  /// has to be on the client's own disk.
  ///
  /// Auth mirrors `/proxy/media`: the caller signs the canonical target
  /// `meeting-audio:<workspaceId>/<meetingId>` with its device PSK
  /// ([RemoteControlCrypto.signProxyTarget]); the signature is re-derived from
  /// the stored PSK of an `active`, unexpired device. Ownership is enforced by
  /// [meetingAudio], which resolves the file only when the meeting belongs to the
  /// signed `workspaceId` (a foreign meeting is simply not found → 404).
  Future<void> _serveMeetingAudio(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }

    final q = request.uri.queryParameters;
    final workspaceId = q['w'];
    final meetingId = q['m'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (workspaceId == null ||
        meetingId == null ||
        deviceId == null ||
        sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }

    final target = 'meeting-audio:$workspaceId/$meetingId';
    final psk = await _activeDevicePsk(deviceId);
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final resolver = meetingAudio;
    if (resolver == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    File? file;
    try {
      file = await resolver(workspaceId: workspaceId, meetingId: meetingId);
    } catch (e) {
      _w('meeting audio resolve failed for $meetingId: $e');
      await _closeProxy(res, HttpStatus.internalServerError);
      return;
    }
    if (file == null || !file.existsSync()) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    await _serveFileWithRange(request, file, 'audio/wav');
  }

  /// Serves a workspace's persisted logo image over `/workspace/logo` so a thin
  /// client never reads the SERVER's disk directly — the workspace mark renders
  /// identically on desktop, web, and remote. Built by
  /// `MediaProxyConfig.workspaceLogoUrl`.
  ///
  /// Auth mirrors `/meeting/audio`: the caller signs the canonical target
  /// `workspace-logo:<workspaceId>` with its device PSK
  /// ([RemoteControlCrypto.signProxyTarget]); the signature is re-derived from
  /// the stored PSK of an `active`, unexpired device. Ownership is enforced by
  /// [workspaceLogo], which resolves the file only for the signed `workspaceId`
  /// (a foreign workspace is simply not found → 404).
  Future<void> _serveWorkspaceLogo(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }

    final q = request.uri.queryParameters;
    final workspaceId = q['w'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (workspaceId == null || deviceId == null || sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }

    final target = 'workspace-logo:$workspaceId';
    final psk = await _activeDevicePsk(deviceId);
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final resolver = workspaceLogo;
    if (resolver == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    File? file;
    try {
      file = await resolver(workspaceId: workspaceId);
    } catch (e) {
      _w('workspace logo resolve failed for $workspaceId: $e');
      await _closeProxy(res, HttpStatus.internalServerError);
      return;
    }
    if (file == null || !file.existsSync()) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    await _serveFileWithRange(request, file, _logoContentType(file.path));
  }

  /// Serves one variant of a selectable font family over `/proxy/font` so a
  /// client can register it with Flutter's font loader — built by
  /// `MediaProxyConfig.fontUrl`.
  ///
  /// WHY THE HOST IS IN THIS PATH AT ALL: Skia decodes `ttf`/`otf`, not `woff2`,
  /// and font upstreams choose the format from the request's `User-Agent` —
  /// which a browser `fetch()` cannot set. So a client physically cannot obtain
  /// bytes it can render; the host can, and caches them once for every client.
  ///
  /// Auth mirrors `/workspace/logo`: the caller signs the canonical target
  /// `font:<family>/<subset>/<weight>/<style>` with its device PSK
  /// ([RemoteControlCrypto.signProxyTarget]). Note what is NOT in the request: a
  /// URL. [fontFile] mints one only for a family in the host's catalogue, so
  /// this route has no SSRF surface to blocklist — an uncatalogued family is
  /// simply a 404.
  Future<void> _serveFontProxy(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }

    final q = request.uri.queryParameters;
    final family = q['f'];
    final weightRaw = q['wt'];
    final style = q['st'];
    final subset = q['sub'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (family == null ||
        weightRaw == null ||
        style == null ||
        subset == null ||
        deviceId == null ||
        sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }
    final weight = int.tryParse(weightRaw);
    if (weight == null ||
        weight < 1 ||
        weight > 1000 ||
        (style != 'normal' && style != 'italic')) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }

    final target = 'font:$family/$subset/$weight/$style';
    final psk = await _activeDevicePsk(deviceId);
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final resolver = fontFile;
    if (resolver == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    Uri? upstream;
    try {
      upstream = await resolver(
        family: family,
        weight: weight,
        italic: style == 'italic',
        subset: subset,
      );
    } catch (e) {
      _w('font resolve failed for $family: $e');
      await _closeProxy(res, HttpStatus.internalServerError);
      return;
    }
    if (upstream == null) {
      // Not a catalogued family — the client's family name was a system font,
      // or the catalogue has not loaded yet.
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }

    final cache = _fontCache;
    if (cache != null) {
      try {
        final resolution = await cache.resolve(
          MediaCache.keyFor(upstream.toString(), null),
          ({etag, lastModified}) => _fetchMediaForCache(
            upstream!,
            maxWidth: null,
            etag: etag,
            lastModified: lastModified,
            // A font is not an image, so without this it would stream through
            // as a passthrough and never be stored — every client would then
            // re-fetch it from the CDN.
            alwaysBuffer: true,
            bufferCap: _maxFontBytes,
          ),
        );
        switch (resolution) {
          case MediaCacheHit(:final bodyFile, :final contentType):
            await _serveBufferedMedia(
              res,
              contentType,
              await bodyFile.readAsBytes(),
            );
            return;
          case MediaCacheUncached(:final bytes, :final contentType):
            await _serveBufferedMedia(res, contentType, bytes);
            return;
          case MediaCachePassthrough(:final outcome):
            await _relayMediaStream(res, outcome.response, outcome.client);
            return;
          case MediaCacheFailure():
            await _closeProxy(res, HttpStatus.badGateway);
            return;
        }
      } catch (e) {
        // The cache must never take the route down — fall through to a direct
        // fetch below.
        _w('Font cache path failed for $family: $e');
      }
    }

    final outcome = await _fetchMediaForCache(
      upstream,
      maxWidth: null,
      alwaysBuffer: true,
      bufferCap: _maxFontBytes,
    );
    switch (outcome) {
      case MediaFetchBuffered(:final bytes, :final contentType):
        await _serveBufferedMedia(res, contentType, bytes);
      case MediaFetchStream(:final response, :final client):
        await _relayMediaStream(res, response, client);
      case MediaFetchNotModified():
        // Unreachable: no conditional headers are sent on this path.
        await _closeProxy(res, HttpStatus.badGateway);
      case MediaFetchFailed():
        await _closeProxy(res, HttpStatus.badGateway);
    }
  }

  /// Size ceiling for one font file. A static variant of a text family is tens
  /// to a few hundred KB; even a full CJK face stays well under this, and the
  /// bytes are buffered in memory, so the cap is what keeps a wrong upstream
  /// from being read into the server's heap.
  static const _maxFontBytes = 16 * 1024 * 1024;

  /// Maps a logo file's extension to its MIME type (defaults to a generic
  /// binary type for unknown extensions). Logos are small images picked by the
  /// user, so the set is bounded.
  String _logoContentType(String path) {
    final ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.png' => 'image/png',
      '.jpg' || '.jpeg' || '.jfif' => 'image/jpeg',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      '.svg' => 'image/svg+xml',
      '.bmp' => 'image/bmp',
      '.ico' => 'image/x-icon',
      _ => 'application/octet-stream',
    };
  }

  /// Streams a soundscape's continuous generated MP3 over `/soundscape/stream`
  /// as an open-ended `audio/mpeg` body (the internet-radio pattern) — the
  /// primary transport for desktop + web. There is no `Content-Length` and no
  /// Range support: it is a live stream, not a seekable file, so the client
  /// treats it as radio (no scrubber). Auth mirrors `/meeting/audio`: the caller
  /// signs `soundscape:<workspaceId>/<mood>` with its device PSK. Attaching the
  /// response consumes a hub consumer for the shared `(workspaceId, mood)`
  /// session; a client disconnect cancels the source subscription, which
  /// detaches the consumer (and reaps the session when the last one leaves).
  Future<void> _serveSoundscapeStream(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    final q = request.uri.queryParameters;
    final workspaceId = q['w'];
    final mood = q['mood'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (workspaceId == null ||
        mood == null ||
        deviceId == null ||
        sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }
    final target = 'soundscape:$workspaceId/$mood';
    final psk = await _activeDevicePsk(deviceId);
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    final resolver = soundscapeStream;
    Stream<List<int>>? stream;
    try {
      stream = resolver?.call(workspaceId: workspaceId, mood: mood);
    } on Object catch (e, st) {
      // The hub creates the MP3 encoder here, and `liblame_ffi` is a REQUIRED
      // native — so a broken install throws instead of degrading. Answer 500
      // (not the 404 that means "no engine on this host", and not a hang: this
      // handler's throw would otherwise escape into an unhandled async error
      // and leave the request open until the client times out).
      _e('soundscape stream failed for $workspaceId/$mood: $e', e, st);
      await _closeProxy(res, HttpStatus.internalServerError);
      return;
    }
    if (stream == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    res.statusCode = HttpStatus.ok;
    res.headers
      ..contentType = ContentType('audio', 'mpeg')
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      // No Content-Length: dart:io then uses chunked transfer for the
      // open-ended body, which is what every progressive-MP3 player expects.
      ..set(HttpHeaders.connectionHeader, 'keep-alive');
    try {
      // addStream cancels its source subscription when the socket errors
      // (client disconnect), which fires the hub consumer's onCancel → detach.
      await res.addStream(stream);
    } catch (_) {
      // Client disconnected mid-stream — the source was cancelled; nothing else.
    }
    try {
      await res.close();
    } catch (_) {}
  }

  /// Serves the live HLS media playlist for a soundscape `(workspaceId, mood)`
  /// over `/soundscape/playlist.m3u8` — the transport the mobile PWA uses for
  /// native background/lock-screen playback and any relay-only client. Each
  /// segment URI in the playlist carries the same signed query, so this one
  /// signature authorizes the playlist and every segment it references.
  Future<void> _serveSoundscapePlaylist(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    final q = request.uri.queryParameters;
    final workspaceId = q['w'];
    final mood = q['mood'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (workspaceId == null ||
        mood == null ||
        deviceId == null ||
        sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }
    final target = 'soundscape:$workspaceId/$mood';
    final psk = await _activeDevicePsk(deviceId);
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    final resolver = soundscapePlaylist;
    // Re-encode the auth query so the relative `seg?…` URIs the segmenter emits
    // resolve to `/soundscape/seg?…` carrying the same device + signature.
    final segmentQuery = Uri(
      queryParameters: {
        'w': workspaceId,
        'mood': mood,
        'd': deviceId,
        's': sig,
      },
    ).query;
    final playlist = resolver?.call(
      workspaceId: workspaceId,
      mood: mood,
      segmentQuery: segmentQuery,
    );
    if (playlist == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    res
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType('application', 'vnd.apple.mpegurl')
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
      ..write(playlist);
    await res.close();
  }

  /// Serves one HLS segment's MP3 bytes over `/soundscape/seg?…&n=<index>`.
  Future<void> _serveSoundscapeSegment(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    final q = request.uri.queryParameters;
    final workspaceId = q['w'];
    final mood = q['mood'];
    final deviceId = q['d'];
    final sig = q['s'];
    final index = int.tryParse(q['n'] ?? '');
    if (workspaceId == null ||
        mood == null ||
        deviceId == null ||
        sig == null ||
        index == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }
    final target = 'soundscape:$workspaceId/$mood';
    final psk = await _activeDevicePsk(deviceId);
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    final resolver = soundscapeSegment;
    final bytes = resolver?.call(
      workspaceId: workspaceId,
      mood: mood,
      index: index,
    );
    if (bytes == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    res
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType('audio', 'mpeg')
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
      ..add(bytes);
    await res.close();
  }

  /// Streams [file] to [request] as [contentType], honoring a single-range
  /// `Range: bytes=` request with a `206 Partial Content` reply (so an
  /// `<audio>`/AVPlayer can seek). A missing/blank/whole-file request gets a
  /// plain `200`. CORS headers are already set by the caller.
  ///
  /// The reply is HTTP-cacheable: an `ETag` (`"<size>-<mtime>"`) +
  /// `Last-Modified` + a 1h `private` max-age. The web tier otherwise
  /// re-fetches the workspace logo on EVERY render (no caching headers meant
  /// no browser cache); with validators a repeat costs one cheap conditional
  /// `304`, and a changed logo (new mtime/size) still revalidates correctly.
  Future<void> _serveFileWithRange(
    HttpRequest request,
    File file,
    String contentType,
  ) async {
    final res = request.response;
    final stat = file.statSync();
    final length = stat.size;
    final etag = '"$length-${stat.modified.millisecondsSinceEpoch}"';
    res.headers
      ..set(HttpHeaders.acceptRangesHeader, 'bytes')
      ..set(HttpHeaders.etagHeader, etag)
      ..set(HttpHeaders.lastModifiedHeader, HttpDate.format(stat.modified))
      // `private`: the URL is per-device signed — shared caches must not store
      // it. 1h bounds how long a REPLACED logo can linger.
      ..set('Cache-Control', 'private, max-age=3600')
      ..contentType = ContentType.parse(contentType);

    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);

    // Conditional GET (non-range only): unchanged file → cheap 304.
    if (rangeHeader == null) {
      final ifNoneMatch = request.headers.value(HttpHeaders.ifNoneMatchHeader);
      if (ifNoneMatch != null &&
          ifNoneMatch.split(',').map((t) => t.trim()).contains(etag)) {
        res.statusCode = HttpStatus.notModified;
        await res.close();
        return;
      }
    }
    final range = rangeHeader == null
        ? null
        : _parseSingleRange(rangeHeader, length);
    try {
      if (rangeHeader != null && range == null) {
        // A Range header was sent but is unsatisfiable for this length.
        res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        res.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$length');
        await res.close();
        return;
      }
      if (range != null) {
        final (start, end) = range;
        res.statusCode = HttpStatus.partialContent;
        res.headers
          ..set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$length')
          ..contentLength = end - start + 1;
        await res.addStream(file.openRead(start, end + 1));
      } else {
        res.statusCode = HttpStatus.ok;
        res.headers.contentLength = length;
        await res.addStream(file.openRead());
      }
      await res.close();
    } catch (_) {
      // Client disconnected mid-stream — nothing to do.
    }
  }

  /// Parses a single HTTP byte range (`bytes=start-end`, `bytes=start-`, or
  /// `bytes=-suffix`) against a file of [length] bytes, returning the inclusive
  /// `(start, end)` or null when absent/multi-range/unsatisfiable. Multi-range
  /// requests are deliberately unsupported (one contiguous range covers media
  /// seeking).
  (int, int)? _parseSingleRange(String header, int length) {
    if (length <= 0 || !header.startsWith('bytes=')) {
      return null;
    }
    final spec = header.substring('bytes='.length);
    if (spec.contains(',') || !spec.contains('-')) {
      return null;
    }
    final dash = spec.indexOf('-');
    final startStr = spec.substring(0, dash).trim();
    final endStr = spec.substring(dash + 1).trim();
    int start;
    int end;
    if (startStr.isEmpty) {
      // Suffix range: the last `suffix` bytes.
      final suffix = int.tryParse(endStr);
      if (suffix == null || suffix <= 0) {
        return null;
      }
      start = suffix >= length ? 0 : length - suffix;
      end = length - 1;
    } else {
      final s = int.tryParse(startStr);
      if (s == null || s >= length) {
        return null;
      }
      start = s;
      end = endStr.isEmpty ? length - 1 : (int.tryParse(endStr) ?? length - 1);
      if (end >= length) {
        end = length - 1;
      }
    }
    if (start > end) {
      return null;
    }
    return (start, end);
  }

  /// Fetches and relays a remote **media** asset (image, favicon, audio, video,
  /// document, …) so a thin client can render it without touching the upstream
  /// host directly — the north-star invariant that every outbound fetch goes
  /// through `cc_server`.
  ///
  /// Why this exists: a Flutter-web build draws images through CanvasKit, which
  /// downloads the bytes via `fetch` — a CORS-gated request. Arbitrary feed /
  /// avatar / attachment hosts send no `Access-Control-Allow-Origin`, so the
  /// browser refuses the bytes and every remote asset fails. The server (no
  /// CORS) fetches the bytes and re-serves them with permissive CORS headers
  /// from the very origin the client is already paired with. The native desktop
  /// is now a thin client too (it talks to a loopback `cc_server`), so it routes
  /// media through here as well — keeping all outbound fetches server-side.
  ///
  /// Not an open relay: the URL is signed with the caller's device PSK
  /// ([RemoteControlCrypto.signProxyTarget]). We re-derive the signature from
  /// the stored PSK of an `active`, unexpired device before fetching, so only an
  /// authenticated client can drive a fetch — and only to the exact URL it
  /// signed. A blocklist additionally refuses loopback / link-local / private
  /// targets so a signed URL can't be aimed at the host's own internal network.
  ///
  /// Range requests are forwarded to the upstream and the `206 Partial Content`
  /// reply (with `Content-Range`/`Accept-Ranges`) is relayed verbatim, so a
  /// `<video>`/`VideoPlayer` can seek through a proxied movie. The image-only
  /// transforms (ICO→PNG transcode, `w` downscale) are skipped for ranged or
  /// non-image bodies so audio/video/documents stream untouched.
  ///
  /// Non-ranged image fetches are served through a persistent disk cache
  /// ([MediaCache], wired via [mediaCacheDir]): a repeat of the same `(url, w)`
  /// is a loopback disk read, stale entries are revalidated with a conditional
  /// GET when the upstream gave validators, and a failed refresh serves stale
  /// rather than erroring. The cache sits BEHIND signature verification, so it
  /// never widens what a client can fetch.
  Future<void> _serveMediaProxy(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }

    final q = request.uri.queryParameters;
    final encoded = q['u'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (encoded == null || deviceId == null || sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }
    // Optional, UNSIGNED downscale hint: resize the proxy's own output to at
    // most `w` device pixels wide. It only narrows already-authorised output,
    // so it is deliberately outside the signature (see MediaProxyConfig.resolve)
    // and clamped to a sane range here. Ignored for ranged / non-image bodies.
    final wParam = int.tryParse(q['w'] ?? '');
    final maxWidth = wParam?.clamp(8, 2048).toInt();
    String rawUrl;
    try {
      // The client encodes with `base64Url.encode` (padding kept; the query
      // codec round-trips the `=`), so a plain decode is exact.
      rawUrl = utf8.decode(base64Url.decode(encoded));
    } catch (_) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }

    final psk = await _activeDevicePsk(deviceId);
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(rawUrl, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final target = Uri.tryParse(rawUrl);
    if (target == null ||
        (target.scheme != 'http' && target.scheme != 'https')) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }
    if (isBlockedProxyTarget(target)) {
      _w('Media proxy refusing blocked target host: ${target.host}');
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    // A `Range` request (video seeking, resumable downloads) is forwarded to the
    // upstream and the partial reply relayed; the image transforms below never
    // touch a ranged body. Audio/video can be large, so the cap is generous.
    final clientRange = request.headers.value(HttpHeaders.rangeHeader);
    const maxBytes = 96 * 1024 * 1024;

    // Disk-cache path (non-ranged only): a repeat of the same `(url, w)` is a
    // loopback disk read instead of a full upstream round trip — see
    // [MediaCache]. A ranged body is a slice, not the asset, so it never
    // enters the cache.
    final cache = _mediaCache;
    if (cache != null && (clientRange == null || clientRange.isEmpty)) {
      try {
        final resolution = await cache.resolve(
          MediaCache.keyFor(rawUrl, maxWidth),
          ({etag, lastModified}) => _fetchMediaForCache(
            target,
            maxWidth: maxWidth,
            etag: etag,
            lastModified: lastModified,
          ),
        );
        switch (resolution) {
          case MediaCacheHit(:final bodyFile, :final contentType):
            await _serveBufferedMedia(
              res,
              contentType,
              await bodyFile.readAsBytes(),
            );
            return;
          case MediaCacheUncached(:final bytes, :final contentType):
            await _serveBufferedMedia(res, contentType, bytes);
            return;
          case MediaCachePassthrough(:final outcome):
            await _relayMediaStream(res, outcome.response, outcome.client);
            return;
          case MediaCacheFailure():
            await _closeProxy(res, HttpStatus.badGateway);
            return;
        }
      } catch (e) {
        // The cache must never take the proxy down — fall through to the
        // direct upstream fetch below.
        _w('Media cache path failed for ${target.host}: $e');
      }
    }

    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..userAgent = 'control-center-media-proxy';
      final opened = await _openUpstream(client, target, range: clientRange);
      switch (opened) {
        case _UpstreamError(:final statusCode):
          await _closeProxy(res, statusCode);
          return;
        case _UpstreamNotModified():
          // Unreachable: the direct path never sends conditional headers.
          await _closeProxy(res, HttpStatus.badGateway);
          return;
        case _UpstreamOk(:final response, :final finalUri):
          final upstream = response;
          if (upstream.statusCode >= 400 || upstream.contentLength > maxBytes) {
            await _closeProxy(res, HttpStatus.badGateway);
            return;
          }

          final isRanged =
              upstream.statusCode == HttpStatus.partialContent ||
              (clientRange != null && clientRange.isNotEmpty);

          // Image-only transforms apply only to a full (non-ranged) response.
          if (!isRanged) {
            // Newsfeed source icons resolve to `<host>/favicon.ico`, and a
            // favicon is almost always ICO — a format the web client's
            // CanvasKit renderer cannot decode, so it would fail to paint even
            // once the bytes arrive. Detect those (by `.ico` path or an icon
            // content-type), buffer them, and transcode to PNG. Everything else
            // streams straight through.
            final looksLikeIcon =
                finalUri.path.toLowerCase().endsWith('.ico') ||
                _isIconContentType(upstream.headers.contentType);
            if (looksLikeIcon) {
              final bytes = await _readCapped(upstream, maxBytes);
              if (bytes == null) {
                await _closeProxy(res, HttpStatus.badGateway);
                return;
              }
              // If it really is ICO, hand the client PNG; if the `.ico` URL
              // actually served a renderable format already (some hosts do),
              // pass it through.
              final png = transcodeIcoToPng(bytes);
              final source = png ?? bytes;
              final resized = maxWidth != null
                  ? resizeRasterToWidth(source, maxWidth)
                  : null;
              await _serveBufferedMedia(
                res,
                resized?.mimeType ??
                    (png != null
                        ? 'image/png'
                        : (upstream.headers.contentType?.toString() ??
                              'application/octet-stream')),
                resized?.bytes ?? source,
              );
              return;
            }
            // With a downscale hint we must buffer to decode/resize; without
            // one we keep the zero-copy streaming path. A
            // non-raster/animated/already-small body falls through to the
            // original bytes so an asset is never dropped because resize
            // couldn't run (e.g. it isn't an image at all).
            if (maxWidth != null) {
              final raw = await _readCapped(upstream, maxBytes);
              if (raw == null) {
                await _closeProxy(res, HttpStatus.badGateway);
                return;
              }
              final resized = resizeRasterToWidth(raw, maxWidth);
              await _serveBufferedMedia(
                res,
                resized?.mimeType ??
                    (upstream.headers.contentType?.toString() ??
                        'application/octet-stream'),
                resized?.bytes ?? raw,
              );
              return;
            }
          }

          // Stream-through path (full bodies of any media type, and every
          // ranged response). Ownership of the client moves to the relayer.
          final relayClient = client;
          client = null;
          await _relayMediaStream(res, upstream, relayClient);
          return;
      }
    } catch (e) {
      _w('Media proxy fetch failed for ${target.host}: $e');
      await _closeProxy(res, HttpStatus.badGateway);
    } finally {
      client?.close(force: true);
    }
  }

  /// One upstream fetch for the media cache: buffers image bodies (applying
  /// the ICO→PNG transcode / `w` downscale) and reports anything else as an
  /// open stream for zero-copy relay. Never writes to the client response —
  /// every result is a [MediaFetchOutcome] the cache maps to a serve / store /
  /// revalidate decision. [etag] / [lastModified] turn the request
  /// conditional for revalidation of a stale entry.
  /// Fetches [target] for the caching proxies.
  ///
  /// [alwaysBuffer] forces a body that is not an image to be read into memory
  /// rather than streamed. Streaming is right for media (a 90-minute recording
  /// must not be buffered) but wrong for a font: [MediaCache] can only store a
  /// BUFFERED outcome, so streaming one means every client re-fetches it from
  /// the upstream CDN forever. Callers that pass this must know the body is
  /// small; [bufferCap] bounds it regardless.
  Future<MediaFetchOutcome> _fetchMediaForCache(
    Uri target, {
    required int? maxWidth,
    String? etag,
    String? lastModified,
    bool alwaysBuffer = false,
    int bufferCap = 96 * 1024 * 1024,
  }) async {
    final maxBytes = bufferCap;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..userAgent = 'control-center-media-proxy';
    var transferred = false;
    try {
      final opened = await _openUpstream(
        client,
        target,
        etag: etag,
        lastModified: lastModified,
      );
      switch (opened) {
        case _UpstreamError():
          return const MediaFetchFailed();
        case _UpstreamNotModified():
          return const MediaFetchNotModified();
        case _UpstreamOk(:final response, :final finalUri):
          final upstream = response;
          if (upstream.statusCode >= 400 || upstream.contentLength > maxBytes) {
            await upstream.drain<void>();
            return const MediaFetchFailed();
          }
          final looksLikeIcon =
              finalUri.path.toLowerCase().endsWith('.ico') ||
              _isIconContentType(upstream.headers.contentType);
          final isImage =
              looksLikeIcon ||
              (upstream.headers.contentType?.mimeType.toLowerCase().startsWith(
                    'image/',
                  ) ??
                  false);
          if (!isImage && maxWidth == null && !alwaysBuffer) {
            // A non-image full body (audio/video/documents) streams zero-copy
            // and is never cached. Ownership of client + response moves to
            // the relayer.
            transferred = true;
            return MediaFetchStream(upstream, client);
          }
          final raw = await _readCapped(upstream, maxBytes);
          if (raw == null) {
            return const MediaFetchFailed();
          }
          final String contentType;
          final List<int> body;
          if (looksLikeIcon) {
            final png = transcodeIcoToPng(raw);
            final source = png ?? raw;
            final resized = maxWidth != null
                ? resizeRasterToWidth(source, maxWidth)
                : null;
            body = resized?.bytes ?? source;
            contentType =
                resized?.mimeType ??
                (png != null
                    ? 'image/png'
                    : (upstream.headers.contentType?.toString() ??
                          'application/octet-stream'));
          } else {
            final resized = maxWidth != null
                ? resizeRasterToWidth(raw, maxWidth)
                : null;
            body = resized?.bytes ?? raw;
            contentType =
                resized?.mimeType ??
                (upstream.headers.contentType?.toString() ??
                    'application/octet-stream');
          }
          final cacheControl = upstreamCacheControlValue(upstream.headers);
          return MediaFetchBuffered(
            bytes: body,
            contentType: contentType,
            etag: firstUpstreamHeaderValue(
              upstream.headers,
              HttpHeaders.etagHeader,
            ),
            lastModified: firstUpstreamHeaderValue(
              upstream.headers,
              HttpHeaders.lastModifiedHeader,
            ),
            maxAgeSeconds: _parseMaxAgeSeconds(cacheControl),
            cache: !_forbidsStoring(cacheControl),
          );
      }
    } catch (e) {
      _w('Media proxy fetch failed for ${target.host}: $e');
      return const MediaFetchFailed();
    } finally {
      if (!transferred) {
        client.close(force: true);
      }
    }
  }

  /// Opens [target] on [client], following redirects MANUALLY so every hop is
  /// re-validated against the SSRF block list. `followRedirects: true` only
  /// vets the initial target — an authorised signed URL to a benign host could
  /// still 3xx toward an internal address (169.254.169.254, 10.x, …), which
  /// HttpClient would then fetch unchecked. We resolve each Location, reject
  /// non-http(s) and blocked hosts, and cap the hop count ourselves.
  ///
  /// [range] forwards a single `Range` header (video seeking); [etag] /
  /// [lastModified] make the request conditional (media-cache revalidation) —
  /// a `304` is then reported as [_UpstreamNotModified], never relayed.
  Future<_UpstreamOpen> _openUpstream(
    HttpClient client,
    Uri target, {
    String? range,
    String? etag,
    String? lastModified,
  }) async {
    var current = target;
    for (var hop = 0; ; hop++) {
      final req = (await client.getUrl(current))
        ..followRedirects = false
        ..headers.set(HttpHeaders.acceptHeader, '*/*');
      if (range != null && range.isNotEmpty) {
        req.headers.set(HttpHeaders.rangeHeader, range);
      }
      if (etag != null && etag.isNotEmpty) {
        req.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
      }
      if (lastModified != null && lastModified.isNotEmpty) {
        req.headers.set(HttpHeaders.ifModifiedSinceHeader, lastModified);
      }
      final upstream = await req.close().timeout(const Duration(seconds: 20));
      if (upstream.statusCode == HttpStatus.notModified &&
          (etag != null || lastModified != null)) {
        await upstream.drain<void>();
        return const _UpstreamNotModified();
      }
      if (!upstream.isRedirect) {
        return _UpstreamOk(upstream, current);
      }
      // Drain the redirect body so the connection can be reused/closed.
      await upstream.drain<void>();
      if (hop >= 3) {
        _w('Media proxy exceeded redirect budget for ${target.host}');
        return const _UpstreamError(HttpStatus.badGateway);
      }
      final loc = firstUpstreamHeaderValue(
        upstream.headers,
        HttpHeaders.locationHeader,
      );
      if (loc == null || loc.isEmpty) {
        return const _UpstreamError(HttpStatus.badGateway);
      }
      final next = current.resolve(loc);
      if (next.scheme != 'http' && next.scheme != 'https') {
        return const _UpstreamError(HttpStatus.badRequest);
      }
      if (isBlockedProxyTarget(next)) {
        _w('Media proxy refusing blocked redirect host: ${next.host}');
        return const _UpstreamError(HttpStatus.forbidden);
      }
      current = next;
    }
  }

  /// Writes a buffered media body (cached, revalidated, or freshly fetched)
  /// to [res] with the proxy's standard cache/nosniff headers.
  Future<void> _serveBufferedMedia(
    HttpResponse res,
    String contentType,
    List<int> bytes,
  ) async {
    ContentType parsed;
    try {
      parsed = ContentType.parse(contentType);
    } on FormatException {
      parsed = ContentType('application', 'octet-stream');
    }
    res
      ..statusCode = HttpStatus.ok
      ..headers.contentType = parsed
      // The signed URL embeds the source, so a changed source produces a new
      // URL — safe to cache hard.
      ..headers.set('Cache-Control', 'public, max-age=86400')
      ..headers.set('X-Content-Type-Options', 'nosniff')
      ..add(bytes);
    await res.close();
  }

  /// Relays an open [upstream] response to [res] zero-copy — full bodies of
  /// any media type and every ranged response — forwarding the status (200 or
  /// 206) plus the range/length headers a media player needs to seek. Closes
  /// [client] when done (ownership transferred from the caller).
  Future<void> _relayMediaStream(
    HttpResponse res,
    HttpClientResponse upstream,
    HttpClient client,
  ) async {
    const maxBytes = 96 * 1024 * 1024;
    try {
      res
        ..statusCode = upstream.statusCode
        ..headers.contentType =
            upstream.headers.contentType ??
            ContentType('application', 'octet-stream')
        // The signed URL embeds the source, so a changed source produces a new
        // URL — safe to cache hard.
        ..headers.set('Cache-Control', 'public, max-age=86400')
        ..headers.set('X-Content-Type-Options', 'nosniff')
        ..headers.set('Accept-Ranges', 'bytes');
      final contentRange = firstUpstreamHeaderValue(
        upstream.headers,
        HttpHeaders.contentRangeHeader,
      );
      if (contentRange != null) {
        res.headers.set(HttpHeaders.contentRangeHeader, contentRange);
      }
      var total = 0;
      await for (final chunk in upstream) {
        total += chunk.length;
        if (total > maxBytes) {
          // Past the cap mid-stream (chunked, no content-length) — abort the
          // connection rather than serve a truncated, oversized payload.
          await res.close();
          return;
        }
        res.add(chunk);
      }
      await res.close();
    } finally {
      client.close(force: true);
    }
  }

  /// The `max-age` (or `s-maxage`) directive of a `Cache-Control` value, or
  /// null when absent/unparseable (the cache then applies its default TTL).
  int? _parseMaxAgeSeconds(String? cacheControl) {
    if (cacheControl == null) {
      return null;
    }
    final match = RegExp(
      r'(?:^|,)\s*(?:s-maxage|max-age)\s*=\s*(\d+)',
    ).firstMatch(cacheControl.toLowerCase());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// Whether an upstream `Cache-Control` forbids persisting the body
  /// (`no-store`, or `private` — a per-user response a shared server cache
  /// must not retain).
  bool _forbidsStoring(String? cacheControl) {
    if (cacheControl == null) {
      return false;
    }
    final value = cacheControl.toLowerCase();
    return value.contains('no-store') || value.contains('private');
  }

  /// Reverse-proxies `/proxy/vscode/<sid>/<rest...>` to the loopbound
  /// code-server for session `<sid>` (HTTP pass-through + WebSocket upgrade),
  /// capability-authorizing each request: `<sid>` must be a live session owned
  /// by the connected device's workspace, else 403 (loud deny). See the plan's
  /// § Architecture / § Workspace isolation & security.
  ///
  /// Strips the `/proxy/vscode/<sid>` prefix and the frame-blocking headers
  /// (`X-Frame-Options`, CSP `frame-ancestors`) so the editor can render framed
  /// in the app; forwards method + headers + body and streams the response back
  /// (never buffers — code-server is chatty). WebSocket upgrades are bridged
  /// bidirectionally (the extension host, integrated terminal, LSP results, and
  /// file watcher all ride WS).
  Future<void> _serveCodeServerProxy(HttpRequest request) async {
    final res = request.response;
    final lookup = codeServerLookup;
    if (lookup == null) {
      // No code-server capability on this host — honest 404, not a silent fall
      // through to the static bundle (which would mask the route as a SPA).
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }

    // Parse `<sid>/<rest>` from the path after `/proxy/vscode/`.
    final segments = request.uri.path.substring('/proxy/vscode/'.length);
    final slash = segments.indexOf('/');
    final sid = slash < 0 ? segments : segments.substring(0, slash);
    final rest = slash < 0 ? '' : segments.substring(slash);
    if (sid.isEmpty) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    final session = lookup(sid);
    if (session == null) {
      // Unknown / expired / foreign-workspace capability → loud 403.
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    // Bridge-extension report endpoint: the in-editor bridge POSTs the file the
    // user navigated to (or a dirty-state change) here (authorized by the same
    // capability). It is NOT a code-server path, so handle it locally.
    if (rest == '/__cc_open__') {
      await _handleCodeServerOpenReport(request, res, sid);
      return;
    }

    // Reverse command channel: the bridge extension opens this as a long-lived
    // SSE stream and executes the `{cmd, …}` events we push (e.g. Save-on-close).
    if (rest == '/__cc_commands__') {
      await _handleCodeServerCommandStream(res, sid);
      return;
    }

    final upstreamBase = 'http://127.0.0.1:${session.port}';
    final upstreamPath = rest.isEmpty ? '/' : rest;
    final upstreamUri = Uri.parse('$upstreamBase$upstreamPath');
    // Re-attach the query string (code-server uses it for assets + the WS
    // session ticket).
    final target = request.uri.query.isEmpty
        ? upstreamUri
        : upstreamUri.replace(query: request.uri.query);

    // WebSocket upgrade → bridge bidirectionally rather than terminate locally.
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      await _bridgeCodeServerWebSocket(request, sid, target);
      return;
    }

    // Plain HTTP pass-through.
    await _forwardCodeServerHttp(request, res, target);
  }

  /// Handles a bridge-extension report POSTed to
  /// `/proxy/vscode/<sid>/__cc_open__`. The session [sid] is already validated
  /// (capability authz) by the caller. Reads `{path, …}` from the JSON body and,
  /// depending on `type`, either fans out a dirty-state change (`type:'dirty'` →
  /// [codeServerReportDirty]) or an "open this file as a new app tab" request
  /// (absent / any other type → [codeServerReport]). Always 200s (the report is
  /// best-effort fire-and-forget from the extension's side).
  Future<void> _handleCodeServerOpenReport(
    HttpRequest request,
    HttpResponse res,
    String sid,
  ) async {
    try {
      if (request.method == 'POST') {
        final body = await utf8.decoder
            .bind(request)
            .join()
            .timeout(const Duration(seconds: 5));
        final decoded = body.isEmpty ? null : jsonDecode(body);
        if (decoded is Map) {
          final path = decoded['path'];
          if (path is String && path.isNotEmpty) {
            if (decoded['type'] == 'dirty') {
              codeServerReportDirty?.call(sid, path, decoded['dirty'] == true);
            } else {
              final rawLine = decoded['line'];
              final line = rawLine is num ? rawLine.toInt() : null;
              codeServerReport?.call(sid, path, line);
            }
          }
        }
      }
    } catch (_) {
      // Best-effort — a malformed report never breaks the editor.
    }
    res.statusCode = HttpStatus.noContent;
    // The report is a same-machine loopback POST from the extension, but set a
    // permissive CORS header anyway so a future in-page (worker) caller works.
    res.headers.set('Access-Control-Allow-Origin', '*');
    await res.close();
  }

  /// Serves the reverse command channel at `/proxy/vscode/<sid>/__cc_commands__`
  /// as Server-Sent Events. The bridge extension holds this open; each
  /// [CodeServerCommandStreamResolver] event is written as one `data: <json>`
  /// frame. Ends when the session's command stream closes (process death) or the
  /// socket drops. The session [sid] is already capability-validated by the
  /// caller; a host without code-server (`codeServerCommandStream == null`) 404s.
  Future<void> _handleCodeServerCommandStream(
    HttpResponse res,
    String sid,
  ) async {
    final resolver = codeServerCommandStream;
    if (resolver == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    res.statusCode = HttpStatus.ok;
    res.headers
      ..set(HttpHeaders.contentTypeHeader, 'text/event-stream')
      ..set(HttpHeaders.cacheControlHeader, 'no-cache')
      ..set('Connection', 'keep-alive')
      ..set('Access-Control-Allow-Origin', '*');
    final sub = resolver(sid).listen((cmd) {
      try {
        res.write('data: ${jsonEncode(cmd)}\n\n');
      } catch (_) {
        // Socket gone — the done handler / error path tears down.
      }
    }, onError: (_) {});
    try {
      // Keep the response open until the command stream ends or the client
      // disconnects (res.done completes when the socket is torn down).
      await res.done;
    } catch (_) {
      // Client hung up — fall through to cancel + close.
    } finally {
      await sub.cancel();
      try {
        await res.close();
      } catch (_) {
        // Already closed.
      }
    }
  }

  /// Forwards a plain HTTP request to code-server [target], streaming the body
  /// both ways and rewriting the framing headers.
  Future<void> _forwardCodeServerHttp(
    HttpRequest request,
    HttpResponse res,
    Uri target,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      // Byte-faithful pass-through: leave the body encoded exactly as code-server
      // sent it. With the default (autoUncompress: true) Dart silently gunzips
      // the upstream body BUT keeps the `content-encoding: gzip` header, so we'd
      // forward decompressed bytes labelled as gzip — the browser then fails to
      // decode every asset (and the workbench HTML) and renders a blank page.
      // Disabling it means we never advertise `Accept-Encoding` ourselves, and
      // whatever encoding the client asked for (gzip/br/identity) flows through
      // untouched alongside its matching header + content-length.
      ..autoUncompress = false
      ..userAgent = 'control-center-vscode-proxy';
    try {
      final upstreamReq = await client.openUrl(request.method, target);
      // Forward request headers (drop hop-by-hop + host, which the upstream
      // sets itself from [target]). `HttpHeaders.forEach` exposes each header
      // name with its full value list; code-server headers are single-valued in
      // practice, so they're rejoined with ", ".
      request.headers.forEach((name, values) {
        if (_isHopByHopHeader(name) || name == 'host') {
          return;
        }
        upstreamReq.headers.set(name, values.join(', '));
      });
      // code-server must see the proxy so it generates sub-path-correct URLs.
      upstreamReq.headers.set('X-Forwarded-Proto', 'http');
      upstreamReq.headers.set(
        'X-Forwarded-Host',
        request.headers.value('host') ?? '',
      );
      // Stream the request body through (code-server POSTs: file saves, search,
      // settings writes).
      await request
          .cast<List<int>>()
          .pipe(upstreamReq)
          .timeout(const Duration(seconds: 30));
      final upstream = await upstreamReq.close().timeout(
        const Duration(seconds: 30),
      );

      res.statusCode = upstream.statusCode;
      upstream.headers.forEach((name, values) {
        if (_isHopByHopHeader(name)) {
          return;
        }
        // Strip frame-blocking headers so the editor can render framed in the
        // app; CSP frame-ancestors is rewritten to allow the app origin.
        if (name.toLowerCase() == 'x-frame-options') {
          return;
        }
        if (name.toLowerCase() == 'content-security-policy') {
          res.headers.set(name, _relaxCspForFraming(values.join(', ')));
          return;
        }
        res.headers.set(name, values.join(', '));
      });
      // If the upstream set no permissive framing, allow the app to frame it
      // (same-origin by construction on desktop; the web bundle is same-origin
      // to the proxy).
      res.headers.removeAll('x-frame-options');
      // Stream the response back (never buffer — code-server is chatty).
      await upstream.cast<List<int>>().pipe(res);
    } catch (e) {
      _w('VS Code proxy HTTP forward failed for $target: $e');
      await _closeProxy(res, HttpStatus.badGateway);
    } finally {
      client.close(force: true);
    }
  }

  /// Bridges a WebSocket upgrade for `/proxy/vscode/<sid>/...` to the upstream
  /// code-server WS, piping frames bidirectionally until either side closes.
  /// Forwards the negotiated subprotocol so code-server's protocol negotiation
  /// works unchanged.
  Future<void> _bridgeCodeServerWebSocket(
    HttpRequest request,
    String sid,
    Uri target,
  ) async {
    final wsTarget = target.replace(
      scheme: target.scheme == 'https' ? 'wss' : 'ws',
    );
    WebSocket? clientSocket;
    WebSocket? upstreamSocket;
    try {
      // The server side accepts the upgrade; the client socket now talks WS.
      clientSocket = await WebSocketTransformer.upgrade(request);
      // Forward the subprotocols the client offered so code-server can pick.
      final offered = request.headers.value('sec-websocket-protocol');
      final upstreamUri = wsTarget.toString();
      upstreamSocket = offered == null
          ? await WebSocket.connect(upstreamUri)
          : await WebSocket.connect(
              upstreamUri,
              protocols: offered
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            );
      // Bidirectional pipe: each direction runs until its source closes, then
      // the other is torn down. Subscriptions are fire-and-forget (cancelOnError
      // closes the peer on error; the sockets are local resources reaped on
      // disconnect).
      clientSocket.listen(
        upstreamSocket.add,
        onDone: () => upstreamSocket?.close(),
        onError: (Object e) => upstreamSocket?.close(),
        cancelOnError: true,
      );
      upstreamSocket.listen(
        clientSocket.add,
        onDone: () => clientSocket?.close(),
        onError: (Object e) => clientSocket?.close(),
        cancelOnError: true,
      );
    } catch (e) {
      _w('VS Code proxy WS bridge failed for $wsTarget: $e');
      await clientSocket?.close();
      await upstreamSocket?.close();
    }
  }

  /// Whether [name] is a hop-by-hop / connection-scoped header that must NOT be
  /// forwarded by a proxy (per RFC 7230 §6.1).
  bool _isHopByHopHeader(String name) {
    switch (name.toLowerCase()) {
      case 'connection':
      case 'keep-alive':
      case 'proxy-authenticate':
      case 'proxy-authorization':
      case 'te':
      case 'trailers':
      case 'transfer-encoding':
      case 'upgrade':
        return true;
      default:
        return false;
    }
  }

  /// Rewrites a CSP value so the `frame-ancestors` directive lets the Control
  /// Center app frame code-server. Leaves all other directives intact.
  String _relaxCspForFraming(String csp) {
    // Drop an existing frame-ancestors directive, then append our own.
    final kept = csp
        .split(';')
        .map((d) => d.trim())
        .where(
          (d) => d.isNotEmpty && !d.toLowerCase().startsWith('frame-ancestors'),
        )
        .join('; ');
    final ancestors = _frameAncestorSources();
    return kept.isEmpty
        ? 'frame-ancestors $ancestors'
        : '$kept; frame-ancestors $ancestors';
  }

  /// The `frame-ancestors` allow-list for the embedded editor: exactly the
  /// origins this server already trusts to connect ([_originAllowed]) — loopback
  /// on ANY port plus every configured [allowedOrigins].
  ///
  /// The desktop InAppWebView loads the proxy same-origin (`'self'` covers it),
  /// but the WEB client runs the Flutter bundle on its own origin — a dev server
  /// on an ephemeral `localhost` port (e.g. `http://localhost:57272`) or a hosted
  /// build on a configured domain — which is cross-origin to the proxy and must
  /// be named here or the browser refuses the frame. A bare `http://localhost`
  /// matches only port 80 per the CSP spec, so the port WILDCARD is required.
  /// Framing is not the security boundary — the unguessable capability token in
  /// the `/proxy/vscode/<sid>/` path is — so this mirrors the connection policy
  /// rather than reflecting an arbitrary embedder's `Referer`/`Origin`.
  String _frameAncestorSources() {
    final sources = <String>{
      "'self'",
      'http://localhost:*',
      'https://localhost:*',
      'http://127.0.0.1:*',
      'https://127.0.0.1:*',
      ...allowedOrigins,
    };
    return sources.join(' ');
  }

  /// Whether [ct] names the ICO favicon family (some hosts omit the `.ico`
  /// path extension but still send an icon content-type).
  bool _isIconContentType(ContentType? ct) {
    if (ct == null) {
      return false;
    }
    final m = ct.mimeType.toLowerCase();
    return m == 'image/x-icon' ||
        m == 'image/vnd.microsoft.icon' ||
        m == 'image/ico';
  }

  /// Drains [resp] into a single byte buffer, returning null if it exceeds
  /// [cap] (favicons are tiny, so the cap is never hit in practice — it only
  /// guards a hostile/oversized response).
  Future<List<int>?> _readCapped(HttpClientResponse resp, int cap) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in resp) {
      builder.add(chunk);
      if (builder.length > cap) {
        return null;
      }
    }
    return builder.takeBytes();
  }

  /// Permissive CORS + CORP for signed proxy resources. Echoes the request
  /// `Origin` (never `*` with credentials — there are none here) so a
  /// Cloudflare-hosted web build on a different origin can read the bytes;
  /// same-origin (desktop-served bundle) requests simply ignore it.
  ///
  /// `Cross-Origin-Resource-Policy: cross-origin` also keeps native
  /// `<audio>`/`<video>` loads working when a self-hoster chooses the stricter
  /// `COEP: require-corp` instead of the shipped `credentialless` policy. Every
  /// caller is backed by a signed capability URL, and CORS already permits any
  /// origin that holds one, so CORP does not widen the route's authorization
  /// boundary.
  void _setProxyCors(HttpRequest request, HttpResponse response) {
    final origin = request.headers.value('origin') ?? '*';
    response.headers
      ..set('Access-Control-Allow-Origin', origin)
      ..set('Access-Control-Allow-Methods', 'GET, OPTIONS')
      ..set('Cross-Origin-Resource-Policy', 'cross-origin')
      // `Range` lets a cross-origin <video>/VideoPlayer seek; the exposed
      // headers let it read the partial-content metadata it gets back.
      ..set('Access-Control-Allow-Headers', 'Range')
      ..set(
        'Access-Control-Expose-Headers',
        'Content-Range, Accept-Ranges, Content-Length, Content-Type',
      )
      ..set('Vary', 'Origin');
  }

  Future<void> _closeProxy(HttpResponse res, int status) async {
    try {
      res.statusCode = status;
      await res.close();
    } catch (_) {
      // Connection already gone — nothing to do.
    }
  }

  /// Returns the stored PSK of [deviceId] when it is an `active`, unexpired
  /// paired device; null otherwise. Mirrors the gates in [_authenticate].
  Future<String?> _activeDevicePsk(String deviceId) async {
    final row = await devicesDao.getById(deviceId);
    final psk = await secrets.readPsk(deviceId);
    if (row == null ||
        psk == null ||
        row.status != PairedDeviceStatus.active ||
        RemotePairingLifecycle.isExpired(row.expiresAt, DateTime.now())) {
      return null;
    }
    return psk;
  }

  bool _originAllowed(String? origin) {
    if (origin == null || origin.isEmpty) {
      return true; // Native (non-browser) client — no Origin header.
    }
    final uri = Uri.tryParse(origin);
    if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return true;
    }
    return allowedOrigins.contains(origin);
  }

  Future<void> _onSocket(WebSocket socket, InternetAddress? peer) async {
    final transport = WsRemoteTransport(socket, label: peer?.host ?? 'ws')
      ..start();
    final auth = await _authenticate(transport);
    if (auth == null) {
      // Tell the client it was rejected instead of letting its handshake stall
      // until the timeout (which surfaces as an opaque "Server did not complete
      // auth"). Deliberately generic: the precise reason (unpaired / wrong key /
      // expired) is logged server-side in [_authenticate] and must NOT be
      // revealed to an unauthenticated peer.
      try {
        await transport.send(const {'type': 'auth_denied'});
      } catch (_) {
        // Best effort — the socket may already be gone.
      }
      await transport.close();
      return;
    }
    final userId = auth.row.userId;
    if (userId == null || userId.isEmpty) {
      // A device credential with no user binding cannot act as a principal.
      // The identity bootstrap binds every legacy row at startup, so this only
      // fires for a corrupt/hand-edited row — fail closed, generic wire error.
      _w('Rejecting session for device ${auth.row.id} — no bound user');
      try {
        await transport.send(const {'type': 'auth_denied'});
      } catch (_) {
        // Best effort.
      }
      await transport.close();
      return;
    }
    final rpc = RemoteRpcSession(
      deviceId: auth.row.id,
      userId: userId,
      channel: transport,
      dispatcher: dispatcher,
      workspaceResolver: workspaceResolver,
      workspaceExists: workspaceExists,
      // Privilege is derived from the authenticated device's platform: a
      // first-party web/desktop client gets full privilege; a phone is
      // restricted (cannot reach pairing.* ops).
      capability: SessionCapability.fromPlatform(auth.row.platform),
      repoOps: repoOps,
      watchQueries: watchQueries,
      // The server's view of the client address, captured at the WS upgrade.
      // Loopback for local sockets; the relay/tunnel endpoint when the
      // connection arrived via a relay. Flows into `repo/call` audit records.
      remoteAddress: peer?.address,
      // Sessions of the same user share one budget (three devices must not
      // triple a member's mutation allowance).
      rateLimiter: rateLimiters.forUser(userId),
    );
    final forwarder = RemoteEventForwarder(
      eventBus: eventBus,
      channel: transport,
      deviceId: auth.row.id,
    );
    final session = _WsSession(
      rpc: rpc,
      forwarder: forwarder,
      transport: transport,
      deviceId: auth.row.id,
      userId: userId,
    );
    _sessions.add(session);
    await rpc.start();
    forwarder.start();
    await devicesDao.markSeen(auth.row.id, DateTime.now());
    try {
      await transport.send(const {'type': 'approved'});
    } catch (_) {
      // Best effort.
    }
    // Drive teardown off the transport's close.
    session.stateSub = transport.state.listen((s) {
      if (s == RemoteChannelState.closed) {
        unawaited(_drop(session));
      }
    });
    _i('WSS session up for ${auth.row.id}');
  }

  Future<void> _drop(_WsSession session) async {
    if (_sessions.remove(session)) {
      await session.dispose();
    }
  }

  /// Mutual PSK challenge over the (TLS-protected) WebSocket. Delegates to the
  /// shared [authenticatePairedPeer] — the same handshake the broker-relay path
  /// (`RemoteRelayHost`) runs, so a direct WS and a relayed phone authenticate
  /// identically. Returns null on any failure (fail closed).
  Future<({PairedDevicesTableData row, String psk})?> _authenticate(
    WsRemoteTransport transport,
  ) => authenticatePairedPeer(
    transport,
    devicesDao: devicesDao,
    secrets: secrets,
    identity: identity,
    warn: _w,
  );

  Future<void> _serveStatic(HttpRequest request) async {
    final root = webRoot;
    if (root == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    // Resolve the request path under the web root, blocking traversal.
    final rel = request.uri.path == '/' ? 'index.html' : request.uri.path;
    final normalized = p.normalize(p.join(root, rel.replaceFirst('/', '')));
    if (!p.isWithin(root, normalized) && normalized != p.normalize(root)) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }
    var file = File(normalized);
    // SPA fallback: unknown paths serve index.html so client routing works.
    if (!file.existsSync()) {
      file = File(p.join(root, 'index.html'));
      if (!file.existsSync()) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
    }
    request.response.headers
      ..contentType = _contentTypeFor(file.path)
      // Strict CSP for the served web bundle (matches § Security web client).
      // connect-src names https + plaintext loopback on top of 'self' because
      // connecting starts with a cross-origin `GET <server>/healthz` probe:
      // even when this very server serves the bundle, the resolver's loopback
      // path probes `http://127.0.0.1:<port>`, which 'self' does not match
      // when the page was loaded over `localhost`. Plaintext stays
      // loopback-only, mirroring `TransportSecurityPolicy`.
      ..set(
        'Content-Security-Policy',
        "default-src 'self'; "
            "connect-src 'self' ws: wss: https: "
            'http://localhost:* http://127.0.0.1:*; '
            "img-src 'self' data:; "
            // media-src mirrors connect-src rather than img-src, for the same
            // reason: the soundscape stream, meeting audio, and proxied video
            // all play from this server through an <audio>/<video> element, and
            // the URL the client builds comes from `MediaProxyConfig.httpBase`
            // — which may name the loopback IP (or a tunnel host) while the page
            // was loaded over `localhost`. 'self' does not match across that
            // alias, and blocked media is silent: the player never starts.
            "media-src 'self' blob: data: https: "
            'http://localhost:* http://127.0.0.1:*; '
            "style-src 'self' 'unsafe-inline'; "
            // The in-app "simple web browser" embeds arbitrary pages in an
            // <iframe>; allow any http/https framed source. (frame-ancestors
            // below still restricts who may frame the app itself.)
            "frame-src 'self' https: http:; "
            "object-src 'none'; base-uri 'none'; frame-ancestors 'none'",
      )
      ..set('X-Content-Type-Options', 'nosniff');
    await request.response.addStream(file.openRead());
    await request.response.close();
  }

  ContentType _contentTypeFor(String path) {
    final ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.html' => ContentType.html,
      '.js' => ContentType('application', 'javascript', charset: 'utf-8'),
      '.json' => ContentType('application', 'json', charset: 'utf-8'),
      '.css' => ContentType('text', 'css', charset: 'utf-8'),
      '.wasm' => ContentType('application', 'wasm'),
      '.png' => ContentType('image', 'png'),
      '.svg' => ContentType('image', 'svg+xml'),
      _ => ContentType.binary,
    };
  }
}

class _WsSession {
  _WsSession({
    required this.rpc,
    required this.forwarder,
    required this.transport,
    required this.deviceId,
    required this.userId,
  });
  final RemoteRpcSession rpc;
  final RemoteEventForwarder forwarder;

  /// The underlying transport — used by [LocalRpcServer.broadcast] to fan out
  /// host-side notifications (e.g. shutdown progress) to this session.
  final RemoteRpcChannelPort transport;

  /// The authenticated device — the live-revocation watcher drops sessions
  /// whose device leaves the active set.
  final String deviceId;

  /// The authenticated user behind [deviceId].
  final String userId;
  StreamSubscription<RemoteChannelState>? stateSub;

  Future<void> dispose() async {
    await stateSub?.cancel();
    await forwarder.dispose();
    await rpc.stop();
  }
}
