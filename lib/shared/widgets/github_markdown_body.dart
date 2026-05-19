import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:chewie/chewie.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/utils/raster_header_size.dart';
import 'package:control_center/shared/utils/video_embed_adapter.dart';
import 'package:control_center/shared/widgets/github_link_handler.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:control_center/shared/widgets/video_embed_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

/// Renders GitHub-flavoured markdown into Flutter widgets via the cc_markdown
/// engine, supporting `<details>` blocks (engine-parsed), image attachments,
/// inline video embeds, footnotes, and GitHub reference chips.
class GitHubMarkdownBody extends ConsumerWidget {
  /// Creates a [GitHubMarkdownBody].
  const GitHubMarkdownBody({
    super.key,
    required this.data,
    this.repoOwner,
    this.repoName,
    this.styleOverride,
    this.linkBuilder,
    this.compact = false,
    this.codeFontFamily,
    this.codeLigatures = true,
    this.bodyHtml,
    this.attachmentsPending = false,
    this.onAttachmentLoadFailed,
    this.onSwitchToRepo,
    this.githubToken = '',
    this.embedVideos = false,
  });

  /// The raw markdown string to render.
  final String data;

  /// Optional HTML version of [data] (GitHub's `body_html`). When provided,
  /// `github.com/user-attachments/assets/<uuid>` references in [data] are
  /// rewritten to the pre-signed `private-user-images.*` JWT URLs found in
  /// [bodyHtml] — the only way to load private repo attachments without a
  /// GitHub session cookie.
  final String? bodyHtml;

  /// True while [bodyHtml] is still being fetched asynchronously (e.g. the
  /// PR-list peek loads it in a second request after the row's raw markdown).
  ///
  /// When set, un-spliced `github.com/user-attachments/*` images render a
  /// loading placeholder instead of being fetched.
  final bool attachmentsPending;

  /// Invoked when an image fails to load and the source is a
  /// `private-user-images.*` URL (most likely a stale JWT). The parent can
  /// re-fetch `body_html` to refresh the URL map.
  final VoidCallback? onAttachmentLoadFailed;

  /// Called when a cross-repo GitHub link requires switching the active
  /// workspace and repo. Receives `(workspaceId, repoId)`.
  final Future<void> Function(String workspaceId, String repoId)?
  onSwitchToRepo;

  /// The GitHub repository owner (used for resolving relative issue/PR links).
  final String? repoOwner;

  /// The GitHub repository name (used for resolving relative issue/PR links).
  final String? repoName;

  /// Optional full stylesheet override. When null the unified
  /// [appMarkdownStyle] (honouring [compact]/[codeFontFamily]/[codeLigatures])
  /// is used.
  final CcMarkdownStyle? styleOverride;

  /// Optional `'link'` node-builder override — call sites with repo context
  /// pass a `GitHubReferenceLinkBuilder` to render PR/commit reference chips.
  /// Kept as an injected parameter (rather than imported here) so this shared
  /// widget never depends on the pr_review feature.
  final CcNodeBuilder? linkBuilder;

  /// Renders at the denser compact scale.
  final bool compact;

  /// Mono font family for code (falls back to the app default).
  final String? codeFontFamily;

  /// Whether programming ligatures render in fenced code.
  final bool codeLigatures;

  /// GitHub personal access token used for authenticated image fetches.
  final String githubToken;

  /// When true, standalone third-party video links (Loom, …) in the body are
  /// rendered as an inline [VideoEmbedView] instead of a plain link. Off by
  /// default so comment/chat surfaces aren't turned into webview farms — the
  /// PR description opts in.
  final bool embedVideos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = githubToken;
    final owner = repoOwner ?? '';
    final repo = repoName ?? '';

