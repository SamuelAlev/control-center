import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:flutter/material.dart';

/// design system semantic design tokens.
///
/// Names mirror the CSS variables in the design source (`--color-bg-primary`
/// → [bgPrimary], `--color-text-secondary_hover` → [textSecondaryHover], …)
/// so a token written by a designer maps to exactly one field here.
///
/// Use [DesignSystemTokens.of] (or the [BuildContext] extension) to read tokens
/// inside widgets. ForUI's `FColors` holds the subset ForUI's own widgets
/// consume; this extension is the source of truth for anything richer.
final class DesignSystemTokens extends ThemeExtension<DesignSystemTokens> {
  /// Creates [DesignSystemTokens].
  const DesignSystemTokens({
    // Backgrounds.
    required this.bgPrimary,
    required this.bgPrimaryHover,
    required this.bgPrimaryAlt,
    required this.bgPrimarySolid,
    required this.bgSecondary,
    required this.bgSecondaryHover,
    required this.bgSecondaryAlt,
    required this.bgSecondarySolid,
    required this.bgTertiary,
    required this.bgQuaternary,
    required this.bgActive,
    required this.bgDisabled,
    required this.bgOverlay,
    required this.bgBrandPrimary,
    required this.bgBrandPrimaryAlt,
    required this.bgBrandSecondary,
    required this.bgBrandSolid,
    required this.bgBrandSolidHover,
    required this.bgBrandSection,
    required this.bgBrandSectionSubtle,
    required this.bgErrorPrimary,
    required this.bgErrorSecondary,
    required this.bgErrorSolid,
    required this.bgErrorSolidHover,
    required this.bgWarningPrimary,
    required this.bgWarningSecondary,
    required this.bgWarningSolid,
    required this.bgSuccessPrimary,
    required this.bgSuccessSecondary,
    required this.bgSuccessSolid,
    // Text.
    required this.textPrimary,
    required this.textSecondary,
    required this.textSecondaryHover,
    required this.textTertiary,
    required this.textTertiaryHover,
    required this.textQuaternary,
    required this.textQuaternaryOnBrand,
    required this.textPlaceholder,
    required this.textDisabled,
    required this.textWhite,
    required this.textBrandPrimary,
    required this.textBrandSecondary,
    required this.textBrandSecondaryHover,
    required this.textBrandTertiary,
    required this.textBrandTertiaryAlt,
    required this.textPrimaryOnBrand,
    required this.textSecondaryOnBrand,
    required this.textTertiaryOnBrand,
    required this.textErrorPrimary,
    required this.textErrorPrimaryHover,
    required this.textWarningPrimary,
    required this.textSuccessPrimary,
    // Foreground (icons & decorative).
    required this.fgPrimary,
    required this.fgSecondary,
    required this.fgSecondaryHover,
    required this.fgTertiary,
    required this.fgTertiaryHover,
    required this.fgQuaternary,
    required this.fgQuaternaryHover,
    required this.fgDisabled,
    required this.fgWhite,
    required this.fgBrandPrimary,
    required this.fgBrandPrimaryAlt,
    required this.fgBrandSecondary,
    required this.fgBrandSecondaryAlt,
    required this.fgBrandSecondaryHover,
    required this.fgErrorPrimary,
    required this.fgErrorSecondary,
    required this.fgWarningPrimary,
    required this.fgWarningSecondary,
    required this.fgSuccessPrimary,
    required this.fgSuccessSecondary,
    // Borders.
    required this.borderPrimary,
    required this.borderSecondary,
    required this.borderSecondaryAlt,
    required this.borderTertiary,
    required this.borderDisabled,
    required this.borderBrand,
    required this.borderBrandAlt,
    required this.borderBrandSolid,
    required this.borderBrandSolidHover,
    required this.borderError,
    required this.borderErrorSubtle,
    // Focus rings.
    required this.focusRing,
    required this.focusRingError,
    // Design-system aliases (near-white / ink-black / orange system).
    required this.canvas,
    required this.surface,
    required this.panel,
    required this.sidebar,
    required this.rail,
    required this.fg,
    required this.muted,
    required this.idle,
    required this.borderSoft,
    required this.lineStrong,
    required this.hover,
    required this.hoverStrong,
    required this.accent,
    required this.accentOn,
    required this.accentHover,
    required this.accentActive,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.warn,
    required this.warnSoft,
    required this.danger,
    required this.dangerSoft,
    required this.sunshine900,
    required this.sunshine700,
    required this.sunshine500,
    required this.sunshine300,
    required this.brightYellow,
    required this.blockEdge,
  });

