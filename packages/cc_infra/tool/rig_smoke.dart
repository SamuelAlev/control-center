// Boots one real rig through the SAME code path the server uses and reports
// what happened. The unit suite pins every policy decision against fakes;
// this is the one place the launch argv, the images, the readiness probes and
// the egress policy meet an actual hypervisor.
//
//   cd packages/cc_infra
//   fvm dart run tool/rig_smoke.dart "<dataDir>"            # exec (terminal)
//   fvm dart run tool/rig_smoke.dart "<dataDir>" browser    # Chromium
//   fvm dart run tool/rig_smoke.dart "<dataDir>" firefox    # Firefox (BiDi)
//   fvm dart run tool/rig_smoke.dart "<dataDir>" webkit     # WebKit (WebDriver)
//   fvm dart run tool/rig_smoke.dart "<dataDir>" computer   # desktop image
//
// Exec (a smolvm microVM): exits 0 only when the machine booted, answered
// `machine exec`, reached an allowlisted host and was refused a
// non-allowlisted one. Browser (smolvm): boots the engine's image, waits for
// its automation endpoint and drives real verbs over the SAME client the
// server attaches — three protocols, one contract, and the engines that
// install their own browser prove that too. Computer (QEMU): boots the
// interactive image, waits for its guest agent and captures frames.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/cc_infra.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run tool/rig_smoke.dart <dataDir> '
      '[exec|browser|firefox|webkit|computer]',
    );
    exit(2);
  }
  final dataDir = args.first;
  final mode = args.length > 1 ? args[1] : 'exec';
  switch (mode) {
    case 'exec':
      await _smokeExec(dataDir);
    case 'browser':
      await _smokeBrowser(dataDir, RigBrowserEngine.chromium);
    case 'firefox':
      await _smokeBrowser(dataDir, RigBrowserEngine.firefox);
    case 'webkit':
      await _smokeBrowser(dataDir, RigBrowserEngine.webkit);
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
      'machine',
      'exec',
      '--name',
      machine.name,
      '--timeout',
      '120s',
      '--',
      'sh',
      '-c',
      guestCommand,
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

/// Boots a browser microVM and proves its real lane: the forwarded automation
/// port answers, the page drives, and a screenshot comes back.
///
/// Every verb here is one the driver sends on behalf of a domain action, and
/// each engine reaches them through a different protocol — which is exactly
/// why this runs against a real guest rather than a fake.
Future<void> _smokeBrowser(String dataDir, RigBrowserEngine engine) async {
  final backend = SmolvmEnclosureBackend(dataDir: dataDir);

  final probe = await backend.probe();
  stdout.writeln(
    'probe: available=${probe.available} backend=${probe.backend.wire} '
    'surfaces=${probe.surfaces} engines=${probe.browserEngines}'
    '${probe.note == null ? '' : '\n  note: ${probe.note}'}',
  );
  if (!probe.available || !probe.surfaces.contains(RigSurface.browser)) {
    stderr.writeln('cannot smoke-test browser: surface not offered');
    exit(1);
  }
  if (!probe.browserEngines.contains(engine)) {
    stderr.writeln('cannot smoke-test ${engine.label}: not offered here');
    exit(1);
  }

  final rigId = 'smoke${DateTime.now().millisecondsSinceEpoch % 100000}';
  final sw = Stopwatch()..start();
  stdout.writeln('launching ${engine.label} rig $rigId…');
  final SmolvmMachine machine;
  try {
    machine = await backend.launch(
      rigId: rigId,
      spec: RigSpec(
        surface: RigSurface.browser,
        browserEngine: engine,
        conversationId: 'smoke',
        egressAllowlist: browserRigEgressAllowlist(),
      ),
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
    // The SAME attach the server performs, engine and Host header included.
    final client = await attachBrowserEngine(
      engine: machine.engine,
      host: '127.0.0.1',
      port: machine.devtoolsPort!,
      guestPort:
          machine.automationGuestPort ?? browserRigEndpointPort(machine.engine),
    );
    try {
      void check(String label, bool ok, [String detail = '']) {
        stdout.writeln('  ${ok ? 'ok  ' : 'FAIL'} $label $detail');
        if (!ok) {
          failed = true;
        }
      }

      // A `data:` page: no egress, no DNS, and every element this needs.
      const page =
          'data:text/html,<title>Smoke</title>'
          '<button id=b onclick="document.title=%27hit%27">Hit</button>'
          '<input id=i>';
      check('navigate', await client.navigate(page));
      check('currentUrl', (await client.currentUrl()).contains('Smoke'));

      final centre = await client.centerOf('#b');
      check('centerOf', centre != null, '$centre');
      if (centre != null) {
        await client.clickAt(centre.$1, centre.$2);
        // Read through the DOM digest rather than a bespoke evaluate: it is
        // the same path the agent's `extract` verb takes.
        final after = await client.domSnapshot(selector: 'title');
        check(
          'click landed',
          (after ?? '').contains('hit'),
          '(title digest ${after?.replaceAll('\n', ' ')})',
        );
      }

      check('fill', await client.fill('#i', 'typed'));
      check('waitFor', await client.waitFor('#i', const Duration(seconds: 3)));

      final dom = await client.domSnapshot();
      check('domSnapshot', (dom ?? '').contains('<button'), '');
      final a11y = await client.accessibilitySnapshot();
      check('a11y', a11y.contains('button'), '');

      final shot = await client.captureScreenshot();
      final bytes = base64Decode(shot);
      final magic = engine.capturesJpeg
          ? bytes.take(2).toList().toString() == '[255, 216]'
          : bytes.take(4).toList().toString() == '[137, 80, 78, 71]';
      check(
        'screenshot ${engine.stillMediaType}',
        bytes.length > 1000 && magic,
        '(${bytes.length} bytes)',
      );

      await client.navigate('data:text/html,<title>Two</title>two');
      check('back', await client.goHistory(-1));
      final state = await client.navigationState();
      check('canGoForward after back', state.canGoForward);
      check('forward', await client.goHistory(1));
      check(
        'overshoot refused',
        !await client.goHistory(20),
        'a history end is a false, never a silent no-op',
      );
      await client.reload();
      stdout.writeln('  ok   reload');

      // The human lane, through the driver rather than the client: Chromium
      // pushes frames and the other two are polled, and a lane that connects
      // and never paints looks identical to a healthy one from every other
      // signal.
      final driver = BrowserRigDriver(
        client: client,
        viewport: RigDisplaySize.defaultDesktop,
      );
      try {
        final stream = await driver.openWatchStream(
          const RigWatchRequest(size: RigDisplaySize.defaultDesktop, fps: 4),
        );
        if (stream == null) {
          check('watch lane', false, 'no lane offered');
        } else {
          // ONE frame is the bar, not a byte budget. Chromium PUSHES frames
          // and only when the page repaints, so a static test page yields the
          // primed screenshot and then nothing — which is correct, and what a
          // 20 KB threshold read as a failure. The polled engines produce a
          // frame per tick and clear this immediately.
          var bytes = 0;
          final done = Completer<void>();
          final sub = stream.listen((chunk) {
            bytes += chunk.length;
            if (bytes > 2000 && !done.isCompleted) {
              done.complete();
            }
          });
          await done.future.timeout(
            const Duration(seconds: 25),
            onTimeout: () {},
          );
          await sub.cancel();
          check(
            'watch lane (${driver.watchCodec.wire})',
            bytes > 2000,
            '($bytes bytes)',
          );
        }
      } on RigStreamUnavailable catch (e) {
        check('watch lane', false, '${e.code}: ${e.message}');
      }

      stdout.writeln('drove ${engine.label} in ${sw.elapsed.inSeconds}s');
    } finally {
      await client.close();
    }
  } on Object catch (e) {
    stderr.writeln('attach/drive failed: $e');
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
        stderr.writeln('watch lane below 5 fps — the stream path is degraded');
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
