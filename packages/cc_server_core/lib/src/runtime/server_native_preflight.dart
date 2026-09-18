import 'package:cc_natives/cc_natives.dart'
    show
        CcSaml,
        GrammarManager,
        NativeDirectoryWatcher,
        Pty,
        kLanguageByExtension,
        nativeLibraryCandidates,
        inferenceLibraryBaseName,
        platformLibraryFileName,
        ptyLibraryBaseName,
        samlLibraryBaseName,
        tryOpenFirst,
        watcherLibraryBaseName;
import 'package:cc_server_core/src/native_preflight.dart';
import 'package:path/path.dart' as p;

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
  required GrammarManager grammarManager,
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
    nativeRequirement(
      '${platformLibraryFileName('tree-sitter')} (code graph indexing)',
      () async => dylibProbe('tree-sitter')(),
    ),
    for (final languageId in kLanguageByExtension.values.toSet())
      nativeRequirement(
        '${platformLibraryFileName('tree-sitter-$languageId')} '
        '($languageId code graph grammar)',
        () async => await grammarManager.resolve(languageId) != null,
      ),
  ];
}
