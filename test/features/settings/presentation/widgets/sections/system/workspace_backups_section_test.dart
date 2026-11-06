import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/media_proxy_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/workspace_backups_section.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../helpers/fake_rpc_client.dart';

/// Settings → Server → Backup & restore, the scheduled half.
///
/// The card exists so "is this workspace being backed up?" has an answer on
/// screen, so what is pinned is that answer in each state, and that restoring
/// is the existing `workspace.import` rather than a second mechanism.
void main() {
  final now = DateTime.now().toUtc();
  const dbPath = '/data/backups/workspace-backups/ws-1/new/workspace.db';

  Workspace workspace(String id, String name) =>
      Workspace(id: id, name: name, createdAt: now, updatedAt: now);

  Map<String, dynamic> backup({
    required String name,
    required Duration age,
    bool complete = true,
    String path = dbPath,
  }) => {
    'path': '/data/backups/workspace-backups/ws-1/$name',
    'name': name,
    'created_at': now.subtract(age).toIso8601String(),
    'bytes': 5 * 1024 * 1024,
    'complete': complete,
    'workspaces': [
      if (complete) {'workspace_id': 'ws-1', 'path': path, 'bytes': 1024},
    ],
    'skipped_workspace_ids': const <String>[],
  };

  Widget wrap(
    FakeRpcHost host,
    List<Workspace> workspaces, {
    TextDirection textDirection = TextDirection.ltr,
    MediaProxyConfig? proxy,
    List<Override> overrides = const [],
  }) => ProviderScope(
    overrides: [
      rpcClientProvider.overrideWithValue(host.client()),
      workspacesProvider.overrideWith((ref) => Stream.value(workspaces)),
      mediaProxyConfigProvider.overrideWithValue(proxy),
      ...overrides,
    ],
    child: CcTheme(
      data: CcThemeData.light(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Directionality(
          textDirection: textDirection,
          child: const Scaffold(
            body: SingleChildScrollView(child: WorkspaceBackupsSection()),
          ),
        ),
      ),
    ),
  );

  testWidgets('a collapsed row says when the workspace was last backed up', (
    tester,
  ) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {
      'backups': [
        backup(name: 'new', age: const Duration(days: 5)),
        backup(name: 'old', age: const Duration(days: 12)),
      ],
    };

    await tester.pumpWidget(wrap(host, [workspace('ws-1', 'Acme')]));
    await tester.pumpAndSettle();

    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
    expect(find.textContaining('Last backup'), findsOneWidget);
    expect(find.text('2 backups'), findsOneWidget);
    expect(find.text('10 MB'), findsOneWidget);
  });

  testWidgets('a workspace with no backups says so and does not expand', (
    tester,
  ) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {'backups': const <Map<String, dynamic>>[]};

    await tester.pumpWidget(wrap(host, [workspace('ws-1', 'Acme')]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acme'));
    await tester.pumpAndSettle();

    expect(find.text('No backups yet'), findsOneWidget);
    expect(find.text('Restore'), findsNothing);
  });

  testWidgets('a refused workspace says why and leaves the others readable', (
    tester,
  ) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {
      'backups': [backup(name: 'new', age: const Duration(days: 5))],
    };

    await tester.pumpWidget(
      wrap(
        host,
        [workspace('ws-1', 'Mine'), workspace('ws-2', 'Theirs')],
        overrides: [
          workspaceBackupsProvider('ws-2').overrideWith(
            (ref) => throw RemoteRpcException(
              RpcErrorCodes.unauthorized,
              'Operation requires the admin role: workspace.listBackups',
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 backup'), findsOneWidget);
    expect(
      find.text(
        'You need the admin role on this workspace to see its backups.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('RemoteRpcException'), findsNothing);
    final refusal = tester.widget<Text>(
      find.textContaining('You need the admin role'),
    );
    expect(
      refusal.style?.color,
      isNot(DesignSystemTokens.light().textErrorPrimary),
      reason: 'lacking a role is not a failure',
    );
  });

  testWidgets('deleting a backup goes through a typed confirmation', (
    tester,
  ) async {
    final deletes = <Map<String, dynamic>>[];
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      if (op == 'workspace.deleteBackup') {
        deletes.add(args);
        return {'ok': true};
      }
      return {
        'backups': [backup(name: 'new', age: const Duration(days: 5))],
      };
    };

    await tester.pumpWidget(wrap(host, [workspace('ws-1', 'Acme')]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acme'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(AppIcons.trash2));
    await tester.pumpAndSettle();

    expect(deletes, isEmpty, reason: 'nothing happens before the confirmation');

    await tester.enterText(find.byType(EditableText).last, 'Acme');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CcButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(deletes.single['workspace_id'], 'ws-1');
    expect(deletes.single['name'], 'new');
  });

  testWidgets('download needs a file lane and a real file', (tester) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {
      'backups': [
        backup(name: 'new', age: const Duration(days: 1)),
        backup(name: 'bad', age: const Duration(days: 2), complete: false),
      ],
    };
    final proxy = MediaProxyConfig(
      httpBase: Uri.parse('http://127.0.0.1:9030'),
      deviceId: 'device-1',
      psk: 'psk-1',
    );
    List<VoidCallback?> downloads() => [
      for (final button in tester.widgetList<CcIconButton>(
        find.byType(CcIconButton),
      ))
        if (button.icon == AppIcons.download) button.onPressed,
    ];

    await tester.pumpWidget(
      wrap(host, [workspace('ws-1', 'Acme')], proxy: proxy),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acme'));
    await tester.pumpAndSettle();

    expect(downloads().first, isNotNull);
    expect(downloads().last, isNull, reason: 'nothing there to download');
  });

  testWidgets('with no file lane no backup can be downloaded', (tester) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {
      'backups': [backup(name: 'new', age: const Duration(days: 1))],
    };

    await tester.pumpWidget(wrap(host, [workspace('ws-1', 'Acme')]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acme'));
    await tester.pumpAndSettle();

    final download = tester
        .widgetList<CcIconButton>(find.byType(CcIconButton))
        .firstWhere((b) => b.icon == AppIcons.download);
    expect(download.onPressed, isNull);
  });

  testWidgets('a deleted workspace is listed for download and delete only', (
    tester,
  ) async {
    final deletes = <Map<String, dynamic>>[];
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      if (op == 'server.deleteOrphanedBackup') {
        deletes.add(args);
        return {'ok': true};
      }
      if (op == 'server.listOrphanedBackups') {
        return {
          'workspaces': [
            {
              'workspace_id': 'ws-gone',
              'workspace_name': 'Old project',
              'backups': [backup(name: 'old', age: const Duration(days: 40))],
            },
          ],
        };
      }
      return {'backups': const <Map<String, dynamic>>[]};
    };

    await tester.pumpWidget(wrap(host, const []));
    await tester.pumpAndSettle();

    expect(find.text('Old project'), findsOneWidget);
    expect(find.text('Workspace deleted'), findsOneWidget);

    await tester.tap(find.text('Old project'));
    await tester.pumpAndSettle();

    expect(find.text('Restore'), findsNothing);

    await tester.tap(find.byIcon(AppIcons.trash2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'Old project');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CcButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(deletes.single['workspace_id'], 'ws-gone');
    expect(deletes.single['name'], 'old');
  });

  testWidgets('someone who is not the install owner sees no deleted rows', (
    tester,
  ) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {'backups': const <Map<String, dynamic>>[]};

    await tester.pumpWidget(
      wrap(
        host,
        [workspace('ws-1', 'Acme')],
        overrides: [
          orphanedWorkspaceBackupsProvider.overrideWith(
            (ref) => throw RemoteRpcException(
              RpcErrorCodes.unauthorized,
              'Install owner required',
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme'), findsOneWidget);
    expect(find.textContaining('Install owner'), findsNothing);
    expect(find.textContaining('Failed'), findsNothing);
  });

  testWidgets('restoring goes through workspace.import after typed confirm', (
    tester,
  ) async {
    final imports = <Map<String, dynamic>>[];
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      if (op == 'workspace.import') {
        imports.add(args);
        return {'ok': true, 'workspace_id': 'ws-1'};
      }
      return {
        'backups': [backup(name: 'new', age: const Duration(days: 5))],
      };
    };

    await tester.pumpWidget(wrap(host, [workspace('ws-1', 'Acme')]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(imports, isEmpty, reason: 'nothing happens before the confirmation');

    await tester.enterText(find.byType(EditableText).last, 'Acme');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore').last);
    await tester.pumpAndSettle();

    expect(imports.single['workspace_id'], 'ws-1');
    expect(imports.single['source_path'], dbPath);
  });

  testWidgets('an incomplete backup is listed but cannot be restored', (
    tester,
  ) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {
      'backups': [
        backup(name: 'bad', age: const Duration(days: 1), complete: false),
      ],
    };

    await tester.pumpWidget(wrap(host, [workspace('ws-1', 'Acme')]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acme'));
    await tester.pumpAndSettle();

    expect(find.text('Incomplete'), findsNWidgets(2));
    final restore = tester.widget<CcButton>(
      find.ancestor(of: find.text('Restore'), matching: find.byType(CcButton)),
    );
    expect(restore.onPressed, isNull);
  });

  testWidgets('mirrors under a right-to-left locale', (tester) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => {
      'backups': [backup(name: 'new', age: const Duration(days: 5))],
    };

    await tester.pumpWidget(
      wrap(host, [workspace('ws-1', 'Acme')], textDirection: TextDirection.rtl),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acme'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getCenter(find.text('Acme')).dx,
      greaterThan(tester.getCenter(find.byType(CcIconButton).first).dx),
    );
  });
}
