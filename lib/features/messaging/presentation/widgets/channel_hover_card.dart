import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/utils/provisioning_step_label.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_hover_rows.dart';
import 'package:control_center/features/messaging/providers/channel_activity_summary_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Width of the flyout. Wide enough for an agent name plus a ticking clock on
/// one line, narrow enough to sit beside the 248px rail without covering the
/// content column.
const double kChannelHoverCardWidth = 300;

/// The floating panel revealed by hovering (or focusing) a channel row in the
/// global sidebar: what is running in that channel right now, which agents and
/// subagents are doing it, how long they have been at it, how much of their
/// context window is gone, and what the conversation has cost.
///
/// Everything here is derived from subscriptions that already exist for the open
/// conversation and are `autoDispose`, so an idle sidebar costs nothing and a
/// hover's cost dies with the hover.
class ChannelHoverCard extends ConsumerWidget {
  /// Creates a [ChannelHoverCard].
  const ChannelHoverCard({
    super.key,
    required this.channel,
    required this.workspaceId,
    required this.onOpenChannel,
    required this.onOpenRun,
  });

  /// The channel being described.
  final Channel channel;

  /// The active workspace — the isolation scope for every read below.
  final String workspaceId;

  /// Opens the channel (a root agent row, or the header).
  final VoidCallback onOpenChannel;

  /// Opens one subagent run's activity.
  final void Function(ChannelLiveRun run, String label) onOpenRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(
      channelActivitySummaryProvider((
        workspaceId: workspaceId,
        conversationId: channel.id,
      )),
    );
    final needsInput = ref.watch(channelNeedsInputProvider(channel.id));
    final visual = ChannelStatusVisual.resolve(
      status: channel.provisioningStatus,
      needsInput: needsInput,
      isLive: summary.isLive,
      tokens: t,
      l10n: l10n,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        border: Border.all(color: t.borderSecondary),
        boxShadow: AppShadows.golden,
      ),
      child: SizedBox(
        width: kChannelHoverCardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              channel: channel,
              visual: visual,
              summary: summary,
              onOpenChannel: onOpenChannel,
            ),
            CcDivider(color: t.borderSecondary),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: summary.isLive
                      ? _LiveBody(
                          channelId: channel.id,
                          workspaceId: workspaceId,
                          summary: summary,
                          onOpenChannel: onOpenChannel,
                          onOpenRun: onOpenRun,
                        )
                      : _IdleBody(
                          channelId: channel.id,
                          workspaceId: workspaceId,
                        ),
                ),
              ),
            ),
            CcDivider(color: t.borderSecondary),
            _Footer(channelId: channel.id, summary: summary),
          ],
        ),
      ),
    );
  }
}

/// Channel name, live status pill, and the one-line "what is going on" summary.
class _Header extends StatelessWidget {
  const _Header({
    required this.channel,
    required this.visual,
    required this.summary,
    required this.onOpenChannel,
  });

  final Channel channel;
  final ChannelStatusVisual visual;
  final ChannelActivitySummary summary;
  final VoidCallback onOpenChannel;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final name = channel.name.isNotEmpty ? channel.name : l10n.channelLabel;

    return CcTappable(
      onPressed: onOpenChannel,
      semanticLabel: '$name, ${visual.label}',
      builder: (context, states) => Container(
        color: states.contains(WidgetState.hovered)
            ? t.bgSecondaryHover
            : const Color(0x00000000),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.body.copyWith(
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChannelStatusPill(visual: visual),
              ],
            ),
            const SizedBox(height: 5),
            _HeaderMeta(channel: channel, summary: summary),
          ],
        ),
      ),
    );
  }
}

/// The line under the channel name: how many agents are working and for how
/// long, or (when idle) when the channel last saw activity.
class _HeaderMeta extends StatelessWidget {
  const _HeaderMeta({required this.channel, required this.summary});

  final Channel channel;
  final ChannelActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final style = CcTypography.caption.copyWith(
      height: 1.35,
      color: t.textTertiary,
    );

