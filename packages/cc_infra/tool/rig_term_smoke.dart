// Exercises the VM-terminal path exactly as TerminalSessionService does:
// boot the conversation's exec rig, sync a worktree in, then run the SAME
// interactive ssh argv the PTY would — and prove a shell answers in it.
//   fvm dart run tool/rig_term_smoke.dart "<dataDir>"
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_infra/cc_infra.dart';

Future<void> main(List<String> args) async {
  final dataDir = args.first;
  final images = RigImageStore(dataDir: dataDir);
  final backend = QemuEnclosureBackend(dataDir: dataDir, images: images);

  final worktree = await Directory.systemTemp.createTemp('cc-term-smoke-');
  await File('${worktree.path}/hello.txt').writeAsString('hi\n');
  await Process.run('git', ['-C', worktree.path, 'init', '-q']);

  final sw = Stopwatch()..start();
  final machine = await backend.launch(
    rigId: 'termsmoke${DateTime.now().millisecondsSinceEpoch % 100000}',
    spec: RigSpec.exec(
      conversationId: 'termsmoke',
      worktreePath: worktree.path,
      egressAllowlist: execRigEgressAllowlist(),
    ),
    onProgress: (s) => stdout.writeln('  [${sw.elapsed.inSeconds}s] $s'),
  );
  var failed = false;
  try {
    stdout.writeln('booted in ${sw.elapsed.inSeconds}s');
    final sync = WorktreeSync(
      sshPort: machine.sshPort,
      privateKeyPath: machine.privateKeyPath,
    );
    final synced = await sync.syncIn(
      hostPath: worktree.path,
      onProgress: (s) => stdout.writeln('  [${sw.elapsed.inSeconds}s] $s'),
    );
    stdout.writeln('syncIn: ok=${synced.ok} ${synced.message}');
    failed |= !synced.ok;

    // The EXACT argv the terminal PTY runs.
    final argv = sync.interactiveShellArgv(workingDirectory: '/home/cc/work');
    stdout.writeln('shell argv: ssh ${argv.join(' ')}');
    final proc = await Process.start('ssh', argv);
    final out = StringBuffer();
    proc.stdout.transform(utf8.decoder).listen(out.write);
    proc.stderr.transform(utf8.decoder).listen(out.write);
    proc.stdin.writeln('echo CC_TERM_OK; pwd; ls; exit');
    final code = await proc.exitCode.timeout(const Duration(seconds: 30));
    stdout
      ..writeln('--- shell transcript ---')
      ..writeln(out.toString().trim())
      ..writeln('--- exit $code ---');
    if (!out.toString().contains('CC_TERM_OK')) {
      stderr.writeln('the shell never answered');
      failed = true;
    }
  } on Object catch (e) {
    stderr.writeln('FAILED: $e');
    failed = true;
  } finally {
    await backend.destroy(machine);
    await worktree.delete(recursive: true);
  }
  stdout.writeln(failed ? 'TERM SMOKE FAILED' : 'TERM SMOKE PASSED');
  exit(failed ? 1 : 0);
}
