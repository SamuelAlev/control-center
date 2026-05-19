import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Settings section for theme, language, and typography appearance.
class AppearanceSection extends ConsumerWidget {
  /// Creates an [AppearanceSection].
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final localeOverride = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.appearanceLanguage,
      child: Column(
        children: [
          SettingsRow(
            icon: LucideIcons.languages,
            title: l10n.settingsLanguage,
            subtitle: l10n.settingsLanguageDescription,
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: CcSelect<Locale>(
                options: [
                  CcSelectOption(
                    value: const Locale('system'),
                    label: l10n.languageSystem,
                  ),
                  CcSelectOption(
                    value: const Locale('en', 'US'),
                    label: l10n.languageEnglish,
                  ),
                  CcSelectOption(
                    value: const Locale('fr', 'FR'),
                    label: l10n.languageFrench,
                  ),
                  CcSelectOption(
                    value: const Locale('es', 'ES'),
                    label: l10n.languageSpanish,
                  ),
                  CcSelectOption(
                    value: const Locale('it', 'IT'),
                    label: l10n.languageItalian,
                  ),
                  CcSelectOption(
                    value: const Locale('de', 'DE'),
                    label: l10n.languageGerman,
                  ),
                  CcSelectOption(
                    value: const Locale('pt', 'BR'),
                    label: l10n.languagePortuguese,
                  ),
                  CcSelectOption(
                    value: const Locale('nl', 'NL'),
                    label: l10n.languageDutch,
                  ),
                ],
                value: localeOverride ?? const Locale('system'),
                onChanged: (v) {
                  ref.read(localeProvider.notifier).setLocale(
                    v == const Locale('system') ? null : v,
                  );
                },
              ),
            ),
          ),
          SettingsRow(
            icon: LucideIcons.sun,
            title: l10n.theme,
            subtitle: l10n.matchOsAppearance,
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: CcSelect<ThemeMode>(
                options: [
                  CcSelectOption(
                    value: ThemeMode.system,
                    label: l10n.themeSystem,
                  ),
                  CcSelectOption(
                    value: ThemeMode.light,
                    label: l10n.themeLight,
                  ),
                  CcSelectOption(
                    value: ThemeMode.dark,
                    label: l10n.themeDark,
                  ),
                ],
                value: themeMode,
                onChanged: (v) {
                  ref.read(themeModeProvider.notifier).setThemeMode(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled settings row with icon, title, subtitle, and trailing widget.
class SettingsRow extends StatelessWidget {
  /// Creates a [SettingsRow].
  const SettingsRow({super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.subtitleStyle,
    this.subtitleWidget,
  });

  /// Leading icon for the row.
  final IconData icon;
  /// Row title text.
  final String title;
  /// Row subtitle text.
  final String subtitle;
  /// Optional custom style for the subtitle.
  final TextStyle? subtitleStyle;
  /// Optional custom subtitle widget (replaces text subtitle).
  final Widget? subtitleWidget;
  /// Trailing widget (e.g. switch, button).
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final defaultSubtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: tokens?.textTertiary,
      height: 1.45,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: tokens?.fgTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: tokens?.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                subtitleWidget ??
                    Text(
                      subtitle,
                      style: subtitleStyle ?? defaultSubtitleStyle,
                    ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

/// Animated skeleton placeholder bar.
class SkeletonBar extends StatefulWidget {
  /// Creates a [SkeletonBar] with the given [width].
  const SkeletonBar({required this.width, super.key});

  /// Width of the skeleton bar.
  final double width;

  @override
  State<SkeletonBar> createState() => _SkeletonBarState();
}

class _SkeletonBarState extends State<SkeletonBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final base = tokens?.textTertiary ?? Colors.grey;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final opacity = 0.3 + (_controller.value * 0.5);
        return Container(
          width: widget.width,
          height: 14,
          decoration: BoxDecoration(
            color: base.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

/// Shows a dialog for entering a secret token or API key.
Future<void> showTokenDialog(
  BuildContext context, {
  required String title,
  required Future<void> Function(String) save,
  String initialValue = '',
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initialValue);
  await showCcDialog<void>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: title,
      content: CcTextField(
        controller: controller,
        hintText: l10n.pasteValueHere,
        obscureText: true,
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.pop(dialogContext),
          variant: CcButtonVariant.ghost,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () async {
            try {
              await save(controller.text);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            } on Object catch (e) {
              if (dialogContext.mounted) {
                CcToastScope.of(dialogContext).show(
                  l10n.failedWithError('$e'),
                  variant: CcToastVariant.danger,
                );
              }
            }
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
}
