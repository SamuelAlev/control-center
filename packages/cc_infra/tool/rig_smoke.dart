// Boots one real rig on the server path (unit suite uses fakes).
//
//   fvm dart run tool/rig_smoke.dart "<dataDir>" [exec|browser|firefox|webkit|computer]
//   fvm dart run tool/rig_smoke.dart "<dataDir>" ios <App.app> <bundle-id>
//   fvm dart run tool/rig_smoke.dart "<dataDir>" environment <worktree>
//   fvm dart run tool/rig_smoke.dart "<dataDir>" environment-host <worktree>
//
// Exec: boot + machine exec + allowlist pass/fail. Browser: engine image +
// automation verbs. Computer: QEMU image + guest agent + frames. Environment:
// an unmodified compose stack on virtio-net, proving the port mux and the
// reverse tunnel there; <worktree> must hold a compose.yaml publishing 18080.
// Environment-host: the same through RigEnvironmentHost and a real RigService,
// and its compose.yaml must add a one-shot service.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/repositories/rig_repository.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/ios_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_image_settings.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/cc_infra.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run tool/rig_smoke.dart <dataDir> '
      '[exec|browser|firefox|webkit|computer|ios|environment] '
      '[path-to-built.app bundle-id | worktree]',
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
    case 'environment':
      if (args.length != 3) {
        stderr.writeln(
          'usage: dart run tool/rig_smoke.dart <dataDir> environment '
          '<worktree>',
        );
        exit(2);
      }
      await _smokeEnvironment(dataDir, args[2]);
    case 'environment-host':
      if (args.length != 3) {
        stderr.writeln(
          'usage: dart run tool/rig_smoke.dart <dataDir> environment-host '
          '<worktree>',
        );
        exit(2);
      }
      await _smokeEnvironmentHost(dataDir, args[2]);
    case 'ios':
      if (args.length != 4) {
        stderr.writeln(
          'usage: dart run tool/rig_smoke.dart <dataDir> ios '
          '<path-to-built.app> <bundle-id>',
        );
        exit(2);
      }
      await _smokeIos(dataDir, args[2], args[3]);
    default:
      stderr.writeln('unsupported smoke mode: $mode');
      exit(2);
  }
}

/// The compose stack's published port, fixed by the file rather than by us.
const int _environmentStackPort = 18080;

