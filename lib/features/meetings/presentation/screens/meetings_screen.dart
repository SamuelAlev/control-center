import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_capture_banner.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_list_row.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_stats_strip.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_toolbar.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/live_dot.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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

/// Meetings home: an editorial header with the record CTA,
/// capture stats, the "armed" capture banner, and the day-grouped meeting list
/// with status filters and search.
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
    final controller = ref.read(meetingRecorderControllerProvider.notifier);
    await controller.start();
    if (!mounted) {
      return;
    }
    final state = ref.read(meetingRecorderControllerProvider);
    if (state.isRecording) {
      context.go(meetingsRecordRoute);
    } else if (state.error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.error!)));
    }
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

    return PageWrapper(
      child: meetingsAsync.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => Center(child: Text('$e')),
        data: (meetings) =>
            _buildBody(context, l10n, workspaceId, meetings, recorder),
      ),
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
    final actionStats =
        ref.watch(meetingActionItemStatsProvider(workspaceId)).asData?.value ??
            const {};
    final decisionCounts =
        ref.watch(meetingDecisionCountsProvider(workspaceId)).asData?.value ??
            const {};

    // Aggregate stats over all meetings.
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
    final decisions =
        decisionCounts.values.fold<int>(0, (sum, c) => sum + c);
    final openActions = actionStats.values
        .fold<int>(0, (sum, s) => sum + (s.total - s.done));

    final processingCount = meetings
        .where((m) =>
            m.status == MeetingStatus.processing ||
            m.status == MeetingStatus.recording)
        .length;

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
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
                _PageHead(
                  recorder: recorder,
                  processingCount: processingCount,
                  onRecord: _startRecording,
                  onResume: () => context.go(meetingsRecordRoute),
                ),
                if (recorder.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    recorder.error!,
                    style: TextStyle(color: context.ds.danger),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                MeetingStatsStrip(
                  thisWeek: thisWeek,
                  recorded: recorded,
                  openActions: openActions,
                  decisions: decisions,
                ),
                const SizedBox(height: AppSpacing.lg),
                const MeetingCaptureBanner(),
                const SizedBox(height: AppSpacing.lg),
                _ListPanel(
                  meetings: filtered,
                  now: now,
                  filter: _filter,
                  searchController: _searchController,
                  onFilterChanged: (f) => setState(() => _filter = f),
                  onOpen: (m) => _open(context, l10n, m),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, AppLocalizations l10n, Meeting m) {
    if (m.status == MeetingStatus.processing ||
        m.status == MeetingStatus.recording) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.meetingsStillTranscribing)));
      return;
    }
    context.go(meetingDetailRoute(m.id));
  }
}

/// The editorial header: eyebrow, big title, subtitle, and the record CTA with
/// a "processing now" live pill.
class _PageHead extends StatelessWidget {
  const _PageHead({
    required this.recorder,
    required this.processingCount,
    required this.onRecord,
    required this.onResume,
  });

  final MeetingRecorderState recorder;
  final int processingCount;
  final VoidCallback onRecord;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MeetingEyebrow(l10n.meetingsOverlineKnowledge),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: MeetingEyebrow(
                      l10n.meetingsOverlineEngine,
                      color: ds.muted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.navMeetings,
                style: TextStyle(
                  fontSize: 52,
                  height: 1.0,
                  letterSpacing: -1,
                  fontWeight: FontWeight.w600,
                  color: ds.fg,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  l10n.meetingsSubtitle,
                  style: TextStyle(fontSize: 15, height: 1.5, color: ds.muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _RecordButton(recorder: recorder, onRecord: onRecord, onResume: onResume),
            if (processingCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              _ProcessingPill(count: processingCount),
            ],
          ],
        ),
      ],
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
      return FButton(
        variant: FButtonVariant.primary,
        size: FButtonSizeVariant.sm,
        onPress: onResume,
        prefix: LiveDot(color: context.mDanger, size: 8),
        child: Text(l10n.meetingsRecordingCrumb),
      );
    }
    return FButton(
      variant: FButtonVariant.primary,
      size: FButtonSizeVariant.sm,
      onPress: onRecord,
      prefix: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: context.mDanger, shape: BoxShape.circle),
      ),
      child: Text(l10n.meetingsRecordMeeting),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
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

/// The list panel: a toolbar (scope + search + status filter) over the
/// day-grouped meeting rows, with an empty state when nothing matches.
class _ListPanel extends StatelessWidget {
  const _ListPanel({
    required this.meetings,
    required this.now,
    required this.filter,
    required this.searchController,
    required this.onFilterChanged,
    required this.onOpen,
  });

  final List<Meeting> meetings;
  final DateTime now;
  final MeetingListFilter filter;
  final TextEditingController searchController;
  final ValueChanged<MeetingListFilter> onFilterChanged;
  final ValueChanged<Meeting> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;

    // Group by day bucket, preserving the repository's newest-first order.
    final buckets = <MeetingDayBucket, List<Meeting>>{};
    for (final m in meetings) {
      buckets.putIfAbsent(MeetingFormat.bucketFor(m.startedAt, now), () => [])
          .add(m);
    }

    final children = <Widget>[
      MeetingToolbar(
        filter: filter,
        searchController: searchController,
        onFilterChanged: onFilterChanged,
      ),
    ];

    if (meetings.isEmpty) {
      children.add(_EmptyState(l10n: l10n));
    } else {
      for (final bucket in MeetingDayBucket.values) {
        final rows = buckets[bucket];
        if (rows == null || rows.isEmpty) {
          continue;
        }
        children.add(_DayHeader(bucket: bucket, count: rows.length));
        for (var i = 0; i < rows.length; i++) {
          if (i > 0) {
            children.add(
              Divider(height: 1, thickness: 1, color: ds.borderSecondary),
            );
          }
          children.add(MeetingListRow(
            meeting: rows[i],
            now: now,
            onTap: () => onOpen(rows[i]),
          ));
        }
      }
    }

    return SectionCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.bucket, required this.count});

  final MeetingDayBucket bucket;
  final int count;

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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: ds.rail,
        border: Border(
          top: BorderSide(color: ds.borderSecondary),
          bottom: BorderSide(color: ds.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          Text(label, style: meetingMono(context, fontSize: 12)),
          const Spacer(),
          Text('$count', style: meetingMono(context, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        children: [
          Text(
            l10n.meetingsNoMatch,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ds.fg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.meetingsNoMatchHint,
            style: TextStyle(color: ds.muted),
          ),
        ],
      ),
    );
  }
}
