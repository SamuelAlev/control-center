import 'package:cc_harness/context.dart' show ToolCallForms;
import 'package:cc_harness/loop.dart' show SteeringQueue;
import 'package:cc_infra/cc_infra.dart' show DispatchSession;
import 'package:cc_infra/src/dispatch/dispatch_session.dart'
    show DispatchSession;

/// The slice of a live dispatch session the steering queue needs.
///
/// An interface (implemented by [DispatchSession]) so the steering queue and
/// its tests can work with sessions without constructing the real thing — a
/// `DispatchSession` owns processes, transcripts and credentials, none of
/// which a queue test should have to fake.
abstract class SteeringSessionView {
  /// Whether a message pushed into [steeringQueue] now will reach the run: a
  /// built-in harness loop drains it at its next turn boundary, a `claude -p`
  /// turn writes it to its open stdin.
  bool get acceptsSteering;

  /// The session's workspace, when scoped.
  String? get workspaceId;

  /// The conversation the session was dispatched into.
  String? get conversationId;

  /// The agent the session runs: a wake reaches only its own agent's run.
  String? get agentId;

  /// The space the session was dispatched into.
  String? get spaceId;

  /// The run-log id backing this session, when it has one.
  String? get runLogId;

  /// The person the run acts for; null for a bot run. A wake joins the
  /// run's lane only when it acts for the same.
  String? get requestedByUserId;

  /// Whether the run may only read: no wake joins its lane.
  bool get readOnly;

  /// Whether the run started without history: no wake joins its lane.
  bool get freshHistory;

  /// The session's steering inbox. Safe to mutate between turns: the harness
  /// loop reads it only at turn boundaries, a Claude run on the next
  /// microtask after a push.
  SteeringQueue get steeringQueue;

  /// How the run calls a tool, for a text pushed into its lane that names
  /// one (a wake's follow-up).
  ToolCallForms get toolForms;
}

/// A live run that may be live only because a Claude Code turn waits on its
/// own background tasks (its turn answered, nothing queued): such a run must
/// block nothing. The wake queue asks it to [yieldBackgroundHold] when work
/// for its agent in its conversation would otherwise wait behind it, and
/// delivers that work after the run settles.
abstract interface class BackgroundHoldView {
  /// Whether the run is live only for that wait (or already yielding it).
  bool get heldForBackgroundOnly;

  /// Ends the wait now: stdin closes and the run settles as at any turn end.
  /// A no-op when the run is not [heldForBackgroundOnly].
  void yieldBackgroundHold();
}
