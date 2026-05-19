import 'dart:async';

import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:chewie/chewie.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:control_center/shared/utils/video_embed_adapter.dart';
import 'package:control_center/shared/widgets/github_link_handler.dart';
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/markdown_media_metrics.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:control_center/shared/widgets/video_embed_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Renders GitHub-flavoured markdown into Flutter widgets via the cc_markdown
/// engine, supporting `<details>` blocks (engine-parsed), image attachments,
/// inline video embeds, footnotes and GitHub reference chips.
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

  /// When true, standalone third-party video links (Loom, …) in the body are
  /// rendered as an inline [VideoEmbedView] instead of a plain link. Off by
  /// default so comment/chat surfaces aren't turned into webview farms — the
  /// PR description opts in.
  final bool embedVideos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = repoOwner ?? '';
    final repo = repoName ?? '';

    // Preprocessing chain: strip HTML comments, splice private
    // attachment URLs from body_html, normalize <img>/<video> tags, embed
    // provider video links, then rewrite GitHub #/ow- references to the app's
    // control-center:// deep-link scheme. The engine parses <details> and
    // footnotes itself — no manual segmentation.
    //
    // MEMOIZED. This is a pure function of the five inputs below, but it ran
    // in `build` — seven full passes over the source plus the attachment
    // extraction — every time any ancestor rebuilt. PR descriptions are tens
    // of KB and these bodies render per description, per comment row and per
    // timeline entry.
    final pre = _preprocessCached(
      data: data,
      bodyHtml: bodyHtml,
      owner: owner,
      repo: repo,
      embedVideos: embedVideos,
    );
    final videoUuids = pre.videoUuids;
    final processed = pre.markdown;

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
        // session. The renderers hold their reserved box instead of firing a
        // doomed request (and, when the host isn't already fetching, ask it to).
        final pending = attachmentsPending && isUnsplicedUserAttachment(uri);
        if (_isVideo(uri, videoUuids)) {
          final decoded = decodeAltWithDimensions(alt);
          return _VideoWidget(
            uri: uri,
            alt: decoded.alt,
            onAttachmentLoadFailed: onAttachmentLoadFailed,
            attachmentPending: pending,
          );
        }
        return MarkdownImage(
          uri: uri,
          alt: alt,
          onAttachmentLoadFailed: onAttachmentLoadFailed,
          attachmentPending: pending,
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

/// Inline video player for GitHub user-attachment videos (typically `.mov`
/// from screen recordings). Pre-signed URLs work without auth so we hand
/// the URL directly to `video_player`. Chewie wraps the player with
/// scrub/play/fullscreen controls.
class _VideoWidget extends StatefulWidget {
  const _VideoWidget({
    required this.uri,
    this.alt,
    this.onAttachmentLoadFailed,
    this.attachmentPending = false,
  });

  final Uri uri;
  final String? alt;
  final VoidCallback? onAttachmentLoadFailed;

  /// See [MarkdownImage.attachmentPending] — the host is still fetching the
  /// `body_html` that carries a playable URL, so don't open a player on one
  /// that can only 404.
  final bool attachmentPending;

  @override
  State<_VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<_VideoWidget> {
  /// See `_MarkdownImageState._credentialGrace`.
  static const Duration _credentialGrace = Duration(seconds: 8);

  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _error = false;
  bool _notifiedFailure = false;
  Timer? _graceTimer;

  /// See `_MarkdownImageState._deferredForExpiry` — not reset on a URL change,
  /// so a refresh that mints another already-expired-looking token falls back
  /// to playing it rather than deferring again forever.
  bool _deferredForExpiry = false;

  bool get _deferred {
    final expired = hasExpiredAttachmentJwt(widget.uri);
    if (expired && _deferredForExpiry) {
      return false;
    }
    return widget.attachmentPending ||
        isUnsplicedUserAttachment(widget.uri) ||
        expired;
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant _VideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uri != oldWidget.uri ||
        widget.attachmentPending != oldWidget.attachmentPending) {
      _graceTimer?.cancel();
      _disposeControllers();
      _error = false;
      _notifiedFailure = false;
      _start();
    }
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    _disposeControllers();
    super.dispose();
  }

  void _start() {
    if (_deferred) {
      _deferredForExpiry =
          _deferredForExpiry || hasExpiredAttachmentJwt(widget.uri);
      // A raw `github.com/user-attachments/*` URL is unplayable — it resolves
      // only against a browser session. Opening a player on it produced a
      // failure card the splice then replaced, so hold the reserved box and
      // ask the host for `body_html` instead. Videos never recovered from this
      // at all before: the stale-JWT retry was gated on the pre-signed host,
      // which an un-spliced URL is not.
      if (!widget.attachmentPending && !_notifiedFailure) {
        _notifiedFailure = true;
        final refresh = widget.onAttachmentLoadFailed;
        if (refresh != null) {
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
          setState(() => _error = true);
        }
      });
      return;
    }
    _init();
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
      // Remember the real shape so every later render of this recording — a
      // refreshed JWT, a revisit — reserves the right box before the player
      // initializes, instead of settling into it.
      MarkdownMediaMetrics.record(requested, controller.value.size);
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
    // ONE box for every state. A recording used to load through a fixed 180px
    // card and then snap to its real aspect (a 16:9 clip in an 800px column is
    // 450px), so the description below it moved twice — once when the player
    // initialized and again when a stale JWT sent it round the loop.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final cappedWidth = maxWidth.isFinite
            ? maxWidth.clamp(0.0, kMaxMarkdownImageWidth)
            : kMaxMarkdownImageWidth;

        final video = _video;
        final natural = video != null && !video.value.size.isEmpty
            ? video.value.size
            : reservedMediaIntrinsic(uri: widget.uri, columnWidth: cappedWidth);
        final box = resolveMarkdownImageBox(
          hint: const ImageDimensionHint(),
          intrinsic: natural,
          cappedWidth: cappedWidth,
        );
        final width = box.width;
        final height = box.height ?? cappedWidth * kDefaultAttachmentAspect;

        if (_error) {
          return MarkdownAttachmentCard(
            uri: widget.uri,
            alt: widget.alt,
            width: width,
            height: height,
          );
        }

        final chewie = _chewie;
        final child = (chewie == null || video == null)
            ? ColoredBox(
                color: context.ds.bgSecondary,
                child: const Center(child: CcSpinner()),
              )
            : Chewie(controller: chewie);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: width, height: height, child: child),
          ),
        );
      },
    );
  }
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

