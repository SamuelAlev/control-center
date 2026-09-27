import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/media_proxy_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_snapshots_section.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/fake_rpc_client.dart';

/// Settings → Server → Backup & restore, the snapshot half.
///
/// The point of the card is that a backup you cannot find is not a backup, so
/// what is pinned here is the reporting: which snapshots exist, whether each
/// one is whole, and which of its workspaces this server can still take back.
void main() {
  final now = DateTime.utc(2026, 8, 31, 9);

  Workspace workspace(String id, String name) =>
      Workspace(id: id, name: name, createdAt: now, updatedAt: now);

  Map<String, dynamic> snapshot({
    required String name,
    bool complete = true,
    List<Map<String, dynamic>> workspaces = const [],
    List<String> skipped = const [],
  }) => {
    'path': '/data/backups/$name',
    'name': name,
    'created_at': now.toIso8601String(),
    'bytes': 5 * 1024 * 1024,
    'complete': complete,
    'workspaces': workspaces,
    'skipped_workspace_ids': skipped,
  };

  Widget wrap(
    FakeRpcHost host, {
    List<Workspace> workspaces = const [],
    MediaProxyConfig? proxy,
  }) {
    return ProviderScope(
      overrides: [
        rpcClientProvider.overrideWithValue(host.client()),
        workspacesProvider.overrideWith((ref) => Stream.value(workspaces)),
        mediaProxyConfigProvider.overrideWithValue(proxy),
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(child: BackupSnapshotsSection()),
          ),
        ),
      ),
    );
  }

  testWidgets('a half-written snapshot is listed, not hidden', (tester) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {
      'backups': [
        snapshot(name: 'good'),
        snapshot(name: 'interrupted', complete: false, skipped: ['ws-2']),
      ],
    };

    await tester.pumpWidget(wrap(host));
    await tester.pumpAndSettle();

    expect(find.text('good'), findsOneWidget);
    expect(find.text('interrupted'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
    expect(find.text('Incomplete'), findsOneWidget);
    expect(find.text('1 workspace not captured'), findsOneWidget);
  });

  testWidgets('taking a snapshot goes through server.backupNow', (
    tester,
  ) async {
    final ops = <String>[];
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      ops.add(op);
      if (op == 'server.backupNow') {
        return {'ok': true, 'path': '/data/backups/fresh'};
      }
      return {'backups': <Map<String, dynamic>>[]};
    };

    await tester.pumpWidget(wrap(host));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back up now'));
    await tester.pumpAndSettle();

    expect(ops, contains('server.backupNow'));
  });

  testWidgets(
    'incomplete snapshot deletion requires typed danger confirmation',
    (tester) async {
      final calls = <Map<String, dynamic>>[];
      final host = FakeRpcHost();
      var deleted = false;
      var lists = 0;
      host.onCall = (op, args) {
        if (op == 'server.deleteBackup') {
          calls.add(args);
          deleted = true;
          return {'ok': true};
        }
        if (op == 'server.listBackups') {
          lists++;
          return {
            'backups': deleted
                ? <Map<String, dynamic>>[]
                : [snapshot(name: 'interrupted', complete: false)],
          };
        }
        throw StateError('unexpected operation $op');
      };

      await tester.pumpWidget(wrap(host));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(BackupSnapshotsSection)),
      );
      await tester.tap(find.text('interrupted'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CcAlert>(find.byType(CcAlert).last).variant,
        CcAlertVariant.danger,
      );
      await tester.tap(
        find.widgetWithText(CcButton, l10n.backupDeleteSnapshotAction).first,
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      await tester.enterText(find.byType(CcTextField).last, 'wrong name');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CcButton>(
              find
                  .widgetWithText(CcButton, l10n.backupDeleteSnapshotAction)
                  .last,
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(CcTextField).last, 'interrupted');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CcButton, l10n.backupDeleteSnapshotAction).last,
      );
      await tester.pumpAndSettle();

      expect(calls, [
        {'name': 'interrupted'},
      ]);
      expect(lists, greaterThan(1));
      expect(find.text('interrupted'), findsNothing);
    },
  );

  testWidgets('canceling snapshot deletion leaves it untouched', (
    tester,
  ) async {
    final ops = <String>[];
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      ops.add(op);
      return {
        'backups': [snapshot(name: 'retain')],
      };
    };
    await tester.pumpWidget(wrap(host));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(BackupSnapshotsSection)),
    );
    await tester.tap(find.text('retain'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CcButton, l10n.backupDeleteSnapshotAction).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CcButton, l10n.cancel).last);
    await tester.pumpAndSettle();

    expect(ops, isNot(contains('server.deleteBackup')));
    expect(find.text('retain'), findsOneWidget);
  });

  testWidgets('failed deletion clears busy state and refreshes the listing', (
    tester,
  ) async {
    final host = FakeRpcHost();
    var lists = 0;
    host.onCall = (op, args) {
      if (op == 'server.deleteBackup') {
        throw StateError('filesystem error');
      }
      lists++;
      return {
        'backups': [snapshot(name: 'retain')],
      };
    };

    await tester.pumpWidget(wrap(host));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(BackupSnapshotsSection)),
    );
    await tester.tap(find.text('retain'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CcButton, l10n.backupDeleteSnapshotAction).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CcTextField).last, 'retain');
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CcButton, l10n.backupDeleteSnapshotAction).last,
    );
    await tester.pumpAndSettle();

    expect(lists, greaterThan(1));
    expect(find.text('retain'), findsOneWidget);
    expect(
      tester
          .widget<CcButton>(
            find.widgetWithText(CcButton, l10n.backupDeleteSnapshotAction),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a workspace the server no longer has cannot be restored', (
    tester,
  ) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {
      'backups': [
        snapshot(
          name: 'snap',
          workspaces: [
            {
              'workspace_id': 'ws-1',
              'path': '/data/backups/snap/ws-1/workspace.db',
              'bytes': 2048,
            },
            {
              'workspace_id': 'ws-gone',
              'path': '/data/backups/snap/ws-gone/workspace.db',
              'bytes': 1024,
            },
          ],
        ),
      ],
    };

    await tester.pumpWidget(
      wrap(host, workspaces: [workspace('ws-1', 'Control Center')]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('snap'));
    await tester.pumpAndSettle();

    // The registered one is named and offered; the one the registry lost is
    // shown by id and refused here rather than failing server-side after a
    // type-to-confirm.
    expect(find.text('Control Center'), findsOneWidget);
    expect(find.text('ws-gone'), findsOneWidget);
    expect(find.text('Not on this server any more'), findsOneWidget);

    final buttons = tester
        .widgetList<CcButton>(find.widgetWithText(CcButton, 'Restore'))
        .toList();
    expect(buttons, hasLength(2));
    expect(buttons.where((b) => b.onPressed != null), hasLength(1));
  });

  testWidgets('a snapshot can be downloaded whole, as one archive', (
    tester,
  ) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {
      'backups': [snapshot(name: 'snap')],
    };

    await tester.pumpWidget(
      wrap(
        host,
        proxy: MediaProxyConfig(
          httpBase: Uri.parse('http://127.0.0.1:9030'),
          deviceId: 'device-1',
          psk: 'psk-1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('snap'));
    await tester.pumpAndSettle();

    // A snapshot is a directory; the host zips it so "download the backup"
    // means the backup rather than a scavenger hunt through its pieces.
    final download = find.widgetWithText(CcButton, 'Download');
    expect(download, findsOneWidget);
    expect(tester.widget<CcButton>(download).onPressed, isNotNull);
  });

  testWidgets('with no file lane the snapshot download is dead', (
    tester,
  ) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {
      'backups': [snapshot(name: 'snap')],
    };

    await tester.pumpWidget(wrap(host));
    await tester.pumpAndSettle();
    await tester.tap(find.text('snap'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<CcButton>(find.widgetWithText(CcButton, 'Download'))
          .onPressed,
      isNull,
    );
  });
}
