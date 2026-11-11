// A rig follows its space. Someone with only a read grant on the space's
// repositories watches its machines but cannot start, drive or stop one;
// someone who cannot read the space sees no machine at all. The rig rows do
// not carry this, so the tab learns it from the first refusal by kind.
import 'dart:async';

import 'package:cc_data/cc_data.dart'
    show RemoteRigRepository, RigBackendView, RigView;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/rigs/presentation/rig_input_surface.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_pane.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_access_provider.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/active_workspace.dart';

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

class _RefusingRigRepository extends RemoteRigRepository {
  _RefusingRigRepository(this.refusal) : super(RemoteRpcClient(_StubChannel()));

  final Object refusal;
  int opens = 0;

  @override
  Future<
    ({String text, bool isError, String? imageBase64, String? imageMediaType})
  >
  act({
    required String workspaceId,
    required String rigId,
    required Map<String, dynamic> action,
  }) async =>
      (text: '', isError: false, imageBase64: null, imageMediaType: null);

  @override
  Future<RigView> open({
    required String workspaceId,
    required String surface,
    String? conversationId,
    String? engine,
    String? homeTheme,
    String? slotId,
  }) async {
    opens++;
    throw refusal;
  }
}

RemoteRpcException _grant(String level) => RemoteRpcException(
  RpcErrorCodes.unauthorized,
  'server words',
  {'kind': 'repo_grant_required', 'level': level},
);

const _space = (workspaceId: 'ws-1', spaceId: 'space-1');

final _holderRefusal = RemoteRpcException(
  RpcErrorCodes.unauthorized,
  'server words',
  {'kind': 'rig_holder_only'},
);

/// The desktop as a row that says, for this caller, whether they may drive
/// it and whether it carries somebody else's sign-ins.
RigView _desktopRow({required bool canDrive, bool holderOnly = false}) =>
    RigView(
      id: 'rig-1',
      surface: 'computer',
      backendLabel: 'QEMU',
      phase: 'ready',
      accelerated: true,
      conversationId: 'space-1',
      displayWidth: 1024,
      displayHeight: 768,
      canDrive: canDrive,
      holderOnly: holderOnly,
    );

const _holderHint =
    'You can watch this machine. It uses the sign-ins of the person it was '
    'opened for, so only they can drive it, forward its ports, paste into it '
    'or drop files on it.';

const _desktop = RigView(
  id: 'rig-1',
  surface: 'computer',
  backendLabel: 'QEMU',
  phase: 'ready',
  accelerated: true,
  conversationId: 'space-1',
  displayWidth: 1024,
  displayHeight: 768,
);

ProviderContainer _container({
  required RemoteRigRepository repository,
  List<RigView> rigs = const [],
  Stream<List<RigView>>? frames,
}) {
  final container = ProviderContainer(
    overrides: [
      activeWorkspaceIdOverride('ws-1'),
      isDemoServerProvider.overrideWith((ref) => false),
      mediaPlaybackAvailableProvider.overrideWithValue(false),
      rigRepositoryProvider.overrideWithValue(repository),
      rigSessionsProvider.overrideWith(
        (ref, _) => frames ?? Stream.value(rigs),
      ),
      rigCapabilitiesProvider.overrideWith(
        (ref) async => const [
          RigBackendView(
            backend: 'qemu',
            label: 'QEMU',
            available: true,
            surfaces: ['computer', 'browser'],
          ),
        ],
      ),
    ],
  );
  // Held open the way the tab on screen holds it, so the test can read it.
  container.listen(rigAccessProvider(_space), (_, _) {});
  return container;
}