  /// design system tokens for a light theme.
  factory DesignSystemTokens.light() => const DesignSystemTokens(
        bgPrimary: DesignSystemPalette.white,
        // Hover wash on a white surface — the warm-neutral surface (#f2f0e9),
        // a clearly-visible ~5% step. (gray50 = the page canvas, which made
        // row/card hovers blend into the background.)
        bgPrimaryHover: DesignSystemPalette.gray100,
        bgPrimaryAlt: DesignSystemPalette.white,
        bgPrimarySolid: DesignSystemPalette.gray950,
        bgSecondary: DesignSystemPalette.gray50,
        bgSecondaryHover: DesignSystemPalette.gray100,
        bgSecondaryAlt: DesignSystemPalette.gray50,
        bgSecondarySolid: DesignSystemPalette.gray600,
        bgTertiary: DesignSystemPalette.gray100,
        bgQuaternary: DesignSystemPalette.gray200,
        bgActive: DesignSystemPalette.gray50,
        bgDisabled: DesignSystemPalette.gray100,
        bgOverlay: DesignSystemPalette.gray950,
        bgBrandPrimary: DesignSystemPalette.brand50,
        bgBrandPrimaryAlt: DesignSystemPalette.brand50,
        bgBrandSecondary: DesignSystemPalette.brand100,
        bgBrandSolid: DesignSystemPalette.brand600,
        bgBrandSolidHover: DesignSystemPalette.brand700,
        bgBrandSection: DesignSystemPalette.brand800,
        bgBrandSectionSubtle: DesignSystemPalette.brand700,
        bgErrorPrimary: DesignSystemPalette.red50,
        bgErrorSecondary: DesignSystemPalette.red100,
        bgErrorSolid: DesignSystemPalette.red600,
        bgErrorSolidHover: DesignSystemPalette.red700,
        bgWarningPrimary: DesignSystemPalette.yellow50,
        bgWarningSecondary: DesignSystemPalette.yellow100,
        bgWarningSolid: DesignSystemPalette.yellow600,
        bgSuccessPrimary: DesignSystemPalette.green50,
        bgSuccessSecondary: DesignSystemPalette.green100,
        bgSuccessSolid: DesignSystemPalette.green600,
        textPrimary: DesignSystemPalette.gray900,
        textSecondary: DesignSystemPalette.gray700,
        textSecondaryHover: DesignSystemPalette.gray800,
        textTertiary: DesignSystemPalette.gray600,
        textTertiaryHover: DesignSystemPalette.gray700,
        textQuaternary: DesignSystemPalette.gray500,
        textQuaternaryOnBrand: DesignSystemPalette.brand300,
        textPlaceholder: DesignSystemPalette.gray500,
        textDisabled: DesignSystemPalette.gray500,
        textWhite: DesignSystemPalette.white,
        textBrandPrimary: DesignSystemPalette.brand900,
        textBrandSecondary: DesignSystemPalette.brand700,
        textBrandSecondaryHover: DesignSystemPalette.brand800,
        textBrandTertiary: DesignSystemPalette.brand600,
        textBrandTertiaryAlt: DesignSystemPalette.brand600,
        textPrimaryOnBrand: DesignSystemPalette.white,
        textSecondaryOnBrand: DesignSystemPalette.brand200,
        textTertiaryOnBrand: DesignSystemPalette.brand200,
        textErrorPrimary: DesignSystemPalette.red600,
        textErrorPrimaryHover: DesignSystemPalette.red700,
        textWarningPrimary: DesignSystemPalette.yellow600,
        textSuccessPrimary: DesignSystemPalette.green600,
        fgPrimary: DesignSystemPalette.gray900,
        fgSecondary: DesignSystemPalette.gray700,
        fgSecondaryHover: DesignSystemPalette.gray800,
        fgTertiary: DesignSystemPalette.gray600,
        fgTertiaryHover: DesignSystemPalette.gray700,
        fgQuaternary: DesignSystemPalette.gray500,
        fgQuaternaryHover: DesignSystemPalette.gray600,
        fgDisabled: DesignSystemPalette.gray400,
        fgWhite: DesignSystemPalette.white,
        fgBrandPrimary: DesignSystemPalette.brand600,
        fgBrandPrimaryAlt: DesignSystemPalette.brand600,
        fgBrandSecondary: DesignSystemPalette.brand500,
        fgBrandSecondaryAlt: DesignSystemPalette.brand500,
        fgBrandSecondaryHover: DesignSystemPalette.brand600,
        fgErrorPrimary: DesignSystemPalette.red600,
        fgErrorSecondary: DesignSystemPalette.red500,
        fgWarningPrimary: DesignSystemPalette.yellow600,
        fgWarningSecondary: DesignSystemPalette.yellow500,
        fgSuccessPrimary: DesignSystemPalette.green600,
        fgSuccessSecondary: DesignSystemPalette.green500,
        borderPrimary: DesignSystemPalette.gray300,
        borderSecondary: DesignSystemPalette.gray200,
        borderSecondaryAlt: Color(0x1A1F1F1F), // fg @ 10% (warm, never pure black)
        borderTertiary: DesignSystemPalette.gray100,
        borderDisabled: DesignSystemPalette.gray200,
        borderBrand: DesignSystemPalette.brand500,
        borderBrandAlt: DesignSystemPalette.brand600,
        borderBrandSolid: DesignSystemPalette.brand600,
        borderBrandSolidHover: DesignSystemPalette.brand700,
        borderError: DesignSystemPalette.red500,
        borderErrorSubtle: DesignSystemPalette.red300,
        focusRing: DesignSystemPalette.brand600,
        focusRingError: DesignSystemPalette.red500,
        // Design-system aliases.
        canvas: DesignSystemPalette.gray50,
        surface: DesignSystemPalette.gray100,
        panel: DesignSystemPalette.white,
        sidebar: Color(0xFFF7F5F0),
        rail: Color(0xFFFAF9F5),
        fg: DesignSystemPalette.gray900,
        muted: DesignSystemPalette.gray600,
        idle: Color(0x611F1F1F),
        borderSoft: Color(0xFFEFECE4),
        lineStrong: Color(0x291F1F1F),
        hover: Color(0x0D1F1F1F),
        hoverStrong: Color(0x141F1F1F),
        accent: DesignSystemPalette.brand600,
        accentOn: DesignSystemPalette.white,
        accentHover: DesignSystemPalette.brand500,
        accentActive: DesignSystemPalette.brand700,
        accentSoft: Color(0x1FFA520F),
        success: DesignSystemPalette.green600,
        successSoft: Color(0x2417A34A),
        warn: DesignSystemPalette.yellow500,
        warnSoft: Color(0x33EAB308),
        danger: DesignSystemPalette.red600,
        dangerSoft: Color(0x1FDC2626),
        sunshine900: DesignSystemPalette.sunshine900,
        sunshine700: DesignSystemPalette.sunshine700,
        sunshine500: DesignSystemPalette.sunshine500,
        sunshine300: DesignSystemPalette.sunshine300,
        brightYellow: DesignSystemPalette.brightYellow,
        blockEdge: DesignSystemPalette.blockEdge,
      );

