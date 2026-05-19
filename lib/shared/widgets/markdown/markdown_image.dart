import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/core/media/media_disk_cache.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:control_center/shared/utils/media_width_ladder.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/utils/raster_header_size.dart';
import 'package:control_center/shared/widgets/image_viewer_labels.dart';
import 'package:control_center/shared/widgets/markdown/markdown_media_metrics.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

/// The widest an embedded markdown image is ever laid out at (logical px).
/// Shared by the layout cap in [_MarkdownImageState.build] and the proxy
/// downscale hint in [_MarkdownImageState._fetch], so the "we never render
/// wider than this" invariant the hint relies on can't silently drift. The
/// inline video player keeps its own cap.
const double kMaxMarkdownImageWidth = 800;

/// The tallest an embedded markdown image is ever laid out at (logical px).
/// Applied by scaling BOTH axes down (see [resolveMarkdownImageBox]), never by
/// pinning the box height on its own — a box that doesn't match the image's
/// aspect ratio is exactly what letterboxes it over the placeholder.
const double kMaxMarkdownImageHeight = 600;

/// How far into a response body the header probe keeps looking for pixel
/// dimensions. Every still format this app recognises declares them in its
/// first chunk; past this the probe is copying megabytes for nothing.
const int _headerProbeLimit = 64 * 1024;

/// Smallest laid-out edge (logical px) that still earns the expand affordance.
///
/// Set well above every badge and well below every screenshot. A shields.io
/// status badge is ~20px tall, a GitHub custom emoji ~18px; a real content
/// image — a screenshot, a diagram, a photo — is hundreds. The gap is wide
/// enough that a single threshold separates them without a heuristic.
const double kMinExpandableImageExtent = 64;

/// Whether an image laid out at [width] × [height] is CONTENT — something a
/// reader would want bigger — rather than a badge inline with a sentence.
///
/// This is deliberately a question about the laid-out box, not about which
/// layout branch the image took. Conflating the two is what hid the affordance
/// from most PR screenshots: the raster path treats "narrower than the column"
/// as "is a badge", so a 600px screenshot in a 700px column rendered at its
/// intrinsic size with no expand and the selection I-beam over it —
/// indistinguishable from prose.
///
/// A null [height] means nothing revealed an aspect ratio, so the box is
/// width-driven and the width alone decides.
@visibleForTesting
bool isExpandableMarkdownImage({required double width, double? height}) =>
    width >= kMinExpandableImageExtent &&
    (height == null || height >= kMinExpandableImageExtent);

/// The source's height ÷ width, or null when nothing knows it.
///
/// Prefers [intrinsic] (measured from the bytes we actually hold) over the
/// author's declared pair: the media proxy may have downscaled the raster, and
/// a proxy resize preserves aspect, so the measured ratio is the truthful one
/// either way. The `width`/`height` attribute pair is the fallback for bytes we
/// couldn't measure.
double? _aspectRatioOf(ImageDimensionHint hint, Size? intrinsic) {
  if (intrinsic != null && intrinsic.width > 0 && intrinsic.height > 0) {
    return intrinsic.height / intrinsic.width;
  }
  final w = hint.width;
  final h = hint.height;
  if (w != null && h != null && w > 0 && h > 0) {
    return h / w;
  }
  return null;
}

/// The box an embedded markdown image is laid out in: the width the column
/// allows, and the height that width implies through the source's aspect ratio.
@immutable
class MarkdownImageBox {
  /// Creates a [MarkdownImageBox].
  const MarkdownImageBox({required this.width, required this.height});

  /// Logical width the image is laid out at.
  final double width;

  /// Logical height, or null when neither the bytes nor the author's
  /// attributes revealed an aspect ratio (the image then sizes itself).
  final double? height;

  @override
  bool operator ==(Object other) =>
      other is MarkdownImageBox &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'MarkdownImageBox(${width}x$height)';
}

/// Resolves the layout box for an embedded raster.
///
/// The invariant this exists to hold: **the box always matches the image's
/// aspect ratio**. Every renderer here paints with [BoxFit.contain] over a
/// placeholder that stays behind the frame for the widget's whole life, so any
/// slack between box and image shows up as coloured bands — the letterboxing a
/// PR screenshot was rendering with.
///
/// [hint] carries the author's `width`/`height` attributes, which state the
/// image's NATURAL size (GitHub's uploader writes the pair verbatim). So a
/// `height` attribute is never used as the box height on its own: once the
/// width is clamped to [cappedWidth], the height has to come down with it.
/// [maxHeight] is likewise applied by scaling BOTH axes, never by clamping the
/// height alone — that would pillarbox instead of letterbox, same defect.
///
/// Public because it is the ONE box every media state resolves through — the
/// loaded raster, the reserved placeholder behind it, the failure card and the
/// inline video player. Two renderers computing "the box" separately is how a
/// loading state and a loaded state come to disagree by 400px.
MarkdownImageBox resolveMarkdownImageBox({
  required ImageDimensionHint hint,
  required Size? intrinsic,
  required double cappedWidth,
  double maxHeight = kMaxMarkdownImageHeight,
}) {
  final aspect = _aspectRatioOf(hint, intrinsic);

  double width;
  if (hint.width != null) {
    width = hint.width!.clamp(0.0, cappedWidth);
  } else if (hint.widthPercent != null) {
    width = (cappedWidth * hint.widthPercent!).clamp(0.0, cappedWidth);
  } else if (hint.height != null && aspect != null) {
    // Height-only hint: derive the width from it so the box keeps the aspect.
    width = (hint.height! / aspect).clamp(0.0, cappedWidth);
  } else if (intrinsic != null) {
    // GitHub semantics: an un-hinted raster renders at its intrinsic pixel
    // size (a 16px badge is 16 logical px), capped to the column.
    width = intrinsic.width.clamp(0.0, cappedWidth);
  } else {
    width = cappedWidth;
  }

  var height = aspect == null ? null : width * aspect;
  if (height != null && height > maxHeight) {
    width = width * maxHeight / height;
    height = maxHeight;
  }
  return MarkdownImageBox(width: width, height: height);
}

