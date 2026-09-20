// Closing a rig tab has to ask what to do with the machine — including when
// that tab lives on a PR, which used to skip the prompt entirely.
import 'package:cc_data/cc_data.dart' show RemoteRigRepository, RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_close.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RigView _rig({
  String id = 'r-1',
  String surface = 'browser',
  RigBrowserEngine? engine = RigBrowserEngine.chromium,
  String phase = 'ready',
  String conversationId = 'space-1',
  String? slotId,
}) => RigView(
  id: id,
  surface: surface,
  backendLabel: 'smolvm',
  phase: phase,
  accelerated: true,
  conversationId: conversationId,
  browserEngine: engine,
  slotId: slotId,
);

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

class _Harness extends ConsumerWidget {
  const _Harness({
    required this.args,
    required this.onResult,
  });

  final Map<String, Object?> args;
  final void Function(bool result) onResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Same as a mounted rig tab: the sessions stream is already live when
    // someone hits ×. Reading it cold on the tap would still be in loading
    // and skip the prompt.
    ref.watch(rigSessionsProvider('ws-1'));
    return TextButton(
      onPressed: () async {
        final result = await confirmCloseLiveRigTab(
          context: context,
          ref: ref,
          title: 'Close Chromium?',
          workspaceId: 'ws-1',
          conversationId: 'space-1',
          args: args,
        );
        onResult(result);
      },
      child: const Text('close'),
    );
  }
}

void main() {
  const Map<String, Object?> chromiumArgs = {
    'surface': RigTabSurfaces.browser,
    'engine': 'chromium',
  };

  Future<void> pump(
    WidgetTester tester, {
    required List<RigView> rigs,
    required void Function(bool result) onResult,
    Map<String, Object?> args = chromiumArgs,
    _RecordingRigRepository? repo,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rigSessionsProvider('ws-1').overrideWith((ref) => Stream.value(rigs)),
          if (repo != null) rigRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: CcTheme(
            data: CcThemeData.light(),
            child: CcToastScope(
              child: Scaffold(body: _Harness(args: args, onResult: onResult)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an unstarted tab closes without asking', (tester) async {
    bool? result;
    await pump(tester, rigs: const [], onResult: (value) => result = value);
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(find.text('Close Chromium?'), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('a live browser rig asks keep running or shut down', (
    tester,
  ) async {
    await pump(tester, rigs: [_rig()], onResult: (_) {});
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(find.text('Close Chromium?'), findsOneWidget);
    expect(find.text('Keep running'), findsOneWidget);
    expect(find.text('Shut down'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('keep running closes the tab and leaves the machine', (
    tester,
  ) async {
    bool? result;
    final repo = _RecordingRigRepository();
    await pump(
      tester,
      rigs: [_rig()],
      repo: repo,
      onResult: (value) => result = value,
    );
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep running'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(repo.destroyed, isEmpty);
  });

  testWidgets('shut down closes the tab and destroys the machine', (
    tester,
  ) async {
    bool? result;
    final repo = _RecordingRigRepository();
    await pump(
      tester,
      rigs: [_rig()],
      repo: repo,
      onResult: (value) => result = value,
    );
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shut down'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(repo.destroyed, [('ws-1', 'r-1')]);
  });

  testWidgets('cancel leaves the tab and the machine', (tester) async {
    bool? result;
    final repo = _RecordingRigRepository();
    await pump(
      tester,
      rigs: [_rig()],
      repo: repo,
      onResult: (value) => result = value,
    );
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(repo.destroyed, isEmpty);
  });

  testWidgets('a still-booting machine is asked about too', (tester) async {
    // Provisioning is not "live" to the viewer, but the guest already exists.
    // Skipping the prompt here is how a closed tab used to leak a VM.
    await pump(
      tester,
      rigs: [_rig(phase: 'provisioning')],
      onResult: (_) {},
    );
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(find.text('Close Chromium?'), findsOneWidget);
  });

  testWidgets('a failed boot is dismissed without asking', (tester) async {
    bool? result;
    final repo = _RecordingRigRepository();
    await pump(
      tester,
      rigs: [_rig(phase: 'failed')],
      repo: repo,
      onResult: (value) => result = value,
    );
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(find.text('Close Chromium?'), findsNothing);
    expect(result, isTrue);
    expect(repo.destroyed, [('ws-1', 'r-1')]);
  });

  testWidgets('a Chromium tab does not shut down the Firefox machine', (
    tester,
  ) async {
    // The reason engine is in the lookup key: two browser tabs in one
    // conversation are two machines, and closing one must not speak for both.
    bool? result;
    await pump(
      tester,
      rigs: [_rig(engine: RigBrowserEngine.firefox)],
      onResult: (value) => result = value,
    );
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(find.text('Close Chromium?'), findsNothing);
    expect(result, isTrue);
  });
}
