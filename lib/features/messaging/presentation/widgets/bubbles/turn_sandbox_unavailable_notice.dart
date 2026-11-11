import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A run the server refused before it started: it has no sandbox, and only
/// work its owner is accountable for may run unsandboxed on its machine.
///
/// Guidance, not a red error row: nothing broke, and the fix is the owner's
/// (install the sandbox, or turn sandboxing off for everyone). Read from the
/// segment's code, never from the server's sentence.
class TurnSandboxUnavailableNotice extends StatelessWidget {
  /// Creates a [TurnSandboxUnavailableNotice].
  const TurnSandboxUnavailableNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcAlert(
      variant: CcAlertVariant.info,
      icon: AppIcons.shield,
      title: l10n.runSandboxUnavailableTitle,
      description: Text(l10n.runSandboxUnavailable),
    );
  }
}
