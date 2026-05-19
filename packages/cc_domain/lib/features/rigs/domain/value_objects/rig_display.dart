import 'dart:math' as math;

/// A display resolution in guest pixels.
class RigDisplaySize {
  /// Creates a [RigDisplaySize]. Both dimensions must be positive and even —
  /// odd dimensions break H.264 chroma subsampling and several guest mode-set
  /// paths, so they are rounded down at construction rather than failing a
  /// video encoder three layers away.
  factory RigDisplaySize(int width, int height) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Display size must be positive: ${width}x$height');
    }
    return RigDisplaySize._(
      width - (width.isOdd ? 1 : 0),
      height - (height.isOdd ? 1 : 0),
    );
  }

  const RigDisplaySize._(this.width, this.height);

  /// Width in guest pixels (always even).
  final int width;

  /// Height in guest pixels (always even).
  final int height;

  /// The default desktop size a rig boots at before a viewer negotiates one.
  static const RigDisplaySize defaultDesktop = RigDisplaySize._(1280, 800);

  /// The default phone-shaped viewport for the mobile surface.
  static const RigDisplaySize defaultMobile = RigDisplaySize._(1080, 1920);

  /// The ceiling for a frame sent to a MODEL (not to a human viewer).
  ///
  /// Anthropic's own computer-use guidance is that accuracy degrades above
  /// roughly this size while cost keeps climbing, so the agent lane downscales
  /// to fit inside it however large the actual display is. The human watch
  /// lane is deliberately NOT bound by this — that is the whole point of
  /// having two lanes.
  static const RigDisplaySize agentCeiling = RigDisplaySize._(1280, 800);

  /// The largest display a rig will negotiate. A viewer on a 6K monitor
  /// dragging a panel wide must not talk a guest into a mode that costs more
  /// to encode than the host can afford.
  static const RigDisplaySize negotiationCeiling = RigDisplaySize._(2560, 1600);

  /// The most DEVICE pixels a browser guest is asked to rasterise.
  ///
  /// [negotiationCeiling] bounds the CSS viewport, and for a long time that
  /// was the same thing — a guest rendered one device pixel per CSS pixel, so
  /// bounding one bounded the other. Rendering at the viewer's device pixel
  /// ratio broke that tie and, at 2x, quietly asked for FOUR times the raster
  /// work above a ceiling that exists because the guest cannot afford it.
  ///
  /// Measured, not guessed: a browser rig is a 2-vCPU microVM with no GPU, so
  /// every pixel is rasterised in software. At 1296x970 (1.26 MP) it kept up;
  /// at 2x — 2592x1940, 5.03 MP — its control channel stopped answering
  /// inside the timeout, and `Page.navigate` and `input.performActions` began
  /// timing out on Chromium and Firefox respectively. The same request is
  /// fine on a desktop browser with hardware acceleration, which is exactly
  /// why this is a budget and not a constant scale.
  static const int devicePixelBudget = 1400000;

  /// The smallest scale worth re-rendering a guest for.
  ///
  /// Below this the sharpening is invisible while the guest still pays the
  /// full cost of a mode change and re-raster, so a viewport that can only
  /// afford 1.05x renders at 1x instead of churning for nothing.
  static const double minWorthwhileScale = 1.25;

  /// The largest device-pixel scale this CSS size may be rendered at without
  /// exceeding [devicePixelBudget], never above [requested] and never below 1.
  ///
  /// A small panel has headroom and gets a sharp guest; a full-screen one does
  /// not and stays at 1x. That is the trade being made deliberately — a blurry
  /// picture is worse than a sharp one, and both are far better than a guest
  /// too busy to answer a click.
  double deviceScaleWithin(double requested) {
    if (!requested.isFinite || requested <= 1 || pixels <= 0) {
      return 1;
    }
    final affordable = math.sqrt(devicePixelBudget / pixels);
    final scale = requested < affordable ? requested : affordable;
    return scale < minWorthwhileScale ? 1 : scale;
  }

  /// Total pixels.
  int get pixels => width * height;

  /// This size scaled down to fit inside [bound], preserving aspect ratio.
  /// Returns `this` when it already fits — no upscaling, ever: enlarging a
  /// screenshot adds bytes and zero information.
  RigDisplaySize fitInside(RigDisplaySize bound) {
    if (width <= bound.width && height <= bound.height) {
      return this;
    }
    final scale = (bound.width / width) < (bound.height / height)
        ? bound.width / width
        : bound.height / height;
    return RigDisplaySize((width * scale).floor(), (height * scale).floor());
  }

  /// This size clamped to the negotiation ceiling.
  RigDisplaySize clampedForNegotiation() => fitInside(negotiationCeiling);

  /// JSON form.
  Map<String, dynamic> toJson() => {'width': width, 'height': height};

  /// Reads a size from [json], falling back to [fallback] when absent or
  /// malformed.
  static RigDisplaySize fromJson(
    Map<String, dynamic>? json, {
    RigDisplaySize fallback = defaultDesktop,
  }) {
    final w = json?['width'];
    final h = json?['height'];
    if (w is! int || h is! int || w <= 0 || h <= 0) {
      return fallback;
    }
    return RigDisplaySize(w, h);
  }

  @override
  String toString() => '${width}x$height';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RigDisplaySize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// The wire codec a watch-lane stream carries.
