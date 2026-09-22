import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// What to do with text that was edited from an already-sent message.
enum EditMessageChoice {
  /// Write the text onto that message and revert the conversation to it.
  revert,

  /// Leave that message alone and send the text as a new one.
  sendNew,
}

/// Asks whether an edited earlier message should rewind the conversation or
/// be sent as a new message. `null` means the edit session stays open.
Future<EditMessageChoice?> showEditMessageChoice(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showCcDialog<EditMessageChoice>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.editMessage,
      onClose: () => Navigator.of(dialogContext).pop(),
      content: Text(l10n.editMessageChoiceBody),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(EditMessageChoice.sendNew),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.sendAsNewMessage),
        ),
        CcButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(EditMessageChoice.revert),
          variant: CcButtonVariant.destructive,
          child: Text(l10n.revertToThere),
        ),
      ],
    ),
  );
}
