import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A deliberate second step before a plan begins spending or a goal stops.
Future<bool> confirmOperation(
  BuildContext context, {
  required String title,
  required String description,
  required String action,
  bool destructive = false,
}) async =>
    await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: title,
        content: Text(description),
        actions: [
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(dialogContext).cancel),
          ),
          CcButton(
            size: CcButtonSize.lg,
            variant: destructive
                ? CcButtonVariant.destructive
                : CcButtonVariant.primary,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