  /// design system tokens for a dark theme — mirrors the design source verbatim.
  factory DesignSystemTokens.dark() => const DesignSystemTokens(
        bgPrimary: DesignSystemPalette.gray950,
        bgPrimaryHover: DesignSystemPalette.gray900,
        bgPrimaryAlt: DesignSystemPalette.gray900,
        bgPrimarySolid: DesignSystemPalette.gray900,
        bgSecondary: DesignSystemPalette.gray900,
        bgSecondaryHover: DesignSystemPalette.gray800,
        bgSecondaryAlt: DesignSystemPalette.gray950,
        bgSecondarySolid: DesignSystemPalette.gray600,
        bgTertiary: DesignSystemPalette.gray800,
        bgQuaternary: DesignSystemPalette.gray700,
        bgActive: DesignSystemPalette.gray800,
        bgDisabled: DesignSystemPalette.gray800,
        bgOverlay: DesignSystemPalette.gray800,
        bgBrandPrimary: DesignSystemPalette.brand500,
        bgBrandPrimaryAlt: DesignSystemPalette.gray900,
        bgBrandSecondary: DesignSystemPalette.brand600,
        bgBrandSolid: DesignSystemPalette.brand600,
        bgBrandSolidHover: DesignSystemPalette.brand500,
        bgBrandSection: DesignSystemPalette.gray900,
        bgBrandSectionSubtle: DesignSystemPalette.gray950,
        bgErrorPrimary: DesignSystemPalette.red950,
        bgErrorSecondary: DesignSystemPalette.red600,
        bgErrorSolid: DesignSystemPalette.red600,
        bgErrorSolidHover: DesignSystemPalette.red500,
        bgWarningPrimary: DesignSystemPalette.yellow950,
        bgWarningSecondary: DesignSystemPalette.yellow600,
        bgWarningSolid: DesignSystemPalette.yellow600,
        bgSuccessPrimary: DesignSystemPalette.green950,
        bgSuccessSecondary: DesignSystemPalette.green600,
        bgSuccessSolid: DesignSystemPalette.green600,
        textPrimary: DesignSystemPalette.gray50,
        textSecondary: DesignSystemPalette.gray300,
        textSecondaryHover: DesignSystemPalette.gray200,
        textTertiary: DesignSystemPalette.gray400,
        textTertiaryHover: DesignSystemPalette.gray300,
        textQuaternary: DesignSystemPalette.gray400,
        textQuaternaryOnBrand: DesignSystemPalette.gray400,
        textPlaceholder: DesignSystemPalette.gray500,
        textDisabled: DesignSystemPalette.gray500,
        textWhite: DesignSystemPalette.white,
        textBrandPrimary: DesignSystemPalette.gray50,
        textBrandSecondary: DesignSystemPalette.gray300,
        textBrandSecondaryHover: DesignSystemPalette.gray200,
        textBrandTertiary: DesignSystemPalette.gray400,
        textBrandTertiaryAlt: DesignSystemPalette.gray50,
        textPrimaryOnBrand: DesignSystemPalette.gray50,
        textSecondaryOnBrand: DesignSystemPalette.gray300,
        textTertiaryOnBrand: DesignSystemPalette.gray400,
        textErrorPrimary: DesignSystemPalette.red400,
        textErrorPrimaryHover: DesignSystemPalette.red300,
        textWarningPrimary: DesignSystemPalette.yellow400,
        textSuccessPrimary: DesignSystemPalette.green400,
        fgPrimary: DesignSystemPalette.white,
        fgSecondary: DesignSystemPalette.gray300,
        fgSecondaryHover: DesignSystemPalette.gray200,
        fgTertiary: DesignSystemPalette.gray400,
        fgTertiaryHover: DesignSystemPalette.gray300,
        fgQuaternary: DesignSystemPalette.gray600,
        fgQuaternaryHover: DesignSystemPalette.gray500,
        fgDisabled: DesignSystemPalette.gray500,
        fgWhite: DesignSystemPalette.white,
        fgBrandPrimary: DesignSystemPalette.brand500,
        fgBrandPrimaryAlt: DesignSystemPalette.gray300,
        fgBrandSecondary: DesignSystemPalette.brand500,
        fgBrandSecondaryAlt: DesignSystemPalette.gray600,
        fgBrandSecondaryHover: DesignSystemPalette.gray500,
        fgErrorPrimary: DesignSystemPalette.red500,
        fgErrorSecondary: DesignSystemPalette.red400,
        fgWarningPrimary: DesignSystemPalette.yellow500,
        fgWarningSecondary: DesignSystemPalette.yellow400,
        fgSuccessPrimary: DesignSystemPalette.green500,
        fgSuccessSecondary: DesignSystemPalette.green400,
        borderPrimary: DesignSystemPalette.gray700,
        borderSecondary: DesignSystemPalette.gray800,
        borderSecondaryAlt: DesignSystemPalette.gray800,
        borderTertiary: DesignSystemPalette.gray800,
        borderDisabled: DesignSystemPalette.gray700,
        borderBrand: DesignSystemPalette.brand400,
        borderBrandAlt: DesignSystemPalette.gray700,
        borderBrandSolid: DesignSystemPalette.brand600,
        borderBrandSolidHover: DesignSystemPalette.brand500,
        borderError: DesignSystemPalette.red400,
        borderErrorSubtle: DesignSystemPalette.red500,
        focusRing: DesignSystemPalette.brand500,
        focusRingError: DesignSystemPalette.red500,
        // Design-system aliases (warm dark derivation of the light system).
        canvas: DesignSystemPalette.gray950,
        surface: DesignSystemPalette.gray800,
        panel: DesignSystemPalette.gray900,
        sidebar: Color(0xFF121110),
        rail: Color(0xFF1B1A17),
        fg: DesignSystemPalette.gray50,
        muted: DesignSystemPalette.gray400,
        idle: Color(0x61FCFBF9),
        borderSoft: DesignSystemPalette.gray800,
        lineStrong: Color(0x29FCFBF9),
        hover: Color(0x0DFCFBF9),
        hoverStrong: Color(0x14FCFBF9),
        accent: DesignSystemPalette.brand500,
        accentOn: DesignSystemPalette.white,
        accentHover: DesignSystemPalette.brand400,
        accentActive: DesignSystemPalette.brand600,
        accentSoft: Color(0x1FFB6424),
        success: DesignSystemPalette.green400,
        successSoft: Color(0x2447CD89),
        warn: DesignSystemPalette.yellow400,
        warnSoft: Color(0x33FAC515),
        danger: DesignSystemPalette.red400,
        dangerSoft: Color(0x1FF97066),
        sunshine900: DesignSystemPalette.sunshine900,
        sunshine700: DesignSystemPalette.sunshine700,
        sunshine500: DesignSystemPalette.sunshine500,
        sunshine300: DesignSystemPalette.sunshine300,
        brightYellow: DesignSystemPalette.brightYellow,
        blockEdge: DesignSystemPalette.blockEdge,
      );

