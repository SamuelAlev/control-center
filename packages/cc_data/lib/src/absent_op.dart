import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';

/// Reads that tolerate a server which does not have the op at all.
///
/// Not every server exposes every op. A demo server removes whole families by
/// wiring no port; a server built before a feature landed has never heard of
/// it. Both answer `opUnknown`, and a READ that lets that through becomes the
/// screen: the surface renders `RemoteRpcException(-33006)` in red where its
/// content should be, which is how the public demo shipped five broken pages.
///
/// So a read that has a sensible empty answer says so here, at the one place
/// that knows the shape. Only `opUnknown` is caught — a timeout, an
/// authorization failure or a server-side crash still reaches the caller,
/// because those mean the op exists and went wrong, which is a real error a
/// screen should show.
///
/// This is deliberately NOT available for mutations. Silently reporting
/// success for a write the server never performed is worse than the error.
extension AbsentOpTolerance on RemoteRpcClient {
  /// Calls [op], answering [ifAbsent] when the server does not have it.
  Future<Map<String, dynamic>> readOr(
    String op,
    Map<String, dynamic> args,
    Map<String, dynamic> ifAbsent,
  ) async {
    try {
      return await call(op, args);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return ifAbsent;
      }
      rethrow;
    }
  }
}
