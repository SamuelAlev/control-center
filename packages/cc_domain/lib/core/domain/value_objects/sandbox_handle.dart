import 'package:cc_domain/core/domain/ports/sandbox_port.dart' show SandboxPort;
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:collection/collection.dart';

/// Lifecycle states a sandbox session moves through.
enum SandboxState {
  /// Spec created but the VM has not started yet.
  created,

  /// VM is running and ready to exec commands.
  warm,

  /// VM is currently executing a command.
  active,

  /// VM is paused / checkpointed to disk to save RAM.
  suspended,

  /// VM has been destroyed; the handle is no longer valid.
  destroyed,

  /// Launch failed — see [SandboxHandle.error] for details.
  error,
}

/// Opaque handle returned by [SandboxPort.launch]. Implementations attach
/// adapter-specific bookkeeping via [details].
class SandboxHandle {
  /// Creates a new [SandboxHandle].
  SandboxHandle({
    required this.sessionId,
    required this.backend,
    this.state = SandboxState.created,
    this.error,
    Map<String, Object?>? details,
  }) : details = details ?? <String, Object?>{};

  /// Stable id for this sandbox session.
  final String sessionId;

  /// Backend that owns this handle.
  final SandboxBackend backend;

  /// Current lifecycle state.
  final SandboxState state;

  /// Set when [state] is [SandboxState.error].
  final Object? error;

  /// Adapter-private bookkeeping (working directory, PID, profile path, etc.).
  final Map<String, Object?> details;

  /// Returns a copy of this handle with the given fields replaced.
  SandboxHandle copyWith({
    String? sessionId,
    SandboxBackend? backend,
    SandboxState? state,
    Object? error,
    Map<String, Object?>? details,
  }) {
    return SandboxHandle(
      sessionId: sessionId ?? this.sessionId,
      backend: backend ?? this.backend,
      state: state ?? this.state,
      error: error ?? this.error,
      details: details ?? this.details,
    );
  }

  @override
  /// Structural equality, comparing all fields including [details].
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SandboxHandle &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          backend == other.backend &&
          state == other.state &&
          error == other.error &&
          const MapEquality<String, Object?>().equals(details, other.details);

  @override
  /// Hash based on all fields including [details] entries.
  int get hashCode => Object.hash(
    sessionId,
    backend,
    state,
    error,
    Object.hashAll(details.entries.map((e) => Object.hash(e.key, e.value))),
  );
}
