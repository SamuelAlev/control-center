import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;

/// Whether a failed RPC call is worth sending again unchanged.
///
/// A [RemoteRpcException] is the server's answer about this request: only a
/// pre-dispatch refusal (the session's request budget or in-flight cap) or a
/// handler that ran out of time can succeed on a later attempt. Anything else
/// (no such session, invalid arguments, denied) will fail the same way again.
///
/// Every other failure means the call never got an answer: the request timed
/// out, the client closed for a reconnect, or the transport failed while
/// sending. Whether the server applied it is unknown, so only a call the server
/// can recognize as a repeat (a sequence number or idempotency key) may be
/// retried on this basis.
bool isTransientRpcFailure(Object error) => switch (error) {
  RemoteRpcException(:final code) =>
    code == RpcErrorCodes.rateLimited || code == RpcErrorCodes.handlerTimeout,
  _ => true,
};
