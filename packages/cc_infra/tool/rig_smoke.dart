// Boots one real rig through the SAME code path the server uses and reports
// what happened. The unit suite pins every policy decision against fakes;
// this is the one place the launch argv, the images, the readiness probes and
// the egress policy meet an actual hypervisor.
//
//   cd packages/cc_infra
//   fvm dart run tool/rig_smoke.dart "<dataDir>"            # exec (terminal)
//   fvm dart run tool/rig_smoke.dart "<dataDir>" browser    # headless browser
//   fvm dart run tool/rig_smoke.dart "<dataDir>" computer   # desktop image
//
// Exec (a smolvm microVM): exits 0 only when the machine booted, answered
// `machine exec`, reached an allowlisted host and was refused a
// non-allowlisted one. Browser (smolvm): boots the image, waits for its
// DevTools endpoint and takes one real screenshot over CDP. Computer (QEMU):
// boots the interactive image, waits for its guest agent and captures frames.
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/cc_infra.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run tool/rig_smoke.dart <dataDir> [exec|browser|computer]',
    );
    exit(2);
  }
  final dataDir = args.first;
  final mode = args.length > 1 ? args[1] : 'exec';
  switch (mode) {
    case 'exec':
      await _smokeExec(dataDir);
    case 'browser':
      await _smokeBrowser(dataDir);
    case 'computer':
      await _smokeDesktop(dataDir);
    default:
      stderr.writeln('unsupported smoke mode: $mode');
      exit(2);
  }
}

/// Boots an exec microVM and proves the terminal's whole contract: the guest
/// answers, its init landed (git is how worktrees sync), an allowlisted host
/// is reachable and a non-allowlisted one is refused — enforced by the
/// microVM's net layer itself, with no proxy involved.
Future<void> _smokeExec(String dataDir) async {
  final backend = SmolvmEnclosureBackend(dataDir: dataDir);

  final probe = await backend.probe();
  stdout.writeln(
    'probe: available=${probe.available} backend=${probe.backend.wire} '
    'terminals=${probe.supportsTerminals} surfaces=${probe.surfaces}'
    '${probe.note == null ? '' : '\n  note: ${probe.note}'}',
  );
  if (!probe.available || !probe.supportsTerminals) {
    stderr.writeln('cannot smoke-test: no bootable exec backend here');
    exit(1);
  }

  final rigId = 'smoke${DateTime.now().millisecondsSinceEpoch % 100000}';
  final spec = RigSpec.exec(
    conversationId: 'smoke',
    egressAllowlist: execRigEgressAllowlist(),
  );
  final sw = Stopwatch()..start();
  stdout.writeln(
    'launching exec rig $rigId (${spec.memoryMb} MB, ${spec.cpuCount} vCPU)…',
  );
  final SmolvmMachine machine;
  try {
    machine = await backend.launch(
      rigId: rigId,
      spec: spec,
      onProgress: (step) =>
          stdout.writeln('  [${sw.elapsed.inSeconds}s] $step'),
    );
  } on Object catch (e) {
    stderr.writeln('LAUNCH FAILED after ${sw.elapsed.inSeconds}s: $e');
    exit(1);
  }
  stdout.writeln('booted in ${sw.elapsed.inSeconds}s as ${machine.name}');

  var failed = false;
  try {
    // One string, built outside the argv list: adjacent string literals
    // inside a list literal are a lint here.
    const guestCommand =
        'echo CC_SMOKE_OK "\$(uname -m)" "\$(whoami)"; '
        'command -v git >/dev/null 2>&1 && echo GIT_OK || echo GIT_MISSING; '
        'if curl -fsS --max-time 20 https://api.github.com/zen '
        '>/dev/null 2>&1; then echo EGRESS_ALLOWED_OK; '
        'else echo EGRESS_ALLOWED_FAIL; fi; '
        'if curl -fsS --max-time 20 https://example.com '
        '>/dev/null 2>&1; then echo EGRESS_DENY_LEAK; '
        'else echo EGRESS_DENY_OK; fi';
    final result = await Process.run(backend.resolvedBinary!, [
      'machine', 'exec', '--name', machine.name, '--timeout', '120s',
      '--', 'sh', '-c', guestCommand,
    ]).timeout(const Duration(seconds: 150));
    stdout
      ..writeln('--- guest says ---')
      ..write(result.stdout)
      ..writeln('------------------');
    final out = '${result.stdout}';
    if (result.exitCode != 0 || !out.contains('CC_SMOKE_OK')) {
      stderr.writeln(
        'exec into the guest failed (${result.exitCode}): ${result.stderr}',
      );
      failed = true;
    }
    if (!out.contains('GIT_OK')) {
      stderr.writeln('git is missing in the guest — worktree sync cannot run');
      failed = true;
    }
    if (!out.contains('EGRESS_ALLOWED_OK')) {
      stderr.writeln('an allowlisted host was NOT reachable');
      failed = true;
    }
    if (out.contains('EGRESS_DENY_LEAK')) {
      stderr.writeln(
        'a non-allowlisted host WAS reachable — the egress allowlist is not '
        'being enforced',
      );
      failed = true;
    }
  } on Object catch (e) {
    stderr.writeln('exec into the guest failed: $e');
    failed = true;
  } finally {
    stdout.writeln('destroying $rigId…');
    await backend.destroy(machine);
  }
  stdout.writeln(failed ? 'SMOKE TEST FAILED' : 'SMOKE TEST PASSED');
  exit(failed ? 1 : 0);
}

