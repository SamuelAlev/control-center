import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A command to read and copy.
class EnvironmentCommandBox extends StatelessWidget {
  /// Creates an [EnvironmentCommandBox].
  const EnvironmentCommandBox({super.key, required this.command});

  /// The command text.
  final String command;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // RTL carve-out: a shell command reads left to right in every locale.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.sm,
          end: AppSpacing.xxs,
          top: AppSpacing.xxs,
          bottom: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: t.bgSecondary,
          border: Border.all(color: t.borderSecondary),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                command,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: CcFonts.code(
                  textStyle: CcTypography.caption.copyWith(
                    color: t.textPrimary,
                  ),
                ),
              ),
            ),
            CcIconButton(
              icon: AppIcons.copy,
              size: CcButtonSize.sm,
              tooltip: l10n.environmentCopyCommand,
              onPressed: () => copyEnvironmentText(context, command),
            ),
          ],
        ),
      ),
    );
  }
}
