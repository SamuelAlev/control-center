import 'package:control_center/core/analytics/command_analytics_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('static command IDs report as themselves', () {
    expect(commandAnalyticsId('inbox'), 'inbox');
    expect(commandAnalyticsId('new-ticket'), 'new-ticket');
    expect(commandAnalyticsId('toggleFocusMode'), 'toggleFocusMode');
  });

  test('entity-bearing IDs report only their kind', () {
    expect(commandAnalyticsId('space:ws-1:sp-2'), 'space');
    expect(commandAnalyticsId('conversation:w:s:c'), 'conversation');
    expect(commandAnalyticsId('member-octocat'), 'member');
    expect(commandAnalyticsId('pr-42'), 'pr');
    expect(commandAnalyticsId('ticket-0b6f8f6e'), 'ticket');
    expect(commandAnalyticsId('42'), 'other');
    expect(commandAnalyticsId('weird id with spaces'), 'other');
  });
}
