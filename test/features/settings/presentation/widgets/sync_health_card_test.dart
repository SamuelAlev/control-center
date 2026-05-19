import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sync_health_card.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedWs extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws1';
}

TicketSyncConfig _config(String vendor, {bool enabled = true}) =>
    TicketSyncConfig(
      id: 'cfg-$vendor',
      workspaceId: 'ws1',
      vendor: vendor,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      enabled: enabled,
    );

TicketSyncLogEntry _log(
  String vendor,
  SyncOutcome outcome,
  DateTime at, {
  String? message,
}) => TicketSyncLogEntry(
  id: 'log-$vendor-${at.microsecondsSinceEpoch}',
  workspaceId: 'ws1',
  vendor: vendor,
  direction: SyncDirection.bidirectional,
  outcome: outcome,
  message: message,
  createdAt: at,
);

Widget _wrap({
  required List<TicketSyncConfig> configs,
  required List<TicketSyncLogEntry> logs,
}) => ProviderScope(
  overrides: [
    activeWorkspaceIdProvider.overrideWith(_FixedWs.new),
    workspaceSyncConfigsProvider.overrideWith(
      (ref, ws) => Stream.value(configs),
    ),
    workspaceSyncLogsProvider.overrideWith((ref, ws) => Stream.value(logs)),
    // Stub the manual-sync trigger so the button renders without an RPC host.
    ticketSyncNowProvider.overrideWith(
      (ref) =>
          ({String? vendor}) async =>
              (created: 0, updated: 0, skipped: 0, deduplicated: 0, failed: 0),
    ),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: CcTheme(
      data: CcThemeData.light(),
      child: const Scaffold(body: SyncHealthCard()),
    ),
  ),
);

void main() {
  testWidgets('empty state when no sync connections', (tester) async {
    await tester.pumpWidget(_wrap(configs: const [], logs: const []));
    await tester.pump();
    await tester.pump();
    expect(find.text('No sync connections yet'), findsOneWidget);
  });

  testWidgets('shows a vendor row with its latest outcome', (tester) async {
    await tester.pumpWidget(
      _wrap(
        configs: [_config('linear')],
        logs: [_log('linear', SyncOutcome.ok, DateTime.now())],
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Linear'), findsOneWidget);
    expect(find.textContaining('Synced'), findsWidgets);
    // §188: the manual "Sync now" trigger renders when configs exist.
    expect(find.text('Sync now'), findsOneWidget);
  });

  testWidgets('surfaces a consecutive-failure streak + latest error message', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      _wrap(
        configs: [_config('clickup')],
        logs: [
          // newest-first
          _log('clickup', SyncOutcome.failed, now, message: 'HTTP 401'),
          _log(
            'clickup',
            SyncOutcome.failed,
            now.subtract(const Duration(minutes: 5)),
          ),
          _log(
            'clickup',
            SyncOutcome.ok,
            now.subtract(const Duration(minutes: 10)),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('ClickUp'), findsOneWidget);
    // 2 consecutive failures from newest.
    expect(find.textContaining('2 consecutive failures'), findsOneWidget);
    // The latest failure's message is surfaced.
    expect(find.text('HTTP 401'), findsOneWidget);
  });
}
