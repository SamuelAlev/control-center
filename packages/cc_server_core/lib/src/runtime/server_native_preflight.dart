import 'dart:io';

import 'package:cc_domain/core/domain/ports/media_render_port.dart'
    show MediaRenderException;
import 'package:cc_infra/cc_infra.dart'
    show
        BundledCodeRunner,
        BundledMediaTools,
        CodeRunnerNotFoundException,
        createHttpClient;
import 'package:cc_natives/cc_natives.dart'
    show
        CcSaml,
        CcWindow,
        GrammarManager,
        NativeDirectoryWatcher,
        Pty,
        kLanguageByExtension,
        nativeLibraryCandidates,
        inferenceLibraryBaseName,
        platformLibraryFileName,
        ptyLibraryBaseName,
        resolveRhttpLibraryPath,
        rhttpLibraryBaseName,
        samlLibraryBaseName,
        tryOpenFirst,
        watcherLibraryBaseName,
        windowLibraryBaseName,
        configureRigNatives,
        initializeRhttp,
        nativeLibDirEnvVar,
        ptyLibraryEnvVar,
        resolveInferenceLibraryPath,
        samlLibraryEnvVar,
        watcherLibraryEnvVar;
import 'package:cc_server_core/src/native_preflight.dart';
import 'package:cc_server_core/src/server_boot_refusal.dart';
import 'package:path/path.dart' as p;

/// Points the native loaders that resolve lazily (terminals, file watching,
/// SAML, desktop app windows) at [dataDir], beside the bundle and
/// `CC_NATIVE_LIB_DIR`, the same places the preflight looks.
void configureServerNativeLoaders(String dataDir) {
  // libccpty, libcc_watcher and libcc_saml are loose runtime dylibs that no
  // plugin bundles into this pure-Dart binary; their default resolvers check
  // only their own variable and the bundle layout, so a dev or headless
  // deploy that drops them in the data dir would otherwise not find them.
  Pty.libraryResolver = () => tryOpenFirst(
    nativeLibraryCandidates(
      ptyLibraryBaseName,
      appSupportRoot: dataDir,
      envVar: ptyLibraryEnvVar,
    ),
  );
  // Required, with no `package:watcher` fallback: its full-tree scan is the
  // startup freeze this native exists to remove.
  NativeDirectoryWatcher.libraryResolver = () => tryOpenFirst(
    nativeLibraryCandidates(
      watcherLibraryBaseName,
      appSupportRoot: dataDir,
      envVar: watcherLibraryEnvVar,
    ),
  );
  // Required with no degraded mode: a hand-rolled Dart XML-DSig is exactly
  // where signature-wrapping vulnerabilities live.
  CcSaml.libraryResolver = () => tryOpenFirst(
    nativeLibraryCandidates(
      samlLibraryBaseName,
      appSupportRoot: dataDir,
      envVar: samlLibraryEnvVar,
    ),
  );
  // Desktop app windows: candidates rather than an opened library, since the
  // calls block in the OS and each runs on a worker isolate.
  configureRigNatives(dataDir: dataDir);
}

/// Refuses the boot ([NativeLibrariesMissing]) when a required native is
/// missing, before anything opens, creates or migrates a database or writes
/// in [dataDir]: a broken install never touches the owner's data. The serve
/// path and every subcommand that opens a database call it first.
///
/// It loads the HTTP transport (idempotent), which the grammar check needs;
/// without that library the grammars cannot be checked and are not listed.
Future<void> refuseMissingNatives(String dataDir) async {
  configureServerNativeLoaders(dataDir);
  final grammarsRoot = p.join(dataDir, 'grammars');
  final httpReady = resolveRhttpLibraryPath(appSupportRoot: dataDir) != null;
  if (httpReady) {
    await initializeRhttp(appSupportRoot: dataDir);
  }
  final missing = await missingRequiredNatives(
    buildNativeRequirements(
      grammarsRoot: grammarsRoot,
      dataDir: dataDir,
      inferenceLibPath: resolveInferenceLibraryPath(appSupportRoot: dataDir),
      // Looked up without creating the grammars directory.
      grammarManager: httpReady
          ? GrammarManager(
              httpClient: createHttpClient(),
              grammarsDir: () async => Directory(grammarsRoot),
            )
          : null,
    ),
  );
  if (missing.isNotEmpty) {
    throw NativeLibrariesMissing(
      missing,
      searched: ['\$$nativeLibDirEnvVar', dataDir, grammarsRoot],
    );
  }
}

