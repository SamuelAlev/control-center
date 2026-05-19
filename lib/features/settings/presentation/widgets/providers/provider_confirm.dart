import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Confirms a destructive provider action, then runs it.
///
/// Disconnecting is not undoable from the settings screen — an API key is not
/// shown again after saving and an OAuth plan needs the whole browser login
/// repeated — and it silently strands every agent pinned to one of the
/// provider's models. Cheap to confirm, expensive to misclick.
///
/// Shared by the credential controls and the remove-provider action so the two
/// cannot drift into confirming differently.
Future<void> confirmProviderAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required Future<void> Function() action,
  required void Function({required bool busy}) setBusy,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showCcDialog<bool>(
    context: context,
    builder: (ctx) => CcDialog(
      title: title,
      content: Text(body),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.destructive,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }
  setBusy(busy: true);
  try {
    await action();
  } finally {
    setBusy(busy: false);
  }
}
