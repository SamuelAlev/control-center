import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/focus_mode/domain/focus_mode_state.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart' show CcIconButton;
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/observable_key_value_backend.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_actions.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_needs_you.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_spaces.dart';
import 'package:control_center/features/desktop_app/providers/tray_panel_providers.dart';
import 'package:control_center/features/desktop_app/providers/tray_status_providers.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../helpers/test_wrap.dart';

const _ws = 'ws-1';
final _now = DateTime.now();
final _l10n = AppLocalizationsLoader.lookupLoaded(const Locale('en'));

Space _space(String id, String name) => Space(
  id: id,
  name: name,
  workspaceId: _ws,
  createdAt: _now,
  updatedAt: _now,
);

Conversation _conversation(String id, String title, Duration ago) =>
    Conversation(
      id: id,
      workspaceId: _ws,
      spaceId: 's2',
      title: title,
      createdAt: _now.subtract(ago),
      updatedAt: _now.subtract(ago),
    );

final _spaces = [
  _space('s1', 'checkout-flow'),
  _space('s2', 'api-server rate limits'),
  _space('s3', 'docs refresh'),
  _space('s4', 'shop-ui dark mode'),
  _space('s5', 'billing export'),
  _space('s6', 'flaky e2e'),
  _space('s7', 'onboarding copy'),
  _space('s8', 'release notes'),
];

SubscriptionWindow _window(String label, double used) => SubscriptionWindow(
  id: label,
  label: label,
  usedFraction: used,
  resetsAt: _now.add(const Duration(hours: 2)),
);

class _Actions implements TrayPanelActions {
  final List<String> routes = [];
  final List<String> switches = [];

  @override
  void dismiss({bool returnFocus = false}) {}
  @override
  void openApp() {}
  @override
  void openRoute(String route) => routes.add(route);
  @override
  void openSettings() {}
  @override
  void quit() {}
  @override
  void switchWorkspace(String workspaceId) => switches.add(workspaceId);
}

class _Ws extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _ws;
}

final _focusing = FocusModeState(
  active: true,
  sessionStartedAt: _now.subtract(const Duration(minutes: 14)),
);

List<Override> _overrides({
  required TrayConnection connection,
  required List<SubscriptionUsage> usage,
  FocusModeState focus = const FocusModeState(active: false),
}) => [
  keyValueBackendProvider.overrideWithValue(
    ObservableKeyValueBackend(InMemoryStorage()),
  ),
  trayStatusProvider.overrideWithValue(
    TrayStatus(
      connection: connection,
      workspaceId: _ws,
      attention: const [
        TrayAttentionSpace(
          spaceId: 's1',
          name: 'checkout-flow',
          openQuestions: 2,
        ),
      ],
      approvals: 1,
      workingSpaces: 1,
    ),
  ),
  activeWorkspaceIdProvider.overrideWith(_Ws.new),
  workspacesProvider.overrideWith(
    (ref) => Stream.value([
      Workspace(
        id: _ws,
        name: 'Acme platform',
        createdAt: _now,
        updatedAt: _now,
      ),
      Workspace(
        id: 'ws-2',
        name: 'Side projects',
        createdAt: _now,
        updatedAt: _now,
      ),
    ]),
  ),
  activeWorkspaceDisplayProvider.overrideWithValue((
    name: 'Acme platform',
    workspaceId: _ws,
    hasLogo: false,
  )),
  workspaceVisibleSpacesProvider(_ws).overrideWithValue(_spaces),
  workspaceSpacesProvider(_ws).overrideWith((ref) => Stream.value(_spaces)),
  workspaceSpaceActivityProvider(_ws).overrideWith(
    (ref) => Stream.value({
      for (final (i, s) in _spaces.indexed)
        s.id: SpaceActivity(
          spaceId: s.id,
          lastMessageAt: _now.subtract(Duration(minutes: 5 * i + 1)),
          openQuestionCount: s.id == 's1' ? 2 : 0,
        ),
    }),
  ),
  spaceStatusProvider.overrideWith(
    (ref, id) => switch (id) {
      's1' => SpaceStatus.needsInput,
      's2' => SpaceStatus.running,
      _ => SpaceStatus.idle,
    },
  ),
  spaceUnreadProvider.overrideWith((ref, id) => id == 's2'),
  spaceConversationsProvider.overrideWith(
    (ref, id) => Stream.value(
      id == 's2'
          ? [
              _conversation('c1', 'Token bucket', const Duration(hours: 1)),
              _conversation('c2', 'Load test', const Duration(hours: 3)),
            ]
          : const <Conversation>[],
    ),
  ),
  spaceRunStartedAtProvider.overrideWith(
    (ref, id) => id == 's2'
        ? {'c1': _now.subtract(const Duration(minutes: 4))}
        : const <String, DateTime>{},
  ),
  conversationUnreadProvider.overrideWith(
    (ref, key) => key.conversationId == 'c2',
  ),
  conversationTitleGeneratingProvider.overrideWith((ref, key) => false),
  spacePullRequestsProvider.overrideWith((ref, id) => const []),
  spaceAllPrsMergedProvider.overrideWith((ref, id) => false),
  subscriptionUsageProvider.overrideWith(() => _Usage(usage)),
  focusModeProvider.overrideWith(() => _Focus(focus)),
];

