import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart'
    show externalUrlOpenerProvider;
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/mcp/providers/workspace_mcp_servers_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_hover_reveal.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_sign_in_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_servers_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../../helpers/active_workspace.dart';
import '../../../../../../../helpers/test_wrap.dart';
import 'fake_workspace_mcp_server_control.dart';

/// Signing in to an MCP server: the browser goes to the provider, and the
/// code this server's page shows comes back typed into the dialog.
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });
  tearDown(SettingsHoverReveal.debugForgetMouse);

  late List<String> opened;

  Future<FakeWorkspaceMcpServerControl> pump(
    WidgetTester tester, {
    List<Object>? begins,
    List<McpServerAuthorization> completions = const [],
    bool browserOpens = true,
    TextDirection? textDirection,
  }) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    opened = [];
    final control = FakeWorkspaceMcpServerControl(
      personal: [httpEntry(lifecycle: 'needs_auth', userId: 'u-1')],
      begins: begins,
      completions: [...completions],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride('ws-1'),
          canUseHostProvider.overrideWithValue(false),
          myWorkspaceRoleProvider(
            'ws-1',
          ).overrideWith((ref) => WorkspaceRole.member),
          workspaceMcpServerControlProvider.overrideWithValue(control),
          externalUrlOpenerProvider.overrideWithValue((url) {
            opened.add(url);
            return browserOpens;
          }),
        ],
        child: testWrapWithToastOverlay(
          const SingleChildScrollView(
            child: McpServersSection(scope: McpServerScope.personal),
          ),
          textDirection: textDirection,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return control;
  }

  Future<void> startSignIn(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(CcButton, l10n.mcpServerSignIn));
    await tester.pumpAndSettle();
  }

  Finder codeField() => find.descendant(
    of: find.byType(McpServerSignInDialog),
    matching: find.byType(EditableText),
  );

  Future<void> finish(WidgetTester tester, String code) async {
    await tester.enterText(codeField(), code);
    await tester.tap(find.widgetWithText(CcButton, l10n.finish));
    await tester.pumpAndSettle();
  }

  testWidgets('the code from the browser signs in and re-reads the list', (
    tester,
  ) async {
    final control = await pump(
      tester,
      completions: [authorization(status: McpServerAuthorizationStatus.done)],
    );

    await startSignIn(tester);

    expect(control.calls, contains('authorize ws-1 personal srv-2'));
    expect(opened, ['https://auth.example.com/authorize?state=s1']);
    expect(find.text(l10n.mcpServerSignInTitle('linear')), findsOneWidget);
    expect(find.text(l10n.signInCodePrompt), findsOneWidget);
    expect(find.text(l10n.signInReopenPage), findsOneWidget);

    await finish(tester, 'k7q2-9wxm');

    // Typed loosely, sent as the code itself.
    expect(control.calls, contains('complete ws-1 personal att-1 K7Q29WXM'));
    expect(find.byType(McpServerSignInDialog), findsNothing);
    expect(find.text(l10n.mcpServerSignedIn('linear')), findsOneWidget);
    expect(control.listCalls[McpServerScope.personal], 2);
  });

  testWidgets('a wrong code says how many tries are left and stays open', (
    tester,
  ) async {
    final control = await pump(
      tester,
      completions: [
        authorization(
          status: McpServerAuthorizationStatus.wrongCode,
          triesLeft: 4,
        ),
        authorization(status: McpServerAuthorizationStatus.done),
      ],
    );
    await startSignIn(tester);

    await finish(tester, 'AAAA-BBBB');

    expect(find.text(l10n.mcpServerSignInWrongCode(4)), findsOneWidget);
    expect(find.byType(McpServerSignInDialog), findsOneWidget);

    await finish(tester, 'K7Q2-9WXM');

    expect(control.calls.where((c) => c.startsWith('complete ')), hasLength(2));
    expect(find.byType(McpServerSignInDialog), findsNothing);
  });

  testWidgets('something that cannot be a code is never sent', (tester) async {
    final control = await pump(tester);
    await startSignIn(tester);

    await finish(tester, 'ABC');

    expect(find.text(l10n.signInCodeMalformed), findsOneWidget);
    expect(control.calls.where((c) => c.startsWith('complete ')), isEmpty);
  });

  testWidgets('an ended sign-in has to be started again', (tester) async {
    final control = await pump(
      tester,
      begins: [
        authorization(),
        authorization(
          attemptId: 'att-2',
          url: 'https://auth.example.com/authorize?state=s2',
        ),
      ],
      completions: [authorization(status: McpServerAuthorizationStatus.failed)],
    );
    await startSignIn(tester);

    await finish(tester, 'K7Q2-9WXM');

    expect(find.text(l10n.mcpServerSignInEnded), findsOneWidget);
    expect(codeField(), findsNothing);
    expect(find.widgetWithText(CcButton, l10n.finish), findsNothing);

    await tester.tap(
      find.widgetWithText(CcButton, l10n.mcpServerSignInStartAgain),
    );
    await tester.pumpAndSettle();

    expect(
      control.calls.where((c) => c.startsWith('authorize ')),
      hasLength(2),
    );
    expect(opened.last, 'https://auth.example.com/authorize?state=s2');
    expect(find.text(l10n.mcpServerSignInEnded), findsNothing);
    expect(codeField(), findsOneWidget);
  });

  testWidgets('a refused start is toasted and opens nothing', (tester) async {
    await pump(
      tester,
      begins: [
        RemoteRpcException(RpcErrorCodes.invalidParams, 'raw words', {
          'kind': 'mcp_server.not_found',
        }),
      ],
    );

    await startSignIn(tester);

    expect(find.text(l10n.mcpServerNotFound), findsOneWidget);
    expect(find.text('raw words'), findsNothing);
    expect(find.byType(McpServerSignInDialog), findsNothing);
    expect(opened, isEmpty);
  });

  testWidgets('without a browser the link is shown to copy', (tester) async {
    await pump(tester, browserOpens: false);

    await startSignIn(tester);

    expect(find.text(l10n.couldNotOpenBrowser), findsOneWidget);
    expect(
      find.text('https://auth.example.com/authorize?state=s1'),
      findsOneWidget,
    );
    expect(find.text(l10n.signInReopenPage), findsNothing);
  });

  testWidgets('the dialog lays out right to left, the code left to right', (
    tester,
  ) async {
    await pump(tester, textDirection: TextDirection.rtl);
    await startSignIn(tester);

    expect(tester.takeException(), isNull);
    final finishButton = tester.getCenter(
      find.widgetWithText(CcButton, l10n.finish),
    );
    final cancel = tester.getCenter(find.widgetWithText(CcButton, l10n.cancel));
    expect(finishButton.dx, lessThan(cancel.dx));
    expect(Directionality.of(tester.element(codeField())), TextDirection.ltr);
  });
}
