// The app's one deliberate import of the deprecated framework Material
// library. Third-party widgets we mount (chewie, kalender, fl_chart, xterm,
// shiki_flutter, sentry_flutter) still build on `package:flutter/material.dart`,
// whose `Theme` and `MaterialLocalizations` are different classes from
// material_ui's. This bridge re-provides both for them; delete it once those
// packages move to material_ui.
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter_localizations/flutter_localizations.dart' as legacy;
import 'package:material_ui/material_ui.dart';

/// Re-provides the ambient material_ui [Theme] and localizations to
/// descendants built on the deprecated `package:flutter/material.dart`.
///
/// Mounted once under each `MaterialApp` that can host third-party Material
/// widgets. Unlike material_ui's `MaterialUiCompatibilityBridge`, which carries
/// only the color scheme and text theme, this maps every facet `AppTheme` sets
/// for those widgets: font, surfaces, no-splash ink, selection colors, and the
/// divider, chip, button and input component themes.
class LegacyMaterialBridge extends StatelessWidget {
  /// Bridges the theme and localizations above this widget into [child].
  const LegacyMaterialBridge({super.key, required this.child});

  /// The subtree that may contain legacy Material widgets.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return legacy.Theme(
      data: legacyThemeOf(Theme.of(context)),
      child: Localizations.override(
        context: context,
        delegates: const [
          legacy.GlobalMaterialLocalizations.delegate,
          legacy.GlobalCupertinoLocalizations.delegate,
        ],
        child: child,
      ),
    );
  }
}

/// Converts a material_ui [ThemeData] into the legacy framework type.
///
/// Painting, gesture and widget-state values are shared between the two
/// libraries and copy across as-is; Material-specific classes are rebuilt.
@visibleForTesting
legacy.ThemeData legacyThemeOf(ThemeData theme) {
  final scheme = theme.colorScheme;
  return legacy.ThemeData(
    useMaterial3: theme.useMaterial3,
    brightness: theme.brightness,
    platform: theme.platform,
    visualDensity: legacy.VisualDensity(
      horizontal: theme.visualDensity.horizontal,
      vertical: theme.visualDensity.vertical,
    ),
    fontFamily: theme.textTheme.bodyMedium?.fontFamily,
    colorScheme: legacy.ColorScheme(
      brightness: scheme.brightness,
      primary: scheme.primary,
      onPrimary: scheme.onPrimary,
      primaryContainer: scheme.primaryContainer,
      onPrimaryContainer: scheme.onPrimaryContainer,
      secondary: scheme.secondary,
      onSecondary: scheme.onSecondary,
      secondaryContainer: scheme.secondaryContainer,
      onSecondaryContainer: scheme.onSecondaryContainer,
      tertiary: scheme.tertiary,
      onTertiary: scheme.onTertiary,
      tertiaryContainer: scheme.tertiaryContainer,
      onTertiaryContainer: scheme.onTertiaryContainer,
      error: scheme.error,
      onError: scheme.onError,
      errorContainer: scheme.errorContainer,
      onErrorContainer: scheme.onErrorContainer,
      surface: scheme.surface,
      onSurface: scheme.onSurface,
      surfaceDim: scheme.surfaceDim,
      surfaceBright: scheme.surfaceBright,
      surfaceContainerLowest: scheme.surfaceContainerLowest,
      surfaceContainerLow: scheme.surfaceContainerLow,
      surfaceContainer: scheme.surfaceContainer,
      surfaceContainerHigh: scheme.surfaceContainerHigh,
      surfaceContainerHighest: scheme.surfaceContainerHighest,
      onSurfaceVariant: scheme.onSurfaceVariant,
      outline: scheme.outline,
      outlineVariant: scheme.outlineVariant,
      shadow: scheme.shadow,
      scrim: scheme.scrim,
      inverseSurface: scheme.inverseSurface,
      onInverseSurface: scheme.onInverseSurface,
      inversePrimary: scheme.inversePrimary,
      surfaceTint: scheme.surfaceTint,
    ),
    canvasColor: theme.canvasColor,
    scaffoldBackgroundColor: theme.scaffoldBackgroundColor,
    splashFactory: identical(theme.splashFactory, NoSplash.splashFactory)
        ? legacy.NoSplash.splashFactory
        : null,
    textSelectionTheme: legacy.TextSelectionThemeData(
      cursorColor: theme.textSelectionTheme.cursorColor,
      selectionColor: theme.textSelectionTheme.selectionColor,
      selectionHandleColor: theme.textSelectionTheme.selectionHandleColor,
    ),
    textTheme: _legacyTextTheme(theme.textTheme),
    primaryTextTheme: _legacyTextTheme(theme.primaryTextTheme),
    dividerTheme: legacy.DividerThemeData(
      color: theme.dividerTheme.color,
      space: theme.dividerTheme.space,
      thickness: theme.dividerTheme.thickness,
      indent: theme.dividerTheme.indent,
      endIndent: theme.dividerTheme.endIndent,
    ),
    chipTheme: legacy.ChipThemeData(
      backgroundColor: theme.chipTheme.backgroundColor,
      selectedColor: theme.chipTheme.selectedColor,
      secondarySelectedColor: theme.chipTheme.secondarySelectedColor,
      disabledColor: theme.chipTheme.disabledColor,
      side: theme.chipTheme.side,
      shape: theme.chipTheme.shape,
      labelStyle: theme.chipTheme.labelStyle,
      secondaryLabelStyle: theme.chipTheme.secondaryLabelStyle,
      deleteIconColor: theme.chipTheme.deleteIconColor,
      checkmarkColor: theme.chipTheme.checkmarkColor,
    ),
    elevatedButtonTheme: legacy.ElevatedButtonThemeData(
      style: _legacyButtonStyle(theme.elevatedButtonTheme.style),
    ),
    outlinedButtonTheme: legacy.OutlinedButtonThemeData(
      style: _legacyButtonStyle(theme.outlinedButtonTheme.style),
    ),
    textButtonTheme: legacy.TextButtonThemeData(
      style: _legacyButtonStyle(theme.textButtonTheme.style),
    ),
    iconButtonTheme: legacy.IconButtonThemeData(
      style: _legacyButtonStyle(theme.iconButtonTheme.style),
    ),
    inputDecorationTheme: legacy.InputDecorationThemeData(
      focusedBorder: _legacyInputBorder(
        theme.inputDecorationTheme.focusedBorder,
      ),
    ),
  );
}

