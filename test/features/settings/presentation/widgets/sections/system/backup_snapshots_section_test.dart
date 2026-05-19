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

  testWidgets('says so when the install has never been backed up', (
    tester,
  ) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {'backups': <Map<String, dynamic>>[]};

    await tester.pumpWidget(wrap(host));
    await tester.pumpAndSettle();

    expect(find.textContaining('No snapshots yet'), findsOneWidget);
  });

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
