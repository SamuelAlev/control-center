import 'package:cc_server_core/src/native_preflight.dart';
import 'package:test/test.dart';

/// The boot preflight's platform-aware requirement table.
///
/// Every native is required on every platform, with rift the one documented
/// exemption (Windows has no MSVC copy-on-write backend, so `git worktree` is
/// the backend there). These tests pin that asymmetry — the exemption is easy to
/// widen by accident, and a native that silently stops being required is exactly
/// the invisible degradation the whole change removes.
void main() {
  NativeRequirement present(String name, {bool requiredOnWindows = true}) =>
      nativeRequirement(
        name,
        () async => true,
        requiredOnWindows: requiredOnWindows,
      );

  NativeRequirement absent(String name, {bool requiredOnWindows = true}) =>
      nativeRequirement(
        name,
        () async => false,
        requiredOnWindows: requiredOnWindows,
      );

  test('passes when every requirement resolves', () async {
    expect(
      await missingRequiredNatives([
        present('libfff_c'),
        present('libtree-sitter'),
      ], isWindows: false),
      isEmpty,
    );
  });

  test('reports each missing description, in declaration order', () async {
    expect(
      await missingRequiredNatives([
        absent('libfff_c (fuzzy file search)'),
        present('libtree-sitter (code graph indexing)'),
        absent('libccpty (sandboxed terminals)'),
      ], isWindows: false),
      ['libfff_c (fuzzy file search)', 'libccpty (sandboxed terminals)'],
    );
  });

  test('requires everything by default, including on Windows', () async {
    // `nativeRequirement` defaults `requiredOnWindows` to true so an exemption
    // is never granted by omission — it has to be written down.
    expect(
      await missingRequiredNatives([absent('cc_watcher.dll')], isWindows: true),
      ['cc_watcher.dll'],
    );
  });

  test('skips a Windows-exempt requirement only on Windows', () async {
    final rift = absent(
      'librift_ffi (CoW worktrees)',
      requiredOnWindows: false,
    );

    expect(
      await missingRequiredNatives([rift], isWindows: true),
      isEmpty,
      reason: 'Windows ships no rift; git worktree is the backend there',
    );
    expect(await missingRequiredNatives([rift], isWindows: false), [
      'librift_ffi (CoW worktrees)',
    ], reason: 'everywhere else a missing rift dylib is a broken install');
  });

  test(
    'an exempt requirement that DOES resolve on Windows still passes',
    () async {
      // The exemption skips the probe, so a present library must not be reported
      // either way.
      expect(
        await missingRequiredNatives([
          present('librift_ffi', requiredOnWindows: false),
        ], isWindows: true),
        isEmpty,
      );
    },
  );

  test('an empty table is vacuously satisfied', () async {
    expect(await missingRequiredNatives([], isWindows: false), isEmpty);
  });
}
