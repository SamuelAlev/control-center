import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Localized label for a ticket status (also used for board columns).
String ticketStatusLabel(AppLocalizations l10n, TicketStatus status) =>
    switch (status) {
      TicketStatus.backlog => l10n.ticketStatusBacklog,
      TicketStatus.open => l10n.ticketStatusOpen,
      TicketStatus.inProgress => l10n.ticketStatusInProgress,
      TicketStatus.blocked => l10n.ticketStatusBlocked,
      TicketStatus.inReview => l10n.ticketStatusInReview,
      TicketStatus.done => l10n.ticketStatusDone,
      TicketStatus.failed => l10n.ticketStatusFailed,
      TicketStatus.cancelled => l10n.ticketStatusCancelled,
    };

/// The semantic foreground color for a status, from the design tokens.
Color ticketStatusColor(DesignSystemTokens t, TicketStatus status) =>
    switch (status) {
      TicketStatus.backlog => t.fgQuaternary,
      TicketStatus.open => t.fgQuaternary,
      TicketStatus.inProgress => t.fgWarningPrimary,
      TicketStatus.blocked => t.fgWarningPrimary,
      TicketStatus.inReview => t.fgSuccessPrimary,
      TicketStatus.done => t.fgBrandPrimary,
      TicketStatus.failed => t.fgErrorPrimary,
      TicketStatus.cancelled => t.fgQuaternary,
    };

/// A subtle column-tint background for the active board lanes (In progress /
/// In review). Other lanes stay neutral.
Color ticketColumnTint(DesignSystemTokens t, TicketStatus status) =>
    switch (status) {
      TicketStatus.inProgress => t.bgWarningPrimary.withValues(alpha: 0.35),
      TicketStatus.inReview => t.bgSuccessPrimary.withValues(alpha: 0.35),
      _ => t.bgSecondary.withValues(alpha: 0.5),
    };

/// A small filled status dot, optionally with a label.
///
/// When [animate] is set and the status is "live" (in progress), the dot
/// emits a slow, soft halo so a running ticket reads as *alive* at a glance —
/// the Living Status Rule from DESIGN.md. The pulse is paired with color and
/// position (never motion alone), and falls back to a static halo ring under
/// `prefers-reduced-motion`, so the running state is still distinguishable.
class TicketStatusDot extends StatefulWidget {
  /// Creates a [TicketStatusDot].
  const TicketStatusDot({
    super.key,
    required this.status,
    this.label,
    this.size = 8,
    this.animate = false,
  });

  /// The status to colour.
  final TicketStatus status;

  /// Optional trailing label.
  final String? label;

  /// Dot diameter.
  final double size;

  /// Whether the dot may breathe when the status is live (in progress). Off in
  /// dense menus and pickers where a moving dot would be noise; on in the
  /// ticket list, board, and group headers where presence is the point.
  final bool animate;

  @override
  State<TicketStatusDot> createState() => _TicketStatusDotState();
}

class _TicketStatusDotState extends State<TicketStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  bool get _isLive => widget.status == TicketStatus.inProgress;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final color = ticketStatusColor(t, widget.status);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final pulsing = widget.animate && _isLive && !reduceMotion;

    // Drive the loop only while it should pulse, so static dots cost nothing.
    if (pulsing) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else if (_controller.isAnimating) {
      _controller.stop();
    }

    final size = widget.size;
    // The halo is laid out larger than the dot so the ring can expand past it.
    final extent = size * 2.6;

    Widget dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    if (pulsing) {
      dot = SizedBox(
        width: extent,
        height: extent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final v = Curves.easeOut.transform(_controller.value);
                final ringSize = size + (extent - size) * v;
                return Opacity(
                  opacity: (1 - v) * 0.5,
                  child: Container(
                    width: ringSize,
                    height: ringSize,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      );
    } else if (widget.animate && _isLive) {
      // Reduced-motion: a static halo ring still marks the live state.
      dot = SizedBox(
        width: extent,
        height: extent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 1.9,
              height: size * 1.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      );
    }

    if (widget.label == null) {
      return dot;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 8),
        Text(
          widget.label!,
          style: TextStyle(
            fontSize: 13,
            height: 1.3,
            color: t.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Localized label for a priority.
String ticketPriorityLabel(AppLocalizations l10n, TicketPriority p) =>
    switch (p) {
      TicketPriority.none => l10n.ticketPriorityNone,
      TicketPriority.urgent => l10n.ticketPriorityUrgent,
      TicketPriority.high => l10n.ticketPriorityHigh,
      TicketPriority.medium => l10n.ticketPriorityMedium,
      TicketPriority.low => l10n.ticketPriorityLow,
    };

/// Priority indicator: three small bars whose filled
/// count reflects the level, with an accent colour for urgent. Optionally
/// shows the label next to the bars.
class TicketPriorityIndicator extends StatelessWidget {
  /// Creates a [TicketPriorityIndicator].
  const TicketPriorityIndicator({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  /// The priority to render.
  final TicketPriority priority;

  /// Whether to show the text label next to the bars.
  final bool showLabel;

  int get _filled => switch (priority) {
    TicketPriority.none => 0,
    TicketPriority.low => 1,
    TicketPriority.medium => 2,
    TicketPriority.high => 3,
    TicketPriority.urgent => 3,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final accent = priority == TicketPriority.urgent
        ? t.fgErrorPrimary
        : t.fgSecondary;
    final faint = t.borderPrimary;

    final bars = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Container(
            width: 3,
            height: 6.0 + i * 3,
            decoration: BoxDecoration(
              color: i < _filled ? accent : faint,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ],
    );

    if (!showLabel) {
      return bars;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        bars,
        const SizedBox(width: 6),
        Text(
          ticketPriorityLabel(l10n, priority),
          style: TextStyle(
            fontSize: 12,
            height: 1.3,
            color: priority == TicketPriority.none
                ? t.textQuaternary
                : t.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A small circular avatar showing an assignee's initial. [name] is the
/// resolved display name (agent name, or "You"); null renders an "unassigned"
/// dashed circle.
class TicketAssigneeAvatar extends StatelessWidget {
  /// Creates a [TicketAssigneeAvatar].
  const TicketAssigneeAvatar({super.key, required this.name, this.size = 22});

  /// Resolved display name, or null for unassigned.
  final String? name;

  /// Avatar diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (name == null || name!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: t.borderPrimary,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Icon(LucideIcons.user, size: size * 0.55, color: t.fgQuaternary),
      );
    }
    final initial = name!.characters.first.toUpperCase();
    return FAvatar.raw(
      size: size,
      child: Text(
        initial,
        style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w600),
      ),
    );
  }
}
