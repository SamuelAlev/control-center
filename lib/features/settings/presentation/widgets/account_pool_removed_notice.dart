import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Says the pool names only removed accounts, with the one-click way out.
///
/// Clearing is offered rather than done automatically: an agent pool cleared
/// falls back to the workspace's accounts, and whether that is acceptable is
/// the operator's call, not the server's.
class AccountPoolRemovedNotice extends StatelessWidget {
  /// Creates an [AccountPoolRemovedNotice].
  const AccountPoolRemovedNotice({required this.onClear, super.key});

  /// Clears the pool.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountPoolAllRemoved,
          style: TextStyle(fontSize: 12, color: t.fgWarningPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          onPressed: onClear,
          child: Text(l10n.accountPoolClear),
        ),
      ],
    );
  }
}
