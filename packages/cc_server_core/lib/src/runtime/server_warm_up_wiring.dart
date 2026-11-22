part of '../cc_server_runtime.dart';

/// Work boot starts once the ready banner is up (or right before it, never
/// awaited): the speech native check, the code-server and Claude Code model
/// list warm-ups, and the on-device model installs. None of it holds the
/// banner; each [_AfterReady] entry waits its own delay past it.
void _scheduleWarmUps({
  required _AfterReady afterReady,
  required bool isDemo,
  required String dataDir,
  required bool hasMeetingTranscriber,
  required String? inferenceLibPath,
  required CodeServerService codeServerSessions,
  required ClaudeCodeModelCatalog claudeCodeModels,
  required ManagedModelControl embeddingModelControl,
  required ManagedModelControl diarizationModelControl,
  required SelectableVoiceModelControl voiceModelControl,
}) {
  // Says, loudly, in the server log the desktop pipes through, whether the
  // inference native loads in THIS pure-Dart process: the #1 cause of "audio
  // captured + WAV retained, but transcript empty" is the dylib failing to
  // resolve here (nothing bundles it into a pure-Dart binary; the desktop must
  // hand us its bundled-dylib dir via CC_NATIVE_LIB_DIR).
  // The check opens the library and stops there. It used to load the whole
  // recognizer and unload it again, which answered the same question by
  // reading several hundred MB of ASR weights on every boot, right while the
  // first client was connecting. The model itself loads when a recording
  // starts, while its first audio window buffers (capture is never lost —
  // audio queues), and a model that cannot load says so then.
  if (hasMeetingTranscriber) {
    afterReady.add(const Duration(seconds: 3), 'speech native check', () async {
      if (await inferenceLibraryLoads(explicitPath: inferenceLibPath)) {
        CcHostLog.info(
          'cc_server: speech native verified — meeting transcription enabled '
          '(the model loads when a recording starts)',
        );
        return;
      }
      CcHostLog.error(
        'cc_server: speech native FAILED to load — meeting transcripts will '
        'be EMPTY. The cc_inference dylib did not resolve in this process '
        '(looked at ${inferenceLibPath ?? '<unresolved>'}); ensure '
        '\$$nativeLibDirEnvVar points at a dir containing '
        '${platformLibraryFileName(inferenceLibraryBaseName)}, drop the dylib '
        'in $dataDir, or ship it beside the binary.',
      );
    });
  }

  // Download the pinned code-server standalone archive + the curated language
  // extensions OFF the ready path, so the embedded editor is warm by the time
  // a user opens a file — the first `codeServer.open` then only spawns an
  // already-installed binary instead of paying a multi-second download.
  // Best-effort + non-fatal on real servers. The public demo offers no editor
  // and must not download or extract the archive at boot.
  if (!isDemo) {
    afterReady.add(const Duration(seconds: 2), 'code-server warm-up', () async {
      CcHostLog.info(
        'cc_server: warming code-server (managed dir: '
        '${printableText(dataDir, max: 1024)}/code-server)',
      );
      await codeServerSessions.warmUp();
      CcHostLog.info('cc_server: code-server ready — embedded editor enabled');
    });
  }

  // Claude Code's model list, read off the ready path: a cold read drives
  // the CLI through every model (~10s), and the first picker open should not
  // be what waits for it. Read-only and token-free (see
  // [ClaudeCodeModelProbe]); a host without `claude` makes it a no-op. The
  // demo never spawns the CLI. Held a few seconds past the banner: the read
  // is a Node process at full tilt, and a picker opened before then starts
  // the same read itself.
  if (!isDemo) {
    afterReady.add(
      const Duration(seconds: 5),
      'Claude Code model list',
      claudeCodeModels.models,
    );
  }

  // On-device model warm-up (embedding + diarization + ASR) via the same
  // [ManagedModelControl]s as `models.*` RPC: no-op if on disk; clients see
  // live progress on `models.watch*`; failure → control `error` (retry next
  // boot / install button) without blocking ready.
  //
  // ASR is the SELECTED model (not hardcoded) — largest (~600 MB); its absence
  // disables `meeting.*` / `dictation.*` rather than degrading.
  // Speech needs one restart: transcriber resolves its model early in boot;
  // awaiting the download would blow the desktop's 20s ready-banner timeout.
  //
  // demo: SKIPPED — ~700 MB public downloads; meetings/dictation denied at the
  // op layer and seeded memory is FTS-only by design.
  if (!isDemo) {
    CcHostLog.info(
      'cc_server: ensuring on-device models (embedding + diarization + '
      'speech) under ${printableText(dataDir, max: 1024)}/models',
    );
    unawaited(embeddingModelControl.install());
    unawaited(diarizationModelControl.install());
    unawaited(voiceModelControl.install());
  }
}
