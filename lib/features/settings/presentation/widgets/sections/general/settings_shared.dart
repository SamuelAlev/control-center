import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings section for theme, language and typography appearance.
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
            icon: AppIcons.languages,
            title: l10n.settingsLanguage,
            subtitle: l10n.settingsLanguageDescription,
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: _LanguagePicker(
                selected: localeOverride,
                systemLabel: l10n.languageSystem,
                searchHint: l10n.searchPlaceholder,
                semanticLabel: l10n.settingsLanguage,
              ),
            ),
          ),
          SettingsRow(
            icon: AppIcons.sun,
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
                  CcSelectOption(value: ThemeMode.dark, label: l10n.themeDark),
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

/// Closed-list language autocomplete. Opening lists every locale; typing
/// then filters native names, BCP 47 tags and ISO codes. Abandoning the
/// query restores the current selection rather than committing free text.
class _LanguagePicker extends ConsumerStatefulWidget {
  const _LanguagePicker({
    required this.selected,
    required this.systemLabel,
    required this.searchHint,
    required this.semanticLabel,
  });

  /// Current locale override, or `null` to follow the system.
  final Locale? selected;

  /// Localized label for the follow-system option.
  final String systemLabel;

  /// Placeholder shown while the field is empty.
  final String searchHint;

  /// Accessibility name for the field.
  final String semanticLabel;

  @override
  ConsumerState<_LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends ConsumerState<_LanguagePicker> {
  static const _system = Locale('system');

  final _controller = TextEditingController();
  final _focus = FocusNode();
  var _seeded = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed before the first paint so the field never flashes empty. The
    // autocomplete has not attached its listener yet, so this write cannot
    // pop the overlay.
    if (!_seeded) {
      _seeded = true;
      _controller.text = _labelFor(widget.selected);
    }
  }

  @override
  void didUpdateWidget(covariant _LanguagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected && !_focus.hasFocus) {
      final label = _labelFor(widget.selected);
      if (_controller.text != label) {
        // Defer: writing during build notifies the autocomplete, which would
        // try to show its overlay in the persistent-callbacks phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_focus.hasFocus && _controller.text != label) {
            _controller.text = label;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus || !mounted) {
      return;
    }
    final label = _labelFor(widget.selected);
    if (_controller.text != label) {
      _controller.text = label;
    }
  }

  String _labelFor(Locale? selected) {
    if (selected == null) {
      return widget.systemLabel;
    }
    for (final variant in kAppLocaleVariants) {
      if (variant.locale == selected) {
        return variant.nativeLabel;
      }
    }
    return widget.systemLabel;
  }

  @override
  Widget build(BuildContext context) {
    return CcAutocomplete<Locale>(
      controller: _controller,
      focusNode: _focus,
      hintText: widget.searchHint,
      semanticLabel: widget.semanticLabel,
      options: [
        CcSelectOption(value: _system, label: widget.systemLabel),
        // Native, self-named labels (see AppLocaleVariant.nativeLabel):
        // each language names itself and its country so the entry is
        // findable regardless of the active locale.
        for (final variant in kAppLocaleVariants)
          CcSelectOption(value: variant.locale, label: variant.nativeLabel),
      ],
      filter: (options, query) => [
        for (final option in options)
          if (localePickerQueryMatches(
            query: query,
            label: option.label,
            locale: option.value,
          ))
            option,
      ],
      onSelected: (value) {
        ref
            .read(localeProvider.notifier)
            .setLocale(value == _system ? null : value);
      },
    );
  }
}

/// A labeled settings row with icon, title, subtitle and trailing widget.
class SettingsRow extends StatelessWidget {
  /// Creates a [SettingsRow].
  const SettingsRow({
    super.key,
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
    final tokens = context.designSystem;
    final defaultSubtitleStyle = CcTypography.caption.copyWith(
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
                  style: CcTypography.body.copyWith(
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

/// Shows a dialog for entering a value. [obscure] masks the input (default;
/// for secrets like tokens/keys) — pass `false` for non-secret values such as
/// URLs or device ids.
///
/// [multiline] is for a pasted BLOCK: a PEM private key is a dozen lines and
/// masking it would also collapse it to one, so a multiline field is never
/// obscured. It is still a secret; it is just one you have to be able to see
/// you pasted whole.
Future<void> showTokenDialog(
  BuildContext context, {
  required String title,
  required Future<void> Function(String) save,
  String initialValue = '',
  bool obscure = true,
  bool multiline = false,
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
        obscureText: obscure && !multiline,
        minLines: multiline ? 6 : 1,
        maxLines: multiline ? 12 : 1,
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