Widget _app(
  ProviderContainer container, {
  TextDirection direction = TextDirection.ltr,
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Directionality(
      textDirection: direction,
      child: MediaProxyScope(
        config: MediaProxyConfig(
          httpBase: Uri.parse('https://cc.example.com:9030'),
          deviceId: 'test-device',
          psk: 'test-psk',
        ),
        child: CcTheme(
          data: CcThemeData.light(),
          child: const CcToastScope(
            child: Scaffold(
              body: SizedBox(
                width: 900,
                height: 700,
                // Hidden, so the frame lane holds still: the test is about
                // what the panel offers, not about streaming.
                child: RigTabPane(
                  surface: RigTabSurfaces.computer,
                  conversationId: 'space-1',
                  isVisible: false,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// Pumps past the panel's debounces. A live panel never settles: its
/// paused frame lane keeps a spinner turning until a first frame.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 700));
  }
}

void main() {
  testWidgets(
    'a start refused for want of write access disables Start and says why',
    (tester) async {
      final repository = _RefusingRigRepository(_grant('write'));
      final container = _container(repository: repository);
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start the machine'));
      await tester.pumpAndSettle();

      expect(repository.opens, 1);
      expect(
        find.text(
          'Starting a machine here needs write access to every repository in '
          'this space. A workspace admin can grant it.',
        ),
        findsOneWidget,
      );
      // The server's own sentence never shows.
      expect(find.textContaining('server words'), findsNothing);
      final start = tester.widget<CcButton>(
        find.ancestor(
          of: find.text('Start the machine'),
          matching: find.byType(CcButton),
        ),
      );
      expect(start.onPressed, isNull);
      expect(container.read(rigAccessProvider(_space)).access, RigAccess.watch);
    },
  );

  testWidgets(
    'a start refused for want of read access shows the space notice',
    (tester) async {
      final container = _container(
        repository: _RefusingRigRepository(_grant('read')),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start the machine'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "You don't have read access to a repository this space uses. A "
          'workspace admin can grant it.',
        ),
        findsOneWidget,
      );
      expect(find.text('Start the machine'), findsNothing);
    },
  );

  testWidgets('a viewing lane 403 leaves no machine to look at', (
    tester,
  ) async {
    final container = _container(
      repository: _RefusingRigRepository(_grant('write')),
      rigs: const [_desktop],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await _settle(tester);
    container
        .read(rigAccessProvider(_space).notifier)
        .noteLaneForbidden(drive: false);
    await _settle(tester);

    expect(
      find.text(
        "You can't view this machine. It belongs to a space you don't have "
        'read access to.',
      ),
      findsOneWidget,
    );
  });

  for (final direction in TextDirection.values) {
    testWidgets('a watch-only machine shows why and takes no input '
        '(${direction.name})', (tester) async {
      final container = _container(
        repository: _RefusingRigRepository(_grant('write')),
        rigs: const [_desktop],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, direction: direction));
      await _settle(tester);
      // Driving is the default until the server says otherwise.
      expect(find.text('Watch only'), findsNothing);
      expect(
        tester.widget<RigInputSurface>(find.byType(RigInputSurface)).enabled,
        isTrue,
      );
      expect(find.byIcon(AppIcons.power), findsOneWidget);

      container
          .read(rigAccessProvider(_space).notifier)
          .noteRefusal(_grant('write'));
      await _settle(tester);

      expect(find.text('Watch only'), findsOneWidget);
      expect(
        find.text(
          'You can watch this machine. Driving it, forwarding its ports, '
          'pasting into it or dropping files on it needs write access to '
          'every repository in this space.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<RigInputSurface>(find.byType(RigInputSurface)).enabled,
        isFalse,
      );
      // Stopping the machine and the microphone are driving too.
      expect(find.byIcon(AppIcons.power), findsNothing);
      expect(find.byIcon(AppIcons.micOff), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('somebody else\'s machine is watched, and says whose it is '
        '(${direction.name})', (tester) async {
      final container = _container(
        repository: _RefusingRigRepository(_holderRefusal),
        rigs: [_desktopRow(canDrive: false, holderOnly: true)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, direction: direction));
      await _settle(tester);

      // From the first frame, with no refusal needed.
      expect(find.text('Watch only'), findsOneWidget);
      expect(find.text(_holderHint), findsOneWidget);
      expect(
        tester.widget<RigInputSurface>(find.byType(RigInputSurface)).enabled,
        isFalse,
      );
      expect(find.byIcon(AppIcons.power), findsNothing);
      // The space itself is untouched: Start elsewhere in it still works.
      expect(container.read(rigAccessProvider(_space)).access, RigAccess.drive);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a holder refusal elsewhere in the space leaves this machine '
      'drivable', (tester) async {
    final container = _container(
      repository: _RefusingRigRepository(_holderRefusal),
      rigs: [_desktopRow(canDrive: true)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await _settle(tester);
    // Somebody else's machine in the same space refused a drive op, and one
    // of its drive lanes answered 403.
    final noted = container
        .read(rigAccessProvider(_space).notifier)
        .noteRefusal(_holderRefusal);
    await _settle(tester);

    expect(noted, isFalse);
    expect(container.read(rigAccessProvider(_space)).access, RigAccess.drive);
    expect(find.text('Watch only'), findsNothing);
    expect(
      tester.widget<RigInputSurface>(find.byType(RigInputSurface)).enabled,
      isTrue,
    );
  });

  testWidgets('a row that stops allowing driving turns the strip on', (
    tester,
  ) async {
    final frames = StreamController<List<RigView>>();
    addTearDown(frames.close);
    final container = _container(
      repository: _RefusingRigRepository(_grant('write')),
      frames: frames.stream,
    );
    addTearDown(container.dispose);

    frames.add([_desktopRow(canDrive: true)]);
    await tester.pumpWidget(_app(container));
    await _settle(tester);
    expect(find.text('Watch only'), findsNothing);

    // The server re-sends the row when the answer changes (a grant taken
    // away): no refusal comes first.
    frames.add([_desktopRow(canDrive: false)]);
    await _settle(tester);

    expect(find.text('Watch only'), findsOneWidget);
    expect(
      find.textContaining('needs write access to every repository'),
      findsOneWidget,
    );
    expect(
      tester.widget<RigInputSurface>(find.byType(RigInputSurface)).enabled,
      isFalse,
    );
  });

  testWidgets('a row that allows driving outranks the space\'s state', (
    tester,
  ) async {
    final container = _container(
      repository: _RefusingRigRepository(_grant('write')),
      rigs: [_desktopRow(canDrive: true)],
    );
    addTearDown(container.dispose);
    container
        .read(rigAccessProvider(_space).notifier)
        .noteRefusal(_grant('write'));

    await tester.pumpWidget(_app(container));
    await _settle(tester);

    expect(find.text('Watch only'), findsNothing);
    expect(
      tester.widget<RigInputSurface>(find.byType(RigInputSurface)).enabled,
      isTrue,
    );
  });
}
