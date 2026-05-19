import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('humanizeEmailName', () {
    test('title-cases a dotted local part', () {
      expect(humanizeEmailName('ada.lovelace@example.com'), 'Ada Lovelace');
    });

    test('handles a single-token local part', () {
      expect(humanizeEmailName('grace@x.com'), 'Grace');
    });

    test('splits on dots, underscores, and hyphens', () {
      expect(humanizeEmailName('jean-luc.picard@x.com'), 'Jean Luc Picard');
      expect(humanizeEmailName('john_doe@x.com'), 'John Doe');
    });

    test('normalises shouty casing', () {
      expect(humanizeEmailName('SAMUEL.ALEV@frontify.com'), 'Samuel Alev');
    });

    test('drops a +tag sub-address', () {
      expect(humanizeEmailName('ada.lovelace+meetings@x.com'), 'Ada Lovelace');
    });

    test('returns the raw value when nothing usable can be derived', () {
      expect(humanizeEmailName(''), '');
      expect(humanizeEmailName('@x.com'), '@x.com');
    });
  });

  group('CalendarAttendee.displayLabel', () {
    test('prefers the provider display name', () {
      const a = CalendarAttendee(
        email: 'ada.lovelace@x.com',
        displayName: 'Ada, Countess of Lovelace',
      );
      expect(a.displayLabel, 'Ada, Countess of Lovelace');
    });

    test('derives from the email when no display name', () {
      const a = CalendarAttendee(email: 'grace.hopper@x.com');
      expect(a.displayLabel, 'Grace Hopper');
    });

    test('derives when the display name is blank', () {
      const a = CalendarAttendee(email: 'alan.turing@x.com', displayName: '   ');
      expect(a.displayLabel, 'Alan Turing');
    });
  });
}
