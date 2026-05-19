import 'package:cc_data/cc_data.dart' show RemoteRigRepository, RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/rigs_sections.dart';
import 'package:control_center/features/messaging/providers/space_browser_tabs_provider.dart';
import 'package:control_center/features/rigs/presentation/browser_engine_logo.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RigView _rig({
  String id = 'r-1',
  String surface = 'browser',
  RigBrowserEngine? engine,
  String phase = 'ready',
  String conversationId = 'c-1',
  bool isExec = false,
  String? slotId,
}) => RigView(
  id: id,
  surface: surface,
  backendLabel: 'smolvm',
  phase: phase,
  accelerated: true,
  conversationId: conversationId,
  isExec: isExec,
  browserEngine: engine,
  slotId: slotId,
);

/// A channel that carries nothing — the recording repository below never
/// reaches its client because only `destroy` is called, and that is recorded
/// locally.
class _StubChannel implements RemoteRpcChannelPort {
  @override
  Stream<Map<String, dynamic>> get incoming => const Stream.empty();
  @override
  Stream<RemoteChannelState> get state => const Stream.empty();
  @override
  bool get isOpen => false;
  @override
  Future<void> send(Map<String, dynamic> frame) async {}
  @override
  Future<void> close() async {}
}

/// Records `destroy` calls instead of dialing a server.
class _RecordingRigRepository extends RemoteRigRepository {
  _RecordingRigRepository() : super(RemoteRpcClient(_StubChannel()));

  final List<(String, String)> destroyed = [];

  @override
  Future<void> destroy(
    String workspaceId,
    String rigId, {
    String? reason,
  }) async {
    destroyed.add((workspaceId, rigId));
  }
}

