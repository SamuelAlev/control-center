import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/shared/utils/media_width_ladder.dart';
import 'package:flutter/widgets.dart';

/// Configures how remote media URLs (images, favicons, audio, video, documents)
/// are rewritten to load through the host's media proxy.
///
/// Both the web/remote thin client AND the desktop (which talks to a loopback
/// `cc_server`) install one — the north-star invariant is that every outbound
/// fetch goes through `cc_server`, never the client. A build with no live
/// connection leaves the ambient [MediaProxyScope] absent, so
/// [MediaProxyScope.urlOf] becomes a pass-through there.
@immutable
class MediaProxyConfig {
  /// Creates a [MediaProxyConfig].
  ///
  /// Not `const`: the instance carries a signed-URL memo (see [resolve]), and
  /// a canonicalized const instance would share it across configs.
  MediaProxyConfig({
    required this.httpBase,
    required this.deviceId,
    required this.psk,
  });

  /// Builds a config from the live RPC connection's WebSocket [serverUri]
  /// (`ws(s)://host:port/rpc`), the paired [deviceId] and the connection [psk].
  /// Returns null when [serverUri] is not a `ws`/`wss` URL or fields are blank,
  /// so callers fall back to direct media loading.
  static MediaProxyConfig? fromConnection({
    required Uri serverUri,
    required String deviceId,
    required String psk,
  }) {
    if (deviceId.isEmpty || psk.isEmpty) {
      return null;
    }
    final scheme = switch (serverUri.scheme) {
      'wss' => 'https',
      'ws' => 'http',
      _ => '',
    };
    if (scheme.isEmpty || serverUri.host.isEmpty) {
      return null;
    }
    return MediaProxyConfig(
      // Same host:port as the RPC socket — the origin the client is already
      // paired with — but the http(s) scheme the `/proxy/media` GET needs.
      httpBase: Uri(
        scheme: scheme,
        host: serverUri.host,
        port: serverUri.hasPort ? serverUri.port : null,
      ),
      deviceId: deviceId,
      psk: psk,
    );
  }

  /// `http(s)://host:port` of the server hosting `/proxy/media`.
  final Uri httpBase;

  /// The paired device id, echoed back to the server to pick the verifying PSK.
  final String deviceId;

  /// The connection pre-shared key. Signs each proxied URL so the endpoint can
  /// only be driven by this authenticated client (see [RemoteControlCrypto]).
  final String psk;

  /// Rewrites [rawUrl] to a same-pairing `/proxy/media` URL. Returns [rawUrl]
  /// unchanged when it is empty or not an absolute `http(s)` URL (e.g. `data:`,
  /// `blob:`, asset, or relative URLs, which the client loads directly).
  ///
  /// When [maxWidth] is set, a `w` query param asks the proxy to downscale the
  /// image it serves to at most that many device pixels (it preserves aspect and
  /// never upscales). It is only meaningful for raster images — the proxy
  /// ignores it for ranged or non-image bodies (audio/video/documents). `w` is
  /// deliberately OUTSIDE the signature: the signed `u` still pins the exact
  /// upstream URL the proxy fetches, so `w` can only shrink the proxy's own
  /// already-authorised output — it cannot redirect the fetch or be used to scan
  /// (no SSRF surface). Each distinct `(url, w)` is a separate cache key,
  /// mirroring GitHub's per-`s` avatar caching — which is why [maxWidth] is
  /// bucketed UP to the shared media-width ladder (`bucketMediaWidth`) here:
  /// nearby display sizes then share one server cache entry and one
  /// `ImageCache` entry instead of minting one per size.
  String resolve(String rawUrl, {int? maxWidth}) {
    if (rawUrl.isEmpty) {
      return rawUrl;
    }
    // Memoized. Every call base64-encodes the URL, computes an HMAC and
    // rebuilds a Uri, and this is invoked from `build` — per avatar, per
    // favicon, per markdown image, on every rebuild — for a config that is
    // immutable once the connection is up. The width is bucketed to the shared
    // ladder before keying, so nearby sizes share an entry the same way they
    // share a server cache entry.
    final bucketed = maxWidth == null ? null : bucketMediaWidth(maxWidth);
    final key = '$bucketed\u0000$rawUrl';
    final cached = _resolved[key];
    if (cached != null) {
      return cached;
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return rawUrl;
    }
    final resolvedUrl = httpBase
        .replace(
          path: '/proxy/media',
          queryParameters: {
            'u': base64Url.encode(utf8.encode(rawUrl)),
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(rawUrl, psk),
            if (bucketed != null) 'w': '$bucketed',
          },
        )
        .toString();
    // Bounded: a long session scrolling a feed would otherwise retain a signed
    // URL for every image it ever saw. Oldest-first eviction is enough — this
    // is a pure function's memo, so a miss just re-signs.
    if (_resolved.length >= _maxResolved) {
      _resolved.remove(_resolved.keys.first);
    }
    _resolved[key] = resolvedUrl;
    return resolvedUrl;
  }

