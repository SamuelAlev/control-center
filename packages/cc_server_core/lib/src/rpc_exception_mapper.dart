import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/git_repo_info.dart'
    show GitRepoInspectionException;
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart'
    show DirectoryAccessException;
import 'package:cc_host/cc_host.dart';

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
  return null;
}
