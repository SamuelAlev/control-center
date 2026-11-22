import 'dart:convert';

import 'package:test/test.dart';

/// [value] as the script receives it: a JSON text a tool answered with
/// (`ScriptJsonText`) arrives decoded.
Object? asScriptSees(Object? value) => jsonDecode(jsonEncode(value));

/// Checks a JSON object a script receives against the tool's result note:
/// [value] has every key in [required], no key outside [required] and
/// [optional], and [note] names every one of them.
void expectNotedObject(
  String? note,
  Object? value, {
  required Set<String> required,
  Set<String> optional = const {},
}) {
  expect(note, isNotNull);
  expect(value, isA<Map<String, Object?>>());
  final keys = (value! as Map<String, Object?>).keys.toSet();
  expect(keys, containsAll(required));
  expect(keys.difference({...required, ...optional}), isEmpty);
  for (final key in {...required, ...optional}) {
    expect(note, matches(RegExp('\\b$key\\b')), reason: 'note names $key');
  }
}
