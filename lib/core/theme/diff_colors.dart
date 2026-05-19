import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/vscode_theme/domain/vscode_editor_theme.dart';
import 'package:flutter/widgets.dart';

/// The single source of truth for diff add/remove colors across CC's three diff
/// surfaces — the PR-details canvas diff, the messaging transcript edit diff,
/// and the session-review diff. Previously each surface defined its own
/// add/delete backgrounds (8–12% vs a hard-coded 20% vs design-token green/red),
/// so the same change looked different depending on where you saw it.
///
/// The add/delete set is GitHub's hand-tuned diff palette, per brightness:
/// line tint, stronger word-level (intraline) tint, and the line-number gutter
/// tint. Light mode uses Primer's solid tints rather than alpha blends of the
/// accent — an alpha blend over white always drags the dominant channel below
/// 255 and reads grey-muddy, while the tuned values keep it at 255 so the tint
/// stays luminous. Dark mode alpha-blends GitHub's *dark* hues over the editor
/// surface (the light-mode hues turn brown on dark). Context/gutter/hunk colors
/// come from the design-system tokens. An imported VS Code theme can override
/// the whole set via [DiffColors.fromVsCode].
///
/// The syntax-token palette is *already* shared (`lightSyntaxPalette` /
/// `darkSyntaxPalette`), so it is intentionally not duplicated here.
@immutable
class DiffColors {
  /// Creates a [DiffColors].
  const DiffColors({
    required this.additionBg,
    required this.deletionBg,
    required this.additionWordBg,
    required this.deletionWordBg,
    required this.additionGutterBg,
    required this.deletionGutterBg,
    required this.additionGutterFg,
    required this.deletionGutterFg,
    required this.additionAccent,
    required this.deletionAccent,
    required this.contextFg,
    required this.gutterFg,
    required this.hunkBg,
  });

  /// The canonical diff colors for [brightness], blending GitHub add/delete
  /// hues with the design-system text/gutter tokens for that brightness.
  factory DiffColors.forBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final t = dark ? DesignSystemTokens.dark() : DesignSystemTokens.light();
    if (dark) {
      return DiffColors(
        additionBg: _darkGreenBlend.withValues(alpha: 0.15),
        deletionBg: _darkRed.withValues(alpha: 0.15),
        additionWordBg: _darkGreenBlend.withValues(alpha: 0.4),
        deletionWordBg: _darkRed.withValues(alpha: 0.4),
        additionGutterBg: _darkGreen.withValues(alpha: 0.3),
        deletionGutterBg: _darkRed.withValues(alpha: 0.3),
        additionGutterFg: const Color(0xFF56D364),
        deletionGutterFg: const Color(0xFFFF7B72),
        additionAccent: _darkGreen,
        deletionAccent: _darkRed,
        contextFg: t.textSecondary,
        gutterFg: t.textQuaternary,
        hunkBg: t.bgSecondary,
      );
    }
    return DiffColors(
      additionBg: const Color(0xFFE6FFEC),
      deletionBg: const Color(0xFFFFEBE9),
      additionWordBg: const Color(0xFFABF2BC),
      deletionWordBg: const Color(0xFFFFCECB),
      additionGutterBg: const Color(0xFFCCFFD8),
      deletionGutterBg: const Color(0xFFFFD7D5),
      additionGutterFg: const Color(0xFF116329),
      deletionGutterFg: const Color(0xFF82071E),
      additionAccent: _green,
      deletionAccent: _red,
      contextFg: t.textSecondary,
      gutterFg: t.textQuaternary,
      hunkBg: t.bgSecondary,
    );
  }

  /// Resolves diff colors from [context]'s brightness and design tokens.
  factory DiffColors.of(BuildContext context) =>
      DiffColors.forBrightness(diffBrightnessOf(context));

  /// Diff colors distilled from an imported VS Code [theme], so the embedded
  /// diff matches the user's IDE. VS Code themes only carry line-level diff
  /// backgrounds, so the word emphasis is a translucent accent that composites
  /// over whatever line tint the theme chose, and the gutter reuses the line
  /// tint with the theme's own line-number color.
  factory DiffColors.fromVsCode(VsCodeEditorTheme theme) {
    final dark = theme.brightness == Brightness.dark;
    final green = dark ? _darkGreen : _green;
    final red = dark ? _darkRed : _red;
    return DiffColors(
      additionBg: theme.addedBackground,
      deletionBg: theme.removedBackground,
      additionWordBg: green.withValues(alpha: 0.4),
      deletionWordBg: red.withValues(alpha: 0.4),
      additionGutterBg: theme.addedBackground,
      deletionGutterBg: theme.removedBackground,
      additionGutterFg: theme.lineNumber,
      deletionGutterFg: theme.lineNumber,
      additionAccent: green,
      deletionAccent: red,
      contextFg: theme.foreground,
      gutterFg: theme.lineNumber,
      hunkBg: theme.foreground.withValues(alpha: dark ? 0.06 : 0.04),
    );
  }

  /// Added-line row background.
  final Color additionBg;

  /// Removed-line row background.
  final Color deletionBg;

  /// Word-level (intraline) emphasis over an added line — the changed
  /// characters within a modified line pair. Stronger than [additionBg];
  /// glyphs keep their syntax color on top of it.
  final Color additionWordBg;

  /// Word-level (intraline) emphasis over a removed line.
  final Color deletionWordBg;

  /// Line-number gutter tint on added rows (stronger than the row tint, like
  /// GitHub's number column).
  final Color additionGutterBg;

  /// Line-number gutter tint on removed rows.
  final Color deletionGutterBg;

  /// Line-number text on added rows.
  final Color additionGutterFg;

  /// Line-number text on removed rows.
  final Color deletionGutterFg;

  /// Added-line accent (the `+` marker / added text).
  final Color additionAccent;

  /// Removed-line accent (the `-` marker / removed text).
  final Color deletionAccent;

  /// Unchanged (context) line text.
  final Color contextFg;

  /// Gutter line-number text.
  final Color gutterFg;

  /// Hunk-header row background.
  final Color hunkBg;

  // GitHub's accent hues. Light mode keeps the Primer light accents; dark mode
  // needs the brighter dark-theme hues (the light ones lose all chroma on a
  // dark surface). _darkGreenBlend is Primer's dedicated blend hue for dark
  // line/word tints (slightly deeper than the dark accent).
  static const Color _green = Color(0xFF2DA44E);
  static const Color _red = Color(0xFFCF222E);
  static const Color _darkGreen = Color(0xFF3FB950);
  static const Color _darkRed = Color(0xFFF85149);
  static const Color _darkGreenBlend = Color(0xFF2EA043);
}

/// The brightness a diff surface should render at: the [CcTheme]'s when there is
/// one (the app always installs it), the platform's otherwise. Shared by
/// [DiffColors.of] and by the syntax palette every diff renderer picks, so a
/// diff's tints and its code colours can never disagree about the mode.
Brightness diffBrightnessOf(BuildContext context) {
  final cc = context.ccTheme?.brightness;
  if (cc == CcBrightness.dark) {
    return Brightness.dark;
  }
  if (cc == CcBrightness.light) {
    return Brightness.light;
  }
  return MediaQuery.maybeOf(context)?.platformBrightness ?? Brightness.light;
}
