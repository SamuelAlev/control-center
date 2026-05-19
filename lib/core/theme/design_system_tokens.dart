// Re-export shim. Semantic tokens and the `CcTheme` token-delivery
// `InheritedWidget` now live in the `cc_ui` package (`DesignSystemTokens` was
// converted off Material's `ThemeExtension`). `context.designSystem` resolves
// from the nearest `CcTheme` ancestor. New code should import
// `package:cc_ui/cc_ui.dart` directly.
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

export 'package:cc_ui/cc_ui.dart'
    show
        CcBrightness,
        CcTheme,
        CcThemeData,
        DesignSystemTokens,
        DesignSystemTokensBuildContext;

/// Resolves [DesignSystemTokens] from [context], falling back to the light or
/// dark defaults when there is no `CcTheme` ancestor.
///
/// Lives here rather than in a feature so `lib/shared/` widgets can use it
/// without importing the features layer (a boundary a ratchet test enforces).
/// `channel_bubble_shared.dart` keeps its own identical helper for the
/// messaging feature's existing call sites.
DesignSystemTokens resolveDesignTokens(BuildContext context) {
  final tokens = context.designSystem;
  if (tokens != null) {
    return tokens;
  }
  // No CcTheme ancestor (a bare widget test, or a surface built outside the
  // shell): fall back on the platform brightness rather than Material's
  // ThemeData, so this stays usable from widgets-only components.
  final platformBrightness =
      MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light;
  return platformBrightness == Brightness.dark
      ? DesignSystemTokens.dark()
      : DesignSystemTokens.light();
}
