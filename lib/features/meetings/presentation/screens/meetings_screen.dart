import 'dart:async';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_ui/cc_ui.dart';

import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_detection_banner.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_ledger_strip.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_list_row.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_live_strip.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_toolbar.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/inline_load_error.dart';
import 'package:control_center/shared/widgets/live_dot.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The status filter applied to the meetings list.
enum MeetingListFilter {
  /// Every meeting.
  all,

  /// Finalized meetings only.
  done,

  /// Meetings still recording or summarizing.
  processing,
}

/// Meetings home: the standard page header carrying a live subtitle and the
/// record CTA, the capture ledger, the toolbar and one section card per day
/// bucket.
///
/// The two full-width panels that used to sit between the header and the list —
/// a four-card stat grid and a permanent "capture is armed" pitch — are gone.
/// The numbers survive as a single mono ledger line and the band they occupied
/// is now used only when something is actually recording.
class MeetingsScreen extends ConsumerStatefulWidget {
  /// Creates a [MeetingsScreen].
  const MeetingsScreen({super.key});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  MeetingListFilter _filter = MeetingListFilter.all;
  final _searchController = TextEditingController();
  String _query = '';

  /// Day buckets the operator has folded away. Session-scoped on purpose: a
  /// collapsed "Older" should not still be hiding meetings a week later.
  final _collapsed = <MeetingDayBucket>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_query != _searchController.text) {
      setState(() => _query = _searchController.text);
    }
  }

  Future<void> _startRecording() async {
    // Recording needs audio capture and a speech model on the host; a demo
    // ships neither and `meeting.startRecording` is refused. Say so in the
    // demo's own words rather than letting the controller surface a raw
    // transport error in a red toast.
    if (ref.read(isDemoServerProvider)) {
      CcToastScope.of(
        context,
      ).show(AppLocalizations.of(context).demoUnavailableAudio);
      return;
    }
    final ws = context.currentWorkspaceId!;
    final controller = ref.read(meetingRecorderControllerProvider.notifier);
    await controller.start();
    if (!mounted) {
      return;
    }
    final state = ref.read(meetingRecorderControllerProvider);
    if (state.isRecording) {
      context.go(meetingsRecordRoute(ws));
    } else if (state.error != null) {
      CcToastScope.of(
        context,
      ).show(state.error!, variant: CcToastVariant.danger);
    }
  }

  void _openRecording() =>
      context.go(meetingsRecordRoute(context.currentWorkspaceId!));

  void _stopRecording() {
    // Fire-and-forget: stop() drives the meeting through processing → done in
    // the background and the list reflects that reactively.
    unawaited(ref.read(meetingRecorderControllerProvider.notifier).stop());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return PageWrapper(
        title: l10n.navMeetings,
        child: Center(
          child: Text(
            l10n.meetingsNoWorkspace,
            style: TextStyle(color: context.ds.muted),
          ),
        ),
      );
    }

    final meetingsAsync = ref.watch(meetingsProvider(workspaceId));
    final recorder = ref.watch(meetingRecorderControllerProvider);
    final meetings = meetingsAsync.asData?.value ?? const <Meeting>[];
    // Summarizing only. A meeting that is still *recording* is reported by the
    // live strip, in far more detail and with the controls to act on it — the
    // pill counting it too would say the same thing twice in one header.
    final processingCount = meetings
        .where((m) => m.status == MeetingStatus.processing)
        .length;

    return PageWrapper(
      title: l10n.navMeetings,
      // One short line about what the page is, where three lines of product
      // pitch used to sit. Live state has its own homes and is deliberately
      // not repeated here: the processing pill, the live strip and the ledger
      // each own exactly one fact.
      subtitle: l10n.meetingsSubtitle,
      actions: [
        if (processingCount > 0) _ProcessingPill(count: processingCount),
        _RecordButton(
          recorder: recorder,
          onRecord: _startRecording,
          onResume: _openRecording,
        ),
      ],
      child: meetingsAsync.when(
        loading: () => const Center(child: CcSpinner()),
        error: (e, _) => InlineLoadError(e),
        data: (data) => _buildBody(context, l10n, workspaceId, data, recorder),
      ),
    );
  }

  /// The four ledger numbers, folded over the meeting list once.
  _MeetingAggregate _aggregate(
    String workspaceId,
    List<Meeting> meetings,
    DateTime now,
  ) {
    final actionStats =
        ref.watch(meetingActionItemStatsProvider(workspaceId)).asData?.value ??
        const {};
    final decisionCounts =
        ref.watch(meetingDecisionCountsProvider(workspaceId)).asData?.value ??
        const {};

    var thisWeek = 0;
    var recorded = Duration.zero;
    for (final m in meetings) {
      final bucket = MeetingFormat.bucketFor(m.startedAt, now);
      if (bucket == MeetingDayBucket.today ||
          bucket == MeetingDayBucket.yesterday ||
          bucket == MeetingDayBucket.earlierThisWeek) {
        thisWeek++;
      }
      if (m.endedAt != null) {
        recorded += MeetingFormat.duration(m.startedAt, m.endedAt, now);
      }
    }
    return (
      thisWeek: thisWeek,
      recorded: recorded,
      openActions: actionStats.values.fold<int>(
        0,
        (sum, s) => sum + (s.total - s.done),
      ),
      decisions: decisionCounts.values.fold<int>(0, (sum, c) => sum + c),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    String workspaceId,
    List<Meeting> meetings,
    MeetingRecorderState recorder,
  ) {
    final now = DateTime.now();
    final stats = _aggregate(workspaceId, meetings, now);

    final query = _query.trim().toLowerCase();
    final filtered = meetings.where((m) {
      switch (_filter) {
        case MeetingListFilter.done:
          if (m.status != MeetingStatus.done) {
            return false;
          }
        case MeetingListFilter.processing:
          if (m.status != MeetingStatus.processing &&
              m.status != MeetingStatus.recording) {
            return false;
          }
        case MeetingListFilter.all:
          break;
      }
      if (query.isNotEmpty) {
        final hay = '${m.title} ${m.sourceApp ?? ''}'.toLowerCase();
        if (!hay.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Group by day bucket, preserving the repository's newest-first order.
    final buckets = <MeetingDayBucket, List<Meeting>>{};
    for (final m in filtered) {
      buckets
          .putIfAbsent(MeetingFormat.bucketFor(m.startedAt, now), () => [])
          .add(m);
    }

    Meeting? recordingMeeting;
    for (final m in meetings) {
      if (m.id == recorder.meetingId) {
        recordingMeeting = m;
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      // Uncapped: the body tracks the viewport, so it shares the header's 24px
      // right inset instead of stopping short of the record CTA above it.
      children: [
        const MeetingDetectionBanner(),
        if (recorder.error != null) ...[
          CcAlert(variant: CcAlertVariant.danger, title: recorder.error!),
          const SizedBox(height: AppSpacing.lg),
        ],
        // Present only while something is being captured. When nothing
        // is, this band costs nothing.
        if (recorder.isRecording) ...[
          MeetingLiveStrip(
            title: recordingMeeting?.title,
            onOpen: _openRecording,
            onStop: _stopRecording,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        MeetingLedgerStrip(
          thisWeek: stats.thisWeek,
          recorded: stats.recorded,
          openActions: stats.openActions,
          decisions: stats.decisions,
        ),
        const SizedBox(height: AppSpacing.lg),
        MeetingToolbar(
          filter: _filter,
          searchController: _searchController,
          onFilterChanged: (f) => setState(() => _filter = f),
          resultCount: filtered.length,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (filtered.isEmpty)
          meetings.isEmpty
              ? _FirstMeetingState(
                  l10n: l10n,
                  recorder: recorder,
                  onRecord: _startRecording,
                  onResume: _openRecording,
                )
              : _NoMatchState(l10n: l10n)
        else
          // One card per day bucket. An empty bucket renders nothing at
          // all, so a quiet week is a short page rather than a page of
          // empty headers.
          for (final bucket in MeetingDayBucket.values)
            if (buckets[bucket]?.isNotEmpty ?? false) ...[
              _DaySection(
                bucket: bucket,
                meetings: buckets[bucket]!,
                now: now,
                collapsed: _collapsed.contains(bucket),
                onToggle: () => setState(() {
                  if (!_collapsed.remove(bucket)) {
                    _collapsed.add(bucket);
                  }
                }),
                onOpen: (m) => _open(context, l10n, m),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
      ],
    );
  }

  void _open(BuildContext context, AppLocalizations l10n, Meeting m) {
    if (m.status == MeetingStatus.processing ||
        m.status == MeetingStatus.recording) {
      CcToastScope.of(context).show(l10n.meetingsStillTranscribing);
      return;
    }
    context.go(meetingDetailRoute(context.currentWorkspaceId!, m.id));
  }
}

/// The four aggregate numbers the header and the ledger both read.
typedef _MeetingAggregate = ({
  int thisWeek,
  Duration recorded,
  int openActions,
  int decisions,
});

/// One day bucket: a collapsible header row carrying the day's name and count,
/// over that day's rows.
///
/// The header follows the app's section-card vocabulary (chevron, count chip,
/// semibold label, no filled band) so a day of meetings reads like a section of
/// the inbox or the pull-request queue rather than like a table sub-head.
class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.bucket,
    required this.meetings,
    required this.now,
    required this.collapsed,
    required this.onToggle,
    required this.onOpen,
  });

  final MeetingDayBucket bucket;
  final List<Meeting> meetings;
  final DateTime now;
  final bool collapsed;
  final VoidCallback onToggle;
  final ValueChanged<Meeting> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final label = switch (bucket) {
      MeetingDayBucket.today => l10n.meetingsBucketToday,
      MeetingDayBucket.yesterday => l10n.meetingsBucketYesterday,
      MeetingDayBucket.earlierThisWeek => l10n.meetingsBucketEarlierThisWeek,
      MeetingDayBucket.lastWeek => l10n.meetingsBucketLastWeek,
      MeetingDayBucket.older => l10n.meetingsBucketOlder,
    };

    return SectionCard(
      padding: EdgeInsets.zero,
      // The header hover wash and the row washes must stop at the card's
      // hairline rather than paint over it.
      child: ClipRRect(
        borderRadius: AppRadii.brMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CcTappable(
              onPressed: onToggle,
              semanticLabel: '$label · ${meetings.length}',
              builder: (context, states) => ColoredBox(
                color: states.contains(WidgetState.hovered)
                    ? ds.hover
                    : const Color(0x00000000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: collapsed ? -0.25 : 0,
                        duration: CcMotion.resolve(context, CcMotion.fast),
                        child: Icon(
                          AppIcons.chevronDown,
                          size: 16,
                          color: ds.muted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _DayCount(count: meetings.length),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CcTypography.body.copyWith(
                            color: ds.fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: CcMotion.resolve(context, CcMotion.normal),
              curve: CcMotion.standard,
              alignment: Alignment.topCenter,
              child: collapsed
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CcDivider(color: ds.borderSecondary),
                        for (var i = 0; i < meetings.length; i++) ...[
                          if (i > 0) CcDivider(color: ds.borderSoft),
                          MeetingListRow(
                            meeting: meetings[i],
                            now: now,
                            onTap: () => onOpen(meetings[i]),
                          ),
                        ],
                      ],
                    ),
            ),
            if (collapsed) const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

/// The day's meeting count, in the app's shared count-chip treatment (mono on
/// the hover-strong wash).
class _DayCount extends StatelessWidget {
  const _DayCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ds.hoverStrong,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
      ),
      child: Text(
        '$count',
        style: meetingMono(context, fontSize: 11, color: ds.muted),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.recorder,
    required this.onRecord,
    required this.onResume,
  });

  final MeetingRecorderState recorder;
  final VoidCallback onRecord;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Summarization runs as a pipeline now, so the recorder never sits in a
    // "processing" state — it returns to idle right after stop. The "N
    // processing now" pill (driven by meeting-row status) shows that progress.
    if (recorder.isRecording) {
      return CcButton(
        variant: CcButtonVariant.primary,
        size: CcButtonSize.sm,
        onPressed: onResume,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LiveDot(color: context.mDanger, size: 8),
            const SizedBox(width: 8),
            Text(l10n.meetingsRecordingCrumb),
          ],
        ),
      );
    }
    return CcButton(
      variant: CcButtonVariant.primary,
      size: CcButtonSize.sm,
      onPressed: onRecord,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.mDanger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(l10n.meetingsRecordMeeting),
        ],
      ),
    );
  }
}

class _ProcessingPill extends StatelessWidget {
  const _ProcessingPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: ds.panel,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: ds.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveDot(color: context.mSuccess, size: 8),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.meetingsProcessingNow(count),
            style: meetingMono(context, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Shown when no meeting has ever been recorded: what the feature does and
/// the record CTA. This is the one place the product pitch belongs — it used
/// to run as a permanent banner above every visit's list.
class _FirstMeetingState extends StatelessWidget {
  const _FirstMeetingState({
    required this.l10n,
    required this.recorder,
    required this.onRecord,
    required this.onResume,
  });

  final AppLocalizations l10n;
  final MeetingRecorderState recorder;
  final VoidCallback onRecord;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxxl,
      ),
      child: CcEmptyState(
        icon: AppIcons.audioLines,
        iconSize: 32,
        maxWidth: 460,
        message: l10n.meetingsEmpty,
        description: l10n.meetingsEmptyHint,
        action: _RecordButton(
          recorder: recorder,
          onRecord: onRecord,
          onResume: onResume,
        ),
      ),
    );
  }
}

/// Shown when filters or the search box exclude everything.
class _NoMatchState extends StatelessWidget {
  const _NoMatchState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: CcEmptyState(
        icon: AppIcons.searchX,
        iconSize: 28,
        message: l10n.meetingsNoMatch,
        description: l10n.meetingsNoMatchHint,
      ),
    );
  }
}
