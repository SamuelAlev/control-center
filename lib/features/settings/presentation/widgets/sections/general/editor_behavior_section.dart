import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/settings/providers/editor_preferences_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Appearance: behaviour of the embedded (code-server) editor.
/// Currently the auto-save preference, seeded into code-server's
/// `files.autoSave` on every editor open.
class EditorBehaviorSection extends ConsumerWidget {
  /// Creates an [EditorBehaviorSection].
  const EditorBehaviorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(editorAutoSaveModeProvider);
    return SectionCard(
      label: l10n.ideCodeServer,
      child: SettingsRow(
        icon: AppIcons.save,
        title: l10n.editorAutoSave,
        subtitle: l10n.editorAutoSaveDescription,
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: CcSelect<EditorAutoSaveMode>(
            options: [
              CcSelectOption(
                value: EditorAutoSaveMode.off,
                label: l10n.editorAutoSaveOff,
              ),
              CcSelectOption(
                value: EditorAutoSaveMode.afterDelay,
                label: l10n.editorAutoSaveAfterDelay,
              ),
              CcSelectOption(
                value: EditorAutoSaveMode.onFocusChange,
                label: l10n.editorAutoSaveOnFocusChange,
              ),
            ],
            value: mode,
            onChanged: (v) =>
                ref.read(editorAutoSaveModeProvider.notifier).setMode(v),
          ),
        ),
      ),
    );
  }
}
