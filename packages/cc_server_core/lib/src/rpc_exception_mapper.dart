import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/git_repo_info.dart'
    show GitRepoInspectionException;
import 'package:cc_domain/core/domain/ports/database_backup_port.dart'
    show WorkspaceImportRefusal, WorkspaceImportRefusedException;
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart'
    show DirectoryAccessException;
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_domain/core/domain/value_objects/server_owner_required.dart'
    show serverOwnerRequiredKind;
import 'package:cc_domain/core/domain/value_objects/username.dart'
    show UsernameRefusedException;
import 'package:cc_domain/core/domain/value_objects/workspace_storage_state.dart'
    show workspaceReadOnlyKind;
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
import 'package:cc_persistence/database/schema/converged_database.dart'
    show
        DatabaseDamagedException,
        DatabaseNewerThanBinaryException,
        ForeignDatabaseFileException;
import 'package:cc_persistence/database/utils/storage_errors.dart';
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
  // A storage failure is classified before anything else: drift wraps the
  // SQLite error, and its own text carries the statement's bound values.
  final storage = storageFailureOf(error);
  if (storage != null) {
    return _mapStorageFailure(storage, error);
  }
  final database = _mapDatabaseRefusal(error);
  if (database != null) {
    return database;
  }
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
  // A workspace file the import refused: nothing was replaced. The kind is
  // the refusal's (`import.damaged`, `import.newer_schema`, ...), and a newer
  // file names both schema versions, as `storage.newer_schema` does.
  if (error is WorkspaceImportRefusedException) {
    return RpcErrorMapping(RpcErrorCodes.validation, error.message, {
      'kind': error.refusal.kind,
      if (error.refusal == WorkspaceImportRefusal.newerSchema) ...{
        'file_version': ?error.fileVersion,
        'server_version': ?error.serverVersion,
      },
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
RpcErrorMapping _needsSignIn(String message, String lane) => RpcErrorMapping(
  RpcErrorCodes.unauthorized,
  message,
  {'kind': 'needs_sign_in', 'lane': lane},
);

/// The `data.kind` of a write refused because the database stayed locked by
/// another writer past the busy timeout. Retrying later can succeed.
const storageBusyKind = 'storage.busy';

/// The `data.kind` of a write refused because the disk (or the database's size
/// limit) is full.
const storageFullKind = 'storage.full';

/// The `data.kind` of a request that hit damage in a workspace's database
/// file. Only restoring a snapshot ends it.
const storageDamagedKind = 'storage.damaged';

/// The `data.kind` of a request for a database a newer server version wrote.
/// `data.file_version` and `data.server_version` carry the two schema
/// versions.
const storageNewerSchemaKind = 'storage.newer_schema';

/// The `data.kind` of a request for a database file this server did not
/// write for that purpose.
const storageForeignFileKind = 'storage.foreign_file';

/// The `data.kind` of a request that names a workspace which was deleted.
const workspaceDeletedKind = 'workspace.deleted';

/// A log-safe one-line description of [error], for the dispatcher's failure
/// log lines. A storage error is rendered as its result code, message and
/// statement, never the bound parameter values its own `toString` appends
/// (message bodies, tokens). Anything else is its usual text.
String describeErrorForLog(Object error) =>
    describeStorageError(error) ?? error.toString();

/// A database the server will not open, or a workspace that is gone.
///
/// The messages are written here and not taken from the exceptions, whose
/// text names files and ids for the operator's log.
RpcErrorMapping? _mapDatabaseRefusal(Object error) => switch (error) {
  DatabaseNewerThanBinaryException() => RpcErrorMapping(
    RpcErrorCodes.internalError,
    'This data was written by a newer server version; update the server',
    {
      'kind': storageNewerSchemaKind,
      'file_version': error.fileVersion,
      'server_version': error.binaryVersion,
    },
  ),
  ForeignDatabaseFileException() => const RpcErrorMapping(
    RpcErrorCodes.internalError,
    'The database file on the server is not one this server wrote',
    {'kind': storageForeignFileKind},
  ),
  DatabaseDamagedException() => const RpcErrorMapping(
    RpcErrorCodes.internalError,
    "This workspace's database is damaged and must be restored",
    {'kind': storageDamagedKind},
  ),
  DeletedWorkspaceException() => const RpcErrorMapping(
    RpcErrorCodes.notFound,
    'This workspace was deleted',
    {'kind': workspaceDeletedKind},
  ),
  _ => null,
};

/// Busy/locked, full, damaged and read-only get their own kind, so a client
/// can say "try again", "the server's disk is full" or "this workspace needs
/// restoring" instead of a bare internal error. Every other storage failure
/// stays unmapped: the dispatcher logs it (through [describeErrorForLog])
/// under a diagnostic id.
RpcErrorMapping? _mapStorageFailure(StorageFailure failure, Object error) {
  final (kind, message) = switch (failure) {
    StorageFailure.busy => (storageBusyKind, 'The database is busy; try again'),
    StorageFailure.full => (storageFullKind, 'The server is out of disk space'),
    StorageFailure.damaged => (
      storageDamagedKind,
      "This workspace's database is damaged and must be restored",
    ),
    StorageFailure.readOnly => (
      workspaceReadOnlyKind,
      'This workspace is read-only: its database failed an integrity check',
    ),
    StorageFailure.other => (null, null),
  };
  if (kind == null || message == null) {
    return null;
  }
  CcHostLog.warning('repo/call storage refusal: ${describeErrorForLog(error)}');
  return RpcErrorMapping(RpcErrorCodes.internalError, message, {'kind': kind});
}