/// The output of [GitHubMarkdownBody]'s preprocessing chain.
class _PreprocessedBody {
  const _PreprocessedBody({required this.markdown, required this.videoUuids});

  /// The fully rewritten markdown source handed to the engine.
  final String markdown;

  /// Attachment UUIDs recognized as videos in `body_html`.
  final Set<String> videoUuids;
}

/// Small LRU over the preprocessing chain, keyed by its complete input set.
///
/// Module-level rather than per-State because the widget is stateless and used
/// from many call sites; bounded by BOTH entry count and total source length
/// so one enormous PR body cannot pin the cache (the same dual bound the
/// syntax highlighter uses).
final Map<String, _PreprocessedBody> _preprocessCache = {};
final Map<String, int> _preprocessCacheSizes = {};
var _preprocessCacheChars = 0;
const int _maxPreprocessEntries = 48;
const int _maxPreprocessChars = 1024 * 1024;

_PreprocessedBody _preprocessCached({
  required String data,
  required String? bodyHtml,
  required String owner,
  required String repo,
  required bool embedVideos,
}) {
  final key =
      '$owner\u0000$repo\u0000$embedVideos\u0000'
      '${bodyHtml?.length ?? -1}\u0000${bodyHtml ?? ''}\u0000$data';
  final hit = _preprocessCache.remove(key);
  if (hit != null) {
    _preprocessCache[key] = hit; // refresh recency
    return hit;
  }

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
  final result = _PreprocessedBody(markdown: processed, videoUuids: videoUuids);

  final cost = key.length + processed.length;
  if (cost > _maxPreprocessChars) {
    // Never admit something that would evict the whole working set for one
    // entry — recomputing it is cheaper than the churn.
    return result;
  }
  _preprocessCache[key] = result;
  _preprocessCacheSizes[key] = cost;
  _preprocessCacheChars += cost;
  while (_preprocessCache.length > _maxPreprocessEntries ||
      (_preprocessCacheChars > _maxPreprocessChars &&
          _preprocessCache.length > 1)) {
    final oldest = _preprocessCache.keys.first;
    _preprocessCache.remove(oldest);
    _preprocessCacheChars -= _preprocessCacheSizes.remove(oldest) ?? 0;
  }
  return result;
}
