import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/mcp/providers/workspace_mcp_servers_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_hover_reveal.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_servers_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../../helpers/active_workspace.dart';
import '../../../../../../../helpers/test_wrap.dart';
import 'fake_workspace_mcp_server_control.dart';

/// MCP servers in a workspace: the workspace's, which admins manage and the
/// server owner approves, and each member's own.
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });
  tearDown(SettingsHoverReveal.debugForgetMouse);

  Future<FakeWorkspaceMcpServerControl> pump(
    WidgetTester tester, {
    McpServerScope scope = McpServerScope.workspace,
    bool owner = false,
    WorkspaceRole role = WorkspaceRole.admin,
    List<WorkspaceMcpServerEntry>? workspace,
    List<WorkspaceMcpServerEntry> personal = const [],
    bool unavailable = false,
    TextDirection? textDirection,
  }) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final control = FakeWorkspaceMcpServerControl(
      workspace: workspace ?? [stdioEntry(), httpEntry()],
      personal: personal,
      unavailable: unavailable,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride('ws-1'),
          canUseHostProvider.overrideWithValue(owner),
          myWorkspaceRoleProvider('ws-1').overrideWith((ref) => role),
          workspaceMcpServerControlProvider.overrideWithValue(control),
        ],
        child: testWrap(
          SingleChildScrollView(child: McpServersSection(scope: scope)),
          textDirection: textDirection,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return control;
  }

  group('workspace servers', () {
    testWidgets('lists servers with their state and the approval wait', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text(l10n.mcpWorkspaceServers.toUpperCase()), findsOneWidget);
      expect(find.text('github'), findsOneWidget);
      expect(find.text('npx -y server-github'), findsOneWidget);
      expect(find.text(l10n.mcpStatusAwaitingApproval), findsOneWidget);
      expect(find.text(l10n.mcpApprovalStdioMember), findsOneWidget);

      expect(find.text('linear'), findsOneWidget);
      expect(find.text('https://mcp.example.com/mcp'), findsOneWidget);
      expect(find.text(l10n.mcpStatusConnected), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      // Approved: no public-only fact, no approval line.
      expect(find.text(l10n.mcpPublicAddressesOnly), findsNothing);
      expect(find.text(l10n.mcpApprovalRemoteMember), findsNothing);
      // Connected: nothing to sign in to.
      expect(find.text(l10n.mcpServerSignInNeeded), findsNothing);

      expect(find.widgetWithText(CcButton, l10n.mcpAddServer), findsOneWidget);
      // An admin who is not the owner never gets Approve.
      expect(
        find.widgetWithText(CcButton, l10n.mcpApproveServer),
        findsNothing,
      );
    });

    testWidgets('the server owner approves an unapproved server', (
      tester,
    ) async {
      final control = await pump(
        tester,
        owner: true,
        workspace: [stdioEntry(), httpEntry(approved: false)],
      );

      expect(find.text(l10n.mcpApprovalStdioOwner), findsOneWidget);
      expect(find.text(l10n.mcpApprovalRemoteOwner), findsOneWidget);
      expect(find.text(l10n.mcpPublicAddressesOnly), findsOneWidget);
      expect(
        find.widgetWithText(CcButton, l10n.mcpApproveServer),
        findsNWidgets(2),
      );

      await tester.tap(
        find.widgetWithText(CcButton, l10n.mcpApproveServer).first,
      );
      await tester.pumpAndSettle();

      expect(control.calls, contains('approve ws-1 srv-1'));
      expect(control.listCalls[McpServerScope.workspace], 2);
    });

    testWidgets("a member is told the list is the admins'", (tester) async {
      final control = await pump(tester, role: WorkspaceRole.member);

      expect(find.text(l10n.mcpWorkspaceServersAdminsOnly), findsOneWidget);
      expect(find.text('github'), findsNothing);
      expect(find.widgetWithText(CcButton, l10n.mcpAddServer), findsNothing);
      expect(control.listCalls, isEmpty);
    });

    testWidgets('a server without the ops says so', (tester) async {
      await pump(tester, unavailable: true);

      expect(find.text(l10n.mcpWorkspaceServersUnavailable), findsOneWidget);
      expect(find.widgetWithText(CcButton, l10n.mcpAddServer), findsNothing);
    });

    testWidgets('the switch saves only enabled, and remove asks first', (
      tester,
    ) async {
      final control = await pump(tester);

      await tester.tap(find.byType(CcSwitch).last);
      await tester.pumpAndSettle();
      final draft = control.saved.single;
      expect(draft.id, 'srv-2');
      expect(draft.enabled, isFalse);
      expect(draft.headerSet, isEmpty);
      expect(draft.headerRemove, isEmpty);
      expect(control.calls, contains('save ws-1 workspace srv-2'));

      await tester.tap(_iconButton(l10n.mcpRemoveServer).first);
      await tester.pumpAndSettle();
      expect(find.text(l10n.mcpRemoveServerTitle('github')), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(CcDialog),
          matching: find.widgetWithText(CcButton, l10n.mcpRemoveServer),
        ),
      );
      await tester.pumpAndSettle();
      expect(control.calls, contains('delete ws-1 workspace srv-1'));
    });
  });

  group('your own servers', () {
    testWidgets('a member lists their own, with no approval to wait for', (
      tester,
    ) async {
      final control = await pump(
        tester,
        scope: McpServerScope.personal,
        role: WorkspaceRole.member,
        personal: [httpEntry(approved: false, userId: 'u-1')],
      );

      expect(find.text(l10n.mcpPersonalServers.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.mcpPersonalServersDescription), findsOneWidget);
      expect(find.text(l10n.mcpWorkspaceServersAdminsOnly), findsNothing);
      expect(find.text('linear'), findsOneWidget);
      // Nobody approves a member's own server: it stays public-only, and
      // nothing under the row asks for an approval.
      expect(find.text(l10n.mcpPublicAddressesOnly), findsOneWidget);
      expect(find.text(l10n.mcpApprovalRemoteMember), findsNothing);
      expect(find.widgetWithText(CcButton, l10n.mcpAddServer), findsOneWidget);
      expect(control.listCalls, {McpServerScope.personal: 1});

      await tester.tap(find.byType(CcSwitch));
      await tester.pumpAndSettle();
      expect(control.calls, contains('save ws-1 personal srv-2'));
    });

    testWidgets('an empty list invites adding one', (tester) async {
      await pump(
        tester,
        scope: McpServerScope.personal,
        role: WorkspaceRole.member,
      );

      expect(find.text(l10n.mcpPersonalServersEmpty), findsOneWidget);
      expect(
        find.text(l10n.mcpPersonalServersEmptyDescription),
        findsOneWidget,
      );
    });
  });

  testWidgets('a connecting server is read again until it settles, and no '
      'longer after', (tester) async {
    final servers = [httpEntry(lifecycle: 'connecting')];
    final control = await pump(
      tester,
      scope: McpServerScope.personal,
      personal: servers,
    );
    expect(find.text(l10n.mcpStatusConnecting), findsOneWidget);
    expect(control.listCalls[McpServerScope.personal], 1);

    servers[0] = httpEntry();
    await tester.pump(mcpServersSettleInterval);
    await tester.pumpAndSettle();
    expect(find.text(l10n.mcpStatusConnected), findsOneWidget);
    expect(control.listCalls[McpServerScope.personal], 2);

    await tester.pump(mcpServersSettleInterval * 3);
    expect(control.listCalls[McpServerScope.personal], 2);
  });

  testWidgets('a remote server waiting for a sign-in offers one', (
    tester,
  ) async {
    await pump(
      tester,
      scope: McpServerScope.personal,
      personal: [
        httpEntry(lifecycle: 'needs_auth'),
        httpEntry(
          id: 'srv-3',
          name: 'sentry',
          lifecycle: 'needs_auth',
          enabled: false,
        ),
      ],
    );

    expect(find.text(l10n.mcpStatusNeedsAuth), findsNWidgets(2));
    // Only the enabled one: a switched-off server is never dialled.
    expect(find.text(l10n.mcpServerSignInNeeded), findsOneWidget);
    expect(find.widgetWithText(CcButton, l10n.mcpServerSignIn), findsOneWidget);
  });

  testWidgets('lays out right to left', (tester) async {
    await pump(
      tester,
      owner: true,
      textDirection: TextDirection.rtl,
      workspace: [
        stdioEntry(),
        httpEntry(lifecycle: 'needs_auth'),
      ],
    );

    expect(tester.takeException(), isNull);
    final add = tester.getCenter(
      find.widgetWithText(CcButton, l10n.mcpAddServer),
    );
    final title = tester.getCenter(
      find.text(l10n.mcpWorkspaceServers.toUpperCase()),
    );
    // The section's action sits at the start edge's opposite: the left.
    expect(add.dx, lessThan(title.dx));
    // The notices hang from the row's start (right) side, their buttons at
    // the end (left).
    final note = tester.getTopRight(find.text(l10n.mcpApprovalStdioOwner));
    final approve = tester.getCenter(
      find.widgetWithText(CcButton, l10n.mcpApproveServer),
    );
    expect(approve.dx, lessThan(note.dx));
    final signInNote = tester.getTopRight(
      find.text(l10n.mcpServerSignInNeeded),
    );
    final signIn = tester.getCenter(
      find.widgetWithText(CcButton, l10n.mcpServerSignIn),
    );
    expect(signIn.dx, lessThan(signInNote.dx));
  });
}

Finder _iconButton(String tooltip) =>
    find.byWidgetPredicate((w) => w is CcIconButton && w.tooltip == tooltip);
