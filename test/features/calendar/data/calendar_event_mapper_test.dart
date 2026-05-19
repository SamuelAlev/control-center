import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/calendar/data/mappers/calendar_event_mapper.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = CalendarEventMapper();

  group('CalendarEventMapper.accountToDomain', () {
    CalendarAccountsTableData row({DateTime? authExpiredAt}) =>
        CalendarAccountsTableData(
          id: 'acc-1',
          workspaceId: 'ws-A',
          providerId: 'google',
          accountEmail: 'a@x.com',
          authExpiredAt: authExpiredAt,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );

    test('maps a healthy account (no reauth flag)', () {
      final account = mapper.accountToDomain(row());
      expect(account.authExpiredAt, isNull);
      expect(account.needsReauth, isFalse);
    });

    test('carries authExpiredAt through so needsReauth is true', () {
      final at = DateTime.utc(2026, 6, 11, 9);
      final account = mapper.accountToDomain(row(authExpiredAt: at));
      expect(account.authExpiredAt, at);
      expect(account.needsReauth, isTrue);
    });
  });

  group('CalendarEventMapper attendees JSON', () {
    test('encode then decode round-trips attendees', () {
      const attendees = [
        CalendarAttendee(
          email: 'a@x.com',
          displayName: 'Ada',
          responseStatus: 'accepted',
          self: true,
        ),
        CalendarAttendee(email: 'b@x.com', organizer: true),
      ];
      final json = mapper.encodeAttendees(attendees);
      final decoded = mapper.decodeAttendees(json);
      expect(decoded, attendees);
    });

    test('decodes empty / malformed JSON to an empty list', () {
      expect(mapper.decodeAttendees(''), isEmpty);
      expect(mapper.decodeAttendees('not json'), isEmpty);
      expect(mapper.decodeAttendees('{}'), isEmpty);
    });
  });
}