  /// Signed-URL memo, keyed by `(bucketed width, raw url)`.
  final Map<String, String> _resolved = {};

  /// Cap on retained signed URLs.
  static const int _maxResolved = 512;

  /// Builds the `/meeting/audio` URL that streams meeting [meetingId]'s recorded
  /// audio (the host's mixed WAV) for playback — the same on web and desktop, so
  /// playback never needs the file on the client's own disk. The canonical target
  /// `meeting-audio:<workspaceId>/<meetingId>` is signed with the connection PSK,
  /// mirroring [resolve]; the host re-derives the signature and serves the file
  /// only when the meeting belongs to [workspaceId].
  String meetingAudioUrl({
    required String workspaceId,
    required String meetingId,
  }) {
    final target = 'meeting-audio:$workspaceId/$meetingId';
    return httpBase
        .replace(
          path: '/meeting/audio',
          queryParameters: {
            'w': workspaceId,
            'm': meetingId,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(target, psk),
          },
        )
        .toString();
  }

  /// Builds the `/workspace/logo` URL that serves a workspace's persisted logo
  /// image — the same on web and desktop, so the mark never needs the file on
  /// the client's own disk. The canonical target `workspace-logo:$workspaceId`
  /// is signed with the connection PSK, mirroring [meetingAudioUrl]; the host
  /// re-derives the signature and serves the file only when it belongs to
  /// [workspaceId].
  String workspaceLogoUrl({required String workspaceId}) {
    final target = 'workspace-logo:$workspaceId';
    return httpBase
        .replace(
          path: '/workspace/logo',
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(target, psk),
          },
        )
        .toString();
  }

  /// Builds the `/blob` URL for a stored tool-result image — the screenshot an
  /// agent took while driving a browser, desktop or phone.
  ///
  /// [ref] is the `blob:sha256:<hex>` reference the transcript carries. Returns
  /// an empty string for anything that is not one, so a caller can treat the
  /// result as "no image" without a second validity check.
  ///
  /// The canonical target `blob:<workspaceId>:<hash>` is signed with the
  /// connection PSK, mirroring [workspaceLogoUrl]. There is no width parameter:
  /// the response is content-addressed and immutable, so it is cached by hash
  /// and resized client-side — a `w` here would fork the cache per display size
  /// for bytes that never change.
  String blobUrl({required String workspaceId, required String ref}) {
    const prefix = 'blob:sha256:';
    if (!ref.startsWith(prefix)) {
      return '';
    }
    final hash = ref.substring(prefix.length);
    if (hash.length != 64 || !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      return '';
    }
    final target = 'blob:$workspaceId:$hash';
    return httpBase
        .replace(
          path: '/blob',
          queryParameters: {
            'w': workspaceId,
            'h': hash,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(target, psk),
          },
        )
        .toString();
  }

  /// Builds the `POST /blob` URL the composer uploads an attached picture to.
  ///
  /// **Why the bytes go over HTTP and not the RPC socket.** `WsRemoteTransport`
  /// caps a single inbound frame at 256 KB and CLOSES the connection past it —
  /// so a base64 screenshot sent as a `blob.put` argument never arrived; it
  /// dropped the socket instead, and the message went out with its pictures
  /// silently missing. Bulk content rides the same HTTP lane as every other
  /// large payload here.
  ///
  /// The signed target is `blob-put:<workspaceId>` rather than the GET side's
  /// `blob:<workspaceId>:<hash>`, because the hash is what the upload produces:
  /// the client cannot sign for bytes the server has not stored yet.
  String blobUploadUrl({required String workspaceId}) {
    final target = 'blob-put:$workspaceId';
    return httpBase
        .replace(
          path: '/blob',
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(target, psk),
          },
        )
        .toString();
  }

  /// Builds the `GET /backup/workspace` URL that downloads [workspaceId]'s
  /// database to this device.
  ///
  /// The counterpart to the `workspace.export` op, and the reason both exist:
  /// the op writes a file on the SERVER and returns its path, which is a
  /// complete answer only when the server is this machine. Everywhere else the
  /// path names a file nobody here can open, so the export was a thing you
  /// could trigger and not collect. The signed target is
  /// `backup-workspace:<workspaceId>`; the host additionally requires the
  /// signer to be an ADMIN of that workspace, because this is its whole
  /// history.
  String backupWorkspaceUrl({required String workspaceId}) {
    return httpBase
        .replace(
          path: '/backup/workspace',
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(
              'backup-workspace:$workspaceId',
              psk,
            ),
          },
        )
        .toString();
  }

  /// Builds the `GET /backup/snapshot` URL that downloads install snapshot
  /// [name] as one archive.
  ///
  /// A snapshot is a DIRECTORY and a response carries one body, so the host
  /// zips it. It also holds every workspace on the install, which is why the
  /// host requires the signer to be the install's OPERATOR — a role in one
  /// workspace buys nothing here. The signed target is
  /// `backup-snapshot:<name>`.
  String backupSnapshotUrl({required String name}) {
    return httpBase
        .replace(
          path: '/backup/snapshot',
          queryParameters: {
            'n': name,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(
              'backup-snapshot:$name',
              psk,
            ),
          },
        )
        .toString();
  }

  /// Builds the `POST /backup/restore` URL that uploads a workspace database
  /// file and has the host adopt it as [workspaceId]'s.
  ///
  /// The mirror of [backupWorkspaceUrl], and it exists for the same reason:
  /// `workspace.import` takes a path on the SERVER, which a person sitting at
  /// another machine cannot produce. Here the bytes travel in the body. The
  /// signed target is `backup-restore:<workspaceId>`; the host requires the
  /// signer to be the workspace's OWNER, because adopting a file destroys
  /// everything that workspace currently holds.
  String backupRestoreUrl({required String workspaceId}) {
    return httpBase
        .replace(
          path: '/backup/restore',
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(
              'backup-restore:$workspaceId',
              psk,
            ),
          },
        )
        .toString();
  }

  /// Builds the `/proxy/font` URL for one variant of [family] — the bytes the
  /// client registers with Flutter's font loader.
  ///
  /// Note there is no URL parameter: the host resolves the file from its own
  /// catalogue, so this endpoint cannot be aimed anywhere. It exists because the
  /// client CANNOT fetch a font itself — upstreams pick their format from the
  /// `User-Agent`, serving browsers `woff2`, which Skia cannot decode and a
  /// `fetch()` cannot override that header. The canonical target
  /// `font:<family>/<subset>/<weight>/<style>` is signed with the connection PSK,
  /// mirroring [workspaceLogoUrl].
  String fontUrl({
    required String family,
    required int weight,
    required bool italic,
    String subset = 'latin',
  }) {
    final style = italic ? 'italic' : 'normal';
    final target = 'font:$family/$subset/$weight/$style';
    return httpBase
        .replace(
          path: '/proxy/font',
          queryParameters: {
            'f': family,
            'wt': '$weight',
            'st': style,
            'sub': subset,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(target, psk),
          },
        )
        .toString();
  }

  /// The canonical signed target for a soundscape stream. The stream identity is
  /// `(workspaceId, mood)` — weather and time-of-day adapt *within* one
  /// persistent connection (the server ramps the running mix), so the URL never
  /// has to change as the day/weather change. Listeners on the same
  /// `(workspaceId, mood)` share one server-side generative session.
  String _soundscapeTarget(String workspaceId, String mood) =>
      'soundscape:$workspaceId/$mood';

  /// Builds the `/rig/stream/<rigId>` URL that carries a rig's live frames.
  ///
  /// The signed target is `rig:<workspaceId>/<rigId>`, mirroring the other
  /// proxy routes. The size/fps/quality parameters sit OUTSIDE the signature
  /// deliberately: they can only shrink what the server already authorised for
  /// this viewer, so leaving them unsigned lets a panel renegotiate on resize
  /// without minting a new signature, and cannot widen access.
  String rigStreamUrl({
    required String workspaceId,
    required String rigId,
    required int width,
    required int height,
    int fps = 24,
    int quality = 70,
    String? guestKey,
  }) {
    final target = 'rig:$workspaceId/$rigId';
    return httpBase
        .replace(
          path: '/rig/stream/$rigId',
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(target, psk),
            'width': '$width',
            'height': '$height',
            'fps': '$fps',
            'quality': '$quality',
            // The guest's CURRENT display size, ignored by the server. Its
            // only job is to change the URL when the guest re-modes: the
            // in-guest capture keeps grabbing the geometry it opened with,
            // and when the screen GROWS x11grab silently crops the old
            // region instead of erroring — so without this the viewer shows
            // the previous screen size until some unrelated resize happens
            // to reconnect the stream.
            'g': ?guestKey,
          },
        )
        .toString();
  }

  /// Builds a `/rig/clipboard/<rigId>` or `/rig/files/<rigId>` URL.
  ///
  /// Signed with `rig-files:<workspaceId>/<rigId>` — a target of its own, NOT
  /// the watch lane's `rig:<…>`. Both come from the same device PSK, so this
  /// is not a new trust boundary; it is a legible one. A URL minted to watch
  /// a machine should not also, by being pasted somewhere, be able to write
  /// files into it.
  String _rigTransferUrl(
    String path,
    String workspaceId,
    String rigId, [
    Map<String, String> extra = const {},
  ]) => httpBase
      .replace(
        path: '$path/$rigId',
        queryParameters: {
          'w': workspaceId,
          'd': deviceId,
          's': RemoteControlCrypto.signProxyTarget(
            'rig-files:$workspaceId/$rigId',
            psk,
          ),
          ...extra,
        },
      )
      .toString();

  /// The `/rig/clipboard/<rigId>` URL. GET reads the guest's clipboard, POST
  /// writes it. [selection] picks which X selection to read (see
  /// `RigClipboardSelection`) and is ignored by a POST.
  String rigClipboardUrl({
    required String workspaceId,
    required String rigId,
    String? selection,
  }) => _rigTransferUrl('/rig/clipboard', workspaceId, rigId, {
    'sel': ?selection,
  });

  /// The `/rig/files/<rigId>` URL. POST drops files into the guest; GET with
  /// [guestPath] reads one back out.
  ///
  /// The path is base64url'd into a query parameter rather than placed in the
  /// URL path: a guest path carries slashes, spaces and anything else a Linux
  /// filesystem allows, and percent-encoding that into a path segment is a
  /// decoding argument nobody wins.
  String rigFilesUrl({
    required String workspaceId,
    required String rigId,
    String? guestPath,
  }) => _rigTransferUrl('/rig/files', workspaceId, rigId, {
    if (guestPath != null)
      'p': base64Url.encode(utf8.encode(guestPath)).replaceAll('=', ''),
  });

  /// The `/rig/stream/<rigId>?lane=audio` URL — the guest's sound as an
  /// MP3 stream, signed identically to the frame lane (the lane parameter
  /// selects between two streams the same viewer is already authorized for).
  String rigAudioUrl({required String workspaceId, required String rigId}) {
    final target = 'rig:$workspaceId/$rigId';
    return httpBase
        .replace(
          path: '/rig/stream/$rigId',
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(target, psk),
            'lane': 'audio',
          },
        )
        .toString();
  }

  /// Builds the infinite progressive-MP3 `/soundscape/stream` URL for the given
  /// [mood] in [workspaceId] — the primary transport on desktop and web. Signed
  /// with the connection PSK exactly like [meetingAudioUrl]; the host re-derives
  /// the signature from the paired device's stored PSK.
  String soundscapeStreamUrl({
    required String workspaceId,
    required String mood,
  }) {
    return httpBase
        .replace(
          path: '/soundscape/stream',
          queryParameters: {
            'w': workspaceId,
            'mood': mood,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(
              _soundscapeTarget(workspaceId, mood),
              psk,
            ),
          },
        )
        .toString();
  }

  /// Builds the HLS `/soundscape/playlist.m3u8` URL for the given [mood] — the
  /// transport used by the mobile PWA (native HLS + lock-screen media controls)
  /// and any client where an infinite progressive connection is unreliable
  /// through the relay. Segment URIs inside the playlist carry the same
  /// signature, so one signed target authorizes the playlist and all its
  /// segments.
  String soundscapePlaylistUrl({
    required String workspaceId,
    required String mood,
  }) {
    return httpBase
        .replace(
          path: '/soundscape/playlist.m3u8',
          queryParameters: {
            'w': workspaceId,
            'mood': mood,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(
              _soundscapeTarget(workspaceId, mood),
              psk,
            ),
          },
        )
        .toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaProxyConfig &&
          httpBase == other.httpBase &&
          deviceId == other.deviceId &&
          psk == other.psk;

  @override
  int get hashCode => Object.hash(httpBase, deviceId, psk);
}

