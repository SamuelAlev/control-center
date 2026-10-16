/// The chrome around the pre-context auth surfaces — first-run onboarding and
/// the re-authentication screen: the full-screen frame, the labelled progress
/// bar, the card each step's copy and body sit in, and local appearance controls.
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
import 'package:control_center/shared/widgets/language_picker.dart';
import 'package:control_center/shared/widgets/shader_background.dart';
import 'package:control_center/shared/widgets/window_caption_buttons.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

part 'onboarding_step_chrome.dart';

/// The full-screen frame every pre-context auth surface sits in: the shader background, a
/// centred column capped at a readable width, and language/theme controls.
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
                const WindowCaptionCorner(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 200, child: OnboardingLanguagePicker()),
                      SizedBox(width: AppSpacing.sm),
                      OnboardingThemeToggle(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Local language selection without opening the app's settings.
class OnboardingLanguagePicker extends ConsumerWidget {
  /// Creates the login language picker.
  const OnboardingLanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return LanguagePicker(
      selected: ref.watch(localeProvider),
      systemLabel: l10n.languageSystem,
      searchHint: l10n.searchPlaceholder,
      semanticLabel: l10n.settingsLanguage,
    );
  }
}

/// The light/dark switch in the onboarding corner.
///
/// Flips the theme itself: it already has to read the current brightness to
/// pick its own icon, so having each host pass back an `onToggle` that derives
/// the same thing again was two copies of one decision.
class OnboardingThemeToggle extends ConsumerWidget {
  /// Creates an [OnboardingThemeToggle].
  const OnboardingThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return CcIconButton(
      icon: isLight ? AppIcons.moon : AppIcons.sun,
      tooltip: AppLocalizations.of(context).toggleTheme,
      onPressed: () => ref
          .read(themeModeProvider.notifier)
          .setThemeMode(isLight ? ThemeMode.dark : ThemeMode.light),
    );
  }
}
