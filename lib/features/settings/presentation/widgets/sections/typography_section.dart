import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:control_center/features/pr_review/providers/diff_view_settings_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/font_picker.dart';
import 'package:control_center/features/settings/presentation/widgets/font_preview_card.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TypographySection extends ConsumerWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fontSettings = ref.watch(fontSettingsProvider);
    final notifier = ref.read(fontSettingsProvider.notifier);
    final overflowMode = ref.watch(diffOverflowModeProvider);

    return SectionCard(
      label: l10n.typography,
      child: Column(
        children: [
          _FontTile(
            icon: LucideIcons.type,
            label: l10n.appFont,
            selection: fontSettings.appFontSelection,
            onTap: () async {
              final result = await showFontPicker(
                context: context,
                currentSelection: fontSettings.appFontSelection,
                contextType: FontContext.app,
              );
              if (result != null) {
                await notifier.setAppFont(result);
              }
            },
          ),
          const SizedBox(height: 8),
          _FontTile(
            icon: LucideIcons.code,
            label: l10n.codeFont,
            selection: fontSettings.codeFontSelection,
            onTap: () async {
              final result = await showFontPicker(
                context: context,
                currentSelection: fontSettings.codeFontSelection,
                contextType: FontContext.code,
              );
              if (result != null) {
                await notifier.setCodeFont(result);
              }
            },
          ),
          const SizedBox(height: 8),
          SettingsRow(
            icon: LucideIcons.wrapText,
            title: l10n.diffLineDisplay,
            subtitle: l10n.diffLineDisplayDescription,
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: FSelect<DiffOverflowMode>(
                items: {
                  l10n.diffLineWrap: DiffOverflowMode.wrap,
                  l10n.diffLineScroll: DiffOverflowMode.scroll,
                },
                control: FSelectControl<DiffOverflowMode>.lifted(
                  value: overflowMode,
                  onChange: (v) {
                    if (v != null) {
                      ref
                          .read(diffOverflowModeProvider.notifier)
                          .setMode(v);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FontTile extends StatelessWidget {
  const _FontTile({
    required this.icon,
    required this.label,
    required this.selection,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final FontSelection selection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = FTheme.of(context).colors;
    final preview = selection.source == FontSource.google
        ? GoogleFonts.getFont(
            selection.family,
            fontSize: 13,
            color: colors.mutedForeground,
          )
        : TextStyle(
            fontFamily: selection.family,
            fontSize: 13,
            color: colors.mutedForeground,
          );
    return SettingsRow(
      icon: icon,
      title: label,
      subtitle: selection.family,
      subtitleStyle: preview,
      trailing: FButton(
        onPress: onTap,
        variant: FButtonVariant.outline,
        mainAxisSize: MainAxisSize.min,
        suffix: const Icon(LucideIcons.chevronRight, size: 14),
        child: Text(l10n.change),
      ),
    );
  }
}
