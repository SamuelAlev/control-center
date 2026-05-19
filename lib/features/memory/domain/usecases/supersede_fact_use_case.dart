import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';

class SupersedeFactUseCase {
  SupersedeFactUseCase({required MemoryFactRepository factRepository})
      : _factRepository = factRepository;

  final MemoryFactRepository _factRepository;

  Future<MemoryFact> execute({
    required String workspaceId,
    required String factId,
    required String supersedingFactId,
  }) async {
    final fact = await _factRepository.getById(factId);
    if (fact == null) {
      throw ArgumentError('Fact not found: $factId');
    }
    // Facts are workspace-scoped: never let one workspace supersede another's
    // fact (fact ids are global UUIDs, so this guard is the only barrier).
    if (fact.workspaceId != workspaceId) {
      throw ArgumentError(
        'Fact $factId does not belong to workspace $workspaceId',
      );
    }

    final superseded = fact.copyWith(
      supersededBy: supersedingFactId,
      updatedAt: DateTime.now(),
    );

    await _factRepository.upsert(superseded);
    return superseded;
  }
}
