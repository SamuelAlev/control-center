import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/git_repo_info.dart'
    show GitRepoInspectionException;
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart'
    show DirectoryAccessException;
import 'package:cc_domain/core/domain/value_objects/server_owner_required.dart'
    show serverOwnerRequiredKind;
import 'package:cc_domain/core/domain/value_objects/username.dart'
    show UsernameRefusedException;
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart'
    show ForgeUnsupportedError;
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        kGitHubInstallationSuspendedCode,
        kNeedsSignInCode,
        kRepoReplacedCode,
        mapHttpException,
        needsSignInLaneOf,
        repoReplacedForgeOf;
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
  // A person action with no usable sign-in of their own: the client offers
  // that sign-in (`needs_sign_in`) instead of reporting a failure.
  if (error is NeedsSignInException) {
    return _needsSignIn(error.message, error.lane);
  }
  // The same refusal raised inside an HTTP client's interceptor (a person's
  // token lookup), which rhttp wraps.
  if (error is RhttpInterceptorException &&
      error.error is NeedsSignInException) {
    final inner = error.error as NeedsSignInException;
    return _needsSignIn(inner.message, inner.lane);
  }
  // A forge client that already classified a local refusal: the missing
  // sign-in (`ForgeCredentialUnavailable.needsSignIn`), or a linked
  // repository whose path now names another one
  // (`ForgeCredentialUnavailable.repoReplaced`).
  if (error is NetworkException &&
      (error.code == kNeedsSignInCode || error.code == kRepoReplacedCode)) {
    return _mapNetworkFailure(error);
  }
  // An op only the server owner may run, refused inside its handler: the same
  // wire shape the dispatcher's server-authority gate answers, so a client
  // maps one thing.
  if (error is ServerOwnerRequiredException) {
    return RpcErrorMapping(RpcErrorCodes.unauthorized, error.message, const {
      'kind': serverOwnerRequiredKind,
    });
  }
  // A forge refusal names its forge, so a client can say which account.
  if (error is ForgeAccessRefusedException) {
    return RpcErrorMapping(RpcErrorCodes.unauthorized, error.message, {
      'kind': error.code,
      'forge': error.forge.wire,
    });
  }
  // A missing per-repo grant: the same `{kind, level}` the dispatcher's grant
  // gates answer.
  if (error is RepoGrantRequiredException) {
    return RpcErrorMapping(
      RpcErrorCodes.unauthorized,
      error.message,
      repoGrantRequiredData(error.level),
    );
  }
  if (error is AuthException) {
    return RpcErrorMapping(
      RpcErrorCodes.unauthorized,
      error.message,
      _kindOf(error),
    );
  }
  // A merge the forge refused carries the forge's own reason, and whether it
  // was a conflict, so the merge button can offer to resolve it.
  if (error is PrNotMergeableException) {
    return RpcErrorMapping(RpcErrorCodes.prNotMergeable, error.message, {
      'has_conflicts': error.hasConflicts,
    });
  }
  // A refused username names why, so the client can localise it.
  if (error is UsernameRefusedException) {
    return RpcErrorMapping(RpcErrorCodes.validation, error.message, {
      'kind': error.reason.errorKind,
    });
  }
  if (error is ValidationException) {
    return RpcErrorMapping(
      RpcErrorCodes.validation,
      error.message,
      _kindOf(error),
    );
  }
  // A surface the repo's forge does not have. Named, so a client can tell it
  // from a failure and hide the affordance instead of reporting an error.
  if (error is ForgeUnsupportedError) {
    return RpcErrorMapping(RpcErrorCodes.validation, error.toString(), {
      'unsupported_capability': error.capability,
      'forge': error.forge.wire,
    });
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
    case kNeedsSignInCode:
      final lane = needsSignInLaneOf(error.responseBody);
      return lane == null
          ? RpcErrorMapping(RpcErrorCodes.unauthorized, error.message)
          : _needsSignIn(error.message, lane);
    // The same `{kind, forge}` a `ForgeAccessRefusedException` answers.
    case kRepoReplacedCode:
      return RpcErrorMapping(RpcErrorCodes.unauthorized, error.message, {
        'kind': kRepoReplacedCode,
        'forge': ?repoReplacedForgeOf(error.responseBody)?.wire,
      });
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

/// A refusal's authored code (`forge_cannot_read`, `repo_replaced`,
/// `repo_path.host_path`), as the `kind` a client localizes by instead of
/// reading the message. Null when the refusal names none.
Map<String, Object?>? _kindOf(AppException error) {
  final code = error.code;
  return code == null || code.isEmpty ? null : {'kind': code};
}

/// A person action with no usable sign-in of their own for [lane].
RpcErrorMapping _needsSignIn(String message, String lane) =>
    RpcErrorMapping(RpcErrorCodes.unauthorized, message, {
      'kind': 'needs_sign_in',
      'lane': lane,
    });