  // Backgrounds.
  /// bgPrimary — background color.
  final Color bgPrimary;
  /// bgPrimaryHover — background color.
  final Color bgPrimaryHover;
  /// bgPrimaryAlt — background color.
  final Color bgPrimaryAlt;
  /// bgPrimarySolid — background color.
  final Color bgPrimarySolid;
  /// bgSecondary — background color.
  final Color bgSecondary;
  /// bgSecondaryHover — background color.
  final Color bgSecondaryHover;
  /// bgSecondaryAlt — background color.
  final Color bgSecondaryAlt;
  /// bgSecondarySolid — background color.
  final Color bgSecondarySolid;
  /// bgTertiary — background color.
  final Color bgTertiary;
  /// bgQuaternary — background color.
  final Color bgQuaternary;
  /// bgActive — background color.
  final Color bgActive;
  /// bgDisabled — background color.
  final Color bgDisabled;
  /// bgOverlay — background color.
  final Color bgOverlay;
  /// bgBrandPrimary — background color.
  final Color bgBrandPrimary;
  /// bgBrandPrimaryAlt — background color.
  final Color bgBrandPrimaryAlt;
  /// bgBrandSecondary — background color.
  final Color bgBrandSecondary;
  /// bgBrandSolid — background color.
  final Color bgBrandSolid;
  /// bgBrandSolidHover — background color.
  final Color bgBrandSolidHover;
  /// bgBrandSection — background color.
  final Color bgBrandSection;
  /// bgBrandSectionSubtle — background color.
  final Color bgBrandSectionSubtle;
  /// bgErrorPrimary — background color.
  final Color bgErrorPrimary;
  /// bgErrorSecondary — background color.
  final Color bgErrorSecondary;
  /// bgErrorSolid — background color.
  final Color bgErrorSolid;
  /// bgErrorSolidHover — background color.
  final Color bgErrorSolidHover;
  /// bgWarningPrimary — background color.
  final Color bgWarningPrimary;
  /// bgWarningSecondary — background color.
  final Color bgWarningSecondary;
  /// bgWarningSolid — background color.
  final Color bgWarningSolid;
  /// bgSuccessPrimary — background color.
  final Color bgSuccessPrimary;
  /// bgSuccessSecondary — background color.
  final Color bgSuccessSecondary;
  /// bgSuccessSolid — background color.
  final Color bgSuccessSolid;
  // Text.
  /// textPrimary — text color.
  final Color textPrimary;
  /// textSecondary — text color.
  final Color textSecondary;
  /// textSecondaryHover — text color.
  final Color textSecondaryHover;
  /// textTertiary — text color.
  final Color textTertiary;
  /// textTertiaryHover — text color.
  final Color textTertiaryHover;
  /// textQuaternary — text color.
  final Color textQuaternary;
  /// textQuaternaryOnBrand — text color.
  final Color textQuaternaryOnBrand;
  /// textPlaceholder — text color.
  final Color textPlaceholder;
  /// textDisabled — text color.
  final Color textDisabled;
  /// textWhite — text color.
  final Color textWhite;
  /// textBrandPrimary — text color.
  final Color textBrandPrimary;
  /// textBrandSecondary — text color.
  final Color textBrandSecondary;
  /// textBrandSecondaryHover — text color.
  final Color textBrandSecondaryHover;
  /// textBrandTertiary — text color.
  final Color textBrandTertiary;
  /// textBrandTertiaryAlt — text color.
  final Color textBrandTertiaryAlt;
  /// textPrimaryOnBrand — text color.
  final Color textPrimaryOnBrand;
  /// textSecondaryOnBrand — text color.
  final Color textSecondaryOnBrand;
  /// textTertiaryOnBrand — text color.
  final Color textTertiaryOnBrand;
  /// textErrorPrimary — text color.
  final Color textErrorPrimary;
  /// textErrorPrimaryHover — text color.
  final Color textErrorPrimaryHover;
  /// textWarningPrimary — text color.
  final Color textWarningPrimary;
  /// textSuccessPrimary — text color.
  final Color textSuccessPrimary;
  // Foreground.
  /// fgPrimary — foreground color.
  final Color fgPrimary;
  /// fgSecondary — foreground color.
  final Color fgSecondary;
  /// fgSecondaryHover — foreground color.
  final Color fgSecondaryHover;
  /// fgTertiary — foreground color.
  final Color fgTertiary;
  /// fgTertiaryHover — foreground color.
  final Color fgTertiaryHover;
  /// fgQuaternary — foreground color.
  final Color fgQuaternary;
  /// fgQuaternaryHover — foreground color.
  final Color fgQuaternaryHover;
  /// fgDisabled — foreground color.
  final Color fgDisabled;
  /// fgWhite — foreground color.
  final Color fgWhite;
  /// fgBrandPrimary — foreground color.
  final Color fgBrandPrimary;
  /// fgBrandPrimaryAlt — foreground color.
  final Color fgBrandPrimaryAlt;
  /// fgBrandSecondary — foreground color.
  final Color fgBrandSecondary;
  /// fgBrandSecondaryAlt — foreground color.
  final Color fgBrandSecondaryAlt;
  /// fgBrandSecondaryHover — foreground color.
  final Color fgBrandSecondaryHover;
  /// fgErrorPrimary — foreground color.
  final Color fgErrorPrimary;
  /// fgErrorSecondary — foreground color.
  final Color fgErrorSecondary;
  /// fgWarningPrimary — foreground color.
  final Color fgWarningPrimary;
  /// fgWarningSecondary — foreground color.
  final Color fgWarningSecondary;
  /// fgSuccessPrimary — foreground color.
  final Color fgSuccessPrimary;
  /// fgSuccessSecondary — foreground color.
  final Color fgSuccessSecondary;
  // Borders.
  /// borderPrimary — border color.
  final Color borderPrimary;
  /// borderSecondary — border color.
  final Color borderSecondary;
  /// borderSecondaryAlt — border color.
  final Color borderSecondaryAlt;
  /// borderTertiary — border color.
  final Color borderTertiary;
  /// borderDisabled — border color.
  final Color borderDisabled;
  /// borderBrand — border color.
  final Color borderBrand;
  /// borderBrandAlt — border color.
  final Color borderBrandAlt;
  /// borderBrandSolid — border color.
  final Color borderBrandSolid;
  /// borderBrandSolidHover — border color.
  final Color borderBrandSolidHover;
  /// borderError — border color.
  final Color borderError;
  /// borderErrorSubtle — border color.
  final Color borderErrorSubtle;
  // Focus rings.
  /// focusRing — focus ring color.
  final Color focusRing;
  /// focusRingError — focus ring color.
  final Color focusRingError;

