part of 'knowledge_graph.dart';

extension _ActionMethods on _KnowledgeGraphState {
  /// Reconcile the [ValueNotifier] position store with the freshly computed
  /// [positions]: reuse notifiers for surviving keys (updating their value),
  /// create notifiers for new keys and dispose notifiers for removed keys.
  ///
  /// Removed notifiers are disposed in a post-frame callback so we never
  /// dispose one while a [ValueListenableBuilder] still listens to it during
  /// this frame's rebuild.
  void _syncPositions(Map<String, Offset> positions) {
    final removed = _positions.keys
        .where((key) => !positions.containsKey(key))
        .toList();
    final orphaned = <ValueNotifier<Offset>>[];
    for (final key in removed) {
      orphaned.add(_positions.remove(key)!);
      _pinned.remove(key);
    }

    for (final entry in positions.entries) {
      final existing = _positions[entry.key];
      if (existing != null) {
        // A node the operator moved keeps its place across data refreshes.
        if (!_pinned.contains(entry.key)) {
          existing.value = entry.value;
        }
      } else {
        _positions[entry.key] = ValueNotifier<Offset>(entry.value);
      }
    }

    if (orphaned.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final notifier in orphaned) {
          notifier.dispose();
        }
      });
    }
  }
}
