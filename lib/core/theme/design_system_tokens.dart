// Re-export shim. Semantic tokens and the `CcTheme` token-delivery
// `InheritedWidget` now live in the `cc_ui` package (`DesignSystemTokens` was
// converted off Material's `ThemeExtension`). `context.designSystem` resolves
// from the nearest `CcTheme` ancestor. New code should import
// `package:cc_ui/cc_ui.dart` directly.
export 'package:cc_ui/cc_ui.dart'
    show
        CcBrightness,
        CcTheme,
        CcThemeData,
        DesignSystemTokens,
        DesignSystemTokensBuildContext;
