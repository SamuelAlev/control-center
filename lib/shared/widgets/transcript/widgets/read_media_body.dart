import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/attachments/attachment_preview_pane.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_media.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';

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
              final actionUrl = downloadOriginal ? downloadUrl : url;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (url != null && !document && !hasRenderedPreview)
                    SizedBox(
                      height: kind == AttachmentMediaKind.audio ? 120 : 320,
                      child: Semantics(
                        label: attachment.name,
                        image: kind == AttachmentMediaKind.image,
                        child: AttachmentPreviewBody(
                          key: ValueKey(url),
                          attachment: ComposerAttachment(
                            id: 'read:${attachment.path}',
                            kind: attachment.kind.name,
                            label: attachment.name,
                            mimeType: attachment.mediaType,
                            sizeBytes: attachment.size,
                            remoteUrl: url,
                          ),
                        ),
                      ),
                    )
                  else if (url == null)
                    Text(l10n.attachmentUnavailableDetail),
                  if (actionUrl != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: CcButton(
                        variant: CcButtonVariant.secondary,
                        size: CcButtonSize.sm,
                        onPressed: () => openExternalUrl(actionUrl),
                        child: Text(
                          '${downloadOriginal ? l10n.download : l10n.attachmentOpenExternally}: ${attachment.name}',
                        ),
                      ),
                    ),
                  if (canDownloadInline &&
                      !downloadOriginal &&
                      downloadUrl != null)
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
