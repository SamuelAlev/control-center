import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Closed-list language autocomplete. Opening lists every locale; typing
/// then filters native names, BCP 47 tags and ISO codes. Abandoning the
/// query restores the current selection rather than committing free text.
class LanguagePicker extends ConsumerStatefulWidget {
  /// Creates the shared closed-list language picker.
  const LanguagePicker({
    required this.selected,
    required this.systemLabel,
    required this.searchHint,
    required this.semanticLabel,
    super.key,
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
  ConsumerState<LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends ConsumerState<LanguagePicker> {
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
  void didUpdateWidget(covariant LanguagePicker oldWidget) {
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

/// Interactive language selection backed only by local preferences.
@Preview(name: 'Language picker', group: 'Auth', size: Size(320, 160))
Widget languagePickerPreview() => ProviderScope(
  overrides: [
    appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
  ],
  child: Consumer(
    builder: (context, ref, _) {
      final theme = CcThemeData.light();
      return CcTheme(
        data: theme,
        child: WidgetsApp(
          color: theme.tokens.bgPrimary,
          locale: ref.watch(localeProvider),
          supportedLocales: kSupportedAppLocales,
          localeResolutionCallback: resolveAppLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          textStyle: CcFonts.ui(textStyle: CcTypography.body).copyWith(
            color: theme.tokens.textPrimary,
            decoration: TextDecoration.none,
          ),
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Center(
                child: SizedBox(
                  width: 240,
                  child: LanguagePicker(
                    selected: ref.watch(localeProvider),
                    systemLabel: l10n.languageSystem,
                    searchHint: l10n.searchPlaceholder,
                    semanticLabel: l10n.settingsLanguage,
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  ),
);