/// Reads the device pixel ratio WITHOUT registering an inherited dependency,
/// so it is safe to call from `initState` — mirroring [MediaProxyScope.resolveOf],
/// which the fetch also calls there. Falls back to 1.0 when there is no
/// [MediaQuery] ancestor (e.g. some headless tests).
double _nonSubscribingDevicePixelRatio(BuildContext context) =>
    context
        .getInheritedWidgetOfExactType<MediaQuery>()
        ?.data
        .devicePixelRatio ??
    1.0;

/// The ONE embedded-image renderer every markdown surface draws through — PR
/// bodies and review comments, agent transcripts, ticket descriptions, meeting
/// notes and artifacts alike — with the product-wide expand-to-fullscreen
/// affordance on anything large enough to be content.
///
/// It used to live inside `github_markdown_body.dart` as a private widget,
/// which meant the GitHub register got media-proxied, aspect-correct,
/// SVG-aware images and every other register got a bare `Image.network` from
/// the engine's fallback path. Same content, two behaviours, and only one of
/// them was the one anybody had thought about.
///
/// Fetches the bytes once on init, then dispatches to an SVG or raster
/// renderer based on the response's `Content-Type` (with a `<svg` / `<?xml`
/// byte-sniff fallback for servers that return `application/octet-stream` or
/// similar). Doing one authoritative fetch lets us:
///   * Honour an SVG's intrinsic `width`/`height`/`viewBox` so badges and
///     other small SVGs render at their natural size instead of being
///     stretched to the full content width.
///   * Drop the previous URL-host whitelist for SVG detection — the response
///     is the source of truth.
///   * Hand the lightbox the FULL-resolution bytes while the inline rendition
///     decodes capped to its column.
class MarkdownImage extends StatefulWidget {
  /// Creates a [MarkdownImage].
  const MarkdownImage({
    super.key,
    required this.uri,
    this.alt,
    this.onAttachmentLoadFailed,
    this.attachmentPending = false,
  });

  /// The image source (already rewritten by any preprocessing).
  final Uri uri;

  /// Alt text, VERBATIM from the source — it may still carry the dimension
  /// sentinel [decodeAltWithDimensions] decodes.
  final String? alt;

  /// Invoked when the fetch fails for a URL whose credentials go stale (a
  /// `private-user-images.*` JWT). The GitHub host re-fetches `body_html`.
  final VoidCallback? onAttachmentLoadFailed;

  /// True when the host is ALREADY fetching the credentials this URL needs
  /// (GitHub's `body_html`, which carries the pre-signed URL).
  ///
  /// Only suppresses the ASK — a raw `github.com/user-attachments/*` URL is
  /// recognised as unfetchable on its own, so the reserved box is held either
  /// way. Set it when the host has its own fetch in flight and a second
  /// request for one would be redundant.
  final bool attachmentPending;

  @override
  State<MarkdownImage> createState() => _MarkdownImageState();
}

class _MarkdownImageState extends State<MarkdownImage> {
  /// How long a deferred attachment waits for the host to splice in a usable
  /// URL before it admits defeat and shows the open-in-browser card.
  ///
  /// Bounded because the wait is not guaranteed to end: the host caps recovery
  /// refreshes, and a repo whose `body_html` never arrives would otherwise
  /// hold a loading box open for the life of the page.
  static const Duration _credentialGrace = Duration(seconds: 8);

  _FetchResult? _result;
  Object? _error;
  bool _notifiedFailure = false;
  Timer? _graceTimer;

  /// Pixel size read out of the response header mid-download, before the body
  /// finished. Upgrades the reserved box from a guessed aspect to the exact
  /// one, so the image fades into a hole of precisely its own shape.
  Size? _headerSize;

  /// Whether this image has already skipped a fetch because its token read as
  /// expired. Deliberately NOT reset by [didUpdateWidget] — the whole point is
  /// to notice that a refresh already happened and the verdict did not change.
  bool _deferredForExpiry = false;

  /// The fetched raster's intrinsic pixel size (decoded from the image header,
  /// not a full frame decode). Null until known and for non-raster bytes
  /// (SVG). Lets un-hinted badges/icons render at natural size instead of
  /// stretching to the column width.
  Size? _intrinsicSize;

