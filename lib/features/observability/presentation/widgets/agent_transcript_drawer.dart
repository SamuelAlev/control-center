import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/run_activity_providers.dart';
import 'package:control_center/features/observability/presentation/tool_render/tool_renderers.dart';
import 'package:control_center/features/observability/presentation/widgets/run_activity_stats.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// On-demand transcript drawer for one agent: a stat bar (tokens, context-window
/// % gauge that warns past 80%, cost, tool count, duration) plus the run's
/// tool-call transcript rendered through the tool-render registry, with a kill
/// control while it is running. PRD 06 feature #8.
///
/// Scoped to [latestRun]: both halves — the stats and the transcript — describe
/// the same run, read through the run-activity providers.
class AgentTranscriptDrawer extends ConsumerWidget {
  /// Creates an [AgentTranscriptDrawer].
  const AgentTranscriptDrawer({
    super.key,
    required this.agent,
    this.latestRun,
    this.onClose,
    this.onKill,
  });

  /// The agent whose transcript is shown.
  final AgentRef agent;

  /// The agent's most-recent run (for token/cost/duration stats), if any.
  final AgentRunLog? latestRun;

  /// Closes the drawer.
  final VoidCallback? onClose;

  /// Kills the agent's running process (enabled while running with a pid).
  final VoidCallback? onKill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final cost = latestRun?.cost;
    // The run's OWN recorded activity, read run-scoped.
    //
    // This used to walk the channel feed backwards for the agent's latest turn
    // and reassemble its segments from three fallbacks (live registry → message
    // → cache → refetch). Now that a run's transcript is addressable, the run
    // id is the key — which also means the drawer reports the run whose stats
    // it is already showing, instead of whichever turn happened to be last.
    final workspaceId = latestRun?.workspaceId;
    final segments = (latestRun == null || workspaceId == null)
        ? const <ToolSegment>[]
        : ref
                  .watch(
                    runTranscriptProvider((
                      workspaceId: workspaceId,
                      runId: latestRun!.id,
                    )),
                  )
                  .asData
                  ?.value
                  .whereType<ToolSegment>()
                  .toList() ??
              const <ToolSegment>[];

    return Container(
      width: 440,
      decoration: BoxDecoration(
        color: t.bgPrimary,
        border: Border(left: BorderSide(color: t.borderPrimary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.displayName,
                        style: CcTypography.body.copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${agent.kind.name} · ${agent.status.name}',
                        style: CcTypography.caption.copyWith(
                          color: t.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onKill != null && agent.status == AgentStatus.running)
                  CcIconButton(
                    icon: AppIcons.circleStop,
                    onPressed: onKill,
                    tooltip: 'Kill agent',
                  ),
                if (onClose != null)
                  CcIconButton(
                    icon: AppIcons.x,
                    onPressed: onClose,
                    tooltip: 'Close',
                  ),
              ],
            ),
          ),
          const CcDivider(),
          // Stat bar — the same widget (and the same numbers) the run-scoped
          // activity tab renders.
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: RunActivityStatBar(
              cost: cost,
              toolCount: segments.length,
              childCostCents: latestRun?.childCostCents ?? 0,
            ),
          ),
          const CcDivider(),
          // Transcript.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tool calls',
                    style: CcTypography.caption.copyWith(color: t.textTertiary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TranscriptToolList(segments: segments),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
