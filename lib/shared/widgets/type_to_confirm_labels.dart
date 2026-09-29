import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The localized strings for `showCcConfirmDialog(typeToConfirm: ...)`.
///
/// cc_ui carries no localizations, so every dialog that asks for a name to be
/// typed back hands it the same prompt and copy labels from here; a per-call
/// literal is how two destructive dialogs end up asking differently.
CcTypeToConfirmLabels appTypeToConfirmLabels(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return CcTypeToConfirmLabels(
    prompt: l10n.typeToConfirmPrompt,
    copy: l10n.copy,
    copied: l10n.copied,
  );
}
