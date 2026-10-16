import 'dart:async';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_model_control.dart';
import 'package:control_center/core/infrastructure/speech/diarization_model_control.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_control.dart';
import 'package:control_center/core/server/server_startup_status.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/popup_route_tracker.dart';
import 'package:control_center/shared/widgets/server_activity_overlay.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _installed = ModelStatusSnapshot(status: ModelLifecycleStatus.installed);
const _downloading = ModelStatusSnapshot(
  status: ModelLifecycleStatus.downloading,
  phase: 'downloading',
  progress: 0.42,
);

class _ModelControl implements ModelControl {
  ModelStatusSnapshot current = _installed;
  final updates = StreamController<ModelStatusSnapshot>.broadcast();
  Object? installError;

  void emit(ModelStatusSnapshot status) {
    current = status;
    updates.add(status);
  }

  @override
  Future<ModelStatusSnapshot> status() async => current;

  @override
  Stream<ModelStatusSnapshot> watch() => updates.stream;

  @override
  Future<void> install() async {
    if (installError case final error?) {
      throw error;
    }
    emit(_downloading);
  }

  @override
  Future<void> cancel() async => emit(
    const ModelStatusSnapshot(status: ModelLifecycleStatus.notInstalled),
  );

  @override
  Future<void> uninstall() => cancel();
}

