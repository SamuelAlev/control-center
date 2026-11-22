import 'package:cc_domain/features/dispatch/domain/services/wake_rule_command.dart';
import 'package:test/test.dart';

WakeRuleCommandRequest _read(String text) {
  final read = parseWakeRuleCommand(text);
  if (read is! WakeRuleCommandRequest) {
    fail('$text did not read: $read');
  }
  return read;
}

String _refused(String text) {
  final read = parseWakeRuleCommand(text);
  if (read is! WakeRuleCommandInvalid) {
    fail('$text was not refused: $read');
  }
  return read.message;
}

void main() {
  test('only /loop and /schedule with text after them are commands', () {
    expect(isWakeRuleCommand('/loop every 5m check'), isTrue);
    expect(isWakeRuleCommand('  /schedule in 2h go'), isTrue);
    expect(isWakeRuleCommand('/loop'), isFalse);
    expect(isWakeRuleCommand('/looping now'), isFalse);
    expect(isWakeRuleCommand('please /loop every 5m'), isFalse);
    expect(parseWakeRuleCommand('/goal ship it'), isNull);
  });

  group('/loop', () {
    test('with every, options and a prompt', () {
      final c = _read(
        '/loop every 30m --max 12 --days 3 --budget 2.50 check the deploy\n'
        'and report',
      );
      expect(c.command, 'loop');
      expect(c.when, 'every:30m');
      expect(c.maxRuns, 12);
      expect(c.days, 3);
      expect(c.budgetMicros, 2500000);
      expect(c.prompt, 'check the deploy\nand report');
    });

    test('without every is self-paced', () {
      final c = _read(r'/loop --budget $5 keep the build green');
      expect(c.when, 'next');
      expect(c.budgetMicros, 5000000);
      expect(c.prompt, 'keep the build green');
    });

    test('refuses a bad interval, a bad option, and no prompt', () {
      expect(_refused('/loop every soon check'), contains('every'));
      expect(_refused('/loop --max zero check'), contains('--max'));
      expect(_refused('/loop --budget 1.234 check'), contains('--budget'));
      expect(_refused('/loop --fast check'), contains('not an option'));
      expect(_refused('/loop every 5m --max 3 '), contains('what to do'));
    });
  });

  group('/schedule', () {
    test('in, at an ISO time, at a wall clock, and cron', () {
      expect(_read('/schedule in 2h review the PR').when, 'in:2h');
      final at = _read('/schedule at 2026-11-20T09:00Z standup notes');
      expect(at.when, 'at:2026-11-20T09:00Z');
      expect(at.prompt, 'standup notes');
      final clock = _read('/schedule at 9:05 standup notes');
      expect(clock.when, isNull);
      expect(clock.clock, (hour: 9, minute: 5));
      final cron = _read(
        '/schedule cron "0 9 * * 1-5" --days 30 triage new issues',
      );
      expect(cron.when, 'cron:0 9 * * 1-5');
      expect(cron.days, 30);
      expect(cron.prompt, 'triage new issues');
    });

    test('refuses a missing or unreadable when', () {
      expect(_refused('/schedule tomorrow do it'), contains('Say when'));
      expect(_refused('/schedule at noonish do it'), contains('"at"'));
      expect(_refused('/schedule cron every day do it'), contains('quotes'));
      expect(_refused('/schedule cron "61 9 * * *" do it'), contains('quotes'));
      expect(_refused('/schedule in 2h'), contains('what to do'));
    });

    test('reads a cron without its quotes', () {
      final cron = _read('/schedule cron 0 9 * * 1-5 --max 3 triage issues');
      expect(cron.when, 'cron:0 9 * * 1-5');
      expect(cron.maxRuns, 3);
      expect(cron.prompt, 'triage issues');
      // Five words that are not a cron are not taken for one.
      expect(_refused('/schedule cron a b c d e f'), contains('quotes'));
    });
  });

  test('a refusal names the part that is wrong', () {
    WakeRuleCommandProblem problem(String text) =>
        (parseWakeRuleCommand(text)! as WakeRuleCommandInvalid).problem;
    expect(problem('/schedule tomorrow x'), WakeRuleCommandProblem.when);
    expect(problem('/schedule in soon x'), WakeRuleCommandProblem.duration);
    expect(problem('/loop every soon x'), WakeRuleCommandProblem.duration);
    expect(problem('/schedule at noonish x'), WakeRuleCommandProblem.time);
    expect(problem('/schedule cron often x'), WakeRuleCommandProblem.cron);
    expect(problem('/loop --max zero x'), WakeRuleCommandProblem.maxRuns);
    expect(problem('/loop --days zero x'), WakeRuleCommandProblem.days);
    expect(problem('/loop --budget 1.234 x'), WakeRuleCommandProblem.budget);
    expect(problem('/loop --fast x'), WakeRuleCommandProblem.option);
    expect(problem('/schedule in 2h '), WakeRuleCommandProblem.prompt);
  });

  group('a draft', () {
    WakeRuleCommandDraft draft(String text) => readWakeRuleCommandDraft(text)!;

    test('is read from the bare command on, and from nothing else', () {
      expect(readWakeRuleCommandDraft('/scheduled in 2h x'), isNull);
      expect(readWakeRuleCommandDraft('hello /schedule'), isNull);
      final bare = draft('/schedule');
      expect(bare.problem, WakeRuleCommandProblem.when);
      expect(bare.problemSettled, isFalse);
      expect(bare.argumentsStart, 9);
      final loop = draft('/loop ');
      expect(loop.when, 'next');
      expect(loop.problem, WakeRuleCommandProblem.prompt);
      expect((loop.argumentsStart, loop.whenEnd, loop.optionsEnd), (6, 6, 6));
    });

    test('keeps what was read before the part that is missing', () {
      final d = draft('/schedule in 2h --max 4 ');
      expect(d.when, 'in:2h');
      expect(d.maxRuns, 4);
      expect(d.problem, WakeRuleCommandProblem.prompt);
      expect(d.prompt, isEmpty);
    });

    test('says where the when and the options end', () {
      const text = '  /schedule at 09:00 --days 3 --max 2 post the summary';
      final d = draft(text);
      expect(d.problem, isNull);
      expect(text.substring(d.argumentsStart, d.whenEnd), 'at 09:00');
      expect(text.substring(d.whenEnd, d.optionsEnd), ' --days 3 --max 2');
      expect(text.substring(d.optionsEnd).trim(), d.prompt);
      final quoted = draft('/schedule cron "0 9 * * 1-5" go');
      expect(
        '/schedule cron "0 9 * * 1-5" go'.substring(
          quoted.argumentsStart,
          quoted.whenEnd,
        ),
        'cron "0 9 * * 1-5"',
      );
    });

    test('tells a part still being written from one left behind', () {
      expect(draft('/schedule in 4').problemSettled, isFalse);
      expect(draft('/schedule in').problemSettled, isFalse);
      expect(draft('/schedule in soon check').problemSettled, isTrue);
      expect(draft('/schedule tom').problemSettled, isFalse);
      expect(draft('/schedule tomorrow check').problemSettled, isTrue);
      expect(draft('/schedule cron "0 9 *').problemSettled, isFalse);
      expect(draft('/schedule cron 0 9 *').problemSettled, isFalse);
      expect(draft('/schedule cron "x" check').problemSettled, isTrue);
      expect(draft('/loop --max').problemSettled, isFalse);
      expect(draft('/loop --max x check').problemSettled, isTrue);
      final option = draft('/loop --fast check');
      expect(option.option, '--fast');
      expect(option.problemSettled, isTrue);
      expect(draft('/loop --fa').problemSettled, isFalse);
    });
  });
}