///
/// The server relays these bytes without decoding them — it is a pipe, not a
/// transcoder. Anything else would put video decoding on the server's isolate,
/// which is the one thing the code-index work established must never happen.
///
/// A codec is declared by the DRIVER, never by the viewer: the request carries
/// what the client can decode, but the bytes on the wire are whatever the
/// surface actually produces. Reporting the requested codec had the mobile
/// lane advertise MJPEG over raw H.264, which the viewer scanned for JPEG
/// markers forever.
enum RigStreamCodec {
  /// A stream of concatenated JPEG frames, no multipart framing.
  ///
  /// `video/x-motion-jpeg` and not `multipart/x-mixed-replace`, because that
  /// is literally what every surface sends: the guest agent's ffmpeg writes
  /// raw `-f mjpeg` output, and both other surfaces are normalised to match.
  /// Declaring multipart while emitting no boundary is a header that lies —
  /// and a viewer that trusted it (rather than resynchronising on SOI/EOI,
  /// which ours does) would never paint a frame.
  ///
  /// Universally decodable, no keyframe negotiation, high bitrate. The Tier 1
  /// default for every surface.
  mjpeg('mjpeg', 'video/x-motion-jpeg'),

  /// A stream of concatenated PNG frames, framed the same way [mjpeg] is —
  /// by the format's own markers, with nothing between them.
  ///
  /// Exists because ONE surface cannot produce JPEG: WebKit is driven over
  /// classic WebDriver, whose screenshot endpoint has no format parameter and
  /// answers PNG. The alternatives were both worse than a second codec — a
  /// host ffmpeg (which the mobile lane already needs, but demanding one to
  /// watch a BROWSER is a poor trade) or a server-side decode-and-re-encode,
  /// which is real CPU on the isolate that answers RPCs. The viewer decodes
  /// PNG as readily as JPEG; only the framing differs, and the content type
  /// says which.
  ///
  /// Bigger on the wire than JPEG for a photographic frame, which is part of
  /// why the polled lanes run at a handful of frames per second.
  mpng('mpng', 'video/x-motion-png'),

  /// A raw H.264 Annex-B elementary stream. Roughly an order of magnitude
  /// cheaper on the wire than MJPEG at the same quality, which is why every
  /// surface wants it eventually.
  ///
  /// NOT what the mobile lane serves today, though it is what Android's
  /// `screenrecord` produces: no viewer we ship decodes H.264, so the host
  /// transcodes to [mjpeg] and declares that. Relaying the device's bytes and
  /// calling them JPEG is precisely the bug this enum's "declared by the
  /// driver" rule exists to prevent.
  h264('h264', 'video/h264');

  const RigStreamCodec(this.wire, this.contentType);

