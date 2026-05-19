import 'package:cc_harness/slash_command.dart';
import 'package:test/test.dart';

void main() {
  group('parseSlashCommand', () {
    test('parses a built-in command with args', () {
      final r = parseSlashCommand('/plan build the auth flow');
      expect(r.isCommand, isTrue);
      expect(r.command, 'plan');
      expect(r.args, 'build the auth flow');
    });

    test('parses a bare command with no args', () {
      final r = parseSlashCommand('/loop');
      expect(r.command, 'loop');
      expect(r.args, isEmpty);
    });

    test('parses a skill name with a colon/dash', () {
      final r = parseSlashCommand('/security-review the diff');
      expect(r.command, 'security-review');
      expect(r.args, 'the diff');
    });

    test('leading whitespace is tolerated', () {
      final r = parseSlashCommand('   /goal ship it');
      expect(r.command, 'goal');
      expect(r.args, 'ship it');
    });

    test('non-command text is not a command', () {
      expect(parseSlashCommand('hello world').isCommand, isFalse);
      expect(parseSlashCommand('use / as a separator').isCommand, isFalse);
      expect(parseSlashCommand('/').isCommand, isFalse);
    });

    test('built-in set contains plan/goal/loop/compact', () {
      expect(
        harnessBuiltinCommands,
        containsAll(['plan', 'goal', 'loop', 'compact']),
      );
    });
  });

  group('skillNameFor', () {
    test('strips the namespace', () {
      expect(skillNameFor('skill:testing'), 'testing');
    });

    test('keeps the repo qualifier for downstream resolution', () {
      expect(skillNameFor('skill:web-app:testing'), 'web-app:testing');
    });

    test('a namespaced skill may share a builtin name', () {
      // The whole point: `/plan` runs the builtin, `/skill:plan` runs the
      // skill. Before the namespace the skill was unreachable.
      expect(skillNameFor('plan'), isNull);
      expect(skillNameFor('skill:plan'), 'plan');
    });

    test('a bare non-builtin still resolves, for messages predating the namespace', () {
      expect(skillNameFor('testing'), 'testing');
    });

    test('every builtin is refused as a bare skill name', () {
      for (final builtin in harnessBuiltinCommands) {
        expect(skillNameFor(builtin), isNull, reason: builtin);
      }
    });

    test('a bare namespace is not a skill', () {
      expect(skillNameFor('skill:'), isNull);
    });

    test('a repo literally named "skill" still works', () {
      expect(skillNameFor('skill:skill:testing'), 'skill:testing');
    });

    test('the parser accepts the namespaced form', () {
      final r = parseSlashCommand('/skill:web-app:testing run it');
      expect(r.command, 'skill:web-app:testing');
      expect(r.args, 'run it');
      expect(skillNameFor(r.command!), 'web-app:testing');
    });
  });
}
