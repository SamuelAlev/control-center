import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/connection_error_alert.dart';
import 'package:control_center/shared/widgets/server_connect/connect_appearance.dart';
import 'package:control_center/shared/widgets/server_connect/pre_app_settings.dart';
import 'package:control_center/shared/widgets/shader_background.dart';
import 'package:control_center/shared/widgets/window_caption_buttons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// One way into Control Center, offered as a full-width landing button.
class ConnectAction {
  /// Creates a [ConnectAction].
  const ConnectAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.loading = false,
  });

  /// The leading glyph.
  final IconData icon;

  /// The button's label.
  final String label;

  /// Runs the action; null disables it.
  final VoidCallback? onPressed;

  /// Whether this is the screen's main action.
  final bool primary;

  /// Whether this action is running.
  final bool loading;
}

/// The login screen on desktop and web: the brand mark, a welcome and the ways
/// in, over the same cloudscape onboarding uses, so signing in and setting up
/// read as one place.
class ConnectLanding extends StatelessWidget {
  /// Creates a [ConnectLanding].
  const ConnectLanding({
    super.key,
    required this.subtitle,
    required this.actions,
    required this.appearance,
    this.error,
  });

  /// The sentence under the welcome, naming what this client can do.
  final String subtitle;

  /// The ways in, most likely first.
  final List<ConnectAction> actions;

  /// Language and theme, behind the corner settings button.
  final ConnectAppearance appearance;

  /// A failure no dialog is showing, such as a local server that would not
  /// start or a saved connection that was lost.
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final failure = error;
    return ShaderBackground(
      animate: !CcMotion.reduced(context),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _ContentScrim(color: t.bgPrimary)),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ExcludeSemantics(
                          // The app icon's continuous corner, about 22.5% of
                          // the tile, so this reads as the icon in the Dock.
                          child: ClipRSuperellipse(
                            borderRadius: BorderRadius.circular(16),
                            child: SvgPicture.asset(
                              'assets/logo_with_background.svg',
                              width: 72,
                              height: 72,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.connectWelcomeTitle,
                          textAlign: TextAlign.center,
                          style: CcTypography.display.copyWith(
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: CcTypography.body.copyWith(
                          color: t.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      for (final (index, action) in actions.indexed) ...[
                        if (index > 0) const SizedBox(height: AppSpacing.md),
                        CcButton(
                          onPressed: action.onPressed,
                          variant: action.primary
                              ? CcButtonVariant.accent
                              : CcButtonVariant.line,
                          size: CcButtonSize.lg,
                          icon: action.icon,
                          loading: action.loading,
                          fullWidth: true,
                          child: Text(action.label),
                        ),
                      ],
                      if (failure != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        ConnectionErrorAlert(error: failure),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            WindowCaptionCorner(child: _SettingsButton(appearance)),
          ],
        ),
      ),
    );
  }
}

/// Settles the cloudscape behind the centred content so its text keeps its
/// contrast wherever the clouds drift, leaving the edges of the window clear.
class _ContentScrim extends StatelessWidget {
  const _ContentScrim({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [
              color.withValues(alpha: 0.92),
              color.withValues(alpha: 0.82),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.6, 1],
          ),
        ),
      ),
    );
  }
}

/// Opens the settings a person needs before signing in.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton(this.appearance);

  final ConnectAppearance appearance;

  @override
  Widget build(BuildContext context) {
    return CcIconButton(
      icon: AppIcons.settings,
      tooltip: AppLocalizations.of(context).navSettings,
      onPressed: () => showPreAppSettings(
        context,
        (_) => ListenableBuilder(
          listenable: appearance,
          builder: (_, _) => PreAppSettingsPage(
            locale: appearance.locale,
            onLocaleChanged: appearance.setLocale,
            theme: appearance.theme,
            onThemeChanged: appearance.setTheme,
          ),
        ),
      ),
    );
  }
}
