// Re-export shim. The design-system palette now lives in the `cc_ui` package.
// This keeps the historical import path working during the cc_ui migration;
// new code should import `package:cc_ui/cc_ui.dart` directly.
export 'package:cc_ui/cc_ui.dart' show DesignSystemPalette;
