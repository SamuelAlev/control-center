import 'dart:io';

import 'package:test/test.dart';

/// Secrets-file keys are matched exactly or by a full prefix ending in a
/// delimiter ids cannot contain. A suffix match (`endsWith('_$id')`) let a
/// workspace whose id equals a user's id reach that user's global sign-in, so
/// no predicate that lists or deletes secrets may use one.
void main() {
  test('no secrets-file predicate matches a key by its suffix', () {
    final offenders = <String>[];
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in sources) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final predicate =
            line.contains('deleteMatching(') ||
            line.contains('keysMatching(') ||
            line.contains('static bool isWorkspace');
        if (!predicate) {
          continue;
        }
        // The predicate's body: up to the statement's end.
        for (var j = i; j < lines.length && j < i + 12; j++) {
          if (lines[j].contains('.endsWith(')) {
            offenders.add('${file.path}:${j + 1}');
          }
          if (lines[j].trimRight().endsWith(';')) {
            break;
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: 'match secrets-file keys by prefix');
  });
}
