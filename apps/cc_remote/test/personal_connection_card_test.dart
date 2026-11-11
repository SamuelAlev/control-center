@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart' show SignInLaneInfo, SignInLaneMode;
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
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
          'error': error is _RpcError
              ? {
                  'code': error.code,
                  'message': error.message,
                  'data': error.data,
                }
              : {'code': -32000, 'message': '$error'},
        }),
      );
    }
  }

  Future<void> close() async {
    await client.close();
    await server.close();
  }
}

/// A server refusal with its own code and `data`.
class _RpcError {
  const _RpcError(this.code, this.message, this.data);

  final int code;
  final String message;
  final Map<String, dynamic> data;
}

Map<String, dynamic> _attempt(
  String status, {
  String mode = 'connect',
  String? codeError,
  String? error,
  String? message,
}) => {
  'login_id': 'login-1234567890abcdef12',
  'lane': 'github',
  'mode': mode,
  'url': 'https://connect.example/oauth/github/start',
  'expires_at': DateTime.now()
      .toUtc()
      .add(const Duration(minutes: 10))
      .toIso8601String(),
  'status': status,
  'code_error': ?codeError,
  'error': ?error,
  'message': ?message,
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

PersonalConnectionCard _github({
  required SignInLaneInfo? info,
  ForgeConnectionStatus? status,
  ForgeCredentialScope? scope,
  bool connected = false,
  String username = '',
}) => PersonalConnectionCard(
  providerId: 'github',
  name: 'GitHub',
  workspaceId: _ws,
  isForge: true,
  connected: connected,
  username: username,
  canManage: true,
  lane: ConnectOAuthLane.github,
  laneInfo: info,
  status: status,
  scope: scope,
);

const _connectLane = SignInLaneInfo(
  lane: ConnectOAuthLane.github,
  mode: SignInLaneMode.connect,
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
      'oauth.complete' => _attempt('pending', codeError: 'code_mismatch'),
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

  testWidgets('a failed call is not reported as a wrong code', (tester) async {
    final host = _Host();
    addTearDown(host.close);
    host.onCall = (op, args) => switch (op) {
      'oauth.begin' || 'oauth.status' => _attempt('pending'),
      'oauth.complete' => throw StateError('socket closed'),
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

    expect(find.textContaining("doesn't match this sign-in"), findsNothing);
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

  testWidgets('a lapsed sign-in says so and offers sign in again', (
    tester,
  ) async {
    final host = _Host();
    addTearDown(host.close);
    await _mount(
      tester,
      host,
      _github(info: _connectLane, status: ForgeConnectionStatus.needsSignIn),
    );
    expect(
      find.text('Your GitHub sign-in has lapsed. Sign in again.'),
      findsOne,
    );
    expect(find.text('Sign in again'), findsOne);
    expect(find.text('Disconnect'), findsOne);
  });

  testWidgets('a paused sign-in explains itself and offers no sign-in', (
    tester,
  ) async {
    final host = _Host();
    addTearDown(host.close);
    await _mount(
      tester,
      host,
      _github(info: _connectLane, status: ForgeConnectionStatus.paused),
    );
    expect(find.textContaining('sign-in service changed'), findsOne);
    expect(find.text('Sign in again'), findsNothing);
    expect(find.text('Sign in with browser'), findsNothing);
    expect(find.text('Disconnect'), findsOne);
  });

  testWidgets('an unreachable provider reads as retrying', (tester) async {
    final host = _Host();
    addTearDown(host.close);
    await _mount(
      tester,
      host,
      _github(info: _connectLane, status: ForgeConnectionStatus.unreachable),
    );
    expect(find.text("Can't reach GitHub right now. Retrying."), findsOne);
    expect(find.text('Sign in with browser'), findsNothing);
  });

  testWidgets('a connection names its scope, and so does removing it', (
    tester,
  ) async {
    final host = _Host();
    addTearDown(host.close);
    await _mount(
      tester,
      host,
      _github(
        info: _connectLane,
        status: ForgeConnectionStatus.connected,
        scope: ForgeCredentialScope.workspace,
        connected: true,
        username: 'octocat',
      ),
    );
    expect(find.text('Signed in as octocat · This workspace only'), findsOne);
    await tester.tap(find.text('Disconnect'));
    await _settle(tester);
    expect(find.textContaining('Other workspaces keep theirs'), findsOne);
  });

  testWidgets('a Bitbucket token goes out with its account email', (
    tester,
  ) async {
    final host = _Host();
    addTearDown(host.close);
    host.onCall = (op, args) => switch (op) {
      'credentials.setForgeToken' => <String, dynamic>{},
      'forge.listConnections' => {'connections': <Object>[]},
      _ => throw StateError('Unexpected RPC: $op'),
    };
    await _mount(
      tester,
      host,
      const PersonalConnectionCard(
        providerId: 'bitbucket',
        name: 'Bitbucket',
        workspaceId: _ws,
        isForge: true,
        connected: false,
        username: '',
        canManage: true,
      ),
    );
    await tester.tap(find.text('Add token'));
    await _settle(tester);
    expect(find.text('Atlassian account email'), findsOne);

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'ana');
    await tester.enterText(fields.at(1), 'ATATT-1');
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(
      host.calls.where((c) => c.$1 == 'credentials.setForgeToken'),
      isEmpty,
    );
    expect(
      find.text('Enter the email address of your Atlassian account.'),
      findsOne,
    );

    await tester.enterText(fields.at(0), 'ana@example.com');
    await tester.tap(find.text('Save'));
    await _settle(tester);
    final saved = host.calls
        .firstWhere((c) => c.$1 == 'credentials.setForgeToken')
        .$2;
    expect(saved['token'], 'ana@example.com:ATATT-1');
    // The person's own token, used in every workspace: no scope, and no
    // workspace to pin it to.
    expect(saved.containsKey('scope'), isFalse);
    expect(saved.containsKey('workspace_id'), isFalse);
  });

  testWidgets('an own-app sign-in also asks for the code its page shows', (
    tester,
  ) async {
    final host = _Host();
    addTearDown(host.close);
    host.onCall = (op, args) => switch (op) {
      'oauth.begin' => _attempt('pending', mode: 'own'),
      'oauth.complete' => _attempt('succeeded', mode: 'own'),
      'oauth.status' => _attempt('pending', mode: 'own'),
      'forge.listConnections' => {'connections': <Object>[]},
      _ => throw StateError('Unexpected RPC: $op'),
    };
    await _mount(
      tester,
      host,
      _github(
        info: const SignInLaneInfo(
          lane: ConnectOAuthLane.github,
          mode: SignInLaneMode.own,
          redirectUri: 'https://cc.example.com/oauth/github/callback',
        ),
      ),
    );

    await tester.tap(find.text('Sign in with browser'));
    await _settle(tester);
    expect(
      find.text('Confirm in your browser, then enter the code it shows.'),
      findsOne,
    );
    await tester.enterText(find.byType(EditableText), 'abcd-efgh');
    await tester.tap(find.text('Confirm'));
    await _settle(tester);

    final complete = host.calls.firstWhere((c) => c.$1 == 'oauth.complete').$2;
    expect(complete['code'], 'ABCDEFGH');
  });

  testWidgets('an account another person holds gets its own sentence', (
    tester,
  ) async {
    final host = _Host();
    addTearDown(host.close);
    host.onCall = (op, args) => switch (op) {
      'oauth.begin' => _attempt('pending'),
      'oauth.complete' => _attempt(
        'failed',
        error: 'account_already_bound',
        message:
            'This account is already connected to another person on this '
            'server. An account can act for one person only.',
      ),
      'oauth.status' => _attempt('pending'),
      'forge.listConnections' => {'connections': <Object>[]},
      _ => throw StateError('Unexpected RPC: $op'),
    };
    await _mount(tester, host, _github(info: _connectLane));

    await tester.tap(find.text('Sign in with browser'));
    await _settle(tester);
    await tester.enterText(find.byType(EditableText), 'ABCDEFGH');
    await tester.tap(find.text('Confirm'));
    await _settle(tester);

    expect(
      find.text(
        'This account is already connected to another person on this server. '
        'Sign in with a different account.',
      ),
      findsOne,
    );
    expect(find.textContaining('was refused'), findsNothing);
  });

  testWidgets('a refused token says why', (tester) async {
    final host = _Host();
    addTearDown(host.close);
    host.onCall = (op, args) => switch (op) {
      'credentials.setForgeToken' => throw const _RpcError(
        -32005,
        'This GitLab token lacks the "api" scope.',
        {'code': 'person_token.narrow_scope'},
      ),
      'forge.listConnections' => {'connections': <Object>[]},
      _ => throw StateError('Unexpected RPC: $op'),
    };
    await _mount(
      tester,
      host,
      const PersonalConnectionCard(
        providerId: 'gitlab',
        name: 'GitLab',
        workspaceId: _ws,
        isForge: true,
        connected: false,
        username: '',
        canManage: true,
      ),
    );
    await tester.tap(find.text('Add token'));
    await _settle(tester);
    await tester.enterText(find.byType(EditableText), 'glpat-1');
    await tester.tap(find.text('Save'));
    await _settle(tester);

    expect(
      find.text(
        'This token is missing the api scope, which reviewing and commenting '
        'need. Create one that has it.',
      ),
      findsOne,
    );
  });
}
