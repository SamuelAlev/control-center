import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/auth/presentation/widgets/provider_sign_in_dialog.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_prompts.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_rpc_client.dart';
import '../../../../helpers/test_wrap.dart';

const _url = 'https://connect.example/start?login=cx-1';

Map<String, dynamic> _attempt({
  String mode = 'connect',
  String status = 'pending',
  String? error,
  String? codeError,
  String account = '',
}) => {
  'login_id': 'cx-1',
  'lane': 'github',
  'mode': mode,
  'url': _url,
  'expires_at': DateTime.now()
      .toUtc()
      .add(const Duration(minutes: 10))
      .toIso8601String(),
  'status': status,
  'account': account,
  'error': ?error,
  'code_error': ?codeError,
};

void main() {
  late AppLocalizations l10n;
  late FakeRpcHost host;
  late List<String> opened;
  late List<Map<String, dynamic>> completes;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    opened = [];
    completes = [];
    host = FakeRpcHost()
      ..onCall = (op, args) => switch (op) {
        'oauth.begin' => _attempt(),
        'oauth.complete' => () {
          completes.add(args);
          return _attempt(status: 'succeeded', account: 'octocat');
        }(),
        _ => throw StateError('unexpected op $op'),
      };
  });

  Widget scope(Widget child, {TextDirection? textDirection}) {
    final rpc = host.client();
    addTearDown(rpc.close);
    return ProviderScope(
      overrides: [
        rpcClientProvider.overrideWithValue(rpc),
        externalUrlOpenerProvider.overrideWithValue((url) {
          opened.add(url);
          return true;
        }),
      ],
      child: testWrap(child, textDirection: textDirection),
    );
  }

  /// A button that runs the real entry point, so closing and the success
  /// toast are exercised as callers see them.
  Widget launcher({String? workspaceId}) => Builder(
    builder: (context) => CcButton(
      onPressed: () => showProviderSignInDialog(
        context,
        lane: ConnectOAuthLane.github,
        workspaceId: workspaceId,
      ),
      child: const Text('open'),
    ),
  );

  Future<void> settle(WidgetTester tester) async {
    // The status spinner never settles; pump the RPC round trips through.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('Connect mode', () {
    testWidgets('opens the browser and asks for the code it shows', (
      tester,
    ) async {
      await tester.pumpWidget(scope(launcher()));
      await tester.tap(find.text('open'));
      await settle(tester);

      expect(opened, [_url]);
      expect(find.text(l10n.signInToProvider('GitHub')), findsOneWidget);
      expect(find.text(l10n.signInCodePrompt), findsOneWidget);
      expect(find.byType(CcTextField), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('refuses a malformed code without sending it', (tester) async {
      await tester.pumpWidget(scope(launcher()));
      await tester.tap(find.text('open'));
      await settle(tester);

      await tester.enterText(find.byType(EditableText), 'K7Q2');
      await tester.tap(find.widgetWithText(CcButton, l10n.continueLabel));
      await settle(tester);

      expect(find.text(l10n.signInCodeMalformed), findsOneWidget);
      expect(completes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a good code completes, closes and announces the account', (
      tester,
    ) async {
      await tester.pumpWidget(scope(launcher(workspaceId: 'ws-1')));
      await tester.tap(find.text('open'));
      await settle(tester);

      await tester.enterText(find.byType(EditableText), 'k7q2-9wxm');
      await tester.tap(find.widgetWithText(CcButton, l10n.continueLabel));
      await settle(tester);

      expect(completes.single, {
        'login_id': 'cx-1',
        'code': 'K7Q29WXM',
        'workspace_id': 'ws-1',
      });
      expect(find.text(l10n.signInCodePrompt), findsNothing);
      expect(
        find.text(l10n.signInSucceeded('GitHub', 'octocat')),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a rejected code says it did not match and stays open', (
      tester,
    ) async {
      host.onCall = (op, args) => switch (op) {
        'oauth.begin' => _attempt(),
        'oauth.complete' => _attempt(codeError: 'code_mismatch'),
        'oauth.status' => _attempt(),
        _ => throw StateError('unexpected op $op'),
      };
      await tester.pumpWidget(scope(launcher()));
      await tester.tap(find.text('open'));
      await settle(tester);

      await tester.enterText(find.byType(EditableText), 'K7Q29WXM');
      await tester.tap(find.widgetWithText(CcButton, l10n.continueLabel));
      await settle(tester);

      expect(find.text(l10n.signInErrorInvalidCode), findsOneWidget);
      expect(find.text(l10n.signInCodePrompt), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('failures', () {
    testWidgets('a failed attempt shows its reason and offers a retry', (
      tester,
    ) async {
      host.onCall = (op, args) => switch (op) {
        'oauth.begin' => _attempt(
          mode: 'own',
          status: 'failed',
          error: 'scope_mismatch',
        ),
        _ => throw StateError('unexpected op $op'),
      };
      await tester.pumpWidget(scope(launcher()));
      await tester.tap(find.text('open'));
      await settle(tester);

      expect(find.text(l10n.signInFailedTitle), findsOneWidget);
      expect(
        find.text(l10n.signInErrorScopeMismatch('GitHub')),
        findsOneWidget,
      );
      expect(find.widgetWithText(CcButton, l10n.retry), findsOneWidget);
    });

    testWidgets('a refused start shows what the server said', (tester) async {
      host.onCall = (op, args) =>
          throw StateError('GitHub sign-in is not set up on this server.');
      await tester.pumpWidget(scope(launcher()));
      await tester.tap(find.text('open'));
      await settle(tester);

      expect(
        find.textContaining('GitHub sign-in is not set up on this server.'),
        findsOneWidget,
      );
      expect(opened, isEmpty);
    });
  });

  testWidgets('the phishing warning names the danger and only closes', (
    tester,
  ) async {
    await tester.pumpWidget(
      scope(
        Builder(
          builder: (context) => CcButton(
            onPressed: () => showSignInPhishingWarning(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.signInPhishingTitle), findsOneWidget);
    expect(find.text(l10n.signInPhishingBody), findsOneWidget);
    expect(find.byType(CcButton), findsNWidgets(2));
    await tester.tap(find.widgetWithText(CcButton, l10n.close));
    await tester.pumpAndSettle();
    expect(find.text(l10n.signInPhishingTitle), findsNothing);
  });

  group('RTL', () {
    testWidgets('mirrors the layout but keeps the code left to right', (
      tester,
    ) async {
      await tester.pumpWidget(
        scope(
          const ProviderSignInDialog(
            lane: ConnectOAuthLane.github,
            workspaceId: null,
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      final field = find.byType(CcTextField);
      expect(field, findsOneWidget);
      expect(
        Directionality.of(tester.element(field)),
        TextDirection.ltr,
        reason: 'the code is a machine string',
      );
      expect(
        Directionality.of(tester.element(find.text(l10n.signInCodePrompt))),
        TextDirection.rtl,
      );
      // Actions mirror: the first one (Close) sits at the start, which is
      // the right-hand side.
      final close = tester.getCenter(find.widgetWithText(CcButton, l10n.close));
      final next = tester.getCenter(
        find.widgetWithText(CcButton, l10n.continueLabel),
      );
      expect(close.dx, greaterThan(next.dx));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('puts the waiting spinner at the start edge', (tester) async {
      host.onCall = (op, args) => switch (op) {
        'oauth.begin' => _attempt(mode: 'own'),
        'oauth.status' => _attempt(mode: 'own'),
        _ => throw StateError('unexpected op $op'),
      };
      await tester.pumpWidget(
        scope(
          const ProviderSignInDialog(
            lane: ConnectOAuthLane.github,
            workspaceId: null,
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      await settle(tester);

      final line = find.text(l10n.signInWaiting('GitHub'));
      expect(line, findsOneWidget);
      expect(
        tester.getCenter(find.byType(CcSpinner)).dx,
        greaterThan(tester.getCenter(line).dx),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
