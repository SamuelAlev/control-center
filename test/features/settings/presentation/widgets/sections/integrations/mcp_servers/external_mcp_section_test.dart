import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/mcp/providers/mcp_external_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_hover_reveal.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/external_mcp_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_editor_dialog.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../../helpers/test_wrap.dart';

/// The owner's personal servers: hand-added ones open the editor and can be
/// removed; discovered ones belong to their tool.
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });
  tearDown(SettingsHoverReveal.debugForgetMouse);

  Future<_FakeClientControl> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final control = _FakeClientControl();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          canUseHostProvider.overrideWithValue(true),
          mcpClientControlProvider.overrideWithValue(control),
        ],
        child: testWrap(
          const SingleChildScrollView(child: ExternalMcpSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return control;
  }

  testWidgets('a hand-added server opens the editor; a discovered one does '
      'not', (tester) async {
    await pump(tester);

    expect(find.text('cursor'), findsOneWidget);
    expect(find.text(l10n.mcpHandAddedSource), findsOneWidget);
    // Only the hand-added server can be removed.
    expect(_iconButton(l10n.mcpRemoveServer), findsOneWidget);

    await tester.tap(find.text('filesystem'));
    await tester.pumpAndSettle();
    expect(find.byType(McpServerEditorDialog), findsNothing);

    await tester.tap(find.text('notes'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.mcpServerEditorEditTitle('notes')), findsOneWidget);
    expect(find.text('NOTES_KEY'), findsOneWidget);
  });

  testWidgets('removing a hand-added server deletes it by id', (tester) async {
    final control = await pump(tester);

    await tester.tap(_iconButton(l10n.mcpRemoveServer));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(CcDialog),
        matching: find.widgetWithText(CcButton, l10n.mcpRemoveServer),
      ),
    );
    await tester.pumpAndSettle();

    expect(control.deleted, ['p-1']);
  });
}

class _FakeClientControl implements McpClientControl {
  final deleted = <String>[];
  final saved = <McpServerDraft>[];
  final _at = DateTime.utc(2026, 11);

  @override
  Future<List<McpExternalServerInfo>> servers() async => [
    const McpExternalServerInfo(
      name: 'filesystem',
      transport: 'stdio',
      lifecycle: 'connected',
      auth: 'none',
      toolCount: 3,
      source: 'cursor',
    ),
    McpExternalServerInfo(
      name: 'notes',
      transport: 'stdio',
      lifecycle: 'connected',
      auth: 'none',
      toolCount: 2,
      source: McpExternalServerInfo.handAddedSource,
      definition: McpServerDefinition(
        id: 'p-1',
        name: 'notes',
        transport: McpServerTransport.stdio,
        command: 'notes-mcp',
        envNames: const ['NOTES_KEY'],
        createdAt: _at,
        updatedAt: _at,
      ),
    ),
  ];

  @override
  Future<ApprovalMode> approvalMode() async => ApprovalMode.alwaysAsk;

  @override
  Future<void> setApprovalMode(ApprovalMode mode) async {}

  @override
  Future<void> authorize(String serverName) async {}

  @override
  Future<void> reconnect(String serverName) async {}

  @override
  Future<McpServerDefinition> saveServer(McpServerDraft draft) async {
    saved.add(draft);
    throw UnimplementedError();
  }

  @override
  Future<void> deleteServer(String id) async => deleted.add(id);
}

Finder _iconButton(String tooltip) => find.byWidgetPredicate(
  (w) => w is CcIconButton && w.tooltip == tooltip,
);
