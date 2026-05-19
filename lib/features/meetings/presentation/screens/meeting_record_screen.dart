import 'dart:async';

import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_diarization.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_detection_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_toolbar_controller.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_notes_editor.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_level_meter.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_transcript_row.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_template_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/live_dot.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The widest the record column grows before it stops tracking the viewport.
const double _kContentMaxWidth = 1400.0;

/// Below this the two panes stack instead of sitting side by side.
const double _kSplitBreakpoint = 880.0;

/// The live recording view: the running clock, the editable title and the
/// pause/stop controls live in the page header (pinned, so they never scroll
/// away), over a split of the notes pane and the streaming, speaker-attributed
/// transcript.
///
/// The header replaces a card that used to scroll with the body, and the
/// template picker and privacy notice — previously two more full-width bands
/// above the content — now sit on the notes pane they actually describe and in
/// a single footer line.
class MeetingRecordScreen extends ConsumerStatefulWidget {
  /// Creates a [MeetingRecordScreen].
  const MeetingRecordScreen({super.key});

  @override
  ConsumerState<MeetingRecordScreen> createState() =>
      _MeetingRecordScreenState();
}

class _MeetingRecordScreenState extends ConsumerState<MeetingRecordScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _transcriptScroll = ScrollController();
  Timer? _ticker;
  Timer? _titleDebounce;
  Timer? _notesDebounce;
  bool _initialized = false;
  int _lastSegmentCount = 0;

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
    _titleDebounce?.cancel();
    _notesDebounce?.cancel();
    _titleController.dispose();
    _notesController.dispose();
    _transcriptScroll.dispose();
    super.dispose();
  }

  void _onTitleChanged(String meetingId, String value) {
    _titleDebounce?.cancel();
    _titleDebounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(meetingRecorderControllerProvider.notifier)
          .updateTitle(meetingId, value);
    });
  }

  void _onNotesChanged(String meetingId, String value) {
    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(meetingRecorderControllerProvider.notifier)
          .updateNotes(meetingId, value);
    });
  }

  void _stop(String meetingId) {
    // Fire-and-forget: stop() drives the meeting through processing → done in
    // the background while we jump straight to its detail, which reflects the
    // status reactively.
    unawaited(ref.read(meetingRecorderControllerProvider.notifier).stop());
    context.go(meetingDetailRoute(context.currentWorkspaceId!, meetingId));
  }

  void _maybeAutoScroll(int segmentCount) {
    if (segmentCount == _lastSegmentCount) {
      return;
    }
    _lastSegmentCount = segmentCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transcriptScroll.hasClients) {
        _transcriptScroll.jumpTo(_transcriptScroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final recorder = ref.watch(meetingRecorderControllerProvider);

    if (workspaceId == null || recorder.meetingId == null) {
      return PageWrapper(
        child: _NotRecording(
          label: l10n.meetingRecordNotActive,
          onBack: () => context.go(meetingsRoute(context.currentWorkspaceId!)),
        ),
      );
    }

    final meetingId = recorder.meetingId!;
    final key = (workspaceId: workspaceId, meetingId: meetingId);
    final meeting = ref.watch(meetingDetailProvider(key)).asData?.value;
    final segments =
        ref.watch(meetingSegmentsProvider(key)).asData?.value ??
        const <MeetingSegment>[];

    if (meeting != null && !_initialized) {
      _titleController.text = meeting.title;
      _notesController.text = meeting.userNotes;
      _initialized = true;
    }
    _maybeAutoScroll(segments.length);

    final suggestAutoStop = ref
        .watch(meetingDetectionControllerProvider)
        .suggestAutoStop;

    return PageWrapper(
      overline: _CaptureLine(recorder: recorder, sourceApp: meeting?.sourceApp),
      titleWidget: _RecordTitle(
        recorder: recorder,
        controller: _titleController,
        onChanged: (v) => _onTitleChanged(meetingId, v),
      ),
      actions: [
        // Pop-out is the one control here that can lose its label without
        // ambiguity; pause and stop keep theirs at every width, because
        // guessing which glyph ends a recording is not a risk worth taking.
        if (meetingCompactActions(context))
          CcIconButton(
            icon: AppIcons.pictureInPicture2,
            size: CcButtonSize.sm,
            tooltip: l10n.meetingToolbarPopOut,
            onPressed: () =>
                ref.read(meetingToolbarControllerProvider.notifier).open(),
          )
        else
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () =>
                ref.read(meetingToolbarControllerProvider.notifier).open(),
            icon: AppIcons.pictureInPicture2,
            child: Text(l10n.meetingToolbarPopOut),
          ),
        const SizedBox(width: AppSpacing.sm),
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          onPressed: () => ref
              .read(meetingRecorderControllerProvider.notifier)
              .togglePause(),
          icon: recorder.paused ? AppIcons.play : AppIcons.pause,
          child: Text(
            recorder.paused
                ? l10n.meetingRecordResume
                : l10n.meetingRecordPause,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        CcButton(
          size: CcButtonSize.sm,
          onPressed: () => _stop(meetingId),
          icon: AppIcons.square,
          child: Text(l10n.meetingRecordStop),
        ),
      ],
      // Left-aligned so the capped column starts at the same inset as the
      // pinned header above it (see the meetings list for the same note).
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (recorder.micWarning && !recorder.paused) ...[
                  const _MicWarningBanner(),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (suggestAutoStop) ...[
                  _AutoStopBanner(onStop: () => _stop(meetingId)),
                  const SizedBox(height: AppSpacing.md),
                ],
                Expanded(
                  child: _RecordSplit(
                    notesController: _notesController,
                    onNotesChanged: (v) => _onNotesChanged(meetingId, v),
                    segments: segments,
                    transcriptScroll: _transcriptScroll,
                    paused: recorder.paused,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _SummaryPrivacyNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The page overline while recording: a link back to the list on the left, and
/// on the right what is actually being tapped plus the two live meters. The
/// meters are reassurance, not controls, so they are the first thing dropped
/// when the row gets tight.
class _CaptureLine extends StatelessWidget {
  const _CaptureLine({required this.recorder, required this.sourceApp});

  final MeetingRecorderState recorder;
  final String? sourceApp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final active = recorder.isRecording && !recorder.paused;
    final source = sourceApp?.isNotEmpty ?? false
        ? sourceApp!
        : l10n.meetingRecordSystemAudio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showMeta = constraints.maxWidth >= 700;
        return Row(
          children: [
            CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: () =>
                  context.go(meetingsRoute(context.currentWorkspaceId!)),
              icon: AppIcons.chevronLeft,
              child: Text(l10n.meetingBackAllMeetings),
            ),
            const Spacer(),
            if (showMeta) ...[
              Flexible(
                child: Text.rich(
                  TextSpan(
                    style: meetingMono(context, fontSize: 12),
                    children: [
                      TextSpan(text: '${l10n.meetingRecordTappingLabel} '),
                      TextSpan(
                        text: source,
                        style: meetingMono(context, fontSize: 12, color: ds.fg),
                      ),
                      const TextSpan(text: ' + '),
                      TextSpan(
                        text: l10n.meetingRecordMic,
                        style: meetingMono(context, fontSize: 12, color: ds.fg),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              MeetingLevelMeter(
                active: active,
                color: ds.success,
                seed: 0,
                level: recorder.inputLevel,
                height: 18,
              ),
              const SizedBox(width: 4),
              MeetingLevelMeter(
                active: active,
                color: ds.muted,
                seed: 2.5,
                height: 18,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The page title while recording: the live state dot, the running clock and
/// the meeting's own name, editable in place.
class _RecordTitle extends StatelessWidget {
  const _RecordTitle({
    required this.recorder,
    required this.controller,
    required this.onChanged,
  });

  final MeetingRecorderState recorder;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final active = recorder.isRecording && !recorder.paused;
    final elapsed = recorder.elapsedAt(DateTime.now());

    return Row(
      children: [
        if (active)
          LiveDot(color: ds.danger, size: 11)
        else
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: recorder.paused ? ds.muted : ds.danger,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: AppSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            MeetingFormat.clock(elapsed),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: meetingMono(
              context,
              fontSize: 30,
              color: ds.fg,
              fontWeight: FontWeight.w500,
            ).copyWith(height: 1),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: CcTextField(
            controller: controller,
            onChanged: onChanged,
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ds.fg,
            ),
            hintText: l10n.meetingRecordTitleHint,
            chromeless: true,
          ),
        ),
      ],
    );
  }
}

class _RecordSplit extends StatelessWidget {
  const _RecordSplit({
    required this.notesController,
    required this.onNotesChanged,
    required this.segments,
    required this.transcriptScroll,
    required this.paused,
  });

  final TextEditingController notesController;
  final ValueChanged<String> onNotesChanged;
  final List<MeetingSegment> segments;
  final ScrollController transcriptScroll;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final notes = _NotesPane(
      controller: notesController,
      onChanged: onNotesChanged,
    );
    final transcript = _LiveTranscriptPane(
      segments: segments,
      scroll: transcriptScroll,
      paused: paused,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _kSplitBreakpoint) {
          // Stacked, the panes need their own scroll: the transcript is the one
          // that grows without bound, so it takes the larger share.
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(height: 320, child: notes),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(height: 440, child: transcript),
            ],
          );
        }
        // Side by side the panes fill the viewport instead of a fixed 460px, so
        // a tall window shows more transcript rather than more empty canvas.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: notes),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: transcript),
          ],
        );
      },
    );
  }
}

class _PaneScaffold extends StatelessWidget {
  const _PaneScaffold({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return SectionCard(
      expands: true,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadii.brMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: ds.borderSecondary)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: ds.muted),
                  const SizedBox(width: AppSpacing.sm),
                  MeetingEyebrow(title),
                  const Spacer(),
                  Flexible(child: trailing),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _NotesPane extends StatelessWidget {
  const _NotesPane({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _PaneScaffold(
      icon: AppIcons.pencil,
      title: l10n.meetingRecordYourNotes,
      // The template shapes the summary these notes become, so it belongs on
      // this pane rather than on a band of its own above the page.
      trailing: const _TemplateSelect(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: MeetingNotesEditor(
          controller: controller,
          onChanged: onChanged,
          hintText: l10n.meetingRecordNotesPlaceholder,
          minLines: 6,
        ),
      ),
    );
  }
}

class _LiveTranscriptPane extends StatelessWidget {
  const _LiveTranscriptPane({
    required this.segments,
    required this.scroll,
    required this.paused,
  });

  final List<MeetingSegment> segments;
  final ScrollController scroll;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    // Merge consecutive same-speaker windows into coherent turns and drop
    // chunk-boundary duplicates, so the live transcript reads cleanly instead
    // of as choppy 1.5–5 s fragments.
    final rows = mergeConsecutiveTurns(segments);
    return _PaneScaffold(
      icon: AppIcons.audioLines,
      title: l10n.meetingRecordLiveTranscript,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: paused ? ds.muted : ds.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              paused
                  ? l10n.meetingRecordPausedHint
                  : l10n.meetingRecordDecoding,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: paused ? ds.muted : ds.success,
              ),
            ),
          ),
        ],
      ),
      child: rows.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  l10n.meetingRecordListening,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: ds.muted),
                ),
              ),
            )
          : ListView.separated(
              controller: scroll,
              padding: EdgeInsets.zero,
              itemCount: rows.length,
              separatorBuilder: (_, _) => CcDivider(color: ds.borderSecondary),
              itemBuilder: (context, i) => MeetingTranscriptRow.fromSegment(
                rows[i],
                compact: true,
                timeColumnWidth: 50,
              ),
            ),
    );
  }
}

