import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:control_center/core/providers/rpc_client_default_io.dart'
    if (dart.library.js_interop) 'package:control_center/core/providers/rpc_client_default_web.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single RPC client the entire UI talks to.
///
/// Web-safe by construction: it depends only on `cc_rpc` + Riverpod and resolves
/// its default through a conditional import, so the same feature providers (the
/// `cc_data` `RpcX` repositories) drive both targets without any per-feature
/// platform binding — they all just `ref.watch(rpcClientProvider)`:
///
///  - Both **desktop** and **web** default to throwing — there is no
///    in-process host on either target. `cc_server` is the sole owner of the
///    database, MCP registry and execution; the desktop composition root
///    spawns or connects to it and overrides this provider with the
///    connected [RemoteRpcClient] after the handshake, exactly like web's
///    connect flow.
final rpcClientProvider = Provider<RemoteRpcClient>(defaultRpcClient);
