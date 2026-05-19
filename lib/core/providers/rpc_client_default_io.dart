import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Desktop default for `rpcClientProvider`: there is none.
///
/// Selected by the conditional import in `rpc_client_provider.dart` on the VM.
/// The desktop is a thin client exactly like web — it opens no database and
/// hosts no in-process server — so it has no self-serve client to default to.
/// The composition root (`bootstrap_io.dart`) MUST override this with a live
/// [RemoteRpcClient] obtained from the spawned-or-remote `cc_server` connect
/// handshake, mirroring `rpc_client_default_web.dart`.
RemoteRpcClient defaultRpcClient(Ref ref) => throw UnimplementedError(
  'rpcClientProvider must be overridden with a connected RemoteRpcClient '
  '(the desktop composition root installs it after the spawn/connect '
  'handshake).',
);
