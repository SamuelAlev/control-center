import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/merged_space_archive_prompt.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/fake_rpc_client.dart';

Space _space(String workspaceId, String id) => Space(
  id: id,
  workspaceId: workspaceId,
  name: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class _Fixture {
  _Fixture() {
    host.onCall = (op, args) {
      if (op == 'prefs.set') {
        if (failWrite) {
          throw StateError('Write failed');
        }
        prefs[args['key'] as String] = args['value'] as String;
      } else if (op == 'messaging.archiveSpace') {
        archived.add((
          args['workspace_id'] as String,
          args['space_id'] as String,
        ));
      } else {
        throw StateError('Unexpected operation: $op');
      }
      return {'ok': true};
    };
  }
  final prefs = <String, String>{};
  final archived = <(String, String)>[];
  final host = FakeRpcHost();
  bool failWrite = false;

  GoRouter router() => GoRouter(
    initialLocation: spaceRoute('ws-1', 'space-1'),
    routes: [
      GoRoute(
        path: '/workspaces/:wid/spaces/:sid',
        builder: (_, state) => Align(
          alignment: AlignmentDirectional.topStart,
          child: MergedSpaceArchivePrompt(
            key: ValueKey(state.uri.path),
            workspaceId: state.pathParameters['wid']!,
            spaceId: state.pathParameters['sid']!,
          ),
        ),
      ),
      GoRoute(
        path: '/workspaces/:wid/spaces',
        builder: (_, _) => const SizedBox(),
      ),
    ],
  );

  Widget app(GoRouter router, {Stream<Map<String, String>>? initialPrefs}) {
    return ProviderScope(
      overrides: [
        rpcClientProvider.overrideWithValue(host.client()),
        ownServerPrefsProvider.overrideWith(
          (ref) => initialPrefs ?? Stream.value(Map.of(prefs)),
        ),
        for (final workspace in ['ws-1', 'ws-2'])
          workspaceSpacesProvider(workspace).overrideWith(
            (ref) => Stream.value([
              _space(workspace, 'space-1'),
              _space(workspace, 'space-2'),
            ]),
          ),
        spaceAllPrsMergedProvider.overrideWith((ref, id) => true),
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'declining survives reopen and a new client, scoped per space and workspace',
    (tester) async {
      final fixture = _Fixture();
      addTearDown(fixture.host.close);
      final router = fixture.router();
      addTearDown(router.dispose);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(fixture.app(router));
      await tester.pumpAndSettle();
      expect(find.text(l10n.spaceAllPrsMerged), findsOneWidget);

      await tester.tap(find.text(l10n.spaceKeepAfterMerge));
      await tester.pumpAndSettle();
      expect(find.text(l10n.spaceAllPrsMerged), findsNothing);
      expect(fixture.archived, isEmpty);

      router.go(spaceRoute('ws-1', 'space-2'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.spaceAllPrsMerged), findsOneWidget);
      router.go(spaceRoute('ws-1', 'space-1'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.spaceAllPrsMerged), findsNothing);
      router.go(spaceRoute('ws-2', 'space-1'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.spaceAllPrsMerged), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      final secondRouter = fixture.router();
      addTearDown(secondRouter.dispose);
      await tester.pumpWidget(fixture.app(secondRouter));
      await tester.pumpAndSettle();
      expect(find.text(l10n.spaceAllPrsMerged), findsNothing);
    },
  );

  testWidgets('waits for preferences and retains the notice if saving fails', (
    tester,
  ) async {
    final fixture = _Fixture()..failWrite = true;
    final snapshots = StreamController<Map<String, String>>();
    final router = fixture.router();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await snapshots.close();
      await fixture.host.close();
    });
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      fixture.app(router, initialPrefs: snapshots.stream),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.spaceAllPrsMerged), findsNothing);
    snapshots.add({});
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.spaceKeepAfterMerge));
    await tester.pumpAndSettle();
    expect(find.text(l10n.spaceAllPrsMerged), findsOneWidget);
    expect(find.textContaining('Write failed'), findsOneWidget);
    expect(fixture.prefs, isEmpty);
    fixture.failWrite = false;
    await tester.tap(find.text(l10n.spaceKeepAfterMerge));
    await tester.pumpAndSettle();
    expect(find.text(l10n.spaceAllPrsMerged), findsNothing);
  });

  testWidgets(
    'archive uses soft archive, unfiles the space, and remembers the answer',
    (tester) async {
      final fixture = _Fixture();
      fixture.prefs['space_folders.ws-1'] = jsonEncode([
        {
          'id': 'folder',
          'name': 'Work',
          'spaceIds': ['space-1', 'space-2'],
        },
      ]);
      addTearDown(fixture.host.close);
      final router = fixture.router();
      addTearDown(router.dispose);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(fixture.app(router));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.archiveSpace));
      await tester.pumpAndSettle();
      expect(fixture.archived, [('ws-1', 'space-1')]);
      expect(
        router.routeInformationProvider.value.uri.path,
        spacesRoute('ws-1'),
      );
      final folder = (jsonDecode(fixture.prefs['space_folders.ws-1']!) as List)
          .cast<Map<String, dynamic>>()
          .single;
      expect(folder['spaceIds'], ['space-2']);
      router.go(spaceRoute('ws-1', 'space-1'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.spaceAllPrsMerged), findsNothing);
    },
  );
}
