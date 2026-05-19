/// Model retry-fallback chain resolution for subagent dispatch.
///
/// When an agent declares `model: [a, b, c]`, the selected model is tried
/// first; if it fails, the run falls back to the candidates that come after it
/// in declaration order. The chain is suppressed when an auth fallback has
/// already been used or when there is only one candidate to choose from.
///
/// Ported from oh-my-pi `task/executor.ts` (`resolveSubagentRetryFallback` /
/// `installSubagentRetryFallbackChain`).
library;

/// Resolves the ordered fallback selectors that come after [selectedModel] in
/// [candidates].
///
/// Returns `const []` (no fallback) when any of the following hold, mirroring
/// oh-my-pi's guards:
/// - [selectedModel] is `null`,
/// - [authFallbackUsed] is `true` (an auth fallback already consumed a retry),
/// - [candidates] has one or zero entries,
/// - [selectedModel] is not present in [candidates], or
/// - [selectedModel] is the last candidate (nothing follows it).
List<String> resolveModelFallbackChain({
  required List<String> candidates,
  required String? selectedModel,
  required bool authFallbackUsed,
}) {
  if (selectedModel == null) {
    return const [];
  }
  if (authFallbackUsed) {
    return const [];
  }
  if (candidates.length <= 1) {
    return const [];
  }
  final selectedIndex = candidates.indexOf(selectedModel);
  if (selectedIndex < 0) {
    return const [];
  }
  final fallbacks = candidates.sublist(selectedIndex + 1);
  if (fallbacks.isEmpty) {
    return const [];
  }
  return List<String>.unmodifiable(fallbacks);
}

/// A resolved fallback plan: the [selected] model selector and the ordered
/// [fallbacks] to try if it fails.
class ModelFallbackPlan {
  /// Creates a [ModelFallbackPlan].
  const ModelFallbackPlan({
    required this.selected,
    required this.fallbacks,
  });

  /// Resolves a plan from [candidates] and the [selectedModel], applying the
  /// same guards as [resolveModelFallbackChain].
  factory ModelFallbackPlan.resolve({
    required List<String> candidates,
    required String? selectedModel,
    required bool authFallbackUsed,
  }) {
    return ModelFallbackPlan(
      selected: selectedModel,
      fallbacks: resolveModelFallbackChain(
        candidates: candidates,
        selectedModel: selectedModel,
        authFallbackUsed: authFallbackUsed,
      ),
    );
  }

  /// The model selector tried first, or `null` when none was selected.
  final String? selected;

  /// The ordered selectors to try after [selected] fails. Empty when there is
  /// no fallback chain.
  final List<String> fallbacks;

  /// Whether this plan has any fallback candidates.
  bool get hasFallback => fallbacks.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelFallbackPlan &&
          runtimeType == other.runtimeType &&
          selected == other.selected &&
          _listEquals(fallbacks, other.fallbacks);

  @override
  int get hashCode => Object.hash(selected, Object.hashAll(fallbacks));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