class _Usage extends SubscriptionUsageNotifier {
  _Usage(this.reports);

  final List<SubscriptionUsage> reports;

  @override
  Future<List<SubscriptionUsage>> build() async => reports;

  @override
  Future<void> refresh({bool force = false}) async {}
}

class _Focus extends FocusModeNotifier {
  _Focus(this.initial);

  final FocusModeState initial;

  @override
  FocusModeState build() => initial;
}

final _claude = SubscriptionUsage(
  providerId: 'claude',
  displayName: 'Claude',
  status: SubscriptionStatus.ok,
  windows: [_window('5-hour', 0.42), _window('Weekly', 0.81)],
);

final _codex = SubscriptionUsage(
  providerId: 'codex',
  displayName: 'Codex',
  status: SubscriptionStatus.ok,
  windows: [_window('Daily', 0.1)],
);

/// Two Claude logins: the first signed out, the second reading.
final _claudeAccounts = [
  const SubscriptionUsage(
    providerId: 'claude',
    displayName: 'Claude',
    status: SubscriptionStatus.signInExpired,
    accountId: 'a1',
    accountLabel: 'me@acme.dev',
  ),
  SubscriptionUsage(
    providerId: 'claude',
    displayName: 'Claude',
    status: SubscriptionStatus.ok,
    accountId: 'a2',
    accountLabel: 'ops@acme.dev',
    windows: [_window('5-hour', 0.42)],
  ),
];

final _gemini = SubscriptionUsage(
  providerId: 'gemini',
  displayName: 'Gemini',
  status: SubscriptionStatus.ok,
  windows: [_window('Monthly', 0.3)],
);

/// Prepaid: money left, no window.
const _deepseek = SubscriptionUsage(
  providerId: 'deepseek',
  displayName: 'DeepSeek',
  status: SubscriptionStatus.ok,
  balances: [SubscriptionBalance(amountMinor: 1250, currency: 'USD')],
);

Future<_Actions> _pump(
  WidgetTester tester, {
  TrayConnection connection = TrayConnection.online,
  List<SubscriptionUsage>? usage,
  FocusModeState focus = const FocusModeState(active: false),
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final actions = _Actions();
  await tester.pumpWidget(
    testWrap(
      ProviderScope(
        overrides: _overrides(
          connection: connection,
          usage: usage ?? [_claude],
          focus: focus,
        ),
        child: TrayPanelScope(
          actions: actions,
          child: const Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(width: 360, height: 1300, child: TrayPanel()),
          ),
        ),
      ),
    ),
  );
  // Spinners never settle; a few frames resolve the streams.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return actions;
}

/// A [CcIconButton] by its tooltip (its own, not a Material Tooltip).
Finder _iconButton(String tooltip) =>
    find.byWidgetPredicate((w) => w is CcIconButton && w.tooltip == tooltip);

/// Opens the header's workspace menu, its list streamed in.
Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.text('Acme platform'));
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.text('Side projects'), findsOne);
}

Finder _in<T extends Widget>(Finder finder) =>
    find.descendant(of: find.byType(T), matching: finder);

