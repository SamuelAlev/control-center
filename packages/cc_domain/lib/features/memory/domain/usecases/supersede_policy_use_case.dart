import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';

/// Retires a memory policy by marking it inactive within its workspace.
///
/// Mirrors `SupersedeFactUseCase`: the lookup is scoped to `workspaceId`, so a
/// policy owned by another workspace is simply not found — one workspace can
/// never retire another's policy (policy ids are global UUIDs, so the workspace
/// clause is the isolation boundary, not id uniqueness). The row is kept
/// (`active = false`) rather than deleted so the audit trail and any
/// `rule://` references survive.
class SupersedePolicyUseCase {
  /// Creates a [SupersedePolicyUseCase].
  SupersedePolicyUseCase({required MemoryPolicyRepository policyRepository})
      : _policyRepository = policyRepository;

  final MemoryPolicyRepository _policyRepository;

  /// Marks [policyId] inactive within [workspaceId]. Returns the updated policy.
  ///
  /// Throws [ArgumentError] when no active-or-inactive policy with that id
  /// exists in the workspace.
  Future<MemoryPolicy> execute({
    required String workspaceId,
    required String policyId,
  }) async {
    final policy = await _policyRepository.getById(workspaceId, policyId);
    if (policy == null) {
      throw ArgumentError('Policy not found: $policyId');
    }

    final retired = policy.copyWith(active: false, updatedAt: DateTime.now());
    await _policyRepository.upsert(retired);
    return retired;
  }
}
