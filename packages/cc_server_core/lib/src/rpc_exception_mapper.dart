import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/git_repo_info.dart'
    show GitRepoInspectionException;
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart'
    show DirectoryAccessException;
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart'
    show kGitHubInstallationSuspendedCode, mapHttpException;
import 'package:rhttp/rhttp.dart';

/// Maps the app's domain exceptions to stable [RpcErrorCodes] for the cc_host
/// [RepoOpDispatcher] (which is generic and cannot know this hierarchy).
///
/// Only client-actionable exceptions are mapped; everything else returns null
/// so the dispatcher logs it locally and reports a generic internal error
/// (never leaking raw exception text, which can embed paths / SQL / secrets).
/// The mapped `message` comes from [AppException.message], which is authored to
/// be client-safe.
RpcErrorMapping? mapAppExceptionToRpc(Object error) {
  if (error is WorkspaceMismatchException) {
    return RpcErrorMapping(RpcErrorCodes.workspaceMismatch, error.message);
  }
  if (error is NotFoundException) {
    return RpcErrorMapping(RpcErrorCodes.notFound, error.message);
  }
  if (error is ConcurrencyConflictException) {
    return RpcErrorMapping(RpcErrorCodes.conflict, error.message);
  }
  if (error is AuthException) {
    return RpcErrorMapping(RpcErrorCodes.unauthorized, error.message);
  }
  // A merge the forge refused carries the forge's own reason, and whether it
  // was a conflict, so the merge button can offer to resolve it.
  if (error is PrNotMergeableException) {
    return RpcErrorMapping(RpcErrorCodes.prNotMergeable, error.message, {
      'has_conflicts': error.hasConflicts,
    });
  }
  if (error is ValidationException) {
    return RpcErrorMapping(RpcErrorCodes.validation, error.message);
  }
  // `repos.addFromPath` rejects a non-GitHub checkout with a client-safe reason
  // (no path/secret leakage) — surface it so the web add-repo form can show it.
  if (error is GitRepoInspectionException) {
    return RpcErrorMapping(RpcErrorCodes.validation, error.message);
  }
  // `fs.browseDirectory` refuses a path outside the allow-listed roots (or one
  // that is not an accessible directory) with a client-safe reason — surface it
  // so the web folder browser can show why a folder could not be opened.
  if (error is DirectoryAccessException) {
    return RpcErrorMapping(RpcErrorCodes.validation, error.message);
  }
  // A cancellation is a subscriber/orchestrator standing down, not a failure.
  // `mapHttpException` deliberately has no cancel branch (it would fall through
  // as `network_error`), so map it explicitly here — otherwise the dispatcher
  // logs it as an internal error. Stream-shaped callers already check the type
  // before mapping; this is the non-stream safety net.
  if (error is RhttpCancelException) {
    return const RpcErrorMapping(
      RpcErrorCodes.requestCancelled,
      'Request cancelled',
    );
  }
  // A raw transport failure reaches here when a forge client deliberately lets
  // a status through (GitLab/Bitbucket's optional-status branches) rather than
  // wrapping it in a domain exception. Classify it the way the client would
  // have — [mapHttpException] preserves the status and its code — so a 404/401
  // is reported as notFound/unauthorized instead of a generic internal error.
  if (error is RhttpException) {
    return _mapNetworkFailure(mapHttpException(error));
  }
  return null;
}

/// Classifies an HTTP failure surfaced by a forge client, by its error code
/// (preferred) or, failing that, its status. Unrecognised failures return null
/// so the dispatcher records them locally and reports a generic internal error.
RpcErrorMapping? _mapNetworkFailure(NetworkException error) {
  switch (error.code) {
    case 'bad_request':
    case 'not_acceptable':
    case 'diff_too_large':
    case 'unprocessable_entity':
      return RpcErrorMapping(RpcErrorCodes.validation, error.message);
    case 'rate_limited':
      return RpcErrorMapping(RpcErrorCodes.rateLimited, error.message);
    case 'auth_error':
    // A suspended GitHub App installation (403) needs a human to resume it,
    // which is an authorization failure from the caller's point of view; the
    // [message] already says so. Mapped explicitly rather than left to the 403
    // fallback so the intent is recorded (and holds if the status ever moves).
    case kGitHubInstallationSuspendedCode:
      return RpcErrorMapping(RpcErrorCodes.unauthorized, error.message);
    case 'not_found':
      return RpcErrorMapping(RpcErrorCodes.notFound, error.message);
    case 'conflict':
      return RpcErrorMapping(RpcErrorCodes.conflict, error.message);
  }
  switch (error.statusCode) {
    case 400:
    case 422:
      return RpcErrorMapping(RpcErrorCodes.validation, error.message);
    case 401:
    case 403:
      return RpcErrorMapping(RpcErrorCodes.unauthorized, error.message);
    case 404:
      return RpcErrorMapping(RpcErrorCodes.notFound, error.message);
    case 409:
      return RpcErrorMapping(RpcErrorCodes.conflict, error.message);
    case 429:
      return RpcErrorMapping(RpcErrorCodes.rateLimited, error.message);
    default:
      return null;
  }
}
