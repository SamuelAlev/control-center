import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/services/cache_stats.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart'
    show RigPort, RigStreamUnavailable;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart'
    show browserHandoffPage;
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show ChatDeepLinks, CodeServerService;
import 'package:cc_mcp/cc_mcp.dart' show McpRequestHandler;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/favicon_transcode.dart';
import 'package:cc_server_core/src/identity/oidc_service.dart';
import 'package:cc_server_core/src/identity/provider_oauth_service.dart';
import 'package:cc_server_core/src/identity/saml_service.dart';
import 'package:cc_server_core/src/identity/scim_service.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:cc_server_core/src/identity/sso_settings_service.dart';
import 'package:cc_server_core/src/image_resize.dart';
import 'package:cc_server_core/src/media_cache.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/redeem_capacity_exception.dart';
import 'package:cc_server_core/src/relay/paired_peer_auth.dart';
import 'package:cc_server_core/src/remote_event_forwarder.dart';
import 'package:cc_server_core/src/server_mcp_control.dart';
import 'package:path/path.dart' as p;

part 'local_rpc_server_auth.dart';
part 'local_rpc_server_backup.dart';
part 'local_rpc_server_codeserver.dart';
part 'local_rpc_server_media.dart';
part 'local_rpc_server_rig.dart';

// Diagnostics go through cc_host's log sink; this file needs no Flutter logger.
void _e(String m, [Object? err, StackTrace? st]) =>
    CcHostLog.error('LocalRpcServer: $m', err, st);
void _i(String m) => CcHostLog.info('LocalRpcServer: $m');
void _w(String m) => CcHostLog.warning('LocalRpcServer: $m');

/// Parses a streaming lane's declared content type into a header value.
///
/// `ContentType.parse`, never a split on `/`: a type with a parameter
/// (`multipart/x-mixed-replace; boundary=…`, `audio/mpeg; rate=…`) put its
/// whole tail into the SUBTYPE, so the relay advertised a media type no client
/// has ever heard of. A malformed value degrades to a binary blob rather than
/// taking the lane down — the bytes are still the bytes, and
/// `application/octet-stream` is an honest "we do not know".
ContentType relayContentType(String value) {
  const fallback = 'octet-stream';
  try {
    final parsed = ContentType.parse(value);
    // `parse` is lenient: a value with no '/' yields an empty subtype and a
    // `nonsense/` header, which is a malformed type dressed as a valid one.
    if (parsed.primaryType.isEmpty || parsed.subType.isEmpty) {
      return ContentType('application', fallback);
    }
    return parsed;
  } on FormatException {
    return ContentType('application', fallback);
  }
}

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
/// client's, so a workspace mark renders identically on desktop, web and
/// remote (mirroring `/meeting/audio`).
typedef WorkspaceLogoResolver =
    Future<File?> Function({required String workspaceId});

/// Resolves one stored blob (a tool-result screenshot) to its file and MIME
/// type, or null when the workspace holds no blob with that hash.
typedef BlobResolver =
    Future<({File file, String contentType})?> Function({
      required String workspaceId,
      required String hash,
    });

/// Stores bytes a client uploaded (a pasted or dropped screenshot) and returns
/// the reference the message will carry, or null when the payload is empty,
/// malformed or over the store's own ceiling.
///
/// Bytes arrive over HTTP rather than on the RPC socket, and that is the whole
/// point of this route existing: `WsRemoteTransport` caps a single inbound
/// frame at 256 KB and CLOSES the connection past it, so a base64 screenshot on
/// the control channel could not arrive — it dropped the socket instead. Bulk
/// content rides the same HTTP lane as every other large payload here (media
/// proxy, meeting audio, rig files), which also spares the server's main
/// isolate a multi-megabyte JSON parse and the 33% base64 tax.
typedef BlobWriter =
    Future<({String ref, int bytes, String mediaType})?> Function({
      required String workspaceId,
      required List<int> bytes,
      required String mediaType,
    });

/// Writes a throwaway copy of [workspaceId]'s database for a client to
/// download, or null when the workspace has no file yet.
///
/// The file it returns is the route's to DELETE once it has been streamed. That
/// is the difference between this and the `workspace.export` RPC op, which
/// writes the same bytes and leaves them: an export's destination is the server
/// and a download's destination is the caller's disk, so keeping a second copy
/// per download is how a data directory fills up with files nobody asked for.
typedef BackupExportWriter =
    Future<File?> Function({required String workspaceId});