/// Builds the boot-time native-library requirement table.
///
/// The natives ship INSIDE the server bundle (`apps/cc_server/hook/build.dart`
/// emits them as DynamicLoadingBundled code assets into `<bundle>/lib/`), so a
/// miss here is a broken install — refuse to boot rather than run with
/// keyword-only search, dead terminals, an empty code graph, or worktrees that
/// silently stopped being copy-on-write. Only the on-device MODELS are
/// downloaded at runtime; every LIBRARY is required.
///
/// Declared as a table (see `native_preflight.dart`) rather than inline
/// `Platform.isWindows` branches, because the same matrix is re-stated in
/// `scripts/release/verify_natives.sh` and `cc_server_package.sh` — keeping it
/// in one readable list is what makes those three auditable side by side.
List<NativeRequirement> buildNativeRequirements({
  required String grammarsRoot,
  required String dataDir,
  required String? inferenceLibPath,
  // Null when the HTTP transport is missing: the grammars are not checked.
  required GrammarManager? grammarManager,
  // Where the code mode runner may be (`CC_CODEMODE_RUNNER`,
  // `CC_NATIVE_LIB_DIR`) is read from this process's own environment only,
  // never one merged with `.env` (`BundledCodeRunner.candidates`); a test
  // gives its own.
  Map<String, String>? processEnvironment,
}) {
  bool Function() dylibProbe(String baseName, {String? envVar}) =>
      () =>
          tryOpenFirst([
            p.join(grammarsRoot, platformLibraryFileName(baseName)),
            ...nativeLibraryCandidates(
              baseName,
              appSupportRoot: dataDir,
              envVar: envVar,
            ),
          ]) !=
          null;

  return [
    // The HTTP engine first: without it `runCcServer` cannot even build the
    // clients every other subsystem is handed, so a bundle missing `librhttp`
    // must be refused before anything else is reported. `initializeRhttp()`
    // opens the same file this resolves — the probe only stats, so a JIT host
    // (dart test / dart run) cannot hang here.
    nativeRequirement(
      '${platformLibraryFileName(rhttpLibraryBaseName)} (HTTP transport)',
      () async => resolveRhttpLibraryPath(appSupportRoot: dataDir) != null,
    ),
    nativeRequirement(
      '${platformLibraryFileName(inferenceLibraryBaseName)} (semantic '
      'embeddings, meeting transcription, diarization, VAD, dictation)',
      () async => inferenceLibPath != null,
    ),
    nativeRequirement(
      '${platformLibraryFileName(ptyLibraryBaseName)} (sandboxed terminals)',
      () async => Pty.isAvailable,
    ),
    nativeRequirement(
      '${platformLibraryFileName(watcherLibraryBaseName)} (code-graph file '
      'watching)',
      () async => NativeDirectoryWatcher.isAvailable,
    ),
    nativeRequirement(
      '${platformLibraryFileName(samlLibraryBaseName)} (SAML SSO response '
      'verification)',
      () async => CcSaml.isAvailable,
    ),
    nativeRequirement(
      '${platformLibraryFileName('fff_c')} (fuzzy file search)',
      () async => dylibProbe('fff_c')(),
    ),
    nativeRequirement(
      '${platformLibraryFileName('lame_ffi')} (soundscape MP3 encoding)',
      () async => dylibProbe('lame_ffi', envVar: 'LAME_FFI_DYLIB')(),
    ),
    // TODO(windows): rift has no MSVC copy-on-write backend, so
    // `scripts/release/windows_natives.sh` deliberately does not build it and
    // `git worktree` is the BACKEND there (not a degradation) — see
    // `RiftRepoIsolationAdapter.missingRiftIsExpected`. Drop this exemption once
    // a Windows CoW backend exists.
    nativeRequirement(
      '${platformLibraryFileName('rift_ffi')} (copy-on-write worktrees)',
      () async => dylibProbe('rift_ffi', envVar: 'RIFT_FFI_DYLIB')(),
      requiredOnWindows: false,
    ),
    // TODO(windows): cc_window_windows.cpp has never been compiled, so no
    // Windows build ships this yet and an app component there fails at Launch.
    // Drop this exemption with the one in scripts/lib/natives.sh, once
    // windows_natives.sh builds it.
    nativeRequirement(
      '${platformLibraryFileName(windowLibraryBaseName)} (desktop app windows)',
      () async => CcWindow.isAvailable,
      requiredOnWindows: false,
    ),
    nativeRequirement(
      '${platformLibraryFileName('tree-sitter')} (code graph indexing)',
      () async => dylibProbe('tree-sitter')(),
    ),
    // Subprocess executables rather than dylibs, but the same contract: they
    // ship in `<bundle>/bin/media/` and `render_media` has no system-tool
    // fallback, so a miss would otherwise surface only on an agent's first
    // media read. Plain `dart build cli` does not stage them;
    // `scripts/build_server.sh` and the release packagers do.
    nativeRequirement(
      'media/ ffmpeg, ffprobe, cc_pdf_render and cc_svg_render (render_media '
      'video, PDF, SVG and image rendering; stage with scripts/build_server.sh '
      '— searched ${BundledMediaTools.searchDirectories(appSupportRoot: dataDir).join(', ')})',
      () async {
        try {
          BundledMediaTools.locate(appSupportRoot: dataDir);
          return true;
        } on MediaRenderException {
          return false;
        }
      },
    ),
    // Code mode's script runner, staged like the media helpers in
    // `<bundle>/bin/codemode/`. Required even where it cannot confine itself:
    // that is decided by its self-test after boot and only makes code mode
    // unavailable, while a missing runner is a broken install. There is no
    // fallback that runs a script in the server process.
    nativeRequirement(
      'codemode/${BundledCodeRunner.executableName} (code mode script runner '
      'for the repl tool; stage with scripts/build_server.sh — searched '
      '${BundledCodeRunner.candidates(appSupportRoot: dataDir, processEnvironment: processEnvironment).join(', ')})',
      () async {
        try {
          BundledCodeRunner.locate(
            appSupportRoot: dataDir,
            processEnvironment: processEnvironment,
          );
          return true;
        } on CodeRunnerNotFoundException {
          return false;
        }
      },
    ),
    if (grammarManager != null)
      for (final languageId in kLanguageByExtension.values.toSet())
        nativeRequirement(
          '${platformLibraryFileName('tree-sitter-$languageId')} '
          '($languageId code graph grammar)',
          () async => await grammarManager.resolve(languageId) != null,
        ),
  ];
}
