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
///  - **desktop self-serve** defaults to an in-process host client
///    (`inProcessRpcClientProvider`), which owns the local Drift database; the
///    FFI/server stack it pulls only ever compiles on the VM.
///  - **web** has no in-process host, so the default throws — the web
///    composition root MUST override this with a live [RemoteRpcClient]
///    obtained from the connect/PSK handshake.
///  - **desktop-connected-to-remote** likewise overrides it with a connected
///    client instead of self-serving.
final rpcClientProvider = Provider<RemoteRpcClient>(defaultRpcClient);
