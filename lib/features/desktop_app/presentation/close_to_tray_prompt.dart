import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/desktop_app/providers/desktop_app_preferences.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Asks, once, what the main window's close button should do.
///
/// Shown on the first close on Windows and Linux, where the X has always
/// quit: the app now keeps running in the tray by default, and that must not
/// happen behind the operator's back. Resolves to their pick (remembered by
/// the caller), or null when they dismiss it — the window then stays open.
Future<CloseAction?> showCloseToTrayPrompt(BuildContext context) =>
    showCcDialog<CloseAction>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        void pick(CloseAction action) =>
            Navigator.of(dialogContext).pop(action);
        return CcDialog(
          title: l10n.closeToTrayPromptTitle,
          content: Text(l10n.closeToTrayPromptBody),
          actions: [
            CcButton(
              variant: CcButtonVariant.ghost,
              onPressed: () => pick(CloseAction.quit),
              child: Text(l10n.closeToTrayPromptQuit),
            ),
            CcButton(
              autofocus: true,
              onPressed: () => pick(CloseAction.keepRunning),
              child: Text(l10n.closeToTrayPromptKeepRunning),
            ),
          ],
        );
      },
    );
