import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The horizontal inset every onboarding step applies to its own children.
///
/// The onboarding card itself carries no side padding: the scrolling viewport
/// has to reach the card border so the injected scrollbar hugs it instead of
/// floating inside. Each child re-applies the inset so the content still lines
/// up with the step's pinned title.
const double kOnboardingStepInset = 24;

/// The breathing room between the last field and the boundary above the pinned
/// action row.
///
/// It is padding INSIDE the scrolling viewport, not a gap above the divider:
/// scrolled to the bottom, a field would otherwise sit flush against the rule
/// and read as clipped when nothing is left to see. Because it is whitespace,
/// content that overflows by no more than this amount has only padding out of
/// view — which is why the boundary below is drawn against this threshold
/// rather than against zero.
const double kOnboardingStepBottomGap = 16;

/// The body layout shared by every onboarding step: the fields scroll, the
/// action row does not.
///
/// A step's actions ("Continue", "Back", "Skip") are the whole point of the
/// step, so they stay on screen no matter how tall the fields grow — only
/// [content] scrolls, between the pinned title above (owned by the step card)
/// and the pinned [footer] below.
///
/// The scrolling viewport spans the card's full width and re-applies
/// [kOnboardingStepInset] as its own padding, which is what puts the scrollbar
/// on the card border rather than 24px inside it.
class OnboardingStepLayout extends StatefulWidget {
  /// Creates an [OnboardingStepLayout].
  const OnboardingStepLayout({super.key, required this.content, this.footer});

  /// The step's fields. The only part that scrolls.
  final Widget content;

  /// The step's action row, pinned to the bottom of the card. Steps with no
  /// actions of their own (a loading or error branch) leave it null.
  final Widget? footer;

  @override
  State<OnboardingStepLayout> createState() => _OnboardingStepLayoutState();
}

class _OnboardingStepLayoutState extends State<OnboardingStepLayout> {
  bool _overflowing = false;

  /// Content clipped at the viewport edge needs a boundary, or the pinned
  /// action row reads as floating over a half-cut field. The rule is drawn
  /// only when there is actually something scrolled out of view — the trailing
  /// [kOnboardingStepBottomGap] is whitespace, so an overflow within it hides
  /// nothing and needs no boundary.
  bool _onMetrics(ScrollMetricsNotification notification) {
    final overflowing =
        notification.metrics.maxScrollExtent > kOnboardingStepBottomGap;
    if (overflowing != _overflowing) {
      // Metrics arrive during layout; defer so this never rebuilds mid-frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && overflowing != _overflowing) {
          setState(() => _overflowing = overflowing);
        }
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final footer = widget.footer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: _onMetrics,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                kOnboardingStepInset,
                0,
                kOnboardingStepInset,
                kOnboardingStepBottomGap,
              ),
              child: widget.content,
            ),
          ),
        ),
        if (footer != null) ...[
          if (_overflowing) CcDivider(color: tokens?.borderSoft),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kOnboardingStepInset,
              20,
              kOnboardingStepInset,
              0,
            ),
            child: footer,
          ),
        ],
      ],
    );
  }
}
