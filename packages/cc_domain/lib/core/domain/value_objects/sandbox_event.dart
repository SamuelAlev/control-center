/// Kind of event emitted on a sandbox's event stream.
enum SandboxEventType {
  /// stdout line from inside the guest.
  stdout,

  /// stderr line from inside the guest.
  stderr,

  /// Guest process exited (see [SandboxEvent.exitCode]).
  exit,

  /// Sandbox is starting up. Useful to surface "booting…" in the UI.
  starting,

  /// Sandbox is ready to accept exec calls.
  ready,

  /// Guest process was killed by the host (OOM, timeout, manual stop).
  killed,

  /// OS-level sandbox blocked a syscall. Surfaced as a yellow banner so the
  /// user can either grant a capability and retry or ignore.
  violation,
}

/// A single event emitted while a sandbox is alive.
class SandboxEvent {
  /// Creates a new [SandboxEvent].
  const SandboxEvent({
    required this.type,
    this.content = '',
    this.exitCode,
    this.violation,
  });

  /// Event kind.
  final SandboxEventType type;

  /// Payload for stdout/stderr events. Empty for lifecycle events.
  final String content;

  /// Set for [SandboxEventType.exit] events.
  final int? exitCode;

  /// Set for [SandboxEventType.violation] events. Carries the parsed
  /// sandbox-deny record.
  final SandboxViolation? violation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SandboxEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          content == other.content &&
          exitCode == other.exitCode &&
          violation == other.violation;

  @override
  int get hashCode => Object.hash(type, content, exitCode, violation);
}

/// Structured form of a sandbox denial — what was attempted, what was
/// blocked, and (when known) which capability would unblock it on retry.
class SandboxViolation {
  /// Creates a [SandboxViolation].
  const SandboxViolation({
    required this.action,
    required this.target,
    this.suggestedCapability,
    this.raw,
  });

  /// Verb that was denied (e.g. `file-read*`, `network-outbound`).
  final String action;

  /// Path or host that was the target of the denied operation.
  final String target;

  /// When non-null, the agent capability flag the user can flip to allow
  /// the operation next time (e.g. `canCallGitHubApi`).
  final String? suggestedCapability;

  /// Raw log line, useful for debugging / "Show details".
  final String? raw;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SandboxViolation &&
          runtimeType == other.runtimeType &&
          action == other.action &&
          target == other.target &&
          suggestedCapability == other.suggestedCapability &&
          raw == other.raw;

  @override
  int get hashCode => Object.hash(action, target, suggestedCapability, raw);
}
