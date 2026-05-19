import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/run_transcript_relay_port.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/agents/providers/run_activity_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_activity_header.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/transcript_flow.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How close to the bottom counts as "following" the live tail, in pixels.
const double _kFollowThreshold = 48;

/// One agent run's activity timeline, as an editor tab body.
///
/// The surface a spawned subagent otherwise has nowhere to live: its tool calls,
/// reasoning and text never become chat messages, so the conversation cannot
/// show them. Streams live while the run executes and replays the persisted
/// record afterwards — the server's relay op serves both.
class AgentActivityPane extends ConsumerStatefulWidget {
  /// Creates an [AgentActivityPane].
  const AgentActivityPane({
    super.key,
    required this.workspaceId,
    required this.channelId,
    required this.runId,
    required this.agentId,
    this.fallbackLabel,
  }) : _unavailable = false;

  /// Renders only the unresolvable-tab state: a restored tab whose workspace no
  /// longer matches the active one (deny visibly rather than render another
  /// tenant's run), or one missing the args it needs.
  const AgentActivityPane.unavailable({super.key})
    : workspaceId = '',
      channelId = '',
      runId = '',
      agentId = '',
      fallbackLabel = null,
      _unavailable = true;

  /// The workspace the run belongs to.
  final String workspaceId;

  /// The conversation the run belongs to — scopes the run-log derive.
  final String channelId;

  /// The run whose activity is shown.
  final String runId;

  /// The agent that executed the run.
  final String agentId;

  /// The label the tab was opened with, shown until the run row resolves.
  final String? fallbackLabel;

  final bool _unavailable;

  @override
  ConsumerState<AgentActivityPane> createState() => _AgentActivityPaneState();
}

class _AgentActivityPaneState extends ConsumerState<AgentActivityPane> {
  final ScrollController _scroll = ScrollController();

  /// Whether the view is pinned to the live tail. Flips off the moment the
  /// operator scrolls up to read something, so new activity never yanks them
  /// away from it.
  bool _following = true;
  int _lastSegmentCount = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final position = _scroll.position;
    final atBottom =
        position.maxScrollExtent - position.pixels < _kFollowThreshold;
    if (atBottom != _following) {
      setState(() => _following = atBottom);
    }
  }

  /// Re-pins to the tail after new segments arrive.
  ///
  /// `jumpTo`, not `animateTo`: reduced-motion-safe by construction and
  /// jitter-free when a fast run appends several segments a second.
  void _followTail(int segmentCount) {
    if (segmentCount == _lastSegmentCount) {
      return;
    }
    _lastSegmentCount = segmentCount;
    if (!_following) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) {
        return;
      }
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget._unavailable) {
      return CcEmptyState(
        icon: AppIcons.activity,
        message: l10n.agentActivityRunUnavailable,
      );
    }

    final runAsync = ref.watch(
      runInConversationProvider((
        workspaceId: widget.workspaceId,
        channelId: widget.channelId,
        runId: widget.runId,
      )),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AgentActivityHeader(
          workspaceId: widget.workspaceId,
          channelId: widget.channelId,
          runId: widget.runId,
          agentId: widget.agentId,
          run: runAsync.asData?.value,
          fallbackLabel: widget.fallbackLabel,
        ),
        const CcDivider(),
        Expanded(child: _body(context, l10n, runAsync)),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<AgentRunLog?> runAsync,
  ) {
    // The run row is the discriminator for the two empty states, so resolve it
    // before the transcript.
    if (runAsync.isLoading && !runAsync.hasValue) {
      return const Center(child: CcSpinner(size: 18, strokeWidth: 2));
    }
    final run = runAsync.asData?.value;
    if (run == null) {
      return CcEmptyState(
        icon: AppIcons.activity,
        message: l10n.agentActivityRunUnavailable,
      );
    }

    final key = (workspaceId: widget.workspaceId, runId: widget.runId);
    final transcript = ref.watch(runTranscriptProvider(key));

    // Dispatched by hand rather than through `when`: a stream that errors
    // before its first value reports AsyncLoading WITH the error attached and
    // `when` would send that to `loading` — a spinner that never resolves.
    if (transcript.hasError) {
      return transcript.error is RunActivityUnsupportedException
          // Not "this run recorded nothing": the server has no such op, which
          // in practice means the app is talking to a stale server binary.
          ? CcEmptyState(
              icon: AppIcons.triangleAlert,
              message: l10n.agentActivityUnsupported,
              description: l10n.agentActivityUnsupportedHint,
            )
          : _LoadFailed(
              onRetry: () => ref.invalidate(runTranscriptProvider(key)),
            );
    }
    if (!transcript.hasValue) {
      return const Center(child: CcSpinner(size: 18, strokeWidth: 2));
    }

    final segments = transcript.requireValue;
    if (segments.isEmpty) {
      // A terminal run with nothing recorded IS "not recorded" — which is also
      // how a run predating activity capture degrades.
      return run.isActive
          ? CcEmptyState(
              icon: AppIcons.loaderCircle,
              message: l10n.agentActivityWaiting,
            )
          : CcEmptyState(
              icon: AppIcons.activity,
              message: l10n.agentActivityNotRecorded,
              description: l10n.agentActivityNotRecordedHint,
            );
    }
    _followTail(segments.length);
    return _Timeline(
      segments: segments,
      isLive: run.isActive,
      scroll: _scroll,
      following: _following,
      onJumpToLatest: _jumpToLatest,
    );
  }

  void _jumpToLatest() {
    setState(() => _following = true);
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }
}

/// The scrollable timeline plus its "jump to latest" affordance.
class _Timeline extends ConsumerWidget {
  const _Timeline({
    required this.segments,
    required this.isLive,
    required this.scroll,
    required this.following,
    required this.onJumpToLatest,
  });

  final List<TranscriptSegment> segments;
  final bool isLive;
  final ScrollController scroll;
  final bool following;
  final VoidCallback onJumpToLatest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        Semantics(
          liveRegion: isLive && following,
          label: isLive && following ? l10n.agentActivityFollowingLive : null,
          child: CcScrollbar(
            controller: scroll,
            child: SingleChildScrollView(
              controller: scroll,
              // Deeper bottom gutter than the other three sides: the tail is
              // where the eye lands, so it must not sit against the pane edge,
              // and the "jump to latest" pill floats over this corner.
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              // `live: null` is the supported persisted path: rows render from
              // `segments` directly instead of re-reading a delta registry.
              child: TranscriptFlow(
                segments: segments,
                codeFont: ref.watch(codeFontFamilyProvider),
                isLive: isLive,
              ),
            ),
          ),
        ),
        if (isLive && !following)
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: CcButton(
              icon: AppIcons.arrowDown,
              size: CcButtonSize.sm,
              onPressed: onJumpToLatest,
              child: Text(l10n.agentActivityJumpToLatest),
            ),
          ),
      ],
    );
  }
}

/// The transcript failed to load — offer a retry rather than a dead tab.
class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcEmptyState(
      icon: AppIcons.triangleAlert,
      message: l10n.agentActivityLoadFailed,
      action: CcButton(
        size: CcButtonSize.sm,
        onPressed: onRetry,
        child: Text(l10n.retry),
      ),
    );
  }
}
