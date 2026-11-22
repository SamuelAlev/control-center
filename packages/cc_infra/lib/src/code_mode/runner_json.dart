import 'dart:convert';

/// The deepest JSON nesting the runner accepts in a host frame (serde_json's
/// limit). A deeper frame is a protocol violation on the runner's side, which
/// would end the script, so the host checks values before it sends them.
const int kRunnerMaxJsonDepth = 128;

/// The nesting depth of [value]: zero for a scalar, one for an empty or flat
/// map or list, and so on. Stops counting at [limit] + 1, so a hostile value
/// cannot make the walk itself expensive.
int jsonDepth(Object? value, {int limit = kRunnerMaxJsonDepth}) {
  var deepest = 0;
  final stack = <(Object?, int)>[(value, 0)];
  while (stack.isNotEmpty) {
    final (node, depth) = stack.removeLast();
    if (node is Map || node is List) {
      final d = depth + 1;
      if (d > deepest) {
        deepest = d;
        if (deepest > limit) {
          return deepest;
        }
      }
      final children = node is Map ? node.values : node as List;
      for (final child in children) {
        stack.add((child, d));
      }
    }
  }
  return deepest;
}

/// [value] as compact JSON, or null when it is not JSON-serialisable
/// (a non-finite number, an object without `toJson`, a cycle).
String? tryJsonEncode(Object? value) {
  try {
    return jsonEncode(value);
  } on Object {
    return null;
  }
}
