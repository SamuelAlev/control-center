import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';

/// Creates the queue's one timer (`Timer.new` outside tests).
typedef WakeTimerFactory = Timer Function(Duration delay, void Function() fire);

/// One run the wake queue starts: the plain agent dispatch
/// (`MessagingService.dispatchAgentRun`) with the wakes' context.
class WakeDispatchRequest {
  /// Creates a request.
  const WakeDispatchRequest({
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.wakeContext,
    required this.requestedByUserId,
    required this.mentionChain,
    required this.inReplyToAgentId,
    required this.costCapMicros,
    required this.expectedOutputSchema,
    required this.freshHistory,
    required this.readOnly,
  });

  /// The request that delivers [wakes] (one agent, one conversation, one
  /// way of running: the queue's batch) with [wakeContext].
  factory WakeDispatchRequest.forWakes(
    List<Wake> wakes, {
    required WakeContext wakeContext,
  }) {
    final first = wakes.first;
    final options = first.runOptions;
    return WakeDispatchRequest(
      workspaceId: first.workspaceId,
      spaceId: first.spaceId,
      conversationId: first.conversationId,
      agentId: first.agentId,
      wakeContext: wakeContext,
      requestedByUserId: first.requestedByUserId,
      mentionChain: first.chain,
      inReplyToAgentId: first.detail.sourceAgentId,
      costCapMicros: options?.costCapMicros,
      expectedOutputSchema: options?.outputSchema == null
          ? null
          : Map<String, dynamic>.of(options!.outputSchema!),
      freshHistory: options?.freshHistory ?? false,
      readOnly: options?.readOnly ?? false,
    );
  }

  /// Owning workspace.
  final String workspaceId;

  /// The conversation's space.
  final String spaceId;

  /// The conversation the run belongs to.
  final String conversationId;

  /// The agent to run.
  final String agentId;

  /// Why the run exists: the wakes it delivers.
  final WakeContext wakeContext;

  /// The person the run acts for; null for a bot run.
  final String? requestedByUserId;

  /// The agents whose messages led here (the wake's chain).
  final List<String> mentionChain;

  /// The agent the run's turn answers, when another agent caused it.
  final String? inReplyToAgentId;

  /// The run's cost cap; null for the default.
  final int? costCapMicros;

  /// The `submit_output` schema the run must satisfy.
  final Map<String, dynamic>? expectedOutputSchema;

  /// Start with no history from before the run.
  final bool freshHistory;

  /// Run with the review mode's capabilities.
  final bool readOnly;

  /// The run's turn input: a fixed server sentence, never stored as a
  /// person's message ([wakeTurnInput]).
  String get prompt => wakeTurnInput;
}

/// Starts the run for a [WakeDispatchRequest]. Returns its run id, or null
/// when no run started. May throw `ReadOnlyRunUnavailableException`.
typedef WakeRunDispatcher = Future<String?> Function(WakeDispatchRequest run);

/// Posts one system row into a conversation (message type `system`).
typedef WakeSystemRowSender =
    Future<void> Function({
      required String workspaceId,
      required String spaceId,
      required String conversationId,
      required String content,
      required Map<String, Object?> metadata,
    });

/// What the wake queue asks of the rest of the server, as functions so the
/// runtime wires them and tests fake them.
class WakeQueuePorts {
  /// Creates the ports.
  const WakeQueuePorts({
    required this.workspaceActive,
    required this.conversationSpace,
    required this.agent,
    required this.isMember,
    required this.takenOver,
    required this.budgetBlocked,
    required this.liveSessions,
    required this.hasLiveRun,
    required this.dispatch,
    required this.postSystemRow,
  });

  /// Whether the workspace is registered and not deleted. Asked before the
  /// workspace's database is opened.
  final Future<bool> Function(String workspaceId) workspaceActive;

  /// The space of the conversation in that workspace, or null when the
  /// conversation is not there.
  final Future<String?> Function(String workspaceId, String conversationId)
  conversationSpace;

  /// The agent, or null when it no longer exists.
  final Future<Agent?> Function(String workspaceId, String agentId) agent;

  /// Whether the user is still a member of the workspace.
  final Future<bool> Function(String workspaceId, String userId) isMember;

  /// Whether a person holds the space's worktree (take-over).
  final Future<bool> Function(String workspaceId, String spaceId) takenOver;

  /// Whether a budget blocks a run of the agent
  /// (`BudgetEnforcementService.checkInvocationBlock`).
  final Future<bool> Function(String workspaceId, String agentId) budgetBlocked;

  /// The live dispatch sessions in the conversation (any workspace: the
  /// queue filters by workspace and agent).
  final List<SteeringSessionView> Function(String conversationId) liveSessions;

  /// Whether a top-level run of the agent is active in the conversation
  /// (its run log), with or without a session yet.
  final Future<bool> Function(
    String workspaceId,
    String conversationId,
    String agentId,
  )
  hasLiveRun;

  /// Starts a run.
  final WakeRunDispatcher dispatch;

  /// Posts a system row.
  final WakeSystemRowSender postSystemRow;
}

/// The `kind` metadata of the row a wake-started run leaves.
const String wakeDeliveredRowKind = 'wake';

/// The `kind` metadata of the row a skipped wake leaves.
const String wakeSkippedRowKind = 'wake_skipped';

/// Whether a run that delivered [wakes] leaves a "Woke …" row: not when
/// every one of them is marked [WakeFields.quietDelivery] (a goal's first
/// segment, which the person's own `/goal` message just announced).
bool wantsDeliveredRow(List<Wake> wakes) =>
    !wakes.every((w) => w.detail.fields[WakeFields.quietDelivery] == true);

/// The compact row a wake-started run leaves in its conversation.
String deliveredRowText(List<Wake> wakes, {required String agentName}) {
  final first = wakes.first;
  final more = wakes.length == 1 ? '' : ' (and ${wakes.length - 1} more)';
  return 'Woke $agentName: [${wakeLabel(first)}] ${wakeHeadline(first)}$more';
}

/// The row's metadata: which wakes, why, from where, and the run;
/// `wakeHeadline` is the first wake's headline as the frame builder writes
/// it ([wakeHeadline]: record pieces neutralised and cut), so a client need
/// not parse it out of the text.
Map<String, Object?> deliveredRowMetadata(
  List<Wake> wakes, {
  required String runId,
}) => {
  'kind': wakeDeliveredRowKind,
  'wakeIds': [for (final w in wakes) w.id],
  'wakeReason': wakes.first.reason.wire,
  'wakeOrigin': wakeLabel(wakes.first),
  'wakeHeadline': wakeHeadline(wakes.first),
  'wakeRunId': runId,
  'wakeAgentId': wakes.first.agentId,
  'wakeSourceAgentId': ?wakes.first.detail.sourceAgentId,
};

/// The compact row a skipped wake leaves.
String skippedRowText(Wake wake, String kind) =>
    'A wake was not delivered ($kind): [${wakeLabel(wake)}] '
    '${wakeHeadline(wake)}';

/// The skipped row's metadata (a missed slot is a skip of kind
/// `wake_missed`), with its `wakeHeadline` as [deliveredRowMetadata] has it.
Map<String, Object?> skippedRowMetadata(Wake wake, String kind) => {
  'kind': wakeSkippedRowKind,
  'wakeId': wake.id,
  'wakeReason': wake.reason.wire,
  'wakeOrigin': wakeLabel(wake),
  'wakeHeadline': wakeHeadline(wake),
  'wakeSkipKind': kind,
  'wakeAgentId': wake.agentId,
  'wakeSourceAgentId': ?wake.detail.sourceAgentId,
};
