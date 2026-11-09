import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single RPC client the entire UI talks to.
///
/// Web-safe by construction: it depends only on `cc_rpc` + Riverpod, so the
/// same feature providers (the `cc_data` `RpcX` repositories) drive desktop and
/// web without any per-feature platform binding — they all just
/// `ref.watch(rpcClientProvider)`.
///
/// No client hosts a server: `cc_server` is the sole owner of the database,
/// MCP registry and execution. Each composition root (`bootstrap_io.dart`,
/// `bootstrap_web.dart`) overrides this provider with the connected
/// [RemoteRpcClient] after the handshake, so reaching the default means a
/// screen read the client before the session was connected.
final rpcClientProvider = Provider<RemoteRpcClient>(
  (ref) => throw UnimplementedError(
    'rpcClientProvider must be overridden with a connected RemoteRpcClient '
    '(the composition root installs it after the connect handshake).',
  ),
);
