import 'package:cc_server_core/src/native_preflight.dart';
import 'package:cc_server_core/src/server_boot_refusal.dart';
import 'package:test/test.dart';

/// A bundle without a required native library (the code mode runner among
/// them) is refused like any other boot refusal: the binary prints one line
/// and exits 78, rather than logging an uncaught error and staying alive
/// with the global database open.
void main() {
  test('a missing library is a boot refusal of one line naming it and where '
      'it was searched', () async {
    final missing = await missingRequiredNatives([
      nativeRequirement('libfff_c (fuzzy file search)', () async => true),
      nativeRequirement(
        'codemode/cc_codemode (code mode script runner for the repl tool; '
        'stage with scripts/build_server.sh — searched\n'
        '/opt/bundle/bin/codemode/cc_codemode, /data/codemode/cc_codemode)',
        () async => false,
      ),
    ], isWindows: false);
    final Object refusal = NativeLibrariesMissing(
      missing,
      searched: [r'$CC_NATIVE_LIB_DIR', '/data', '/data/grammars'],
    );

    expect(refusal, isA<ServerBootRefusal>());
    final message = (refusal as ServerBootRefusal).message;
    expect(message, isNot(contains('\n')));
    expect(message, startsWith('cc_server: cannot start — required native'));
    expect(message, contains('codemode/cc_codemode (code mode script runner'));
    expect(message, contains('/opt/bundle/bin/codemode/cc_codemode'));
    expect(message, isNot(contains('libfff_c')));
    expect(
      message,
      contains(r'Looked in $CC_NATIVE_LIB_DIR, /data, /data/grammars'),
    );
    expect(message, endsWith('Refusing to boot with a degraded feature set.'));
    expect(refusal.toString(), message);
  });
}
