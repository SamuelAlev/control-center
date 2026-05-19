import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A small keyboard key-cap chip — the cc_ui replacement for the app's old
/// Riverpod-backed `Kbd` widget.
///
/// Renders [keyLabel] (already platform-formatted by the caller, e.g. `⌘K`,
/// `Esc`, `Ctrl+S`) inside a flat, hairline-bordered box using the monospace
/// type ramp via [CcFonts.code]. The mono family is resolved from [fontFamily]
/// when given; otherwise it falls back to the design system's JetBrains Mono.
///
/// This widget is presentational only — it holds no state and takes no
/// Riverpod/Provider dependencies; the caller supplies the formatted label.
class CcKbd extends StatelessWidget {
  /// Creates a [CcKbd].
  const CcKbd({
    super.key,
    required this.keyLabel,
    this.fontSize = 11,
    this.fontFamily,
  });

  /// Pre-formatted key label (e.g. `⌘K`, `Esc`, `Ctrl+S`).
  final String keyLabel;

  /// Font size of the label text.
  final double fontSize;

  /// Optional monospace family override. When null, the design system's
  /// default monospace family is used.
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadii.brXs,
        border: Border.all(color: t.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          keyLabel,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: CcFonts.code(
            family: fontFamily,
            textStyle: TextStyle(
              fontSize: fontSize,
              height: 1.3,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.4,
              color: t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
