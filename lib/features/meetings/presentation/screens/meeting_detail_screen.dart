import 'dart:async';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_markdown_export.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_file_export.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_action_items_tab.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_decisions_tab.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_detail_row_widgets.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_edit_dialogs.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_notes_tab.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_playback_bar.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_transcript_tab.dart';
import 'package:control_center/features/meetings/presentation/widgets/link_event_sheet.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Which tab the meeting detail is showing.
enum MeetingDetailTab {
  /// Notes split-view.
  notes,

  /// Full transcript.
  transcript,

  /// Extracted action items.
  actionItems,

  /// Extracted decisions.
  decisions,
}

/// Meeting detail: an editorial header, a status banner while the
/// agent is augmenting, and four tabs — Notes (split editor + transcript
/// reference), Transcript, Action items, and Decisions.
class MeetingDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [MeetingDetailScreen] for [meetingId].
  const MeetingDetailScreen({super.key, required this.meetingId});

  /// The meeting being viewed.
  final String meetingId;

  @override
  ConsumerState<MeetingDetailScreen> createState() =>
      _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends ConsumerState<MeetingDetailScreen> {
  MeetingDetailTab _tab = MeetingDetailTab.notes;
  MeetingNotesMode _notesMode = MeetingNotesMode.enhanced;
  final _notesController = TextEditingController();
  Timer? _debounce;
  bool _notesInitialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _onNotesChanged(String value) {
    setState(() => _saving = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      await ref
          .read(meetingRecorderControllerProvider.notifier)
          .updateNotes(widget.meetingId, value);
      if (mounted) {
        setState(() => _saving = false);
      }
    });
  }

  Future<void> _reRun(Meeting meeting, List<MeetingSegment> segments) async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    if (segments.isEmpty) {
      toaster.show(l10n.meetingReRunNoTranscript);
      return;
    }
    // Kicks off the summary pipeline (async); the meeting reactively moves
    // processing → done as the agent works, so we only confirm the start.
    toaster.show(l10n.meetingReRunStarted);
    await ref
        .read(meetingRecorderControllerProvider.notifier)
        .resummarize(meeting.id);
  }

  Future<void> _editTitle(Meeting meeting) {
    final l10n = AppLocalizations.of(context);
    return showCcDialog<void>(
      context: context,
      builder: (_) => MeetingTextFieldDialog(
        title: l10n.meetingEditTitle,
        label: l10n.meetingTitleLabel,
        hint: l10n.meetingRecordTitleHint,
        submitLabel: l10n.save,
        initialValue: meeting.title,
        onSubmit: (value) {
          ref
              .read(meetingRecorderControllerProvider.notifier)
              .updateTitle(meeting.id, value);
        },
      ),
    );
  }

  Future<void> _export(
    Meeting meeting,
    List<MeetingSegment> segments,
    List<MeetingActionItem> actionItems,
    List<MeetingDecision> decisions,
  ) async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    final markdown = buildMeetingMarkdown(
      meeting: meeting,
      segments: segments,
      actionItems: actionItems,
      decisions: decisions,
    );
    if (markdown.trim().isEmpty) {
      toaster.show(l10n.meetingExportNothing);
      return;
    }
    // Offer a Save-as dialog; fall back to the clipboard if the user cancels,
    // so export always does something useful.
    final suggested = '${_safeFileName(meeting.title)}.md';
    final location = await getSaveLocation(
      suggestedName: suggested,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Markdown', extensions: ['md']),
      ],
    );
    if (location == null) {
      await Clipboard.setData(ClipboardData(text: markdown));
      toaster.show(l10n.meetingExportCopied, variant: CcToastVariant.success);
      return;
    }
    try {
      await writeStringToFile(location.path, markdown);
      toaster.show(l10n.meetingExportSaved, variant: CcToastVariant.success);
    } on Object catch (e) {
      toaster.show(l10n.meetingExportFailed('$e'), variant: CcToastVariant.danger);
    }
  }

  static String _safeFileName(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? 'meeting' : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return PageWrapper(
        title: l10n.navMeetings,
        child: Center(child: Text(l10n.meetingsNoWorkspace)),
      );
    }

    final key = (workspaceId: workspaceId, meetingId: widget.meetingId);
    final meetingAsync = ref.watch(meetingDetailProvider(key));
    final segmentsAsync = ref.watch(meetingSegmentsProvider(key));
    final segments = segmentsAsync.asData?.value ?? const <MeetingSegment>[];
    final actionItems = ref.watch(meetingActionItemsProvider(key)).asData?.value ??
        const <MeetingActionItem>[];
    final decisions =
        ref.watch(meetingDecisionsProvider(key)).asData?.value ??
            const <MeetingDecision>[];

    return PageWrapper(
      child: meetingAsync.when(
        loading: () => const Center(child: CcSpinner()),
        error: (e, _) => Center(child: Text('$e')),
        data: (meeting) {
          if (meeting == null) {
            return Center(child: Text(l10n.meetingsEmpty));
          }
          if (!_notesInitialized) {
            _notesController.text = meeting.userNotes;
            _notesInitialized = true;
          }
          return _buildBody(context, l10n, meeting, segments, actionItems, decisions);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    Meeting meeting,
    List<MeetingSegment> segments,
    List<MeetingActionItem> actionItems,
    List<MeetingDecision> decisions,
  ) {
    final processing = meeting.status == MeetingStatus.processing ||
        meeting.status == MeetingStatus.recording;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        96,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailHeader(
                  meeting: meeting,
                  onEditTitle: () => _editTitle(meeting),
                  onReRun: () => _reRun(meeting, segments),
                  onExport: () =>
                      _export(meeting, segments, actionItems, decisions),
                ),
                if (processing) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _StatusBanner(label: l10n.meetingAugmentingBanner),
                ],
                // The per-channel WAVs are still open while recording, so the
                // mixed clip can't be read yet; the bar appears once recording
                // stops (status `processing` onward), when the audio is final.
                if (meeting.audioPath != null &&
                    meeting.status != MeetingStatus.recording) ...[
                  const SizedBox(height: AppSpacing.lg),
                  MeetingPlaybackBar(
                    workspaceId: meeting.workspaceId,
                    meetingId: meeting.id,
                    audioPath: meeting.audioPath,
                    status: meeting.status,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                CcTabView(
                  scrollable: true,
                  selectedIndex: MeetingDetailTab.values.indexOf(_tab),
                  onChanged: (i) =>
                      setState(() => _tab = MeetingDetailTab.values[i]),
                  tabs: [
                    CcTabViewEntry(
                      label: const _TabLabel(_notesTabKey),
                      content: MeetingNotesTab(
                        meeting: meeting,
                        mode: _notesMode,
                        onModeChanged: (m) => setState(() => _notesMode = m),
                        notesController: _notesController,
                        onNotesChanged: _onNotesChanged,
                        savingLabel: _saving
                            ? l10n.meetingNotesSaving
                            : l10n.meetingNotesSavedLocally,
                        segments: segments,
                        onViewFullTranscript: () =>
                            setState(() => _tab = MeetingDetailTab.transcript),
                      ),
                    ),
                    CcTabViewEntry(
                      label: _TabLabel(
                        _transcriptTabKey,
                        count: segments.length,
                      ),
                      content: MeetingTranscriptTab(
                        segments: segments,
                        workspaceId: meeting.workspaceId,
                        meetingId: meeting.id,
                      ),
                    ),
                    CcTabViewEntry(
                      label: _TabLabel(
                        _actionItemsTabKey,
                        count: actionItems.length,
                      ),
                      content: MeetingActionItemsTab(
                        meeting: meeting,
                        actionItems: actionItems,
                      ),
                    ),
                    CcTabViewEntry(
                      label: _TabLabel(
                        _decisionsTabKey,
                        count: decisions.length,
                      ),
                      content: MeetingDecisionsTab(
                        meeting: meeting,
                        decisions: decisions,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Tab-label resolution is deferred to build (needs l10n + selected styling from
// CcTabView), so the entries carry a stable key the label widget resolves.
const String _notesTabKey = 'notes';
const String _transcriptTabKey = 'transcript';
const String _actionItemsTabKey = 'actionItems';
const String _decisionsTabKey = 'decisions';

/// A tab label: the localized title (styled by [CcTabView] for the selected
/// state) with an optional neutral count chip.
class _TabLabel extends StatelessWidget {
  const _TabLabel(this.tabKey, {this.count});

  final String tabKey;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (tabKey) {
      _transcriptTabKey => l10n.meetingTabTranscript,
      _actionItemsTabKey => l10n.meetingTabActionItems,
      _decisionsTabKey => l10n.meetingTabDecisions,
      _ => l10n.meetingTabNotes,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count != null) ...[
          const SizedBox(width: 6),
          _TabCount(count!),
        ],
      ],
    );
  }
}

class _TabCount extends StatelessWidget {
  const _TabCount(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: ds.hoverStrong,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        '$count',
        style: meetingMono(context, fontSize: 11, color: ds.muted),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.meeting,
    required this.onEditTitle,
    required this.onReRun,
    required this.onExport,
  });

  final Meeting meeting;
  final VoidCallback onEditTitle;
  final VoidCallback onReRun;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final bucket = MeetingFormat.bucketFor(meeting.startedAt, now);
    final whenPrefix = switch (bucket) {
      MeetingDayBucket.today => l10n.meetingsBucketToday,
      MeetingDayBucket.yesterday => l10n.meetingsBucketYesterday,
      _ => DateFormat.MMMd(locale).format(meeting.startedAt),
    };
    final when = '$whenPrefix · ${DateFormat.Hm(locale).format(meeting.startedAt)}';
    final duration = MeetingFormat.clock(
      MeetingFormat.duration(meeting.startedAt, meeting.endedAt, now),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: onEditTitle,
                      borderRadius: AppRadii.brSm,
                      child: Text(
                        meeting.title,
                        style: TextStyle(
                          fontSize: 38,
                          height: 1.04,
                          letterSpacing: -0.8,
                          fontWeight: FontWeight.w600,
                          color: ds.fg,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: MeetingRowIconButton(
                      icon: AppIcons.pencil,
                      tooltip: l10n.meetingEditTitle,
                      onTap: onEditTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  Text(when, style: meetingMono(context, fontSize: 12)),
                  Text('·', style: meetingMono(context, fontSize: 12)),
                  Text(duration, style: meetingMono(context, fontSize: 12)),
                  if (meeting.sourceApp != null && meeting.sourceApp!.isNotEmpty) ...[
                    Text('·', style: meetingMono(context, fontSize: 12)),
                    _SourceChip(label: meeting.sourceApp!),
                  ],
                  Consumer(
                    builder: (context, ref, _) {
                      final event = ref
                          .watch(eventForMeetingProvider((
                            workspaceId: meeting.workspaceId,
                            meetingId: meeting.id,
                          )))
                          .asData
                          ?.value;
                      if (event == null) {
                        return const SizedBox.shrink();
                      }
                      return _FromCalendarChip(
                        title: event.title,
                        onTap: () =>
                            context.go(calendarDetailRoute(context.currentWorkspaceId!, event.id)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            _LinkEventButton(meeting: meeting),
            CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: onReRun,
              icon: AppIcons.refreshCw,
              child: Text(l10n.meetingReRunSummary),
            ),
            CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: onExport,
              icon: AppIcons.download,
              child: Text(l10n.meetingExport),
            ),
          ],
        ),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: ds.surface,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: ds.borderSecondary),
      ),
      child: Text(
        label,
        style: meetingMono(context, fontSize: 12, color: ds.fg),
      ),
    );
  }
}

/// A tappable chip shown on a recorded meeting that links back to the calendar
/// event it was recorded for.
class _FromCalendarChip extends StatelessWidget {
  const _FromCalendarChip({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: ds.surface,
          borderRadius: AppRadii.brSm,
          border: Border.all(color: ds.borderSecondary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.calendar, size: 12, color: ds.accent),
            const SizedBox(width: 4),
            Text(
              '${l10n.calendarFromCalendar} · $title',
              style: meetingMono(context, fontSize: 12, color: ds.fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header action that links the meeting to a calendar event (or changes the
/// existing link). Opens the [LinkEventSheet] picker; the label reflects
/// whether the meeting is already linked.
class _LinkEventButton extends ConsumerWidget {
  const _LinkEventButton({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final event = ref
        .watch(eventForMeetingProvider((
          workspaceId: meeting.workspaceId,
          meetingId: meeting.id,
        )))
        .asData
        ?.value;
    final linked = event != null;
    return CcButton(
      variant: CcButtonVariant.secondary,
      size: CcButtonSize.sm,
      onPressed: () => showCcDialog<void>(
        context: context,
        builder: (_) => LinkEventSheet(
          workspaceId: meeting.workspaceId,
          meetingId: meeting.id,
          meetingStartedAt: meeting.startedAt,
          currentEventId: event?.id,
        ),
      ),
      icon: AppIcons.calendar,
      child: Text(linked ? l10n.meetingChangeEvent : l10n.meetingLinkEvent),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.mAccentSoft,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: ds.borderSecondary),
      ),
      child: Row(
        children: [
          MeetingEqualizerBars(color: context.mAccent, height: 12),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: ds.fg),
            ),
          ),
        ],
      ),
    );
  }
}
