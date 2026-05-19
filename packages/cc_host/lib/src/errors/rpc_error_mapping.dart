import 'package:cc_domain/cc_domain.dart';

/// A handler exception classified into a stable [RpcErrorCodes] response.
class RpcErrorMapping {
  /// Creates an [RpcErrorMapping].
  const RpcErrorMapping(this.code, this.message, [this.data]);

  /// A stable code from [RpcErrorCodes].
  final int code;

  /// Client-safe message (must not embed internal paths / SQL / secrets).
  final String message;

  /// Optional structured error data.
  final Object? data;
}

/// Classifies a handler error into an [RpcErrorMapping], or null to fall back
/// to a generic internal error.
///
/// `cc_host` is generic and does not know the app's exception hierarchy
/// (`WorkspaceMismatchException`, `NotFoundException`, …). The embedding app
/// supplies a mapper that recognises its own domain exceptions and maps them to
/// codes clients can react to (e.g. roll back on a conflict). Anything the
/// mapper returns null for is logged locally and reported as a generic internal
/// error — never the raw exception text.
typedef RpcExceptionMapper = RpcErrorMapping? Function(Object error);
