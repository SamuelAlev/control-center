/// Transport-level exceptions for the phone→Mac RPC link.
///
/// The transport contract itself ([incoming]/[state]/[isOpen]/[send]/[close],
/// with the [RemoteChannelState] enum) now comes from `package:cc_rpc`'s
/// [RemoteRpcChannelPort] — the phone's [RtcTransport] and [RelayRpcChannel]
/// implement that interface directly, so there is no longer a phone-local
/// `RpcChannel`/`RpcChannelState` duplicate. Only the two thrown exceptions
/// (which cc_rpc does not define) remain here.
library;

class RpcNotConnectedException implements Exception {
  const RpcNotConnectedException([this.message = 'Not connected to your Mac']);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when an RPC does not receive a response within the deadline.
class RpcTimeoutException implements Exception {
  const RpcTimeoutException(this.method);

  final String method;

  @override
  String toString() => 'Timed out waiting for a response to $method';
}
