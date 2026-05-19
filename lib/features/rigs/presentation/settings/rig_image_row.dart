import 'package:cc_data/cc_data.dart' show RigImageView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/human_bytes.dart';
import 'package:flutter/widgets.dart';

/// One base image: what it is, whether it is here, and how to get it.
class RigImageRow extends StatelessWidget {
  /// Creates a [RigImageRow].
  const RigImageRow({
    super.key,
    required this.image,
    required this.busy,
    required this.downloading,
    required this.importing,
    required this.pathController,
    required this.onDownload,
    required this.onStartImport,
    required this.onCancelImport,
    required this.onConfirmImport,
  });

  /// The image this row describes.
  final RigImageView image;

  /// Whether a blocking action (an import) is running for it.
  final bool busy;

  /// Whether a download is in flight on the SERVER for it.
  final bool downloading;

  /// Whether the import field is open on this row.
  final bool importing;

  /// The shared import-path field's controller.
  final TextEditingController pathController;

  /// Null when the artifact is not published — the button is then ABSENT
  /// rather than present-and-doomed.
  final VoidCallback? onDownload;

  /// Opens the import field.
  final VoidCallback onStartImport;

  /// Closes the import field.
  final VoidCallback onCancelImport;

  /// Imports whatever path is typed.
  final VoidCallback onConfirmImport;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          image.id,
                          overflow: TextOverflow.ellipsis,
                          style: CcTypography.bodySm.copyWith(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      CcStatusTag(
                        label: image.present
                            ? l10n.rigImageInstalled
                            : downloading
                            ? l10n.rigImageDownloading
                            : image.published
                            ? l10n.rigImageNotDownloaded
                            : l10n.rigImageNotPublished,
                        tone: image.present
                            ? CcStatusTone.positive
                            : downloading
                            ? CcStatusTone.caution
                            : image.published
                            ? CcStatusTone.neutral
                            : CcStatusTone.caution,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    image.description,
                    style: CcTypography.caption.copyWith(color: t.textTertiary),
                  ),
                  Text(
                    '${humanBytes(image.sizeBytes)} · ${image.surface}',
                    style: CcTypography.caption.copyWith(
                      color: t.textQuaternary,
                    ),
                  ),
                ],
              ),
            ),
            if (busy)
              const CcSpinner()
            else if (!image.present && !importing) ...[
              if (onDownload != null && !downloading) ...[
                CcButton(
                  size: CcButtonSize.sm,
                  variant: CcButtonVariant.secondary,
                  onPressed: onDownload,
                  child: Text(l10n.rigImageDownload),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              if (!downloading)
                CcButton(
                  size: CcButtonSize.sm,
                  variant: CcButtonVariant.secondary,
                  onPressed: onStartImport,
                  child: Text(l10n.rigImageImport),
                ),
            ],
          ],
        ),
        // A multi-minute transfer with no number on screen is
        // indistinguishable from one that silently failed.
        if (downloading) ...[
          const SizedBox(height: AppSpacing.xs),
          _DownloadProgress(image: image),
        ],
        // The honest reason there is no download button, said where the button
        // would otherwise have been.
        if (!image.present &&
            !image.published &&
            !importing &&
            !downloading) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.rigImageNotPublishedHint,
            style: CcTypography.caption.copyWith(color: t.warn),
          ),
        ],
        if (importing) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.rigImageImportMessage,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: CcTextField(
                  controller: pathController,
                  autofocus: true,
                  hintText: '/path/to/disk.qcow2',
                  onSubmitted: (_) => onConfirmImport(),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              CcButton(
                size: CcButtonSize.sm,
                onPressed: onConfirmImport,
                child: Text(l10n.rigImageImport),
              ),
              const SizedBox(width: AppSpacing.xs),
              CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.ghost,
                onPressed: onCancelImport,
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({required this.image});

  final RigImageView image;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final received = image.downloadedBytes ?? 0;
    final total = image.sizeBytes;
    return Row(
      children: [
        const CcSpinner(size: 12),
        const SizedBox(width: AppSpacing.xs),
        Text(
          received == 0
              ? l10n.rigImageDownloading
              : '${humanBytes(received)} / ${humanBytes(total)}',
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
      ],
    );
  }
}
