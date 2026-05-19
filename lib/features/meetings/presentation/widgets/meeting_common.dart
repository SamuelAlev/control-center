import 'dart:math' as math;

import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Visual emphasis for a [MeetingSignalPill].
enum MeetingPillTone {
  /// Quiet neutral chip (decisions, defaults).
  neutral,

  /// Orange brand accent (the "enhanced" pill).
  accent,

  /// Caution amber (open action items).
  warn,

  /// Success green (all action items complete).
  success,
}

/// A compact monospaced pill: a small icon plus a label, in one of the
/// [MeetingPillTone]s. Used for the per-row signal chips (decisions, action
/// items, enhanced). Colors come from the design-system tokens.
class MeetingSignalPill extends StatelessWidget {
  /// Creates a [MeetingSignalPill].
  const MeetingSignalPill({
    super.key,
    required this.icon,
    required this.label,
    this.tone = MeetingPillTone.neutral,
  });

  /// Leading glyph.
  final IconData icon;

  /// Pill text.
  final String label;

  /// Color treatment.
  final MeetingPillTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      MeetingPillTone.neutral => (context.mChipFill, context.ds.muted),
      MeetingPillTone.accent => (context.mAccentSoft, context.mAccent),
      MeetingPillTone.warn => (context.mWarnSoft, context.mWarn),
      MeetingPillTone.success => (context.mSuccessSoft, context.mSuccess),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(label, style: meetingMono(context, fontSize: 11, color: fg)),
        ],
      ),
    );
  }
}

/// The leading status glyph for a meeting row / header: a green check when
/// done, an orange equalizer when processing, a red mic when recording.
class MeetingStatusGlyph extends StatelessWidget {
  /// Creates a [MeetingStatusGlyph].
  const MeetingStatusGlyph({super.key, required this.status, this.size = 18});

  /// The meeting's lifecycle status.
  final MeetingStatus status;

  /// Glyph size.
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MeetingStatus.done:
        return Icon(LucideIcons.circleCheck, size: size, color: context.mSuccess);
      case MeetingStatus.processing:
        return MeetingEqualizerBars(color: context.mAccent, height: size * 0.78);
      case MeetingStatus.recording:
        return Icon(LucideIcons.mic, size: size, color: context.mDanger);
      case MeetingStatus.failed:
        return Icon(LucideIcons.circleAlert, size: size, color: context.mDanger);
    }
  }
}

/// A small three-bar equalizer that animates while audio is being processed.
/// Honors the platform "reduce motion" setting by holding the bars static.
class MeetingEqualizerBars extends StatefulWidget {
  /// Creates a [MeetingEqualizerBars].
  const MeetingEqualizerBars({
    super.key,
    required this.color,
    this.height = 12,
    this.barWidth = 2,
    this.barCount = 3,
  });

  /// Bar color.
  final Color color;

  /// Overall height of the tallest bar.
  final double height;

  /// Width of each bar.
  final double barWidth;

  /// Number of bars.
  final int barCount;

  @override
  State<MeetingEqualizerBars> createState() => _MeetingEqualizerBarsState();
}

class _MeetingEqualizerBarsState extends State<MeetingEqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return SizedBox(
      height: widget.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.barCount, (i) {
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final phase = (_controller.value + i / widget.barCount) % 1.0;
                final factor = reduceMotion
                    ? 0.6
                    : 0.3 + 0.7 * (0.5 - 0.5 * math.cos(phase * 2 * math.pi));
                return Container(
                  width: widget.barWidth,
                  height: widget.height * factor,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

/// A monospaced, letter-spaced, uppercase eyebrow label — the design system's
/// signature mono label. Colors come from the design-system tokens.
class MeetingEyebrow extends StatelessWidget {
  /// Creates a [MeetingEyebrow].
  const MeetingEyebrow(this.text, {super.key, this.color});

  /// Eyebrow text (rendered uppercase).
  final String text;

  /// Optional color override.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: meetingMono(
        context,
        fontSize: 11,
        color: color ?? context.ds.muted,
        letterSpacing: 0.8,
      ),
    );
  }
}
