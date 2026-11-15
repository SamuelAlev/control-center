import 'package:cc_domain/cc_domain.dart' show ServerOwnerRequiredException;
import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/mcp/providers/mcp_server_control_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_wrap.dart';

/// The MCP token always exists and is the owner's: shown, copied and rotated
/// by them only, and sent as an `Authorization: Bearer` header.
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  Future<_FakeControl> pump(
    WidgetTester tester, {
    required bool owner,
    bool refuseToken = false,
  }) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final control = _FakeControl(refuseToken: refuseToken);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isDemoServerProvider.overrideWithValue(false),
          isServerOwnerProvider.overrideWithValue(owner),
          mcpServerControlProvider.overrideWithValue(control),
        ],
        child: testWrap(const SingleChildScrollView(child: McpSection())),
      ),
    );
    await tester.pumpAndSettle();
    return control;
  }

  testWidgets('the owner reveals the token as a Bearer header', (tester) async {
    final control = await pump(tester, owner: true);

    expect(find.text('Authorization: Bearer tok-1'), findsNothing);
    expect(find.text(l10n.mcpTokenDescription), findsOneWidget);
    await tester.tap(find.widgetWithText(CcButton, l10n.mcpShowToken));
    await tester.pumpAndSettle();

    expect(control.calls, ['token']);
    expect(find.text('Authorization: Bearer tok-1'), findsOneWidget);
    expect(find.widgetWithText(CcButton, l10n.mcpHideToken), findsOneWidget);
    expect(find.textContaining('?token='), findsNothing);
  });

  testWidgets('rotating asks first, then shows the new token', (tester) async {
    final control = await pump(tester, owner: true);

    await tester.tap(find.widgetWithText(CcButton, l10n.mcpRotateToken));
    await tester.pumpAndSettle();
    expect(find.text(l10n.mcpRotateTokenTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(CcButton, l10n.cancel));
    await tester.pumpAndSettle();
    expect(control.calls, isEmpty);

    await tester.tap(find.widgetWithText(CcButton, l10n.mcpRotateToken));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(CcDialog),
        matching: find.widgetWithText(CcButton, l10n.mcpRotateToken),
      ),
    );
    await tester.pumpAndSettle();

    expect(control.calls, ['rotateToken']);
    expect(find.text('Authorization: Bearer tok-2'), findsOneWidget);
    expect(find.text(l10n.mcpTokenRotated), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('anyone else sees the endpoint is the owner\'s, not an error', (
    tester,
  ) async {
    await pump(tester, owner: false);

    expect(find.text(l10n.mcpOwnerOnlyTitle), findsOneWidget);
    expect(find.text(l10n.portLabel), findsOneWidget);
    expect(find.widgetWithText(CcButton, l10n.mcpShowToken), findsNothing);
    expect(find.widgetWithText(CcButton, l10n.mcpRotateToken), findsNothing);
    expect(find.widgetWithText(CcButton, l10n.stop), findsNothing);
    expect(find.text(l10n.startOnAppLaunch), findsNothing);
  });

  testWidgets('a refused token turns the card owner-only', (tester) async {
    await pump(tester, owner: true, refuseToken: true);

    await tester.tap(find.widgetWithText(CcButton, l10n.mcpShowToken));
    await tester.pumpAndSettle();

    expect(find.text(l10n.mcpOwnerOnlyTitle), findsOneWidget);
    expect(find.textContaining('server_owner_required'), findsNothing);
    expect(find.widgetWithText(CcButton, l10n.mcpShowToken), findsNothing);
  });
}

class _FakeControl implements McpServerControl {
  _FakeControl({required this.refuseToken});

  final bool refuseToken;
  final calls = <String>[];

  @override
  Future<McpServerStatus> status() async =>
      const McpServerStatus(running: true, port: 9030, enabled: true);

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setEnabled({required bool enabled}) async {}

  @override
  Future<String> token() async {
    calls.add('token');
    if (refuseToken) {
      throw const ServerOwnerRequiredException('server_owner_required');
    }
    return 'tok-1';
  }

  @override
  Future<String> rotateToken() async {
    calls.add('rotateToken');
    return 'tok-2';
  }
}
