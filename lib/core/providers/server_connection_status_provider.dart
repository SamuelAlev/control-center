import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The live [ServerConnectionSupervisor] behind `rpcClientProvider` — the
/// source of the connection pill's path + latency + relayed/insecure state
/// (PRD 15 §8). Overridden by each composition root (desktop boot / web
/// gate); null in tests that fake the RPC client.
final serverConnectionSupervisorProvider =
    Provider<ServerConnectionSupervisor?>((ref) => null);

/// The current connection status, updated live. Null when no supervisor is
/// wired (fake clients in tests).
final serverConnectionStatusProvider = StreamProvider<ServerConnectionStatus>((
  ref,
) {
  final supervisor = ref.watch(serverConnectionSupervisorProvider);
  if (supervisor == null) {
    return const Stream.empty();
  }
  return Stream<ServerConnectionStatus>.multi((controller) {
    controller.add(supervisor.current);
    final sub = supervisor.status.listen(controller.add);
    controller.onCancel = sub.cancel;
  });
});
