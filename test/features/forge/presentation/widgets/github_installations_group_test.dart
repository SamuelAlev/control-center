import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/forge/presentation/widgets/github_installations_group.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/fake_rpc_client.dart';

Map<String, dynamic> _installation(
  String id,
  String login, {
  bool suspended = false,
}) => {
  'installation_id': id,
  'account_id': '5$id',
  'account_login': login,
  'target_type': 'Organization',
  if (suspended) 'suspended': true,
};

void main() {
  late FakeRpcHost host;
  late List<Map<String, dynamic>> reads;
  late List<Map<String, dynamic>> listed;

  setUp(() {
    reads = [];
    listed = [];
    host = FakeRpcHost()
      ..onCall = (op, args) {
        if (op != 'github.installations') {
          throw StateError('unexpected op $op');
        }
        reads.add(args);
        return {'lane': 'connect', 'installations': listed};
      };
  });

  Future<void> pump(WidgetTester tester, {WorkspaceRole? role}) async {
    final rpc = host.client();
    addTearDown(rpc.close);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          rpcClientProvider.overrideWithValue(rpc),
          myWorkspaceRoleProvider.overrideWith((ref, ws) => role),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: GitHubInstallationsGroup(workspaceId: 'ws'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists installations with no per-server authorization step', (
    tester,
  ) async {
    listed = [
      _installation('77', 'acme'),
      _installation('78', 'globex', suspended: true),
    ];
    await pump(tester);

    expect(find.text('acme'), findsOneWidget);
    expect(find.text('globex'), findsOneWidget);
    // Only a suspended installation carries a tag; a working one needs none.
    expect(find.text('Suspended'), findsOneWidget);
    expect(find.byType(CcStatusTag), findsOneWidget);
    expect(find.textContaining('uthori'), findsNothing);
    // Installed somewhere already: the action adds another account.
    expect(find.text('Install on another organization'), findsOneWidget);
  });

  testWidgets('a plain read never asks GitHub afresh', (tester) async {
    await pump(tester, role: WorkspaceRole.admin);

    expect(reads, [
      {'workspace_id': 'ws'},
    ]);
  });

  testWidgets('an admin refresh asks GitHub afresh and shows the answer', (
    tester,
  ) async {
    await pump(tester, role: WorkspaceRole.admin);
    expect(find.text('acme'), findsNothing);

    listed = [_installation('77', 'acme')];
    await tester.tap(find.widgetWithText(CcButton, 'Refresh'));
    await tester.pumpAndSettle();

    expect(reads.last, {'workspace_id': 'ws', 'refresh': true});
    expect(reads, hasLength(2));
    expect(find.text('acme'), findsOneWidget);
  });

  testWidgets('a member has no refresh', (tester) async {
    await pump(tester, role: WorkspaceRole.member);

    expect(find.widgetWithText(CcButton, 'Refresh'), findsNothing);
  });
}
