import 'dart:io';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_infra/src/speech/voice_model_manager.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:cc_server_core/src/models/selectable_voice_model_control.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late CcPaths paths;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_voice_model_test');
    paths = CcPaths(tmp.path);
  });

  tearDown(() {
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  test('catalog lists every installable model and defaults to the recommended '
      'pick', () async {
    final control = SelectableVoiceModelControl(paths: paths);
    addTearDown(control.dispose);

    final catalog = await control.catalog();

    expect(
      catalog.models.map((m) => m.id),
      VoiceModelInfo.all.map((m) => m.id),
      reason: 'the catalog mirrors the full registry, in picker order',
    );
    expect(catalog.selectedId, VoiceModelInfo.defaultId);
  });

  test('honors the persisted initial selection', () async {
    final control = SelectableVoiceModelControl(
      paths: paths,
      initialId: VoiceModelInfo.whisperBaseEn.id,
    );
    addTearDown(control.dispose);

    expect((await control.catalog()).selectedId, VoiceModelInfo.whisperBaseEn.id);
  });

  test('select switches the active model and persists the choice', () async {
    final persisted = <String>[];
    final control = SelectableVoiceModelControl(
      paths: paths,
      persistSelection: persisted.add,
    );
    addTearDown(control.dispose);

    await control.select(VoiceModelInfo.whisperLargeV3Turbo.id);

    expect(control.selectedId, VoiceModelInfo.whisperLargeV3Turbo.id);
    expect(persisted, [VoiceModelInfo.whisperLargeV3Turbo.id]);
    expect(
      (await control.catalog()).selectedId,
      VoiceModelInfo.whisperLargeV3Turbo.id,
    );
  });

  test('selecting the already-active model is a no-op (no re-persist)', () async {
    final persisted = <String>[];
    final control = SelectableVoiceModelControl(
      paths: paths,
      initialId: VoiceModelInfo.parakeetTdtV3.id,
      persistSelection: persisted.add,
    );
    addTearDown(control.dispose);

    await control.select(VoiceModelInfo.parakeetTdtV3.id);

    expect(persisted, isEmpty);
    expect(control.selectedId, VoiceModelInfo.parakeetTdtV3.id);
  });

  test('watch reports notInstalled (nothing on disk) and re-emits after a '
      'model switch', () async {
    final control = SelectableVoiceModelControl(paths: paths);
    addTearDown(control.dispose);

    final seen = <ModelLifecycleStatus>[];
    final sub = control.watch().listen((s) => seen.add(s.status));

    // Let the initial disk probe resolve to notInstalled.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // Switching to a different model rebuilds the inner control; the long-lived
    // broadcast must keep the subscriber's stream alive and push the new
    // model's freshly-probed status.
    await control.select(VoiceModelInfo.whisperBaseEn.id);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    expect(seen, contains(ModelLifecycleStatus.notInstalled));
    expect(
      seen.length,
      greaterThanOrEqualTo(2),
      reason: 'the stream survives a model switch and re-emits',
    );
  });
}
