import 'package:control_center/features/auth/presentation/screens/onboarding_chrome.dart';
import 'package:control_center/shared/widgets/server_activity_overlay.dart';
import 'package:flutter/widgets.dart';

/// Frames the current step, keeping its actions and server activity visible.
class OnboardingFlowView extends StatelessWidget {
  /// Creates the responsive first-run flow view.
  const OnboardingFlowView({
    required this.copy,
    required this.body,
    required this.labels,
    required this.currentStep,
    required this.canManageModels,
    required this.hideVoiceActivity,
    super.key,
  });

  /// Headline and description for the current step.
  final OnboardingStepCopy copy;

  /// Fields and pinned actions for the current step.
  final Widget body;

  /// Ordered labels of every step in this flow.
  final List<String> labels;

  /// Zero-based current step.
  final int currentStep;

  /// Whether this operator may retry server-side model installation.
  final bool canManageModels;

  /// The voice step renders its own voice transfer state.
  final bool hideVoiceActivity;

  @override
  Widget build(BuildContext context) {
    // Compact steps scroll their introduction with the fields; actions remain
    // pinned above activity. Wide steps also keep their introduction pinned.
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingStepIndicator(
              currentStep: currentStep,
              total: labels.length,
              labels: labels,
            ),
            const SizedBox(height: 32),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(currentStep),
                  child: OnboardingStepHero(
                    copy: copy,
                    body: body,
                    scrollIntroduction: compact,
                  ),
                ),
              ),
            ),
          ],
        );
        final activity = ServerActivityOverlay(
          docked: compact,
          canManageModels: canManageModels,
          hiddenModels: hideVoiceActivity
              ? const {ServerActivityModel.voice}
              : const {},
        );
        final scaffold = OnboardingScaffold(
          bottomActivity: compact ? activity : null,
          child: content,
        );
        return compact
            ? scaffold
            : Stack(
                children: [
                  scaffold,
                  Positioned.fill(child: activity),
                ],
              );
      },
    );
  }
}
