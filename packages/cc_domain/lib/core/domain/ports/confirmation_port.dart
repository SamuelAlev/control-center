/// Severity of a confirmation request, used by the UI to colour the modal.
enum ConfirmationSeverity {
  /// Read-only operation that's still worth flagging (e.g. network egress
  /// to a non-allowlisted host).
  info,

  /// Mutates the workspace or sends a message externally.
  warning,

  /// Destructive (force-push, delete branch, `rm -rf`, package install).
  destructive,
}

/// What kind of privileged operation is being confirmed.
enum ConfirmationKind {
  /// A shell command (e.g. `git push`, `npm install`).
  command,
  /// A file write outside the allowed roots.
  fileWrite,
  /// Network egress to a non-allowlisted host.
  networkEgress,
  /// An agent requesting a capability escalation.
  capabilityEscalation,
}

/// How long a remembered decision should persist.
enum RememberScope {
  /// Single use — always re-prompt.
  once,
  /// Current session only (in-memory, never persisted).
  session,
  /// All future invocations in this workspace.
  workspace,
  /// All future invocations for this specific agent.
  agent,
}

/// Request payload surfaced to the user for inline approval of a privileged
/// agent action.
class ConfirmationRequest {
  /// Creates a new [ConfirmationRequest].
  const ConfirmationRequest({
    required this.conversationId,
    required this.title,
    required this.detail,
    this.severity = ConfirmationSeverity.warning,
    this.command,
    this.kind = ConfirmationKind.command,
    this.rememberChoice,
    this.fingerprint,
  });

  /// Conversation the request originated from. The UI routes the modal to
  /// the right chat.
  final String conversationId;

  /// Short headline ("Push to main", "Install package").
  final String title;

  /// Long-form description of what the agent is about to do.
  final String detail;

  /// Severity tier.
  final ConfirmationSeverity severity;

  /// Verbatim command the agent is about to run, if applicable.
  final String? command;

  /// What kind of operation is being confirmed.
  final ConfirmationKind kind;

  /// When non-null, the UI offers a "remember this decision" dropdown
  /// scoped to this value. Destructive-severity requests never set this
  /// (the UI hides the dropdown).
  final RememberScope? rememberChoice;

  /// Canonical fingerprint of the matched command (exact token sequence).
  /// Used to look up / persist remembered decisions.
  final String? fingerprint;
}

/// Wire DTO for a pending agent-action confirmation — the
/// `confirmation.watchPending` snapshot entry + the payload the phone renders.
/// Mirrors the host's `pendingConfirmationToWire` shape.
class ConfirmationRequestDto {
  /// Creates a [ConfirmationRequestDto].
  const ConfirmationRequestDto({
    required this.id,
    required this.conversationId,
    required this.title,
    required this.detail,
    required this.severity,
    this.command,
    required this.createdAt,
  });

  /// Factory from the wire map.
  factory ConfirmationRequestDto.fromJson(Map<String, dynamic> json) =>
      ConfirmationRequestDto(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        severity: json['severity'] as String? ?? 'warning',
        command: json['command'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );

  /// Stable id echoed back in `confirmation.respond`.
  final String id;

  /// Conversation (channel) the request originated from.
  final String conversationId;

  /// Short headline ("Push to main").
  final String title;

  /// Long-form description of what the agent is about to do.
  final String detail;

  /// Severity tier name (`info` / `warning` / `destructive`).
  final String severity;

  /// Verbatim command, when applicable.
  final String? command;

  /// ISO-8601 creation timestamp.
  final String createdAt;
}

/// Port used by sandbox hooks to interrupt an in-flight agent and ask the
/// user to approve a destructive operation.
abstract interface class ConfirmationPort {
  /// Surfaces [request] in the UI. Resolves once the user accepts or denies.
  /// Returns true on accept, false on deny / timeout.
  Future<bool> requestApproval(ConfirmationRequest request);
}