  /// The SVG source and its parsed intrinsic size, decoded ONCE per fetch.
  ///
  /// Both used to be recomputed inside `build`: a `utf8.decode` of the whole
  /// body plus a regex scan for `width`/`height`, on every rebuild. A
  /// badge-heavy PR body re-decoded every badge on each ancestor rebuild.
  String? _svgSource;
  _SvgIntrinsic? _svgIntrinsic;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant MarkdownImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uri != oldWidget.uri ||
        widget.attachmentPending != oldWidget.attachmentPending) {
      _graceTimer?.cancel();
      _result = null;
      _error = null;
      _notifiedFailure = false;
      _intrinsicSize = null;
      _headerSize = null;
      _svgSource = null;
      _svgIntrinsic = null;
      _start();
    }
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    super.dispose();
  }

  /// Picks the load path for the current [MarkdownImage.uri]: the session
  /// payload cache, the deferred lane, or a network fetch.
  ///
  /// Safe to call from `initState` — the cache branch assigns fields directly
  /// (there is no frame to rebuild yet) and the deferred branch schedules its
  /// callback off the current frame.
  void _start() {
    final cached = _readCachedPayload(widget.uri);
    if (cached != null) {
      // Already measured and decoded this attachment in this session. Painting
      // it from the first frame is the whole point: a refreshed JWT changes
      // the URL but not the bytes, and re-fetching them is what used to reset
      // a settled image back to a 20px spinner mid-read.
      _result = cached.result;
      _intrinsicSize = cached.intrinsic;
      _svgSource = cached.svg;
      _svgIntrinsic = cached.svgIntrinsic;
      return;
    }
    final expired = hasExpiredAttachmentJwt(widget.uri);
    if (expired && _deferredForExpiry) {
      // A refresh already ran for this image and the token it produced ALSO
      // reads expired. At that point the likelier fault is this machine's
      // clock, not GitHub's minting, so stop trusting the reading and let the
      // server be the judge — which is what happened before the check existed.
      // Without this the loop is unbounded: each refresh mints a new URL,
      // `didUpdateWidget` clears the one-shot guard, and we ask again.
      _fetch();
      return;
    }
    if (widget.attachmentPending ||
        isUnsplicedUserAttachment(widget.uri) ||
        expired) {
      _deferredForExpiry = _deferredForExpiry || expired;
      _deferForCredentials();
      return;
    }
    _fetch();
  }

  /// Holds the reserved box while the host resolves a fetchable URL, instead of
  /// firing a request that CANNOT succeed.
  ///
  /// A raw `github.com/user-attachments/*` URL resolves only against a browser
  /// session cookie; through the proxy it returns 200 `text/html` (the sign-in
  /// page), which threw, painted the failure card, asked for a refresh and
  /// then reset for the spliced URL. Four layout passes to load one screenshot,
  /// and three of them were known to be doomed before the first byte.
  void _deferForCredentials() {
    if (!widget.attachmentPending && !_notifiedFailure) {
      _notifiedFailure = true;
      final refresh = widget.onAttachmentLoadFailed;
      if (refresh != null) {
        // Off the current frame: this runs from `initState`/`didUpdateWidget`
        // and the host's handler invalidates providers, which a build may not.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            refresh();
          }
        });
      }
    }
    _graceTimer?.cancel();
    _graceTimer = Timer(_credentialGrace, () {
      if (mounted) {
        setState(() => _error = const _AttachmentCredentialsUnavailable());
      }
    });
  }

  static Future<Size?> _decodeIntrinsicSize(Uint8List bytes) async {
    // Header parse FIRST, because `ui.ImageDescriptor` cannot answer this on
    // the web: `encoded` resolves but `width`/`height` throw
    // `UnsupportedError` there, so this probe used to come back null for every
    // image and the un-hinted branch in [_buildRaster] stretched each badge to
    // the column width (a 16px check painted blurry at ~500px on web while
    // desktop rendered it correctly).
    final header = rasterPixelSizeFromHeader(bytes);
    if (header != null) {
      return Size(header.width.toDouble(), header.height.toDouble());
    }
    // Covers what the parser doesn't (HEIF/AVIF via a platform codec).
    // Native-only: on web this stays null, exactly as it did before.
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      return Size(descriptor.width.toDouble(), descriptor.height.toDouble());
    } catch (_) {
      // Not a decodable raster (e.g. SVG bytes) — the SVG path sizes itself.
      return null;
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  Future<void> _fetch() async {
    // Capture the URI this fetch is for. A body_html refresh mints a fresh
    // JWT, so the spliced URL changes and `didUpdateWidget` starts a new
    // fetch — but the previous (stale-URL) fetch is still in flight. Without
    // this guard its late completion would clobber the fresh success with an
    // error card AND fire `onAttachmentLoadFailed` again, looping the refresh.
    // Ignore any completion whose URI is no longer the one we're showing.
    final requested = widget.uri;
    try {
      // Route through the host media proxy so the byte fetch hits `cc_server`
      // (which holds the gh credentials and is CORS-permissive) rather than the
      // upstream host directly. No-op when no proxy scope is present.
      //
      // Ask the proxy to downscale to the widest size we could ever display:
      // the body caps rendered images at [kMaxMarkdownImageWidth] logical px
      // (see the LayoutBuilder cap and the raster/SVG ConstrainedBoxes), so
      // requesting that many × devicePixelRatio device px is lossless while
      // sparing us a full-resolution PR screenshot over the wire. The proxy
      // re-encodes only oversized static rasters — it returns SVGs and animated
      // GIFs untouched (they don't raster-decode), so badges keep their
      // intrinsic size. See `resizeRasterToWidth` on the server.
      final dpr = _nonSubscribingDevicePixelRatio(context);
      final decodeWidth = (kMaxMarkdownImageWidth * dpr).ceil();
      final fetchUrl = MediaProxyScope.resolveOf(
        context,
        requested.toString(),
        maxWidth: decodeWidth,
      );

      // The disk cache is keyed by the media's STABLE identity, not by the
      // signed URL: a refreshed JWT is a different URL for the same bytes, so a
      // URL-keyed entry would miss on exactly the refresh it should absorb —
      // and would store a fresh copy of the same screenshot every five minutes.
      // The proxy's downscale width is part of the key because it is part of
      // what the bytes ARE (a 1x and a 2x display get different renditions).
      //
      // Restricted to GitHub attachment media, which is where the win is (a PR
      // full of megabyte screenshots) and where the risk is not. A cached body
      // carries no `Content-Type`, so a document that identified itself only by
      // header — an SVG whose bytes start with a DOCTYPE the sniff does not
      // recognise — would render once and fail on every load afterwards.
      // Attachments are screenshots and recordings; badges keep the plain path.
      final diskKey =
          '${markdownMediaKey(requested)}|w'
          '${bucketMediaWidth(decodeWidth)}';
      final cache = isGitHubAttachmentMedia(requested) ? mediaDiskCache : null;

      // One load per (media, width), shared with any other widget already
      // waiting on it — the same image in the description and in a comment, or
      // a row that rebuilt while its first fetch was in flight.
      final existing = _inflightFetches[diskKey];
      final _MediaPayload payload;
      if (existing != null) {
        payload = await existing;
      } else {
        final future = _loadPayload(
          requested: requested,
          fetchUrl: fetchUrl,
          diskKey: diskKey,
          cache: cache,
        );
        _inflightFetches[diskKey] = future;
        try {
          payload = await future;
        } finally {
          // Only the leader clears its own entry. `remove` hands back the
          // future it evicted — the one already awaited above — so discarding
          // it is the intent, not an oversight.
          if (identical(_inflightFetches[diskKey], future)) {
            unawaited(_inflightFetches.remove(diskKey));
          }
        }
      }
      _applyPayload(requested, payload);
    } catch (e) {
      if (!mounted || widget.uri != requested) {
        return;
      }
      setState(() => _error = e);
      // Same two failure modes that need a body_html refresh:
      //   1. `private-user-images.*` — pre-signed URL with a stale JWT.
      //   2. `github.com/user-attachments/*` — cached PR had no body_html,
      //      so splicing never ran; raw URL returns 200 text/html (signin).
      if (_notifiedFailure) {
        return;
      }
      final host = requested.host.toLowerCase();
      final path = requested.path;
      final shouldRetry =
          host == 'private-user-images.githubusercontent.com' ||
          (host == 'github.com' && path.startsWith('/user-attachments/'));
      if (shouldRetry) {
        _notifiedFailure = true;
        widget.onAttachmentLoadFailed?.call();
      }
    }
  }

  /// Acquires the bytes and everything derivable from them, ONCE.
  ///
  /// Deliberately does no `setState` and never touches `widget`: it is shared
  /// between widgets through [_inflightFetches], so its result has to be
  /// independent of which of them happened to lead. All the caches are written
  /// here, so a widget disposed mid-flight still pays its download forward
  /// rather than throwing it away.
  Future<_MediaPayload> _loadPayload({
    required Uri requested,
    required String fetchUrl,
    required String diskKey,
    required MediaDiskCache? cache,
  }) async {
    final onDisk = await cache?.peek(fetchUrl, cacheKey: diskKey);
    final fromDisk = onDisk != null && onDisk.isNotEmpty;
    final result = fromDisk
        ? _FetchResult(
            bytes: onDisk,
            // Nothing recorded the response header, so the SVG decision falls
            // to the byte sniff — which is what actually decides for every
            // server that answers `application/octet-stream` anyway.
            contentType: 'application/octet-stream',
          )
        : await _fetchImageBytes(
            url: fetchUrl,
            onDimensions: (size) {
              MarkdownMediaMetrics.record(requested, size);
              if (mounted && widget.uri == requested) {
                setState(() => _headerSize = size);
              }
            },
          );

    final intrinsic = await _decodeIntrinsicSize(result.bytes);
    final svg = _looksLikeSvg(result.contentType, result.bytes)
        ? utf8.decode(result.bytes, allowMalformed: true)
        : null;
    final svgIntrinsic = svg == null ? null : _parseSvgIntrinsicSize(svg);
    // Remember the shape under the attachment's stable identity, so every later
    // render of this image — a refreshed JWT, a recycled list row, a revisit —
    // reserves the final box from frame one instead of settling into it.
    final natural = intrinsic ?? _svgNaturalSize(svgIntrinsic);
    if (natural != null) {
      MarkdownMediaMetrics.record(requested, natural);
    }
    final payload = _MediaPayload(
      result: result,
      intrinsic: intrinsic,
      svg: svg,
      svgIntrinsic: svgIntrinsic,
    );
    _writeCachedPayload(requested, payload);
    // Survives a restart, unlike the in-process payload cache: a desktop paired
    // to a remote server otherwise re-downloads every screenshot in every PR it
    // reopens. Never an SVG — the stored copy loses its `Content-Type` and only
    // the byte sniff would be left to identify it.
    if (!fromDisk && svg == null) {
      unawaited(cache?.put(fetchUrl, result.bytes, cacheKey: diskKey));
    }
    return payload;
  }

  /// Shows [payload], if this widget is still the one that asked for it.
  void _applyPayload(Uri requested, _MediaPayload payload) {
    if (!mounted || widget.uri != requested) {
      return;
    }
    setState(() {
      _result = payload.result;
      _intrinsicSize = payload.intrinsic;
      _svgSource = payload.svg;
      _svgIntrinsic = payload.svgIntrinsic;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dimensions come in via the alt-text sentinel — the preprocessor strips
    // URL fragments before the image reaches a builder, so we can't use the
    // URL itself.
    final decoded = decodeAltWithDimensions(widget.alt);
    final hint = decoded.hint;
    final cleanAlt = decoded.alt;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxLayoutWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final cappedWidth = maxLayoutWidth.isFinite
            ? maxLayoutWidth.clamp(0.0, kMaxMarkdownImageWidth)
            : kMaxMarkdownImageWidth;

        final result = _result;
        if (_error != null || result == null) {
          // Deferred, loading and failed all lay out through the SAME box the
          // loaded image will occupy. That is the whole anti-flicker rule:
          // a body with three screenshots must reflow at most once per
          // screenshot — when its real shape is first learned — not once per
          // state transition.
          final reserved = _reservedBox(hint, cappedWidth);
          if (_error != null) {
            return _buildAttachmentCard(cleanAlt, reserved);
          }
          return _buildReservedPlaceholder(context, reserved, cappedWidth);
        }

        final svg = _svgSource;
        if (svg != null) {
          return _buildSvg(svg, hint, cappedWidth, cleanAlt);
        }
        return _buildRaster(
          result.bytes,
          hint,
          cappedWidth,
          cleanAlt,
          MediaQuery.devicePixelRatioOf(context),
        );
      },
    );
  }

  /// The box this image will occupy once loaded, resolved from what is known
  /// BEFORE any byte arrives: a size measured earlier in the session, the
  /// author's declared `width`/`height`, or the default attachment aspect.
  ///
  /// Null when nothing knows enough — an un-hinted badge from an arbitrary
  /// host — in which case the caller keeps the small inline placeholder rather
  /// than holding a column-wide hole open for a 20px check.
  MarkdownImageBox? _reservedBox(ImageDimensionHint hint, double cappedWidth) {
    final box = resolveMarkdownImageBox(
      hint: hint,
      intrinsic:
          _headerSize ??
          reservedMediaIntrinsic(
            uri: widget.uri,
            columnWidth: cappedWidth,
            // Both axes declared: the resolver derives the box from the hint
            // and a synthetic intrinsic would only outrank it (measured beats
            // declared).
            hasDimensionHint: hint.width != null && hint.height != null,
          ),
      cappedWidth: cappedWidth,
    );
    return box.height == null ? null : box;
  }

  /// A quiet surface holding [reserved] open while the bytes are in flight.
  ///
  /// Geometry mirrors [_buildRaster] branch for branch — the same tight box
  /// under the column width, the same vertical padding and corner radius at or
  /// above it — so the image lands into the space rather than displacing it.
  Widget _buildReservedPlaceholder(
    BuildContext context,
    MarkdownImageBox? reserved,
    double cappedWidth,
  ) {
    if (reserved == null) {
      // Tiny inline placeholder so badge-sized images don't reserve a tall
      // strip while loading.
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: CcSpinner(size: 20),
      );
    }
    final isContent = isExpandableMarkdownImage(
      width: reserved.width,
      height: reserved.height,
    );
    final surface = ColoredBox(
      color: context.ds.bgSecondary,
      child: isContent
          ? const Center(child: CcSpinner(size: 22))
          : const SizedBox.shrink(),
    );

    if (reserved.width < cappedWidth) {
      return SizedBox(
        width: reserved.width,
        height: reserved.height,
        child: surface,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: reserved.width,
          height: reserved.height,
          child: surface,
        ),
      ),
    );
  }

  /// The open-in-browser fallback, sized to [reserved] so a failure does not
  /// resize the page either.
  Widget _buildAttachmentCard(String cleanAlt, MarkdownImageBox? reserved) {
    return MarkdownAttachmentCard(
      uri: widget.uri,
      alt: cleanAlt,
      width: reserved?.width,
      height: reserved?.height,
    );
  }

  /// Wraps [inline] in the expand affordance when the laid-out box says the
  /// image is content ([isExpandableMarkdownImage]), and returns it untouched
  /// when it doesn't.
  ///
  /// The wrap adds no layout of its own — no padding, and no clip unless the
  /// caller asks for one — so a branch that opts in keeps the box it had.
  Widget _expandable({
    required Widget inline,
    required WidgetBuilder full,
    required String cleanAlt,
    required double width,
    required double? height,
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    if (!isExpandableMarkdownImage(width: width, height: height)) {
      return inline;
    }
    return CcExpandableImage(
      labels: appImageViewerLabels(context),
      title: cleanAlt.isEmpty ? null : cleanAlt,
      borderRadius: borderRadius,
      viewerBuilder: full,
      actions: [
        CcIconButton(
          icon: AppIcons.externalLink,
          size: CcButtonSize.sm,
          color: context.ds.textTertiary,
          tooltip: AppLocalizations.of(context).openInBrowser,
          onPressed: () => openExternalUrl(widget.uri.toString()),
        ),
      ],
      child: inline,
    );
  }

  Widget _buildSvg(
    String svg,
    ImageDimensionHint hint,
    double cappedWidth,
    String cleanAlt,
  ) {
    final intrinsic = _svgIntrinsic ?? _parseSvgIntrinsicSize(svg);
    final natural = (intrinsic.width != null && intrinsic.height != null)
        ? Size(intrinsic.width!, intrinsic.height!)
        : null;
    final aspect = _aspectRatioOf(hint, natural);

    double? targetWidth;
    if (hint.width != null) {
      targetWidth = hint.width!.clamp(0.0, cappedWidth);
    } else if (hint.widthPercent != null) {
      targetWidth = cappedWidth * hint.widthPercent!;
    } else if (intrinsic.width != null) {
      targetWidth = intrinsic.width!.clamp(0.0, cappedWidth);
    }
    // Same rule as the raster path: the height follows the (possibly clamped)
    // width through the aspect ratio, so `BoxFit.contain` never has slack to
    // letterbox. Falls back to the declared height only when no width is known.
    final double? targetHeight = (targetWidth != null && aspect != null)
        ? targetWidth * aspect
        : (hint.height ?? intrinsic.height);

    final svgPicture = SvgPicture.string(
      svg,
      width: targetWidth,
      height: targetHeight,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => const SizedBox.shrink(),
      errorBuilder: (_, _, _) => MarkdownAttachmentCard(
        uri: widget.uri,
        alt: cleanAlt,
        width: targetWidth,
        height: targetHeight,
      ),
    );

    Widget full(BuildContext _) => SvgPicture.string(svg, fit: BoxFit.contain);

    // Intrinsic-sized (badges, icons): render at natural size, TIGHT — no
    // width-filling Align. Every image is an inline `WidgetSpan`, so a
    // full-width Align would make the badge occupy the whole line and push
    // adjacent text (and stretch a wrapping link's underline) — see the raster
    // path. A tight box keeps the badge inline with its text.
    //
    // A LARGE intrinsic-sized SVG (a diagram exported at 500px) is still
    // content, so it takes the affordance without taking the chrome: the wrap
    // adds no padding and no clip, so the box it lays out in is unchanged.
    if (targetWidth != null) {
      return _expandable(
        cleanAlt: cleanAlt,
        full: full,
        width: targetWidth,
        height: targetHeight,
        inline: SizedBox(
          width: targetWidth,
          height: targetHeight,
          child: svgPicture,
        ),
      );
    }

    // No usable intrinsic info — treat as a flowing illustration.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _expandable(
        cleanAlt: cleanAlt,
        full: full,
        // Fills the column, so it is content by construction.
        width: cappedWidth,
        height: null,
        borderRadius: BorderRadius.circular(8),
        inline: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: kMaxMarkdownImageWidth,
              maxHeight: kMaxMarkdownImageHeight,
            ),
            child: svgPicture,
          ),
        ),
      ),
    );
  }

  Widget _buildRaster(
    Uint8List bytes,
    ImageDimensionHint hint,
    double cappedWidth,
    String cleanAlt,
    double devicePixelRatio,
  ) {
    final box = resolveMarkdownImageBox(
      hint: hint,
      intrinsic: _intrinsicSize,
      cappedWidth: cappedWidth,
    );
    final targetWidth = box.width;
    final targetHeight = box.height;

    // The bytes are already fetched, so this only caps the decode — it stops a
    // multi-thousand-pixel screenshot from decoding full-res into a <=800px
    // column. WIDTH ONLY, always: `ResizeImage` defaults to
    // `ResizeImagePolicy.exact`, which clamps each axis independently under
    // `allowUpscaling: false` — so handing it a width AND a height decodes a
    // NON-UNIFORM scale whenever only one axis is actually oversized. Asking
    // for 1600x1452 from an 1976x726 source produced a 1600x726 raster: the
    // width genuinely downscaled, the height clamped straight back to the
    // source, and the screenshot rendered 23% too tall.
    final cacheWidth = (targetWidth * devicePixelRatio).round();

    // The lightbox decodes the bytes UNCAPPED: the inline decode is capped to
    // the column, and handing the viewer that same 800px-wide raster would
    // make "expand" a blur — the one thing it exists to fix.
    Widget full(BuildContext _) => Image(
      image: MemoryImage(bytes),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    // Narrower than the column: natural size, no illustration chrome — a 20px
    // check doesn't stretch blurry across the card. Rendered TIGHT (no
    // width-filling Align): cc_markdown embeds every image as an inline
    // `WidgetSpan`, so an Align that expanded to the paragraph width would make
    // the badge consume the whole line — pushing the adjacent link text onto
    // the next row and, since SonarQube wraps badges in links, stretching the
    // link's underline into a full-width "divider". A tight box keeps the badge
    // inline with its text (GitHub semantics); a badge alone in its paragraph
    // still sits at the left edge naturally.
    //
    // This branch is NOT "the badge branch", which is the assumption that hid
    // the affordance from most screenshots: a 600px screenshot in a 700px
    // column lands here too, as does any portrait one the height cap scaled
    // down. So [_expandable] decides on the laid-out size and adds nothing to
    // the layout when it wraps.
    if (targetWidth < cappedWidth) {
      return _expandable(
        cleanAlt: cleanAlt,
        full: full,
        width: targetWidth,
        height: targetHeight,
        inline: ImageFade(
          image: ResizeImage(
            MemoryImage(bytes),
            width: cacheWidth > 0 ? cacheWidth : null,
          ),
          placeholder: const SizedBox.shrink(),
          width: targetWidth,
          height: targetHeight,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          syncDuration: Duration.zero,
          errorBuilder: (context, error) => MarkdownAttachmentCard(
            uri: widget.uri,
            alt: cleanAlt,
            width: targetWidth,
            height: targetHeight,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _expandable(
        cleanAlt: cleanAlt,
        full: full,
        width: targetWidth,
        height: targetHeight,
        borderRadius: BorderRadius.circular(8),
        inline: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: kMaxMarkdownImageWidth,
              maxHeight: kMaxMarkdownImageHeight,
            ),
            // Cross-fade the decoded frame in over a quiet surface instead of
            // popping it onto the page the moment the bytes decode. The bytes
            // are already fetched above; ResizeImage caps the decode (it stops
            // a multi-thousand-pixel screenshot from decoding full-res into a
            // <=800px column). The placeholder sits BEHIND the frame for the
            // widget's whole life, so any gap between the box and the image
            // shows as a coloured band — which is why the box is sized to the
            // aspect.
            child: ImageFade(
              image: ResizeImage(
                MemoryImage(bytes),
                width: cacheWidth > 0 ? cacheWidth : null,
              ),
              placeholder: ColoredBox(color: context.ds.bgSecondary),
              width: targetWidth,
              height: targetHeight,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              syncDuration: Duration.zero,
              errorBuilder: (context, error) => MarkdownAttachmentCard(
                uri: widget.uri,
                alt: cleanAlt,
                width: targetWidth,
                height: targetHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown in place of an image whose bytes could not be fetched or decoded —
/// most often a private GitHub attachment whose pre-signed URL has expired.
/// Tapping it opens the source in the browser, where a signed-in session can
/// still show it.
class MarkdownAttachmentCard extends StatelessWidget {
  /// Creates a [MarkdownAttachmentCard].
  const MarkdownAttachmentCard({
    super.key,
    required this.uri,
    this.alt,
    this.width,
    this.height,
  });

  /// The source that failed.
  final Uri uri;

  /// Alt text, shown in place of the generic caption when present.
  final String? alt;

  /// The box the image would have occupied, when the caller could reserve one.
  ///
  /// A failure that resizes the page is the same defect as a load that resizes
  /// it, so the card takes over the reserved geometry rather than imposing its
  /// own strip height. Falls back to a full-width 140px card when nothing knew
  /// the shape.
  final double? width;

  /// Height of the reserved box. See [width].
  final double? height;

  bool get _isUserAttachment => isUnsplicedUserAttachment(uri);

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    final l10n = AppLocalizations.of(context);
    final hasAlt = alt?.isNotEmpty == true;
    final caption = _isUserAttachment
        ? l10n.imageHostedOnGitHub
        : l10n.imageOpenExternally;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CcTappable(
        onPressed: () => openExternalUrl(uri.toString()),
        borderRadius: BorderRadius.circular(8),
        semanticLabel: hasAlt ? alt : caption,
        builder: (context, states) => Container(
          height: height ?? 140,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: states.contains(WidgetState.hovered)
                ? tokens.bgSecondaryHover
                : tokens.bgSecondary,
            border: Border.all(color: tokens.borderSecondary),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          // The card now inherits whatever box the image had reserved, and a
          // wide, short screenshot reserves a box shorter than this content.
          // Shed the optional rows rather than overflow: what a reader needs is
          // "there is media here and it opens in a browser", which survives
          // down to a single line.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final room = constraints.maxHeight;
              final showIcon = !room.isFinite || room >= 104;
              final showAction = !room.isFinite || room >= 64;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showIcon) ...[
                    Icon(AppIcons.image, size: 28, color: tokens.textTertiary),
                    const SizedBox(height: 8),
                  ],
                  Flexible(
                    child: Text(
                      hasAlt ? alt! : caption,
                      style: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showAction) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.externalLink,
                          size: 12,
                          color: tokens.textQuaternary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.openInBrowser,
                          style: CcTypography.caption.copyWith(
                            color: tokens.textQuaternary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The [CcImageBuilder] every non-GitHub markdown register passes to the
/// engine.
///
/// A top-level final, NOT a closure built in `build`: `CcStreamingMarkdown`
/// memoizes its settled blocks on the IDENTITY of the callbacks it was handed,
/// so a fresh lambda per rebuild would re-render every sealed block of a
/// streaming answer on every delta.
const CcImageBuilder appMarkdownImageBuilder = _buildAppMarkdownImage;

Widget _buildAppMarkdownImage(String url, String? alt, String? title) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    // A relative path has no host to fetch from outside a repo context; the
    // alt text is the only honest thing left to show.
    return Text(alt ?? url);
  }
  return MarkdownImage(uri: uri, alt: alt);
}

/// Decides whether [bytes] should be rendered as SVG. Trusts a `*svg*`
/// content-type first, then sniffs the head of the payload for `<svg` or
/// an XML prolog wrapping an `<svg>` — handles servers that return
/// `application/octet-stream` or generic `text/xml`.
bool _looksLikeSvg(String contentType, Uint8List bytes) {
  if (contentType.contains('svg')) {
    return true;
  }
  final headLen = bytes.length < 256 ? bytes.length : 256;
  final head = String.fromCharCodes(
    bytes.sublist(0, headLen),
  ).toLowerCase().trimLeft();
  return head.startsWith('<svg') ||
      (head.startsWith('<?xml') && head.contains('<svg'));
}

/// Intrinsic width/height parsed from an SVG document's root `<svg>` tag.
typedef _SvgIntrinsic = ({double? width, double? height});

/// Reads `width` / `height` (or `viewBox` as a fallback) from [svg]'s root
/// tag so badges can render at their natural size. Returns nulls for any
/// missing or non-numeric dimensions.
_SvgIntrinsic _parseSvgIntrinsicSize(String svg) {
  final m = RegExp(r'<svg\b([^>]*)>', caseSensitive: false).firstMatch(svg);
  if (m == null) {
    return (width: null, height: null);
  }
  final attrs = m.group(1)!;
  final w = _parseSvgDim(_extractSvgAttr(attrs, 'width'));
  final h = _parseSvgDim(_extractSvgAttr(attrs, 'height'));
  if (w != null && h != null) {
    return (width: w, height: h);
  }
  final vb = _extractSvgAttr(attrs, 'viewBox');
  if (vb != null) {
    final parts = vb.trim().split(RegExp(r'[\s,]+'));
    if (parts.length == 4) {
      return (
        width: w ?? double.tryParse(parts[2]),
        height: h ?? double.tryParse(parts[3]),
      );
    }
  }
  return (width: w, height: h);
}

String? _extractSvgAttr(String attrs, String name) {
  final m = RegExp(
    '\\b$name\\s*=\\s*["\']([^"\']*)["\']',
    caseSensitive: false,
  ).firstMatch(attrs);
  return m?.group(1);
}

double? _parseSvgDim(String? raw) {
  if (raw == null) {
    return null;
  }
  final trimmed = raw.trim();
  // Percentage = no intrinsic pixel value; let the fallback path size it.
  if (trimmed.endsWith('%')) {
    return null;
  }
  final m = RegExp(r'^([\d.]+)').firstMatch(trimmed);
  if (m == null) {
    return null;
  }
  return double.tryParse(m.group(1)!);
}

/// Raw bytes + observed Content-Type for a remote image, returned by
/// [_fetchImageBytes].
class _FetchResult {
  const _FetchResult({required this.bytes, required this.contentType});

  /// The full response body.
  final Uint8List bytes;

  /// Lower-cased `Content-Type` header, or `application/octet-stream` if the
  /// server didn't supply one.
  final String contentType;
}

/// Fetches [url] cross-platform via `package:http`, whose BrowserClient backs
/// the web build — the previous `dart:io` `HttpClient` only threw there (DDC /
/// dart2js stubs), so every PR-body image fell back to the attachment card even
/// though its URL was correctly rewritten to the media proxy.
///
/// **This request is anonymous.** The client holds no forge credential any
/// more, so a PRIVATE asset is readable only through the media proxy, which
/// attaches the server-side credential for the hosts that need one. Redirects
/// are still followed manually because the no-proxy fallback path takes the
/// cross-host hop to S3 itself. Returns the body bytes together with the
/// response's `Content-Type` so the caller can decide whether to decode as SVG
/// or raster.
///
/// [onDimensions] fires at most once, as soon as enough of the stream has
/// arrived to read the pixel size out of the format's header — well before the
/// body finishes. It never fires for bytes no header parser recognises (SVG,
/// AVIF/HEIF).
Future<_FetchResult> _fetchImageBytes({
  required String url,
  void Function(Size size)? onDimensions,
}) async {
  final client = http.Client();
  try {
    var uri = Uri.parse(url);

    for (var hop = 0; hop < 10; hop++) {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['Accept'] = 'image/*,*/*;q=0.8';

      final response = await client.send(request);

      if (response.isRedirect) {
        // `http` lower-cases response header names.
        final location = response.headers['location'];
        await response.stream.drain<void>();
        if (location == null) {
          throw Exception('Redirect without Location header: $uri');
        }
        final parsed = Uri.parse(location);
        uri = parsed.hasScheme ? parsed : uri.resolveUri(parsed);
        continue;
      }

      if (response.statusCode != 200) {
        await response.stream.drain<void>();
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: uri,
        );
      }

      final contentType =
          response.headers['content-type']?.toLowerCase() ??
          'application/octet-stream';

      // Private user-attachments hit with a PAT come back as 200 text/html
      // (the signin page). Bail before consuming the body so the fallback
      // card renders without attempting to decode HTML as an image.
      if (contentType.startsWith('text/html')) {
        await response.stream.drain<void>();
        throw const _NotAnImageResponse();
      }

      // Accumulate rather than `toBytes()` so the pixel dimensions can be
      // read out of the HEADER, mid-stream, and reported the moment they are
      // known. A screenshot is megabytes and its size is in the first packet;
      // waiting for the last byte to learn the shape means the page reflows
      // when the download FINISHES, which on anything but a warm loopback
      // server is a visible jolt seconds after the text rendered.
      final builder = BytesBuilder(copy: false);
      final probe = onDimensions;
      var probing = probe != null;
      await for (final chunk in response.stream) {
        builder.add(chunk);
        if (!probing) {
          continue;
        }
        if (builder.length > _headerProbeLimit) {
          // Past any still format's header. Stop copying; the full decode in
          // `_decodeIntrinsicSize` answers for whatever this is.
          probing = false;
          continue;
        }
        final header = rasterPixelSizeFromHeader(builder.toBytes());
        if (header != null) {
          probing = false;
          probe!(Size(header.width.toDouble(), header.height.toDouble()));
        }
      }
      final bytes = builder.takeBytes();
      if (bytes.isEmpty) {
        throw Exception('Empty image response: $uri');
      }
      return _FetchResult(bytes: bytes, contentType: contentType);
    }
    throw Exception('Too many redirects for $url');
  } finally {
    client.close();
  }
}

// Thrown when the server returns 200 OK but a non-image content-type — most
// commonly GitHub's signin HTML for private user-attachments hit with a PAT.
class _NotAnImageResponse implements Exception {
  const _NotAnImageResponse();
}

/// The deferred lane gave up: nothing ever spliced a fetchable URL in.
class _AttachmentCredentialsUnavailable implements Exception {
  const _AttachmentCredentialsUnavailable();
}

/// The natural size an SVG declared, when it declared both axes.
Size? _svgNaturalSize(_SvgIntrinsic? intrinsic) {
  final w = intrinsic?.width;
  final h = intrinsic?.height;
  if (w == null || h == null) {
    return null;
  }
  return Size(w, h);
}

/// Everything one fetch produced: the response, the measured raster size and
/// the decoded SVG source. Cached whole so a repeat render skips the fetch,
/// the header parse AND the utf8 decode.
class _MediaPayload {
  const _MediaPayload({
    required this.result,
    this.intrinsic,
    this.svg,
    this.svgIntrinsic,
  });

  final _FetchResult result;
  final Size? intrinsic;
  final String? svg;
  final _SvgIntrinsic? svgIntrinsic;

  int get cost => result.bytes.lengthInBytes;
}

/// Session cache of fetched media, keyed by [markdownMediaKey].
///
/// The point is the JWT refresh. A pre-signed attachment URL expires after five
/// minutes, so the host re-fetches `body_html` and the image's URL changes —
/// same bytes, new signature. Keying on the URL, that is a miss, and the widget
/// tore a settled screenshot back down to a spinner and re-downloaded it. Keyed
/// on the attachment's UUID it is a hit, and the refresh is invisible.
///
/// Bounded by BOTH entry count and total bytes: one 12MB screenshot must not be
/// able to evict a body's whole working set, and a long session browsing PRs
/// must not retain every image it ever saw.
final Map<String, _MediaPayload> _payloadCache = {};
var _payloadCacheBytes = 0;
const int _maxPayloadEntries = 48;
const int _maxPayloadBytes = 24 * 1024 * 1024;

/// Fetches in flight, keyed by [markdownMediaKey].
///
/// Two widgets showing one attachment in the same frame is the ordinary case —
/// a screenshot in the description and the same screenshot quoted in a comment,
/// or a list row rebuilding while its first fetch is still running. Without
/// this they each download it and each write the caches; the payload cache only
/// starts helping once one of them has finished.
final Map<String, Future<_MediaPayload>> _inflightFetches = {};

_MediaPayload? _readCachedPayload(Uri uri) {
  final key = markdownMediaKey(uri);
  final hit = _payloadCache.remove(key);
  if (hit != null) {
    _payloadCache[key] = hit; // refresh recency
  }
  return hit;
}

void _writeCachedPayload(Uri uri, _MediaPayload payload) {
  if (payload.cost > _maxPayloadBytes) {
    return;
  }
  final key = markdownMediaKey(uri);
  final previous = _payloadCache.remove(key);
  if (previous != null) {
    _payloadCacheBytes -= previous.cost;
  }
  _payloadCache[key] = payload;
  _payloadCacheBytes += payload.cost;
  while (_payloadCache.length > _maxPayloadEntries ||
      (_payloadCacheBytes > _maxPayloadBytes && _payloadCache.length > 1)) {
    final oldest = _payloadCache.keys.first;
    _payloadCacheBytes -= _payloadCache.remove(oldest)?.cost ?? 0;
  }
}

/// Empties the fetched-media cache.
@visibleForTesting
void resetMarkdownMediaPayloadCache() {
  _payloadCache.clear();
  _payloadCacheBytes = 0;
}
