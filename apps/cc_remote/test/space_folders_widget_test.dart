@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/phone_widgets_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/screens/messaging_screen.dart';
import 'package:cc_remote/space_folders.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _ws = 'ws-1';

SpaceDto _space(String id, {String workspaceId = _ws, bool archived = false}) =>
    SpaceDto(
      id: id,
      name: id,
      workspaceId: workspaceId,
      archivedAt: archived ? DateTime.utc(2025) : null,
    );

class _PhoneRpcHost {
  _PhoneRpcHost() {
    final (host, channel) = InProcessRpcChannel.pair();
    server = host;
    server.incoming.listen(_handle);
    client = RemoteRpcClient(channel)..start();
  }

  late final RemoteRpcChannelPort server;
  late final RemoteRpcClient client;
  late Map<String, dynamic> Function(String, Map<String, dynamic>) onCall;

  void _handle(Map<String, dynamic> frame) {
    final id = frame['id'];
    if (id == null) return;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    if (frame['method'] == RpcMethods.repoCall) {
      try {
        final op = params['op'] as String;
        final args = (params['args'] as Map).cast<String, dynamic>();
        final data = onCall(op, args);
        unawaited(
          server.send({
            'jsonrpc': '2.0',
            'id': id,
            'result': {'op': op, 'data': data},
          }),
        );
      } catch (error) {
        unawaited(
          server.send({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': -32000, 'message': '$error'},
          }),
        );
      }
      return;
    }
    unawaited(
      server.send({
        'jsonrpc': '2.0',
        'id': id,
        'result': {'capabilities': <String, dynamic>{}},
      }),
    );
  }

  Future<void> close() => server.close();
}

class _PhoneHost {
  _PhoneHost({
    required this.spaces,
    required String folders,
    this.locale = const Locale('en'),
  }) : _preferences = {'space_folders.$_ws': folders} {
    client = rpc.client;
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const MessagingScreen()),
        GoRoute(
          path: '/spaces/:id',
          builder: (_, state) =>
              Center(child: Text('Opened ${state.pathParameters['id']}')),
        ),
      ],
    );
    rpc.onCall = (op, args) {
      switch (op) {
        case 'prefs.set':
          final key = args['key'] as String;
          final value = args['value'] as String;
          written.add((key: key, value: value));
          _preferences[key] = value;
          changes.add(Map.of(_preferences));
          return const {'ok': true};
        case 'messaging.listSpaces':
          if (args['workspace_id'] != _ws) throw StateError('Wrong workspace');
          return {'spaces': spaces.map((s) => s.toJson()).toList()};
        case 'messaging.deleteSpace':
          if (args['workspace_id'] != _ws) throw StateError('Wrong workspace');
          deleted.add(args['space_id'] as String);
          return const {'ok': true};
      }
      throw StateError('Unexpected RPC: $op');
    };
  }

  final List<SpaceDto> spaces;
  final Locale locale;
  final Map<String, String> _preferences;
  final _PhoneRpcHost rpc = _PhoneRpcHost();
  final changes = StreamController<Map<String, String>>.broadcast();
  final List<({String key, String value})> written = [];
  final List<String> deleted = [];
  late final RemoteRpcClient client;
  late final GoRouter router;
  late final ProviderContainer container = ProviderContainer(
    overrides: [
      activeWorkspaceIdProvider.overrideWith((ref) async* {
        yield _ws;
      }),
      rpcClientProvider.overrideWith((ref) async* {
        yield client;
      }),
      spacesProvider.overrideWith((ref) async* {
        await ref.watch(rpcClientProvider.future);
        ref.watch(activeWorkspaceIdProvider);
        yield spaces;
      }),
      ownServerPrefsProvider.overrideWith((ref) async* {
        yield Map.of(_preferences);
        yield* changes.stream;
      }),
    ],
  );

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: WidgetsApp.router(
          color: const Color(0xFFFFFFFF),
          locale: locale,
          supportedLocales: kSupportedRemoteLocales,
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            PhoneWidgetsLocalizationsDelegate(),
          ],
          builder: (_, child) =>
              CcTheme(data: CcThemeData.light(), child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> close() async {
    container.dispose();
    router.dispose();
    await client.close();
    await rpc.close();
    await changes.close();
  }
}

List<Map<String, dynamic>> _savedFolders(_PhoneHost host) =>
    (jsonDecode(host.written.last.value) as List).cast<Map<String, dynamic>>();

Finder _moveButton(String id) => find.descendant(
  of: find.byKey(ValueKey('space-$id')),
  matching: find.byType(PhoneIconButton),
);

Finder _folderButton(String id) => find.descendant(
  of: find.byKey(ValueKey('folder-$id')),
  matching: find.byType(PhoneIconButton),
);

