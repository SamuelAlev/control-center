import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';

/// Supersedes one fact with another, marking the original as outdated.
class SupersedeFactUseCase {
  /// Creates a [SupersedeFactUseCase].
  SupersedeFactUseCase({required MemoryFactRepository factRepository})
      : _factRepository = factRepository;

  final MemoryFactRepository _factRepository;

  /// Marks [factId] as superseded by [supersedingFactId] within [workspaceId].
  ///
  /// Returns the updated fact.
  Future<MemoryFact> execute({
    required String workspaceId,
    required String factId,
    required String supersedingFactId,
  }) async {
    // The lookup is scoped to [workspaceId], so a fact owned by another
    // workspace is simply not found — never let one workspace supersede
    // another's fact (fact ids are global UUIDs, so the scope is the barrier).
    final fact = await _factRepository.getById(workspaceId, factId);
    if (fact == null) {
      throw ArgumentError('Fact not found: $factId');
    }

    final superseded = fact.copyWith(
      supersededBy: supersedingFactId,
      updatedAt: DateTime.now(),
    );

    await _factRepository.upsert(superseded);
    return superseded;
  }
}
