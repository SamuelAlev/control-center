import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// Light or dark appearance for the design system.
///
/// A purist replacement for Material's `Brightness` so cc_ui never imports
/// `package:flutter/material.dart`.
enum CcBrightness {
  /// Light appearance.
  light,

  /// Dark appearance.
  dark,
}

/// Immutable configuration carried by a [CcTheme].
///
/// Holds the semantic [DesignSystemTokens] plus ambient presentation state
/// (brightness, reduced-motion, the resolved font families). This is the
/// purist replacement for delivering [DesignSystemTokens] as a Material
/// `ThemeExtension`: the tokens travel through an [InheritedWidget] instead of
/// `ThemeData`, so no part of cc_ui depends on Material.
@immutable
class CcThemeData {
  /// Creates a [CcThemeData].
  const CcThemeData({
    required this.tokens,
    required this.brightness,
    this.reducedMotion = false,
    this.fontFamily,
    this.monoFontFamily,
  });

  /// Light defaults.
  factory CcThemeData.light({
    String? fontFamily,
    String? monoFontFamily,
    bool reducedMotion = false,
  }) =>
      CcThemeData(
        tokens: DesignSystemTokens.light(),
        brightness: CcBrightness.light,
        reducedMotion: reducedMotion,
        fontFamily: fontFamily,
        monoFontFamily: monoFontFamily,
      );

  /// Dark defaults.
  factory CcThemeData.dark({
    String? fontFamily,
    String? monoFontFamily,
    bool reducedMotion = false,
  }) =>
      CcThemeData(
        tokens: DesignSystemTokens.dark(),
        brightness: CcBrightness.dark,
        reducedMotion: reducedMotion,
        fontFamily: fontFamily,
        monoFontFamily: monoFontFamily,
      );

  /// The active semantic color tokens.
  final DesignSystemTokens tokens;

  /// Whether the appearance is light or dark.
  final CcBrightness brightness;

  /// Whether animations should be suppressed (mirrors
  /// `MediaQuery.disableAnimationsOf`). Components collapse durations to zero
  /// when this is set.
  final bool reducedMotion;

  /// The resolved UI font family (e.g. `Manrope`), or null for the
  /// platform default.
  final String? fontFamily;

  /// The resolved monospace font family (e.g. `Fira Code`), or null.
  final String? monoFontFamily;

  /// Whether this is the dark appearance.
  bool get isDark => brightness == CcBrightness.dark;

  /// Returns a copy with the given fields replaced.
  CcThemeData copyWith({
    DesignSystemTokens? tokens,
    CcBrightness? brightness,
    bool? reducedMotion,
    String? fontFamily,
    String? monoFontFamily,
  }) =>
      CcThemeData(
        tokens: tokens ?? this.tokens,
        brightness: brightness ?? this.brightness,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        fontFamily: fontFamily ?? this.fontFamily,
        monoFontFamily: monoFontFamily ?? this.monoFontFamily,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcThemeData &&
          other.tokens == tokens &&
          other.brightness == brightness &&
          other.reducedMotion == reducedMotion &&
          other.fontFamily == fontFamily &&
          other.monoFontFamily == monoFontFamily;

  @override
  int get hashCode => Object.hash(
        tokens,
        brightness,
        reducedMotion,
        fontFamily,
        monoFontFamily,
      );
}

/// Provides [CcThemeData] (design tokens + ambient presentation state) to the
/// widget subtree via an [InheritedWidget].
///
/// This is the single source of truth for design tokens in the purist build —
/// it replaces attaching [DesignSystemTokens] as a Material `ThemeExtension`.
/// Read tokens with `context.designSystem` and the full config with
/// `context.ccTheme`.
class CcTheme extends InheritedWidget {
  /// Creates a [CcTheme] that exposes [data] to [child] and its descendants.
  const CcTheme({
    required this.data,
    required super.child,
    super.key,
  });

  /// The active design-system configuration.
  final CcThemeData data;

  /// The nearest [CcThemeData], or null if there is no [CcTheme] ancestor.
  static CcThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CcTheme>()?.data;

  /// The nearest [CcThemeData]. Asserts that a [CcTheme] ancestor exists.
  static CcThemeData of(BuildContext context) {
    final data = maybeOf(context);
    assert(data != null, 'No CcTheme found in context.');
    return data!;
  }

  @override
  bool updateShouldNotify(CcTheme oldWidget) => data != oldWidget.data;
}

/// Convenience accessors for the active [CcTheme] on [BuildContext].
extension DesignSystemTokensBuildContext on BuildContext {
  /// The active semantic [DesignSystemTokens], or null when there is no
  /// [CcTheme] ancestor. Call sites typically fall back with
  /// `context.designSystem ?? DesignSystemTokens.light()`.
  DesignSystemTokens? get designSystem => CcTheme.maybeOf(this)?.tokens;

  /// The active [CcThemeData], or null when there is no [CcTheme] ancestor.
  CcThemeData? get ccTheme => CcTheme.maybeOf(this);
}
