import 'dart:async';

import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_status.dart';
import 'package:control_center/features/messaging/providers/channel_activity_summary_provider.dart';
import 'package:control_center/features/messaging/providers/context_usage_provider.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolved colour, glyph and label for a channel's overall state, so the
/// flyout's pill pairs colour with a shape AND a word (never colour alone).
///
/// A sibling of [AgentStatusVisual], not a reuse of it: a channel has two states
/// an agent does not (`needsInput`, `provisioning`) and those are exactly the
/// two the operator most needs to see from the sidebar.
class ChannelStatusVisual {
  /// Creates a [ChannelStatusVisual].
  const ChannelStatusVisual({
    required this.label,
    required this.dotColor,
    required this.textColor,
    required this.fillColor,
    required this.isLive,
    this.icon,
  });

  /// Resolves the treatment for a channel, most-urgent state first: a failed
  /// setup blocks everything, an unanswered question is the one thing only the
  /// operator can clear, provisioning explains why nothing is moving and a live
  /// run is the ordinary busy state.
  factory ChannelStatusVisual.resolve({
    required ChannelProvisioningStatus status,
    required bool needsInput,
    required bool isLive,
    required DesignSystemTokens tokens,
    required AppLocalizations l10n,
  }) {
    if (status == ChannelProvisioningStatus.failed) {
      return ChannelStatusVisual(
        label: l10n.channelFlyoutSetupFailed,
        dotColor: tokens.fgErrorSecondary,
        textColor: tokens.textErrorPrimary,
        fillColor: tokens.bgErrorPrimary,
        isLive: false,
        icon: AppIcons.triangleAlert,
      );
    }
    if (needsInput) {
      return ChannelStatusVisual(
        label: l10n.channelFlyoutNeedsInput,
        dotColor: tokens.fgWarningSecondary,
        textColor: tokens.textWarningPrimary,
        fillColor: tokens.bgWarningPrimary,
        isLive: false,
        icon: AppIcons.circleHelp,
      );
    }
    if (status == ChannelProvisioningStatus.provisioning) {
      return ChannelStatusVisual(
        label: l10n.channelFlyoutPreparing,
        dotColor: tokens.fgQuaternary,
        textColor: tokens.textTertiary,
        fillColor: tokens.bgSecondary,
        isLive: false,
        icon: AppIcons.loader,
      );
    }
    if (isLive) {
      return ChannelStatusVisual(
        label: l10n.running,
        dotColor: tokens.fgBrandPrimary,
        textColor: tokens.textBrandSecondary,
        fillColor: tokens.bgBrandPrimary,
        isLive: true,
      );
    }
    return ChannelStatusVisual(
      label: l10n.idle,
      dotColor: tokens.fgQuaternary,
      textColor: tokens.textTertiary,
      fillColor: tokens.bgSecondary,
      isLive: false,
    );
  }

  /// Sentence-case state label.
  final String label;

  /// Colour of the leading dot / glyph.
  final Color dotColor;

  /// Colour of the label text.
  final Color textColor;

  /// Subtle fill behind the pill.
  final Color fillColor;

  /// Whether the indicator breathes (running) or holds still.
  final bool isLive;

  /// Glyph paired with the colour for non-running states.
  final IconData? icon;
}

/// The pill form of [ChannelStatusVisual] shown in the flyout header.
class ChannelStatusPill extends StatelessWidget {
  /// Creates a [ChannelStatusPill].
  const ChannelStatusPill({super.key, required this.visual});