void main() {
  late _ModelControl voice;
  late _ModelControl embedding;
  late _ModelControl diarization;
  late PopupRouteTracker popupRoutes;

  setUp(() {
    serverStartupStatus.value = null;
    voice = _ModelControl();
    embedding = _ModelControl();
    diarization = _ModelControl();
    popupRoutes = PopupRouteTracker();
  });

  tearDown(() async {
    serverStartupStatus.value = null;
    popupRoutes.dispose();
    await Future.wait([
      voice.updates.close(),
      embedding.updates.close(),
      diarization.updates.close(),
    ]);
  });

  Future<void> pumpActivity(
    WidgetTester tester, {
    Set<ServerActivityModel> hidden = const {},
    bool owner = true,
    bool docked = false,
    TextDirection direction = TextDirection.ltr,
    VoidCallback? onBackgroundTap,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rootPopupRoutesProvider.overrideWithValue(popupRoutes),
          voiceModelControlProvider.overrideWithValue(voice),
          embeddingModelControlProvider.overrideWithValue(embedding),
          diarizationModelControlProvider.overrideWithValue(diarization),
          voiceModelCatalogProvider.overrideWith(
            (ref) async => const ModelCatalog(
              selectedId: 'parakeet',
              models: [
                ModelChoice(id: 'parakeet', displayName: 'Parakeet TDT v3'),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          navigatorObservers: [popupRoutes],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: Directionality(
              textDirection: direction,
              child: Builder(
                builder: (context) {
                  final content = Align(
                    alignment: docked
                        ? AlignmentDirectional.bottomStart
                        : AlignmentDirectional.topStart,
                    child: CcButton(
                      onPressed: onBackgroundTap,
                      child: const Text('Underlying action'),
                    ),
                  );
                  final activity = ServerActivityOverlay(
                    hiddenModels: hidden,
                    canManageModels: owner,
                    docked: docked,
                  );
                  return docked
                      ? Column(
                          children: [
                            Expanded(child: content),
                            activity,
                          ],
                        )
                      : Stack(
                          children: [
                            content,
                            Positioned.fill(child: activity),
                          ],
                        );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tracks concurrent downloads and removes only completed work', (
    tester,
  ) async {
    voice.current = _downloading;
    embedding.current = _downloading;
    var taps = 0;
    await pumpActivity(tester, onBackgroundTap: () => taps++);
    expect(find.text('Parakeet TDT v3'), findsOneWidget);
    expect(find.byType(CcProgressBar), findsNWidgets(2));
    await tester.tap(find.text('Underlying action'));
    expect(
      taps,
      1,
      reason: 'Activity must not capture the rest of the viewport',
    );

    voice.emit(_installed);
    await tester.pumpAndSettle();
    expect(find.text('Parakeet TDT v3'), findsNothing);
    expect(find.byType(CcProgressBar), findsOneWidget);
    embedding.emit(_installed);
    await tester.pumpAndSettle();
    expect(find.text('Server activity'), findsNothing);
  });

  testWidgets(
    'inline onboarding hides only its own model until the step is left',
    (tester) async {
      voice.current = _downloading;
      diarization.current = _downloading;
      await pumpActivity(tester, hidden: {ServerActivityModel.voice});
      expect(find.text('Parakeet TDT v3'), findsNothing);
      expect(find.text('Diarization model'), findsOneWidget);

      await pumpActivity(tester);
      expect(find.text('Parakeet TDT v3'), findsOneWidget);
      expect(find.byType(CcProgressBar), findsNWidgets(2));
    },
  );

  testWidgets('keeps failure details, handles a rejected retry, and recovers', (
    tester,
  ) async {
    voice.current = const ModelStatusSnapshot(
      status: ModelLifecycleStatus.error,
      error: 'Download connection closed',
    );
    voice.installError = StateError('Server is offline');
    await pumpActivity(tester);
    expect(find.text('Download failed'), findsOneWidget);
    expect(find.text('Download connection closed'), findsNothing);
    await tester.tap(find.text('Technical details'));
    await tester.pumpAndSettle();
    expect(find.text('Download connection closed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Server is offline'), findsOneWidget);

    voice.installError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Download failed'), findsNothing);
    expect(find.byType(CcProgressBar), findsOneWidget);
    voice.emit(_installed);
    await tester.pumpAndSettle();
    expect(find.text('Server activity'), findsNothing);
  });

  testWidgets('does not offer server mutations to a non-owner', (tester) async {
    embedding.current = const ModelStatusSnapshot(
      status: ModelLifecycleStatus.error,
      error: 'Disk is full',
    );
    await pumpActivity(tester, owner: false);
    expect(find.text('Download failed'), findsOneWidget);
    expect(find.text('Technical details'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('new failure expands a collapsed panel in narrow RTL', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    voice.current = _downloading;
    await pumpActivity(tester, direction: TextDirection.rtl);
    await tester.tap(find.bySemanticsLabel('Collapse'));
    await tester.pumpAndSettle();
    expect(find.text('Parakeet TDT v3'), findsNothing);
    embedding.emit(
      const ModelStatusSnapshot(
        status: ModelLifecycleStatus.error,
        error: 'No space left on device',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Download failed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'activity stands down for a modal and restores retained failure',
    (tester) async {
      embedding.current = const ModelStatusSnapshot(
        status: ModelLifecycleStatus.error,
        error: 'No space left on device',
      );
      await pumpActivity(tester);
      final context = tester.element(find.text('Underlying action'));
      final dialog = showCcDialog<void>(
        context: context,
        builder: (context) => CcButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close settings'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Server activity'), findsNothing);
      await tester.tap(find.text('Close settings'));
      await tester.pumpAndSettle();
      await dialog;
      expect(find.text('Download failed'), findsOneWidget);
    },
  );

  testWidgets(
    'compact activity leaves pinned actions reachable after failure',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      voice.current = _downloading;
      var taps = 0;
      await pumpActivity(tester, docked: true, onBackgroundTap: () => taps++);
      embedding.emit(
        const ModelStatusSnapshot(
          status: ModelLifecycleStatus.error,
          error: 'No space left on device',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Download failed'), findsOneWidget);
      final action = tester.getRect(find.text('Underlying action'));
      final panel = tester.getRect(find.byType(CcCard));
      expect(action.bottom, lessThanOrEqualTo(panel.top));
      await tester.tap(find.text('Underlying action'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('connection failures do not repeat beside model activity', (
    tester,
  ) async {
    serverStartupStatus.value = const ServerStartupStatus(
      phase: ServerStartupPhase.failed,
      error: 'Connection refused',
    );
    voice.current = _downloading;
    embedding.current = const ModelStatusSnapshot(
      status: ModelLifecycleStatus.error,
      error: 'No space left on device',
    );
    await pumpActivity(tester);
    expect(find.text('Server could not start'), findsNothing);
    expect(find.text('Parakeet TDT v3'), findsOneWidget);
    expect(find.byType(CcProgressBar), findsOneWidget);
    expect(find.text('Download failed'), findsOneWidget);
    await tester.tap(find.text('Technical details'));
    await tester.pumpAndSettle();
    expect(find.text('No space left on device'), findsOneWidget);
    voice.emit(_installed);
    embedding.emit(_installed);
    await tester.pumpAndSettle();
    expect(find.text('Server activity'), findsNothing);
  });

  testWidgets('startup port failure survives before authentication', (
    tester,
  ) async {
    serverStartupStatus.value = const ServerStartupStatus(
      phase: ServerStartupPhase.failed,
      error: 'SocketException: Address already in use, port = 9030',
    );
    await tester.pumpWidget(
      CcTheme(
        data: CcThemeData.light(),
        child: WidgetsApp(
          color: const Color(0xFFFFFFFF),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              const ServerStartupIndicator(child: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('server port is already in use'),
      findsOneWidget,
    );
    await tester.tap(find.text('Technical details'));
    await tester.pumpAndSettle();
    expect(find.textContaining('port = 9030'), findsOneWidget);
    serverStartupStatus.value = const ServerStartupStatus(
      phase: ServerStartupPhase.ready,
    );
    await tester.pumpAndSettle();
    expect(find.text('Server activity'), findsNothing);
  });
}
