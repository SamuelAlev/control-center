import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('incomplete configured media preserves the existing server bundle', () {
    final root = Directory.current.path;
    final fixture = Directory.systemTemp.createTempSync('cc_server_build_');
    addTearDown(() => fixture.deleteSync(recursive: true));
    for (final path in const [
      'scripts/build_server.sh',
      'scripts/lib/common.sh',
      'scripts/lib/media.sh',
      'scripts/lib/natives.sh',
      'scripts/lib/native_pins.env',
    ]) {
      final copy = File('${fixture.path}/$path');
      copy.parent.createSync(recursive: true);
      File('$root/$path').copySync(copy.path);
    }

    final cliDir = Platform.isMacOS
        ? 'macos_arm64'
        : Platform.isWindows
        ? 'windows_${Platform.environment['VSCMD_ARG_TGT_ARCH'] ?? 'x64'}'
        : 'linux_x64';
    final server = File(
      '${fixture.path}/apps/cc_server/build/cli/$cliDir/bundle/bin/cc_server',
    );
    server.parent.createSync(recursive: true);
    server.writeAsStringSync('previous working server');

    // A non-default stage with spaces and a whitespace-padded pointer must be
    // the one validated, not an unrelated repo-root build/natives directory.
    final natives = Directory('${fixture.path}/custom natives/media')
      ..createSync(recursive: true);
    File(
      '${fixture.path}/.cc_natives_prebuilt_dir',
    ).writeAsStringSync('  ${natives.parent.path}\n\t');

    // Dart normally deletes/replaces its output. A stand-in makes that
    // destructive effect observable without compiling the entire application.
    final compiler = File('${fixture.path}/.fvm/flutter_sdk/bin/dart');
    compiler.parent.createSync(recursive: true);
    compiler.writeAsStringSync(
      '#!/bin/sh\n'
      'printf "replacement server" > "${server.path}"\n',
    );
    final chmod = Process.runSync('chmod', ['+x', compiler.path]);
    expect(chmod.exitCode, 0, reason: '${chmod.stderr}');

    final result = Process.runSync('bash', [
      '${fixture.path}/scripts/build_server.sh',
    ], workingDirectory: '${fixture.path}/apps/cc_server');
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('${natives.path}/ffmpeg'));
    expect(server.readAsStringSync(), 'previous working server');
  });
}