/// Packs snapshot [name] into a single archive file for download, or null when
/// no snapshot by that name exists. The route deletes the archive afterwards.
///
/// A snapshot is a DIRECTORY (`manifest.json`, `global.db`, one file per
/// workspace), and HTTP hands out one body — so the only way to download "the
/// backup" rather than its pieces is to pack it here.
typedef BackupSnapshotArchiver = Future<File?> Function({required String name});

/// Adopts an uploaded workspace database file as [workspaceId]'s, replacing
/// what is there. Throws with an operator-readable message when the file is not
/// a workspace database.
///
/// This is `workspace.import` reached from the other direction: the RPC op
/// names a path that already exists on the SERVER, which is unreachable for
/// anyone whose server is not their own machine. Same validation, same
/// replacement, different way of getting the bytes there.
typedef BackupRestoreReader =
    Future<void> Function({
      required String workspaceId,
      required String sourcePath,
    });

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

/// Opens the human watch lane for a rig: an already-encoded byte stream plus
/// the content type to frame it with.
///
/// Returns null when the rig is not live on this host. The server relays these
/// bytes without decoding them — putting a video decoder in the request path
/// is how a server stops being able to answer RPCs while someone watches a VM.
typedef RigStreamResolver =
    Future<({Stream<List<int>> bytes, String contentType})?> Function({
      required String workspaceId,
      required String rigId,
      required Map<String, dynamic> request,
    });

