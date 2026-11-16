import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/mcp/providers/workspace_mcp_servers_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_hover_reveal.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/workspace_mcp_servers_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../../helpers/active_workspace.dart';
import '../../../../../../../helpers/test_wrap.dart';

/// Workspace MCP servers: admins manage them; a server that needs the host
/// waits on the server owner, who alone sees Approve.
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });
  tearDown(SettingsHoverReveal.debugForgetMouse);

  Future<_FakeControl> pump(
    WidgetTester tester, {
    bool owner = false,
    WorkspaceRole role = WorkspaceRole.admin,
    List<WorkspaceMcpServerEntry>? entries,
    bool unavailable = false,
    TextDirection? textDirection,
  }) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final control = _FakeControl(
      entries ?? [_stdioEntry(), _httpEntry()],
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
          const SingleChildScrollView(child: WorkspaceMcpServersSection()),
          textDirection: textDirection,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return control;
  }

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

    expect(find.widgetWithText(CcButton, l10n.mcpAddServer), findsOneWidget);
    // An admin who is not the owner never gets Approve.
    expect(find.widgetWithText(CcButton, l10n.mcpApproveServer), findsNothing);
  });

  testWidgets('the server owner approves an unapproved server', (tester) async {
    final control = await pump(
      tester,
      owner: true,
      entries: [
        _stdioEntry(),
        _httpEntry(approved: false, lifecycle: 'connected'),
      ],
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
    expect(control.listCalls, 2);
  });

  testWidgets('a member is told the list is the admins\'', (tester) async {
    final control = await pump(tester, role: WorkspaceRole.member);

    expect(find.text(l10n.mcpWorkspaceServersAdminsOnly), findsOneWidget);
    expect(find.text('github'), findsNothing);
    expect(find.widgetWithText(CcButton, l10n.mcpAddServer), findsNothing);
    expect(control.listCalls, 0);
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
    expect(control.calls, contains('delete ws-1 srv-1'));
  });

  testWidgets('lays out right to left', (tester) async {
    await pump(tester, owner: true, textDirection: TextDirection.rtl);

    expect(tester.takeException(), isNull);
    final add = tester.getCenter(
      find.widgetWithText(CcButton, l10n.mcpAddServer),
    );
    final title = tester.getCenter(find.text(l10n.mcpWorkspaceServers.toUpperCase()));
    // The section's action sits at the start edge's opposite: the left.
    expect(add.dx, lessThan(title.dx));
    // The approval line hangs from the row's start (right) side.
    final note = tester.getTopRight(find.text(l10n.mcpApprovalStdioOwner));
    final approve = tester.getCenter(
      find.widgetWithText(CcButton, l10n.mcpApproveServer),
    );
    expect(approve.dx, lessThan(note.dx));
  });
}

final _at = DateTime.utc(2026, 11, 2);

WorkspaceMcpServerEntry _stdioEntry() => WorkspaceMcpServerEntry(
  definition: McpServerDefinition(
    id: 'srv-1',
    workspaceId: 'ws-1',
    name: 'github',
    transport: McpServerTransport.stdio,
    command: 'npx',
    args: const ['-y', 'server-github'],
    envNames: const ['GITHUB_TOKEN'],
    createdAt: _at,
    updatedAt: _at,
  ),
  lifecycle: WorkspaceMcpServerEntry.awaitingApproval,
  hostApproved: false,
);

WorkspaceMcpServerEntry _httpEntry({
  bool approved = true,
  String lifecycle = 'connected',
}) => WorkspaceMcpServerEntry(
  definition: McpServerDefinition(
    id: 'srv-2',
    workspaceId: 'ws-1',
    name: 'linear',
    transport: McpServerTransport.http,
    url: 'https://mcp.example.com/mcp',
    headerNames: const ['Authorization'],
    hostApprovedBy: approved ? 'owner' : null,
    createdAt: _at,
    updatedAt: _at,
  ),
  lifecycle: lifecycle,
  hostApproved: approved,
  toolCount: 7,
);

class _FakeControl implements WorkspaceMcpServerControl {
  _FakeControl(this.entries, {this.unavailable = false});

  final List<WorkspaceMcpServerEntry> entries;
  final bool unavailable;
  final calls = <String>[];
  final saved = <McpServerDraft>[];
  int listCalls = 0;

  @override
  Future<List<WorkspaceMcpServerEntry>> list(String workspaceId) async {
    listCalls++;
    if (unavailable) {
      throw RemoteRpcException(RpcErrorCodes.opUnknown, 'unknown op');
    }
    return entries;
  }

  @override
  Future<WorkspaceMcpServerEntry> save(
    String workspaceId,
    McpServerDraft draft,
  ) async {
    saved.add(draft);
    return entries.firstWhere((e) => e.definition.id == draft.id);
  }

  @override
  Future<void> delete(String workspaceId, String id) async =>
      calls.add('delete $workspaceId $id');

  @override
  Future<WorkspaceMcpServerEntry> approve(String workspaceId, String id) async {
    calls.add('approve $workspaceId $id');
    return entries.firstWhere((e) => e.definition.id == id);
  }

  @override
  Future<void> reconnect(String workspaceId, String id) async =>
      calls.add('reconnect $workspaceId $id');
}

Finder _iconButton(String tooltip) => find.byWidgetPredicate(
  (w) => w is CcIconButton && w.tooltip == tooltip,
);
