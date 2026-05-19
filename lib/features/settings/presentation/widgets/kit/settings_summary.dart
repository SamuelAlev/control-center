import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// One fact in a [SettingsSummary].
@immutable
class SettingsFact {
  /// Creates a [SettingsFact].
  const SettingsFact({
    required this.label,
    required this.value,
    this.tone,
    this.mono = true,
  });

  /// What the fact is about. Sentence case, two or three words.
  final String label;

  /// The current value, already localized and formatted.
  final String value;

  /// Colours the value and adds a dot. Use it only where the value is a state
  /// the reader should act on; a fact that is merely a number has no tone.
  final CcStatusTone? tone;

  /// Renders the value in the mono face. On by default: most facts here are
  /// counts, versions and endpoints, and tabular figures stop a summary strip
  /// from jittering when a count ticks.
  final bool mono;
}

/// The "where do I stand" strip that opens a settings surface.
///
/// A settings page that begins with a form asks the reader to configure before
/// it has told them anything. Every dense surface now opens with this instead:
/// three to five facts about the current state, so the first thing the page
/// says is whether SSO is on, how many providers are connected, or how many
/// runners were actually found on this machine.
///
/// It is deliberately not a row of stat cards. Those are the SaaS-dashboard
/// reflex, and four bordered boxes for four short strings is a lot of chrome
/// for a paragraph's worth of information. This is a wrapped strip of
/// label/value pairs on the card's own surface, separated by hairlines.
class SettingsSummary extends StatelessWidget {
  /// Creates a [SettingsSummary].
  const SettingsSummary({
    super.key,
    required this.facts,
    this.trailing,
    this.note,
  });

  /// The facts, in reading order. Put the one that decides what to do first.
  final List<SettingsFact> facts;

  /// Optional action aligned to the right (a refresh, a sync).
  final Widget? trailing;

  /// Optional sentence under the strip — use it for the consequence of the
  /// state above ("agents fall back to the workspace default until one is
  /// connected"), never to restate a fact.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final fact in facts) _Fact(fact: fact, tokens: tokens),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.lg),
              trailing!,
            ],
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            note!,
            style: CcTypography.caption.copyWith(
              color: tokens.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.fact, required this.tokens});

  final SettingsFact fact;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final valueColor = switch (fact.tone) {
      CcStatusTone.positive => tokens.textSuccessPrimary,
      CcStatusTone.negative => tokens.textErrorPrimary,
      CcStatusTone.caution => tokens.textWarningPrimary,
      CcStatusTone.info => tokens.accent,
      CcStatusTone.neutral || null => tokens.textPrimary,
    };
    final valueStyle = CcTypography.bodySm.copyWith(
      color: valueColor,
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          fact.label,
          style: CcTypography.caption.copyWith(color: tokens.textTertiary),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fact.tone != null) ...[
              CcStatusDot(tone: fact.tone!, size: 7),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              fact.value,
              style: fact.mono
                  ? CcFonts.code(textStyle: valueStyle)
                  : valueStyle,
            ),
          ],
        ),
      ],
    );
  }
}
