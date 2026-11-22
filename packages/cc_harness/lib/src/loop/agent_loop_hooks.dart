/// Lifecycle hooks for the built-in agent loop.
///
/// A host can observe (and gate) the loop without the loop knowing about the
/// host. All methods are optional via [NoopAgentLoopHooks]; a pre-tool hook may
/// deny a call by returning false.
library;

import 'package:cc_harness/messages.dart' show HarnessMessageOrigin;

/// Observes and optionally gates agent-loop lifecycle events.
abstract interface class AgentLoopHooks {
  /// Whether this implementation actually observes or gates INDIVIDUAL tool
  /// calls ([preToolUse] / [postToolUse]).
  ///
  /// The loop batches consecutive read-only tools so they execute
  /// concurrently, but a per-tool veto or observation has to run in the
  /// model's original order — so batching is disabled whenever a hook
  /// intercepts tools. That trade is only worth paying for hooks that DO:
  /// gating on "a hooks object exists at all" made a session-start-only hook
  /// serialize every tool call in the run, which is a large, silent cost for
  /// a hook that could not observe the difference.
  ///
  /// Implementations that only handle lifecycle events return false.
  /// Anything unsure returns true — over-serializing is slow, but
  /// under-serializing lets a veto arrive after the call it meant to stop.
  bool get interceptsTools;

  /// Called once when the run starts.
  Future<void> onSessionStart();

  /// Called before a tool executes. Return false to DENY the call (the loop
  /// feeds an error result back to the model instead of running the tool).
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args);

  /// Called after a tool finishes, with the (possibly errored) result text.
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  });
}

/// What happens when the model would end its turn: the answer of one
/// [AgentLoopTurnHooks.onWouldStop] call.
///
/// One seam with one typed result, shared by everything that may keep a run
/// from ending: the kernel's own park on live background commands, the
/// owner's `stop` hook, and server code (a goal that must not stop yet).
sealed class WouldStop {
  const WouldStop();
}

/// Let the turn end.
final class WouldStopEnd extends WouldStop {
  /// Creates the "end the turn" answer.
  const WouldStopEnd();
}

/// Do not end: add [message] to the conversation as a system message and run
/// another turn.
final class WouldStopContinue extends WouldStop {
  /// Creates a "continue" answer. [message] must not be blank. Every producer
  /// decides [origin]: null only for the owner's own text (its `stop` hook)
  /// and the loop's own nudges; a message that carries another agent's, a
  /// tool's or a forge's words names where they came from.
  WouldStopContinue(this.message, {required this.origin}) {
    if (message.trim().isEmpty) {
      throw ArgumentError.value(message, 'message', 'must not be blank');
    }
  }

  /// The system message the model reads next.
  final String message;

  /// Where [message]'s words came from, carried onto the history entry: a
  /// compaction pins untagged system text as steering and only summarises a
  /// tagged one.
  final HarnessMessageOrigin? origin;
}

/// Do not end yet: wait, without a model call, until [until] completes, then
/// look again. The loop also stops waiting when the run is cancelled or a
/// message arrives in any steering lane.
final class WouldStopPark extends WouldStop {
  /// Creates a park answer.
  const WouldStopPark(this.until, {required this.reason});

  /// Completes when the reason to wait may be over.
  final Future<void> until;

  /// What the run waits for, for the run's activity (`LoopPark.reason`).
  final String reason;
}

/// What the loop knows when the model would end its turn.
class WouldStopContext {
  /// Creates a context.
  const WouldStopContext({required this.turn, required this.lastAssistantText});

  /// The turn that would be the last (0-based).
  final int turn;

  /// The text of the model's final message.
  final String lastAssistantText;
}

/// The turn-end and compaction seams of the loop, set beside [AgentLoopHooks]
/// (`LoopSteeringConfig.turnHooks`).
///
/// A separate interface rather than two more [AgentLoopHooks] members: every
/// existing hooks implementation would otherwise have to grow both. A nested
/// run (a subagent) is given none, so it never inherits the owner's `stop`
/// hook (see [NestedRunHooks]).
abstract interface class AgentLoopTurnHooks {
  /// Called when the model would end its turn: after the follow-up lane was
  /// drained and found empty, after the completion contract let the turn
  /// end, and after the loop's own wait for live background commands had
  /// nothing left to wait for. A throw ends the turn.
  Future<WouldStop> onWouldStop(WouldStopContext context);

  /// Called before a compaction of the run's context summarizes anything.
  /// Returns text to add to the summarizer's focus (after the `compact`
  /// tool's own focus, when both exist), or null. A throw adds nothing.
  Future<String?> preCompact();
}

/// A no-op [AgentLoopHooks] that allows everything.
class NoopAgentLoopHooks implements AgentLoopHooks {
  /// Creates a [NoopAgentLoopHooks].
  const NoopAgentLoopHooks();

  @override
  bool get interceptsTools => false;

  @override
  Future<void> onSessionStart() async {}

  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async =>
      true;

  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async {}
}

/// The hooks a NESTED run (a subagent) inherits from its parent's [parent].
///
/// Tool gating and observation forward unchanged: a user's pre-tool veto is a
/// policy over every tool call made on their behalf, and a subagent's call is
/// one — a hook that vetoed only the parent was trivially bypassed by asking a
/// subagent to make the same call. The session-start hook does NOT re-fire: it
/// announces the user's session, which a subagent does not start. Nor do the
/// owner's `stop` and `preCompact` hooks ([AgentLoopTurnHooks]): a nested run
/// is given no turn hooks, so its turn ends when its model is done.
class NestedRunHooks implements AgentLoopHooks {
  /// Wraps [parent] for a nested run.
  const NestedRunHooks(this.parent);

  /// The parent run's hooks.
  final AgentLoopHooks parent;

  @override
  bool get interceptsTools => parent.interceptsTools;

  @override
  Future<void> onSessionStart() async {}

  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) =>
      parent.preToolUse(toolName, args);

  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) => parent.postToolUse(toolName, result, isError: isError);
}
