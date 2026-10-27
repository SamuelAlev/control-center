import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/attachments/attachment_preview_pane.dart';
import 'package:control_center/shared/widgets/attachments/open_attachment_preview.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_media.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/image_viewer_labels.dart';
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline previews resolve only persisted server blobs, never the viewer's disk.
class ReadMediaBody extends StatelessWidget {
  /// Displays retained media alongside any text extracted by the Read tool.
  const ReadMediaBody({
    super.key,
    required this.attachments,
    required this.workspaceId,
    required this.extractedText,
    this.hasRenderedPreview = false,
  });

  /// Original media retained in the workspace blob store.
  final List<MessageAttachment> attachments;

  /// A normalized image is already rendered by the transcript image strip.
  final bool hasRenderedPreview;

  /// Workspace used to sign the media URLs.
  final String? workspaceId;

  /// Read output after line-number prefixes and media markers are removed.
  final String extractedText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final attachment in attachments) ...[
          Builder(
            builder: (context) {
              final kind = attachmentMediaKind(
                mimeType: attachment.mediaType,
                name: attachment.name,
              );
              final workspace = workspaceId;
              final url = workspace == null || workspace.isEmpty
                  ? null
                  : MediaProxyScope.blobUrlOf(
                      context,
                      workspaceId: workspace,
                      ref: attachment.path,
                    );
              final document = kind == AttachmentMediaKind.document;
              final downloadOriginal =
                  kind == AttachmentMediaKind.other || hasRenderedPreview;
              final canDownloadInline =
                  attachment.mediaType == 'image/gif' ||
                  attachment.mediaType == 'image/apng' ||
                  (kind == AttachmentMediaKind.pdf &&
                      attachment.name.toLowerCase().endsWith('.ai'));
              final downloadUrl =
                  workspace == null ||
                      workspace.isEmpty ||
                      (!downloadOriginal && !canDownloadInline)
                  ? null
                  : MediaProxyScope.blobUrlOf(
                      context,
                      workspaceId: workspace,
                      ref: attachment.path,
                      downloadName: attachment.name,
                    );
              final preview = url == null
                  ? null
                  : ComposerAttachment(
                      id: 'read:${attachment.path}',
                      kind: attachment.kind.name,
                      label: attachment.name,
                      mimeType: attachment.mediaType,
                      sizeBytes: attachment.size,
                      remoteUrl: url,
                    );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (preview != null && !document && !hasRenderedPreview)
                    if (kind == AttachmentMediaKind.image)
                      _InlineImage(attachment: preview)
                    else
                      _InlineMedia(
                        attachment: preview,
                        height: kind == AttachmentMediaKind.audio ? 120 : 320,
                      )
                  else if (url == null)
                    Text(l10n.attachmentUnavailableDetail),
                  if (downloadUrl != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: CcButton(
                        variant: CcButtonVariant.secondary,
                        size: CcButtonSize.sm,
                        onPressed: () => openExternalUrl(downloadUrl),
                        child: Text('${l10n.download}: ${attachment.name}'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        if (extractedText.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              child: StyledMarkdownBody(data: extractedText),
            ),
          ),
      ],
    );
  }
}

/// The picture as markdown draws one: capped to the same box, rounded, and
/// expandable from the corner — into an editor tab rather than a lightbox, so
/// it can sit beside the conversation at full size.
class _InlineImage extends ConsumerWidget {
  const _InlineImage({required this.attachment});

  final ComposerAttachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.ds;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    const radius = BorderRadius.all(Radius.circular(8));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: CcExpandableImage(
          labels: appImageViewerLabels(context),
          borderRadius: radius,
          onExpand: () =>
              unawaited(openAttachmentPreview(context, ref, attachment)),
          child: ClipRRect(
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: kMaxMarkdownImageWidth,
                maxHeight: kMaxMarkdownImageHeight,
              ),
              child: Semantics(
                label: attachment.label,
                image: true,
                child: Image.network(
                  attachment.remoteUrl!,
                  // Width only, so the decode keeps the source's aspect.
                  cacheWidth: (kMaxMarkdownImageWidth * dpr).round(),
                  fit: BoxFit.contain,
                  frameBuilder: (context, child, frame, sync) =>
                      frame == null && !sync
                      ? ColoredBox(
                          color: tokens.bgSecondary,
                          child: const SizedBox(
                            width: 240,
                            height: 160,
                            child: Center(child: CcSpinner(size: 14)),
                          ),
                        )
                      : child,
                  errorBuilder: (context, _, _) => Text(
                    AppLocalizations.of(context).attachmentPreviewFailed,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A player or document viewer kept inline, with the same corner expand the
/// picture has. A button rather than the image's whole-surface target: the
/// player's own controls have to keep their taps.
class _InlineMedia extends ConsumerWidget {
  const _InlineMedia({required this.attachment, required this.height});

  final ComposerAttachment attachment;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.ds;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              label: attachment.label,
              child: AttachmentPreviewBody(
                key: ValueKey(attachment.remoteUrl),
                attachment: attachment,
              ),
            ),
          ),
          PositionedDirectional(
            top: AppSpacing.sm,
            end: AppSpacing.sm,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.panel,
                border: Border.all(color: tokens.borderSecondary),
                borderRadius: AppRadii.brLg,
              ),
              child: CcIconButton(
                icon: AppIcons.maximize2,
                size: CcButtonSize.sm,
                color: tokens.textTertiary,
                tooltip: AppLocalizations.of(context).expand,
                onPressed: () =>
                    unawaited(openAttachmentPreview(context, ref, attachment)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
