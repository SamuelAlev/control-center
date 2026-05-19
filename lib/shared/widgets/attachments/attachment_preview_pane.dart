import 'dart:async';
import 'dart:convert';

import 'package:cc_ui/cc_ui.dart';
import 'package:chewie/chewie.dart';
import 'package:control_center/core/infrastructure/clipboard/host_file_staging.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/attachments/local_media.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_media.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_registry.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/image_viewer_labels.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

/// The editor-tab kind a composer attachment preview opens as.
///
/// Declared here rather than in the messaging tab vocabulary so the composer —
/// which is shared, and is where a preview is requested from — does not have to
/// import a feature's presentation layer to name it. `EditorTab.kind` is an
/// opaque string by design; messaging binds this one into its icon table and
/// its layout codec.
const String kAttachmentPreviewTabKind = 'attachment';

/// Tab argument carrying which attachment to show.
const String kAttachmentPreviewIdArg = 'attachmentId';

/// Most bytes read off disk to render a TEXT preview.
///
/// A source file is kilobytes; a log someone dropped by accident is not, and
/// syntax-highlighting eight megabytes of it would lock the frame. Past this
/// the pane says the file is too large rather than trying.
const int kMaxTextPreviewBytes = 2 * 1024 * 1024;

/// Read-only preview of one composer attachment: the picture, video, document
/// or source file a person dropped into the prompt.
///
/// Resolved from [attachmentRegistryProvider] by id, because an editor tab's
/// arguments are JSON primitives that a layout snapshot persists — an
/// attachment (let alone its bytes) cannot travel in them. An id whose entry
/// has been evicted renders the unavailable state, the same way the artifact
/// and run-activity tabs do.
class AttachmentPreviewPane extends ConsumerWidget {
  /// Creates an [AttachmentPreviewPane].
  const AttachmentPreviewPane({
    super.key,
    required this.attachmentId,
    this.label,
  });

  /// Registry key of the attachment to render.
  final String attachmentId;

  /// Name to show while the attachment cannot be resolved (from the tab, which
  /// knows what it was called even when the entry is gone).
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final attachment = ref.watch(attachmentRegistryProvider)[attachmentId];
    if (attachment == null) {
      return _Centered(
        tokens: tokens,
        icon: AppIcons.fileQuestion,
        title: label ?? AppLocalizations.of(context).attachmentUnavailable,
        message: AppLocalizations.of(context).attachmentUnavailableDetail,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreviewHeader(attachment: attachment, tokens: tokens),
        Expanded(child: AttachmentPreviewBody(attachment: attachment)),
      ],
    );
  }
}

/// The preview itself, without the tab header — reused by the dialog fallback
/// on surfaces that are not hosted in an editor layout.
class AttachmentPreviewBody extends StatefulWidget {
  /// Creates an [AttachmentPreviewBody].
  const AttachmentPreviewBody({super.key, required this.attachment});

  /// What to render.
  final ComposerAttachment attachment;

  @override
  State<AttachmentPreviewBody> createState() => _AttachmentPreviewBodyState();
}

class _AttachmentPreviewBodyState extends State<AttachmentPreviewBody> {
  /// Null while resolving; set once the source is known (or known to be
  /// unavailable).
  _PreviewSource? _source;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  @override
  void didUpdateWidget(AttachmentPreviewBody old) {
    super.didUpdateWidget(old);
    if (old.attachment.id != widget.attachment.id) {
      setState(() {
        _source = null;
        _error = null;
      });
      unawaited(_resolve());
    }
  }

  AttachmentMediaKind get _kind => attachmentMediaKind(
    mimeType: widget.attachment.mimeType,
    name: widget.attachment.label,
  );

