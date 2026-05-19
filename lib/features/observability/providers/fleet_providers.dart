import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fleet RPC helper ([RpcFleetClient]) built over the single shared RPC
/// client (PRD 20 §7). `workspace_id` is auto-injected by the client, so this
/// works identically on desktop and web.
final rpcFleetClientProvider = Provider<RpcFleetClient>((ref) {
  return RpcFleetClient(ref.watch(rpcClientProvider));
});

/// Live fleet workers (server-global) over `fleet.watchWorkers`.
///
/// `autoDispose` tears the RPC subscription down when the fleet tab is not
/// mounted.
final fleetWorkersProvider = StreamProvider.autoDispose<List<FleetWorkerView>>((
  ref,
) {
  return ref.watch(rpcFleetClientProvider).watchWorkers();
});

/// Live fleet jobs for the active workspace over `fleet.watchJobs`.
final fleetJobsProvider = StreamProvider.autoDispose<List<FleetJobView>>((ref) {
  return ref.watch(rpcFleetClientProvider).watchJobs();
});

/// Live placement decisions for one job (`jobId`) over `fleet.watchPlacements`.
final fleetPlacementsProvider = StreamProvider.autoDispose
    .family<List<FleetPlacementView>, String>((ref, jobId) {
      return ref.watch(rpcFleetClientProvider).watchPlacements(jobId);
    });
