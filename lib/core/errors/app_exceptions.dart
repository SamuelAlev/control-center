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

/// Exception thrown when a database operation fails.
class CacheException extends AppException {
  /// Creates a [CacheException].
  const CacheException(super.message, {super.code});
}

/// Exception thrown when an external process or CLI tool fails.
class ShellException extends AppException {
  /// Creates a [ShellException].
  const ShellException(super.message, {this.exitCode, super.code});

  /// Exit code from the process, if available.
  final int? exitCode;
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
  const ServerException(super.message, {this.cause, super.code});
  final Object? cause;
}

class ConcurrencyConflictException extends AppException {
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
