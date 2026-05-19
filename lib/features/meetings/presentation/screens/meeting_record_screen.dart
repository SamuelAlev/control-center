import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_level_meter.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_transcript_row.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/live_dot.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The live recording view: a control bar (timer, title, level meters,
/// pause/stop) over a split of the editable notes pane and the streaming,
/// speaker-attributed transcript.
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
    context.go(meetingDetailRoute(meetingId));
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
          onBack: () => context.go(meetingsRoute),
        ),
      );
    }

    final meetingId = recorder.meetingId!;
    final key = (workspaceId: workspaceId, meetingId: meetingId);
    final meeting = ref.watch(meetingDetailProvider(key)).asData?.value;
    final segments =
        ref.watch(meetingSegmentsProvider(key)).asData?.value ?? const <MeetingSegment>[];

    if (meeting != null && !_initialized) {
      _titleController.text = meeting.title;
      _notesController.text = meeting.userNotes;
      _initialized = true;
    }
    _maybeAutoScroll(segments.length);

    return PageWrapper(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BackLink(
                    label: l10n.navMeetings,
                    onTap: () => context.go(meetingsRoute),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RecordBar(
                    recorder: recorder,
                    titleController: _titleController,
                    sourceApp: meeting?.sourceApp,
                    onTitleChanged: (v) => _onTitleChanged(meetingId, v),
                    onTogglePause: () => ref
                        .read(meetingRecorderControllerProvider.notifier)
                        .togglePause(),
                    onStop: () => _stop(meetingId),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _RecordSplit(
                    notesController: _notesController,
                    onNotesChanged: (v) => _onNotesChanged(meetingId, v),
                    segments: segments,
                    transcriptScroll: _transcriptScroll,
                    paused: recorder.paused,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordBar extends StatelessWidget {
  const _RecordBar({
    required this.recorder,
    required this.titleController,
    required this.sourceApp,
    required this.onTitleChanged,
    required this.onTogglePause,
    required this.onStop,
  });

  final MeetingRecorderState recorder;
  final TextEditingController titleController;
  final String? sourceApp;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onTogglePause;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final active = recorder.isRecording && !recorder.paused;
    final elapsed = recorder.elapsedAt(DateTime.now());
    final source = sourceApp?.isNotEmpty == true
        ? sourceApp!
        : l10n.meetingRecordSystemAudio;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ds.panel,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: ds.lineStrong),
        boxShadow: AppShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The capture-source caption and level meters are reassurance, not
          // controls — drop them first when the bar gets tight so the timer,
          // title, and the pause/stop actions never get clipped.
          final showMeta = constraints.maxWidth >= 840;
          return Row(
            children: [
              active
                  ? LiveDot(color: ds.danger, size: 11)
                  : Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: recorder.paused ? ds.muted : ds.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
              const SizedBox(width: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
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
                child: TextField(
                  controller: titleController,
                  onChanged: onTitleChanged,
                  cursorColor: ds.accent,
                  style: TextStyle(fontSize: 16, color: ds.fg),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: l10n.meetingRecordTitleHint,
                  ),
                ),
              ),
              if (showMeta) ...[
                const SizedBox(width: AppSpacing.md),
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
                MeetingLevelMeter(active: active, color: ds.success, seed: 0),
                const SizedBox(width: 4),
                MeetingLevelMeter(active: active, color: ds.muted, seed: 2.5),
              ],
              const SizedBox(width: AppSpacing.lg),
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                onPressed: onTogglePause,
                icon: recorder.paused ? LucideIcons.play : LucideIcons.pause,
                child: Text(
                  recorder.paused
                      ? l10n.meetingRecordResume
                      : l10n.meetingRecordPause,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CcButton(
                size: CcButtonSize.sm,
                onPressed: onStop,
                icon: LucideIcons.square,
                child: Text(l10n.meetingRecordStop),
              ),
            ],
          );
        },
      ),
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
        if (constraints.maxWidth < 840) {
          return Column(
            children: [
              SizedBox(height: 360, child: notes),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(height: 440, child: transcript),
            ],
          );
        }
        return SizedBox(
          height: 460,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: notes),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: transcript),
            ],
          ),
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
        borderRadius: AppRadii.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
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
    final ds = context.ds;
    return _PaneScaffold(
      icon: LucideIcons.pencil,
      title: l10n.meetingRecordYourNotes,
      trailing: Text(
        l10n.meetingRecordNotesTagline,
        textAlign: TextAlign.right,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: ds.muted),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          cursorColor: ds.accent,
          style: TextStyle(fontSize: 14, height: 1.75, color: ds.fg),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: l10n.meetingRecordNotesPlaceholder,
            hintStyle: TextStyle(fontSize: 14, height: 1.75, color: ds.muted),
          ),
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
    return _PaneScaffold(
      icon: LucideIcons.audioLines,
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
          Text(
            paused ? l10n.meetingRecordPausedHint : l10n.meetingRecordDecoding,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: paused ? ds.muted : ds.success,
            ),
          ),
        ],
      ),
      child: segments.isEmpty
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
              itemCount: segments.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, thickness: 1, color: ds.borderSecondary),
              itemBuilder: (context, i) => MeetingTranscriptRow.fromSegment(
                segments[i],
                compact: true,
                timeColumnWidth: 50,
              ),
            ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CcButton(
        variant: CcButtonVariant.ghost,
        size: CcButtonSize.sm,
        onPressed: onTap,
        icon: LucideIcons.chevronLeft,
        child: Text(label),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: context.ds.muted)),
          const SizedBox(height: AppSpacing.lg),
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            onPressed: onBack,
            child: Text(l10n.navMeetings),
          ),
        ],
      ),
    );
  }
}
