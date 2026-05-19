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
}

/// Port used by sandbox hooks to interrupt an in-flight agent and ask the
/// user to approve a destructive operation.
abstract interface class ConfirmationPort {
  /// Surfaces [request] in the UI. Resolves once the user accepts or denies.
  /// Returns true on accept, false on deny / timeout.
  Future<bool> requestApproval(ConfirmationRequest request);
}