/// States where the meeting actually gets processed.
///
/// Capture, transcription and diarization all run on this host, but the
/// summary is an ordinary agent run — so it goes wherever that agent's model
/// lives. The product presents meetings as an on-device feature, which makes
/// the summary step the one place that quietly is not and a recording is
/// exactly the wrong thing to learn that about afterwards.
///
/// It reads as a footnote now rather than a boxed banner above the content, but
/// it is still on screen for the whole recording, which is what the disclosure
/// requires.
class _SummaryPrivacyNotice extends StatelessWidget {
  const _SummaryPrivacyNotice();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(AppIcons.info, size: 13, color: ds.muted),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            l10n.meetingSummaryPrivacyNotice,
            style: TextStyle(fontSize: 12, color: ds.muted, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _MicWarningBanner extends StatelessWidget {
  const _MicWarningBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcAlert(
      variant: CcAlertVariant.danger,
      icon: AppIcons.micOff,
      title: l10n.meetingMicSilentWarning,
    );
  }
}

/// Lets the user pick the meeting-note template that will shape this meeting's
/// summary. Bound to the persisted selection that `stop()` / "Re-run summary"
/// read, so choosing it here applies to this recording's summary (and stays the
/// default for the next one).
class _TemplateSelect extends ConsumerWidget {
  const _TemplateSelect();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final templates = ref.watch(meetingTemplatesProvider);
    final activeId = ref.watch(selectedMeetingTemplateProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(AppIcons.layoutTemplate, size: 13, color: ds.muted),
        const SizedBox(width: 6),
        Text(
          l10n.meetingTemplateShort,
          style: meetingMono(context, fontSize: 11),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: CcSelect<String>(
              value: activeId,
              options: [
                for (final t in templates)
                  CcSelectOption(value: t.id, label: t.name),
              ],
              onChanged: ref
                  .read(selectedMeetingTemplateProvider.notifier)
                  .select,
            ),
          ),
        ),
      ],
    );
  }
}

/// Surfaced while recording when detection believes the meeting has ended:
/// offers to stop, or to dismiss and keep going.
class _AutoStopBanner extends ConsumerWidget {
  const _AutoStopBanner({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return CcAlert(
      variant: CcAlertVariant.warning,
      icon: AppIcons.circleStop,
      title: l10n.meetingAutoStopTitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () => ref
                .read(meetingDetectionControllerProvider.notifier)
                .clearAutoStop(),
            child: Text(l10n.meetingAutoStopKeep),
          ),
          const SizedBox(width: AppSpacing.sm),
          CcButton(
            size: CcButtonSize.sm,
            onPressed: onStop,
            child: Text(l10n.meetingAutoStopStop),
          ),
        ],
      ),
    );
  }
}

class _NotRecording extends StatelessWidget {
  const _NotRecording({required this.label, required this.onBack});

  final String label;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcEmptyState(
      icon: AppIcons.micOff,
      iconSize: 32,
      message: label,
      action: CcButton(
        variant: CcButtonVariant.secondary,
        size: CcButtonSize.sm,
        onPressed: onBack,
        icon: AppIcons.chevronLeft,
        child: Text(l10n.meetingBackAllMeetings),
      ),
    );
  }
}