/// Makes a [MediaProxyConfig] available to the widget subtree so remote-media
/// widgets can route their URLs through the host media proxy without each one
/// threading connection state.
///
/// Install it above the app on both the web/remote client and the desktop
/// (loopback `cc_server`); leaf widgets call [MediaProxyScope.urlOf] (which
/// no-ops when no scope is present — the not-yet-connected case).
class MediaProxyScope extends InheritedWidget {
  /// Creates a [MediaProxyScope].
  const MediaProxyScope({
    super.key,
    required this.config,
    required super.child,
  });

  /// The active proxy configuration for the subtree.
  final MediaProxyConfig config;

  /// Resolves [url] against the nearest [MediaProxyScope], or returns it
  /// unchanged when none is present (the not-yet-connected / direct-load case).
  ///
  /// [maxWidth] (device pixels) asks the host proxy to downscale a served raster
  /// image; it is ignored when no scope is present and by the proxy for
  /// non-image bodies.
  static String urlOf(BuildContext context, String url, {int? maxWidth}) {
    final scope = context.dependOnInheritedWidgetOfExactType<MediaProxyScope>();
    return scope?.config.resolve(url, maxWidth: maxWidth) ?? url;
  }

  /// Like [urlOf] but WITHOUT subscribing the calling element to scope changes,
  /// so it is safe to call from `initState` or an async callback (where
  /// `dependOnInheritedWidgetOfExactType` is disallowed). The config is set once
  /// at boot and never changes for the app's lifetime, so not depending on it
  /// loses nothing. Used by the markdown image/video widgets, which kick their
  /// fetch off `initState`.
  static String resolveOf(BuildContext context, String url, {int? maxWidth}) {
    final scope = context.getInheritedWidgetOfExactType<MediaProxyScope>();
    return scope?.config.resolve(url, maxWidth: maxWidth) ?? url;
  }

