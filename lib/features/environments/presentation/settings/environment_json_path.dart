Object? _copy(Object? value) => switch (value) {
  final Map<dynamic, dynamic> map => <String, dynamic>{
    for (final entry in map.entries) '${entry.key}': _copy(entry.value),
  },
  final List<dynamic> list => [for (final item in list) _copy(item)],
  _ => value,
};

/// A deep copy of [draft] with [value] at [path], creating parents. A null or
/// blank [value] removes the key, so a cleared field goes back to its default.
Map<String, dynamic> environmentJsonSet(
  Map<String, dynamic> draft,
  List<Object> path,
  Object? value,
) {
  final root = _copy(draft)! as Map<String, dynamic>;
  Object? node = root;
  for (var index = 0; index < path.length - 1; index++) {
    final segment = path[index];
    final next = path[index + 1];
    if (node is Map<String, dynamic>) {
      node = node.putIfAbsent(
        segment as String,
        () => next is int ? <Object?>[] : <String, dynamic>{},
      );
    } else if (node is List) {
      node = node[segment as int];
    }
  }
  final last = path.last;
  final blank = value == null || value == '';
  if (node is Map<String, dynamic>) {
    if (blank) {
      node.remove(last as String);
    } else {
      node[last as String] = value;
    }
  } else if (node is List) {
    node[last as int] = value;
  }
  return root;
}

/// The value at [path], or null.
Object? environmentJsonGet(Map<String, dynamic> draft, List<Object> path) {
  Object? node = draft;
  for (final segment in path) {
    if (node is Map && segment is String) {
      node = node[segment];
    } else if (node is List && segment is int && segment < node.length) {
      node = node[segment];
    } else {
      return null;
    }
  }
  return node;
}

/// [path] as the validator writes it: `components[0].cwd.role`.
String environmentIssuePath(List<Object> path) {
  final out = StringBuffer();
  for (final segment in path) {
    if (segment is int) {
      out.write('[$segment]');
    } else {
      if (out.isNotEmpty) {
        out.write('.');
      }
      out.write(segment);
    }
  }
  return out.toString();
}