    // Preprocessing chain: strip HTML comments, splice private
    // attachment URLs from body_html, normalize <img>/<video> tags, embed
    // provider video links, then rewrite GitHub #/ow- references to the app's
    // control-center:// deep-link scheme. The engine parses <details> and
    // footnotes itself — no manual segmentation.
    final cleaned = stripHtmlComments(data);
    final attachmentMap = extractUserAttachmentUrls(bodyHtml);
    final videoUuids = extractUserAttachmentVideoUuids(bodyHtml);
    final spliced = rewriteUserAttachmentUrls(cleaned, urlMap: attachmentMap);
    final mediaProcessed = preprocessHtmlMediaTags(spliced);
    final embedded = embedVideos
        ? preprocessVideoEmbeds(mediaProcessed)
        : mediaProcessed;
    final processed = preprocessGitHubReferences(
      embedded,
      owner: owner,
      repo: repo,
    );

    final style =
        styleOverride ??
        appMarkdownStyle(
          context,
          compact: compact,
          codeFontFamily: codeFontFamily,
          codeLigatures: codeLigatures,
        );
    final builders = linkBuilder == null
        ? githubMarkdownBuilders
        : githubMarkdownBuilders.withOverrides({'link': linkBuilder!});

    return CcMarkdown(
      data: processed,
      selectable: true,
      style: style,
      plugins: githubMarkdownPlugins,
      options: githubMarkdownOptions,
      builders: builders,
      codeBuilder: (code, language, {required bool cache}) =>
          buildSharedCodeBlock(
            context,
            code,
            language,
            codeFontFamily: codeFontFamily,
            codeLigatures: codeLigatures,
            cache: cache,
          ),
      imageBuilder: (url, alt, title) {
        final uri = Uri.tryParse(url);
        if (uri == null) {
          return Text(alt ?? url);
        }
        // A standalone provider link (Loom, …) was rewritten to an image by
        // preprocessVideoEmbeds — swap it for an inline embedded player. The
        // markdown `title` carries the original link for the external-open
        // fallback.
        if (embedVideos) {
          final match = VideoEmbedRegistry.instance.resolve(uri);
          if (match != null) {
            final source = (title != null && title.isNotEmpty)
                ? (Uri.tryParse(title) ?? uri)
                : uri;
            return VideoEmbedView(
              embedUrl: match.embedUrl,
              sourceUrl: source,
              providerName: match.adapter.providerName,
              aspectRatio: match.adapter.aspectRatio,
            );
          }
        }
        // body_html hasn't arrived yet, so this attachment is still its raw
        // `github.com/user-attachments/*` form — unfetchable without a browser
        // session. Show a placeholder rather than firing a doomed request.
        if (attachmentsPending && _isUnsplicedUserAttachment(uri)) {
          return const _AttachmentLoadingPlaceholder();
        }
        if (_isVideo(uri, videoUuids)) {
          final decoded = decodeAltWithDimensions(alt);
          return _VideoWidget(
            uri: uri,
            alt: decoded.alt,
            onAttachmentLoadFailed: onAttachmentLoadFailed,
          );
        }
        return _RemoteImageWidget(
          uri: uri,
          alt: alt,
          token: token,
          onAttachmentLoadFailed: onAttachmentLoadFailed,
        );
      },
      onTapLink: (href) => handleGitHubLink(
        context: context,
        ref: ref,
        href: href,
        currentOwner: owner,
        currentRepo: repo,
        onSwitchToRepo: onSwitchToRepo,
      ),
    );
  }
}

/// The widest an embedded markdown image is ever laid out at (logical px).
/// Shared by the layout cap in [_RemoteImageWidgetState.build] and the proxy
/// downscale hint in [_RemoteImageWidgetState._fetch], so the "we never render
/// wider than this" invariant the hint relies on can't silently drift. The
/// inline video player keeps its own cap.
const double _kMaxImageLogicalWidth = 800;

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

