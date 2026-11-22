import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:test/test.dart';

/// Where in a script a call was made: a display hint from the runner, which
/// executes model-written code. Construction is strict; reading it back from
/// the wire or a row is lenient and drops anything that is not exactly a
/// position.
void main() {
  group('ScriptCallSite', () {
    test('round-trips through JSON as [line, column] with equality', () {
      final site = ScriptCallSite(12, 5);
      expect(site.toJson(), [12, 5]);
      final back = ScriptCallSite.tryParse(jsonDecode(jsonEncode(site)));
      expect(back, site);
      expect(back.hashCode, site.hashCode);
      expect(ScriptCallSite(12, 5), isNot(ScriptCallSite(5, 12)));
    });

    test('accepts both ends of the range', () {
      expect(ScriptCallSite(1, 1).toJson(), [1, 1]);
      const max = ScriptCallSite.maxPosition;
      expect(max, 1048576);
      expect(ScriptCallSite(max, max).toJson(), [max, max]);
      expect(ScriptCallSite.tryParse([max, max]), ScriptCallSite(max, max));
    });

    test('construction outside 1..2^20 throws', () {
      for (final (line, column) in [
        (0, 1),
        (1, 0),
        (-1, 3),
        (ScriptCallSite.maxPosition + 1, 1),
        (1, ScriptCallSite.maxPosition + 1),
      ]) {
        expect(
          () => ScriptCallSite(line, column),
          throwsArgumentError,
          reason: '($line, $column)',
        );
      }
    });

    test('tryParse returns null for anything that is not exactly a '
        'position', () {
      for (final json in <Object?>[
        null,
        '3:4',
        3,
        {'line': 3, 'column': 4},
        <Object?>[],
        [3],
        [3, 4, 5],
        [3, null],
        [null, 4],
        [3.5, 4],
        ['3', 4],
        [true, 1],
        [0, 4],
        [3, 0],
        [-3, 4],
        [ScriptCallSite.maxPosition + 1, 4],
        [3, ScriptCallSite.maxPosition + 1],
      ]) {
        expect(ScriptCallSite.tryParse(json), isNull, reason: '$json');
      }
    });
  });
}