  /// Works out what this attachment can actually be rendered FROM.
  ///
  /// The three renderers want different things and only one of them takes raw
  /// bytes: an image decodes from either, text needs a decoded string, and a
  /// player or a PDF viewer needs a real `file://` URL — which is why bytes
  /// with no file behind them are staged to the host's scratch directory
  /// first. On web there is no scratch directory, and the pane says so.
  Future<void> _resolve() async {
    final attachment = widget.attachment;
    final bytes = attachment.bytes;
    final path = attachment.path;
    final url = attachment.remoteUrl;
    try {
      switch (_kind) {
        case AttachmentMediaKind.image:
          setState(
            () => _source = _PreviewSource(bytes: bytes, path: path, url: url),
          );
        case AttachmentMediaKind.video:
        case AttachmentMediaKind.audio:
        case AttachmentMediaKind.pdf:
          // A player and a webview both take a URL, so a sent attachment needs
          // no local copy at all — the host serves it. Only bytes with neither
          // a file nor a URL behind them have to be staged.
          final resolved =
              path ?? (url == null ? await _stage(attachment) : null);
          if (!mounted) {
            return;
          }
          setState(() => _source = _PreviewSource(path: resolved, url: url));
        case AttachmentMediaKind.text:
        case AttachmentMediaKind.markdown:
          final data =
              bytes ??
              (path != null
                  ? await readLocalBytes(path, maxBytes: kMaxTextPreviewBytes)
                  : (url == null ? null : await _fetch(url)));
          if (!mounted) {
            return;
          }
          if (data != null && data.length > kMaxTextPreviewBytes) {
            setState(() => _source = const _PreviewSource());
            return;
          }
          setState(
            () => _source = _PreviewSource(
              text: data == null ? null : _decode(data),
              path: path,
              url: url,
            ),
          );
        case AttachmentMediaKind.archive:
        case AttachmentMediaKind.document:
        case AttachmentMediaKind.other:
          setState(() => _source = _PreviewSource(path: path, url: url));
      }
    } on Object catch (e, st) {
      AppLog.d('attachment-preview', 'resolving ${attachment.label}: $e\n$st');
      if (mounted) {
        setState(() => _error = e);
      }
    }
  }

  /// Writes in-memory bytes to the host's scratch directory so a player or a
  /// webview has a URL to open. Returns null on web (no filesystem) or when
  /// the write failed.
  Future<String?> _stage(ComposerAttachment attachment) async {
    final bytes = attachment.bytes;
    if (bytes == null || bytes.isEmpty || !hostFileStagingAvailable) {
      return null;
    }
    final staged = await stageFilesOnHost([
      (name: attachment.label, bytes: Uint8List.fromList(bytes)),
    ]);
    if (staged.files.isEmpty) {
      return null;
    }
    return staged.files.first.toFilePath();
  }

  /// Reads a sent attachment's bytes back from the host.
  ///
  /// Only the text renderers need this: an image, a player and a webview all
  /// take the URL directly, so nothing else pulls the bytes into the client.
  Future<List<int>?> _fetch(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        AppLog.d('attachment-preview', 'fetch failed: ${response.statusCode}');
        return null;
      }
      return response.bodyBytes;
    } on Object catch (e) {
      AppLog.d('attachment-preview', 'fetch failed: $e');
      return null;
    }
  }

  /// Decodes bytes as UTF-8, tolerating malformed sequences.
  ///
  /// A file that is not text at all still renders — as mojibake, which reads
  /// as "this is binary" far more clearly than an exception does.
  static String _decode(List<int> bytes) =>
      const Utf8Decoder(allowMalformed: true).convert(bytes);

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    if (_error != null) {
      return _Centered(
        tokens: tokens,
        icon: AppIcons.alertTriangle,
        title: l10n.attachmentPreviewFailed,
        message: '$_error',
      );
    }
    final source = _source;
    if (source == null) {
      return const Center(child: CcSpinner(size: 18));
    }
    switch (_kind) {
      case AttachmentMediaKind.image:
        return _ImagePreview(source: source, tokens: tokens);
      case AttachmentMediaKind.video:
      case AttachmentMediaKind.audio:
        return _MediaPreview(
          source: source,
          tokens: tokens,
          attachment: widget.attachment,
          audioOnly: _kind == AttachmentMediaKind.audio,
        );
      case AttachmentMediaKind.pdf:
        return _PdfPreview(
          source: source,
          tokens: tokens,
          attachment: widget.attachment,
        );
      case AttachmentMediaKind.markdown:
        return _TextPreview(
          source: source,
          tokens: tokens,
          attachment: widget.attachment,
          asMarkdown: true,
        );
      case AttachmentMediaKind.text:
        return _TextPreview(
          source: source,
          tokens: tokens,
          attachment: widget.attachment,
          asMarkdown: false,
        );
      case AttachmentMediaKind.archive:
      case AttachmentMediaKind.document:
      case AttachmentMediaKind.other:
        return _UnsupportedPreview(
          tokens: tokens,
          attachment: widget.attachment,
          path: source.path,
        );
    }
  }
}

/// What a renderer was given to work with. Every field may be absent — that is
/// the "nothing to show" case each renderer handles for itself.
@immutable
class _PreviewSource {
  const _PreviewSource({this.bytes, this.path, this.text, this.url});

  final List<int>? bytes;
  final String? path;
  final String? text;

  /// A signed URL the host serves the bytes from — how an attachment that has
  /// already been SENT is rendered, once the composer's in-memory copy is gone.
  final String? url;
}