/// Renders a remote image inline. Fetches the bytes once on init, then
/// dispatches to an SVG or raster renderer based on the response's
/// `Content-Type` (with a `<svg` / `<?xml` byte-sniff fallback for servers
/// that return `application/octet-stream` or similar).
///
/// Doing one authoritative fetch lets us:
///   * Honour an SVG's intrinsic `width`/`height`/`viewBox` so badges and
///     other small SVGs render at their natural size instead of being
///     stretched to the full content width.
///   * Drop the previous URL-host whitelist for SVG detection — the response
///     is the source of truth.
class _RemoteImageWidget extends StatefulWidget {
  const _RemoteImageWidget({
    required this.uri,
    this.alt,
    this.token = '',
    this.onAttachmentLoadFailed,
  });

  final Uri uri;
  final String? alt;
  final String token;
  final VoidCallback? onAttachmentLoadFailed;

  @override
  State<_RemoteImageWidget> createState() => _RemoteImageWidgetState();
}

class _RemoteImageWidgetState extends State<_RemoteImageWidget> {
  _FetchResult? _result;
  Object? _error;
  bool _notifiedFailure = false;

  /// The fetched raster's intrinsic pixel size (decoded from the image header,
  /// not a full frame decode). Null until known, and for non-raster bytes
  /// (SVG). Lets un-hinted badges/icons render at natural size instead of
  /// stretching to the column width.
  Size? _intrinsicSize;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _RemoteImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uri != oldWidget.uri || widget.token != oldWidget.token) {
      _result = null;
      _error = null;
      _notifiedFailure = false;
      _intrinsicSize = null;
      _fetch();
    }
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
      // the body caps rendered images at [_kMaxImageLogicalWidth] logical px
      // (see the LayoutBuilder cap and the raster/SVG ConstrainedBoxes), so
      // requesting that many × devicePixelRatio device px is lossless while
      // sparing us a full-resolution PR screenshot over the wire. The proxy
      // re-encodes only oversized static rasters — it returns SVGs and animated
      // GIFs untouched (they don't raster-decode), so badges keep their
      // intrinsic size. See `resizeRasterToWidth` on the server.
      final dpr = _nonSubscribingDevicePixelRatio(context);
      final fetchUrl = MediaProxyScope.resolveOf(
        context,
        requested.toString(),
        maxWidth: (_kMaxImageLogicalWidth * dpr).ceil(),
      );
      final result = await _fetchImageBytes(url: fetchUrl, token: widget.token);
      final intrinsic = await _decodeIntrinsicSize(result.bytes);
      if (!mounted || widget.uri != requested) {
        return;
      }
      setState(() {
        _result = result;
        _intrinsicSize = intrinsic;
      });
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

  @override
  Widget build(BuildContext context) {
    // Dimensions come in via the alt-text sentinel — `flutter_markdown_plus`
    // strips URL fragments before invoking imageBuilder, so we can't use
    // the URL itself.
    final decoded = decodeAltWithDimensions(widget.alt);
    final hint = decoded.hint;
    final cleanAlt = decoded.alt;

    if (_error != null) {
      return _AttachmentCard(uri: widget.uri, alt: cleanAlt);
    }
    final result = _result;
    if (result == null) {
      // Tiny inline placeholder so badge-sized images don't reserve a tall
      // strip while loading. A large image will jump in size when it lands.
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: CcSpinner(size: 20),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxLayoutWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final cappedWidth = maxLayoutWidth.isFinite
            ? maxLayoutWidth.clamp(0.0, _kMaxImageLogicalWidth)
            : _kMaxImageLogicalWidth;

        if (_looksLikeSvg(result.contentType, result.bytes)) {
          final svg = utf8.decode(result.bytes, allowMalformed: true);
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

  Widget _buildSvg(
    String svg,
    ImageDimensionHint hint,
    double cappedWidth,
    String cleanAlt,
  ) {
    final intrinsic = _parseSvgIntrinsicSize(svg);

    double? targetWidth;
    if (hint.width != null) {
      targetWidth = hint.width!.clamp(0.0, cappedWidth);
    } else if (hint.widthPercent != null) {
      targetWidth = cappedWidth * hint.widthPercent!;
    } else if (intrinsic.width != null) {
      targetWidth = intrinsic.width!.clamp(0.0, cappedWidth);
    }
    final double? targetHeight = hint.height ?? intrinsic.height;

    final svgPicture = SvgPicture.string(
      svg,
      width: targetWidth,
      height: targetHeight,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => const SizedBox.shrink(),
      errorBuilder: (_, _, _) =>
          _AttachmentCard(uri: widget.uri, alt: cleanAlt),
    );

    // Intrinsic-sized (badges, icons): render at natural size, TIGHT — no
    // width-filling Align. Every image is an inline `WidgetSpan`, so a
    // full-width Align would make the badge occupy the whole line and push
    // adjacent text (and stretch a wrapping link's underline) — see the raster
    // path. A tight box keeps the badge inline with its text.
    if (targetWidth != null) {
      return SizedBox(
        width: targetWidth,
        height: targetHeight,
        child: svgPicture,
      );
    }

    // No usable intrinsic info — treat as a flowing illustration.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _kMaxImageLogicalWidth,
            maxHeight: 600,
          ),
          child: svgPicture,
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
    final intrinsic = _intrinsicSize;
    final double targetWidth;
    if (hint.width != null) {
      targetWidth = hint.width!.clamp(0.0, cappedWidth);
    } else if (hint.widthPercent != null) {
      targetWidth = cappedWidth * hint.widthPercent!;
    } else if (intrinsic != null) {
      // GitHub semantics: an un-hinted raster renders at its intrinsic pixel
      // size (a 16px badge is 16 logical px), capped to the column.
      targetWidth = intrinsic.width.clamp(0.0, cappedWidth);
    } else {
      targetWidth = cappedWidth;
    }
    // The bytes are already fetched, so this only caps the decode — it stops a
    // multi-thousand-pixel screenshot from decoding full-res into a <=800px
    // column. Width-only unless a height hint pins the box (preserves aspect).
    final cacheWidth = (targetWidth * devicePixelRatio).round();

    // Badge/icon-sized (narrower than the column): natural size, no
    // illustration chrome — a 20px check doesn't stretch blurry across the
    // card. Rendered TIGHT (no width-filling Align): cc_markdown embeds every
    // image as an inline `WidgetSpan`, so an Align that expanded to the
    // paragraph width would make the badge consume the whole line — pushing the
    // adjacent link text onto the next row and, since SonarQube wraps badges in
    // links, stretching the link's underline into a full-width "divider". A
    // tight box keeps the badge inline with its text (GitHub semantics); a
    // badge alone in its paragraph still sits at the left edge naturally.
    if (targetWidth < cappedWidth) {
      final double? targetHeight =
          hint.height ??
          (intrinsic != null && intrinsic.width > 0
              ? targetWidth * intrinsic.height / intrinsic.width
              : null);
      return ImageFade(
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
        errorBuilder: (context, error) =>
            _AttachmentCard(uri: widget.uri, alt: cleanAlt),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _kMaxImageLogicalWidth,
            maxHeight: 600,
          ),
          // Cross-fade the decoded frame in over a quiet surface instead of
          // popping it onto the page the moment the bytes decode. The bytes are
          // already fetched above; ResizeImage caps the decode (it stops a
          // multi-thousand-pixel screenshot from decoding full-res into a
          // <=800px column). Width-only unless a height hint pins the box.
          child: ImageFade(
            image: ResizeImage(
              MemoryImage(bytes),
              width: cacheWidth > 0 ? cacheWidth : null,
              height: hint.height != null
                  ? (hint.height! * devicePixelRatio).round()
                  : null,
            ),
            placeholder: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            width: targetWidth,
            height: hint.height,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            syncDuration: Duration.zero,
            errorBuilder: (context, error) =>
                _AttachmentCard(uri: widget.uri, alt: cleanAlt),
          ),
        ),
      ),
    );
  }
}

