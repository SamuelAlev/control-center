import 'dart:io';

import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  const scanner = HarnessCommandScanner();

  setUp(() => root = Directory.systemTemp.createTempSync('cc_commands'));
  tearDown(() => root.deleteSync(recursive: true));

  void writeCommand(String relative, String content) {
    final file = File(p.join(root.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  group('expandCommandArgs', () {
    test(r'$ARGUMENTS takes everything', () {
      expect(
        expandCommandArgs(r'Review $ARGUMENTS carefully', 'lib/a.dart'),
        'Review lib/a.dart carefully',
      );
    });

    test(r'positional $1 $2 split on words', () {
      expect(
        expandCommandArgs(r'move $1 to $2', 'old.dart new.dart'),
        'move old.dart to new.dart',
      );
    });

    test('quotes hold a word together', () {
      expect(
        expandCommandArgs(r'title: $1', '"the big refactor" extra'),
        'title: the big refactor',
      );
    });

    test('backslashes are literal, so Windows paths survive', () {
      expect(
        expandCommandArgs(r'open $1', r'C:\Users\sam\a.dart'),
        r'open C:\Users\sam\a.dart',
      );
    });

    test(r'$@[n] and $@[n:m] slice', () {
      expect(expandCommandArgs(r'[$@[2]]', 'a b c d'), '[b c d]');
      expect(expandCommandArgs(r'[$@[2:2]]', 'a b c d'), '[b c]');
      expect(expandCommandArgs(r'[$@[9]]', 'a b'), '[]');
    });

    test('a missing positional is empty, not the literal token', () {
      expect(expandCommandArgs(r'x=$3', 'only one'), 'x=');
    });

    test('a body with NO placeholder still receives the arguments', () {
      // Otherwise the command silently discards the only thing the user typed.
      expect(
        expandCommandArgs('Summarize the diff.', 'focus on tests'),
        'Summarize the diff.\n\nfocus on tests',
      );
    });

    test('a body with no placeholder and no args is unchanged', () {
      expect(expandCommandArgs('Summarize the diff.', '  '),
          'Summarize the diff.');
    });
  });

  group('scan', () {
    test('discovers a command and its frontmatter', () async {
      writeCommand('.agents/commands/review.md', '''
---
description: Review the working tree
model: claude-sonnet-5
allowed-tools: read, search
---
Review the current diff and report P0 issues first.
''');
      final commands = await scanner.scan([root.path]);
      expect(commands, hasLength(1));
      final command = commands.single;
      expect(command.name, 'review');
      expect(command.description, 'Review the working tree');
      expect(command.model, 'claude-sonnet-5');
      expect(command.allowedTools, ['read', 'search']);
      expect(command.body, contains('P0 issues'));
      expect(
        command.body,
        isNot(contains('description:')),
        reason: 'frontmatter must not reach the model',
      );
    });

    test('falls back to the first prose line for a description', () async {
      writeCommand('.agents/commands/tidy.md', '# Tidy\n\nClean up imports.\n');
      final command = (await scanner.scan([root.path])).single;
      expect(command.description, 'Clean up imports.');
    });

    test('a nested file is reachable as dir:name', () async {
      writeCommand('.agents/commands/review/security.md', 'Look for auth bugs.');
      final command = (await scanner.scan([root.path])).single;
      expect(command.name, 'review:security');
    });

    test('reads the cross-tool directories too', () async {
      writeCommand('.claude/commands/ship.md', 'Ship it.');
      writeCommand('.codex/commands/land.md', 'Land it.');
      final names = (await scanner.scan([root.path])).map((c) => c.name);
      expect(names, containsAll(['ship', 'land']));
    });

    test('the first base wins on a name collision', () async {
      final other = Directory.systemTemp.createTempSync('cc_commands_b');
      addTearDown(() => other.deleteSync(recursive: true));
      writeCommand('.agents/commands/review.md', 'PROJECT version');
      File(p.join(other.path, '.agents', 'commands', 'review.md'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('HOME version');

      final commands = await scanner.scan([root.path, other.path]);
      expect(commands.single.body, 'PROJECT version');
    });

    test('ignores non-markdown and empty files', () async {
      writeCommand('.agents/commands/notes.txt', 'not a command');
      writeCommand('.agents/commands/blank.md', '---\ndescription: x\n---\n');
      expect(await scanner.scan([root.path]), isEmpty);
    });

    test('refuses a body over the cap', () async {
      writeCommand('.agents/commands/huge.md', 'x' * 200000);
      const small = HarnessCommandScanner(maxBodyBytes: 1024);
      expect(await small.scan([root.path]), isEmpty);
    });

    test('caps how many commands it returns', () async {
      for (var i = 0; i < 20; i++) {
        writeCommand('.agents/commands/c$i.md', 'body $i');
      }
      const capped = HarnessCommandScanner(maxCommands: 5);
      expect((await capped.scan([root.path])).length, lessThanOrEqualTo(5));
    });

    test('a missing base is not an error', () async {
      expect(await scanner.scan([null, '', '/no/such/dir']), isEmpty);
    });

    test('render substitutes on the discovered body', () async {
      writeCommand('.agents/commands/fix.md', r'Fix $1 in $2.');
      final command = (await scanner.scan([root.path])).single;
      expect(command.render('overflow main.dart'), 'Fix overflow in main.dart.');
    });
  });
}
