import 'dart:async';

import 'package:cc_data/cc_data.dart' show RemoteRigRepository, RigBackendView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/settings/rig_capabilities_section.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

class _SetupRepository extends RemoteRigRepository {
  _SetupRepository() : super(RemoteRpcClient(_StubChannel()));

  final started = Completer<void>();
  final finish = Completer<void>();
  RigBackendSetupAction? action;

  @override
  Future<void> installBackendSetup(RigBackendSetupAction next) async {
    action = next;
    started.complete();
    await finish.future;
  }
}

void main() {
  const ios = RigBackendView(
    backend: 'ios-simulator',
    label: 'iOS Simulator',
    available: false,
    surfaces: ['ios'],
    enforcedEgress: false,
    note: 'Install the automation bridge.',
    setupAction: RigBackendSetupAction.iosAutomation,
  );

  Widget app(_SetupRepository repository) => ProviderScope(
    overrides: [
      rigRepositoryProvider.overrideWithValue(repository),
      rigCapabilitiesProvider.overrideWith((ref) async => const [ios]),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData(
          tokens: DesignSystemTokens.light(),
          brightness: CcBrightness.light,
        ),
        child: const CcToastScope(
          child: Scaffold(
            body: SingleChildScrollView(child: CapabilitiesSection()),
          ),
        ),
      ),
    ),
  );

  testWidgets('iOS setup action installs the advertised pinned bridge', (
    tester,
  ) async {
    final repository = _SetupRepository();
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.text('iOS Simulator'), findsOneWidget);
    expect(find.text('ios'), findsOneWidget);
    expect(
      find.text(
        'Network is not enclosed on this backend — it manages its own connectivity.',
      ),
      findsOneWidget,
    );
    expect(find.text('Install iOS automation bridge'), findsOneWidget);

    await tester.tap(find.text('Install iOS automation bridge'));
    await tester.pump();
    await repository.started.future;
    expect(repository.action, RigBackendSetupAction.iosAutomation);

    repository.finish.complete();
    await tester.pumpAndSettle();
    expect(find.text('iOS automation bridge installed'), findsOneWidget);
  });

  testWidgets('an unavailable backend without setup metadata has no button', (
    tester,
  ) async {
    final repository = _SetupRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rigRepositoryProvider.overrideWithValue(repository),
          rigCapabilitiesProvider.overrideWith(
            (ref) async => const [
              RigBackendView(
                backend: 'android-emulator',
                label: 'Android emulator',
                available: false,
                surfaces: ['mobile'],
              ),
            ],
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData(
              tokens: DesignSystemTokens.light(),
              brightness: CcBrightness.light,
            ),
            child: const Scaffold(body: CapabilitiesSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Install iOS automation bridge'), findsNothing);
  });
}
