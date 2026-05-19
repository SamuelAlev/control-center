import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A small keyboard key-cap chip — the cc_ui replacement for the app's old
/// Riverpod-backed `Kbd` widget.
///
/// Renders [keyLabel] (already platform-formatted by the caller, e.g. `⌘K`,
/// `Esc`, `Ctrl+S`) inside a flat, hairline-bordered box using the monospace
/// type ramp via [CcFonts.code]. The mono family is resolved from [fontFamily]
/// when given; otherwise it falls back to the design system's Fira Code.
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
              fontWeight: CcTypography.regularWeight,
              letterSpacing: 0.4,
              color: t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Platform-aware symbols for the common modifier keys, so a shortcut hint
/// reads `⌘K` on macOS and `Ctrl K` elsewhere without the caller branching on
/// the platform.
///
/// These are presentational labels only; they do not bind anything. Pass the
/// resulting strings to [CcKbd] / [CcKbdGroup].
abstract final class CcKeys {
  /// The primary command modifier: `⌘` on macOS, `Ctrl` elsewhere.
  static String get cmdOrCtrl =>
      defaultTargetPlatform == TargetPlatform.macOS ? '⌘' : 'Ctrl';

  /// The option/alt modifier: `⌥` on macOS, `Alt` elsewhere.
  static String get optionOrAlt =>
      defaultTargetPlatform == TargetPlatform.macOS ? '⌥' : 'Alt';

  /// The shift modifier symbol.
  static String get shift =>
      defaultTargetPlatform == TargetPlatform.macOS ? '⇧' : 'Shift';

  /// The enter/return key symbol.
  static const String enter = '↵';

  /// The escape key label.
  static const String escape = 'Esc';
}

/// Composes an ordered sequence of [CcKbd] key-caps into a single chord, e.g.
/// `⌘` + `↵` or `G` then `P`. Each entry in [keys] is rendered as its own cap
/// with a thin [separator] between them, so multi-key shortcuts stay legible
/// at the point of use.
///
/// Like [CcKbd] this is purely presentational — the caller supplies already
/// platform-formatted labels (see [CcKeys]).
class CcKbdGroup extends StatelessWidget {
  /// Creates a [CcKbdGroup].
  const CcKbdGroup({
    super.key,
    required this.keys,
    this.fontSize = 11,
    this.fontFamily,
    this.separator,
  });

  /// The ordered key labels rendered as individual caps.
  final List<String> keys;

  /// Font size forwarded to each [CcKbd].
  final double fontSize;

  /// Optional monospace family override forwarded to each [CcKbd].
  final String? fontFamily;

  /// Widget placed between caps. Defaults to a small horizontal gap.
  final Widget? separator;

  @override
  Widget build(BuildContext context) {
    final gap = separator ?? const SizedBox(width: AppSpacing.xs);
    final children = <Widget>[];
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) {
        children.add(gap);
      }
      children.add(
        CcKbd(keyLabel: keys[i], fontSize: fontSize, fontFamily: fontFamily),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// A point-of-use shortcut hint: a [CcKbdGroup] chord followed by a short
/// [label] describing what it does — e.g. `⌘↵ Allow` next to a confirm button.
///
/// Surfaces a keyboard affordance inline so shortcuts are discoverable without
/// a separate cheatsheet. The label uses the caption ramp in a muted tone so it
/// stays quiet next to the action it annotates.
class CcShortcutHint extends StatelessWidget {
  /// Creates a [CcShortcutHint].
  const CcShortcutHint({
    super.key,
    required this.keys,
    required this.label,
    this.fontSize = 11,
  });

  /// The chord key labels (already platform-formatted, see [CcKeys]).
  final List<String> keys;

  /// What the chord does, e.g. `Allow`, `Deny`, `Send`.
  final String label;

  /// Font size forwarded to the key-caps.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcKbdGroup(keys: keys, fontSize: fontSize),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
      ],
    );
  }
}