/// Boots an environment rig twice, the second time from the warmed pack, and
/// proves each thing rig placement depends on.
///
/// Every check prints PASS or FAIL. Nothing here is asserted from memory: the
/// mux and tunnels were only ever measured under TSI, so they run for real.
Future<void> _smokeEnvironment(String dataDir, String worktree) async {
  final backend = SmolvmEnclosureBackend(dataDir: dataDir);
  final probe = await backend.probe();
  if (!probe.available || !probe.surfaces.contains(RigSurface.environment)) {
    stderr.writeln('cannot smoke-test: no environment backend here');
    exit(1);
  }
  final binary = backend.resolvedBinary!;
  final model = {
    'services': {
      'web': {'image': 'nginx:1.27-alpine'},
      'cache': {'image': 'redis:7-alpine'},
    },
  };
  final egress = environmentRigEgressHosts(composeModelImages(model));
  stdout.writeln('egress from images: $egress');

  var failures = 0;
  void check(String name, {required bool ok, String detail = ''}) {
    stdout.writeln(
      '${ok ? 'PASS' : 'FAIL'} $name${detail.isEmpty ? '' : ': $detail'}',
    );
    if (!ok) {
      failures++;
    }
  }

  try {
    Future<void> boot(String label) async {
      final rigId =
          'envsmoke${DateTime.now().millisecondsSinceEpoch % 1000000}';
      final spec = RigSpec.environment(
        conversationId: 'smoke',
        environmentId: 'acme',
        worktreePath: worktree,
        egressAllowlist: egress,
      );
      final sw = Stopwatch()..start();
      stdout.writeln('--- $label: launching $rigId');
      final machine = await backend.launch(
        rigId: rigId,
        spec: spec,
        onProgress: (step) =>
            stdout.writeln('  [${sw.elapsed.inSeconds}s] $step'),
      );
      stdout.writeln('booted in ${sw.elapsed.inSeconds}s as ${machine.name}');
      try {
        await _checkEnvironment(
          backend,
          binary,
          machine,
          spec,
          worktree,
          check,
        );
      } finally {
        await backend.destroy(machine);
      }
    }

    await boot('cold boot');
    // The pack builds in the background after a first boot. Wait for it here
    // so the second boot proves the path every later rig takes.
    final pack = File(
      backend.packPathFor(
        kSmolvmEnvironmentImage,
        variant: kSmolvmEnvironmentPackVariant,
      ),
    );
    final deadline = DateTime.now().add(const Duration(minutes: 6));
    while (!pack.existsSync() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    check('warm pack was built', ok: pack.existsSync());
    if (pack.existsSync()) {
      await boot('boot from pack');
    }
  } finally {
    final swept = await backend.sweepOrphanedRuntimes();
    stdout.writeln('swept $swept leftover machine(s)');
  }
  stdout.writeln(failures == 0 ? 'ALL PASSED' : '$failures CHECK(S) FAILED');
  exit(failures == 0 ? 0 : 1);
}

/// Rows in memory, so the host can run through a real [RigService] with no
/// database. Only what the service calls on this path is implemented.
class _MemoryRigs implements RigRepository {
  final Map<String, Rig> rows = {};

  @override
  Future<void> save(String workspaceId, Rig rig) async => rows[rig.id] = rig;

  @override
  Future<Rig?> getById(String workspaceId, String rigId) async => rows[rigId];

  @override
  Future<List<Rig>> list(
    String workspaceId, {
    bool includeClosed = true,
  }) async => rows.values.toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Runs [RigEnvironmentHost] for real: what the environment service calls.
Future<void> _smokeEnvironmentHost(String dataDir, String worktree) async {
  final backend = SmolvmEnclosureBackend(dataDir: dataDir);
  await backend.probe();
  final images = RigImageStore(dataDir: dataDir);
  final rigs = RigService(
    repository: _MemoryRigs(),
    qemu: QemuEnclosureBackend(dataDir: dataDir, images: images),
    smolvm: backend,
    images: images,
    reapInterval: const Duration(hours: 1),
  );
  final private = Directory.systemTemp.createTempSync('cc_env_private');
  final host = RigEnvironmentHost(
    rigs,
    spaceWorktrees: (_, _) async => [worktree, private.path],
  );
  final definition = EnvironmentDefinition.fromJson(const {
    'id': 'smoke',
    'name': 'Acme',
    'repos': {
      'app': {'repoId': 'repo-1', 'anchor': true},
    },
    'components': [
      {
        'kind': 'compose',
        'id': 'stack',
        'http': ['web'],
      },
    ],
  });
  var failures = 0;
  void check(String name, {required bool ok, String detail = ''}) {
    stdout.writeln(
      '${ok ? 'PASS' : 'FAIL'} $name${detail.isEmpty ? '' : ': $detail'}',
    );
    if (!ok) {
      failures++;
    }
  }

  Future<EnvironmentRigInstance> start() => host.start(
    workspaceId: 'smoke',
    spaceId: 'space-1',
    environmentId: 'env-1',
    definition: definition,
    worktrees: {'app': worktree},
    environment: const {'ACME_MODE': 'smoke'},
  );

  Future<void> proveEndpoint(String when, EnvironmentRigInstance rig) async {
    final web = rig.endpoints.where((e) => e.role == 'web');
    check('the stack publishes a web endpoint $when', ok: web.isNotEmpty);
    if (web.isNotEmpty) {
      final body = await _httpGet(web.first.hostPort!);
      check(
        'that endpoint answers from the host $when',
        ok: body.contains('nginx'),
      );
    }
  }

  try {
    final sw = Stopwatch()..start();
    final rig = await start();
    stdout.writeln('started in ${sw.elapsed.inSeconds}s as ${rig.rigId}');
    check('a stack with a one-shot service comes up', ok: true);
    await proveEndpoint('on first start', rig);
    final task = await host.exec(
      workspaceId: 'smoke',
      spaceId: 'space-1',
      rigId: rig.rigId,
      argv: const ['sh', '-c', 'test -f compose.yaml && echo "\$ACME_MODE"'],
      environment: const {'ACME_MODE': 'task'},
    );
    check(
      'a task runs in the mounted worktree with its environment',
      ok: task.stdout.trim() == 'task',
      detail: task.stderr.trim(),
    );
    final denied = await host.exec(
      workspaceId: 'smoke',
      spaceId: 'space-1',
      argv: const [
        'wget',
        '-q',
        '-O',
        '/dev/null',
        '--timeout=6',
        'https://example.com',
      ],
    );
    check('a task cannot leave the allowlist', ok: denied.exitCode != 0);

    await host.stop(workspaceId: 'smoke', rigId: rig.rigId);
    sw.reset();
    final again = await start();
    stdout.writeln('resumed in ${sw.elapsed.inSeconds}s');
    check('start resumes the same machine', ok: again.rigId == rig.rigId);
    await proveEndpoint('after a resume', again);

    await host.destroy(workspaceId: 'smoke', rigId: rig.rigId);
    final left = rigs.environmentRigFor('smoke', 'space-1', 'env-1');
    check('destroy removes the machine', ok: left == null);
    final after = await Process.run(backend.resolvedBinary!, [
      'machine',
      'ls',
      '--json',
    ]);
    check(
      'nothing is left in the store',
      ok: !'${after.stdout}'.contains('ccrig-${rig.rigId}'),
    );

    File('${private.path}/compose.yaml').writeAsStringSync(
      'services:\n  web:\n    image: registry.acme.test/x:1\n',
    );
    try {
      await host.start(
        workspaceId: 'smoke',
        spaceId: 'space-1',
        environmentId: 'env-2',
        definition: definition,
        worktrees: {'app': private.path},
        environment: const {},
      );
      check('a private registry is refused', ok: false);
    } on RigPrivateRegistryException catch (e) {
      check('a private registry is refused', ok: true, detail: e.registry);
    } finally {
      private.deleteSync(recursive: true);
    }
  } on Object catch (e) {
    check('the run finished', ok: false, detail: '$e');
  } finally {
    await rigs.disposeAll();
    final swept = await backend.sweepOrphanedRuntimes();
    stdout.writeln('swept $swept leftover machine(s)');
  }
  stdout.writeln(failures == 0 ? 'ALL PASSED' : '$failures CHECK(S) FAILED');
  exit(failures == 0 ? 0 : 1);
}

/// Runs every check against one booted environment machine.
Future<void> _checkEnvironment(
  SmolvmEnclosureBackend backend,
  String binary,
  SmolvmMachine machine,
  RigSpec spec,
  String worktree,
  void Function(String name, {required bool ok, String detail}) check,
) async {
  Future<ProcessResult> sh(String script, {int seconds = 120}) => backend.exec(
    machine,
    ['sh', '-c', script],
    workdir: kSmolvmEnvironmentWorkdir,
    timeout: Duration(seconds: seconds),
  );

  // The mux, through the real service: discovery, then the host-side bridge.
  Future<void> proveMux(String when) async {
    final ports = RigPortsService(
      runInGuest: (name, command) => Process.run(binary, [
        'machine',
        'exec',
        '--name',
        name,
        '--timeout',
        '20s',
        '--',
        'sh',
        '-c',
        command,
      ]),
      startInGuest: (name, argv) => Process.start(binary, [
        'machine',
        'exec',
        '--name',
        name,
        '-i',
        '--',
        ...argv,
      ]),
      pollInterval: const Duration(seconds: 1),
    );
    try {
      ports.attachExec(
        rigId: machine.rigId,
        workspaceId: 'smoke',
        machineName: machine.name,
        muxHostPort: machine.portMuxHostPort!,
      );
      RigPortForward? forward;
      final deadline = DateTime.now().add(const Duration(seconds: 40));
      while (forward == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(seconds: 1));
        final snapshot = ports.snapshotFor('smoke', machine.rigId);
        for (final port in snapshot?.ports ?? const <RigPortForward>[]) {
          if (port.guestPort == _environmentStackPort) {
            forward = port;
          }
        }
      }
      check('discovery sees the published port $when', ok: forward != null);
      if (forward != null) {
        final body = await _httpGet(forward.hostPort);
        check(
          'port mux reaches the container from the host $when',
          ok: body.contains('nginx'),
          detail: 'via 127.0.0.1:${forward.hostPort}',
        );
      }
    } finally {
      await ports.dispose();
    }
  }

  final up = await sh('docker compose up -d --wait', seconds: 300);
  check(
    'unmodified compose file comes up',
    ok: up.exitCode == 0,
    detail: up.exitCode == 0 ? '' : '${up.stderr}',
  );
  final named = await sh('docker ps --format "{{.Names}}"');
  check(
    'fixed container_name kept',
    ok: '${named.stdout}'.contains('acme-web'),
    detail: '${named.stdout}'.trim().replaceAll('\n', ' '),
  );
  final dns = await sh('docker exec acme-web ping -c1 -W2 cache');
  check('service DNS between containers', ok: dns.exitCode == 0);

  final marker = 'host-${DateTime.now().microsecondsSinceEpoch}';
  final hostFile = File('$worktree/smoke-marker.txt')
    ..writeAsStringSync(marker);
  final seen = await sh('cat smoke-marker.txt');
  check(
    'live mount: a host edit is visible at once',
    ok: '${seen.stdout}'.trim() == marker,
  );
  final gitConfig = File('$worktree/.git/config');
  final gitBefore = gitConfig.existsSync() ? gitConfig.readAsStringSync() : '';
  final wrote = await sh(
    'echo guest > smoke-guest.txt && '
    'echo "[core] fsmonitor = /tmp/evil" >> .git/config && echo ok',
  );
  check(
    'the guest can write its view of the worktree',
    ok: '${wrote.stdout}'.contains('ok'),
  );
  check(
    'no guest write reaches the host worktree',
    ok: !File('$worktree/smoke-guest.txt').existsSync(),
  );
  check(
    'no guest write reaches the host .git',
    ok:
        (gitConfig.existsSync() ? gitConfig.readAsStringSync() : '') ==
        gitBefore,
  );
  final escape = await sh(
    'umount $kSmolvmEnvironmentWorkdir; '
    'echo x > ${smolvmEnvironmentLowerDir(kSmolvmEnvironmentWorkdir)}/esc.txt',
  );
  check(
    'guest root cannot write the host after unmounting the overlay',
    ok: escape.exitCode != 0 && !File('$worktree/esc.txt').existsSync(),
  );
  await sh(
    smolvmEnvironmentOverlayScript(environmentRigMountTargets(spec).keys),
  );
  final bind = await sh(
    'docker run --rm -v $kSmolvmEnvironmentWorkdir:/w redis:7-alpine '
    'sh -c "echo c > /w/smoke-container.txt && echo ok"',
  );
  check(
    'a container bind of the worktree is writable, and stays in the guest',
    ok:
        '${bind.stdout}'.contains('ok') &&
        !File('$worktree/smoke-container.txt').existsSync(),
  );
  hostFile.deleteSync();

  final guestDenied = await sh(
    'wget -q -O /dev/null --timeout=6 https://example.com',
  );
  check('egress denied from the guest', ok: guestDenied.exitCode != 0);
  final containerDenied = await sh(
    'docker exec acme-web wget -q -O /dev/null --timeout=6 https://example.com',
  );
  check('egress denied from a container', ok: containerDenied.exitCode != 0);

  await proveMux('on virtio-net');

  // The reverse tunnel: a guest dialling its own loopback lands on the host.
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    request.response.write('reverse-tunnel-ok');
    await request.response.close();
  });
  const guestPort = 17777;
  final tunnel = GuestReverseTunnel(
    guestPort: guestPort,
    slots: 1,
    startChannel: (argv) => Process.start(binary, [
      'machine',
      'exec',
      '--name',
      machine.name,
      '-i',
      '--',
      ...argv,
    ]),
    dialTarget: () => Socket.connect(InternetAddress.loopbackIPv4, server.port),
  )..start();
  try {
    await Future<void>.delayed(const Duration(seconds: 3));
    final reached = await sh(
      'wget -q -O - --timeout=8 http://127.0.0.1:$guestPort/',
    );
    check(
      'reverse tunnel reaches the host from the guest on virtio-net',
      ok: '${reached.stdout}'.contains('reverse-tunnel-ok'),
      detail: '${reached.stderr}'.trim(),
    );
  } finally {
    tunnel.stop();
    await server.close(force: true);
  }

  // A stop keeps the disk, so images survive it.
  await sh('docker compose down');
  await backend.stopKeepingDisks(machine);
  await backend.resume(machine, spec: spec);
  final images = await sh('docker images --format "{{.Repository}}"');
  check(
    'a stopped machine keeps its images',
    ok: '${images.stdout}'.contains('nginx'),
  );
  final again = await sh('docker compose up -d --wait', seconds: 120);
  check('the stack comes back after a resume', ok: again.exitCode == 0);
  await proveMux('after a resume');
}

