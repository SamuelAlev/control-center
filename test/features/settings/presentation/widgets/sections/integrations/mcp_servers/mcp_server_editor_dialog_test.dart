import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_editor_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../../helpers/test_wrap.dart';

/// The shared editor: what it sends for a command server and a remote one,
/// with write-only values as set/remove by name.
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  Future<List<McpServerDraft>> open(
    WidgetTester tester, {
    McpServerDefinition? existing,
    bool owner = false,
    McpServerEditorScope scope = McpServerEditorScope.workspace,
    Object? refuseWith,
    TextDirection? textDirection,
  }) async {
    tester.view
      ..physicalSize = const Size(1200, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final drafts = <McpServerDraft>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [canUseHostProvider.overrideWithValue(owner)],
        child: testWrapWithToastOverlay(
          Builder(
            builder: (context) => CcButton(
              onPressed: () => showMcpServerEditor(
                context,
                scope: scope,
                existing: existing,
                onSave: (draft) async {
                  drafts.add(draft);
                  if (refuseWith != null) {
                    throw refuseWith;
                  }
                },
              ),
              child: const Text('open'),
            ),
          ),
          textDirection: textDirection,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return drafts;
  }

  Finder field(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(CcTextField)),
    matching: find.byType(EditableText),
  );

  Finder area(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(CcTextArea)),
    matching: find.byType(EditableText),
  );

  Finder inRow(String name, String button) => find.descendant(
    of: find.byKey(ValueKey('mcp-secret-$name')),
    matching: find.widgetWithText(CcButton, button),
  );

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(CcButton, l10n.save));
    await tester.pumpAndSettle();
  }

  testWidgets('editing a command server keeps, replaces, removes and adds', (
    tester,
  ) async {
    final at = DateTime.utc(2026, 11);
    final drafts = await open(
      tester,
      existing: McpServerDefinition(
        id: 'srv-1',
        workspaceId: 'ws-1',
        name: 'github',
        transport: McpServerTransport.stdio,
        command: 'npx',
        args: const ['-y', 'server-github'],
        envNames: const ['KEEP_ME', 'OLD_TOKEN', 'REPLACE_ME'],
        createdAt: at,
        updatedAt: at,
      ),
    );

    expect(find.text(l10n.mcpServerEditorEditTitle('github')), findsOneWidget);
    expect(find.text(l10n.mcpServerEditorStdioMember), findsOneWidget);
    // Stored names show, their values never do.
    expect(find.text('KEEP_ME'), findsOneWidget);

    await tester.tap(inRow('OLD_TOKEN', l10n.remove));
    await tester.pumpAndSettle();
    expect(find.text(l10n.mcpServerSecretRemovedOnSave), findsOneWidget);

    await tester.tap(inRow('REPLACE_ME', l10n.mcpServerSecretReplace));
    await tester.pumpAndSettle();
    await tester.enterText(field(l10n.mcpServerSecretNewValueHint), 'fresh');

    await tester.enterText(
      area(l10n.mcpServerArgsLabel),
      '-y\nserver-github@2',
    );

    await tester.tap(find.widgetWithText(CcButton, l10n.mcpServerEnvAdd));
    await tester.pumpAndSettle();
    await tester.enterText(field(l10n.mcpServerSecretValueHint), 'v1');
    await tester.enterText(field('API_TOKEN'), 'NEW_VAR');

    await save(tester);

    final draft = drafts.single;
    expect(draft.id, 'srv-1');
    expect(draft.name, 'github');
    expect(draft.transport, McpServerTransport.stdio);
    expect(draft.command, 'npx');
    expect(draft.args, ['-y', 'server-github@2']);
    expect(draft.url, isNull);
    expect(draft.envSet, {'REPLACE_ME': 'fresh', 'NEW_VAR': 'v1'});
    expect(draft.envRemove, {'OLD_TOKEN'});
    expect(draft.headerSet, isEmpty);
    expect(find.byType(McpServerEditorDialog), findsNothing);
  });

  testWidgets('adding a remote server sends its URL and headers', (
    tester,
  ) async {
    final drafts = await open(
      tester,
      owner: true,
      scope: McpServerEditorScope.personal,
    );

    expect(find.text(l10n.mcpServerEditorAddTitle), findsOneWidget);
    expect(find.text(l10n.mcpServerEditorPersonal), findsOneWidget);
    await tester.enterText(field(l10n.nameLabel), 'linear');
    await tester.tap(find.text(l10n.mcpServerTransportHttp));
    await tester.pumpAndSettle();
    await tester.enterText(
      field(l10n.mcpServerUrlLabel),
      'https://mcp.example.com/mcp',
    );
    await tester.tap(find.widgetWithText(CcButton, l10n.mcpServerHeaderAdd));
    await tester.pumpAndSettle();
    await tester.enterText(field(l10n.mcpServerSecretValueHint), 'Bearer t');
    await tester.enterText(field('Authorization'), 'Authorization');

    await save(tester);

    final draft = drafts.single;
    expect(draft.id, isNull);
    expect(draft.transport, McpServerTransport.http);
    expect(draft.url, 'https://mcp.example.com/mcp');
    expect(draft.command, isNull);
    expect(draft.args, isEmpty);
    expect(draft.headerSet, {'Authorization': 'Bearer t'});
    expect(draft.headerRemove, isEmpty);
    expect(draft.envSet, isEmpty);
  });

  testWidgets('nothing is sent while a field is invalid', (tester) async {
    final drafts = await open(tester);

    await tester.enterText(field(l10n.nameLabel), 'bad name');
    await save(tester);

    expect(drafts, isEmpty);
    expect(find.text(l10n.mcpServerNameInvalid), findsOneWidget);
    expect(find.text(l10n.mcpServerCommandRequired), findsOneWidget);
  });

  testWidgets('a refused name is worded under the field, by kind', (
    tester,
  ) async {
    final drafts = await open(
      tester,
      refuseWith: RemoteRpcException(
        RpcErrorCodes.invalidParams,
        'raw server words',
        {'kind': 'mcp_server.name_taken'},
      ),
    );

    await tester.enterText(field(l10n.nameLabel), 'github');
    await tester.enterText(field(l10n.mcpServerCommandLabel), 'npx');
    await save(tester);

    expect(drafts, hasLength(1));
    expect(find.text(l10n.mcpServerNameTaken), findsOneWidget);
    expect(find.text('raw server words'), findsNothing);
    expect(find.byType(McpServerEditorDialog), findsOneWidget);
  });

  testWidgets('lays out right to left', (tester) async {
    await open(tester, owner: true, textDirection: TextDirection.rtl);

    expect(tester.takeException(), isNull);
    final save = tester.getCenter(find.widgetWithText(CcButton, l10n.save));
    final cancel = tester.getCenter(find.widgetWithText(CcButton, l10n.cancel));
    expect(save.dx, lessThan(cancel.dx));
    expect(find.text(l10n.mcpServerEditorStdioOwner), findsOneWidget);
  });
}
