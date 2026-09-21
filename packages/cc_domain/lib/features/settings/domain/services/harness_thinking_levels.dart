import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_harness/provider.dart' show ReasoningEffort;

/// Every effort the built-in harness can express, least → most intensive.
///
/// The CLI adapters each ship a curated vocabulary (`basicThinkingLevels`,
/// `openaiThinkingLevels`, `claudeThinkingLevels`) because their effort is a
/// flag on someone else's binary. The harness owns its own scale — one knob
/// remapped per provider at the request boundary by `effort_mapping.dart` — so
/// the full [ReasoningEffort] enum is the honest list, `minimal` included.
final List<ThinkingLevel> harnessEffortLevels = [
  for (final e in ReasoningEffort.values)
    ThinkingLevel(id: e.id, label: e.label),
];

/// Effort levels for a built-in-harness model ([info] from models.dev, or null).
///
/// Mirrors `DispatchSession._resolveHarnessEffort`: catalog miss → show picker
/// (unclamped); known reasoning → exact accepted efforts; known non-reasoning
/// → none. Returned as a record ([AcpModel] asserts the pair).
({List<ThinkingLevel>? levels, String? defaultLevel}) harnessThinkingLevels(
  ModelInfo? info,
) {
  if (info == null) {
    return (
      levels: harnessEffortLevels,
      defaultLevel: ReasoningEffort.medium.id,
    );
  }
  final thinking = info.thinking;
  if (thinking == null || thinking.efforts.isEmpty) {
    return (levels: null, defaultLevel: null);
  }
  final efforts = thinking.efforts;
  return (
    levels: [for (final e in efforts) ThinkingLevel(id: e.id, label: e.label)],
    // `resolve(null)` falls back to `efforts.first` the same way, so the
    // pre-filled level matches what a never-touched agent actually runs at.
    defaultLevel: (thinking.defaultLevel ?? efforts.first).id,
  );
}
