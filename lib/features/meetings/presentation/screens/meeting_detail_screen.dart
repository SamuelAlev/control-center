import 'dart:async';

import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_action_items_tab.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_decisions_tab.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_notes_tab.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_transcript_tab.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final messenger = ScaffoldMessenger.of(context);
    if (segments.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.meetingReRunNoTranscript)));
      return;
    }
    // Kicks off the summary pipeline (async); the meeting reactively moves
    // processing → done as the agent works, so we only confirm the start.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.meetingReRunStarted)));
    await ref
        .read(meetingRecorderControllerProvider.notifier)
        .resummarize(meeting.id);
  }

  void _export(Meeting meeting) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final body = meeting.enhancedNotes?.trim().isNotEmpty == true
        ? meeting.enhancedNotes!.trim()
        : meeting.userNotes.trim();
    if (body.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.meetingExportNothing)));
      return;
    }
    Clipboard.setData(ClipboardData(text: '# ${meeting.title}\n\n$body'));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.meetingExportCopied)));
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
    final decisions = ref
            .watch(meetingDecisionsProvider(key))
            .asData
            ?.value
            .map((d) => d.content)
            .toList() ??
        const <String>[];

    return PageWrapper(
      child: meetingAsync.when(
        loading: () => const Center(child: FCircularProgress()),
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
    List<String> decisions,
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
                _BackLink(
                  label: l10n.meetingBackAllMeetings,
                  onTap: () => context.go(meetingsRoute),
                ),
                const SizedBox(height: AppSpacing.lg),
                _DetailHeader(
                  meeting: meeting,
                  onReRun: () => _reRun(meeting, segments),
                  onExport: () => _export(meeting),
                ),
                if (processing) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _StatusBanner(label: l10n.meetingAugmentingBanner),
                ],
                const SizedBox(height: AppSpacing.xl),
                FTabs(
                  scrollable: true,
                  control: FTabControl.lifted(
                    index: MeetingDetailTab.values.indexOf(_tab),
                    onChange: (i) =>
                        setState(() => _tab = MeetingDetailTab.values[i]),
                  ),
                  children: [
                    FTabEntry(
                      label: const _TabLabel(_notesTabKey),
                      child: MeetingNotesTab(
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
                    FTabEntry(
                      label: _TabLabel(
                        _transcriptTabKey,
                        count: segments.length,
                      ),
                      child: MeetingTranscriptTab(segments: segments),
                    ),
                    FTabEntry(
                      label: _TabLabel(
                        _actionItemsTabKey,
                        count: actionItems.length,
                      ),
                      child: MeetingActionItemsTab(
                        meeting: meeting,
                        actionItems: actionItems,
                      ),
                    ),
                    FTabEntry(
                      label: _TabLabel(
                        _decisionsTabKey,
                        count: decisions.length,
                      ),
                      child: MeetingDecisionsTab(decisions: decisions),
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
// FTabs), so the entries carry a stable key the label widget resolves.
const String _notesTabKey = 'notes';
const String _transcriptTabKey = 'transcript';
const String _actionItemsTabKey = 'actionItems';
const String _decisionsTabKey = 'decisions';

/// A tab label: the localized title (styled by [FTabs] for the selected state)
/// with an optional neutral count chip.
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

class _BackLink extends StatelessWidget {
  const _BackLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FButton(
        variant: FButtonVariant.ghost,
        size: FButtonSizeVariant.sm,
        onPress: onTap,
        prefix: const Icon(LucideIcons.chevronLeft, size: 15),
        child: Text(label),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.meeting,
    required this.onReRun,
    required this.onExport,
  });

  final Meeting meeting;
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
              Text(
                meeting.title,
                style: TextStyle(
                  fontSize: 38,
                  height: 1.04,
                  letterSpacing: -0.8,
                  fontWeight: FontWeight.w600,
                  color: ds.fg,
                ),
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
                            context.go(calendarDetailRoute(event.id)),
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
            FButton(
              variant: FButtonVariant.outline,
              size: FButtonSizeVariant.sm,
              onPress: onReRun,
              prefix: const Icon(LucideIcons.refreshCw, size: 14),
              child: Text(l10n.meetingReRunSummary),
            ),
            FButton(
              variant: FButtonVariant.outline,
              size: FButtonSizeVariant.sm,
              onPress: onExport,
              prefix: const Icon(LucideIcons.download, size: 14),
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
            Icon(LucideIcons.calendar, size: 12, color: ds.accent),
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
