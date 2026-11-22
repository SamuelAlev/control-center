import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The strip at the top of the composer while a sent message is loaded in it.
class EditingMessageBanner extends StatelessWidget {
  /// Creates the banner.
  const EditingMessageBanner({super.key, required this.onCancel});

  /// Ends the edit, putting the parked draft back.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(AppIcons.pencil, size: 14, color: ds.fgSecondary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.editMessage,
                style: CcTypography.caption.copyWith(
                  color: ds.fgSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CcIconButton(
              icon: AppIcons.x,
              size: CcButtonSize.sm,
              tooltip: l10n.cancelEdit,
              onPressed: onCancel,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const CcDivider(),
        // The gap to the field is the banner's own (see `Composer.banner`).
        const SizedBox(height: 6),
      ],
    );
  }
}