/// Inline video player for GitHub user-attachment videos (typically `.mov`
/// from screen recordings). Pre-signed URLs work without auth so we hand
/// the URL directly to `video_player`. Chewie wraps the player with
/// scrub/play/fullscreen controls.
class _VideoWidget extends StatefulWidget {
  const _VideoWidget({
    required this.uri,
    this.alt,
    this.onAttachmentLoadFailed,
  });

  final Uri uri;
  final String? alt;
  final VoidCallback? onAttachmentLoadFailed;

  @override
  State<_VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<_VideoWidget> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _error = false;
  bool _notifiedFailure = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _VideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uri != oldWidget.uri) {
      _disposeControllers();
      _error = false;
      _notifiedFailure = false;
      _init();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _chewie?.dispose();
    _video?.dispose();
    _chewie = null;
    _video = null;
  }

  Future<void> _init() async {
    // See _RemoteImageWidget._fetch: a fresh JWT changes the URL mid-flight,
    // so ignore a completion for a URI we're no longer showing.
    final requested = widget.uri;
    // Play through the host media proxy: the server fetches the (often
    // pre-signed / private) source and re-serves it with Range support so the
    // player can seek. No-op when no proxy scope is present.
    final playUrl = MediaProxyScope.resolveOf(context, requested.toString());
    final controller = VideoPlayerController.networkUrl(Uri.parse(playUrl));
    try {
      await controller.initialize();
      if (!mounted || widget.uri != requested) {
        await controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _chewie = ChewieController(
          videoPlayerController: controller,
          aspectRatio: controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio,
          autoPlay: false,
          looping: false,
          showControlsOnInitialize: false,
          // Auto-hide the controls overlay ~1s after playback starts (Chewie's
          // default is 3s, which lingers over the video). Hovering the player
          // restarts this timer, so controls still reveal on mouse-over.
          hideControlsTimer: const Duration(seconds: 1),
          allowFullScreen: true,
          allowMuting: true,
        );
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted || widget.uri != requested) {
        return;
      }
      setState(() => _error = true);
      // Likely a stale 5-minute JWT — parent can refresh the URL map.
      if (!_notifiedFailure &&
          requested.host.toLowerCase() ==
              'private-user-images.githubusercontent.com') {
        _notifiedFailure = true;
        widget.onAttachmentLoadFailed?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return _AttachmentCard(uri: widget.uri, alt: widget.alt);
    }
    final chewie = _chewie;
    final video = _video;
    if (chewie == null || video == null) {
      return _VideoLoadingCard(uri: widget.uri, alt: widget.alt);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : double.infinity;
            final cappedWidth = maxWidth.isFinite
                ? maxWidth.clamp(0.0, 800.0)
                : 800.0;
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: cappedWidth,
                maxHeight: 600,
              ),
              child: AspectRatio(
                aspectRatio: video.value.aspectRatio == 0
                    ? 16 / 9
                    : video.value.aspectRatio,
                child: Chewie(controller: chewie),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VideoLoadingCard extends StatelessWidget {
  const _VideoLoadingCard({required this.uri, this.alt});

  final Uri uri;
  final String? alt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.12),
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const CcSpinner(),
      ),
    );
  }
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

