import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:control_center/features/messaging/providers/composer_command_refusal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 11, 20, 12);

WakeCommandReading _read(String text) => readWakeCommand(text, now: _now)!;

void main() {
  test('only /loop and /schedule are read', () {
    expect(readWakeCommand('hello', now: _now), isNull);
    expect(readWakeCommand('/goal ship it', now: _now), isNull);
    expect(readWakeCommand('/scheduled', now: _now), isNull);
    expect(_read('/schedule').issue, WakeCommandIssue.when);
  });

  test('a finished command reads as its trigger, with no issue', () {
    final once = _read('/schedule in 2h check the deploy');
    expect(once.issue, isNull);
    expect((once.trigger! as OnceAt).at, DateTime.utc(2026, 11, 20, 14));
    expect(once.repeats, isFalse);

    final every = _read('/loop every 30m --max 4 check');
    expect((every.trigger! as Every).interval, const Duration(minutes: 30));
    expect(every.repeats, isTrue);

    expect(_read('/loop keep it green').trigger, isA<SelfPaced>());
    final cron = _read('/schedule cron "0 9 * * 1-5" triage');
    expect((cron.trigger! as Cron).expression, '0 9 * * 1-5');
    expect(cron.repeats, isTrue);

    // A wall clock is the workspace zone's: no instant on the client.
    final clock = _read('/schedule at 09:00 standup');
    expect(clock.issue, isNull);
    expect(clock.trigger, isNull);
    expect(clock.draft.clock, (hour: 9, minute: 0));
  });

  test('names the part that is missing or wrong, in writing order', () {
    WakeCommandIssue? issue(String text) => _read(text).issue;
    expect(issue('/schedule '), WakeCommandIssue.when);
    expect(issue('/schedule in soon x'), WakeCommandIssue.duration);
    expect(issue('/schedule at noonish x'), WakeCommandIssue.time);
    expect(issue('/schedule cron often x'), WakeCommandIssue.cron);
    expect(issue('/loop --max x y'), WakeCommandIssue.maxRuns);
    expect(issue('/loop --days x y'), WakeCommandIssue.days);
    expect(issue('/loop --budget x y'), WakeCommandIssue.budget);
    expect(issue('/loop --fast y'), WakeCommandIssue.option);
    expect(issue('/schedule in 2h '), WakeCommandIssue.prompt);
  });

  test('finds what the server would refuse after reading it', () {
    WakeCommandIssue? issue(String text) => _read(text).issue;
    expect(issue('/loop every 30s check'), WakeCommandIssue.tooOften);
    expect(issue('/schedule at 2026-11-19T09:00Z x'), WakeCommandIssue.time);
    expect(issue('/schedule at 2026-11-21T09:00Z x'), isNull);
    expect(issue('/loop --max 501 x'), WakeCommandIssue.maxRuns);
    expect(issue('/loop --max 500 x'), isNull);
    expect(issue('/loop --days 366 x'), WakeCommandIssue.days);
    expect(issue('/loop --budget 99999999 x'), WakeCommandIssue.budget);
    // Before the prompt it has not got to yet.
    expect(issue('/loop --max 501 '), WakeCommandIssue.maxRuns);
  });

  test('tells a part still being written from one left behind', () {
    expect(_read('/schedule in 4').settled, isFalse);
    expect(_read('/schedule in soon check').settled, isTrue);
    expect(_read('/loop every 30s').settled, isFalse);
    expect(_read('/loop every 30s check').settled, isTrue);
    expect(_read('/loop --max 501').settled, isFalse);
    expect(_read('/loop --max 501 check').settled, isTrue);
  });

  test('a /goal that does not read is blocked with the parser\'s words', () {
    expect(goalCommandProblem('/goal ship the release'), isNull);
    expect(goalCommandProblem('/goal '), isNull);
    expect(goalCommandProblem('hello'), isNull);
    expect(goalCommandProblem('/goal --checker'), isNotNull);
    expect(workCommandBlocked('/goal --checker', now: _now), isTrue);
    expect(workCommandBlocked('/schedule in 2h', now: _now), isTrue);
    expect(workCommandBlocked('/schedule in 2h go', now: _now), isFalse);
    expect(workCommandBlocked('a plain message', now: _now), isFalse);
  });

  test('the refusal is remembered until a draft goes through', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const key = (spaceId: 'sp-1', conversationId: 'conv-1');
    final notifier = container.read(
      composerCommandRefusalProvider(key).notifier,
    );
    expect(container.read(composerCommandRefusalProvider(key)), isFalse);
    expect(notifier.check('/schedule soon do it'), isFalse);
    expect(container.read(composerCommandRefusalProvider(key)), isTrue);
    expect(notifier.check('/schedule in 2h do it'), isTrue);
    expect(container.read(composerCommandRefusalProvider(key)), isFalse);
    notifier.check('/loop ');
    notifier.clear();
    expect(container.read(composerCommandRefusalProvider(key)), isFalse);
  });
}
