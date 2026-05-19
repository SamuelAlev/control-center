import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/services/fact_extraction.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';

/// Passive fact extraction: turns free-text agent/user conversation into typed
/// memory facts without an explicit `propose_fact` call. Ported from oh-my-pi
/// mnemopi `core/extraction.ts`, recorded through the shared writer so the
/// extracted facts get the same typing/veracity/conflict treatment.
class ExtractMemoryUseCase {
  /// Creates an [ExtractMemoryUseCase].
  const ExtractMemoryUseCase({
    required MemoryExtractor extractor,
    required RecordMemoryFactUseCase recordFact,
  })  : _extractor = extractor,
        _recordFact = recordFact;

  final MemoryExtractor _extractor;
  final RecordMemoryFactUseCase _recordFact;

  /// Extracts and records facts from [text]. Returns the number of facts
  /// recorded (created or deduped). Best-effort: never throws.
  Future<int> extractAndRecord({
    required String workspaceId,
    required String text,
    String? authoredByAgentId,
    AgentRole authorRole = AgentRole.general,
  }) async {
    ExtractionResult result;
    try {
      result = await _extractor.extract(text);
    } on Object {
      return 0;
    }
    if (result.isEmpty) {
      return 0;
    }
    var recorded = 0;
    for (final item in result.toTypedItems()) {
      try {
        final outcome = await _recordFact.record(
          workspaceId: workspaceId,
          domain: _domainFor(item.type),
          topic: _topicFor(item.type),
          content: item.content,
          confidence: 0.7,
          authoredByAgentId: authoredByAgentId,
          authorRole: authorRole,
          memoryType: item.type,
          veracity: MemoryVeracity.inferred,
        );
        if (outcome != null) {
          recorded++;
        }
      } on Object {
        // Skip the individual item; keep extracting the rest.
      }
    }
    return recorded;
  }

  String _domainFor(MemoryType type) {
    switch (type) {
      case MemoryType.preference:
        return 'preferences';
      case MemoryType.instruction:
        return 'instructions';
      case MemoryType.event:
        return 'timeline';
      default:
        return 'extracted';
    }
  }

  String _topicFor(MemoryType type) {
    switch (type) {
      case MemoryType.preference:
        return 'user preferences';
      case MemoryType.instruction:
        return 'standing instructions';
      case MemoryType.event:
        return 'timeline';
      default:
        return 'extracted facts';
    }
  }
}