Future<String> _httpGet(int port) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.get('127.0.0.1', port, '/');
    final response = await request.close();
    return await response.transform(utf8.decoder).join();
  } on Object catch (e) {
    return 'request failed: $e';
  } finally {
    client.close(force: true);
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

/// Boots the production CoreSimulator backend and proves the complete agent
/// lane against a caller-built simulator app.
Future<void> _smokeIos(String dataDir, String appPath, String bundleId) async {
  if (!Directory(appPath).existsSync() || !appPath.endsWith('.app')) {
    throw StateError(
      'iOS smoke app does not exist or is not an .app: $appPath',
    );
  }

  final store = IosAutomationStore(dataDir: dataDir);
  stdout.writeln('Installing/verifying pinned iOS automation bridge...');
  await store.install();
  final backend = IosSimulatorBackend(dataDir: dataDir, automationStore: store);
  final rigId = 'smoke-$pid-${DateTime.now().microsecondsSinceEpoch}';
  final session = await backend.launch(
    rigId: rigId,
    onProgress: (stage) => stdout.writeln(stage),
  );
  final deviceName = session.name;
  final driver = IosRigDriver(
    session: session,
    backend: backend,
    appRoots: [Directory(appPath).parent.path],
    onDisplayChanged: (display) =>
        stdout.writeln('Simulator display changed to $display'),
  );

  try {
    Future<void> requireOk(String step, Future<RigActionResult> result) async {
      final value = await result;
      if (value.isError) {
        throw StateError('$step failed: ${value.text}');
      }
      stdout.writeln('$step: ${value.text}');
    }

    await requireOk('install_app', driver.perform(IosInstallApp(appPath)));
    await requireOk('start_app', driver.perform(IosStartApp(bundleId)));

    final hierarchy = await session.client.source();
    final hierarchyJson = jsonEncode(hierarchy);
    if (hierarchyJson.isEmpty || hierarchyJson == 'null') {
      throw StateError('WDA returned an empty JSON accessibility hierarchy.');
    }
    stdout.writeln('ui_dump: ${hierarchyJson.length} JSON bytes');
    await requireOk('ui_dump', driver.perform(const IosUiDump()));

    final still = await driver.captureForAgent();
    if (still.isError ||
        still.imageBase64 == null ||
        still.imageBase64!.isEmpty) {
      throw StateError('iOS agent still failed: ${still.text}');
    }
    stdout.writeln(
      'screenshot: ${still.imageBase64!.length} base64 characters '
      '(${still.imageMediaType})',
    );

    final frames = await driver.openWatchStream(
      RigWatchRequest(size: session.display, fps: 2, quality: 60),
    );
    if (frames == null) {
      throw StateError('iOS watch lane returned no stream.');
    }
    final frame = await frames.first.timeout(const Duration(seconds: 15));
    if (frame.isEmpty) {
      throw StateError('iOS watch lane returned an empty MJPEG frame.');
    }
    stdout.writeln('watch: ${frame.length} MJPEG bytes');

    final centerX = session.display.width ~/ 2;
    final centerY = session.display.height ~/ 2;
    await requireOk('tap', driver.perform(IosTap(x: centerX, y: centerY)));
    await requireOk(
      'type',
      driver.perform(const IosType('control-center-smoke')),
    );
  } finally {
    await driver.dispose();
    await backend.close(session);
  }

  final listed = await Process.run('/usr/bin/xcrun', [
    'simctl',
    'list',
    'devices',
    '--json',
  ]);
  if (listed.exitCode != 0) {
    throw StateError('Could not verify simulator cleanup: ${listed.stderr}');
  }
  if ('${listed.stdout}'.contains(deviceName)) {
    throw StateError('Owned simulator still exists after close: $deviceName');
  }
  stdout.writeln('iOS rig smoke passed; $deviceName was deleted.');
}
