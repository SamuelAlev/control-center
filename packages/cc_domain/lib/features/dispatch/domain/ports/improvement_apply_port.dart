import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';

/// The one write an accepted (or rolled-back) text proposal makes to a
/// memory fact, a policy or an agent's notes, applied only while the target
/// is still the row the plan read.
///
/// `expected` is the row as read (null: there must be none); the write
/// replaces it with the new row (null: deletes it).
sealed class ImprovementTextWrite {
  const ImprovementTextWrite();
}

/// A memory fact's write.
final class ImprovementFactWrite extends ImprovementTextWrite {
  /// Creates the write.
  const ImprovementFactWrite({required this.expected, required this.fact});

  /// The fact as read, or null when there must be none.
  final MemoryFact? expected;

  /// The fact to store, or null to delete [expected].
  final MemoryFact? fact;
}

/// A policy's write.
final class ImprovementPolicyWrite extends ImprovementTextWrite {
  /// Creates the write.
  const ImprovementPolicyWrite({required this.expected, required this.policy});

  /// The policy as read, or null when there must be none.
  final MemoryPolicy? expected;

  /// The policy to store, or null to delete [expected].
  final MemoryPolicy? policy;
}

/// An agent's notes' write.
final class ImprovementNoteWrite extends ImprovementTextWrite {
  /// Creates the write.
  const ImprovementNoteWrite({required this.expected, required this.note});

  /// The notes as read, or null when the agent has none.
  final AgentWorkingMemory? expected;

  /// The notes to store.
  final AgentWorkingMemory note;
}

/// What [ImprovementApplyPort.decideAndWrite] did.
enum ImprovementApplyOutcome {
  /// The proposal moved and the write is in place.
  applied,

  /// Someone else decided the proposal first; nothing was written.
  alreadyDecided,

  /// The target is no longer the row the plan read; nothing was written
  /// and the proposal did not move.
  changedSince,
}

/// Moves a text proposal and applies its write in one transaction of its
/// workspace's database, so a crash leaves neither half and a write that
/// landed between the plan and the claim is never overwritten.
abstract interface class ImprovementApplyPort {
  /// Moves proposal [id] from [from] to [to] (recording [decidedByUserId],
  /// [now] and the texts when given) and applies [write], or does neither.
  Future<ImprovementApplyOutcome> decideAndWrite(
    String workspaceId, {
    required String id,
    required ImprovementStatus from,
    required ImprovementStatus to,
    required String decidedByUserId,
    required String? beforeText,
    required String? afterText,
    required String? appliedRef,
    required DateTime now,
    required ImprovementTextWrite write,
  });
}
