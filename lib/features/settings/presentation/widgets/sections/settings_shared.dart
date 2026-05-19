import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppearanceSection extends ConsumerWidget {
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
              child: FSelect<Locale>(
                items: {
                  l10n.languageSystem: const Locale('system'),
                  l10n.languageEnglish: const Locale('en', 'US'),
                  l10n.languageFrench: const Locale('fr', 'FR'),
                  l10n.languageSpanish: const Locale('es', 'ES'),
                  l10n.languageItalian: const Locale('it', 'IT'),
                  l10n.languageGerman: const Locale('de', 'DE'),
                  l10n.languagePortuguese: const Locale('pt', 'BR'),
                  l10n.languageDutch: const Locale('nl', 'NL'),
                },
                control: FSelectControl<Locale>.lifted(
                  value: localeOverride ?? const Locale('system'),
                  onChange: (v) {
                    ref.read(localeProvider.notifier).setLocale(
                      v == const Locale('system') ? null : v,
                    );
                  },
                ),
              ),
            ),
          ),
          SettingsRow(
            icon: LucideIcons.sun,
            title: l10n.theme,
            subtitle: l10n.matchOsAppearance,
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: FSelect<ThemeMode>(
                items: {
                  l10n.themeSystem: ThemeMode.system,
                  l10n.themeLight: ThemeMode.light,
                  l10n.themeDark: ThemeMode.dark,
                },
                control: FSelectControl<ThemeMode>.lifted(
                  value: themeMode,
                  onChange: (v) {
                    if (v != null) {
                      ref.read(themeModeProvider.notifier).setThemeMode(v);
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

class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.subtitleStyle,
    this.subtitleWidget,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final TextStyle? subtitleStyle;
  final Widget? subtitleWidget;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = FTheme.of(context).colors;
    final tokens = context.designSystem;
    final defaultSubtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: tokens?.textTertiary ?? colors.mutedForeground,
      height: 1.45,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: tokens?.fgTertiary ?? colors.mutedForeground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: tokens?.textPrimary ?? colors.foreground,
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

class SkeletonBar extends StatefulWidget {
  const SkeletonBar({required this.width, super.key});

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
    final colors = FTheme.of(context).colors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final opacity = 0.3 + (_controller.value * 0.5);
        return Container(
          width: widget.width,
          height: 14,
          decoration: BoxDecoration(
            color: colors.mutedForeground.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

Future<void> showTokenDialog(
  BuildContext context, {
  required String title,
  required Future<void> Function(String) save,
  String initialValue = '',
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initialValue);
  await showFDialog<void>(
    context: context,
    builder: (dialogContext, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(title),
      body: FTextField(
        control: FTextFieldControl.managed(controller: controller),
        label: Text(title),
        hint: l10n.pasteValueHere,
        obscureText: true,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                onPress: () => Navigator.pop(dialogContext),
                variant: FButtonVariant.ghost,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: () async {
                  try {
                    await save(controller.text);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  } on Object catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(l10n.failedWithError('$e'))),
                      );
                    }
                  }
                },
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  controller.dispose();
}
