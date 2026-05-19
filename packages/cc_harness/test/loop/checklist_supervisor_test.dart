import 'package:cc_harness/loop.dart';
import 'package:test/test.dart';

/// One tool call as the loop hands it to the supervisor.
({String name, Map<String, dynamic> args}) call(
  String name, [
  Map<String, dynamic> args = const {},
]) => (name: name, args: args);

/// A `todo_write` call carrying [items] as `(content, status)` pairs.
({String name, Map<String, dynamic> args}) write(
  List<(String, String)> items, {
  String name = 'todo_write',
}) => (
  name: name,
  args: {
    'todos': [
      for (final (content, status) in items)
        {'content': content, 'status': status},
    ],
  },
);

void main() {
  group('ChecklistSupervisor', () {
    test('stays silent until a checklist exists', () {
      final s = ChecklistSupervisor(staleAfterTurns: 2);
      // Ten turns of work with no list written: there is nothing to be stale
      // about, so the supervisor must not invent a checklist obligation.
      for (var i = 0; i < 10; i++) {
        expect(s.observeTurn([call('read')]), isNull);
      }
    });

    test('is silent on the turn that writes the list', () {
      final s = ChecklistSupervisor(staleAfterTurns: 1);
      expect(
        s.observeTurn([
          write([('ship it', 'in_progress')]),
        ]),
        isNull,
        reason: 'the write result already carries the shape feedback',
      );
    });

    test('nudges once open items go untouched for staleAfterTurns', () {
      final s = ChecklistSupervisor(staleAfterTurns: 3);
      s.observeTurn([
        write([('wire the dao', 'in_progress'), ('add the test', 'pending')]),
      ]);
      expect(s.observeTurn([call('read')]), isNull);
      expect(s.observeTurn([call('edit')]), isNull);
      final note = s.observeTurn([call('bash')]);
      expect(note, isNotNull);
      expect(note, contains('out of date'));
      // Names the item the list still claims is in flight, so the correction is
      // concrete rather than a generic "update your todos".
      expect(note, contains('wire the dao'));
      expect(note, contains('`todo_write`'));
    });

    test('names the next pending item when nothing is in_progress', () {
      final s = ChecklistSupervisor(staleAfterTurns: 1);
      s.observeTurn([
        write([('done bit', 'completed'), ('the next thing', 'pending')]),
      ]);
      final note = s.observeTurn([call('read')]);
      expect(note, contains('Nothing is in_progress'));
      expect(note, contains('the next thing'));
    });

    test('does not nudge when every item is completed', () {
      final s = ChecklistSupervisor(staleAfterTurns: 1);
      s.observeTurn([
        write([('a', 'completed'), ('b', 'completed')]),
      ]);
      for (var i = 0; i < 5; i++) {
        expect(s.observeTurn([call('read')]), isNull);
      }
    });

    test('nudges at most once per staleness episode', () {
      final s = ChecklistSupervisor(staleAfterTurns: 1);
      s.observeTurn([
        write([('a', 'pending')]),
      ]);
      expect(s.observeTurn([call('read')]), isNotNull);
      // Still stale, but already told — silence until the agent writes again.
      expect(s.observeTurn([call('read')]), isNull);
      expect(s.observeTurn([call('read')]), isNull);
    });

    test('re-arms after the agent writes again', () {
      final s = ChecklistSupervisor(staleAfterTurns: 1, maxNudges: 5);
      s.observeTurn([
        write([('a', 'pending')]),
      ]);
      expect(s.observeTurn([call('read')]), isNotNull);
      s.observeTurn([
        write([('a', 'in_progress')]),
      ]);
      expect(
        s.observeTurn([call('read')]),
        isNotNull,
        reason: 'a second drift episode is steered again',
      );
    });

    test('caps total nudges so it cannot nag for a whole run', () {
      final s = ChecklistSupervisor(staleAfterTurns: 1, maxNudges: 2);
      var delivered = 0;
      for (var episode = 0; episode < 6; episode++) {
        s.observeTurn([
          write([('a', 'pending')]),
        ]);
        if (s.observeTurn([call('read')]) != null) {
          delivered++;
        }
      }
      expect(delivered, 2);
    });

    test('matches the bridged mcp__server__ tool name', () {
      final s = ChecklistSupervisor(staleAfterTurns: 1);
      s.observeTurn([
        write([('a', 'pending')], name: 'mcp__control-center__todo_write'),
      ]);
      expect(
        s.observeTurn([call('read')]),
        isNotNull,
        reason: 'the prefixed call must register as a write',
      );
      // And a prefixed write must clear the episode, not be missed.
      expect(
        s.observeTurn([
          write([('a', 'completed')], name: 'mcp__control-center__todo_write'),
        ]),
        isNull,
      );
      expect(s.observeTurn([call('read')]), isNull);
    });

    test('the last write in a turn wins', () {
      final s = ChecklistSupervisor(staleAfterTurns: 1);
      s.observeTurn([
        write([('a', 'pending')]),
        write([('a', 'completed')]),
      ]);
      expect(
        s.observeTurn([call('read')]),
        isNull,
        reason: 'the final state of the turn has no open work',
      );
    });

    test('malformed args leave the prior state intact', () {
      final s = ChecklistSupervisor(staleAfterTurns: 1);
      s.observeTurn([
        write([('a', 'pending')]),
      ]);
      // A call the tool itself will reject must not be read as "list is now
      // empty", which would silently switch the supervisor off.
      s.observeTurn([
        call('todo_write', {'todos': 'not-a-list'}),
      ]);
      expect(s.observeTurn([call('read')]), isNotNull);
    });

    test('resetCadence forgives the counter but keeps the list state', () {
      final s = ChecklistSupervisor(staleAfterTurns: 2);
      s.observeTurn([
        write([('a', 'pending')]),
      ]);
      s.observeTurn([call('read')]);
      s.resetCadence();
      expect(
        s.observeTurn([call('read')]),
        isNull,
        reason: 'the counter restarted, so it is not stale yet',
      );
      expect(s.observeTurn([call('read')]), isNotNull);
    });

    test('staleAfterTurns below 1 is clamped to 1', () {
      final s = ChecklistSupervisor(staleAfterTurns: 0);
      s.observeTurn([
        write([('a', 'pending')]),
      ]);
      expect(s.observeTurn([call('read')]), isNotNull);
    });
  });

  group('decodeChecklistArgs', () {
    test('passes a decoded map through', () {
      expect(decodeChecklistArgs({'todos': []}), {'todos': <Object?>[]});
    });

    test('decodes a JSON string payload', () {
      final decoded = decodeChecklistArgs('{"todos":[{"content":"a"}]}');
      expect(decoded['todos'], isA<List<dynamic>>());
    });

    test('degrades malformed JSON to an empty map', () {
      expect(decodeChecklistArgs('{not json'), isEmpty);
      expect(decodeChecklistArgs(null), isEmpty);
      expect(decodeChecklistArgs(42), isEmpty);
    });
  });
}
