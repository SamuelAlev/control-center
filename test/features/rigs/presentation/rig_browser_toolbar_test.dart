import 'package:cc_data/cc_data.dart'
    show RemoteRigRepository, RigBrowserStateView, RigView;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/features/rigs/presentation/rig_browser_toolbar.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
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
  _StubRepository({this.stateUrl = 'http://localhost:5173/'})
    : super(RemoteRpcClient(_StubChannel()));

  String stateUrl;

  @override
  Future<RigBrowserStateView> browserState(
    String workspaceId,
    String rigId,
  ) async =>
      RigBrowserStateView(url: stateUrl, canGoBack: false, canGoForward: false);
}

RigView _browserRig({String? currentUrl}) => RigView(
  id: 'browser-1',
  surface: 'browser',
  backendLabel: 'smolvm',
  phase: 'ready',
  accelerated: true,
  currentUrl: currentUrl,
  displayWidth: 1280,
  displayHeight: 666,
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    RigView rig,
    _StubRepository repository,
  ) async {
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [rigRepositoryProvider.overrideWithValue(repository)],
          child: RigBrowserToolbar(
            workspaceId: 'ws-1',
            rig: rig,
            onNetworkSecurity: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'chrome-error does not replace the failed URL in the address bar',
    (tester) async {
      final repository = _StubRepository();
      await pump(
        tester,
        _browserRig(currentUrl: 'http://localhost:5173/'),
        repository,
      );

      expect(find.text('http://localhost:5173/'), findsOneWidget);

      repository.stateUrl = 'chrome-error://chromewebdata/';
      await pump(
        tester,
        _browserRig(currentUrl: 'chrome-error://chromewebdata/'),
        repository,
      );
      await tester.pump();

      expect(find.text('http://localhost:5173/'), findsOneWidget);
      expect(find.text('chrome-error://chromewebdata/'), findsNothing);
    },
  );
}
