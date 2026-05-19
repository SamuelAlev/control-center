import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/media_proxy_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_transfer_feedback.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/workspace_data_section.dart';
import 'package:control_center/features/settings/providers/backup_transfer.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/fake_rpc_client.dart';

/// Settings → Server → Backup & restore, the per-workspace half.
///
/// Export, import and delete were RPC-only for as long as they have existed.
/// These pin the three things a UI over them has to get right: the operation
/// reaches the right op, an import cannot fire without a source, and neither
/// destructive action happens without the workspace's name typed back.
void main() {
  final now = DateTime.utc(2026, 8, 31, 9);

  Workspace workspace(String id, String name) =>
      Workspace(id: id, name: name, createdAt: now, updatedAt: now);

  Widget wrap(
    FakeRpcHost host,
    List<Workspace> workspaces, {
    MediaProxyConfig? proxy,
    BackupTransfer Function(Ref)? transfer,
  }) {
    return ProviderScope(
      overrides: [
        rpcClientProvider.overrideWithValue(host.client()),
        workspacesProvider.overrideWith((ref) => Stream.value(workspaces)),
        mediaProxyConfigProvider.overrideWithValue(proxy),
        if (transfer != null) backupTransferProvider.overrideWith(transfer),
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(child: WorkspaceDataSection()),
          ),
        ),
      ),
    );
  }

  /// Opens the row for [name] so its actions are built.
  Future<void> openRow(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  /// Taps a control that may have scrolled out of the 800x600 test viewport —
  /// an opened row is taller than the surface it is rendered on.
  Future<void> tapButton(WidgetTester tester, String label) async {
    final finder = find.widgetWithText(CcButton, label);
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  testWidgets('exporting one workspace names that workspace', (tester) async {
    Map<String, dynamic>? sent;
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      expect(op, 'workspace.export');
      sent = Map.of(args);
      return {'ok': true, 'path': '/data/backups/exports/ws-2.db'};
    };

    await tester.pumpWidget(
      wrap(host, [workspace('ws-1', 'Alpha'), workspace('ws-2', 'Beta')]),
    );
    await openRow(tester, 'Beta');
    await tapButton(tester, 'Save on server');

    // The page lists every workspace, so the id has to travel with the call —
    // the client's active workspace is rarely the one being exported.
    expect(sent?['workspace_id'], 'ws-2');
    expect(find.text('/data/backups/exports/ws-2.db'), findsOneWidget);
  });

  testWidgets('import stays disabled until a source file is named', (
    tester,
  ) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => throw StateError('no call expected: $op');

    await tester.pumpWidget(wrap(host, [workspace('ws-1', 'Alpha')]));
    await openRow(tester, 'Alpha');

    CcButton importButton() =>
        tester.widget<CcButton>(find.widgetWithText(CcButton, 'Import'));
    expect(importButton().onPressed, isNull);

    await tester.enterText(find.byType(CcTextField), '/tmp/workspace.db');
    await tester.pumpAndSettle();

    expect(importButton().onPressed, isNotNull);
  });

  testWidgets('importing replaces a workspace only after it is typed back', (
    tester,
  ) async {
    Map<String, dynamic>? sent;
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      expect(op, 'workspace.import');
      sent = Map.of(args);
      return {'ok': true, 'workspace_id': 'ws-1'};
    };

    await tester.pumpWidget(wrap(host, [workspace('ws-1', 'Alpha')]));
    await openRow(tester, 'Alpha');
    await tester.enterText(find.byType(CcTextField), '/tmp/workspace.db');
    await tester.pumpAndSettle();
    await tapButton(tester, 'Import');

    // The dialog is up and armed only once the name matches — an import
    // destroys everything the target holds.
    final confirm = find.widgetWithText(CcButton, 'Import').last;
    expect(tester.widget<CcButton>(confirm).onPressed, isNull);
    expect(sent, isNull);

    await tester.enterText(find.byType(CcTextField).last, 'Alpha');
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(sent?['workspace_id'], 'ws-1');
    expect(sent?['source_path'], '/tmp/workspace.db');
  });

  testWidgets('deleting says what stays on disk', (tester) async {
    final ops = <String>[];
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      ops.add(op);
      return {'ok': true};
    };

    await tester.pumpWidget(wrap(host, [workspace('ws-1', 'Alpha')]));
    await openRow(tester, 'Alpha');
    await tapButton(tester, 'Delete workspace');

    // A soft delete that reads as an erase is the one thing this surface must
    // not imply. The row says it before the press and the dialog says it again
    // at the press, so both copies are on screen here.
    expect(
      find.textContaining('database file stays on disk'),
      findsNWidgets(2),
    );

    await tester.enterText(find.byType(CcTextField).last, 'Alpha');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CcButton, 'Delete workspace').last);
    await tester.pumpAndSettle();

    expect(ops, contains('workspace.delete'));
  });

  testWidgets('a relayed connection cannot move files, and says so', (
    tester,
  ) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => throw StateError('no call expected: $op');

    // A relayed connection carries RPC and nothing else, so the two controls
    // that move bytes are dead — and say why rather than failing on press.
    await tester.pumpWidget(wrap(host, [workspace('ws-1', 'Alpha')]));
    await openRow(tester, 'Alpha');

    CcButton button(String label) =>
        tester.widget<CcButton>(find.widgetWithText(CcButton, label).first);
    expect(button('Download').onPressed, isNull);
    expect(button('Choose a file and upload').onPressed, isNull);
    expect(find.textContaining('through a relay'), findsOneWidget);
    // The server-path import is unaffected: it names a file the SERVER already
    // holds, so it needs no lane between here and there.
    expect(find.widgetWithText(CcButton, 'Import'), findsOneWidget);
  });

  testWidgets('a direct connection offers both file lanes', (tester) async {
    final host = FakeRpcHost();
    host.onCall = (op, args) => throw StateError('no call expected: $op');

    await tester.pumpWidget(
      wrap(
        host,
        [workspace('ws-1', 'Alpha')],
        proxy: MediaProxyConfig(
          httpBase: Uri.parse('http://127.0.0.1:9030'),
          deviceId: 'device-1',
          psk: 'psk-1',
        ),
      ),
    );
    await openRow(tester, 'Alpha');

    CcButton button(String label) =>
        tester.widget<CcButton>(find.widgetWithText(CcButton, label).first);
    expect(button('Download').onPressed, isNotNull);
    expect(button('Choose a file and upload').onPressed, isNotNull);
    expect(find.textContaining('through a relay'), findsNothing);
  });

  testWidgets('a download reports how far it has got', (tester) async {
    // A workspace database runs to gigabytes; a spinner for four minutes is
    // indistinguishable from a hang, which is the whole point of the bar.
    final release = Completer<void>();
    final host = FakeRpcHost();
    host.onCall = (op, args) => throw StateError('no call expected: $op');

    await tester.pumpWidget(
      wrap(
        host,
        [workspace('ws-1', 'Alpha')],
        proxy: MediaProxyConfig(
          httpBase: Uri.parse('http://127.0.0.1:9030'),
          deviceId: 'device-1',
          psk: 'psk-1',
        ),
        transfer: (ref) => _StubTransfer(ref, release.future),
      ),
    );
    await openRow(tester, 'Alpha');
    expect(find.byType(BackupTransferProgressBar), findsNothing);

    // Not `tapButton`: it settles, and a transfer in flight never settles —
    // the button's own spinner animates for as long as the bytes are moving,
    // which is the state this test exists to look at.
    final download = find.widgetWithText(CcButton, 'Download').first;
    await tester.ensureVisible(download);
    await tester.pumpAndSettle();
    await tester.tap(download);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Mid-flight: the bar is up and says how much of the file has arrived.
    expect(find.byType(BackupTransferProgressBar), findsOneWidget);
    expect(find.textContaining('/'), findsWidgets);

    release.complete();
    await tester.pumpAndSettle();

    // And it goes away with the transfer, rather than sitting full under a
    // button that is ready to be pressed again.
    expect(find.byType(BackupTransferProgressBar), findsNothing);
  });
}

/// A transfer that reports half a megabyte of a one-megabyte file, then waits
/// for the test to let it finish.
class _StubTransfer extends BackupTransfer {
  _StubTransfer(super.ref, this._release);

  final Future<void> _release;

  @override
  Future<BackupDownload> downloadWorkspace({
    required String workspaceId,
    required String suggestedName,
    BackupProgress? onProgress,
  }) async {
    onProgress?.call(512 * 1024, 1024 * 1024);
    await _release;
    return (outcome: BackupDownloadOutcome.saved, path: '/tmp/ws-1.db');
  }
}
