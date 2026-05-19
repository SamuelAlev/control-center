import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web default for `rpcClientProvider`: there is no in-process host on web, so
/// the composition root MUST override `rpcClientProvider` with a connected
/// [RemoteRpcClient] after the connect/PSK handshake. Reaching this throw means
/// a screen tried to read the client before the web app finished connecting.
RemoteRpcClient defaultRpcClient(Ref ref) => throw UnimplementedError(
  'rpcClientProvider must be overridden with a connected RemoteRpcClient on '
  'web (the web composition root installs it after the handshake).',
);
