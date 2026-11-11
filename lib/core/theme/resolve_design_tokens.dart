import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Resolves [DesignSystemTokens] from [context], falling back to the light or
/// dark defaults when there is no `CcTheme` ancestor.
///
/// Lives in `core/` rather than a feature so `lib/shared/` widgets can use it
/// without importing the features layer (a boundary a ratchet test enforces).
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
