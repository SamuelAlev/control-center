import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/favicon_transcode.dart';
import 'package:cc_server_core/src/image_resize.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/relay/paired_peer_auth.dart';
import 'package:cc_server_core/src/remote_event_forwarder.dart';
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
typedef MeetingAudioResolver = Future<File?> Function({
  required String workspaceId,
  required String meetingId,
});

/// A WebSocket JSON-RPC server — the **reachable-server** transport.
///
/// Where the WebRTC path (`RemoteControlServer`) reaches a desktop behind NAT
/// via a broker, this server is dialed directly: a client opens `wss://…/rpc`
/// on the LAN / Tailnet / VPS, or `ws://localhost:<port>` for a same-origin web
/// build. It is the server a headless `cc_server` runs, and the one the desktop
/// starts in "act as server" (LOCAL+serve) mode. The same paired-device PSK
/// authenticates each connection and the same shared [RpcDispatcher] +
/// [RemoteRpcSession] handle the RPC — TLS replaces DTLS as the channel guard.
///
/// Security posture (matches the plan's § Security):
///  * **Loopback or TLS.** Binding any non-loopback interface requires a
///    [SecurityContext]; otherwise [start] throws rather than expose plaintext.
///  * **Origin allow-list.** Browser `Origin` headers are checked against
///    [allowedOrigins] (loopback always allowed) — never reflected.
///  * **PSK challenge.** A connection must prove PSK possession (mutual HMAC
///    challenge) for an `active` device before any RPC is dispatched.
class LocalRpcServer {
  /// Creates a [LocalRpcServer].
  LocalRpcServer({
    required this.dispatcher,
    required this.devicesDao,
    required this.secrets,
    required this.eventBus,
    required this.workspaceResolver,
    this.repoOps,
    this.watchQueries,
    this.meetingAudio,
    this.address,
    this.port = 9030,
    this.securityContext,
    this.allowInsecureBind = false,
    this.allowedOrigins = const <String>{},
    this.webRoot,
    this.onRunningChanged,
  });

  /// Repo-RPC dispatcher exposed to connected clients (`repo/call` / `op/list`).
  final RepoOpDispatcher? repoOps;

  /// Reactive watch-query registry (`sub/subscribe`).
  final WatchQueryRegistry? watchQueries;

  /// Resolves a meeting's playable audio file for the `/meeting/audio` byte
  /// endpoint. Null on a host with no meeting audio capability — the route then
  /// 404s (the client falls back to no playback).
  final MeetingAudioResolver? meetingAudio;

  /// Shared RPC dispatcher (one instance app-wide).
  final RpcDispatcher dispatcher;

  /// Paired-device metadata DAO.
  final PairedDeviceDao devicesDao;

  /// Per-device PSK secure store.
  final PairedDeviceSecretsPort secrets;

  /// Domain event bus for push.
  final DomainEventBus eventBus;

  /// Resolves the workspaces a client may switch between.
  final RemoteWorkspaceResolver workspaceResolver;

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

  /// Callback when running state changes.
  void Function({required bool running})? onRunningChanged;

  HttpServer? _server;
  final Set<_WsSession> _sessions = {};

  /// Whether the server is bound and listening.
  bool get isRunning => _server != null;