void main() {
  testWidgets(
    'groups only visible workspace spaces; collapse does not unfile',
    (tester) async {
      final host = _PhoneHost(
        spaces: [
          _space('First'),
          _space('Second'),
          _space('Archived', archived: true),
          _space('Wrong', workspaceId: 'ws-2'),
        ],
        folders: jsonEncode([
          {
            'id': 'folder',
            'name': 'Pinned',
            'spaceIds': ['First', 'Archived', 'Wrong'],
          },
        ]),
      );
      addTearDown(host.close);
      await host.mount(tester);

      expect(find.text('Pinned'), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Other spaces'), findsOneWidget);
      expect(find.text('Archived'), findsNothing);
      expect(find.text('Wrong'), findsNothing);

      await tester.tap(find.text('Pinned'));
      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Other spaces'), findsOneWidget);
      await tester.tap(find.text('Pinned'));
      await tester.pumpAndSettle();
      expect(find.text('First'), findsOneWidget);
    },
  );

  testWidgets('mirrors folder controls for Arabic without losing grouping', (
    tester,
  ) async {
    final host = _PhoneHost(
      spaces: [_space('First'), _space('Second')],
      folders: jsonEncode([
        {
          'id': 'folder',
          'name': 'Pinned',
          'spaceIds': ['First'],
        },
      ]),
      locale: const Locale('ar', 'SA'),
    );
    addTearDown(host.close);
    await host.mount(tester);

    final folder = find.byKey(const ValueKey('folder-folder'));
    expect(Directionality.of(tester.element(folder)), TextDirection.rtl);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    final menu = _folderButton('folder');
    final icon = find.descendant(
      of: folder,
      matching: find.byIcon(AppIcons.folder),
    );
    expect(tester.getCenter(menu).dx, lessThan(tester.getCenter(icon).dx));
  });
  testWidgets(
    'moves and unfiles spaces via touch picker and shared preference',
    (tester) async {
      final host = _PhoneHost(
        spaces: [_space('First'), _space('Second')],
        folders: jsonEncode([
          {
            'id': 'folder',
            'name': 'Pinned',
            'spaceIds': ['First'],
          },
        ]),
      );
      addTearDown(host.close);
      await host.mount(tester);

      await tester.tap(_moveButton('Second'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pinned').last);
      await tester.pumpAndSettle();
      expect(host.written.last.key, 'space_folders.$_ws');
      expect(_savedFolders(host).single['spaceIds'], ['First', 'Second']);
      expect(find.text('Other spaces'), findsNothing);

      await tester.tap(_moveButton('Second'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from folder'));
      await tester.pumpAndSettle();
      expect(_savedFolders(host).single['spaceIds'], ['First']);
      expect(find.text('Other spaces'), findsOneWidget);
    },
  );

  testWidgets(
    'creates a folder from a space, renames it, then unfiles on delete',
    (tester) async {
      final host = _PhoneHost(spaces: [_space('First')], folders: '[]');
      addTearDown(host.close);
      await host.mount(tester);

      await tester.tap(_moveButton('First'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New folder').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CcTextField), '  Notes  ');
      await tester.pump();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(find.byType(CcTextField), findsNothing);
      expect(find.textContaining('update folders'), findsNothing);
      final created = _savedFolders(host).single;
      final folderId = created['id'] as String;
      expect(created['name'], 'Notes');
      expect(created['spaceIds'], ['First']);

      await tester.tap(_folderButton(folderId));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename folder'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CcTextField), 'Current');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(_savedFolders(host).single['name'], 'Current');

      await tester.tap(_folderButton(folderId));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete folder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(host.deleted, isEmpty);
      expect(find.text('Current'), findsOneWidget);
      await tester.tap(_folderButton(folderId));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete folder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete folder').last);
      await tester.pumpAndSettle();
      expect(jsonDecode(host.written.last.value), isEmpty);
      expect(host.deleted, isEmpty);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Current'), findsNothing);
    },
  );

  testWidgets('creates an empty folder even when the workspace has no spaces', (
    tester,
  ) async {
    final host = _PhoneHost(spaces: const [], folders: '[]');
    addTearDown(host.close);
    await host.mount(tester);

    expect(find.text('No spaces'), findsOneWidget);
    await tester.tap(find.text('New folder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CcTextField), 'Planning');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.byType(CcTextField), findsNothing);
    expect(find.textContaining('update folders'), findsNothing);
    expect(_savedFolders(host).single['name'], 'Planning');
    expect(find.text('Planning'), findsOneWidget);
  });

  testWidgets(
    'permanent deletion only targets actual spaces in this workspace',
    (tester) async {
      final host = _PhoneHost(
        spaces: [
          _space('First'),
          _space('Wrong', workspaceId: 'ws-2'),
        ],
        folders: jsonEncode([
          {
            'id': 'folder',
            'name': 'Pinned',
            'spaceIds': ['Wrong', 'stale', 'First'],
          },
        ]),
      );
      addTearDown(host.close);
      await host.mount(tester);

      await tester.tap(_folderButton('folder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete folder'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(CcCheckbox)).height,
        greaterThanOrEqualTo(kMinTouchTarget),
      );
      await tester.tap(find.byType(CcCheckbox));
      await tester.pumpAndSettle();
      expect(find.textContaining('permanently removes'), findsOneWidget);
      await tester.tap(find.text('Delete folder and spaces'));
      await tester.pumpAndSettle();
      expect(find.byType(CcCheckbox), findsNothing);
      expect(find.textContaining('update folders'), findsNothing);
      expect(host.deleted, ['First']);
      expect(_savedFolders(host), isEmpty);
    },
  );
}
