import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:control_center/features/remote_control/providers/remote_control_server_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Desktop default for `rpcClientProvider`: the in-process host client (the
/// desktop self-serving its own data over a loopback [RemoteRpcClient]).
///
/// Selected by the conditional import in `rpc_client_provider.dart` on the VM.
/// It reads [inProcessRpcClientProvider], which transitively pulls the Drift
/// database + the in-process server stack — code that only ever compiles for the
/// VM, never web. A desktop build that connects to a *remote* server overrides
/// `rpcClientProvider` at the composition root instead of using this default.
RemoteRpcClient defaultRpcClient(Ref ref) =>
    ref.watch(inProcessRpcClientProvider);
