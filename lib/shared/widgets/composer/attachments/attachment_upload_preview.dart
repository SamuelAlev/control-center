import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_strip.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

/// Interactive upload, ready and retry states in the light theme.
@Preview(name: 'Upload states — light', group: 'Composer', size: Size(680, 140))
Widget attachmentUploadLightPreview() => const _AttachmentUploadPreview();

/// The same attachment states in the dark theme.
@Preview(name: 'Upload states — dark', group: 'Composer', size: Size(680, 140))
Widget attachmentUploadDarkPreview() =>
    const _AttachmentUploadPreview(dark: true);

/// Narrow Arabic preview for mirrored controls and horizontal overflow.
@Preview(name: 'Upload states — RTL', group: 'Composer', size: Size(390, 140))
Widget attachmentUploadRtlPreview() =>
    const _AttachmentUploadPreview(rtl: true);

class _AttachmentUploadPreview extends StatefulWidget {
  const _AttachmentUploadPreview({this.dark = false, this.rtl = false});

  final bool dark;
  final bool rtl;

  @override
  State<_AttachmentUploadPreview> createState() =>
      _AttachmentUploadPreviewState();
}

class _AttachmentUploadPreviewState extends State<_AttachmentUploadPreview> {
  final _attachments = <ComposerAttachment>[
    const ComposerAttachment(
      id: 'preview-uploading',
      kind: 'file',
      label: 'recording.mp4',
      mimeType: 'video/mp4',
      sizeBytes: 14680064,
      uploadState: AttachmentUploadState.uploading,
    ),
    const ComposerAttachment(
      id: 'preview-ready',
      kind: 'file',
      label: 'notes.md',
      mimeType: 'text/markdown',
      sizeBytes: 2048,
      uploadState: AttachmentUploadState.ready,
    ),
    const ComposerAttachment(
      id: 'preview-failed',
      kind: 'file',
      label: 'specification.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 524288,
      uploadState: AttachmentUploadState.failed,
      uploadError: AttachmentUploadError.transfer,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = widget.dark ? CcThemeData.dark() : CcThemeData.light();
    return CcTheme(
      data: theme,
      child: WidgetsApp(
        color: theme.tokens.bgPrimary,
        debugShowCheckedModeBanner: false,
        locale: Locale(widget.rtl ? 'ar' : 'en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        textStyle: CcFonts.ui(textStyle: CcTypography.body).copyWith(
          color: theme.tokens.textPrimary,
          decoration: TextDecoration.none,
        ),
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: ColoredBox(
          color: theme.tokens.bgPrimary,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AttachmentStrip(
                attachments: _attachments,
                onRemove: (attachment) => setState(() {
                  _attachments.removeWhere(
                    (entry) => entry.id == attachment.id,
                  );
                }),
                onRetry: (attachment) => setState(() {
                  final index = _attachments.indexWhere(
                    (entry) => entry.id == attachment.id,
                  );
                  _attachments[index] = attachment.copyWith(
                    uploadState: AttachmentUploadState.ready,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
