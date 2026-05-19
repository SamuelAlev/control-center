import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:flutter/widgets.dart';

/// A mono, uppercase, wide-tracked eyebrow — the quiet region/section cue.
class AppEyebrow extends StatelessWidget {
  /// Creates an [AppEyebrow].
  const AppEyebrow(this.text, {super.key, this.codeFont, this.color});

  /// Eyebrow label.
  final String text;

  /// Optional code-font family; defaults to Fira Code.
  final String? codeFont;

  /// Optional colour override.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final family = codeFont;
    final style = TextStyle(
      fontSize: 11,
      letterSpacing: 1.1,
      height: 1.2,
      fontWeight: FontWeight.w500,
      color: color ?? ds.muted,
    );
    return Text(
      text.toUpperCase(),
      style: family != null
          ? AppFonts.codeDynamic(family, textStyle: style)
          : AppFonts.code(textStyle: style),
    );
  }
}
