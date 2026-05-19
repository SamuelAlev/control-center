// Boots one desktop rig and times x11grab pipelines INSIDE the guest, to
// find where the watch lane's frame rate actually goes. Throwaway diagnostic.
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/cc_infra.dart';

Future<void> main(List<String> args) async {
  final dataDir = args.first;
  final images = RigImageStore(dataDir: dataDir);
  final backend = QemuEnclosureBackend(dataDir: dataDir, images: images);
  final machine = await backend.launch(
    rigId: 'fpsprobe${DateTime.now().millisecondsSinceEpoch % 100000}',
    spec: RigSpec(surface: RigSurface.computer, conversationId: 'probe'),
    onProgress: (s) => stdout.writeln('  $s'),
  );
  Future<void> run(String label, String cmd) async {
    final sw = Stopwatch()..start();
    final r = await Process.run('ssh', [
      '-i', machine.privateKeyPath,
      '-p', '${machine.sshPort}',
      '-o', 'StrictHostKeyChecking=no',
      '-o', 'UserKnownHostsFile=/dev/null',
      '-o', 'LogLevel=ERROR',
      '-o', 'BatchMode=yes',
      'cc@127.0.0.1',
      cmd,
    ]).timeout(const Duration(seconds: 90));
    stdout
      ..writeln('== $label (${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s, exit ${r.exitCode})')
      ..writeln('${r.stdout}'.trim())
      ..writeln('${r.stderr}'.trim().split('\n').take(6).join('\n'));
  }

  if (args.length > 1 && args[1] == 'hold') {
    stdout.writeln(
      'HOLD ssh=${machine.sshPort} agent=${machine.agentPort} '
      'key=${machine.privateKeyPath} runtime=${machine.runtimeDir}',
    );
    await Future<void>.delayed(const Duration(minutes: 12));
    await backend.destroy(machine);
    exit(0);
  }
  try {
    // The interactive image's readiness gate is the agent, not sshd; give
    // sshd a moment to come up.
    for (var i = 0; i < 30; i++) {
      final probe = await Process.run('ssh', [
        '-i', machine.privateKeyPath, '-p', '${machine.sshPort}',
        '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null',
        '-o', 'LogLevel=ERROR', '-o', 'BatchMode=yes',
        '-o', 'ConnectTimeout=3',
        'cc@127.0.0.1', 'true',
      ]);
      if (probe.exitCode == 0) {
        break;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    await run('env', 'nproc; uname -r; DISPLAY=:0 xdpyinfo | grep dimensions');
    await run(
      '48 frames, grab+scale+mjpeg (the stream pipeline)',
      'time ffmpeg -loglevel error -f x11grab -framerate 24 '
          '-video_size 1280x800 -i :0 -vf scale=960:600 -q:v 10 '
          '-f mjpeg -frames:v 48 -y /tmp/a.mjpeg 2>&1 | tail -3',
    );
    await run(
      '48 frames, grab only (no scale)',
      'time ffmpeg -loglevel error -f x11grab -framerate 24 '
          '-video_size 1280x800 -i :0 -q:v 10 '
          '-f mjpeg -frames:v 48 -y /tmp/b.mjpeg 2>&1 | tail -3',
    );
    await run(
      '48 frames, grab to null (no encode)',
      'time ffmpeg -loglevel error -f x11grab -framerate 24 '
          '-video_size 1280x800 -i :0 -f null - 2>&1 | tail -3',
    );
  } finally {
    await backend.destroy(machine);
  }
  exit(0);
}
