import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/theme_choice.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Theme choices, each shown as a miniature of the app.
class ThemeChoicePicker extends StatelessWidget {
  /// Creates a [ThemeChoicePicker].
  const ThemeChoicePicker({
    super.key,
    required this.theme,
    required this.onChanged,
  });

  /// The saved choice.
  final ThemeChoice theme;

  /// Saves a choice.
  final ValueChanged<ThemeChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      ThemeChoice.system: l10n.themeSystem,
      ThemeChoice.light: l10n.themeLight,
      ThemeChoice.dark: l10n.themeDark,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, choice) in ThemeChoice.values.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _ThemeTile(
              choice: choice,
              label: labels[choice]!,
              selected: choice == theme,
              onPressed: () => onChanged(choice),
            ),
          ),
        ],
      ],
    );
  }
}

/// One theme, shown as a miniature of the app. The selection carries a check
/// as well as the outline, so it survives without color.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.choice,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final ThemeChoice choice;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final light = CcThemeData.light().tokens;
    final dark = CcThemeData.dark().tokens;
    return Semantics(
      selected: selected,
      child: CcTappable(
        onPressed: onPressed,
        semanticLabel: label,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? t.fgBrandPrimary : t.borderPrimary,
                  width: selected ? 2 : 1,
                ),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CustomPaint(
                  painter: _ThemePreviewPainter(
                    start: choice == ThemeChoice.dark ? dark : light,
                    end: choice == ThemeChoice.system ? dark : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(
                      color: t.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(AppIcons.check, size: 14, color: t.fgBrandPrimary),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a miniature of the app in [start]'s colors, with its right half in
/// [end]'s when set. RTL carve-out: these are painter coordinates, and the
/// miniature is a picture of a theme, not text to mirror.
class _ThemePreviewPainter extends CustomPainter {
  const _ThemePreviewPainter({required this.start, this.end});

  final DesignSystemTokens start;
  final DesignSystemTokens? end;

  void _paintScene(Canvas canvas, Size size, DesignSystemTokens t) {
    final rail = size.width * 0.28;
    final unit = size.height / 16;
    void bar(double x, double y, double width, Color color) {
      canvas.drawRect(Rect.fromLTWH(x, y, width, unit), Paint()..color = color);
    }

    canvas
      ..drawRect(Offset.zero & size, Paint()..color = t.bgPrimary)
      ..drawRect(
        Rect.fromLTWH(0, 0, rail, size.height),
        Paint()..color = t.bgSecondary,
      );
    for (final row in [2.0, 5.0, 8.0]) {
      bar(unit * 2, unit * row, rail - unit * 4, t.textTertiary);
    }
    final x = rail + unit * 2;
    final width = size.width - x - unit * 2;
    bar(x, unit * 2, width * 0.55, t.textPrimary);
    bar(x, unit * 5, width, t.textTertiary);
    bar(x, unit * 8, width * 0.8, t.textTertiary);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - unit * 2 - width * 0.35,
        size.height - unit * 4,
        width * 0.35,
        unit * 2,
      ),
      Paint()..color = t.bgBrandSolid,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintScene(canvas, size, start);
    final second = end;
    if (second != null) {
      canvas
        ..save()
        ..clipRect(
          Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
        );
      _paintScene(canvas, size, second);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ThemePreviewPainter oldDelegate) =>
      oldDelegate.start != start || oldDelegate.end != end;
}
