import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:cc_domain/src/rpc/protocol.dart' show RpcErrorCodes;

/// The `data.kind` a server answers, with its unauthorized code, for any op
/// only the server owner may run (`serverAuthority: serverOwner`), such as
/// `workspace.create` or `codeServer.open`.
const String serverOwnerRequiredKind = 'server_owner_required';

/// The [ServerOwnerRequiredException] an RPC error carries, or null when it is
/// any other refusal: only `unauthorized` with `data.kind:
/// server_owner_required` counts.
///
/// The one reading of that wire shape; a transport calls it with the fields
/// of its own error type, so a client says "only the server owner can do
/// this" in its own words instead of showing a raw RPC error.
ServerOwnerRequiredException? serverOwnerRequiredFromRpc({
  required int code,
  required String message,
  Object? data,
}) =>
    code == RpcErrorCodes.unauthorized &&
        data is Map &&
        data['kind'] == serverOwnerRequiredKind
    ? ServerOwnerRequiredException(message)
    : null;
