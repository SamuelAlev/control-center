import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The last lines a command printed before it failed, to read and copy.
///
/// A tool's own summary often names only what gave up ("compose exited 1").
/// The reason is in what it printed just before, so that sits right under it
/// instead of a tab away.
class EnvironmentOutputBox extends StatelessWidget {
  /// Creates an [EnvironmentOutputBox].
  const EnvironmentOutputBox({super.key, required this.output});

  /// The lines, oldest first.
  final String output;

  /// Lines shown. Copy takes all of them.
  static const int visibleLines = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final lines = output.split('\n');
    final shown = lines
        .skip(lines.length > visibleLines ? lines.length - visibleLines : 0)
        .map((line) => line.trim())
        .join('\n');
    // RTL carve-out: command output reads left to right in every locale.
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Text(
                  shown,
                  maxLines: visibleLines * 2,
                  overflow: TextOverflow.ellipsis,
                  style: CcFonts.code(
                    textStyle: CcTypography.caption.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            CcIconButton(
              icon: AppIcons.copy,
              size: CcButtonSize.sm,
              tooltip: l10n.copy,
              onPressed: () => copyEnvironmentText(context, output),
            ),
          ],
        ),
      ),
    );
  }
}