/// Boots a browser microVM and proves its real lane: the forwarded DevTools
/// port answers and a page screenshot comes back.
Future<void> _smokeBrowser(String dataDir) async {
  final backend = SmolvmEnclosureBackend(dataDir: dataDir);

  final probe = await backend.probe();
  stdout.writeln(
    'probe: available=${probe.available} backend=${probe.backend.wire} '
    'surfaces=${probe.surfaces}'
    '${probe.note == null ? '' : '\n  note: ${probe.note}'}',
  );
  if (!probe.available || !probe.surfaces.contains(RigSurface.browser)) {
    stderr.writeln('cannot smoke-test browser: surface not offered');
    exit(1);
  }

  final rigId = 'smoke${DateTime.now().millisecondsSinceEpoch % 100000}';
  final sw = Stopwatch()..start();
  stdout.writeln('launching browser rig $rigId…');
  final SmolvmMachine machine;
  try {
    machine = await backend.launch(
      rigId: rigId,
      spec: RigSpec(
        surface: RigSurface.browser,
        conversationId: 'smoke',
      ),
      onProgress: (step) =>
          stdout.writeln('  [${sw.elapsed.inSeconds}s] $step'),
    );
  } on Object catch (e) {
    stderr.writeln('LAUNCH FAILED after ${sw.elapsed.inSeconds}s: $e');
    exit(1);
  }
  stdout.writeln('booted in ${sw.elapsed.inSeconds}s');

  var failed = false;
  try {
    final cdp = await CdpClient.attachToFirstPage(
      host: '127.0.0.1',
      port: machine.devtoolsPort!,
      timeout: const Duration(seconds: 75),
    );
    try {
      await cdp.enableDomains();
      final shot = await cdp.captureScreenshot();
      stdout.writeln(
        'CDP attached; screenshot ${shot.length} base64 chars '
        '(t+${sw.elapsed.inSeconds}s)',
      );
      if (shot.length < 1000) {
        stderr.writeln('screenshot is implausibly small');
        failed = true;
      }
    } finally {
      await cdp.close();
    }
  } on Object catch (e) {
    stderr.writeln('CDP attach failed: $e');
    failed = true;
  } finally {
    stdout.writeln('destroying $rigId…');
    await backend.destroy(machine);
  }
  stdout.writeln(failed ? 'SMOKE TEST FAILED' : 'SMOKE TEST PASSED');
  exit(failed ? 1 : 0);
}