  // ── Design-system aliases (near-white / ink-black / orange) ──
  /// canvas — the near-white page background.
  final Color canvas;
  /// surface — warm-neutral secondary fill (chips, secondary buttons).
  final Color surface;
  /// panel — pure-white data surface (cards, panels, popovers).
  final Color panel;
  /// sidebar — the app-shell rail surface.
  final Color sidebar;
  /// rail — the in-panel group-header rail.
  final Color rail;
  /// fg — ink black, primary text/chrome.
  final Color fg;
  /// muted — secondary text & metadata.
  final Color muted;
  /// idle — disabled / faint dots / tertiary meta (fg @ 38%).
  final Color idle;
  /// borderSoft — the softest hairline.
  final Color borderSoft;
  /// lineStrong — dividers & DAG edges that must show (fg @ 16%).
  final Color lineStrong;
  /// hover — row / nav hover wash (fg @ 5%).
  final Color hover;
  /// hoverStrong — count chips / pressed wash (fg @ 8%).
  final Color hoverStrong;
  /// accent — the single orange signal.
  final Color accent;
  /// accentOn — text/icon on accent.
  final Color accentOn;
  /// accentHover — accent hover warm-up (Flame).
  final Color accentHover;
  /// accentActive — accent pressed state.
  final Color accentActive;
  /// accentSoft — accent @ 12% (tinted backgrounds, active chips).
  final Color accentSoft;
  /// success — status success.
  final Color success;
  /// successSoft — success pill background.
  final Color successSoft;
  /// warn — status warning.
  final Color warn;
  /// warnSoft — warning pill background.
  final Color warnSoft;
  /// danger — status danger / error.
  final Color danger;
  /// dangerSoft — danger pill background.
  final Color dangerSoft;
  /// sunshine900 — golden-hour brand graphics only.
  final Color sunshine900;
  /// sunshine700 — golden-hour brand graphics only.
  final Color sunshine700;
  /// sunshine500 — golden-hour brand graphics only.
  final Color sunshine500;
  /// sunshine300 — golden-hour brand graphics only.
  final Color sunshine300;
  /// brightYellow — top note of the brand mosaic.
  final Color brightYellow;
  /// blockEdge — burnt-orange terminus of the brand mosaic.
  final Color blockEdge;

  /// Of.
  static DesignSystemTokens? of(BuildContext context) =>
      Theme.of(context).extension<DesignSystemTokens>();

