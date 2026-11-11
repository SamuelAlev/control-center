import 'package:cc_domain/cc_domain.dart' show ServerOwnerRequiredException;
import 'package:cc_domain/core/domain/value_objects/server_owner_required.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// The one place a refusal for "only the server owner may do this" becomes
/// typed.
///
/// Every op the server declares owner-only answers `unauthorized` with
/// `data: {kind: server_owner_required}`; this reads that shape once, so no
/// call site parses it.
ServerOwnerRequiredException? serverOwnerRequiredOf(Object? error) =>
    switch (error) {
      ServerOwnerRequiredException() => error,
      RemoteRpcException() => serverOwnerRequiredFromRpc(
        code: error.code,
        message: error.message,
        data: error.data,
      ),
      _ => null,
    };

/// Calls owner-only ops, raising [ServerOwnerRequiredException] instead of
/// the raw RPC error when the server refuses one for that reason.
extension ServerOwnerCalls on RemoteRpcClient {
  /// [call], with the owner-only refusal typed.
  Future<Map<String, dynamic>> callAsOwner(
    String op,
    Map<String, dynamic> args,
  ) async {
    try {
      return await call(op, args);
    } on RemoteRpcException catch (e) {
      throw serverOwnerRequiredOf(e) ?? e;
    }
  }
}