void main() {
  group('online', () {
    testWidgets('a space waiting on the operator is listed once, under '
        '"Needs you"', (tester) async {
      await _pump(tester);
      expect(_in<TrayNeedsYouSection>(find.text('checkout-flow')), findsOne);
      expect(_in<TraySpacesSection>(find.text('checkout-flow')), findsNothing);
      expect(_in<TrayNeedsYouSection>(find.text('2')), findsOne);
      expect(find.text(_l10n.trayPanelApprovals), findsOne);
    });

    testWidgets('a working space lists its live conversations', (tester) async {
      await _pump(tester);
      expect(find.text('Token bucket'), findsOne);
      expect(find.text('Load test'), findsOne);
    });

    testWidgets('the spaces off the panel are one link away', (tester) async {
      final actions = await _pump(tester);
      await tester.tap(find.text(_l10n.trayPanelAllSpaces(_spaces.length)));
      expect(actions.routes, [spacesRoute(_ws)]);
    });
  });

  group('connection down', () {
    for (final connection in [
      TrayConnection.connecting,
      TrayConnection.offline,
    ]) {
      testWidgets('${connection.name}: no "Needs you", no live conversations, '
          'every space in the list', (tester) async {
        await _pump(tester, connection: connection);
        expect(find.text(_l10n.trayPanelNeedsYou), findsNothing);
        expect(_in<TraySpacesSection>(find.text('checkout-flow')), findsOne);
        expect(find.text('Token bucket'), findsNothing);
        expect(find.text('Load test'), findsNothing);
      });
    }
  });

  group('usage', () {
    testWidgets('up to two providers show every window', (tester) async {
      await _pump(tester, usage: [_claude, _codex]);
      expect(find.text('\u20685-hour\u2069'), findsOne);
      expect(find.text('\u2068Weekly\u2069'), findsOne);
      expect(find.text('\u2068Daily\u2069'), findsOne);
    });

    testWidgets('past two, each provider is one line', (tester) async {
      await _pump(tester, usage: [_claude, _codex, _gemini]);
      expect(find.text('Claude'), findsOne);
      expect(find.text('Gemini'), findsOne);
      // The window names move into tooltips.
      expect(find.text('\u20685-hour\u2069'), findsNothing);
      expect(find.text('\u2068Monthly\u2069'), findsNothing);
    });

    testWidgets('a prepaid provider shows the balance left, full and '
        'compact', (tester) async {
      await _pump(tester, usage: [_claude, _deepseek]);
      expect(find.text(_l10n.subscriptionUsageBalance), findsOne);
      expect(find.text(r'$12.50'), findsOne);
      expect(find.text(_l10n.subscriptionUsageNoneReported), findsNothing);

      await _pump(tester, usage: [_claude, _codex, _deepseek]);
      expect(find.text('DeepSeek'), findsOne);
      expect(find.text(r'$12.50'), findsOne);
      expect(find.text(_l10n.subscriptionUsageNoneReported), findsNothing);
    });

    testWidgets('a provider with several accounts pages through them, and '
        'the panel stays on the one paged to', (tester) async {
      await _pump(tester, usage: [..._claudeAccounts, _codex]);
      expect(find.text('1/2'), findsOne);
      expect(find.text('me@acme.dev'), findsOne);
      expect(find.text(_l10n.subscriptionUsageSignInExpired), findsOne);

      await tester.tap(
        find.bySemanticsLabel(_l10n.subscriptionUsageNextAccount),
      );
      await tester.pump();
      expect(find.text('2/2'), findsOne);
      expect(find.text('ops@acme.dev'), findsOne);
      expect(find.text('\u20685-hour\u2069'), findsOne);
      expect(find.text(_l10n.subscriptionUsageSignInExpired), findsNothing);

      // A reopened panel (a fresh tree, same session) shows it again.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TrayPanel)),
      );
      expect(container.read(trayUsageAccountProvider), {'claude': 'a2'});

      // Wraps around.
      await tester.tap(
        find.bySemanticsLabel(_l10n.subscriptionUsageNextAccount),
      );
      await tester.pump();
      expect(find.text('1/2'), findsOne);
    });

    testWidgets('a compact line pages too, and its note wraps rather than '
        'being cut', (tester) async {
      await _pump(tester, usage: [..._claudeAccounts, _codex, _gemini]);
      expect(find.text('1/2'), findsOne);
      final note = tester.widget<Text>(
        find.text(_l10n.subscriptionUsageSignInExpired),
      );
      expect(note.maxLines, 2);
      await tester.tap(
        find.bySemanticsLabel(_l10n.subscriptionUsageNextAccount),
      );
      await tester.pump();
      expect(find.text('2/2'), findsOne);
      expect(find.text(_l10n.subscriptionUsageSignInExpired), findsNothing);
    });

    testWidgets('a provider opens the accounts page', (tester) async {
      final actions = await _pump(tester);
      await tester.tap(find.text('Claude'));
      expect(actions.routes, [settingsAdaptersRoute(_ws)]);
    });
  });

  group('header', () {
    testWidgets('switches the workspace from its menu', (tester) async {
      final actions = await _pump(tester);
      await _openMenu(tester);
      expect(find.text('Side projects'), findsOne);
      expect(find.text(_l10n.manageWorkspaces), findsOne);

      await tester.tap(find.text('Side projects'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(actions.switches, ['ws-2']);
      expect(find.text('Side projects'), findsNothing);
    });

    testWidgets('choosing the active workspace only closes the menu', (
      tester,
    ) async {
      final actions = await _pump(tester);
      await _openMenu(tester);
      await tester.tap(find.text('Acme platform').last);
      await tester.pump(const Duration(milliseconds: 200));
      expect(actions.switches, isEmpty);
      expect(find.text('Side projects'), findsNothing);
    });

    testWidgets('manage workspaces opens the list in the app', (tester) async {
      final actions = await _pump(tester);
      await _openMenu(tester);
      await tester.tap(find.text(_l10n.manageWorkspaces));
      await tester.pump(const Duration(milliseconds: 200));
      expect(actions.routes, [workspaceListRoute]);
    });
  });

  group('footer', () {
    testWidgets('has no quit button: quitting is the native menu', (
      tester,
    ) async {
      await _pump(tester);
      expect(_iconButton(_l10n.trayPanelSettings), findsOne);
      expect(_iconButton(_l10n.focusModeStart), findsOne);
      expect(_iconButton(_l10n.trayMenuQuit), findsNothing);
    });

    testWidgets('a focus session shows its minutes left', (tester) async {
      await _pump(tester, focus: _focusing);
      expect(
        find.text(_l10n.focusModeRemaining(_focusing.minutesRemaining)),
        findsOne,
      );
      expect(_iconButton(_l10n.focusModeStart), findsNothing);
    });
  });
}