  @override
  DesignSystemTokens copyWith({
    Color? bgPrimary,
    Color? bgPrimaryHover,
    Color? bgPrimaryAlt,
    Color? bgPrimarySolid,
    Color? bgSecondary,
    Color? bgSecondaryHover,
    Color? bgSecondaryAlt,
    Color? bgSecondarySolid,
    Color? bgTertiary,
    Color? bgQuaternary,
    Color? bgActive,
    Color? bgDisabled,
    Color? bgOverlay,
    Color? bgBrandPrimary,
    Color? bgBrandPrimaryAlt,
    Color? bgBrandSecondary,
    Color? bgBrandSolid,
    Color? bgBrandSolidHover,
    Color? bgBrandSection,
    Color? bgBrandSectionSubtle,
    Color? bgErrorPrimary,
    Color? bgErrorSecondary,
    Color? bgErrorSolid,
    Color? bgErrorSolidHover,
    Color? bgWarningPrimary,
    Color? bgWarningSecondary,
    Color? bgWarningSolid,
    Color? bgSuccessPrimary,
    Color? bgSuccessSecondary,
    Color? bgSuccessSolid,
    Color? textPrimary,
    Color? textSecondary,
    Color? textSecondaryHover,
    Color? textTertiary,
    Color? textTertiaryHover,
    Color? textQuaternary,
    Color? textQuaternaryOnBrand,
    Color? textPlaceholder,
    Color? textDisabled,
    Color? textWhite,
    Color? textBrandPrimary,
    Color? textBrandSecondary,
    Color? textBrandSecondaryHover,
    Color? textBrandTertiary,
    Color? textBrandTertiaryAlt,
    Color? textPrimaryOnBrand,
    Color? textSecondaryOnBrand,
    Color? textTertiaryOnBrand,
    Color? textErrorPrimary,
    Color? textErrorPrimaryHover,
    Color? textWarningPrimary,
    Color? textSuccessPrimary,
    Color? fgPrimary,
    Color? fgSecondary,
    Color? fgSecondaryHover,
    Color? fgTertiary,
    Color? fgTertiaryHover,
    Color? fgQuaternary,
    Color? fgQuaternaryHover,
    Color? fgDisabled,
    Color? fgWhite,
    Color? fgBrandPrimary,
    Color? fgBrandPrimaryAlt,
    Color? fgBrandSecondary,
    Color? fgBrandSecondaryAlt,
    Color? fgBrandSecondaryHover,
    Color? fgErrorPrimary,
    Color? fgErrorSecondary,
    Color? fgWarningPrimary,
    Color? fgWarningSecondary,
    Color? fgSuccessPrimary,
    Color? fgSuccessSecondary,
    Color? borderPrimary,
    Color? borderSecondary,
    Color? borderSecondaryAlt,
    Color? borderTertiary,
    Color? borderDisabled,
    Color? borderBrand,
    Color? borderBrandAlt,
    Color? borderBrandSolid,
    Color? borderBrandSolidHover,
    Color? borderError,
    Color? borderErrorSubtle,
    Color? focusRing,
    Color? focusRingError,
    Color? canvas,
    Color? surface,
    Color? panel,
    Color? sidebar,
    Color? rail,
    Color? fg,
    Color? muted,
    Color? idle,
    Color? borderSoft,
    Color? lineStrong,
    Color? hover,
    Color? hoverStrong,
    Color? accent,
    Color? accentOn,
    Color? accentHover,
    Color? accentActive,
    Color? accentSoft,
    Color? success,
    Color? successSoft,
    Color? warn,
    Color? warnSoft,
    Color? danger,
    Color? dangerSoft,
    Color? sunshine900,
    Color? sunshine700,
    Color? sunshine500,
    Color? sunshine300,
    Color? brightYellow,
    Color? blockEdge,
  }) {
    return DesignSystemTokens(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgPrimaryHover: bgPrimaryHover ?? this.bgPrimaryHover,
      bgPrimaryAlt: bgPrimaryAlt ?? this.bgPrimaryAlt,
      bgPrimarySolid: bgPrimarySolid ?? this.bgPrimarySolid,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgSecondaryHover: bgSecondaryHover ?? this.bgSecondaryHover,
      bgSecondaryAlt: bgSecondaryAlt ?? this.bgSecondaryAlt,
      bgSecondarySolid: bgSecondarySolid ?? this.bgSecondarySolid,
      bgTertiary: bgTertiary ?? this.bgTertiary,
      bgQuaternary: bgQuaternary ?? this.bgQuaternary,
      bgActive: bgActive ?? this.bgActive,
      bgDisabled: bgDisabled ?? this.bgDisabled,
      bgOverlay: bgOverlay ?? this.bgOverlay,
      bgBrandPrimary: bgBrandPrimary ?? this.bgBrandPrimary,
      bgBrandPrimaryAlt: bgBrandPrimaryAlt ?? this.bgBrandPrimaryAlt,
      bgBrandSecondary: bgBrandSecondary ?? this.bgBrandSecondary,
      bgBrandSolid: bgBrandSolid ?? this.bgBrandSolid,
      bgBrandSolidHover: bgBrandSolidHover ?? this.bgBrandSolidHover,
      bgBrandSection: bgBrandSection ?? this.bgBrandSection,
      bgBrandSectionSubtle: bgBrandSectionSubtle ?? this.bgBrandSectionSubtle,
      bgErrorPrimary: bgErrorPrimary ?? this.bgErrorPrimary,
      bgErrorSecondary: bgErrorSecondary ?? this.bgErrorSecondary,
      bgErrorSolid: bgErrorSolid ?? this.bgErrorSolid,
      bgErrorSolidHover: bgErrorSolidHover ?? this.bgErrorSolidHover,
      bgWarningPrimary: bgWarningPrimary ?? this.bgWarningPrimary,
      bgWarningSecondary: bgWarningSecondary ?? this.bgWarningSecondary,
      bgWarningSolid: bgWarningSolid ?? this.bgWarningSolid,
      bgSuccessPrimary: bgSuccessPrimary ?? this.bgSuccessPrimary,
      bgSuccessSecondary: bgSuccessSecondary ?? this.bgSuccessSecondary,
      bgSuccessSolid: bgSuccessSolid ?? this.bgSuccessSolid,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textSecondaryHover: textSecondaryHover ?? this.textSecondaryHover,
      textTertiary: textTertiary ?? this.textTertiary,
      textTertiaryHover: textTertiaryHover ?? this.textTertiaryHover,
      textQuaternary: textQuaternary ?? this.textQuaternary,
      textQuaternaryOnBrand:
          textQuaternaryOnBrand ?? this.textQuaternaryOnBrand,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
      textDisabled: textDisabled ?? this.textDisabled,
      textWhite: textWhite ?? this.textWhite,
      textBrandPrimary: textBrandPrimary ?? this.textBrandPrimary,
      textBrandSecondary: textBrandSecondary ?? this.textBrandSecondary,
      textBrandSecondaryHover:
          textBrandSecondaryHover ?? this.textBrandSecondaryHover,
      textBrandTertiary: textBrandTertiary ?? this.textBrandTertiary,
      textBrandTertiaryAlt: textBrandTertiaryAlt ?? this.textBrandTertiaryAlt,
      textPrimaryOnBrand: textPrimaryOnBrand ?? this.textPrimaryOnBrand,
      textSecondaryOnBrand: textSecondaryOnBrand ?? this.textSecondaryOnBrand,
      textTertiaryOnBrand: textTertiaryOnBrand ?? this.textTertiaryOnBrand,
      textErrorPrimary: textErrorPrimary ?? this.textErrorPrimary,
      textErrorPrimaryHover:
          textErrorPrimaryHover ?? this.textErrorPrimaryHover,
      textWarningPrimary: textWarningPrimary ?? this.textWarningPrimary,
      textSuccessPrimary: textSuccessPrimary ?? this.textSuccessPrimary,
      fgPrimary: fgPrimary ?? this.fgPrimary,
      fgSecondary: fgSecondary ?? this.fgSecondary,
      fgSecondaryHover: fgSecondaryHover ?? this.fgSecondaryHover,
      fgTertiary: fgTertiary ?? this.fgTertiary,
      fgTertiaryHover: fgTertiaryHover ?? this.fgTertiaryHover,
      fgQuaternary: fgQuaternary ?? this.fgQuaternary,
      fgQuaternaryHover: fgQuaternaryHover ?? this.fgQuaternaryHover,
      fgDisabled: fgDisabled ?? this.fgDisabled,
      fgWhite: fgWhite ?? this.fgWhite,
      fgBrandPrimary: fgBrandPrimary ?? this.fgBrandPrimary,
      fgBrandPrimaryAlt: fgBrandPrimaryAlt ?? this.fgBrandPrimaryAlt,
      fgBrandSecondary: fgBrandSecondary ?? this.fgBrandSecondary,
      fgBrandSecondaryAlt: fgBrandSecondaryAlt ?? this.fgBrandSecondaryAlt,
      fgBrandSecondaryHover:
          fgBrandSecondaryHover ?? this.fgBrandSecondaryHover,
      fgErrorPrimary: fgErrorPrimary ?? this.fgErrorPrimary,
      fgErrorSecondary: fgErrorSecondary ?? this.fgErrorSecondary,
      fgWarningPrimary: fgWarningPrimary ?? this.fgWarningPrimary,
      fgWarningSecondary: fgWarningSecondary ?? this.fgWarningSecondary,
      fgSuccessPrimary: fgSuccessPrimary ?? this.fgSuccessPrimary,
      fgSuccessSecondary: fgSuccessSecondary ?? this.fgSuccessSecondary,
      borderPrimary: borderPrimary ?? this.borderPrimary,
      borderSecondary: borderSecondary ?? this.borderSecondary,
      borderSecondaryAlt: borderSecondaryAlt ?? this.borderSecondaryAlt,
      borderTertiary: borderTertiary ?? this.borderTertiary,
      borderDisabled: borderDisabled ?? this.borderDisabled,
      borderBrand: borderBrand ?? this.borderBrand,
      borderBrandAlt: borderBrandAlt ?? this.borderBrandAlt,
      borderBrandSolid: borderBrandSolid ?? this.borderBrandSolid,
      borderBrandSolidHover:
          borderBrandSolidHover ?? this.borderBrandSolidHover,
      borderError: borderError ?? this.borderError,
      borderErrorSubtle: borderErrorSubtle ?? this.borderErrorSubtle,
      focusRing: focusRing ?? this.focusRing,
      focusRingError: focusRingError ?? this.focusRingError,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      panel: panel ?? this.panel,
      sidebar: sidebar ?? this.sidebar,
      rail: rail ?? this.rail,
      fg: fg ?? this.fg,
      muted: muted ?? this.muted,
      idle: idle ?? this.idle,
      borderSoft: borderSoft ?? this.borderSoft,
      lineStrong: lineStrong ?? this.lineStrong,
      hover: hover ?? this.hover,
      hoverStrong: hoverStrong ?? this.hoverStrong,
      accent: accent ?? this.accent,
      accentOn: accentOn ?? this.accentOn,
      accentHover: accentHover ?? this.accentHover,
      accentActive: accentActive ?? this.accentActive,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warn: warn ?? this.warn,
      warnSoft: warnSoft ?? this.warnSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      sunshine900: sunshine900 ?? this.sunshine900,
      sunshine700: sunshine700 ?? this.sunshine700,
      sunshine500: sunshine500 ?? this.sunshine500,
      sunshine300: sunshine300 ?? this.sunshine300,
      brightYellow: brightYellow ?? this.brightYellow,
      blockEdge: blockEdge ?? this.blockEdge,
    );
  }

