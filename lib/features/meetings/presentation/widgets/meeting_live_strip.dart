import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_level_meter.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/live_dot.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The live capture strip on the meetings home: the running clock, the meeting
/// being captured, a real input meter and the two things worth doing about it
/// (open the recording view, stop and summarize).
///
/// It exists ONLY while a recording is in flight. The band it occupies is empty
/// the rest of the time — the surface it replaced was a permanent "capture is
/// armed" panel that reported nothing and pushed the actual meeting list below
/// the fold on every visit.
class MeetingLiveStrip extends ConsumerStatefulWidget {
  /// Creates a [MeetingLiveStrip].
  const MeetingLiveStrip({
    super.key,
    required this.title,
    required this.onOpen,
    required this.onStop,
  });

  /// The title of the meeting being recorded, when it has one yet.
  final String? title;

  /// Opens the full record view.
  final VoidCallback onOpen;

  /// Stops the recording and hands it to the summarizer.
  final VoidCallback onStop;

  @override
  ConsumerState<MeetingLiveStrip> createState() => _MeetingLiveStripState();
}

class _MeetingLiveStripState extends ConsumerState<MeetingLiveStrip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // The elapsed clock is derived from the recorder's start time, so the only
    // thing that has to happen every second is a repaint. The strip is mounted
    // only while recording, so the timer lives exactly as long as the state it
    // reports.
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
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final recorder = ref.watch(meetingRecorderControllerProvider);
    if (!recorder.isRecording) {
      return const SizedBox.shrink();
    }
    final live = !recorder.paused;
    final title = widget.title?.trim();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ds.panel,
        border: Border.all(color: ds.lineStrong),
        boxShadow: AppShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // A Wrap, not a Row: this strip carries a clock that must never be
          // clipped, a status word, an optional title and two buttons whose
          // widths depend on the locale. Any pixel budget written here would be
          // wrong in some translation, so the controls drop to a second line
          // instead of overflowing. The two width gates below are about what
          // is WORTH showing, not about what fits.
          final showMeter = width >= 1000;
          final showTitle = width >= 720;
          final compactOpen = width < 900;

          final status = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (live)
                LiveDot(color: ds.danger, size: 9)
              else
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: ds.muted,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                (live ? l10n.meetingStatusRecording : l10n.meetingHudPaused)
                    .toUpperCase(),
                style: meetingMono(
                  context,
                  fontSize: 11,
                  color: live ? ds.danger : ds.muted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                MeetingFormat.clock(recorder.elapsedAt(DateTime.now())),
                style: meetingMono(
                  context,
                  fontSize: 22,
                  color: ds.fg,
                  fontWeight: FontWeight.w500,
                ).copyWith(height: 1),
              ),
              if (showTitle && title != null && title.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.md),
                // Bounded so the group has a measurable width for the Wrap; a
                // long meeting name truncates rather than pushing the controls
                // onto their own line on its own.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: ds.muted),
                  ),
                ),
              ],
              if (showMeter) ...[
                const SizedBox(width: AppSpacing.md),
                MeetingLevelMeter(
                  active: live,
                  color: live ? ds.success : ds.muted,
                  level: recorder.inputLevel,
                  height: 18,
                ),
              ],
            ],
          );

          final openButton = compactOpen
              ? CcIconButton(
                  icon: AppIcons.audioLines,
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  tooltip: l10n.meetingsLiveOpen,
                  onPressed: widget.onOpen,
                )
              : CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  onPressed: widget.onOpen,
                  icon: AppIcons.audioLines,
                  child: Text(l10n.meetingsLiveOpen),
                );
          // Stop keeps its label at every width: guessing which glyph ends a
          // recording is not a risk worth taking.
          final stopButton = CcButton(
            size: CcButtonSize.sm,
            onPressed: widget.onStop,
            icon: AppIcons.square,
            child: Text(l10n.meetingRecordStop),
          );
          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              openButton,
              const SizedBox(width: AppSpacing.sm),
              stopButton,
            ],
          );

          if (width < 480) {
            // Phone-width web. The clock moves to the trailing edge of its own
            // line and the two controls share the next one, so neither group
            // has to hold a fixed-width neighbour.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                status,
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: openButton),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: stopButton),
                  ],
                ),
              ],
            );
          }

          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [status, controls],
          );
        },
      ),
    );
  }
}
