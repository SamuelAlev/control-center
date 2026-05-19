import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The evals RPC helper ([RpcEvalsClient]) built over the single shared RPC
/// client (PRD 21 §5). `workspace_id` is auto-injected by the client.
final rpcEvalsClientProvider = Provider<RpcEvalsClient>((ref) {
  return RpcEvalsClient(ref.watch(rpcClientProvider));
});

/// Live eval suites for the active workspace over `evals.watchSuites`.
///
/// `autoDispose` tears the RPC subscription down when the evals tab is not
/// mounted.
final evalSuitesProvider = StreamProvider.autoDispose<List<EvalSuiteView>>((
  ref,
) {
  return ref.watch(rpcEvalsClientProvider).watchSuites();
});

/// Live runs for one suite (`suiteId`) over `evals.watchRunsForSuite`.
final evalRunsProvider = StreamProvider.autoDispose
    .family<List<EvalRunView>, String>((ref, suiteId) {
      return ref.watch(rpcEvalsClientProvider).watchRunsForSuite(suiteId);
    });
