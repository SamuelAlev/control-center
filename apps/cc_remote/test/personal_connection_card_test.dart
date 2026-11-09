@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart' show SignInLaneInfo, SignInLaneMode;
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/phone_widgets_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/credentials/personal_connection_card.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

const _ws = 'ws-1';

/// An in-process server answering `repo.call` ops with [onCall].
class _Host {
  _Host() {
    final (host, channel) = InProcessRpcChannel.pair();
    server = host;
    server.incoming.listen(_handle);
    client = RemoteRpcClient(channel)..start();
  }

  late final RemoteRpcChannelPort server;
  late final RemoteRpcClient client;
  final List<(String, Map<String, dynamic>)> calls = [];
  Map<String, dynamic> Function(String, Map<String, dynamic>) onCall =
      (op, _) => throw StateError('Unexpected RPC: $op');

  void _handle(Map<String, dynamic> frame) {
    final id = frame['id'];
    if (id == null) return;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    if (frame['method'] != RpcMethods.repoCall) {
      unawaited(
        server.send({
          'jsonrpc': '2.0',
          'id': id,
          'result': {'capabilities': <String, dynamic>{}},
        }),
      );
      return;
    }
    final op = params['op'] as String;
    final args = (params['args'] as Map).cast<String, dynamic>();
    calls.add((op, args));
    try {
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
  }

  Future<void> close() async {
    await client.close();
    await server.close();
  }
}

Map<String, dynamic> _attempt(String status, {String mode = 'connect'}) => {
  'login_id': 'login-1234567890abcdef12',
  'lane': 'github',
  'mode': mode,
  'url': 'https://connect.example/oauth/github/start',
  'expires_at': DateTime.now()
      .toUtc()
      .add(const Duration(minutes: 10))
      .toIso8601String(),
  'status': status,
};

Future<void> _mount(WidgetTester tester, _Host host, Widget card) async {
  final container = ProviderContainer(
    overrides: [
      activeWorkspaceIdProvider.overrideWith((ref) async* {
        yield _ws;
      }),
      rpcClientProvider.overrideWith((ref) async* {
        yield host.client;
      }),
    ],
  );
  addTearDown(container.dispose);
  // The card reads both synchronously when acting: keep them resolved.
  container
    ..listen(activeWorkspaceIdProvider, (_, _) {})
    ..listen(rpcClientProvider, (_, _) {});
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: WidgetsApp(
        color: const Color(0xFFFFFFFF),
        locale: const Locale('en'),
        supportedLocales: kSupportedRemoteLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          PhoneWidgetsLocalizationsDelegate(),
        ],
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: CcTheme(
          data: CcThemeData.light(),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111111),
              decoration: TextDecoration.none,
            ),
            child: SingleChildScrollView(child: card),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

PersonalConnectionCard _github({required SignInLaneInfo? info}) =>
    PersonalConnectionCard(
      providerId: 'github',
      name: 'GitHub',
      workspaceId: _ws,
      isForge: true,
      connected: false,
      username: '',
      canManage: true,
      lane: ConnectOAuthLane.github,
      laneInfo: info,
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
}

/// URLs the card handed to `window.open`.
final _opened = <String>[];

void main() {
  // A real `window.open` hides the test page, which stops frames for the
  // tests that follow.
  setUpAll(() {
    JSAny? open(JSString? url, JSString? target, JSString? features) {
      _opened.add(url?.toDart ?? '');
      return null;
    }

    (web.window as JSObject).setProperty('open'.toJS, open.toJS);
  });
  setUp(_opened.clear);

  testWidgets('a Connect sign-in hands the typed code back to the server', (
    tester,
  ) async {
    final host = _Host();
    addTearDown(host.close);
    host.onCall = (op, args) => switch (op) {
      'oauth.begin' => _attempt('pending'),
      'oauth.complete' => _attempt('succeeded'),
      'oauth.status' => _attempt('pending'),
      'forge.listConnections' => {'connections': <Object>[]},
      _ => throw StateError('Unexpected RPC: $op'),
    };
    await _mount(
      tester,
      host,
      _github(
        info: const SignInLaneInfo(
          lane: ConnectOAuthLane.github,
          mode: SignInLaneMode.connect,
        ),
      ),
    );

    await tester.tap(find.text('Sign in with browser'));
    await _settle(tester);
    final begin = host.calls.firstWhere((c) => c.$1 == 'oauth.begin').$2;
    expect(begin['lane'], 'github');
    expect(begin['workspace_id'], _ws);
    expect(_opened, ['https://connect.example/oauth/github/start']);

    await tester.enterText(find.byType(EditableText), 'abcd efgh');
    await tester.tap(find.text('Confirm'));
    await _settle(tester);

    final complete = host.calls.firstWhere((c) => c.$1 == 'oauth.complete').$2;
    expect(complete['code'], 'ABCDEFGH', reason: 'normalised before sending');
    expect(complete['workspace_id'], _ws);
    expect(find.text('Confirm'), findsNothing, reason: 'the attempt settled');
  });

  testWidgets('a malformed code is refused locally', (tester) async {
    final host = _Host();
    addTearDown(host.close);
    host.onCall = (op, args) => switch (op) {
      'oauth.begin' || 'oauth.status' => _attempt('pending'),
      _ => throw StateError('Unexpected RPC: $op'),
    };
    await _mount(
      tester,
      host,
      _github(
        info: const SignInLaneInfo(
          lane: ConnectOAuthLane.github,
          mode: SignInLaneMode.connect,
        ),
      ),
    );
    await tester.tap(find.text('Sign in with browser'));
    await _settle(tester);

    await tester.enterText(find.byType(EditableText), 'abc');
    await tester.tap(find.text('Confirm'));
    await _settle(tester);

    expect(host.calls.where((c) => c.$1 == 'oauth.complete'), isEmpty);
    expect(find.textContaining("doesn't look like a sign-in code"), findsOne);
  });

  testWidgets('a code the server refuses keeps the attempt open', (
    tester,
  ) async {
    final host = _Host();
    addTearDown(host.close);
    host.onCall = (op, args) => switch (op) {
      'oauth.begin' || 'oauth.status' => _attempt('pending'),
      'oauth.complete' => throw StateError('wrong code'),
      _ => throw StateError('Unexpected RPC: $op'),
    };
    await _mount(
      tester,
      host,
      _github(
        info: const SignInLaneInfo(
          lane: ConnectOAuthLane.github,
          mode: SignInLaneMode.connect,
        ),
      ),
    );
    await tester.tap(find.text('Sign in with browser'));
    await _settle(tester);
    await tester.enterText(find.byType(EditableText), 'ABCDEFGH');
    await tester.tap(find.text('Confirm'));
    await _settle(tester);

    expect(find.textContaining("doesn't match this sign-in"), findsOne);
    expect(find.text('Confirm'), findsOne);
  });

  testWidgets('an own-app sign-in on a private callback cannot start from a '
      'phone', (tester) async {
    final host = _Host();
    addTearDown(host.close);
    await _mount(
      tester,
      host,
      _github(
        info: const SignInLaneInfo(
          lane: ConnectOAuthLane.github,
          mode: SignInLaneMode.own,
          redirectUri: 'http://localhost:8443/oauth/github/callback',
        ),
      ),
    );

    expect(find.text('Sign in with browser'), findsNothing);
    expect(find.textContaining('reachable securely from a phone'), findsOne);
    expect(host.calls, isEmpty);
  });

  testWidgets('GitHub never offers a pasted token; GitLab does', (
    tester,
  ) async {
    final host = _Host();
    addTearDown(host.close);
    await _mount(
      tester,
      host,
      Column(
        children: [
          _github(
            info: const SignInLaneInfo(
              lane: ConnectOAuthLane.github,
              mode: SignInLaneMode.unavailable,
            ),
          ),
          const PersonalConnectionCard(
            providerId: 'gitlab',
            name: 'GitLab',
            workspaceId: _ws,
            isForge: true,
            connected: false,
            username: '',
            canManage: true,
          ),
        ],
      ),
    );

    expect(find.text('Add token'), findsOne, reason: 'GitLab only');
    expect(
      find.text("GitHub sign-in isn't set up on this server yet."),
      findsOne,
    );
  });
}