/// The pane's header: glyph, name, size and the escape hatch.
class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.attachment, required this.tokens});

  final ComposerAttachment attachment;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = formatAttachmentSize(attachment.sizeBytes);
    final path = attachment.path;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        border: Border(bottom: BorderSide(color: tokens.lineStrong)),
      ),
      child: Row(
        children: [
          Icon(
            attachmentIcon(attachment),
            size: 14,
            color: tokens.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path ?? attachment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: tokens.fg,
                fontFamily: CcFonts.codeFamily,
              ),
            ),
          ),
          if (size != null) ...[
            const SizedBox(width: 8),
            Text(
              size,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
          ],
          // Only when there is a real file to hand over. A pasted screenshot
          // exists nowhere the OS can open.
          if (path != null && localMediaAvailable) ...[
            const SizedBox(width: 8),
            CcIconButton(
              icon: AppIcons.externalLink,
              tooltip: l10n.attachmentOpenExternally,
              onPressed: () => openExternalUrl(Uri.file(path).toString()),
            ),
          ],
        ],
      ),
    );
  }
}

/// Zoomable picture. Pan and pinch/scroll zoom rather than a fixed fit: a
/// screenshot of a dense UI is legible as a whole and unreadable in detail.
///
/// This IS the expanded view, so it uses the same [CcImageViewer] the lightbox
/// does rather than a bare `InteractiveViewer`: same zoom floor, same toolbar,
/// same percentage readout, same `+`/`-`/`0` and double-tap. Two zoom UXes for
/// the same act — look at this picture closely — is the thing the shared
/// component exists to prevent. Unbordered: the pane already has an edge.
class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.source, required this.tokens});

  final _PreviewSource source;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final bytes = source.bytes;
    final path = source.path;
    final url = source.url;
    // Bytes, then the file, then the host. The order is cheapest-first: a
    // just-dropped picture is already in memory, a picked one is on disk, and
    // only a picture that has already been SENT has to come back over the wire.
    final ImageProvider? provider = bytes != null && bytes.isNotEmpty
        ? MemoryImage(Uint8List.fromList(bytes))
        : (path != null
              ? localImageProvider(path)
              : (url == null ? null : NetworkImage(url)));
    if (provider == null) {
      return _Centered(
        tokens: tokens,
        icon: AppIcons.imageOff,
        title: AppLocalizations.of(context).attachmentPreviewUnsupported,
      );
    }
    return CcImageViewer(
      labels: appImageViewerLabels(context),
      bordered: false,
      child: Center(
        child: Image(
          image: provider,
          fit: BoxFit.contain,
          errorBuilder: (context, _, _) => _Centered(
            tokens: tokens,
            icon: AppIcons.imageOff,
            title: AppLocalizations.of(context).attachmentPreviewFailed,
          ),
        ),
      ),
    );
  }
}

/// Video and audio, over the platform player.
class _MediaPreview extends StatefulWidget {
  const _MediaPreview({
    required this.source,
    required this.tokens,
    required this.attachment,
    required this.audioOnly,
  });

  final _PreviewSource source;
  final DesignSystemTokens tokens;
  final ComposerAttachment attachment;
  final bool audioOnly;

  @override
  State<_MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<_MediaPreview> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  @override
  void dispose() {
    _chewie?.dispose();
    unawaited(_video?.dispose());
    super.dispose();
  }

  Future<void> _init() async {
    final path = widget.source.path;
    final url = widget.source.url;
    // A local file when there is one, else straight off the host — a sent
    // recording is never copied down just to be played.
    final controller = path != null
        ? localVideoController(path)
        : (url == null
              ? null
              : VideoPlayerController.networkUrl(Uri.parse(url)));
    if (controller == null) {
      setState(() => _failed = true);
      return;
    }
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      final ratio = controller.value.aspectRatio;
      setState(() {
        _video = controller;
        _chewie = ChewieController(
          videoPlayerController: controller,
          // An audio file reports no usable ratio; give it a short, wide box
          // so the transport controls are the whole of what is shown.
          aspectRatio: widget.audioOnly ? 5 : (ratio == 0 ? 16 / 9 : ratio),
          autoPlay: false,
          looping: false,
          showControlsOnInitialize: true,
          hideControlsTimer: const Duration(seconds: 2),
          allowFullScreen: !widget.audioOnly,
          allowMuting: true,
        );
      });
    } on Object catch (e) {
      AppLog.d('attachment-preview', 'player init failed: $e');
      await controller.dispose();
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewie;
    if (_failed) {
      return _UnsupportedPreview(
        tokens: widget.tokens,
        attachment: widget.attachment,
        path: widget.source.path,
      );
    }
    if (chewie == null) {
      return const Center(child: CcSpinner(size: 18));
    }
    return ColoredBox(
      color: widget.tokens.bgSecondary,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Chewie(controller: chewie),
        ),
      ),
    );
  }
}