  /// The `http(s)://host:port` base of the connected server (the origin hosting
  /// the proxy endpoints), or null when there is no ambient scope. Lets a caller
  /// build an ABSOLUTE same-server URL for a server route (e.g.
  /// `/proxy/vscode/<sid>/`) that must NOT be resolved against the client's own
  /// (web) origin — a relative such path would hit the Flutter SPA and route to
  /// go_router (`no routes for location`) instead of the server. Does not create
  /// a dependency (the config is boot-fixed), so it is safe from callbacks.
  static Uri? httpBaseOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<MediaProxyScope>();
    return scope?.config.httpBase;
  }

  /// The `/meeting/audio` playback URL for [meetingId] in [workspaceId], or null
  /// when there is no ambient proxy scope (no live connection) — the caller then
  /// hides the player. See [MediaProxyConfig.meetingAudioUrl].
  static String? meetingAudioUrlOf(
    BuildContext context, {
    required String workspaceId,
    required String meetingId,
  }) {
    final scope = context.getInheritedWidgetOfExactType<MediaProxyScope>();
    return scope?.config.meetingAudioUrl(
      workspaceId: workspaceId,
      meetingId: meetingId,
    );
  }

  /// The `/workspace/logo` URL for [workspaceId], or null when there is no
  /// ambient proxy scope (no live connection) — the caller then falls back to
  /// the workspace initial. See [MediaProxyConfig.workspaceLogoUrl].
  static String? workspaceLogoUrlOf(
    BuildContext context, {
    required String workspaceId,
  }) {
    final scope = context.getInheritedWidgetOfExactType<MediaProxyScope>();
    return scope?.config.workspaceLogoUrl(workspaceId: workspaceId);
  }

  /// The `/blob` URL for a stored tool-result image, or null when there is no
  /// ambient proxy scope (no live connection) or [ref] is not a
  /// `blob:sha256:<hex>` reference — the caller then renders an unavailable
  /// placeholder rather than a broken image.
  /// See [MediaProxyConfig.blobUrl].
  static String? blobUrlOf(
    BuildContext context, {
    required String workspaceId,
    required String ref,
  }) {
    final scope = context.getInheritedWidgetOfExactType<MediaProxyScope>();
    final url = scope?.config.blobUrl(workspaceId: workspaceId, ref: ref);
    return (url == null || url.isEmpty) ? null : url;
  }

  /// The `/rig/stream/<rigId>` URL for a live rig, or null when there is no
  /// ambient proxy scope (no live connection) — the caller then shows the
  /// disconnected state rather than an empty canvas.
  static String? rigStreamUrlOf(
    BuildContext context, {
    required String workspaceId,
    required String rigId,
    required int width,
    required int height,
    int fps = 24,
    int quality = 70,
    String? guestKey,
  }) {
    final scope = context.getInheritedWidgetOfExactType<MediaProxyScope>();
    return scope?.config.rigStreamUrl(
      workspaceId: workspaceId,
      rigId: rigId,
      width: width,
      height: height,
      fps: fps,
      quality: quality,
      guestKey: guestKey,
    );
  }

  /// The rig's audio-lane URL, or null with no ambient proxy scope.
  static String? rigAudioUrlOf(
    BuildContext context, {
    required String workspaceId,
    required String rigId,
  }) {
    final scope = context.getInheritedWidgetOfExactType<MediaProxyScope>();
    return scope?.config.rigAudioUrl(workspaceId: workspaceId, rigId: rigId);
  }

  /// The ambient proxy config, or null when there is no live connection.
  ///
  /// The rig clipboard and file lanes need SEVERAL URLs off one config over
  /// the life of a gesture (write the clipboard, then fetch a file, then
  /// another), so they take the config once rather than reaching back into
  /// the tree from an async callback where `context` may already be stale.
  static MediaProxyConfig? configOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MediaProxyScope>()?.config;

  /// The `/soundscape/stream` (infinite MP3) URL for [mood] in [workspaceId], or
  /// null when there is no ambient proxy scope (no live connection) — the caller
  /// then hides the player. See [MediaProxyConfig.soundscapeStreamUrl].
  static String? soundscapeStreamUrlOf(
    BuildContext context, {
    required String workspaceId,
    required String mood,
  }) {
    final scope = context.getInheritedWidgetOfExactType<MediaProxyScope>();
    return scope?.config.soundscapeStreamUrl(
      workspaceId: workspaceId,
      mood: mood,
    );
  }

  /// The `/soundscape/playlist.m3u8` (HLS) URL for [mood] in [workspaceId], or
  /// null when there is no ambient proxy scope. See
  /// [MediaProxyConfig.soundscapePlaylistUrl].
  static String? soundscapePlaylistUrlOf(
    BuildContext context, {
    required String workspaceId,
    required String mood,
  }) {
    final scope = context.getInheritedWidgetOfExactType<MediaProxyScope>();
    return scope?.config.soundscapePlaylistUrl(
      workspaceId: workspaceId,
      mood: mood,
    );
  }

  @override
  bool updateShouldNotify(MediaProxyScope oldWidget) =>
      config != oldWidget.config;
}