/// Boots the interactive desktop image and proves its guest agent serves:
/// health answers with a display size and one frame comes back non-empty.
Future<void> _smokeDesktop(String dataDir) async {
  const surface = RigSurface.computer;
  final images = RigImageStore(dataDir: dataDir);
  final backend = QemuEnclosureBackend(dataDir: dataDir, images: images);
  final probe = await backend.probe();
  if (!probe.available || !probe.surfaces.contains(surface)) {
    stderr.writeln(
      'cannot smoke-test computer: '
      '${probe.note ?? 'surface not offered'} '
      '(missing images: ${probe.missingImages})',
    );
    exit(1);
  }
  final rigId = 'smoke${DateTime.now().millisecondsSinceEpoch % 100000}';
  final sw = Stopwatch()..start();
  stdout.writeln('launching computer rig $rigId…');
  final QemuMachine machine;
  try {
    machine = await backend.launch(
      rigId: rigId,
      spec: RigSpec(surface: surface, conversationId: 'smoke'),
      onProgress: (step) =>
          stdout.writeln('  [${sw.elapsed.inSeconds}s] $step'),
    );
  } on Object catch (e) {
    stderr.writeln('LAUNCH FAILED after ${sw.elapsed.inSeconds}s: $e');
    exit(1);
  }
  var failed = false;
  try {
    stdout.writeln(
      'booted in ${sw.elapsed.inSeconds}s; display ${machine.display}',
    );
    // The agent answers /health before the X session it captures from is
    // up, so give the display a grace window before calling the image
    // broken.
    Object? lastError;
    var captured = false;
    for (var attempt = 0; attempt < 10 && !captured; attempt++) {
      try {
        final frame = await machine.agent.capture(
          size: RigDisplaySize(640, 400),
        );
        stdout.writeln(
          'captured a ${frame.length}-byte frame '
          '(t+${sw.elapsed.inSeconds}s)',
        );
        captured = frame.length >= 1000;
        if (!captured) {
          lastError = 'frame is implausibly small (${frame.length} bytes)';
        }
      } on Object catch (e) {
        lastError = e;
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
    if (!captured) {
      stderr.writeln(
        'no frame after ${sw.elapsed.inSeconds}s — the display server in '
        'the image is probably not coming up. Last error: $lastError',
      );
      failed = true;
    } else {
      // Measure the WATCH lane, not just a still: the agent once spawned a
      // fresh ffmpeg per frame and "15 fps" delivered 2-3 — a still-image
      // check can never catch that. Measured AFTER the boot settles: in the
      // first ~15s the session's own startup competes with the encoder for
      // vCPUs and a healthy image reads 2 fps (observed, then 23 fps once
      // idle).
      await Future<void>.delayed(const Duration(seconds: 12));
      final stream = await machine.agent.openStream(
        RigWatchRequest(size: RigDisplaySize(960, 600), fps: 24),
      );
      var frames = 0;
      var bytes = 0;
      final sub = stream.listen((chunk) {
        bytes += chunk.length;
        for (var i = 0; i + 1 < chunk.length; i++) {
          if (chunk[i] == 0xFF && chunk[i + 1] == 0xD8) {
            frames++;
          }
        }
      });
      await Future<void>.delayed(const Duration(seconds: 4));
      await sub.cancel();
      final fps = frames / 4;
      stdout.writeln(
        'watch lane: $frames frames in 4s '
        '(~${fps.toStringAsFixed(1)} fps, ${bytes ~/ 1024} KB)',
      );
      if (frames < 20) {
        stderr.writeln(
          'watch lane below 5 fps — the stream path is degraded',
        );
        failed = true;
      }
      // Dynamic resolution: the tab drives the guest's mode, so the guest
      // must accept an arbitrary (cvt-minted) size, not just the presets.
      // Retried like the real client's re-arm loop: during session
      // startup xfsettingsd can revert an app-initiated mode change, and
      // one early bounce is not a broken image.
      final want = RigDisplaySize(1512, 944);
      var settled = await machine.agent.setDisplay(want);
      for (var i = 0; i < 3 && settled != want; i++) {
        await Future<void>.delayed(const Duration(seconds: 4));
        settled = await machine.agent.setDisplay(want);
      }
      stdout.writeln('set_display $want → guest settled on $settled');
      if (settled.width != want.width || settled.height != want.height) {
        stderr.writeln(
          'the guest never adopted the requested mode — tab-driven resize '
          'is broken in this image',
        );
        failed = true;
      }
      // The audio lane: even a silent desktop encodes to a steady MP3
      // byte stream (~16 KB/s at 128 kbps), so zero bytes means the sink
      // or the encoder is broken, not that nothing is playing.
      try {
        final audio = await machine.agent.openAudio();
        var audioBytes = 0;
        final audioSub = audio.listen((c) => audioBytes += c.length);
        await Future<void>.delayed(const Duration(seconds: 3));
        await audioSub.cancel();
        stdout.writeln('audio lane: $audioBytes bytes in 3s');
        if (audioBytes < 8000) {
          stderr.writeln(
            'audio lane produced almost nothing — the null '
            'sink or the in-guest encoder is broken',
          );
          failed = true;
        }
      } on Object catch (e) {
        stderr.writeln('audio lane failed to open: $e');
        failed = true;
      }
    }
  } on Object catch (e) {
    stderr.writeln('guest agent check failed: $e');
    failed = true;
  } finally {
    stdout.writeln('destroying $rigId…');
    await backend.destroy(machine);
  }
  stdout.writeln(failed ? 'SMOKE TEST FAILED' : 'SMOKE TEST PASSED');
  exit(failed ? 1 : 0);
}