  @override
  DesignSystemTokens lerp(ThemeExtension<DesignSystemTokens>? other, double t) {
    if (other is! DesignSystemTokens) {
      return this;
    }
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DesignSystemTokens(
      bgPrimary: l(bgPrimary, other.bgPrimary),
      bgPrimaryHover: l(bgPrimaryHover, other.bgPrimaryHover),
      bgPrimaryAlt: l(bgPrimaryAlt, other.bgPrimaryAlt),
      bgPrimarySolid: l(bgPrimarySolid, other.bgPrimarySolid),
      bgSecondary: l(bgSecondary, other.bgSecondary),
      bgSecondaryHover: l(bgSecondaryHover, other.bgSecondaryHover),
      bgSecondaryAlt: l(bgSecondaryAlt, other.bgSecondaryAlt),
      bgSecondarySolid: l(bgSecondarySolid, other.bgSecondarySolid),
      bgTertiary: l(bgTertiary, other.bgTertiary),
      bgQuaternary: l(bgQuaternary, other.bgQuaternary),
      bgActive: l(bgActive, other.bgActive),
      bgDisabled: l(bgDisabled, other.bgDisabled),
      bgOverlay: l(bgOverlay, other.bgOverlay),
      bgBrandPrimary: l(bgBrandPrimary, other.bgBrandPrimary),
      bgBrandPrimaryAlt: l(bgBrandPrimaryAlt, other.bgBrandPrimaryAlt),
      bgBrandSecondary: l(bgBrandSecondary, other.bgBrandSecondary),
      bgBrandSolid: l(bgBrandSolid, other.bgBrandSolid),
      bgBrandSolidHover: l(bgBrandSolidHover, other.bgBrandSolidHover),
      bgBrandSection: l(bgBrandSection, other.bgBrandSection),
      bgBrandSectionSubtle: l(bgBrandSectionSubtle, other.bgBrandSectionSubtle),
      bgErrorPrimary: l(bgErrorPrimary, other.bgErrorPrimary),
      bgErrorSecondary: l(bgErrorSecondary, other.bgErrorSecondary),
      bgErrorSolid: l(bgErrorSolid, other.bgErrorSolid),
      bgErrorSolidHover: l(bgErrorSolidHover, other.bgErrorSolidHover),
      bgWarningPrimary: l(bgWarningPrimary, other.bgWarningPrimary),
      bgWarningSecondary: l(bgWarningSecondary, other.bgWarningSecondary),
      bgWarningSolid: l(bgWarningSolid, other.bgWarningSolid),
      bgSuccessPrimary: l(bgSuccessPrimary, other.bgSuccessPrimary),
      bgSuccessSecondary: l(bgSuccessSecondary, other.bgSuccessSecondary),
      bgSuccessSolid: l(bgSuccessSolid, other.bgSuccessSolid),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textSecondaryHover: l(textSecondaryHover, other.textSecondaryHover),
      textTertiary: l(textTertiary, other.textTertiary),
      textTertiaryHover: l(textTertiaryHover, other.textTertiaryHover),
      textQuaternary: l(textQuaternary, other.textQuaternary),
      textQuaternaryOnBrand:
          l(textQuaternaryOnBrand, other.textQuaternaryOnBrand),
      textPlaceholder: l(textPlaceholder, other.textPlaceholder),
      textDisabled: l(textDisabled, other.textDisabled),
      textWhite: l(textWhite, other.textWhite),
      textBrandPrimary: l(textBrandPrimary, other.textBrandPrimary),
      textBrandSecondary: l(textBrandSecondary, other.textBrandSecondary),
      textBrandSecondaryHover:
          l(textBrandSecondaryHover, other.textBrandSecondaryHover),
      textBrandTertiary: l(textBrandTertiary, other.textBrandTertiary),
      textBrandTertiaryAlt: l(textBrandTertiaryAlt, other.textBrandTertiaryAlt),
      textPrimaryOnBrand: l(textPrimaryOnBrand, other.textPrimaryOnBrand),
      textSecondaryOnBrand: l(textSecondaryOnBrand, other.textSecondaryOnBrand),
      textTertiaryOnBrand: l(textTertiaryOnBrand, other.textTertiaryOnBrand),
      textErrorPrimary: l(textErrorPrimary, other.textErrorPrimary),
      textErrorPrimaryHover:
          l(textErrorPrimaryHover, other.textErrorPrimaryHover),
      textWarningPrimary: l(textWarningPrimary, other.textWarningPrimary),
      textSuccessPrimary: l(textSuccessPrimary, other.textSuccessPrimary),
      fgPrimary: l(fgPrimary, other.fgPrimary),
      fgSecondary: l(fgSecondary, other.fgSecondary),
      fgSecondaryHover: l(fgSecondaryHover, other.fgSecondaryHover),
      fgTertiary: l(fgTertiary, other.fgTertiary),
      fgTertiaryHover: l(fgTertiaryHover, other.fgTertiaryHover),
      fgQuaternary: l(fgQuaternary, other.fgQuaternary),
      fgQuaternaryHover: l(fgQuaternaryHover, other.fgQuaternaryHover),
      fgDisabled: l(fgDisabled, other.fgDisabled),
      fgWhite: l(fgWhite, other.fgWhite),
      fgBrandPrimary: l(fgBrandPrimary, other.fgBrandPrimary),
      fgBrandPrimaryAlt: l(fgBrandPrimaryAlt, other.fgBrandPrimaryAlt),
      fgBrandSecondary: l(fgBrandSecondary, other.fgBrandSecondary),
      fgBrandSecondaryAlt: l(fgBrandSecondaryAlt, other.fgBrandSecondaryAlt),
      fgBrandSecondaryHover:
          l(fgBrandSecondaryHover, other.fgBrandSecondaryHover),
      fgErrorPrimary: l(fgErrorPrimary, other.fgErrorPrimary),
      fgErrorSecondary: l(fgErrorSecondary, other.fgErrorSecondary),
      fgWarningPrimary: l(fgWarningPrimary, other.fgWarningPrimary),
      fgWarningSecondary: l(fgWarningSecondary, other.fgWarningSecondary),
      fgSuccessPrimary: l(fgSuccessPrimary, other.fgSuccessPrimary),
      fgSuccessSecondary: l(fgSuccessSecondary, other.fgSuccessSecondary),
      borderPrimary: l(borderPrimary, other.borderPrimary),
      borderSecondary: l(borderSecondary, other.borderSecondary),
      borderSecondaryAlt: l(borderSecondaryAlt, other.borderSecondaryAlt),
      borderTertiary: l(borderTertiary, other.borderTertiary),
      borderDisabled: l(borderDisabled, other.borderDisabled),
      borderBrand: l(borderBrand, other.borderBrand),
      borderBrandAlt: l(borderBrandAlt, other.borderBrandAlt),
      borderBrandSolid: l(borderBrandSolid, other.borderBrandSolid),
      borderBrandSolidHover:
          l(borderBrandSolidHover, other.borderBrandSolidHover),
      borderError: l(borderError, other.borderError),
      borderErrorSubtle: l(borderErrorSubtle, other.borderErrorSubtle),
      focusRing: l(focusRing, other.focusRing),
      focusRingError: l(focusRingError, other.focusRingError),
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      panel: l(panel, other.panel),
      sidebar: l(sidebar, other.sidebar),
      rail: l(rail, other.rail),
      fg: l(fg, other.fg),
      muted: l(muted, other.muted),
      idle: l(idle, other.idle),
      borderSoft: l(borderSoft, other.borderSoft),
      lineStrong: l(lineStrong, other.lineStrong),
      hover: l(hover, other.hover),
      hoverStrong: l(hoverStrong, other.hoverStrong),
      accent: l(accent, other.accent),
      accentOn: l(accentOn, other.accentOn),
      accentHover: l(accentHover, other.accentHover),
      accentActive: l(accentActive, other.accentActive),
      accentSoft: l(accentSoft, other.accentSoft),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warn: l(warn, other.warn),
      warnSoft: l(warnSoft, other.warnSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      sunshine900: l(sunshine900, other.sunshine900),
      sunshine700: l(sunshine700, other.sunshine700),
      sunshine500: l(sunshine500, other.sunshine500),
      sunshine300: l(sunshine300, other.sunshine300),
      brightYellow: l(brightYellow, other.brightYellow),
      blockEdge: l(blockEdge, other.blockEdge),
    );
  }
}

/// BuildContext extension for accessing [DesignSystemTokens].
extension DesignSystemTokensBuildContext on BuildContext {
  /// Shorthand for `DesignSystemTokens.of(this)` — null when the extension
  /// hasn't been registered on the active [Theme].
  DesignSystemTokens? get designSystem =>
      Theme.of(this).extension<DesignSystemTokens>();
}
