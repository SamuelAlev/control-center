import 'dart:async';

import 'package:cc_data/cc_data.dart'
    show RemoteRigRepository, RigBrowserStateView, RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/browser_permission.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_browser_permission_flyout.dart';
import 'package:control_center/features/rigs/presentation/rig_browser_toolbar.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

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

class _StubRepository extends RemoteRigRepository {
  _StubRepository() : super(RemoteRpcClient(_StubChannel()));

  RigBrowserStateView state = _state();
  final requests = <({String workspaceId, String rigId})>[];
  final actions = <Map<String, dynamic>>[];
  final _held = <Completer<RigBrowserStateView>>[];
  int inFlight = 0;
  int maxInFlight = 0;

  Completer<RigBrowserStateView> holdNext() {
    final held = Completer<RigBrowserStateView>();
    _held.add(held);
    return held;
  }

  @override
  Future<RigBrowserStateView> browserState(
    String workspaceId,
    String rigId,
  ) async {
    requests.add((workspaceId: workspaceId, rigId: rigId));
    inFlight++;
    if (inFlight > maxInFlight) {
      maxInFlight = inFlight;
    }
    try {
      return _held.isEmpty ? state : await _held.removeAt(0).future;
    } finally {
      inFlight--;
    }
  }

  @override
  Future<
    ({String text, bool isError, String? imageBase64, String? imageMediaType})
  >
  act({
    required String workspaceId,
    required String rigId,
    required Map<String, dynamic> action,
  }) async {
    actions.add({...action, 'workspace_id': workspaceId, 'rig_id': rigId});
    return (text: '', isError: false, imageBase64: null, imageMediaType: null);
  }
}

RigBrowserStateView _state({
  String url = 'http://localhost:5173/',
  bool back = false,
  bool forward = false,
  bool loading = false,
  List<BrowserPermissionEntry> permissions = const [],
}) => RigBrowserStateView(
  url: url,
  canGoBack: back,
  canGoForward: forward,
  loading: loading,
  permissions: permissions,
);

RigView _browserRig({String id = 'browser-1', String? currentUrl}) => RigView(
  id: id,
  surface: 'browser',
  backendLabel: 'smolvm',
  phase: 'ready',
  accelerated: true,
  currentUrl: currentUrl,
  displayWidth: 1280,
  displayHeight: 666,
);