  /// The resolved treatment to render.
  final ChannelStatusVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: visual.fillColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (visual.icon != null)
            Icon(visual.icon, size: 11, color: visual.dotColor)
          else
            AgentStatusDot(
              visual: AgentStatusVisual(
                label: visual.label,
                dotColor: visual.dotColor,
                textColor: visual.textColor,
                fillColor: visual.fillColor,
                isLive: visual.isLive,
              ),
              size: 7,
            ),
          const SizedBox(width: 5),
          Text(
            visual.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // Sentence case at the caption size, matching [AgentStatusBadge] —
            // the pill this one is a sibling of — so a state reads identically
            // in the flyout and in the agent detail panel.
            style: CcTypography.caption.copyWith(
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: visual.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// One run in the flyout's live tree: a state indicator (a breathing dot while
/// running, that state's glyph otherwise), the run's name (an agent's display
/// name, or a subagent's task label) and its own elapsed clock.
///
/// Subagent rows carry the same `├`/`└` connector the messaging IDE's AGENTS
/// panel uses, so "spawned by the row above" reads identically in both places.
class ChannelRunRow extends StatelessWidget {
  /// Creates a [ChannelRunRow].
  const ChannelRunRow({
    super.key,
    required this.run,
    required this.label,
    required this.isSubagent,
    required this.isLastChild,
    required this.onPressed,
  });

  /// The live run this row reports.
  final ChannelLiveRun run;

  /// The resolved row label.
  final String label;

  /// Whether this is a spawned subagent (indented, connected, lighter).
  final bool isSubagent;

  /// Whether this is the last sibling — draws `└` instead of `├`.
  final bool isLastChild;

  /// Opens this run.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final visual = AgentStatusVisual.resolve(run.state, t, l10n);

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      semanticLabel: '$label, ${visual.label}',
      builder: (context, states) => Container(
        color: states.contains(WidgetState.hovered)
            ? t.bgSecondaryHover
            : const Color(0x00000000),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            if (isSubagent) RunTreeConnector(isLast: isLastChild),
            // Running breathes as a dot; every other state swaps in its own
            // glyph, so "blocked" and "failed" are distinguishable from
            // "running" by SHAPE and not only by colour — the row has no space
            // for the state's word, so the shape has to carry it (the state name
            // is still announced through [semanticLabel]).
            if (visual.icon != null)
              Icon(
                visual.icon,
                size: isSubagent ? 12 : 13,
                color: visual.dotColor,
              )
            else
              AgentStatusDot(visual: visual, size: isSubagent ? 7 : 8),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.bodySm.copyWith(
                  fontWeight: isSubagent
                      ? CcTypography.regularWeight
                      : FontWeight.w600,
                  color: isSubagent ? t.textSecondary : t.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElapsedTime(since: run.startedAt, color: t.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// A live-ticking duration since [since], set in mono with tabular figures so
/// the digits do not jitter as they count.
///
/// Ticks once a second while mounted — the flyout only exists while hovered, so
/// the timer's life is the hover's life. Reduced motion is not consulted: this
/// is a clock reporting real state, not decoration.
class ElapsedTime extends StatefulWidget {
  /// Creates an [ElapsedTime].
  const ElapsedTime({super.key, required this.since, required this.color});

  /// The moment the clock counts from.
  final DateTime since;

  /// Text colour.
  final Color color;

  @override
  State<ElapsedTime> createState() => _ElapsedTimeState();
}

class _ElapsedTimeState extends State<ElapsedTime> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.since);
    return Text(
      fmtDuration(elapsed.isNegative ? 0 : elapsed.inMilliseconds),
      maxLines: 1,
      style: CcFonts.code(
        textStyle: CcTypography.monoNum,
        family: context.ccTheme?.monoFontFamily,
      ).copyWith(color: widget.color),
    );
  }
}

/// A live context-window gauge for one agent in a channel: `145k / 200k` over a
/// thin fill that warms neutral → amber (≥75%) → red (≥90%).
///
/// Mirrors the estimate that drives auto-compaction, so a full bar means a
/// compaction pass is imminent. Renders nothing when the window or the usage is
/// unknown, rather than showing a meter with no meaning.
class ChannelContextMeter extends ConsumerWidget {
  /// Creates a [ChannelContextMeter].
  const ChannelContextMeter({
    super.key,
    required this.channelId,
    required this.agentId,
  });

  /// The channel whose messages fill the window.
  final String channelId;

  /// The agent whose configured window bounds the meter.
  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final usage = ref.watch(
      conversationContextUsageProvider((
        channelId: channelId,
        agentId: agentId,
      )),
    );
    if (usage.windowTokens <= 0 || usage.usedTokens <= 0) {
      return const SizedBox.shrink();
    }

    final fill = usage.isCritical
        ? t.bgErrorSolid
        : usage.isWarning
        ? t.bgWarningSolid
        : t.bgSuccessSolid;
    final label =
        '${fmtTokens(usage.usedTokens)} / '
        '${fmtTokens(usage.windowTokens)}';

    return Padding(
      // Indented to the run row's label column, so the meter reads as belonging
      // to the agent above it rather than floating between rows.
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Semantics(
        label: l10n.channelFlyoutContextUsage(
          label,
          fmtPercent(usage.fraction),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: _meterHeight,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: t.bgTertiary)),
                    // `heightFactor` is required: with only a width factor the
                    // box passes a LOOSE height to its child and a childless
                    // ColoredBox collapses to zero — an invisible fill over a
                    // visible track, which is how a full window would have read
                    // as an empty one.
                    FractionallySizedBox(
                      widthFactor: usage.fraction.clamp(0.02, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(color: fill),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              maxLines: 1,
              style:
                  CcFonts.code(
                    textStyle: CcTypography.monoNum,
                    family: context.ccTheme?.monoFontFamily,
                  ).copyWith(
                    fontSize: CcTypography.caption.fontSize,
                    color: usage.isWarning ? fill : t.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stroke height of the context meter's track and fill.
const double _meterHeight = 3;

/// Horizontal indent one tree level costs — also the connector's width, so the
/// guide lands under the parent row's status dot.
const double _treeIndent = 16;

/// Where the guide sits inside the connector: the parent dot's centre is
/// `dotRadius` (4) from the row's left edge.
const double _guideInset = 4;

/// Vertical bleed past the connector box so a run of siblings reads as one
/// continuous line instead of dashes.
const double _guideBleed = 4;

/// A `├`/`└` connector drawn to the left of a subagent row.
class RunTreeConnector extends StatelessWidget {
  /// Creates a [RunTreeConnector].
  const RunTreeConnector({super.key, required this.isLast});

  /// Whether this is the last sibling (`└`).
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      width: _treeIndent,
      height: 18,
      child: CustomPaint(
        // Not a border token: `borderSecondary` all but disappears on the
        // panel in dark mode. `fgDisabled` is the faintest foreground that
        // still resolves as a line in both themes.
        painter: _ConnectorPainter(color: t.fgDisabled, isLast: isLast),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({required this.color, required this.isLast});

  final Color color;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final midY = size.height / 2;
    canvas.drawLine(
      const Offset(_guideInset, -_guideBleed),
      Offset(_guideInset, isLast ? midY : size.height + _guideBleed),
      paint,
    );
    canvas.drawLine(
      Offset(_guideInset, midY),
      Offset(size.width - AppSpacing.xxs, midY),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.color != color || old.isLast != isLast;
}

/// An icon + text metadata line inside the flyout (the idle roster).
class HoverCardMetaRow extends StatelessWidget {
  /// Creates a [HoverCardMetaRow].
  const HoverCardMetaRow({super.key, required this.icon, required this.text});

  /// Leading glyph.
  final IconData icon;

  /// The line's text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 13, color: t.textTertiary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: CcTypography.caption.copyWith(
              height: 1.4,
              color: t.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// A mono value over a small uppercase label — the flyout's footer figures.
class HoverCardStat extends StatelessWidget {
  /// Creates a [HoverCardStat].
  const HoverCardStat({
    super.key,
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  /// The figure's name (lowercase in the ARB, rendered uppercase).
  final String label;

  /// The figure itself.
  final String value;

  /// Right-aligns the pair (the trailing stat in a row).
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        // The system's signature eyebrow: mono, uppercase, tracked, at its own
        // 12px size — the figure below it is what carries the weight.
        Text(
          label.toUpperCase(),
          maxLines: 1,
          style: CcFonts.code(
            textStyle: CcTypography.label,
            family: context.ccTheme?.monoFontFamily,
          ).copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          maxLines: 1,
          style: CcFonts.code(
            textStyle: CcTypography.monoNum,
            family: context.ccTheme?.monoFontFamily,
          ).copyWith(color: t.textPrimary),
        ),
      ],
    );
  }
}