/// Feeds one bounded PCM16 microphone chunk into a rig.
///
/// The HTTP route authenticates the paired device and resolves its real user
/// principal before this runs. Returns false when the rig or its microphone
/// lane is unavailable.
typedef RigAudioInputResolver =
    Future<bool> Function({
      required String workspaceId,
      required String rigId,
      required Principal actor,
      required String sessionId,
      required Uint8List bytes,
      required int sampleRate,
      required int channels,
      required bool start,
      required bool end,
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
/// build. It is the server a headless `cc_server` runs and the one the desktop
/// starts in "act as server" (LOCAL+serve) mode. The same paired-device PSK
/// authenticates each connection and the same shared `RpcDispatcher` +
/// `RemoteRpcSession` handle the RPC — TLS replaces DTLS as the space guard.
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
/// A bare hostname (not an IP literal) returns `false` here — it cannot be
/// judged without resolving it. Callers pair this with
/// [resolvesToBlockedAddress], which does resolve and applies the same rules
/// to every answer, so a domain pointed at `10.x` / `127.x` /
/// `169.254.169.254` is refused rather than fetched.
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

/// Whether [uri]'s HOST resolves to an address the media proxy must refuse.
///
/// [isBlockedProxyTarget] can only judge IP literals; a hostname needed a
/// resolution, which is how `evil.example.com A 10.0.0.5` walked straight
/// through the literal-IP blocks (classic DNS rebinding, in front of an
/// internal service the server can reach and the caller cannot).
///
/// Resolution failure is treated as BLOCKED: a name the proxy cannot resolve
/// is a name it has no business fetching. Callers still re-check every
/// redirect hop.
///
/// Residual: the proxy connects by NAME, so a resolver that answers
/// differently between this check and the connect can still slip through.
/// Closing that fully means connecting by IP with a preserved `Host` +TLS SNI;
/// this removes the cheap version of the attack, which is the one that matters
/// behind the PSK signature.
Future<bool> resolvesToBlockedAddress(Uri uri) async {
  final host = uri.host;
  if (host.isEmpty || InternetAddress.tryParse(host) != null) {
    return false; // Literals were already judged synchronously.
  }
  try {
    final addresses = await InternetAddress.lookup(
      host,
    ).timeout(const Duration(seconds: 5));
    if (addresses.isEmpty) {
      return true;
    }
    return addresses.any(
      (a) => isBlockedProxyTarget(Uri(scheme: uri.scheme, host: a.address)),
    );
  } on Object {
    return true;
  }
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
    this.sessionPolicy,
    this.repoOps,
    this.watchQueries,
    this.workspaceExists,
    this.resolveRole,
    this.meetingAudio,
    this.workspaceLogo,
    this.blob,
    this.blobPut,
    this.backupExport,
    this.backupSnapshotArchive,
    this.backupRestore,
    this.isServerOwner,
    this.fontFile,
    this.rigStream,
    this.rigAudioInput,
    this.rigTransfer,
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
    this.mediaProxyEnabled = true,
    this.mediaProxyMaxBytes,
    this.isDemo = false,
    this.trustProxy = false,
    this.mediaCredential,
    this.oidc,
    this.providerOAuth,
    this.saml,
    this.scim,
    this.webClientUrl,
    this.authProviders,
    this.manualPairingEnabled,
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
    this.backupUploadDir,
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

  /// Resolves a stored tool-result image for the `/blob` endpoint. Null on a
  /// host with no blob store — the route then 404s and the transcript renders
  /// the tool call without its screenshot.
  final BlobResolver? blob;

  /// Stores an uploaded image for `POST /blob`. Null on a host with no blob
  /// store — the route then 404s and the composer reports the attachment as
  /// not carried rather than silently sending a message without it.
  final BlobWriter? blobPut;

  /// Hard ceiling on one `POST /blob` body, checked before the bytes are
  /// buffered. Sits above the blob store's own 24 MB limit so the store — not
  /// the socket — is what reports an over-sized image.
  static const int _maxBlobUploadBytes = 32 * 1024 * 1024;

  /// Writes one workspace's database for `GET /backup/workspace`. Null on a
  /// host with no backup port (a demo server) — the route then 404s.
  final BackupExportWriter? backupExport;

  /// Packs a snapshot directory for `GET /backup/snapshot`. Null on a host with
  /// no backup port — the route then 404s.
  final BackupSnapshotArchiver? backupSnapshotArchive;

  /// Adopts an uploaded database for `POST /backup/restore`. Null on a host
  /// with no backup port — the route then 404s.
  final BackupRestoreReader? backupRestore;

  /// Whether a user is the operator of this INSTALL. Used by the snapshot
  /// download, which is the one backup route that is not workspace-scoped: a
  /// snapshot holds EVERY workspace, so membership in one of them authorizes
  /// nothing. Null (bare test servers) skips the check.
  final Future<bool> Function(String userId)? isServerOwner;

  /// Hard ceiling on one `POST /backup/restore` body.
  ///
  /// Three orders of magnitude above the blob cap because the payloads are
  /// nothing alike — a pasted screenshot against a workspace's entire history —
  /// and unlike a blob this body is streamed straight to disk, so the ceiling
  /// bounds a file rather than a buffer.
  static const int _maxBackupUploadBytes = 8 * 1024 * 1024 * 1024;

  /// The canonical signed target for the rig transfer lanes.
  static String rigTransferTarget(String workspaceId, String rigId) =>
      'rig-files:$workspaceId/$rigId';

  final _scimRate = <String, (int, DateTime)>{};

  final _inviteRate = <String, (int, DateTime)>{};

  /// Resolves one variant of a catalogued font family to its upstream file URL
  /// for the `/proxy/font` endpoint. Null on a host with no font catalogue — the
  /// route then 404s (clients keep their bundled and system fonts).
  final FontFileResolver? fontFile;

  /// Opens the continuous MP3 stream for a soundscape `(workspaceId, mood)` over
  /// `/soundscape/stream`. Null on a host with no soundscape engine — the route
  /// then 404s (the client hides audio).
  /// Opens a rig's watch lane for `/rig/stream`. Null on a host with no
  /// enclosure support, which makes the route 404 rather than hang.
  final RigStreamResolver? rigStream;

  /// Feeds microphone PCM into a rig. Kept separate from [rigStream] because
  /// this lane is mutating input and therefore needs a real principal plus the
  /// service's take-over chokepoint.
  final RigAudioInputResolver? rigAudioInput;

  /// The rig clipboard and file lanes, serving `/rig/clipboard/<id>` and
  /// `/rig/files/<id>`. Null on a host with no enclosure support.
  ///
  /// **Why these are HTTP routes and not RPC ops.** The RPC socket caps an
  /// inbound frame at 256 KB and CLOSES the connection past it
  /// ([WsRemoteTransport]) — a DoS guard that is right for JSON commands and
  /// fatal for a pasted screenshot. Putting a base64 image or a dropped file
  /// on that lane would not be slow, it would drop the client's whole
  /// session. So bytes ride HTTP, exactly as rig frames, meeting audio and
  /// proxied media already do, and the RPC lane stays small.
  final RigPort? rigTransfer;

  /// Opens the soundscape audio stream for `/soundscape/stream`. Null on a
  /// host with no soundscape engine.
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
  ///
  /// `remoteIp` is the caller's address, supplied so a redeemer can apply a
  /// per-address concurrency cap of its own. The route already rate-limits
  /// attempts; this is for bounding how many live sessions one address holds.
  final Future<Map<String, dynamic>> Function(
    Map<String, dynamic> body, {
    String? remoteIp,
  })?
  inviteRedeemer;

  /// Whether this process is a PUBLIC DEMO server.
  ///
  /// Advertised on `/healthz`, which the web client probes BEFORE it connects
  /// — that is what lets the client show its demo shell (badge, first-run
  /// note, guided tour) without inventing a second way to ask. It is also
  /// honest self-description for anything else that looks: a demo host has no
  /// pty, no git and no sandbox backends.
  final bool isDemo;

  /// Whether `X-Forwarded-For` is trusted as the client address.
  ///
  /// Behind a TLS-terminating edge (the documented demo deployment: Railway,
  /// Render, Fly) `connectionInfo.remoteAddress` is the PROXY, so every visitor
  /// shares one address — a per-IP cap then bounds the whole deployment, not an
  /// address. With this flag the pre-auth IP-sensitive paths take the FIRST
  /// `X-Forwarded-For` hop (the client as the edge saw it) and fall back to the
  /// direct address. Trusting a header an arbitrary client can SEND is a
  /// deliberate trade: it is only read for rate/capacity shaping, never for
  /// authorization, and on a demo the alternative (one shared bucket) is worse.
  /// Defaults false; the demo composition enables it because its documented
  /// topology always has an edge in front.
  final bool trustProxy;

  /// Whether the image/media proxy (`/proxy/media`) answers at all.
  ///
  /// Every other byte route is gated by a nullable port that is simply absent
  /// on a host that cannot serve it. The media proxy had no such gate — a null
  /// [mediaCredential] only made it fetch anonymously — so it was the one
  /// remaining way a locked-down host could still make an outbound HTTP
  /// request. Setting this false 404s the route.
  final bool mediaProxyEnabled;

  /// Ceiling on a single proxied body, or null for the default 96 MB.
  ///
  /// The default is sized for audio and video (a meeting recording, a PR
  /// attachment) on a host whose operator is the only caller. A PUBLIC host
  /// serves anonymous visitors who need thumbnails and favicons, so it takes a
  /// much lower cap: without one, `/proxy/media` is a signed request away from
  /// relaying arbitrary large downloads on the server's bandwidth.
  final int? mediaProxyMaxBytes;

  /// Optional OIDC single sign-on (`GET /oidc/login` + `/oidc/callback`).
  /// Null (the default) leaves the routes absent — SSO is never required.
  final OidcService? oidc;

  /// Optional provider sign-in (`GET /oauth/<provider>/callback`) — the
  /// browser round-trip that mints a user's own GitHub/Linear credential.
  /// Null leaves the route absent; pasting a token still works.
  final ProviderOAuthService? providerOAuth;

  /// Resolves the credential to present when the media proxy fetches a URL on
  /// behalf of a user, or null when that host needs none.
  ///
  /// This is what replaced the client holding a forge token: a private PR
  /// attachment is fetched BY THE SERVER, with the viewer's own credential,
  /// and only the bytes cross to the app. Null leaves every media fetch
  /// anonymous, which is correct for a host with no forge wiring.
  final Future<String?> Function(String userId, Uri target)? mediaCredential;

  /// Optional SAML single sign-on (`GET /saml/login` + `POST /saml/acs` +
  /// `GET /saml/metadata`). Null (the default) leaves the routes absent —
  /// SSO is never required.
  final SamlService? saml;

  /// Optional SCIM 2.0 provisioning surface (`/scim/v2/*`) — the IdP pushes
  /// users and, critically, DEPROVISIONS them. Null leaves the routes
  /// absent; a tokenless-but-present service answers every request 401
  /// (fail closed).
  final ScimService? scim;

  /// Origin of the hosted web client (`https://app.example.com`), for SSO
  /// callbacks to bounce the browser to with the minted credential in the
  /// URL FRAGMENT (never a query param — fragments don't reach the static
  /// host's logs). Null keeps the handoff same-origin (`/#…`), which only
  /// lands when this server serves the web bundle itself.
  final String? webClientUrl;

  /// The `/auth/providers` snapshot provider (the SSO settings service);
  /// null leaves the endpoint reporting "manual pairing only".
  final Future<Map<String, Object?>> Function()? authProviders;

  /// Whether manual pairing (invite redemption; the `pairing.mint` op gates
  /// itself in the catalog) is currently allowed. Null = allowed (tests).
  final Future<bool> Function()? manualPairingEnabled;

  /// Per-user shared rate limiters: every session a user opens draws from
  /// one budget.
  final RemoteRateLimiterPool rateLimiters;

  /// Shared RPC dispatcher (one instance app-wide).
  final RpcDispatcher dispatcher;

  /// Paired-device metadata DAO, from the server-global database: a device is
  /// paired with the server, not with one workspace and survives a workspace
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

  /// Membership gate forwarded to each session: `tools/call` naming a
  /// workspace the user is not a member of is refused, workspace-scoped
  /// subscriptions are denied for non-members and workspace-targeted event
  /// forwarding is filtered. Null (bare test servers) skips the gates;
  /// production wiring always supplies it.
  final WorkspaceRoleResolver? resolveRole;

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
  /// files the UI is actively rendering with and vice versa. Null disables
  /// caching — every request then re-fetches upstream.
  final String? fontCacheDir;

  /// Where `POST /backup/restore` stages an upload before adopting it. Null
  /// disables the route (no backup port on this host). Nothing accumulates
  /// here: the handler deletes the staged file on every path out.
  final String? backupUploadDir;

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
  StreamSubscription<WorkspaceMemberRemoved>? _memberWatch;

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
      // Per-request envelope. `_handle` fans out to ~20 route helpers and each
      // owns its own error handling; one that forgot left the response
      // UNCOMPLETED — the client hung until its own timeout while the failure
      // surfaced only as a zone-level uncaught error. Answer 500 and close, so
      // a missing catch is a visible error instead of a silent hang.
      (request) => unawaited(_handleGuarded(request)),
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
    // Live membership revocation: the `repo/call` role gate resolves per call,
    // but an ATTACHED workspace subscription would otherwise keep streaming to
    // a removed member until they unsubscribed. Tear those down on the event.
    _memberWatch = eventBus.on<WorkspaceMemberRemoved>().listen((e) {
      for (final session in _sessions.toList()) {
        if (session.userId == e.userId) {
          session.rpc.dropWorkspaceSubscriptions(e.workspaceId);
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
    await _memberWatch?.cancel();
    _memberWatch = null;
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

  /// [_handle] with a last-resort error envelope. Never rethrows.
  Future<void> _handleGuarded(HttpRequest request) async {
    try {
      await _handle(request);
    } on Object catch (e, st) {
      _e('Unhandled error serving ${request.uri.path}: $e', e, st);
      try {
        // A route may already have written headers; then this throws and the
        // socket simply closes, which is still better than never answering.
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'error': 'internal error'}));
        await request.response.close();
      } on Object {
        // Response already committed/closed — nothing further to do.
      }
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
    if (request.uri.path.startsWith('/oauth/')) {
      await _serveProviderOAuthCallback(request);
      return;
    }
    if (request.uri.path == '/saml/login') {
      await _serveSamlLogin(request);
      return;
    }
    if (request.uri.path == '/saml/acs') {
      await _serveSamlAcs(request);
      return;
    }
    if (request.uri.path == '/saml/metadata') {
      await _serveSamlMetadata(request);
      return;
    }
    if (request.uri.path == '/auth/providers') {
      await _serveAuthProviders(request);
      return;
    }
    if (request.uri.path.startsWith('/scim/v2/')) {
      await _serveScim(request);
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
    if (request.uri.path == '/blob') {
      await _serveBlob(request);
      return;
    }
    if (request.uri.path == '/backup/workspace') {
      await _serveBackupWorkspace(request);
      return;
    }
    if (request.uri.path == '/backup/snapshot') {
      await _serveBackupSnapshot(request);
      return;
    }
    if (request.uri.path == '/backup/restore') {
      await _serveBackupRestore(request);
      return;
    }
    if (request.uri.path.startsWith('/rig/stream/')) {
      await _serveRigStream(request);
      return;
    }
    if (request.uri.path.startsWith('/rig/clipboard/')) {
      await _serveRigClipboard(request);
      return;
    }
    if (request.uri.path.startsWith('/rig/files/')) {
      await _serveRigFiles(request);
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
  /// mismatch means the spawned prebuilt binary is older than the app) and
  /// self-hosters compare it against the latest published release.
  Future<void> _serveHealth(HttpRequest request) async {
    final res = request.response;
    // CORS: /healthz is the reachability probe the WEB client's resolver
    // fetches cross-origin (PRD 15 §8). It is unauthenticated, carries no
    // credentials and reveals only liveness + the PUBLIC server identity
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
          // Additive and default-false: a real server's payload is unchanged.
          if (isDemo) 'demo': true,
          if (codeGraphStatus != null) 'codeGraph': codeGraphStatus!(),
          // Cache hit/miss/eviction counters. Cheap (three ints per cache,
          // incremented in place) and the only way anyone can tell whether the
          // capacities and TTLs in this codebase are the right ones — none of
          // them had ever been checked against a running system. Absent when
          // nothing has registered, so a host that never served media does not
          // report an empty block.
          if (CacheStatsRegistry.instance.toJson() case final caches
              when caches.isNotEmpty)
            'caches': caches,
        }),
      );
    await res.close();
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
    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    // The PSK proves an active DEVICE; it says nothing about whether the user
    // behind it may see THIS workspace. Check membership too — a paired
    // non-member must not stream another workspace's meeting audio.
    final denied = await _lacksMembershipForUser(device?.userId, workspaceId);
    if (denied) {
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
  /// identically on desktop, web and remote. Built by
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
    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    // Same membership rule as meeting audio: an active device belonging to a
    // NON-member must not fetch another workspace's logo.
    if (await _lacksMembershipForUser(device?.userId, workspaceId)) {
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

  /// Serves one stored tool-result image over `/blob`.
  ///
  /// This is how a screenshot an agent took reaches the transcript the human is
  /// reading. The bytes never travel in the message row — the transcript
  /// carries a `blob:sha256:<hex>` reference and the client resolves it here.
  ///
  /// Auth mirrors `/workspace/logo` exactly: the caller signs the canonical
  /// target `blob:<workspaceId>:<hash>` with its device PSK, and an active
  /// device belonging to a NON-member of that workspace is refused. Both checks
  /// matter — the signature proves the device, membership proves the right to
  /// this workspace's pixels, and a screenshot can contain anything that was on
  /// the agent's screen.
  ///
  /// There is no SSRF surface: the request names a content hash, not a URL, and
  /// the store resolves it inside one workspace's directory (a hash that is not
  /// 64 hex characters never becomes a path).
  Future<void> _serveBlob(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    if (request.method == 'POST') {
      await _storeBlob(request);
      return;
    }

    final q = request.uri.queryParameters;
    final workspaceId = q['w'];
    final hash = q['h'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (workspaceId == null ||
        hash == null ||
        deviceId == null ||
        sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }

    final target = 'blob:$workspaceId:$hash';
    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    if (await _lacksMembershipForUser(device?.userId, workspaceId)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final resolver = blob;
    if (resolver == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    ({File file, String contentType})? resolved;
    try {
      resolved = await resolver(workspaceId: workspaceId, hash: hash);
    } catch (e) {
      _w('blob resolve failed for $workspaceId/$hash: $e');
      await _closeProxy(res, HttpStatus.internalServerError);
      return;
    }
    if (resolved == null || !resolved.file.existsSync()) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    // Content-addressed, so the bytes behind a hash can never change: this is
    // the one response in the server that is safe to cache immutably.
    res.headers.set('cache-control', 'public, max-age=31536000, immutable');
    await _serveFileWithRange(request, resolved.file, resolved.contentType);
  }

  /// Stores an image a client uploaded (`POST /blob`) and answers with the
  /// reference its message will carry.
  ///
  /// Auth mirrors the GET side, with one necessary difference: the canonical
  /// target is `blob-put:<workspaceId>` rather than `blob:<workspaceId>:<hash>`,
  /// because the hash is what this call PRODUCES — the client cannot sign for
  /// bytes the server has not stored yet. Membership is still checked, so the
  /// signature only ever buys a write into a workspace the device's user
  /// belongs to.
  Future<void> _storeBlob(HttpRequest request) async {
    final res = request.response;
    final q = request.uri.queryParameters;
    final workspaceId = q['w'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (workspaceId == null || deviceId == null || sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }

    final target = 'blob-put:$workspaceId';
    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    if (await _lacksMembershipForUser(device?.userId, workspaceId)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final writer = blobPut;
    if (writer == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }

    // Any type, not just images. The device and the server are often not the
    // same machine, so a dropped PDF or source file has to have its BYTES on
    // the server — a host path means nothing there, and a preview opened later
    // (or by another member) has nowhere else to read from. Only the type is
    // recorded; the store is content-addressed and type-agnostic.
    final mediaType =
        request.headers.contentType?.mimeType ?? 'application/octet-stream';

    // Bounded BEFORE the body is buffered. The store refuses an over-sized
    // blob too, but that check happens after the bytes are already in memory —
    // this one is what stops an unbounded read.
    final declared = request.contentLength;
    if (declared > _maxBlobUploadBytes) {
      await _closeProxy(res, HttpStatus.requestEntityTooLarge);
      return;
    }
    final bytes = <int>[];
    try {
      await for (final chunk in request) {
        bytes.addAll(chunk);
        if (bytes.length > _maxBlobUploadBytes) {
          await _closeProxy(res, HttpStatus.requestEntityTooLarge);
          return;
        }
      }
    } on Object catch (e) {
      _w('blob upload read failed for $workspaceId: $e');
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }
    if (bytes.isEmpty) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }

    ({String ref, int bytes, String mediaType})? stored;
    try {
      stored = await writer(
        workspaceId: workspaceId,
        bytes: bytes,
        mediaType: mediaType,
      );
    } on Object catch (e) {
      _w('blob upload failed for $workspaceId: $e');
      await _closeProxy(res, HttpStatus.internalServerError);
      return;
    }
    if (stored == null) {
      await _closeProxy(res, HttpStatus.requestEntityTooLarge);
      return;
    }
    res
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(
        jsonEncode({
          'ref': stored.ref,
          'bytes': stored.bytes,
          'media_type': stored.mediaType,
        }),
      );
    await res.close();
  }

  /// Serves one variant of a selectable font family over `/proxy/font` so a
  /// client can register it with Flutter's font loader — built by
  /// `MediaProxyConfig.fontUrl`.
  ///
  /// WHY THE HOST IS IN THIS PATH AT ALL: Skia decodes `ttf`/`otf`, not `woff2`,
  /// and font upstreams choose the format from the request's `User-Agent` —
  /// which a browser `fetch()` cannot set. So a client physically cannot obtain
  /// bytes it can render; the host can and caches them once for every client.
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
    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
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
            await _serveCachedMediaFile(res, contentType, bodyFile);
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
  /// to a few hundred KB; even a full CJK face stays well under this and the
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
    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    // The signature proves an active device; membership proves that device's
    // USER may touch this workspace. `/meeting/audio` has always checked both;
    // these routes checked only the first, so a revoked member kept streaming
    // a workspace's audio until their device was revoked too.
    if (await _lacksMembershipForUser(device?.userId, workspaceId)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    final resolver = soundscapeStream;
    Stream<List<int>>? stream;
    try {
      stream = resolver?.call(workspaceId: workspaceId, mood: mood);
    } on Object catch (e, st) {
      // The hub creates the MP3 encoder here and `liblame_ffi` is a REQUIRED
      // native — so a broken install throws instead of degrading. Answer 500
      // (not the 404 that means "no engine on this host" and not a hang: this
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
    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    // The signature proves an active device; membership proves that device's
    // USER may touch this workspace. `/meeting/audio` has always checked both;
    // these routes checked only the first, so a revoked member kept streaming
    // a workspace's audio until their device was revoked too.
    if (await _lacksMembershipForUser(device?.userId, workspaceId)) {
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
    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    // The signature proves an active device; membership proves that device's
    // USER may touch this workspace. `/meeting/audio` has always checked both;
    // these routes checked only the first, so a revoked member kept streaming
    // a workspace's audio until their device was revoked too.
    if (await _lacksMembershipForUser(device?.userId, workspaceId)) {
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
  /// `304` and a changed logo (new mtime/size) still revalidates correctly.
  Future<void> _serveFileWithRange(
    HttpRequest request,
    File file,
    String contentType,
  ) async {
    final res = request.response;
    // Deliberately sync: `avoid_slow_async_io` is right that Dart's async
    // `stat` routes through the IO thread pool and costs MORE wall clock than
    // the direct syscall for a local file. There is nothing to win here.
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

  /// Permissive CORS + CORP for signed proxy resources. Echoes the request
  /// `Origin` (never `*` with credentials — there are none here) so a
  /// Cloudflare-hosted web build on a different origin can read the bytes;
  /// same-origin (desktop-served bundle) requests simply ignore it.
  ///
  /// `Cross-Origin-Resource-Policy: cross-origin` also keeps native
  /// `<audio>`/`<video>` loads working when a self-hoster chooses the stricter
  /// `COEP: require-corp` instead of the shipped `credentialless` policy. Every
  /// caller is backed by a signed capability URL and CORS already permits any
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

  /// The PSK **and** the bound user of an active, unexpired paired device.
  ///
  /// Every proxy route needs both — the PSK to verify the signed target, the
  /// user to check workspace membership — and resolving them separately read
  /// the same device row twice per request. Returning them together is what
  /// lets a caller pay for one lookup.
  Future<({String psk, String? userId})?> _activeDevice(String deviceId) async {
    final row = await devicesDao.getById(deviceId);
    final psk = await secrets.readPsk(deviceId);
    final now = DateTime.now();
    if (row == null ||
        psk == null ||
        row.status != PairedDeviceStatus.active ||
        RemotePairingLifecycle.isExpired(row.expiresAt, now)) {
      return null;
    }
    // Install session policy (max age / idle timeout). Enforced HERE — at the
    // credential check every authenticated lane funnels through — rather than
    // advertised to clients: a session bound the client could ignore answers
    // a questionnaire, not an attacker.
    final policy = sessionPolicy;
    if (policy != null) {
      final bounds = await policy();
      if (SsoSettingsService.violatesSessionPolicy(
        policy: bounds,
        pairedAt: row.pairedAt,
        lastSeenAt: row.lastSeenAt,
        now: now,
      )) {
        _w(
          'Refusing device $deviceId — outside the install session policy '
          '(max age ${bounds.maxAgeMinutes}m, idle '
          '${bounds.idleTimeoutMinutes}m)',
        );
        return null;
      }
    }
    return (psk: psk, userId: row.userId);
  }

  /// The install's session policy (max age / idle timeout), or null when the
  /// host wires none — in which case a device credential lives until its
  /// pairing expiry, the pre-policy behaviour.
  final Future<({int maxAgeMinutes, int idleTimeoutMinutes})> Function()?
  sessionPolicy;

  /// Whether [userId] — the user bound to the device that signed this request
  /// — is NOT a member of [workspaceId].
  ///
  /// The signed-target check proves an active DEVICE; this proves the device's
  /// USER may touch the workspace the target names. Fail-closed when the
  /// device has no usable user binding; pass-through only on hosts without
  /// identity wiring (single-user), matching the session gates.
  ///
  /// Takes an already-resolved user rather than a device id: every caller has
  /// just read the device row to verify the PSK, and looking it up again was a
  /// second query per proxy request for a value already in hand.
  ///
  /// The registry existence gate runs FIRST, for the same reason it does at
  /// `repo/call` and `sub/subscribe`: `workspace_members` lives in the named
  /// workspace's OWN database, so the membership lookup below OPENS that file
  /// — and opening CREATES it. A client that keeps a stale
  /// `active_workspace_id` across a data-dir reset renders its shell against
  /// that id and fetches the workspace logo, which materialised an empty ghost
  /// `<dataDir>/<id>/workspace.db` on a server that had never heard of it.
  Future<bool> _lacksMembershipForUser(
    String? userId,
    String workspaceId,
  ) async {
    final gate = workspaceExists;
    if (gate != null && !await gate(workspaceId)) {
      _w(
        'Denying media request for workspace $workspaceId — unknown '
        'workspace',
      );
      return true;
    }
    final roleResolver = resolveRole;
    if (roleResolver == null) {
      return false;
    }
    if (userId == null || userId.isEmpty) {
      return true;
    }
    return await roleResolver(workspaceId, userId) == null;
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
      space: transport,
      dispatcher: dispatcher,
      workspaceResolver: workspaceResolver,
      workspaceExists: workspaceExists,
      resolveRole: resolveRole,
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
    final roleResolver = resolveRole;
    final forwarder = RemoteEventForwarder(
      eventBus: eventBus,
      space: transport,
      deviceId: auth.row.id,
      userId: userId,
      // Workspace-targeted events are dropped server-side when the session
      // user is not a member — the client's active-workspace filter is a
      // display concern, not the access boundary.
      isMember: roleResolver == null
          ? null
          : (workspaceId) async =>
                await roleResolver(workspaceId, userId) != null,
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
      // `RemoteRateLimiterPool` had an `evict` with no call site, so `_byUser`
      // grew monotonically per distinct user for the server's lifetime. Evict
      // only once the user's LAST session is gone: while any session remains
      // the budget must stay shared (that is the point of a per-principal
      // limiter), and evicting earlier would hand back a fresh budget for the
      // price of a reconnect.
      final stillConnected = _sessions.any((s) => s.userId == session.userId);
      if (!stillConnected) {
        rateLimiters.evict(session.userId);
      }
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

  /// Whether the SPA fallback `index.html` exists, resolved once. The web
  /// bundle does not appear or vanish while the server runs.
  bool? _indexHtmlExists;

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
    // The fallback's existence is resolved ONCE per process instead of being
    // re-stat'd on every unknown path (sync on purpose — see _serveFileWithRange).
    if (!file.existsSync()) {
      final fallback = File(p.join(root, 'index.html'));
      _indexHtmlExists ??= fallback.existsSync();
      if (_indexHtmlExists != true) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      file = fallback;
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
            // reason: the soundscape stream, meeting audio and proxied video
            // all play from this server through an <audio>/<video> element and
            // the URL the client builds comes from `MediaProxyConfig.httpBase`
            // — which may name the loopback IP (or a tunnel host) while the page
            // was loaded over `localhost`. 'self' does not match across that
            // alias and blocked media is silent: the player never starts.
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
