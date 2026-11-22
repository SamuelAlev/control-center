import 'package:control_center/features/messaging/providers/wake_command_arguments.dart';
import 'package:flutter_test/flutter_test.dart';

/// The query with the caret at the end of [text].
WakeArgumentQuery? _at(String text) => wakeArgumentQuery(text, text.length);

void main() {
  group('when a /schedule fires', () {
    test('is offered as soon as the command is followed by a space', () {
      expect(_at('/schedule'), isNull, reason: 'the caret is in the name');
      final q = _at('/schedule ')!;
      expect(q.step, WakeArgumentStep.when);
      expect(q.partial, isEmpty);
      expect((q.start, q.end), (10, 10));
      expect(q.tokens, ['in 30m', 'in 2h', 'at 09:00', 'cron "0 9 * * 1-5"']);
    });

    test('narrows to the form being written', () {
      expect(_at('/schedule i')!.tokens.first, 'in 15m');
      expect(_at('/schedule in ')!.tokens, hasLength(5));
      expect(_at('/schedule in 4')!.tokens, ['in 4m', 'in 4h', 'in 4d']);
      expect(_at('/schedule in 1h30')!.tokens, ['in 1h30m']);
      expect(_at('/schedule a')!.tokens, ['at 09:00', 'at 13:00', 'at 17:00']);
      expect(_at('/schedule at 9')!.tokens, ['at 09:00', 'at 09:30']);
      expect(_at('/schedule at 14:')!.tokens, ['at 14:00', 'at 14:30']);
      expect(_at('/schedule at 9:4')!.tokens, ['at 09:40']);
      expect(_at('/schedule c')!.tokens, hasLength(3));
      expect(_at('/schedule cron "0 *')!.tokens, ['cron "0 * * * *"']);
    });

    test('replaces everything written of the when', () {
      final q = _at('  /schedule   in 4')!;
      expect((q.start, q.end), (14, 18));
      expect(q.partial, 'in 4');
    });

    test('confirms a when that reads while the caret is still on it', () {
      expect(_at('/schedule in 2h')!.tokens, ['in 2h']);
      expect(_at('/schedule at 9:05')!.tokens, ['at 09:05']);
      expect(_at('/schedule in 2h '), isNull, reason: 'the prompt is next');
    });

    test('is not offered for words that fit no form, or past the when', () {
      expect(_at('/schedule tomorrow'), isNull);
      expect(_at('/schedule at 25'), isNull);
      expect(_at('/schedule at 2026-11-21T09:00Z'), isNull);
      expect(_at('/schedule in 2h check the dep'), isNull);
      expect(_at('/schedule in soon check'), isNull);
      expect(_at('/plan in 2h'), isNull);
      expect(_at('say /schedule in'), isNull);
    });

    test('follows the caret, not the end of the text', () {
      const text = '/schedule in 4 check the deploy';
      expect(wakeArgumentQuery(text, 14)!.tokens, ['in 4m', 'in 4h', 'in 4d']);
      expect(wakeArgumentQuery(text, 20), isNull);
      expect(wakeArgumentQuery(text, 4), isNull);
      expect(wakeArgumentQuery(text, 99), isNull);
    });
  });

  group('how often a /loop repeats', () {
    test('is offered, though a loop needs none', () {
      expect(_at('/loop ')!.tokens, ['every 10m', 'every 30m', 'every 1h']);
      expect(_at('/loop ev')!.tokens, hasLength(3));
      expect(_at('/loop every 2')!.tokens, [
        'every 2m',
        'every 2h',
        'every 2d',
      ]);
    });

    test('never offers a repeat a schedule may not have', () {
      expect(_at('/loop every 30s'), isNull);
      expect(_at('/loop every 90s')!.tokens, ['every 90s']);
    });

    test('gives way once the words are plainly the prompt', () {
      expect(_at('/loop keep the build green'), isNull);
      expect(_at('/loop every 5m keep'), isNull);
    });
  });

  group('limits', () {
    test('are offered on a dash between the when and the prompt', () {
      final q = _at('/schedule in 2h --')!;
      expect(q.step, WakeArgumentStep.option);
      expect(q.tokens, ['--max', '--days', '--budget']);
      expect((q.start, q.end), (16, 18));
      expect(_at('/schedule in 2h -')!.tokens, hasLength(3));
      expect(_at('/schedule in 2h --b')!.tokens, ['--budget']);
      expect(_at('/loop --')!.tokens, hasLength(3));
    });

    test('leave out the ones already written', () {
      expect(_at('/loop every 5m --max 3 --')!.tokens, ['--days', '--budget']);
    });

    test('are not offered before the when, in the prompt, or by no name', () {
      expect(_at('/schedule --'), isNull);
      expect(_at('/schedule in 2h run it --'), isNull);
      expect(_at('/schedule in 2h --fast'), isNull);
      expect(_at('/schedule in 2h --max'), isNotNull);
      expect(_at('/schedule in 2h --max '), isNull);
    });
  });
}