  /// Stable wire/storage string.
  final String wire;

  /// The HTTP `Content-Type` the relay sets for this codec.
  final String contentType;

  /// Parses [value] back into a codec, or null when unknown.
  static RigStreamCodec? fromWire(String? value) {
    for (final c in RigStreamCodec.values) {
      if (c.wire == value) {
        return c;
      }
    }
    return null;
  }
}

/// What a viewer is asking the watch lane for.
///
/// This is a REQUEST, not a guarantee: the backend clamps every field, and the
/// rig reports what it actually settled on. A viewer that assumed it got what
/// it asked for would draw a 4K canvas around a 720p stream.
class RigWatchRequest {
  /// Creates a [RigWatchRequest].
  const RigWatchRequest({
    required this.size,
    this.fps = 15,
    this.quality = 70,
    this.codec = RigStreamCodec.mjpeg,
  });

  /// The size the viewer would like, normally its own canvas size in physical
  /// pixels.
  final RigDisplaySize size;

  /// Frames per second, 1–60.
  final int fps;

  /// JPEG quality 1–100 (ignored for H.264, which uses [bitrateCeiling]).
  final int quality;

  /// On a REQUEST, the codec the viewer can decode. On the negotiated result,
  /// what the driver actually emits — see [withCodec].
  final RigStreamCodec codec;

  /// This request with every field clamped to what the platform will actually
  /// serve. Applied server-side — a client cannot opt out of it.
  RigWatchRequest clamped() => RigWatchRequest(
    size: size.clampedForNegotiation(),
    fps: fps.clamp(1, 60),
    quality: quality.clamp(1, 100),
    codec: codec,
  );

  /// This request re-stamped with the codec the driver actually emits.
  ///
  /// The negotiation step no viewer can influence: a client never sends
  /// `codec`, so every request defaults to MJPEG, and reporting that back is
  /// how a raw H.264 lane came to be served with an MJPEG content type.
  RigWatchRequest withCodec(RigStreamCodec settled) =>
      RigWatchRequest(size: size, fps: fps, quality: quality, codec: settled);

  /// A bitrate ceiling (bits/second) proportionate to the negotiated size and
  /// rate, so a big canvas at a high frame rate cannot saturate the link.
  ///
  /// ~0.1 bits per pixel per frame is a deliberately conservative constant:
  /// it holds 1280x800@15 to roughly 1.5 Mbps and 2560x1600@30 to ~12 Mbps.
  /// Ignored by the MJPEG lane, which uses `quality` instead.
  int get bitrateCeiling {
    final raw = (size.pixels * fps * 0.1).round();
    return raw.clamp(250000, 16000000);
  }

  /// JSON form (used by the RPC surface and the stream URL builder).
  Map<String, dynamic> toJson() => {
    'width': size.width,
    'height': size.height,
    'fps': fps,
    'quality': quality,
    'codec': codec.wire,
  };

  /// Reads a request from loosely-typed [json] (query params or RPC args),
  /// clamping as it goes. Malformed fields fall back to defaults rather than
  /// throwing: a viewer sending a bad fps should get a stream, not a 400.
  static RigWatchRequest fromJson(Map<String, dynamic> json) {
    // A non-positive dimension is malformed, not a request — constructing
    // RigDisplaySize with it would throw, and this reader promises not to.
    int intOr(Object? v, int fallback) {
      final parsed = switch (v) {
        final int i => i,
        final String s => int.tryParse(s),
        _ => null,
      };
      return (parsed == null || parsed <= 0) ? fallback : parsed;
    }

    return RigWatchRequest(
      size: RigDisplaySize(
        intOr(json['width'], RigDisplaySize.defaultDesktop.width),
        intOr(json['height'], RigDisplaySize.defaultDesktop.height),
      ),
      fps: intOr(json['fps'], 15),
      quality: intOr(json['quality'], 70),
      codec:
          RigStreamCodec.fromWire(json['codec'] as String?) ??
          RigStreamCodec.mjpeg,
    ).clamped();
  }
}