void main() {
  Future<void> pumpToolbar(
    WidgetTester tester,
    _StubRepository repository, {
    RigView? rig,
    String workspaceId = 'ws-1',
    bool visible = true,
    bool ticking = true,
  }) async {
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [rigRepositoryProvider.overrideWithValue(repository)],
          child: Visibility(
            visible: visible,
            maintainState: true,
            child: TickerMode(
              enabled: ticking,
              child: RigBrowserToolbar(
                workspaceId: workspaceId,
                rig: rig ?? _browserRig(currentUrl: 'http://localhost:5173/'),
                onNetworkSecurity: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('chrome-error does not replace the failed URL', (tester) async {
    final repository = _StubRepository();
    await pumpToolbar(tester, repository);
    expect(find.text('http://localhost:5173/'), findsOneWidget);

    repository.state = _state(url: 'chrome-error://chromewebdata/');
    await pumpToolbar(
      tester,
      repository,
      rig: _browserRig(currentUrl: 'chrome-error://chromewebdata/'),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('http://localhost:5173/'), findsOneWidget);
    expect(find.text('chrome-error://chromewebdata/'), findsNothing);
  });

  testWidgets(
    'hidden and muted tabs stop requests; reveal refreshes immediately',
    (tester) async {
      final repository = _StubRepository();
      await pumpToolbar(tester, repository);
      expect(repository.requests, hasLength(1));
      await pumpToolbar(tester, repository, visible: false);
      final hiddenCount = repository.requests.length;
      await tester.pump(const Duration(seconds: 3));
      expect(repository.requests, hasLength(hiddenCount));

      repository.state = _state(back: true);
      await pumpToolbar(tester, repository);
      expect(repository.requests, hasLength(hiddenCount + 1));
      expect(
        tester.widget<CcIconButton>(find.byType(CcIconButton).first).onPressed,
        isNotNull,
      );

      await pumpToolbar(tester, repository, ticking: false);
      final mutedCount = repository.requests.length;
      await tester.pump(const Duration(seconds: 3));
      expect(repository.requests, hasLength(mutedCount));
      await pumpToolbar(tester, repository);
      expect(repository.requests, hasLength(mutedCount + 1));
    },
  );

  testWidgets('nonresumed lifecycle stops requests until resumed', (
    tester,
  ) async {
    final repository = _StubRepository();
    await pumpToolbar(tester, repository);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final count = repository.requests.length;
    await tester.pump(const Duration(seconds: 3));
    expect(repository.requests, hasLength(count));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.requests, hasLength(count + 1));
  });

  testWidgets('slow reads are single flight and actions coalesce a follow-up', (
    tester,
  ) async {
    final repository = _StubRepository();
    final slow = repository.holdNext();
    final followUp = repository.holdNext();
    await pumpToolbar(tester, repository);
    await tester.pump(const Duration(seconds: 2));
    expect(repository.requests, hasLength(1));
    expect(repository.maxInFlight, 1);

    await tester.tap(find.byType(CcIconButton).at(2)); // Reload.
    await tester.pump();
    expect(repository.actions.single['action'], 'reload');
    expect(repository.requests, hasLength(1));
    slow.complete(_state(url: 'http://old.example/'));
    await tester.pump();
    expect(repository.requests, hasLength(2));
    expect(repository.maxInFlight, 1);
    followUp.complete(_state(back: true, forward: true, loading: true));
    await tester.pump();
    expect(
      tester.widget<CcIconButton>(find.byType(CcIconButton).first).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<CcIconButton>(find.byType(CcIconButton).at(1)).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<CcIconButton>(find.byType(CcIconButton).at(2)).tooltip,
      isNot('Reload'),
    );
    await tester.pump(const Duration(milliseconds: 399));
    expect(repository.requests, hasLength(2));
    await tester.pump(const Duration(milliseconds: 1));
    expect(repository.requests, hasLength(3));
  });

  testWidgets('former rig result cannot overwrite new rig, including URL', (
    tester,
  ) async {
    final repository = _StubRepository();
    final former = repository.holdNext();
    final latest = repository.holdNext();
    await pumpToolbar(tester, repository);
    await pumpToolbar(
      tester,
      repository,
      workspaceId: 'ws-2',
      rig: _browserRig(id: 'browser-2', currentUrl: 'http://new.example/'),
    );
    expect(repository.requests, hasLength(1));
    former.complete(_state(url: 'http://stale.example/', back: true));
    await tester.pump();
    expect(find.text('http://stale.example/'), findsNothing);
    expect(find.text('http://new.example/'), findsOneWidget);
    expect(
      tester.widget<CcIconButton>(find.byType(CcIconButton).first).onPressed,
      isNull,
    );
    expect(repository.requests.last, (workspaceId: 'ws-2', rigId: 'browser-2'));
    expect(repository.maxInFlight, 1);
    latest.complete(_state(url: 'http://fresh.example/', forward: true));
    await tester.pump();
    // The async response updates the model first; render its enabled controls.
    await tester.pump();
    expect(find.text('http://fresh.example/'), findsOneWidget);
    expect(
      tester.widget<CcIconButton>(find.byType(CcIconButton).at(1)).onPressed,
      isNotNull,
    );
  });

  testWidgets('back forward stop and address submission remain operable', (
    tester,
  ) async {
    final repository = _StubRepository();
    repository.state = _state(back: true, forward: true, loading: true);
    await pumpToolbar(tester, repository);
    await tester.tap(find.byType(CcIconButton).first);
    await tester.pump();
    expect(repository.actions.last['delta'], -1);
    await tester.tap(find.byType(CcIconButton).at(1));
    await tester.pump();
    expect(repository.actions.last['delta'], 1);
    await tester.tap(find.byType(CcIconButton).at(2));
    await tester.pump();
    expect(repository.actions.last['action'], 'stop_loading');
    await tester.enterText(find.byType(CcTextField), 'example.com');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(repository.actions.last['action'], 'navigate');
    expect(repository.actions.last['url'], 'https://example.com');
  });

  testWidgets('in-flight response while hidden is ignored and reveal rereads', (
    tester,
  ) async {
    final repository = _StubRepository();
    final former = repository.holdNext();
    await pumpToolbar(tester, repository);
    await pumpToolbar(tester, repository, visible: false);
    former.complete(_state(url: 'http://hidden.example/', back: true));
    await tester.pump(const Duration(seconds: 2));
    expect(repository.requests, hasLength(1));
    repository.state = _state(url: 'http://visible.example/');
    await pumpToolbar(tester, repository);
    expect(repository.requests, hasLength(2));
    expect(find.text('http://visible.example/'), findsOneWidget);
    expect(find.text('http://hidden.example/'), findsNothing);
  });

  testWidgets('disposing during a read does not schedule another request', (
    tester,
  ) async {
    final repository = _StubRepository();
    final slow = repository.holdNext();
    await pumpToolbar(tester, repository);
    await tester.pumpWidget(const SizedBox());
    slow.complete(_state());
    await tester.pump(const Duration(seconds: 2));
    expect(repository.requests, hasLength(1));
  });

  testWidgets(
    'equal permission content does not rebuild; focused URL stays draft',
    (tester) async {
      final repository = _StubRepository();
      const permission = BrowserPermissionEntry(
        id: 'request-1',
        origin: 'https://example.com',
        kind: BrowserPermissionKind.notifications,
        decision: BrowserPermissionDecision.granted,
      );
      repository.state = _state(permissions: [permission]);
      await pumpToolbar(tester, repository);
      final flyout = tester.widget<RigBrowserPermissionFlyout>(
        find.byType(RigBrowserPermissionFlyout),
      );
      repository.state = _state(permissions: [permission]);
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        identical(
          flyout,
          tester.widget<RigBrowserPermissionFlyout>(
            find.byType(RigBrowserPermissionFlyout),
          ),
        ),
        isTrue,
      );

      await tester.enterText(find.byType(CcTextField), 'draft.example');
      repository.state = _state(
        url: 'http://pushed.example/',
        permissions: [
          permission.withDecision(BrowserPermissionDecision.denied),
        ],
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('draft.example'), findsOneWidget);
      final updatedFlyout = tester.widget<RigBrowserPermissionFlyout>(
        find.byType(RigBrowserPermissionFlyout),
      );
      expect(identical(flyout, updatedFlyout), isFalse);
      expect(
        updatedFlyout.permissions.single.decision,
        BrowserPermissionDecision.denied,
      );
      updatedFlyout.onRespond('request-1', allow: true);
      await tester.pump();
      expect(repository.actions.last['action'], 'permission_respond');
      expect(repository.actions.last['request_id'], 'request-1');
      expect(repository.actions.last['allow'], isTrue);
    },
  );
}
