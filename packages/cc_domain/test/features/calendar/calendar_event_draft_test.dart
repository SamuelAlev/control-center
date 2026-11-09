import 'package:cc_domain/features/calendar/domain/entities/calendar_event_draft.dart';
import 'package:test/test.dart';

CalendarEventDraft _draft({
  String title = 'Review',
  DateTime? start,
  DateTime? end,
  bool allDay = false,
  List<String> guests = const [],
}) => CalendarEventDraft(
  accountId: 'acct',
  calendarId: 'primary',
  title: title,
  start: start ?? DateTime.utc(2026, 11, 10, 14),
  end: end ?? DateTime.utc(2026, 11, 10, 15),
  isAllDay: allDay,
  attendeeEmails: guests,
);

void main() {
  test('trims, lowercases and de-duplicates', () {
    final draft = _draft(
      title: '  Review ',
      guests: [' A@Example.com', 'a@example.com', ''],
    );
    expect(draft.title, 'Review');
    expect(draft.attendeeEmails, ['a@example.com']);
  });

  test('refuses what Google would reject or nobody meant', () {
    expect(() => _draft(title: '  '), throwsArgumentError);
    expect(
      () => _draft(end: DateTime.utc(2026, 11, 10, 14)),
      throwsArgumentError,
    );
    expect(() => _draft(end: DateTime.utc(2028)), throwsArgumentError);
    expect(() => _draft(guests: ['not an email']), throwsArgumentError);
  });

  test('a timed draft survives its arguments', () {
    final draft = CalendarEventDraft(
      accountId: 'acct',
      calendarId: 'primary',
      title: 'Review',
      start: DateTime.utc(2026, 11, 10, 14),
      end: DateTime.utc(2026, 11, 10, 15),
      location: ' Room 4 ',
      attendeeEmails: const ['b@example.com'],
      addConference: true,
    );
    final args = draft.toArgs();
    expect(args['start'], '2026-11-10T14:00:00.000Z');
    expect(CalendarEventDraft.fromArgs(args), draft);
  });

  test('an all-day draft travels as days, not instants', () {
    final draft = _draft(
      start: DateTime(2026, 11, 12, 23, 30),
      end: DateTime(2026, 11, 14),
      allDay: true,
    );
    final args = draft.toArgs();
    expect(args['start'], '2026-11-12');
    expect(args['end'], '2026-11-14');
    final back = CalendarEventDraft.fromArgs(args);
    expect(back, draft);
    expect(back.start, DateTime(2026, 11, 12));
  });

  test('a malformed date is an argument error', () {
    expect(
      () => CalendarEventDraft.fromArgs({
        'account_id': 'acct',
        'calendar_id': 'primary',
        'title': 'Review',
        'start': 'tomorrow',
        'end': '2026-11-10',
      }),
      throwsArgumentError,
    );
  });
}
