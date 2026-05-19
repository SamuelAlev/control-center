import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

void main() {
  group('network constants', () {
    test('githubApiBaseUrl is the GitHub REST host over HTTPS', () {
      expect(githubApiBaseUrl, 'https://api.github.com');
      expect(githubApiBaseUrl, startsWith('https://'));
    });

    test('googleCalendarApiBaseUrl is the Calendar v3 host over HTTPS', () {
      expect(googleCalendarApiBaseUrl, 'https://www.googleapis.com/calendar/v3');
      expect(googleCalendarApiBaseUrl, startsWith('https://'));
    });

    test('googleAccountIdExtraKey is the per-request account key', () {
      expect(googleAccountIdExtraKey, 'googleAccountId');
    });
  });
}
