/// Transport-agnostic JSON-RPC client and channel transports for Control Center.
///
/// This is the *behavioural* half of the RPC layer — `cc_domain` holds the
/// passive wire types (`JsonRpcRequest`, `RpcMethods`, `RpcErrorCodes`, DTOs),
/// and this package adds the client, the channel abstraction, and the concrete
/// transports that move frames. It is web-safe (no `dart:io`/`dart:ffi`): the
/// same code dials a cc-server from the desktop in REMOTE mode, from the full
/// web build, and from the `cc_remote` PWA.
///
/// The server half (sessions, repo-op dispatch, subscriptions, the WSS server)
/// lives in `cc_host`, which depends on this package for the shared
/// `RpcDispatcher` seam and `RemoteRpcChannelPort`.
library;

export 'src/channel/in_process_rpc_channel.dart';
export 'src/channel/remote_rpc_channel_port.dart';
export 'src/channel/ws_client_channel.dart';
export 'src/client/remote_rpc_client.dart';
export 'src/crypto/relay_frame_crypto.dart';
export 'src/crypto/remote_control_crypto.dart';
export 'src/rpc_dispatcher.dart';
