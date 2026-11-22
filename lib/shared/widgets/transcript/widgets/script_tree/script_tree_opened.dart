import 'package:cc_domain/features/code_mode/domain/services/script_run_view_lines.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How far the reader has opened the long groups of script call trees, by
/// tree scope (one script call, or one execution record), then by group key:
/// how many of the group's hidden calls are shown.
///
/// Held above the rows, so an opened group stays open when its script row is
/// collapsed and reopened, scrolls away and back, or rebuilds while the
/// script streams. In memory only, and bounded: past [maxScopes] trees the
/// one opened longest ago is forgotten.
class ScriptTreeOpenedNotifier extends Notifier<Map<String, Map<String, int>>> {
  /// How many trees keep their opened groups.
  static const int maxScopes = 256;

  @override
  Map<String, Map<String, int>> build() => const {};

  /// Shows [scriptFoldStep] more hidden calls of the group [key] of the
  /// tree [scope].
  void open(String scope, String key) {
    final current = state[scope] ?? const <String, int>{};
    // Insertion order is recency: the scope just touched moves to the end.
    final next = {
      for (final entry in state.entries)
        if (entry.key != scope) entry.key: entry.value,
      scope: {...current, key: (current[key] ?? 0) + scriptFoldStep},
    };
    while (next.length > maxScopes) {
      next.remove(next.keys.first);
    }
    state = next;
  }
}

/// See [ScriptTreeOpenedNotifier]. A tree watches its own scope with
/// `select((opened) => opened[scope])`, so opening a group rebuilds only the
/// tree it belongs to.
final scriptTreeOpenedProvider =
    NotifierProvider<ScriptTreeOpenedNotifier, Map<String, Map<String, int>>>(
      ScriptTreeOpenedNotifier.new,
    );

/// The scope of the tree under the script call [toolCallId] started at
/// [startedAt]: call ids repeat across turns, the pair does not.
String scriptTreeScope(String toolCallId, DateTime startedAt) =>
    '$toolCallId@${startedAt.microsecondsSinceEpoch}';
