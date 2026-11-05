/// The chrome around the pre-context auth surfaces — first-run onboarding and
/// the re-authentication screen: the full-screen frame, the labelled progress
/// bar, the card each step's copy and body sit in, and the settings button.
///
/// Split out of `onboarding_screen.dart` so the screen file is the FLOW — which
/// step follows which, and what each one says — rather than the flow plus the
/// widgets that draw it. Keeping the frame here is also what lets those screens
/// stay free of `flutter/material.dart`: the vendor dependency is concentrated
/// in this one already-allowlisted file.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_step_layout.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/server_connect/pre_app_settings.dart';
import 'package:control_center/shared/widgets/shader_background.dart';
import 'package:control_center/shared/widgets/window_caption_buttons.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

part 'onboarding_step_chrome.dart';

/// The full-screen frame every pre-context auth surface sits in: the shader background, a
/// centred column capped at a readable width, and the settings button.
/// Shared rather than copied because these screens are the app's first impression and the
/// only ones drawn outside the shell — two hand-rolled frames drift in exactly the places
/// (the max width, the inset, where the toggle sits) where the drift is visible as a jump
/// between them.
/// `isMovable = false` (see `styleWindowOnShow`) — the only switch that stops macOS
/// dragging it out from under the app's own title bar — so the app moves it itself, from
class OnboardingScaffold extends StatelessWidget {
  /// Creates an [OnboardingScaffold].
  const OnboardingScaffold({
    required this.child,
    this.bottomActivity,
    super.key,
  });

  /// The surface's own content, centred in the frame.
  final Widget child;

  /// Compact activity, inside the keyboard-resized body rather than over it.
  final Widget? bottomActivity;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return ShaderBackground(
      child: WindowDragArea(
        moveWindowManually: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                    if (bottomActivity case final activity?)
                      Builder(
                        builder: (context) => MediaQuery(
                          // Scaffold removes these from its body; activity
                          // still needs the keyboard state to fold its details.
                          data: MediaQuery.of(
                            context,
                          ).copyWith(viewInsets: viewInsets),
                          child: activity,
                        ),
                      ),
                  ],
                ),
                const WindowCaptionCorner(child: OnboardingSettingsButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the settings a person needs before signing in, from the corner.
class OnboardingSettingsButton extends StatelessWidget {
  /// Creates the [OnboardingSettingsButton].
  const OnboardingSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CcIconButton(
      icon: AppIcons.settings,
      tooltip: AppLocalizations.of(context).navSettings,
      onPressed: () =>
          showPreAppSettings(context, (_) => const _OnboardingSettings()),
    );
  }
}

/// The settings page over the persisted language and theme.
class _OnboardingSettings extends ConsumerWidget {
  const _OnboardingSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PreAppSettingsPage(
      locale: ref.watch(localeProvider),
      onLocaleChanged: ref.read(localeProvider.notifier).setLocale,
      theme: ref.watch(themeModeProvider).choice,
      onThemeChanged: (choice) =>
          ref.read(themeModeProvider.notifier).setThemeMode(choice.mode),
    );
  }
}
