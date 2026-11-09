/// Base exception for all application errors.
sealed class AppException implements Exception {
  /// Creates an [AppException] with the given [message] and optional [code].
  const AppException(this.message, {this.code});

  /// Human-readable error message.
  final String message;

  /// Optional machine-readable error code.
  final String? code;

  @override
  String toString() =>
      '$runtimeType($message${code != null ? ', code: $code' : ''})';
}

/// Exception thrown when a network request fails.
class NetworkException extends AppException {
  /// Creates a [NetworkException].
  const NetworkException(
    super.message, {
    this.statusCode,
    this.responseBody,
    super.code,
  });

  /// HTTP status code, if applicable.
  final int? statusCode;

  /// Raw response body, if available.
  final String? responseBody;
}

/// Exception thrown when authentication fails or credentials are missing.
class AuthException extends AppException {
  /// Creates an [AuthException].
  const AuthException(super.message, {super.code});
}

/// Exception thrown when a requested resource is not found.
class NotFoundException extends AppException {
  /// Creates a [NotFoundException].
  const NotFoundException(super.message, {super.code});
}

/// Exception thrown when opening a local directory in an external editor / IDE
/// fails — the editor is unknown, not installed, the path is empty, or the OS
/// launch process errored. The message is surfaced to the user verbatim.
class EditorLaunchException extends AppException {
  /// Creates an [EditorLaunchException].
  const EditorLaunchException(super.message, {super.code});
}

/// Exception thrown when lazily materializing a PR's branch into a local
/// copy-on-write worktree fails (no GitHub remote/token, fetch/checkout error,
/// or the source repo is mid-operation). The message is shown to the user.
class PrWorktreeException extends AppException {
  /// Creates a [PrWorktreeException].
  const PrWorktreeException(super.message, {super.code});
}

/// Exception thrown when a server fails to start or encounters a runtime error.
class ServerException extends AppException {
  /// Creates a [ServerException].
  const ServerException(super.message, {this.cause, super.code});

  /// The underlying error that caused the server failure.
  final Object? cause;
}

/// Exception thrown when concurrent modifications conflict.
class ConcurrencyConflictException extends AppException {
  /// Creates a [ConcurrencyConflictException].
  const ConcurrencyConflictException(super.message, {super.code});
}

/// Thrown when an operation targets an entity that belongs to a different
/// workspace than the one the caller supplied.
///
/// Workspace isolation is enforced by requiring an explicit `workspaceId` on
/// every workspace-scoped operation and rejecting any access where the target
/// entity's workspace does not match. This is surfaced verbatim to agents (the
/// MCP layer wraps thrown exceptions into a tool error), so a cross-workspace
/// access attempt is an explicit, debuggable denial rather than a silent
/// no-op or — worse — a leak. [toString] returns just the message so the agent
/// sees a clean explanation.
class WorkspaceMismatchException extends AppException {
  /// Creates a [WorkspaceMismatchException].
  const WorkspaceMismatchException(super.message, {super.code});

  @override
  String toString() => message;
}

/// Thrown when a request carries an argument that fails semantic validation
/// (an unknown enum value, an out-of-range number, a malformed structure).
/// Maps to the RPC `validation` error code; the message is client-safe.
class ValidationException extends AppException {
  /// Creates a [ValidationException].
  const ValidationException(super.message, {super.code});

  @override
  String toString() => message;
}

/// Thrown when an org-chart mutation would break the strict reporting tree —
/// a reporting cycle, a manager in a different workspace, an unknown manager,
/// or deleting a manager that still has reports (ON DELETE RESTRICT). Surfaced
/// verbatim to agents via the MCP layer.
class OrgChartException extends AppException {
  /// Creates an [OrgChartException].
  const OrgChartException(super.message, {super.code});

  @override
  String toString() => message;
}

/// Thrown when a board-approval decision is not legal from the approval's
/// current state (e.g. approving an already-rejected approval, or resubmitting
/// one that was never sent back for revision). Surfaced verbatim to agents.
class InvalidApprovalTransitionException extends AppException {
  /// Creates an [InvalidApprovalTransitionException].
  const InvalidApprovalTransitionException(super.message, {super.code});

  @override
  String toString() => message;
}

/// Thrown when a delegation hop is refused by the deterministic delegation
/// guards (PRD 22 §3): it would push the chain past the depth cap, form a cycle
/// (A→B→…→A), exceed the delegator's autonomy ceiling, or spend a budget
/// envelope that is already exhausted.
///
/// The [message] carries the guard's named reason and is surfaced verbatim to
/// the agent via the MCP tool boundary, so a refused delegation is an explicit,
/// debuggable denial — never a silent no-op or a laundered privilege. [toString]
/// returns just the message so the agent sees a clean explanation.
class DelegationRefusedException extends AppException {
  /// Creates a [DelegationRefusedException].
  const DelegationRefusedException(super.message, {super.code});

  @override
  String toString() => message;
}

/// Thrown when an agent attempts to check out (claim for exclusive work) a task
/// that is already held by a different agent.
///
/// A task is assigned to exactly one agent; checkout is atomic, so of two
/// agents racing for the same task exactly one wins and the other is rejected
/// with this exception. The MCP layer surfaces the message verbatim, so the
/// losing agent learns who holds the task and can pick up other work instead.
class CheckoutConflictException extends AppException {
  /// Creates a [CheckoutConflictException]. [holderAgentId] is the agent that
  /// currently holds the task, when known.
  const CheckoutConflictException(
    super.message, {
    this.holderAgentId,
    super.code,
  });

  /// The agent currently holding the task, if known.
  final String? holderAgentId;

  @override
  String toString() => message;
}

/// Thrown when an agent's `complete_ticket` output does not satisfy the
/// ticket's declared `expectedOutputSchema` (strict contract mode).
///
/// The MCP tool boundary catches this and returns the [violations] verbatim to
/// the still-running agent, which fixes its payload and re-calls — the error
/// path is the retry loop. When [terminal] is true the rejection cap has been
/// hit and the ticket has been failed; the agent should stop retrying.
class OutputContractViolationException extends AppException {
  /// Creates an [OutputContractViolationException].
  const OutputContractViolationException(
    super.message, {
    required this.violations,
    this.terminal = false,
    super.code,
  });

  /// Human-readable JSON-path violation messages from the schema validator.
  final List<String> violations;

  /// Whether the rejection cap was reached and the ticket has been failed.
  final bool terminal;

  @override
  String toString() => message;
}

/// Thrown when the forge refuses to merge a pull request: GitHub answers the
/// merge `PUT` with `405` and a reason (merge conflicts, a required check, a
/// protection rule). Typed so the reason reaches the client instead of dying
/// as a generic network error, and so a conflict can be told apart from the
/// rest — a conflict has a fix (resolve it), the others have a wait.
class PrNotMergeableException extends AppException {
  /// Creates a [PrNotMergeableException]. [message] is the forge's own reason.
  const PrNotMergeableException(
    super.message, {
    this.hasConflicts = false,
    super.code,
  });

  /// Whether the forge refused because the branch conflicts with its base.
  final bool hasConflicts;

  @override
  String toString() => message;
}