    if (channel.provisioningStatus == ChannelProvisioningStatus.provisioning) {
      return Text(
        provisioningStepLabel(l10n, channel.provisioningStep),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    if (!summary.isLive) {
      final last = summary.lastActivityAt;
      return Text(
        last == null
            ? l10n.channelFlyoutNeverRun
            : l10n.lastActiveAgo(formatRelativeTime(context, last)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final parts = <String>[
      l10n.agentsRunningCount(summary.liveAgentCount),
      if (summary.liveSubagentCount > 0)
        l10n.subagentsRunningCount(summary.liveSubagentCount),
    ];
    return Row(
      children: [
        Flexible(
          child: Text(
            parts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (summary.startedAt != null) ...[
          Text(' · ', style: style),
          ElapsedTime(since: summary.startedAt!, color: t.textTertiary),
        ],
      ],
    );
  }
}

/// The live run tree: one row per top-level run, its context meter, and its
/// in-flight subagents nested beneath.
class _LiveBody extends ConsumerWidget {
  const _LiveBody({
    required this.channelId,
    required this.workspaceId,
    required this.summary,
    required this.onOpenChannel,
    required this.onOpenRun,
  });

  final String channelId;
  final String workspaceId;
  final ChannelActivitySummary summary;
  final VoidCallback onOpenChannel;
  final void Function(ChannelLiveRun run, String label) onOpenRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents =
        ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
        const <Agent>[];
    final agentsById = {for (final a in agents) a.id: a};

    String nameFor(ChannelLiveRun run) {
      final agent = agentsById[run.agentId];
      final name = agent?.name.trim() ?? '';
      if (name.isNotEmpty) {
        return name;
      }
      final title = agent?.title.trim() ?? '';
      if (title.isNotEmpty) {
        return title;
      }
      return run.summary ?? run.agentId;
    }

    final rows = <Widget>[];
    for (final run in summary.liveRuns) {
      final label = nameFor(run);
      // Agents are groups, and a group needs air around it: rows inside one
      // (agent → meter → its subagents) stay tight, while consecutive agents get
      // a gap, so two agents working at once read as two things at a glance.
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: AppSpacing.sm));
      }
      rows.add(
        ChannelRunRow(
          run: run,
          label: label,
          isSubagent: false,
          isLastChild: true,
          onPressed: onOpenChannel,
        ),
      );
      // The window is a property of the agent, not the channel, so each live
      // agent gets its own meter rather than one aggregate that would be wrong
      // whenever two agents in the room have different windows.
      rows.add(ChannelContextMeter(channelId: channelId, agentId: run.agentId));
      for (var i = 0; i < run.children.length; i++) {
        final child = run.children[i];
        final childLabel = child.summary ?? nameFor(child);
        rows.add(
          ChannelRunRow(
            run: child,
            label: childLabel,
            isSubagent: true,
            isLastChild: i == run.children.length - 1,
            onPressed: () => onOpenRun(child, childLabel),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

/// What an idle channel shows: no work in flight, plus the roster that would do
/// the work if there were.
class _IdleBody extends ConsumerWidget {
  const _IdleBody({required this.channelId, required this.workspaceId});

  final String channelId;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final participants =
        ref.watch(channelParticipantsProvider(channelId)).asData?.value ??
        const [];
    final agents =
        ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
        const <Agent>[];
    final agentsById = {for (final a in agents) a.id: a};
    final names = [
      for (final p in participants)
        if (p.participantType == PrincipalType.agent &&
            (agentsById[p.principalId]?.name.trim().isNotEmpty ?? false))
          agentsById[p.principalId]!.name.trim(),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.generalAgentsEmpty,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          ),
          if (names.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            HoverCardMetaRow(icon: AppIcons.users, text: names.join(' · ')),
          ],
        ],
      ),
    );
  }
}

/// The spend the conversation has accumulated, plus its open pull requests.
class _Footer extends ConsumerWidget {
  const _Footer({required this.channelId, required this.summary});

  final String channelId;
  final ChannelActivitySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final openPrs = ref
        .watch(channelPrsProvider(channelId))
        .where((pr) => pr.isOpen);
    // A run that clearly burned tokens but priced at zero means the model's
    // pricing was not resolvable — say so rather than assert it was free.
    final costUnknown = summary.costCents == 0 && summary.totalTokens > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          HoverCardStat(
            label: l10n.obsStatTokens,
            value: fmtTokens(summary.totalTokens),
          ),
          const SizedBox(width: AppSpacing.lg),
          HoverCardStat(
            label: l10n.obsStatCost,
            value: costUnknown ? '—' : fmtCents(summary.costCents),
          ),
          const Spacer(),
          if (openPrs.isNotEmpty)
            HoverCardStat(
              label: l10n.pullRequests,
              value: '${openPrs.length}',
              alignEnd: true,
            ),
        ],
      ),
    );
  }
}
