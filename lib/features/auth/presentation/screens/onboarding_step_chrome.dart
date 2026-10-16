part of 'onboarding_chrome.dart';

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
  const OnboardingStepHero({
    required this.copy,
    this.body,
    this.scrollIntroduction = false,
    super.key,
  });

  /// The step's title and subtitle.
  final OnboardingStepCopy copy;

  /// The step's own content, scrolled independently of the pinned copy.
  final Widget? body;

  /// Scrolls the copy with the fields, leaving the body's actions pinned.
  ///
  /// The body must contain an [OnboardingStepLayout].
  final bool scrollIntroduction;

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

    final introduction = Column(
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
        if (body != null) const SizedBox(height: 24),
      ],
    );

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
      child: scrollIntroduction && body != null
          ? OnboardingStepIntroduction(introduction: introduction, child: body!)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kOnboardingStepInset,
                  ),
                  child: introduction,
                ),
                if (body != null) Flexible(child: body!),
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
