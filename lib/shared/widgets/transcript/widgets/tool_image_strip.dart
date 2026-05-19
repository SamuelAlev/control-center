import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/image_viewer_labels.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';

/// Renders the images a tool returned — a `browser_use` / `computer_use` /
/// `mobile_use` screenshot, a rendered chart — as a row of thumbnails that
/// open in the shared lightbox.
///
/// **Why this exists.** The harness has carried tool-result images to the model
/// since it was written, and both providers put them on the wire. The
/// transcript dropped them, so a run that screenshotted every step showed the
/// human a column of tool calls asserting a screenshot was taken and nothing to
/// look at. The agent could see; the person watching could not.
///
/// Bytes are never inline: each entry is a `blob:sha256:<hex>` reference the
/// host resolves over `/blob`, signed with the device PSK and gated on
/// workspace membership.
class ToolImageStrip extends StatelessWidget {
  /// Creates a [ToolImageStrip].
  const ToolImageStrip({
    super.key,
    required this.images,
    required this.tokens,
    this.workspaceId,
    this.thumbnailHeight = 132,
  });

  /// The tool result's image references, in the order the tool produced them.
  final List<ToolImageRef> images;

  /// The workspace whose blob store holds them.
  ///
  /// Passed in rather than read from a provider: this lives in `shared/`,
  /// which must not reach into a feature — and a widget that fetches its own
  /// global state is also one that cannot be rendered anywhere else, including
  /// in a test.
  final String? workspaceId;

  /// Resolved design tokens (the transcript resolves them once per cell).
  final DesignSystemTokens tokens;

  /// Height of each thumbnail. Width follows the image's aspect ratio.
  final double thumbnailHeight;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }
    // Without a workspace there is no signable URL, so there is nothing to
    // show. Say so rather than rendering broken frames.
    final workspaceId = this.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      return _Unavailable(count: images.length, tokens: tokens);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: thumbnailHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final image = images[index];
            final url = MediaProxyScope.blobUrlOf(
              context,
              workspaceId: workspaceId,
              ref: image.ref,
            );
            if (url == null) {
              return _Unavailable(count: 1, tokens: tokens);
            }
            return _Thumbnail(
              url: url,
              image: image,
              height: thumbnailHeight,
              tokens: tokens,
            );
          },
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.url,
    required this.image,
    required this.height,
    required this.tokens,
  });

  final String url;
  final ToolImageRef image;
  final double height;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const radius = BorderRadius.all(Radius.circular(6));
    // The shared lightbox rather than a bespoke dialog: a full desktop
    // screenshot is legible as a whole and unreadable in detail, and the
    // zoom / pan / reset controls plus their localized labels already exist.
    return CcExpandableImage(
      labels: appImageViewerLabels(context),
      title: l10n.toolScreenshot,
      borderRadius: radius,
      viewerBuilder: (context) => Image.network(url, fit: BoxFit.contain),
      child: Semantics(
        label: l10n.toolScreenshot,
        image: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: tokens.borderSecondary),
            color: tokens.bgSecondary,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Image.network(
              url,
              height: height,
              fit: BoxFit.contain,
              errorBuilder: (context, _, _) =>
                  _Unavailable(count: 1, tokens: tokens),
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : SizedBox(
                      height: height,
                      // A screenshot is landscape far more often than not, so
                      // the placeholder reserves a landscape box: sizing it
                      // square would make every load visibly reflow.
                      width: height * 1.6,
                      child: const Center(child: CcSpinner(size: 16)),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when an image cannot be resolved — no proxy, no workspace, a missing
/// blob, or a failed load. Explicit rather than an empty gap, so a screenshot
/// that did not arrive is distinguishable from a tool that returned none.
class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.count, required this.tokens});

  final int count;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.borderSecondary),
        color: tokens.bgSecondary,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Center(
          child: Text(
            count == 1
                ? l10n.toolImageUnavailable
                : l10n.toolImagesUnavailable(count),
            style: CcTypography.caption.copyWith(
              color: tokens.textTertiary,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