legacy.TextTheme _legacyTextTheme(TextTheme t) => legacy.TextTheme(
  displayLarge: t.displayLarge,
  displayMedium: t.displayMedium,
  displaySmall: t.displaySmall,
  headlineLarge: t.headlineLarge,
  headlineMedium: t.headlineMedium,
  headlineSmall: t.headlineSmall,
  titleLarge: t.titleLarge,
  titleMedium: t.titleMedium,
  titleSmall: t.titleSmall,
  bodyLarge: t.bodyLarge,
  bodyMedium: t.bodyMedium,
  bodySmall: t.bodySmall,
  labelLarge: t.labelLarge,
  labelMedium: t.labelMedium,
  labelSmall: t.labelSmall,
);

/// Copies the state-driven properties, all of which are shared types.
legacy.ButtonStyle? _legacyButtonStyle(ButtonStyle? s) => s == null
    ? null
    : legacy.ButtonStyle(
        textStyle: s.textStyle,
        backgroundColor: s.backgroundColor,
        foregroundColor: s.foregroundColor,
        overlayColor: s.overlayColor,
        shadowColor: s.shadowColor,
        surfaceTintColor: s.surfaceTintColor,
        elevation: s.elevation,
        padding: s.padding,
        minimumSize: s.minimumSize,
        fixedSize: s.fixedSize,
        maximumSize: s.maximumSize,
        iconColor: s.iconColor,
        iconSize: s.iconSize,
        side: s.side,
        shape: s.shape,
        mouseCursor: s.mouseCursor,
        animationDuration: s.animationDuration,
        enableFeedback: s.enableFeedback,
        alignment: s.alignment,
      );

legacy.InputBorder? _legacyInputBorder(InputBorder? border) => switch (border) {
  OutlineInputBorder(
    :final borderSide,
    :final borderRadius,
    :final gapPadding,
  ) =>
    legacy.OutlineInputBorder(
      borderSide: borderSide,
      borderRadius: borderRadius,
      gapPadding: gapPadding,
    ),
  UnderlineInputBorder(:final borderSide, :final borderRadius) =>
    legacy.UnderlineInputBorder(
      borderSide: borderSide,
      borderRadius: borderRadius,
    ),
  _ => null,
};
