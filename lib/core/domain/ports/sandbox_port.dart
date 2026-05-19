import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/domain/value_objects/sandbox_event.dart';
import 'package:control_center/core/domain/value_objects/sandbox_handle.dart';
import 'package:control_center/core/domain/value_objects/sandbox_spec.dart';

/// Static description of what a [SandboxPort] implementation can do on the
/// current machine. Surface this in settings so users know what they get.
class SandboxBackendCapabilities {
  /// Creates a new [SandboxBackendCapabilities].
  const SandboxBackendCapabilities({
    required this.backend,
    required this.available,
    this.requiresInstall = false,
    this.installHint,
    this.note,
  });

  /// Backend this capability descriptor refers to.
  final SandboxBackend backend;

  /// Whether the backend can launch a sandbox on this host *right now*.
  final bool available;

  /// True when a tool needs to be installed to make [available] flip true
  /// (e.g. `apt-get install bubblewrap socat` on Linux).
  final bool requiresInstall;

  /// Free-form install command shown in the onboarding step.
  final String? installHint;

  /// Optional note for the UI ("Pro/Enterprise only", "Requires KVM", …).
  final String? note;
}

/// Port for managing the lifecycle of isolated execution sandboxes.
///
/// One implementation per backend. Adapters live under
/// `lib/features/sandboxing/data/adapters/`.
abstract interface class SandboxPort {
  /// Backend identifier — used by the UI to render the chat header badge.
  SandboxBackend get backend;

  /// Returns what this backend can do on the current host. Called once at
  /// app startup by `SandboxBackendDetector`.
  Future<SandboxBackendCapabilities> probe();

  /// Boots a sandbox per the [spec]. The returned handle stays valid until
  /// [destroy] is called.
  Future<SandboxHandle> launch(SandboxSpec spec);

  /// Returns true when [handle] still points to a usable runtime. Used by
  /// the agent dispatcher to detect stale handles before reusing them — the
  /// cooldown timer can otherwise race with a fresh dispatch and leave us
  /// with a handle whose temp resources were already cleaned up.
  Future<bool> isAlive(SandboxHandle handle);

  /// Streams lifecycle + stdio events for the sandbox identified by [handle].
  Stream<SandboxEvent> events(SandboxHandle handle);

  /// Executes [argv] inside the running sandbox. [env] is injected into the
  /// child process environment. [workdir], when non-null, overrides the
  /// spec's default `guestWorkdir` for this one invocation — that's how the
  /// agent dispatcher targets the agent directory while the interactive
  /// terminal stays in the conversation directory.
  ///
  /// [onPid] is called once with the child process id immediately after
  /// `Process.start` returns, before any stdio is forwarded. Use it to
  /// capture the PID for process-management UI (kill button, run logs, etc.).
  ///
  /// Returns the exit code. Streams stdout/stderr to the same [events]
  /// stream so the chat UI can pick them up just like the un-sandboxed path.
  ///
  /// [stdinInput], when non-null, is written to the child's stdin and stdin
  /// is then closed. Used by CLIs like `pi` that expect the prompt on stdin
  /// rather than as an argv entry. When null the child's stdin is closed
  /// immediately so reads return EOF instead of blocking.
  Future<int> exec(
    SandboxHandle handle,
    List<String> argv, {
    Map<String, String>? env,
    String? workdir,
    Duration? timeout,
    void Function(int pid)? onPid,
    String? stdinInput,
  });

  /// Pauses a warm sandbox. Implementations may checkpoint to disk to free
  /// RAM. The handle stays valid; call [resume] to wake it back up.
  Future<void> pause(SandboxHandle handle);

  /// Resumes a previously paused sandbox.
  Future<void> resume(SandboxHandle handle);

  /// Tears down the sandbox and invalidates the handle.
  Future<void> destroy(SandboxHandle handle);
}
