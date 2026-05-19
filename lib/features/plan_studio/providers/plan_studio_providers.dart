import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Plan Studio RPC repository — reads/mutates revisions, plan documents,
/// playbooks, estimates, and drift markers over the bound-workspace session.
final planStudioRepositoryProvider = Provider<RemotePlanStudioRepository>(
  (ref) => RemotePlanStudioRepository(ref.watch(rpcClientProvider)),
);

/// Live revision history of an orchestration, oldest first (PRD 17 §5).
final orchestrationRevisionsProvider =
    StreamProvider.family<List<OrchestrationRevision>, String>(
      (ref, orchestrationId) => ref
          .watch(planStudioRepositoryProvider)
          .watchRevisions(orchestrationId),
    );

/// Live plan-mode documents in the workspace, newest first (PRD 17 §8).
final planDocumentsProvider = StreamProvider.autoDispose<List<PlanDocument>>((
  ref,
) {
  return ref.watch(planStudioRepositoryProvider).watchPlanDocuments();
});

/// Live single plan document by id.
final planDocumentProvider = StreamProvider.autoDispose
    .family<PlanDocument?, String>(
      (ref, planId) =>
          ref.watch(planStudioRepositoryProvider).watchPlanById(planId),
    );

/// Live playbooks in the workspace, by name (PRD 17 §10).
final playbooksProvider = StreamProvider.autoDispose<List<Playbook>>((ref) {
  return ref.watch(planStudioRepositoryProvider).watchPlaybooks();
});

/// Divergence markers for an executing orchestration, polled every 15s while
/// mounted (PRD 17 §6). Keyed by orchestration id; the value maps a node key
/// to `{reasons, at, held}`.
final planDivergenceProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, orchestrationId) async* {
      final repo = ref.watch(planStudioRepositoryProvider);
      yield await repo.divergence(orchestrationId);
      await for (final _ in Stream<void>.periodic(
        const Duration(seconds: 15),
      )) {
        yield await repo.divergence(orchestrationId);
      }
    });
