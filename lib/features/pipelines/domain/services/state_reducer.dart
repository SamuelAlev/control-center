import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart' show PipelineNodeConfig;

/// Combines a new value with an existing value when a pipeline step writes a
/// state key that already holds a value (e.g. parallel branches or `forEach`
/// iterations writing the same `outputKey`).
///
/// Without a reducer the engine's merge is last-write-wins, which silently
/// drops one of two concurrent writes. Declaring a reducer on the producing
/// node's [PipelineNodeConfig.reducer] makes the merge deterministic.
class StateReducer {
  /// Creates a [StateReducer].
  const StateReducer();

  /// All supported reducer names (for editor pickers / validation).
  static const List<String> names = [
    'override',
    'append',
    'mergeLists',
    'mergeMaps',
    'sum',
  ];

  /// Whether [name] is a recognized reducer (null/empty counts as override).
  bool isKnown(String? name) =>
      name == null || name.isEmpty || names.contains(name);

  /// Applies the [name] reducer combining [existing] with [incoming].
  ///
  /// When there is no [existing] value the [incoming] value is used as-is
  /// regardless of reducer (first write). `append` wraps non-list existing
  /// values into a list before appending.
  Object? apply(String? name, Object? existing, Object? incoming) {
    if (existing == null) {
      // First write: `append` still normalizes scalars into a single-item
      // list so downstream readers always see a list.
      if (name == 'append') {
        return incoming is List ? incoming : [incoming];
      }
      return incoming;
    }
    switch (name) {
      case 'append':
        final base = existing is List ? List<Object?>.from(existing) : [existing];
        if (incoming is List) {
          base.addAll(incoming);
        } else {
          base.add(incoming);
        }
        return base;
      case 'mergeLists':
        return [
          ...(existing is List ? existing : [existing]),
          ...(incoming is List ? incoming : [incoming]),
        ];
      case 'mergeMaps':
        return <String, dynamic>{
          if (existing is Map) ...existing.cast<String, dynamic>(),
          if (incoming is Map) ...incoming.cast<String, dynamic>(),
        };
      case 'sum':
        if (existing is num && incoming is num) return existing + incoming;
        return incoming;
      case 'override':
      case null:
      case '':
      default:
        return incoming;
    }
  }
}
