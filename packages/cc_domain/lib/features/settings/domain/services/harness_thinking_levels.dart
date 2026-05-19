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

/// The effort levels to offer for a built-in-harness model, given what the
/// models.dev catalog knows about it ([info], null when the catalog has no
/// entry).
///
/// This deliberately mirrors `DispatchSession._resolveHarnessEffort`, which is
/// what actually decides whether an effort reaches the provider:
///
/// - **Catalog miss** — the run keeps thinking on and passes the requested
///   effort through unclamped, so the picker MUST appear. This is the common
///   case for a model newer than the bundled snapshot (`zai/glm-5.3`) or served
///   by a custom provider, and it is why the built-in adapter looked like it
///   had no effort knob at all: the picker renders only when the model carries
///   levels, and the harness branch never attached any.
/// - **Known reasoning model** — offer exactly the efforts it accepts, so the
///   dropdown cannot propose a level that `ThinkingConfig.resolve` will
///   silently clamp away.
/// - **Known non-reasoning model** — no levels, because the run sends no
///   reasoning at all and a knob that changes nothing is worse than no knob.
///
/// Returned as a record because [AcpModel] asserts the two travel together.
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
    levels: [
      for (final e in efforts) ThinkingLevel(id: e.id, label: e.label),
    ],
    // `resolve(null)` falls back to `efforts.first` the same way, so the
    // pre-filled level matches what a never-touched agent actually runs at.
    defaultLevel: (thinking.defaultLevel ?? efforts.first).id,
  );
}
