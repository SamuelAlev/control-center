import 'package:cc_data/cc_data.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Both suite runs and campaign UI share the same typed RPC helper. Legacy
/// suites remain session-bound; campaign calls pass explicit workspace IDs.
final rpcEvalsClientProvider = skillCampaignClientProvider;

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