void main() {
  Future<List<RigTabTarget>> pump(
    WidgetTester tester, {
    required List<RigView> rigs,
    required Widget Function(ValueChanged<RigTabTarget>) builder,
    RemoteRigRepository? rigRepository,
  }) async {
    final focused = <RigTabTarget>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rigSessionsProvider('ws-1').overrideWith((ref) => Stream.value(rigs)),
          if (rigRepository != null)
            rigRepositoryProvider.overrideWithValue(rigRepository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData(
              tokens: DesignSystemTokens.light(),
              brightness: CcBrightness.light,
            ),
            child: Scaffold(body: builder(focused.add)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return focused;
  }

  Widget browsers(ValueChanged<RigTabTarget> onFocusRig) => ListView(
    children: [
      BrowsersSection(
        spaceId: 'c-1',
        workspaceId: 'ws-1',
        onFocusRig: onFocusRig,
        onFocusBrowserTab: (_) {},
        onCloseBrowserTab: (_) {},
      ),
    ],
  );

  Widget computers(ValueChanged<RigTabTarget> onFocusRig) => ListView(
    children: [
      ComputersSection(
        spaceId: 'c-1',
        workspaceId: 'ws-1',
        onFocusRig: onFocusRig,
      ),
    ],
  );

  Widget phones(ValueChanged<RigTabTarget> onFocusRig) => ListView(
    children: [
      PhonesSection(
        spaceId: 'c-1',
        workspaceId: 'ws-1',
        onFocusRig: onFocusRig,
      ),
    ],
  );

  testWidgets('browsers section lists each engine with its logo', (
    tester,
  ) async {
    await pump(
      tester,
      rigs: [
        _rig(id: 'r-ff', engine: RigBrowserEngine.firefox),
        _rig(id: 'r-ch', engine: RigBrowserEngine.chromium),
      ],
      builder: browsers,
    );

    expect(find.text('Chromium'), findsOneWidget);
    expect(find.text('Firefox'), findsOneWidget);
    expect(find.byType(BrowserEngineLogo), findsNWidgets(2));
    // Stable engine order, not boot order: Chromium row comes first.
    final chromiumTop = tester.getTopLeft(find.text('Chromium')).dy;
    final firefoxTop = tester.getTopLeft(find.text('Firefox')).dy;
    expect(chromiumTop, lessThan(firefoxTop));
  });

  testWidgets('browsers section hides closed, foreign and non-browser rigs', (
    tester,
  ) async {
    await pump(
      tester,
      rigs: [
        _rig(id: 'r-closed', phase: 'closed'),
        _rig(id: 'r-foreign', conversationId: 'c-2'),
        _rig(id: 'r-desktop', surface: 'computer'),
      ],
      builder: browsers,
    );

    expect(find.byType(BrowserEngineLogo), findsNothing);
    expect(find.text('No browsers open'), findsOneWidget);
  });

  testWidgets('a booting browser says so in words, not just color', (
    tester,
  ) async {
    await pump(
      tester,
      rigs: [_rig(id: 'r-boot', phase: 'provisioning')],
      builder: browsers,
    );

    expect(find.text('Starting'), findsOneWidget);
  });

  testWidgets('tapping a browser row focuses that engine\'s tab', (
    tester,
  ) async {
    final focused = await pump(
      tester,
      rigs: [
        _rig(id: 'r-ch', engine: RigBrowserEngine.chromium),
        _rig(id: 'r-ff', engine: RigBrowserEngine.firefox),
      ],
      builder: browsers,
    );

    await tester.tap(find.text('Firefox'));
    expect(focused, hasLength(1));
    expect(focused.single.surface, RigTabSurfaces.browser);
    expect(focused.single.engine, RigBrowserEngine.firefox);
  });

  testWidgets('two machines of one engine are numbered and separately '
      'reachable', (tester) async {
    // A conversation can hold a second WebKit to compare two builds. Both rows
    // would otherwise read "WebKit", and tapping either would focus whichever
    // tab came first — leaving the other machine with no way back to it.
    final focused = await pump(
      tester,
      rigs: [
        _rig(id: 'r-wk2', engine: RigBrowserEngine.webkit, slotId: 's2'),
        _rig(id: 'r-wk', engine: RigBrowserEngine.webkit),
      ],
      builder: browsers,
    );

    expect(find.text('WebKit'), findsOneWidget);
    expect(find.text('WebKit 2'), findsOneWidget);
    // Ordered by slot, so the numbering reads top to bottom.
    expect(
      tester.getTopLeft(find.text('WebKit')).dy,
      lessThan(tester.getTopLeft(find.text('WebKit 2')).dy),
    );

    await tester.tap(find.text('WebKit 2'));
    expect(focused.single.engine, RigBrowserEngine.webkit);
    expect(focused.single.slotId, 's2');
  });

  /// Pumps the BROWSERS section with [browsers] host web-browser tabs beside
  /// [rigs] machines, recording focus/close calls. The mirrors are seeded via
  /// their own container (the provider is a plain read mirror the IDE layout
  /// writes through; no stream to stub).
  Future<(List<String> focused, List<String> closed)> pumpWithHostBrowsers(
    WidgetTester tester, {
    required List<BrowserTabMirror> browsers,
    List<RigView> rigs = const [],
  }) async {
    final focused = <String>[];
    final closed = <String>[];
    final container = ProviderContainer(
      overrides: [
        rigSessionsProvider('ws-1').overrideWith((ref) => Stream.value(rigs)),
      ],
    );
    addTearDown(container.dispose);
    if (browsers.isNotEmpty) {
      container.read(spaceBrowserTabsProvider('c-1').notifier).set(browsers);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData(
              tokens: DesignSystemTokens.light(),
              brightness: CcBrightness.light,
            ),
            child: Scaffold(
              body: ListView(
                children: [
                  BrowsersSection(
                    spaceId: 'c-1',
                    workspaceId: 'ws-1',
                    onFocusRig: (_) {},
                    onFocusBrowserTab: focused.add,
                    onCloseBrowserTab: closed.add,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (focused, closed);
  }

  testWidgets('host web browsers are listed above the VM machines', (
    tester,
  ) async {
    await pumpWithHostBrowsers(
      tester,
      browsers: const [
        BrowserTabMirror(tabId: 'bt-1', label: 'Web browser'),
        BrowserTabMirror(tabId: 'bt-2', label: 'Web browser 2'),
      ],
      rigs: [_rig(id: 'r-ch', engine: RigBrowserEngine.chromium)],
    );

    expect(find.text('Web browser'), findsOneWidget);
    expect(find.text('Web browser 2'), findsOneWidget);
    expect(find.text('Chromium'), findsOneWidget);
    // The host webviews sit above the VMs — the same order the `[+]` menu
    // offers them in.
    expect(
      tester.getTopLeft(find.text('Web browser')).dy,
      lessThan(tester.getTopLeft(find.text('Chromium')).dy),
    );
  });

  testWidgets('tapping a host browser row focuses its tab', (tester) async {
    final (focused, _) = await pumpWithHostBrowsers(
      tester,
      browsers: const [
        BrowserTabMirror(tabId: 'bt-1', label: 'Web browser'),
        BrowserTabMirror(tabId: 'bt-2', label: 'Web browser 2'),
      ],
    );

    await tester.tap(find.text('Web browser 2'));
    expect(focused, ['bt-2']);
  });

  testWidgets('a host browser row closes its tab with the hover ×', (
    tester,
  ) async {
    final (focused, closed) = await pumpWithHostBrowsers(
      tester,
      browsers: const [BrowserTabMirror(tabId: 'bt-1', label: 'Web browser')],
    );

    // At rest the row reads clean — the × is a hover affordance, unlike the
    // rig rows' standing power glyph.
    expect(find.byIcon(AppIcons.x), findsNothing);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Web browser')));
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.x), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.x));
    await tester.pumpAndSettle();
    expect(closed, ['bt-1']);
    // The × is a press of its own, not a part of the row: closing a tab must
    // not also jump the editor to it.
    expect(focused, isEmpty);
  });

  testWidgets('computers section lists desktops but never exec rigs', (
    tester,
  ) async {
    await pump(
      tester,
      rigs: [
        _rig(id: 'r-desk', surface: 'computer'),
        _rig(id: 'r-exec', surface: 'computer', isExec: true),
        _rig(id: 'r-web', surface: 'browser'),
      ],
      builder: computers,
    );

    expect(find.text('Computer'), findsOneWidget);
  });

  testWidgets('tapping a computer row focuses the computer tab', (
    tester,
  ) async {
    final focused = await pump(
      tester,
      rigs: [_rig(id: 'r-desk', surface: 'computer')],
      builder: computers,
    );

    await tester.tap(find.text('Computer'));
    expect(focused, hasLength(1));
    expect(focused.single.surface, RigTabSurfaces.computer);
    expect(focused.single.engine, isNull);
  });

  testWidgets('tapping the phone row opens its tab', (tester) async {
    // Closing a rig tab leaves the machine running, so this row is the way
    // back to a phone kept in the background — the phone surface has no other.
    final focused = await pump(
      tester,
      rigs: [_rig(id: 'r-phone', surface: 'mobile')],
      builder: phones,
    );

    await tester.tap(find.text('Mobile'));
    expect(focused, hasLength(1));
    expect(focused.single.surface, RigTabSurfaces.mobile);
    // Never numbered: the mobile surface drives the host's one attached
    // device, so there is no second phone to tell it apart from.
    expect(focused.single.slotId, isNull);
  });

  testWidgets('phones ignore the other surfaces', (tester) async {
    await pump(
      tester,
      rigs: [
        _rig(id: 'r-web', surface: 'browser'),
        _rig(id: 'r-desk', surface: 'computer'),
        _rig(id: 'r-closed', surface: 'mobile', phase: 'closed'),
      ],
      builder: phones,
    );
    expect(find.text('No phones open'), findsOneWidget);
  });

  testWidgets('empty computers render the empty row', (tester) async {
    await pump(tester, rigs: const [], builder: computers);
    expect(find.text('No computers open'), findsOneWidget);
  });

  testWidgets('a live machine\'s stop button destroys it without focusing '
      'its tab', (tester) async {
    final repo = _RecordingRigRepository();
    final focused = await pump(
      tester,
      rigs: [
        _rig(id: 'r-ch', engine: RigBrowserEngine.chromium),
        _rig(id: 'r-desk', surface: 'computer'),
      ],
      // Both sections carry live machines, so both rows carry the button;
      // tapping the computer's must address the computer's machine.
      builder: (onFocusRig) => ListView(
        children: [
          BrowsersSection(
            spaceId: 'c-1',
            workspaceId: 'ws-1',
            onFocusRig: onFocusRig,
            onFocusBrowserTab: (_) {},
            onCloseBrowserTab: (_) {},
          ),
          ComputersSection(
            spaceId: 'c-1',
            workspaceId: 'ws-1',
            onFocusRig: onFocusRig,
          ),
        ],
      ),
      rigRepository: repo,
    );

    expect(find.byIcon(AppIcons.power), findsNWidgets(2));
    await tester.tap(
      find.descendant(
        of: find.byType(ComputersSection),
        matching: find.byIcon(AppIcons.power),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.destroyed, [('ws-1', 'r-desk')]);
    // The button is a press of its own, not a part of the row: stopping a
    // machine must not also jump the editor to its tab.
    expect(focused, isEmpty);
  });

  testWidgets('a machine still booting can already be stopped', (tester) async {
    final repo = _RecordingRigRepository();
    await pump(
      tester,
      rigs: [_rig(id: 'r-boot', surface: 'computer', phase: 'provisioning')],
      builder: computers,
      rigRepository: repo,
    );

    expect(find.byIcon(AppIcons.power), findsOneWidget);
    await tester.tap(find.byIcon(AppIcons.power));
    await tester.pumpAndSettle();

    expect(repo.destroyed, [('ws-1', 'r-boot')]);
  });

  testWidgets('a closing or failed machine has nothing left to stop', (
    tester,
  ) async {
    await pump(
      tester,
      rigs: [_rig(id: 'r-x', surface: 'computer', phase: 'closing')],
      builder: computers,
    );
    expect(find.byIcon(AppIcons.power), findsNothing);

    await pump(
      tester,
      rigs: [_rig(id: 'r-x', surface: 'computer', phase: 'failed')],
      builder: computers,
    );
    expect(find.byIcon(AppIcons.power), findsNothing);
  });
}
