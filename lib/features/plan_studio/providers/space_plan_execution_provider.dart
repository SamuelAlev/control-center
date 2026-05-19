import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/orchestration/providers/orchestration_providers.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a conversation within a workspace.
typedef SpaceKey = ({String workspaceId, String spaceId});

/// One node of a plan executing in a conversation, resolved to what the operator
/// needs to see: what it is, who is doing it, how it is going and the run to
/// jump to.
class PlanNodeExecution {
  /// Creates a [PlanNodeExecution].
  const PlanNodeExecution({
    required this.nodeKey,
    required this.title,
    required this.stepId,
    required this.status,
    this.agentId,
    this.runId,
  });

  /// The plan node's key.
  final String nodeKey;

  /// The node's title (its row label).
  final String title;

  /// The generated pipeline step id (`sub_<nodeKey>`).
  final String stepId;

  /// The step's live status. `pending` covers "not started yet".
  final PipelineStepStatus status;

  /// The agent executing the node, once it has been dispatched.
  final String? agentId;

  /// The agent run to focus when the row is tapped.
  final String? runId;

  /// Whether the node is in flight.
  bool get isRunning =>
      status == PipelineStepStatus.running ||
      status == PipelineStepStatus.suspended;

  /// Whether the node finished successfully.
  bool get isDone => status == PipelineStepStatus.completed;

  /// Whether the node failed.
  bool get isFailed => status == PipelineStepStatus.failed;
}

/// A plan's execution as seen from the conversation it runs in.
class SpacePlanExecution {
  /// Creates a [SpacePlanExecution].
  const SpacePlanExecution({required this.orchestration, required this.nodes});

  /// The orchestration the plan compiled into.
  final Orchestration orchestration;

  /// Its work nodes, in plan order.
  final List<PlanNodeExecution> nodes;

  /// The plan's goal (the section's subject).
  String get goal => orchestration.proposal.goal;

  /// Whether work is still in flight.
  bool get isActive => !orchestration.status.isTerminal;

  /// How many nodes have settled (done or failed).
  int get settled => nodes.where((n) => n.isDone || n.isFailed).length;

  /// Total node count.
  int get total => nodes.length;
}

/// The plan currently executing in a conversation, or null when none is.
///
/// Composed client-side from three live streams the app already has — the
/// workspace's orchestrations (matched on `spaceId`), the pipeline's step runs,
/// and the conversation's agent runs (matched on `pipelineStepId`) — so the
/// space can show per-node progress and attribution without a new RPC.
///
/// Prefers a non-terminal orchestration; falls back to the most recently updated
/// one so a just-finished plan still reads as "6/6 done" instead of vanishing
/// the moment the last step lands.
final spacePlanExecutionProvider = Provider.autoDispose
    .family<SpacePlanExecution?, SpaceKey>((ref, key) {
      final orchestrations =
          ref
              .watch(workspaceOrchestrationsProvider(key.workspaceId))
              .asData
              ?.value ??
          const <Orchestration>[];
      final mine = [
        for (final o in orchestrations)
          if (o.spaceId == key.spaceId) o,
      ];
      if (mine.isEmpty) {
        return null;
      }
      mine.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final orchestration = mine.firstWhere(
        (o) => !o.status.isTerminal,
        orElse: () => mine.first,
      );

      final runId = orchestration.pipelineRunId;
      final stepRuns = runId == null
          ? const <PipelineStepRun>[]
          : ref.watch(pipelineStepRunsForRunProvider(runId)).asData?.value ??
                const <PipelineStepRun>[];
      final stepRunByStepId = {for (final sr in stepRuns) sr.stepId: sr};

      // The conversation's runs carry the template step id (`pipelineStepId`,
      // despite the name), which is the only live, authoritative link from a plan
      // node to the agent actually doing it.
      final runs =
          ref
              .watch(
                conversationRunLogsProvider((
                  workspaceId: key.workspaceId,
                  conversationId: key.spaceId,
                )),
              )
              .asData
              ?.value ??
          const <AgentRunLog>[];
      final runByStepId = <String, AgentRunLog>{};
      for (final run in runs) {
        final stepId = run.pipelineStepId;
        if (stepId == null || stepId.isEmpty) {
          continue;
        }
        // Keep the live run when there is one, else the latest.
        final existing = runByStepId[stepId];
        if (existing == null || run.isRunning) {
          runByStepId[stepId] = run;
        }
      }

      final nodes = <PlanNodeExecution>[
        for (final ticket in orchestration.proposal.subTickets)
          () {
            final stepId = 'sub_${ticket.key}';
            final run = runByStepId[stepId];
            return PlanNodeExecution(
              nodeKey: ticket.key,
              title: ticket.title,
              stepId: stepId,
              status:
                  stepRunByStepId[stepId]?.status ?? PipelineStepStatus.pending,
              agentId: run?.agentId,
              runId: run?.id,
            );
          }(),
      ];

      return SpacePlanExecution(orchestration: orchestration, nodes: nodes);
    });

/// All run logs of a conversation (not just the active ones), so a plan node
/// keeps its attribution after its run finishes.
final conversationRunLogsProvider = StreamProvider.autoDispose
    .family<List<AgentRunLog>, ConversationRunsKey>((ref, key) {
      return ref
          .watch(agentRunLogRepositoryProvider)
          .watchByConversation(key.workspaceId, key.conversationId);
    });