const Set<String> _videoExtensions = {'.mov', '.mp4', '.m4v', '.webm'};

final RegExp _uuidInPath = RegExp(
  r'[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}',
  caseSensitive: false,
);

/// `true` when [uri] points at a video asset GitHub serves through
/// user-attachments. First checks the URL extension (works after the splice
/// has rewritten to a `private-user-images.*.mov?jwt=...` URL); if no
/// extension is present, falls back to matching any UUID in the URL path
/// against [knownVideoUuids] (lets us still dispatch to the video player
/// even when bodyHtml is missing or splicing didn't run).
bool _isVideo(Uri uri, Set<String> knownVideoUuids) {
  final path = uri.path.toLowerCase();
  for (final ext in _videoExtensions) {
    if (path.endsWith(ext)) {
      return true;
    }
  }
  if (knownVideoUuids.isEmpty) {
    return false;
  }
  for (final m in _uuidInPath.allMatches(uri.toString())) {
    if (knownVideoUuids.contains(m.group(0)!.toLowerCase())) {
      return true;
    }
  }
  return false;
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
/// Redirects are followed manually so a GitHub bearer token can ride the first
/// hop (for `private-user-images.*` etc.) and be stripped before the cross-host
/// hop to S3 — the native, no-proxy fallback path. On web the browser follows
/// redirects opaquely (so `followRedirects = false` is a no-op there), but every
/// web fetch goes through the proxy, which performs the redirect chain and
/// credential handling server-side and returns the bytes in one hop. Returns the
/// body bytes together with the response's `Content-Type` so the caller can
/// decide whether to decode as SVG or raster.
Future<_FetchResult> _fetchImageBytes({
  required String url,
  required String token,
}) async {
  final client = http.Client();
  try {
    var uri = Uri.parse(url);
    var sendAuth = token.isNotEmpty && _shouldAuth(uri);

    for (var hop = 0; hop < 10; hop++) {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['Accept'] = 'image/*,*/*;q=0.8';
      if (sendAuth) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final response = await client.send(request);

      if (response.isRedirect) {
        // `http` lower-cases response header names.
        final location = response.headers['location'];
        await response.stream.drain<void>();
        if (location == null) {
          throw Exception('Redirect without Location header: $uri');
        }
        final parsed = Uri.parse(location);
        final next = parsed.hasScheme ? parsed : uri.resolveUri(parsed);
        if (next.host.toLowerCase() != uri.host.toLowerCase()) {
          sendAuth = false;
        }
        uri = next;
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

      final bytes = await response.stream.toBytes();
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

// github.com/user-attachments/* is a web-only endpoint that requires browser
// session cookies — neither `Bearer <PAT>` nor `token <PAT>` works (both
// return 200 text/html signin page). For private attachments the renderer
// splices in pre-signed `private-user-images.*` URLs from `body_html` before
// this fetch is reached. Hit github.com anonymously here as a fallback so
// public-repo redirects to S3 still work.
bool _shouldAuth(Uri uri) {
  final host = uri.host.toLowerCase();
  return host == 'api.github.com' ||
      host == 'raw.githubusercontent.com' ||
      host == 'private-user-images.githubusercontent.com';
}

// Thrown when the server returns 200 OK but a non-image content-type — most
// commonly GitHub's signin HTML for private user-attachments hit with a PAT.
class _NotAnImageResponse implements Exception {
  const _NotAnImageResponse();
}

/// True when [uri] is still a raw `github.com/user-attachments/*` reference,
/// i.e. the `body_html` splice that rewrites it to a fetchable pre-signed
/// `private-user-images.*` URL hasn't run yet (body_html not loaded).
bool _isUnsplicedUserAttachment(Uri uri) =>
    uri.host.toLowerCase() == 'github.com' &&
    uri.path.startsWith('/user-attachments/');

/// Compact spinner shown in place of an attachment image while `body_html`
/// (which carries the fetchable pre-signed URL) is still loading. Sized to a
/// flowing illustration so the body doesn't jump when the real image lands.
class _AttachmentLoadingPlaceholder extends StatelessWidget {
  const _AttachmentLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.12),
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const CcSpinner(size: 22),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.uri, this.alt});

  final Uri uri;
  final String? alt;

  bool get _isUserAttachment =>
      uri.host.toLowerCase() == 'github.com' &&
      uri.path.startsWith('/user-attachments/');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = theme.hintColor;
    final hasAlt = alt?.isNotEmpty == true;
    final caption = _isUserAttachment
        ? 'Image hosted on GitHub'
        : 'Image · open externally';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => openExternalUrl(uri.toString()),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.dividerColor.withValues(alpha: 0.12),
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.image, size: 28, color: hint),
              const SizedBox(height: 8),
              Text(
                hasAlt ? alt! : caption,
                style: CcTypography.caption.copyWith(
                  color: context.ds.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.externalLink, size: 12, color: hint),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to open in GitHub',
                    style: CcTypography.caption.copyWith(color: hint),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
