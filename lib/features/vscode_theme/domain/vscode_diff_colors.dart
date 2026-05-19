import 'package:control_center/core/theme/diff_colors.dart';
import 'package:control_center/features/vscode_theme/domain/vscode_editor_theme.dart';

/// Diff colors distilled from an imported VS Code [theme], so the embedded
/// diff matches the user's IDE.
///
/// Thin typed adapter over [DiffColors.fromEditorTheme]: VS Code themes only
/// carry line-level diff backgrounds, so the word emphasis and gutter fall
/// back to the shared accent hues plus the theme's line-number color. Keeping
/// the mapping here (next to the theme type) is what lets `core/theme/` stay
/// free of feature imports.
DiffColors diffColorsFromVsCode(VsCodeEditorTheme theme) =>
    DiffColors.fromEditorTheme(
      brightness: theme.brightness,
      addedBackground: theme.addedBackground,
      removedBackground: theme.removedBackground,
      lineNumberColor: theme.lineNumber,
      foreground: theme.foreground,
    );
