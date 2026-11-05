import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/theme_choice.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/language_picker.dart';
import 'package:control_center/shared/widgets/theme_choice_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Opens the settings page over a login or onboarding surface.
///
/// [builder] supplies the page, watching whichever state its host keeps so
/// that a choice shows at once. The page takes the root Navigator because the
/// web gate's dialog host is the only one it has.
void showPreAppSettings(BuildContext context, WidgetBuilder builder) {
  unawaited(
    Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: CcMotion.moderate,
        reverseTransitionDuration: CcMotion.moderateExit,
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
  );
}

/// The settings a person needs before signing in: language and theme.
///
/// Everything else in Settings belongs to a signed-in server, so it is not
/// offered here. Two settings have nothing to navigate between, so this is
/// one page with no section rail.
class PreAppSettingsPage extends StatelessWidget {
  /// Creates a [PreAppSettingsPage].
  const PreAppSettingsPage({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required this.theme,
    required this.onThemeChanged,
  });

  /// The saved language, or null to follow the system.
  final Locale? locale;

  /// Saves a language, or null to follow the system.
  final ValueChanged<Locale?> onLocaleChanged;

  /// The saved theme choice.
  final ThemeChoice theme;

  /// Saves a theme choice.
  final ValueChanged<ThemeChoice> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    void close() => Navigator.of(context).pop();
    // The route sits on the root overlay, which in the connected app has no
    // Material text style to inherit.
    return DefaultTextStyle(
      style: CcFonts.ui(
        family: context.ccTheme?.fontFamily,
        textStyle: CcTypography.body.copyWith(
          color: t.textPrimary,
          decoration: TextDecoration.none,
        ),
      ),
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
        child: Focus(
          autofocus: true,
          child: ColoredBox(
            color: t.bgPrimary,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  // The top inset clears the macOS traffic lights.
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.xl,
                    AppSpacing.xxxl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: CcButton(
                            onPressed: close,
                            variant: CcButtonVariant.ghost,
                            size: CcButtonSize.sm,
                            icon: AppIcons.arrowLeft,
                            child: Text(l10n.back),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Semantics(
                          header: true,
                          child: Text(
                            l10n.navSettings,
                            style: CcTypography.display.copyWith(
                              color: t.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _Panel(
                          child: _LanguageRow(
                            locale: locale,
                            onChanged: onLocaleChanged,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Heading(
                                title: l10n.theme,
                                subtitle: l10n.matchOsAppearance,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ThemeChoicePicker(
                                theme: theme,
                                onChanged: onThemeChanged,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.panel,
        border: Border.all(color: t.borderPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CcTypography.body.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: CcTypography.bodySm.copyWith(color: t.textSecondary),
        ),
      ],
    );
  }
}

/// Stacks under its heading once a phone has no room for both side by side.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.locale, required this.onChanged});

  final Locale? locale;
  final ValueChanged<Locale?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final heading = _Heading(
      title: l10n.settingsLanguage,
      subtitle: l10n.settingsLanguageDescription,
    );
    final picker = LanguagePicker(
      selected: locale,
      systemLabel: l10n.languageSystem,
      searchHint: l10n.searchPlaceholder,
      semanticLabel: l10n.settingsLanguage,
      onSelected: onChanged,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              const SizedBox(height: AppSpacing.md),
              picker,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: AppSpacing.lg),
            SizedBox(width: 220, child: picker),
          ],
        );
      },
    );
  }
}
