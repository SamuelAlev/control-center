import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_opener.dart';
import 'package:control_center/shared/widgets/attachments/attachment_preview_pane.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_registry.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows [attachment] — in the split pane when the caller is hosted inside an
/// editor layout, in a dialog when it is not.
///
/// Both paths exist because the composer is shared. Inside a conversation it
/// sits in an IDE layout, where a preview belongs beside the work as a tab you
/// can split, move and keep open while you keep typing. On the dashboard, in a
/// settings sheet or on the phone there is no layout to open a tab in, and a
/// modal is the honest substitute — not a reason to make the reference
/// unclickable there.
///
/// The attachment is registered first either way: the tab carries only an id
/// (its arguments are persisted JSON), and the dialog reads through the same
/// registry so one eviction rule covers both.
Future<void> openAttachmentPreview(
  BuildContext context,
  WidgetRef ref,
  ComposerAttachment attachment,
) async {
  ref.read(attachmentRegistryProvider.notifier).register([attachment]);
  final opener = EditorTabOpenerScope.maybeOf(context);
  if (opener != null) {
    opener.open(
      EditorTab(
        kind: kAttachmentPreviewTabKind,
        label: attachment.refName ?? attachment.label,
        icon: attachmentIcon(attachment),
        // One tab per attachment: clicking the same reference twice brings the
        // open preview forward rather than stacking a second copy of it.
        dedupKey: 'attachment:${attachment.id}',
        args: {
          kAttachmentPreviewIdArg: attachment.id,
          'label': attachment.label,
        },
      ),
    );
    return;
  }
  await showCcDialog<void>(
    context: context,
    builder: (ctx) => CcDialog(
      title: attachment.label,
      content: SizedBox(
        width: 720,
        height: 480,
        child: AttachmentPreviewBody(attachment: attachment),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppLocalizations.of(ctx).close),
        ),
      ],
    ),
  );
}
