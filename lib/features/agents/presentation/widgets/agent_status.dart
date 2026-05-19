import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/live_dot.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Resolved colours, icon and label for an [AgentLiveState], read from the
/// design system token set so light/dark and contrast come from one place.
class AgentStatusVisual {
  /// Creates an [AgentStatusVisual] with explicit resolved values.
  const AgentStatusVisual({
    required this.label,
    required this.dotColor,
    required this.textColor,
    required this.fillColor,
    required this.isLive,
    this.icon,
    this.filled = true,
  });

  /// Resolves the visual treatment for [state].
  factory AgentStatusVisual.resolve(
    AgentLiveState state,
    DesignSystemTokens tokens,
    AppLocalizations l10n,
  ) {
    switch (state) {
      case AgentLiveState.running:
        return AgentStatusVisual(
          label: l10n.running,
          dotColor: tokens.fgBrandPrimary,
          textColor: tokens.textBrandSecondary,
          fillColor: tokens.bgBrandPrimary,
          isLive: true,
        );
      case AgentLiveState.blocked:
        return AgentStatusVisual(
          label: l10n.blocked,
          dotColor: tokens.fgWarningSecondary,
          textColor: tokens.textWarningPrimary,
          fillColor: tokens.bgWarningPrimary,
          isLive: false,
          icon: LucideIcons.triangleAlert,
        );
      case AgentLiveState.failed:
        return AgentStatusVisual(
          label: l10n.failed,
          dotColor: tokens.fgErrorSecondary,
          textColor: tokens.textErrorPrimary,
          fillColor: tokens.bgErrorPrimary,
          isLive: false,
          icon: LucideIcons.circleX,
        );
      case AgentLiveState.idle:
        return AgentStatusVisual(
          label: l10n.idle,
          dotColor: tokens.fgQuaternary,
          textColor: tokens.textTertiary,
          fillColor: tokens.bgSecondary,
          isLive: false,
        );
      case AgentLiveState.neverRun:
        return AgentStatusVisual(
          label: l10n.noRunsYet,
          dotColor: tokens.fgQuaternary,
          textColor: tokens.textQuaternary,
          fillColor: tokens.bgSecondary,
          isLive: false,
          filled: false,
        );
    }
  }

  /// Human-readable, sentence-case state label.
  final String label;

  /// Colour of the leading dot / icon.
  final Color dotColor;

  /// Colour for the label text.
  final Color textColor;

  /// Subtle fill behind the badge form of the indicator.
  final Color fillColor;

  /// Whether this state breathes (running) vs. holds a static dot.
  final bool isLive;

  /// Optional icon paired with the dot for non-running states.
  final IconData? icon;

  /// Whether the dot is a solid fill (true) or a hollow ring (neverRun).
  final bool filled;
}

/// The status dot alone: a breathing [LiveDot] when running, a solid dot for
/// terminal states, or a hollow ring when the agent has never run.
class AgentStatusDot extends StatelessWidget {
  /// Creates an [AgentStatusDot].
  const AgentStatusDot({super.key, required this.visual, this.size = 8});

  /// The resolved status visual.
  final AgentStatusVisual visual;

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    if (visual.isLive) {
      return LiveDot(color: visual.dotColor, size: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: visual.filled ? visual.dotColor : Colors.transparent,
        shape: BoxShape.circle,
        border: visual.filled
            ? null
            : Border.all(color: visual.dotColor, width: 1.5),
      ),
    );
  }
}

/// Compact inline indicator for a roster row: status dot + sentence-case label.
class AgentStatusIndicator extends StatelessWidget {
  /// Creates an [AgentStatusIndicator].
  const AgentStatusIndicator({super.key, required this.state});

  /// The agent's derived live state.
  final AgentLiveState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final visual = AgentStatusVisual.resolve(state, tokens, l10n);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AgentStatusDot(visual: visual),
        const SizedBox(width: 6),
        Text(
          visual.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: visual.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Pill form of the status, used in the detail panel header.
class AgentStatusBadge extends StatelessWidget {
  /// Creates an [AgentStatusBadge].
  const AgentStatusBadge({super.key, required this.state});

  /// The agent's derived live state.
  final AgentLiveState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final visual = AgentStatusVisual.resolve(state, tokens, l10n);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: visual.fillColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (visual.icon != null)
            Icon(visual.icon, size: 12, color: visual.dotColor)
          else
            AgentStatusDot(visual: visual, size: 8),
          const SizedBox(width: 6),
          Text(
            visual.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: visual.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
