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
}