  /// The bound port (after [start]), or the configured [port] before.
  int get boundPort => _server?.port ?? port;

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
      _w('SECURITY: binding $addr over PLAINTEXT (allowInsecureBind). Only safe '
          'behind a TLS-terminating reverse proxy on a trusted network — never '
          'expose this port directly to the public internet.');
    }
    final server = securityContext != null
        ? await HttpServer.bindSecure(addr, port, securityContext!)
        : await HttpServer.bind(addr, port);
    _server = server;
    server.listen(
      _handle,
      onError: (Object e, StackTrace st) {
        _e('LocalRpcServer accept error: $e', e, st);
      },
    );
    _i('LocalRpcServer listening on '
          '${securityContext != null ? 'wss' : 'ws'}://${addr.host}:${server.port} '
          '(web bundle: ${webRoot ?? 'none'})',
    );
    onRunningChanged?.call(running: true);
  }

  /// Stops the server and tears down every live session.
  Future<void> stop() async {
    final server = _server;
    _server = null;
    for (final s in _sessions.toList()) {
      await s.dispose();
    }
    _sessions.clear();
    if (server != null) {
      await server.close(force: true);
    }
    onRunningChanged?.call(running: false);
    _i('LocalRpcServer stopped');
  }

  Future<void> _handle(HttpRequest request) async {
    if (request.uri.path == '/rpc') {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response.statusCode = HttpStatus.upgradeRequired;
        await request.response.close();
        return;
      }
      if (!_originAllowed(request.headers.value('origin'))) {
        _w('Rejecting WS upgrade — origin not allowed: '
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
    if (request.uri.path == '/proxy/media') {
      await _serveMediaProxy(request);
      return;
    }
    if (request.uri.path == '/meeting/audio') {
      await _serveMeetingAudio(request);
      return;
    }
    await _serveStatic(request);
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
    if (psk == null || !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
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

  /// Streams [file] to [request] as [contentType], honoring a single-range
  /// `Range: bytes=` request with a `206 Partial Content` reply (so an
  /// `<audio>`/AVPlayer can seek). A missing/blank/whole-file request gets a
  /// plain `200`. CORS headers are already set by the caller.
  Future<void> _serveFileWithRange(
    HttpRequest request,
    File file,
    String contentType,
  ) async {
    final res = request.response;
    final length = await file.length();
    res.headers
      ..set(HttpHeaders.acceptRangesHeader, 'bytes')
      ..contentType = ContentType.parse(contentType);

    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    final range =
        rangeHeader == null ? null : _parseSingleRange(rangeHeader, length);
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
    if (psk == null || !RemoteControlCrypto.verifyProxyTarget(rawUrl, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final target = Uri.tryParse(rawUrl);
    if (target == null ||
        (target.scheme != 'http' && target.scheme != 'https')) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }
    if (_isBlockedTarget(target)) {
      _w('Media proxy refusing blocked target host: ${target.host}');
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    // A `Range` request (video seeking, resumable downloads) is forwarded to the
    // upstream and the partial reply relayed; the image transforms below never
    // touch a ranged body. Audio/video can be large, so the cap is generous.
    final clientRange = request.headers.value(HttpHeaders.rangeHeader);
    const maxBytes = 96 * 1024 * 1024;
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..userAgent = 'control-center-media-proxy';
      final req = (await client.getUrl(target))
        ..followRedirects = true
        ..maxRedirects = 3
        ..headers.set(HttpHeaders.acceptHeader, '*/*');
      if (clientRange != null && clientRange.isNotEmpty) {
        req.headers.set(HttpHeaders.rangeHeader, clientRange);
      }
      final upstream = await req.close().timeout(const Duration(seconds: 20));
      if (upstream.statusCode >= 400 || upstream.contentLength > maxBytes) {
        await _closeProxy(res, HttpStatus.badGateway);
        return;
      }

      final isRanged = upstream.statusCode == HttpStatus.partialContent ||
          (clientRange != null && clientRange.isNotEmpty);

      // Image-only transforms apply only to a full (non-ranged) response.
      if (!isRanged) {
        // Newsfeed source icons resolve to `<host>/favicon.ico`, and a favicon
        // is almost always ICO — a format the web client's CanvasKit renderer
        // cannot decode, so it would fail to paint even once the bytes arrive.
        // Detect those (by `.ico` path or an icon content-type), buffer them,
        // and transcode to PNG. Everything else streams straight through.
        final looksLikeIcon =
            target.path.toLowerCase().endsWith('.ico') ||
            _isIconContentType(upstream.headers.contentType);
        if (looksLikeIcon) {
          final bytes = await _readCapped(upstream, maxBytes);
          if (bytes == null) {
            await _closeProxy(res, HttpStatus.badGateway);
            return;
          }
          // If it really is ICO, hand the client PNG; if the `.ico` URL actually
          // served a renderable format already (some hosts do), pass it through.
          final png = transcodeIcoToPng(bytes);
          final source = png ?? bytes;
          final resized = maxWidth != null
              ? resizeRasterToWidth(source, maxWidth)
              : null;
          res
            ..statusCode = HttpStatus.ok
            ..headers.contentType = resized != null
                ? ContentType.parse(resized.mimeType)
                : (png != null
                      ? ContentType('image', 'png')
                      : (upstream.headers.contentType ??
                            ContentType('application', 'octet-stream')))
            ..headers.set('Cache-Control', 'public, max-age=86400')
            ..headers.set('X-Content-Type-Options', 'nosniff')
            ..add(resized?.bytes ?? source);
          await res.close();
          return;
        }
        // With a downscale hint we must buffer to decode/resize; without one we
        // keep the zero-copy streaming path. A non-raster/animated/already-small
        // body falls through to the original bytes so an asset is never dropped
        // because resize couldn't run (e.g. it isn't an image at all).
        if (maxWidth != null) {
          final raw = await _readCapped(upstream, maxBytes);
          if (raw == null) {
            await _closeProxy(res, HttpStatus.badGateway);
            return;
          }
          final resized = resizeRasterToWidth(raw, maxWidth);
          res
            ..statusCode = HttpStatus.ok
            ..headers.contentType = resized != null
                ? ContentType.parse(resized.mimeType)
                : (upstream.headers.contentType ??
                      ContentType('application', 'octet-stream'))
            ..headers.set('Cache-Control', 'public, max-age=86400')
            ..headers.set('X-Content-Type-Options', 'nosniff')
            ..add(resized?.bytes ?? raw);
          await res.close();
          return;
        }
      }

      // Stream-through path (full bodies of any media type, and every ranged
      // response). Relay the upstream status (200 or 206) plus the range/length
      // headers a media player needs to seek.
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
      final contentRange =
          upstream.headers.value(HttpHeaders.contentRangeHeader);
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
    } catch (e) {
      _w('Media proxy fetch failed for ${target.host}: $e');
      await _closeProxy(res, HttpStatus.badGateway);
    } finally {
      client?.close(force: true);
    }
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

  /// Permissive CORS for proxied images. Echoes the request `Origin` (never `*`
  /// with credentials — there are none here) so a Cloudflare-hosted web build on
  /// a different origin can read the bytes; same-origin (desktop-served bundle)
  /// requests simply ignore them.
  void _setProxyCors(HttpRequest request, HttpResponse response) {
    final origin = request.headers.value('origin') ?? '*';
    response.headers
      ..set('Access-Control-Allow-Origin', origin)
      ..set('Access-Control-Allow-Methods', 'GET, OPTIONS')
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

  /// Whether [uri] points at an address the proxy must refuse: loopback,
  /// link-local (incl. the 169.254.169.254 cloud-metadata endpoint), or RFC-1918
  /// / unique-local private ranges. IP literals are checked directly; bare
  /// `localhost` is refused by name. Defence-in-depth behind the PSK signature.
  bool _isBlockedTarget(Uri uri) {
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
      if (a == 0 || a == 10 || a == 127 || (a == 169 && b == 254) ||
          (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168)) {
        return true;
      }
    }
    return false;
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
    final rpc = RemoteRpcSession(
      deviceId: auth.row.id,
      channel: transport,
      dispatcher: dispatcher,
      workspaceResolver: workspaceResolver,
      // Privilege is derived from the authenticated device's platform: a
      // first-party web/desktop client gets full privilege; a phone is
      // restricted (cannot reach pairing.* ops).
      capability: SessionCapability.fromPlatform(auth.row.platform),
      repoOps: repoOps,
      watchQueries: watchQueries,
    );
    final forwarder = RemoteEventForwarder(
      eventBus: eventBus,
      channel: transport,
      deviceId: auth.row.id,
    );
    final session = _WsSession(rpc: rpc, forwarder: forwarder);
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
  ) =>
      authenticatePairedPeer(
        transport,
        devicesDao: devicesDao,
        secrets: secrets,
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
      ..set(
        'Content-Security-Policy',
        "default-src 'self'; connect-src 'self' ws: wss:; "
            "img-src 'self' data:; media-src 'self' blob: data:; "
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
  _WsSession({required this.rpc, required this.forwarder});
  final RemoteRpcSession rpc;
  final RemoteEventForwarder forwarder;
  StreamSubscription<RemoteChannelState>? stateSub;

  Future<void> dispose() async {
    await stateSub?.cancel();
    await forwarder.dispose();
    await rpc.stop();
  }
}
