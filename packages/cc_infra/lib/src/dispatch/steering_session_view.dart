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
  /// Whether a built-in harness loop is driving this session (the only
  /// transport whose turn boundaries drain steering).
  bool get isHarnessActive;

  /// The session's workspace, when scoped.
  String? get workspaceId;

  /// The conversation the session was dispatched into.
  String? get conversationId;

  /// The space the session was dispatched into.
  String? get spaceId;

  /// The run-log id backing this session, when it has one.
  String? get runLogId;

  /// The session's steering inbox. Safe to mutate between turns; the loop
  /// reads it only at turn boundaries.
  SteeringQueue get steeringQueue;
}
