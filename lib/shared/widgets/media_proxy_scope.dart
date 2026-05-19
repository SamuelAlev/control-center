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
  const MediaProxyConfig({
    required this.httpBase,
    required this.deviceId,
    required this.psk,
  });

  /// Builds a config from the live RPC connection's WebSocket [serverUri]
  /// (`ws(s)://host:port/rpc`), the paired [deviceId], and the connection [psk].
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
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return rawUrl;
    }
    return httpBase
        .replace(
          path: '/proxy/media',
          queryParameters: {
            'u': base64Url.encode(utf8.encode(rawUrl)),
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(rawUrl, psk),
            if (maxWidth != null) 'w': '${bucketMediaWidth(maxWidth)}',
          },
        )
        .toString();
  }

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

  /// Builds the `/proxy/font` URL for one variant of [family] — the bytes the
  /// client registers with Flutter's font loader.
  ///
  /// Note there is no URL parameter: the host resolves the file from its own
  /// catalogue, so this endpoint cannot be aimed anywhere. It exists because the
  /// client CANNOT fetch a font itself — upstreams pick their format from the
  /// `User-Agent`, serving browsers `woff2`, which Skia cannot decode, and a
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
