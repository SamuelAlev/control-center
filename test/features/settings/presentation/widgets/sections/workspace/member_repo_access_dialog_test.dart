import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/member_repo_access_dialog.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/fake_rpc_client.dart';

void main() {
  final now = DateTime.now();

  final repos = [
    Repo(
      id: 'r-1',
      name: 'alpha/app',
      path: '/tmp/alpha-app',
      remoteOwner: 'alpha',
      remoteName: 'app',
      createdAt: now,
      updatedAt: now,
    ),
    Repo(
      id: 'r-2',
      name: 'alpha/api',
      path: '/tmp/alpha-api',
      remoteOwner: 'alpha',
      remoteName: 'api',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  /// The setRepoGrant calls the dialog issued, in order.
  final grantCalls = <Map<String, dynamic>>[];

  Widget wrap(FakeRpcHost host) {
    return ProviderScope(
      overrides: [
        rpcClientProvider.overrideWithValue(host.client()),
        reposForWorkspaceProvider(
          'ws-1',
        ).overrideWith((ref) => Stream.value(repos)),
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MemberRepoAccessDialog(
              workspaceId: 'ws-1',
              userId: 'u-2',
              memberName: 'Riley Chen',
            ),
          ),
        ),
      ),
    );
  }

  FakeRpcHost hostWithGrants(Map<String, String> grants) {
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      if (op == 'members.getRepoGrants') {
        return {'grants': grants};
      }
      if (op == 'members.setRepoGrant') {
        grantCalls.add(Map.of(args));
        return {'ok': true};
      }
      throw StateError('unexpected op $op');
    };
    return host;
  }

  setUp(grantCalls.clear);

  testWidgets('renders current grants: shared repo checked, other hidden', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(hostWithGrants(const {'r-1': 'read'})));
    await tester.pumpAndSettle();

    expect(find.text('Repo access for Riley Chen'), findsOneWidget);
    expect(find.text('alpha/app'), findsOneWidget);
    expect(find.text('alpha/api'), findsOneWidget);

    final checkboxes = tester
        .widgetList<CcCheckbox>(find.byType(CcCheckbox))
        .toList();
    expect(checkboxes, hasLength(2));
    expect(checkboxes[0].value, isTrue);
    expect(checkboxes[1].value, isFalse);
    // The level dropdown only renders for shared repos.
    expect(find.byType(CcSelect<String>), findsOneWidget);
  });

  testWidgets('checking an unshared repo grants it read access', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(hostWithGrants(const {})));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CcCheckbox).at(1));
    await tester.pumpAndSettle();

    expect(grantCalls, hasLength(1));
    expect(grantCalls.single['workspace_id'], 'ws-1');
    expect(grantCalls.single['user_id'], 'u-2');
    expect(grantCalls.single['repo_id'], 'r-2');
    expect(grantCalls.single['level'], 'read');
  });

  testWidgets('unchecking a shared repo revokes it (level none)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(hostWithGrants(const {'r-1': 'write'})));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CcCheckbox).first);
    await tester.pumpAndSettle();

    expect(grantCalls, hasLength(1));
    expect(grantCalls.single['repo_id'], 'r-1');
    expect(grantCalls.single['level'], 'none');
  });

  testWidgets('changing the level dropdown updates the grant', (tester) async {
    await tester.pumpWidget(wrap(hostWithGrants(const {'r-1': 'read'})));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CcSelect<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write').last);
    await tester.pumpAndSettle();

    expect(grantCalls, hasLength(1));
    expect(grantCalls.single['repo_id'], 'r-1');
    expect(grantCalls.single['level'], 'write');
  });
}
