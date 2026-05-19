import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/vscode_theme/data/vscode_theme_importer.dart';
import 'package:control_center/features/vscode_theme/providers/vscode_theme_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Appearance: import a VS Code color theme so the embedded
/// diff/editor surfaces match the colors the user already reads code in. Paste
/// the contents of a `*-color-theme.json`; CC distils the editor/diff roles and
/// a compact syntax palette from it.
class EditorThemeSection extends ConsumerStatefulWidget {
  /// Creates an [EditorThemeSection].
  const EditorThemeSection({super.key});

  @override
  ConsumerState<EditorThemeSection> createState() => _EditorThemeSectionState();
}

class _EditorThemeSectionState extends ConsumerState<EditorThemeSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      return;
    }
    try {
      await ref.read(vscodeEditorThemeProvider.notifier).import(raw);
      if (!mounted) {
        return;
      }
      _controller.clear();
      CcToastScope.of(context).show(l10n.editorThemeImported);
    } on VsCodeThemeFormatException {
      if (!mounted) {
        return;
      }
      CcToastScope.of(
        context,
      ).show(l10n.editorThemeInvalid, variant: CcToastVariant.danger);
    }
  }

  Future<void> _clear() async {
    await ref.read(vscodeEditorThemeProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final current = ref.watch(vscodeEditorThemeProvider);

    return SectionCard(
      label: l10n.editorTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.editorThemeDescription,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            ),
          ),
          if (current != null) ...[
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: current.background,
                    borderRadius: AppRadii.brXs,
                    border: Border.all(color: t.borderSecondary),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    current.name,
                    style: CcTypography.body.copyWith(color: t.textPrimary),
                  ),
                ),
                CcBadge(
                  label: current.brightness == Brightness.dark
                      ? l10n.themeDark
                      : l10n.themeLight,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          CcTextArea(
            controller: _controller,
            hintText: l10n.editorThemePasteHint,
            minLines: 3,
            maxLines: 8,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (current != null) ...[
                CcButton(
                  size: CcButtonSize.sm,
                  variant: CcButtonVariant.secondary,
                  onPressed: _clear,
                  child: Text(l10n.clearTheme),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              CcButton(
                size: CcButtonSize.sm,
                onPressed: _import,
                child: Text(l10n.importTheme),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
