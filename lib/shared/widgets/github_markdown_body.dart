import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:control_center/shared/utils/video_embed_adapter.dart';
import 'package:control_center/shared/widgets/github_link_handler.dart';
import 'package:control_center/shared/widgets/video_embed_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class GitHubMarkdownBody extends ConsumerWidget {
  const GitHubMarkdownBody({
    super.key,
    required this.data,
    this.repoOwner,
    this.repoName,
    this.styleSheet,
    this.builders,
    this.checkboxBuilder,
    this.shrinkWrap = true,
    this.bodyHtml,
    this.attachmentsPending = false,
    this.onAttachmentLoadFailed,
    this.onSwitchToRepo,
    this.githubToken = '',
    this.embedVideos = false,
  });

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
  /// loading placeholder instead of being fetched. That raw URL can never load
  /// without a browser session cookie — and we deliberately don't attach the
  /// PAT to `github.com` — so attempting it just fails and flashes the
  /// attachment-card fallback. Waiting until [bodyHtml] arrives means the
  /// splice has rewritten the URL to a pre-signed `private-user-images.*` one
  /// that loads on the first try, matching the detail view (which always has
  /// `body_html` in hand before it renders).
  final bool attachmentsPending;

  /// Invoked when an image fails to load and the source is a
  /// `private-user-images.*` URL (most likely a stale JWT). The parent can
  /// re-fetch `body_html` to refresh the URL map.
  final VoidCallback? onAttachmentLoadFailed;

  /// Called when a cross-repo GitHub link requires switching the active
  /// workspace and repo. Receives `(workspaceId, repoId)`.
  final Future<void> Function(String workspaceId, String repoId)?
      onSwitchToRepo;

  final String? repoOwner;
  final String? repoName;
  final MarkdownStyleSheet? styleSheet;
  final Map<String, MarkdownElementBuilder>? builders;
  final MarkdownCheckboxBuilder? checkboxBuilder;
  final bool shrinkWrap;
  final String githubToken;

  /// When true, standalone third-party video links (Loom, …) in the body are
  /// rendered as an inline [VideoEmbedView] instead of a plain link. Off by
  /// default so comment/chat surfaces aren't turned into webview farms — the
  /// PR description opts in.
  final bool embedVideos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = githubToken;

    final effectiveOwner = repoOwner ?? '';
    final effectiveRepo = repoName ?? '';

    // Strip HTML comments first: flutter_markdown_plus has `encodeHtml: false`
    // so raw `<!-- ... -->` blocks end up visible (e.g. Renovate's
    // rebase-check / renovate-debug markers) and a comment touching a
    // paragraph can pull surrounding text into a CommonMark HTML block,
    // which silently kills nearby `[text](url)` links.
    final cleaned = stripHtmlComments(data);

    // Top-level `<details>` blocks become Flutter ExpansionTiles. Anything
    // between/around them is rendered as a regular markdown chunk. This
    // keeps the markdown→widget mapping linear and lets nested details
    // recurse naturally.
    final segments = _parseDetailsSegments(cleaned, defaultSummary: AppLocalizations.of(context).detailsLabel);
    if (segments.length == 1 && segments.first is _MarkdownSegment) {
      // Hot path: no <details> in the body — render a single MarkdownBody.
      return _renderMarkdown(
        context: context,
        ref: ref,
        text: cleaned,
        owner: effectiveOwner,
        repo: effectiveRepo,
        token: token,
      );
    }

    // No outer SelectionArea: it wraps the inline link TapGestureRecognizers
    // in SelectableRegion's pointer-handling, which silently swallows taps —
    // links show as styled but never fire onTapLink. MarkdownBody handles
    // selection itself via `selectable: true` (SelectableText.rich), which
    // preserves the recognizers.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final seg in segments)
          if (seg is _MarkdownSegment)
            _renderMarkdown(
              context: context,
              ref: ref,
              text: seg.text,
              owner: effectiveOwner,
              repo: effectiveRepo,
              token: token,
            )
          else if (seg is _DetailsSegment)
            _DetailsBlock(
              summary: seg.summary,
              body: seg.body,
              initiallyOpen: seg.initiallyOpen,
              repoOwner: repoOwner,
              repoName: repoName,
              styleSheet: styleSheet,
              builders: builders,
              checkboxBuilder: checkboxBuilder,
              bodyHtml: bodyHtml,
              attachmentsPending: attachmentsPending,
              onAttachmentLoadFailed: onAttachmentLoadFailed,
              onSwitchToRepo: onSwitchToRepo,
              githubToken: githubToken,
              embedVideos: embedVideos,
            ),
      ],
    );
  }

  Widget _renderMarkdown({
    required BuildContext context,
    required WidgetRef ref,
    required String text,
    required String owner,
    required String repo,
    required String token,
  }) {
    final hasRepoContext = owner.isNotEmpty && repo.isNotEmpty;
    final attachmentMap = extractUserAttachmentUrls(bodyHtml);
    final videoUuids = extractUserAttachmentVideoUuids(bodyHtml);
    final spliced = rewriteUserAttachmentUrls(text, urlMap: attachmentMap);
    final mediaProcessed = preprocessHtmlMediaTags(spliced);
    final embedded =
        embedVideos ? preprocessVideoEmbeds(mediaProcessed) : mediaProcessed;
    final processed = hasRepoContext
        ? preprocessGitHubReferences(
            embedded,
            owner: owner,
            repo: repo,
          )
        : embedded;

    return MarkdownBody(
      data: processed,
      selectable: true,
      styleSheet: styleSheet,
      builders: builders ?? const {},
      checkboxBuilder: checkboxBuilder,
      imageBuilder: (uri, title, alt) {
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
        // session. Show a placeholder rather than firing a request that's
        // guaranteed to 401/HTML. Once body_html lands, the splice rewrites it
        // to a pre-signed URL and this rebuilds into a real image.
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
      shrinkWrap: shrinkWrap,
      onTapLink: (text, href, title) => handleGitHubLink(
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

class _DetailsBlock extends StatelessWidget {
  const _DetailsBlock({
    required this.summary,
    required this.body,
    required this.initiallyOpen,
    this.repoOwner,
    this.repoName,
    this.styleSheet,
    this.builders,
    this.checkboxBuilder,
    this.bodyHtml,
    this.attachmentsPending = false,
    this.onAttachmentLoadFailed,
    this.onSwitchToRepo,
    this.githubToken = '',
    this.embedVideos = false,
  });

  final String summary;
  final String body;
  final bool initiallyOpen;
  final String? repoOwner;
  final String? repoName;
  final MarkdownStyleSheet? styleSheet;
  final Map<String, MarkdownElementBuilder>? builders;
  final MarkdownCheckboxBuilder? checkboxBuilder;
  final String? bodyHtml;
  final bool attachmentsPending;
  final VoidCallback? onAttachmentLoadFailed;
  final Future<void> Function(String workspaceId, String repoId)?
      onSwitchToRepo;
  final String githubToken;
  final bool embedVideos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Theme(
        // Strip the divider lines ExpansionTile draws by default — they
        // look out of place inside flowing markdown.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyOpen,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          // Render the summary as inline markdown so emphasis / links work.
          title: GitHubMarkdownBody(
            data: summary,
            repoOwner: repoOwner,
            repoName: repoName,
            styleSheet: styleSheet,
            builders: builders,
            checkboxBuilder: checkboxBuilder,
            bodyHtml: bodyHtml,
            attachmentsPending: attachmentsPending,
            onAttachmentLoadFailed: onAttachmentLoadFailed,
            onSwitchToRepo: onSwitchToRepo,
            githubToken: githubToken,
            embedVideos: embedVideos,
          ),
          children: [
            GitHubMarkdownBody(
              data: body,
              repoOwner: repoOwner,
              repoName: repoName,
              styleSheet: styleSheet,
              builders: builders,
              checkboxBuilder: checkboxBuilder,
              bodyHtml: bodyHtml,
              attachmentsPending: attachmentsPending,
              onAttachmentLoadFailed: onAttachmentLoadFailed,
              onSwitchToRepo: onSwitchToRepo,
              githubToken: githubToken,
              embedVideos: embedVideos,
            ),
          ],
        ),
      ),
    );
  }
}

/// Marker base for body segments produced by [_parseDetailsSegments].
sealed class _BodySegment {}

class _MarkdownSegment extends _BodySegment {
  _MarkdownSegment(this.text);
  final String text;
}

class _DetailsSegment extends _BodySegment {
  _DetailsSegment({
    required this.summary,
    required this.body,
    required this.initiallyOpen,
  });
  final String summary;
  final String body;
  final bool initiallyOpen;
}

/// Splits [markdown] into a flat list of markdown chunks and top-level
/// `<details>` blocks. Nested details are kept verbatim inside their
/// parent's body and unwrapped during recursive rendering — see
/// [_DetailsBlock] which calls back into [GitHubMarkdownBody].
///
/// Fenced code blocks are respected: `<details>` tags inside ``` fences
/// pass through as plain text.
List<_BodySegment> _parseDetailsSegments(String markdown, {String defaultSummary = 'Details'}) {
  if (markdown.isEmpty) {
    return [_MarkdownSegment(markdown)];
  }

  final fences = _findFencedRegions(markdown);
  final openRe = RegExp(r'<details\b([^>]*)>', caseSensitive: false);
  final closeRe = RegExp(r'</details\s*>', caseSensitive: false);

  final segments = <_BodySegment>[];
  var cursor = 0;

  while (cursor < markdown.length) {
    // Locate next <details> opening tag outside any fenced region.
    Match? openMatch;
    int openStartGlobal = -1;
    var searchFrom = cursor;
    while (searchFrom < markdown.length) {
      final m = openRe.firstMatch(markdown.substring(searchFrom));
      if (m == null) {
        break;
      }
      final globalStart = searchFrom + m.start;
      if (!_insideRegion(globalStart, fences)) {
        openMatch = m;
        openStartGlobal = globalStart;
        break;
      }
      searchFrom += m.end;
    }

    if (openMatch == null) {
      segments.add(_MarkdownSegment(markdown.substring(cursor)));
      break;
    }

    if (openStartGlobal > cursor) {
      segments.add(
        _MarkdownSegment(markdown.substring(cursor, openStartGlobal)),
      );
    }

    final openEndGlobal = searchFrom + openMatch.end;
    final attrs = openMatch.group(1) ?? '';
    final initiallyOpen =
        RegExp(r'\bopen\b', caseSensitive: false).hasMatch(attrs);

    // Walk forward, tracking nesting depth, to find the matching close.
    var depth = 1;
    var pos = openEndGlobal;
    int? closeStart;
    int? closeEnd;
    while (pos < markdown.length && depth > 0) {
      final rest = markdown.substring(pos);
      final nextOpen = openRe.firstMatch(rest);
      final nextClose = closeRe.firstMatch(rest);
      if (nextClose == null) {
        break;
      }
      final nextOpenGlobal = nextOpen == null ? -1 : pos + nextOpen.start;
      final nextCloseGlobal = pos + nextClose.start;

      if (nextOpen != null &&
          nextOpenGlobal < nextCloseGlobal &&
          !_insideRegion(nextOpenGlobal, fences)) {
        depth++;
        pos = pos + nextOpen.end;
      } else if (!_insideRegion(nextCloseGlobal, fences)) {
        depth--;
        if (depth == 0) {
          closeStart = nextCloseGlobal;
          closeEnd = pos + nextClose.end;
        }
        pos = pos + nextClose.end;
      } else {
        pos = pos + nextClose.end;
      }
    }

    if (closeStart == null || closeEnd == null) {
      // Unbalanced — bail out and pass the remainder as plain text.
      segments.add(_MarkdownSegment(markdown.substring(openStartGlobal)));
      break;
    }

    final inner = markdown.substring(openEndGlobal, closeStart);
    final extracted = _extractSummary(inner, defaultSummary: defaultSummary);
    segments.add(_DetailsSegment(
      summary: extracted.$1,
      body: extracted.$2,
      initiallyOpen: initiallyOpen,
    ));
    cursor = closeEnd;
  }

  return segments;
}

/// Returns a `(summary, body)` record. When no `<summary>` tag is present,
/// returns [defaultSummary] and the unmodified [inner] as the body.
(String, String) _extractSummary(String inner, {String defaultSummary = 'Details'}) {
  final m = RegExp(
    r'<summary\b[^>]*>([\s\S]*?)</summary\s*>',
    caseSensitive: false,
  ).firstMatch(inner);
  if (m == null) {
    return (defaultSummary, inner.trim());
  }
  final summary = m.group(1)!.trim();
  final body = (inner.substring(0, m.start) + inner.substring(m.end)).trim();
  return (summary.isEmpty ? defaultSummary : summary, body);
}

/// Lists `[start, end)` ranges occupied by fenced code blocks (``` ).
List<(int, int)> _findFencedRegions(String md) {
  final regions = <(int, int)>[];
  final lines = md.split('\n');
  var offset = 0;
  int? fenceStart;
  final fenceRe = RegExp(r'^\s*```');
  for (final line in lines) {
    if (fenceRe.hasMatch(line)) {
      if (fenceStart == null) {
        fenceStart = offset;
      } else {
        regions.add((fenceStart, offset + line.length));
        fenceStart = null;
      }
    }
    offset += line.length + 1;
  }
  if (fenceStart != null) {
    regions.add((fenceStart, md.length));
  }
  return regions;
}

bool _insideRegion(int pos, List<(int, int)> regions) {
  for (final (a, b) in regions) {
    if (pos >= a && pos < b) {
      return true;
    }
  }
  return false;
}

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
      _fetch();
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
      final result = await _fetchImageBytes(
        url: requested.toString(),
        token: widget.token,
      );
      if (!mounted || widget.uri != requested) {
        return;
      }
      setState(() => _result = result);
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
      final shouldRetry = host == 'private-user-images.githubusercontent.com' ||
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
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxLayoutWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final cappedWidth = maxLayoutWidth.isFinite
            ? maxLayoutWidth.clamp(0.0, 800.0)
            : 800.0;

        if (_looksLikeSvg(result.contentType, result.bytes)) {
          final svg = utf8.decode(result.bytes, allowMalformed: true);
          return _buildSvg(svg, hint, cappedWidth, cleanAlt);
        }
        return _buildRaster(result.bytes, hint, cappedWidth, cleanAlt);
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

    // Intrinsic-sized (badges, icons): render at natural size, left-aligned
    // so a 52×20 badge doesn't centre itself inside a 600px paragraph.
    if (targetWidth != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: targetWidth,
            height: targetHeight,
            child: svgPicture,
          ),
        ),
      );
    }

    // No usable intrinsic info — treat as a flowing illustration.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
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
  ) {
    final double targetWidth;
    if (hint.width != null) {
      targetWidth = hint.width!.clamp(0.0, cappedWidth);
    } else if (hint.widthPercent != null) {
      targetWidth = cappedWidth * hint.widthPercent!;
    } else {
      targetWidth = cappedWidth;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Image.memory(
            bytes,
            width: targetWidth,
            height: hint.height,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
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
    final controller = VideoPlayerController.networkUrl(requested);
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
            final cappedWidth =
                maxWidth.isFinite ? maxWidth.clamp(0.0, 800.0) : 800.0;
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
        child: const CircularProgressIndicator.adaptive(),
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
  final head =
      String.fromCharCodes(bytes.sublist(0, headLen)).toLowerCase().trimLeft();
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

const Set<String> _videoExtensions = {
  '.mov',
  '.mp4',
  '.m4v',
  '.webm',
};

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

/// Fetches [url], following redirects manually so a GitHub bearer token can
/// be sent on the initial hop (for `private-user-images.*` etc.) and
/// stripped before the cross-host hop to S3. Returns the body bytes together
/// with the response's `Content-Type` so the caller can decide whether to
/// decode as SVG or raster.
Future<_FetchResult> _fetchImageBytes({
  required String url,
  required String token,
}) async {
  final client = HttpClient()..userAgent = 'control-center';
  try {
    var uri = Uri.parse(url);
    var sendAuth = token.isNotEmpty && _shouldAuth(uri);

    for (var hop = 0; hop < 10; hop++) {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'image/*,*/*;q=0.8');
      if (sendAuth) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      final response = await request.close();

      if (response.isRedirect) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.drain<void>();
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

      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: uri,
        );
      }

      final contentType = response.headers
              .value(HttpHeaders.contentTypeHeader)
              ?.toLowerCase() ??
          'application/octet-stream';

      // Private user-attachments hit with a PAT come back as 200 text/html
      // (the signin page). Bail before consuming the body so the fallback
      // card renders without attempting to decode HTML as an image.
      if (contentType.startsWith('text/html')) {
        await response.drain<void>();
        throw const _NotAnImageResponse();
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
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
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
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
        onTap: () => launchUrl(uri),
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
              Icon(LucideIcons.image, size: 28, color: hint),
              const SizedBox(height: 8),
              Text(
                hasAlt ? alt! : caption,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.externalLink, size: 12, color: hint),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to open in GitHub',
                    style: theme.textTheme.labelSmall?.copyWith(color: hint),
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
