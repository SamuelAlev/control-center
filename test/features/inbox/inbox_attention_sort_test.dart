import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:control_center/features/inbox/presentation/models/inbox_attention_item.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD 19 §7: the attention strip orders most-urgent first, then
/// longest-waiting.
void main() {
  InboxAttentionItem item(
    String id,
    InboxAttentionSeverity severity, {
    DateTime? waitingSince,
    String title = '',
  }) => InboxAttentionItem(
    id: id,
    severity: severity,
    title: title.isEmpty ? id : title,
    icon: AppIcons.bot,
    actionLabel: 'Go',
    onAction: () {},
    waitingSince: waitingSince,
  );

  test('blocking sorts above warning sorts above info', () {
    final out = sortInboxAttentionItems([
      item('info', InboxAttentionSeverity.info),
      item('block', InboxAttentionSeverity.blocking),
      item('warn', InboxAttentionSeverity.warning),
    ]);
    expect(out.map((i) => i.id), ['block', 'warn', 'info']);
  });

  test('within a severity, the longest-waiting item is first', () {
    final out = sortInboxAttentionItems([
      item(
        'new',
        InboxAttentionSeverity.blocking,
        waitingSince: DateTime(2026, 7, 12, 10),
      ),
      item(
        'old',
        InboxAttentionSeverity.blocking,
        waitingSince: DateTime(2026, 7, 12, 8),
      ),
    ]);
    expect(out.map((i) => i.id), ['old', 'new']);
  });

  test('items with a waiting time sort ahead of those without', () {
    final out = sortInboxAttentionItems([
      item('none', InboxAttentionSeverity.warning),
      item(
        'timed',
        InboxAttentionSeverity.warning,
        waitingSince: DateTime(2026, 7, 12),
      ),
    ]);
    expect(out.first.id, 'timed');
  });

  test('stable title tiebreak when severity and timing match', () {
    final out = sortInboxAttentionItems([
      item('b', InboxAttentionSeverity.info, title: 'Beta'),
      item('a', InboxAttentionSeverity.info, title: 'Alpha'),
    ]);
    expect(out.map((i) => i.title), ['Alpha', 'Beta']);
  });

  group('latestSyncFailures', () {
    TicketSyncLogEntry log(
      String id,
      String vendor,
      SyncOutcome outcome,
      DateTime at,
    ) => TicketSyncLogEntry(
      id: id,
      workspaceId: 'ws',
      vendor: vendor,
      direction: SyncDirection.pull,
      outcome: outcome,
      createdAt: at,
    );

    test(
      'keeps only the most recent failure per vendor; ignores successes',
      () {
        final out = latestSyncFailures([
          log('1', 'linear', SyncOutcome.failed, DateTime(2026, 7, 1)),
          log('2', 'linear', SyncOutcome.failed, DateTime(2026, 7, 5)),
          log('3', 'linear', SyncOutcome.ok, DateTime(2026, 7, 6)),
          log('4', 'jira', SyncOutcome.failed, DateTime(2026, 7, 2)),
        ]);
        expect(out.length, 2); // one per vendor
        final linear = out.firstWhere((e) => e.vendor == 'linear');
        expect(linear.id, '2'); // the most recent linear failure
      },
    );

    test('no failures → empty', () {
      final out = latestSyncFailures([
        log('1', 'linear', SyncOutcome.ok, DateTime(2026, 7, 1)),
      ]);
      expect(out, isEmpty);
    });
  });
}
