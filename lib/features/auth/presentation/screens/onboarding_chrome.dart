/// The chrome around the pre-context auth surfaces — first-run onboarding and
/// the re-authentication screen: the full-screen frame, the labelled progress
/// bar, the card each step's copy and body sit in, and the theme toggle.
///
/// Split out of `onboarding_screen.dart` so the screen file is the FLOW — which
/// step follows which, and what each one says — rather than the flow plus the
/// widgets that draw it. Keeping the frame here is also what lets those screens
/// stay free of `flutter/material.dart`: the vendor dependency is concentrated
/// in this one already-allowlisted file.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_step_layout.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/shader_background.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The full-screen frame every pre-context auth surface sits in: the shader
/// background, a centred column capped at a readable width, and the theme
/// toggle in the corner.
///
/// Shared rather than copied because these screens are the app's first
/// impression and the only ones drawn outside the shell — two hand-rolled
/// frames drift in exactly the places (the max width, the inset, where the
/// toggle sits) where the drift is visible as a jump between them.
///
/// **The whole frame moves the OS window.** The primary window is
/// `isMovable = false` (see `styleWindowOnShow`) — the only switch that stops
/// macOS dragging it out from under the app's own title bar — so the app moves
/// it itself, from `ShellTitleBar`. That bar lives inside the shell, and these
/// surfaces render outside it: without a drag area of their own the operator
/// gets a window that cannot be moved at all, at the one moment they have not
/// yet reached anything else. There is no bar here to make a strip out of and
/// an invisible 40px band at the top is not an affordance anyone would find, so
/// the whole surface drags; [WindowDragArea] stands down on anything that
/// claims the press (buttons, fields, scrollables), leaving only inert
/// background.
class OnboardingScaffold extends StatelessWidget {
  /// Creates an [OnboardingScaffold].
  const OnboardingScaffold({required this.child, super.key});

  /// The surface's own content, centred in the frame.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderBackground(
      child: WindowDragArea(
        moveWindowManually: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                      child: child,
                    ),
                  ),
                ),
                const Positioned(
                  top: 16,
                  right: 16,
                  child: OnboardingThemeToggle(),
                ),
              ],
            ),
          ),
        ),
      ),
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

/// What one onboarding step says.
class OnboardingStepCopy {
  /// Creates an [OnboardingStepCopy].
  const OnboardingStepCopy({required this.title, required this.subtitle});

  /// The step's headline.
  final String title;

  /// The sentence under it.
  final String subtitle;
}

/// The card an onboarding step's copy and body sit in.
class OnboardingStepHero extends StatelessWidget {
  /// Creates an [OnboardingStepHero].
  const OnboardingStepHero({required this.copy, this.body, super.key});

  /// The step's title and subtitle.
  final OnboardingStepCopy copy;

  /// The step's own content, scrolled independently of the pinned copy.
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final isLight = theme.brightness == Brightness.light;

    final surfaceTint = isLight
        ? (tokens?.panel ?? Colors.white).withValues(alpha: 0.55)
        : (tokens?.bgSecondary ?? const Color(0xFF1F1F1F)).withValues(
            alpha: 0.30,
          );
    final borderColor = isLight
        ? (tokens?.borderSecondary ?? Colors.white).withValues(alpha: 0.65)
        : (tokens?.borderSoft ?? Colors.white).withValues(alpha: 0.10);

    return Container(
      // No side padding: the body's scrolling viewport has to reach the card
      // border so the injected scrollbar hugs it. Every child re-applies
      // [kOnboardingStepInset] instead.
      padding: const EdgeInsets.only(top: 22, bottom: 24),
      decoration: BoxDecoration(
        color: surfaceTint,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        // Shrink-wraps so a short step keeps the compact centred card; the
        // outer Flexible (in OnboardingScreen) caps it at the viewport, where
        // the body below takes over scrolling.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Which step this is is told by the labelled progress bar above the
          // card, so the card opens straight on the title.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kOnboardingStepInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.title,
                  style: CcTypography.display.copyWith(
                    color: tokens?.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  copy.subtitle,
                  style: CcTypography.body.copyWith(
                    color: tokens?.textTertiary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          // The title/subtitle stay pinned under the step indicator and the
          // body pins its own action row; scrolling is confined to the fields
          // in between, via [OnboardingStepLayout].
          if (body != null) ...[
            const SizedBox(height: 24),
            Flexible(child: body!),
          ],
        ],
      ),
    );
  }
}

/// The progress bar: one labelled segment per step, so the whole flow is
/// readable at a glance instead of only the step you happen to be on.
class OnboardingStepIndicator extends StatelessWidget {
  /// Creates an [OnboardingStepIndicator].
  const OnboardingStepIndicator({
    required this.currentStep,
    required this.total,
    required this.labels,
    super.key,
  });

  /// The zero-based step being shown.
  final int currentStep;

  /// How many steps there are.
  final int total;

  /// One label per step, in order.
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.designSystem;
    // Reached steps take the accent; the ones ahead stay in plain body text
    // so they read as "not yet", never as disabled.
    final upcoming = tokens?.textPrimary ?? scheme.onSurface;

    final segments = <Widget>[];
    for (var i = 0; i < total; i++) {
      final reached = i <= currentStep;
      segments.add(
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 260),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.caption.copyWith(
                  color: reached ? scheme.primary : upcoming,
                  fontWeight: i == currentStep
                      ? FontWeight.w600
                      : FontWeight.w500,
                  letterSpacing: 0.6,
                ),
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                height: 4,
                decoration: BoxDecoration(
                  color: reached
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      );
      if (i < total - 1) {
        segments.add(const SizedBox(width: 6));
      }
    }
    return Row(
      key: const Key('onboarding-step-indicator'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: segments,
    );
  }
}