/// PDF, rendered by the platform's own webview.
///
/// No PDF dependency is added for this: WKWebView and WebView2 both render a
/// PDF handed a `file://` URL, with the page navigation and text selection
/// their users already know. Linux has no webview backend and web cannot reach
/// a local file, so both degrade to the "open it in your own reader" card
/// rather than to an empty frame.
class _PdfPreview extends StatelessWidget {
  const _PdfPreview({
    required this.source,
    required this.tokens,
    required this.attachment,
  });

  final _PreviewSource source;
  final DesignSystemTokens tokens;
  final ComposerAttachment attachment;

  static bool get _webviewSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Widget build(BuildContext context) {
    final path = source.path;
    // The host's own URL when the document has been sent; a local file only
    // while it is still a draft.
    final target = path != null ? Uri.file(path).toString() : source.url;
    if (target == null || !_webviewSupported) {
      return _UnsupportedPreview(
        tokens: tokens,
        attachment: attachment,
        path: path,
      );
    }
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(target)),
      initialSettings: InAppWebViewSettings(
        // A local document, opened to be read. It has no business fetching
        // anything, running anything, or navigating anywhere.
        javaScriptEnabled: false,
        allowFileAccessFromFileURLs: true,
        supportZoom: true,
        transparentBackground: true,
      ),
    );
  }
}

/// Text, source and markdown.
class _TextPreview extends StatelessWidget {
  const _TextPreview({
    required this.source,
    required this.tokens,
    required this.attachment,
    required this.asMarkdown,
  });

  final _PreviewSource source;
  final DesignSystemTokens tokens;
  final ComposerAttachment attachment;
  final bool asMarkdown;

  @override
  Widget build(BuildContext context) {
    final text = source.text;
    if (text == null) {
      return _UnsupportedPreview(
        tokens: tokens,
        attachment: attachment,
        path: source.path,
        reason: AppLocalizations.of(context).attachmentTooLargeToPreview,
      );
    }
    if (asMarkdown) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: StyledMarkdownBody(data: text),
      );
    }
    // Through the shared code block so a previewed file is highlighted by the
    // same grammars, theme and tokenizer the transcript and the diff use —
    // one syntax pipeline, not a second one that drifts.
    final language = shikiLangForPath(source.path ?? attachment.label);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: buildSharedCodeBlock(context, text, language),
    );
  }
}

/// The honest end of the line: a file this app cannot draw.
///
/// Says WHICH file, how big, and offers the one thing that does work — handing
/// it to whatever the operating system opens it with. A blank pane would leave
/// the person wondering whether the attachment arrived at all.
class _UnsupportedPreview extends StatelessWidget {
  const _UnsupportedPreview({
    required this.tokens,
    required this.attachment,
    this.path,
    this.reason,
  });

  final DesignSystemTokens tokens;
  final ComposerAttachment attachment;
  final String? path;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = formatAttachmentSize(attachment.sizeBytes);
    return _Centered(
      tokens: tokens,
      icon: attachmentIcon(attachment),
      title: attachment.label,
      message: reason ?? [?size, l10n.attachmentPreviewUnsupported].join(' · '),
      action: path != null && localMediaAvailable
          ? CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => openExternalUrl(Uri.file(path!).toString()),
              child: Text(l10n.attachmentOpenExternally),
            )
          : null,
    );
  }
}

/// Shared empty/error layout.
class _Centered extends StatelessWidget {
  const _Centered({
    required this.tokens,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final DesignSystemTokens tokens;
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: tokens.textTertiary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: CcTypography.body.copyWith(
                color: tokens.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// The glyph that names an attachment's kind, in the chip, the tab strip and
/// the preview header alike.
IconData attachmentIcon(ComposerAttachment attachment) {
  if (attachment.kind == 'scratchpad') {
    return AppIcons.notebookText;
  }
  return switch (attachmentMediaKind(
    mimeType: attachment.mimeType,
    name: attachment.label,
  )) {
    AttachmentMediaKind.image => AppIcons.image,
    AttachmentMediaKind.video => AppIcons.video,
    AttachmentMediaKind.audio => AppIcons.audioLines,
    AttachmentMediaKind.pdf => AppIcons.fileText,
    AttachmentMediaKind.markdown => AppIcons.fileText,
    AttachmentMediaKind.text => AppIcons.fileCode,
    AttachmentMediaKind.archive => AppIcons.archive,
    AttachmentMediaKind.document => AppIcons.fileText,
    AttachmentMediaKind.other => AppIcons.file,
  };
}
