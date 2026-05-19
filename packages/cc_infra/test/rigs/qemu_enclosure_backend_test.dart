import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_infra/src/rigs/guest_agent_client.dart';
import 'package:cc_infra/src/rigs/qemu_enclosure_backend.dart';
import 'package:cc_infra/src/rigs/qmp_client.dart';
import 'package:cc_infra/src/rigs/rig_image_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The lifecycle paths are where a rig backend can do real damage: the sweep
/// deletes directories recursively and the teardown ladder decides whether a
/// hypervisor keeps running. Both used to be unconditional — the sweep removed
/// every directory it could see (so two servers sharing a data dir wiped each
/// other's LIVE overlays, and a QEMU whose state was deleted kept going), and
/// the ladder nested its escalations (so one throwing step skipped the kill).
/// These pin the guards that replaced that.
void main() {
  late Directory temp;
  late Directory dataDir;
  late Directory socketRoot;
  late _FakeProcessProbe probe;
  late QemuEnclosureBackend backend;

  String runRoot() => p.join(dataDir.path, 'rigs', 'run');
  String ccrigRoot() => p.join(socketRoot.path, 'ccrig');

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('cc-rig-backend-');
    dataDir = Directory(p.join(temp.path, 'data'))..createSync(recursive: true);
    socketRoot = Directory(p.join(temp.path, 'sock'))
      ..createSync(recursive: true);
    probe = _FakeProcessProbe();
    backend = QemuEnclosureBackend(
      dataDir: dataDir.path,
      images: RigImageStore(dataDir: dataDir.path),
      processProbe: probe,
      socketRoots: [socketRoot.path],
      ladder: const RigTeardownLadder(
        powerdown: Duration(milliseconds: 20),
        quit: Duration(milliseconds: 20),
        kill: Duration(milliseconds: 40),
        poll: Duration(milliseconds: 2),
      ),
    );
  });

  tearDown(() async {
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  /// Creates a candidate directory with a file in it and, optionally, an
  /// ownership marker.
  Directory candidate(
    String root,
    String rigId, {
    RigRuntimeOwner? owner,
    String? rawMarker,
  }) {
    final dir = Directory(p.join(root, rigId))..createSync(recursive: true);
    File(p.join(dir.path, 'overlay.qcow2')).writeAsStringSync('x' * 32);
    if (owner != null) {
      File(
        p.join(dir.path, RigRuntimeOwner.fileName),
      ).writeAsStringSync(jsonEncode(owner.toJson()));
    }
    if (rawMarker != null) {
      File(
        p.join(dir.path, RigRuntimeOwner.fileName),
      ).writeAsStringSync(rawMarker);
    }
    return dir;
  }

  RigRuntimeOwner owner({
    required String rigId,
    int? qemuPid,
    int serverPid = 999001,
    String instance = 'a-previous-run',
    String? command = 'cc_server',
  }) => RigRuntimeOwner(
    rigId: rigId,
    serverPid: serverPid,
    serverInstance: instance,
    serverCommand: command,
    qemuPid: qemuPid,
    createdAt: DateTime.now(),
  );

  group('sweepOrphanedRuntimes', () {
    test('removes a directory whose owner and hypervisor are both gone',
        () async {
      final dir = candidate(
        runRoot(),
        'rig-dead',
        owner: owner(rigId: 'rig-dead', qemuPid: 4242),
      );
      // Nothing registered in the probe: both pids read as gone.

      expect(await backend.sweepOrphanedRuntimes(), 1);
      expect(dir.existsSync(), isFalse);
      expect(probe.signalled, isEmpty);
    });

    test('kills a live QEMU BEFORE deleting the state it is running on',
        () async {
      // The old sweep deleted the overlay and left the hypervisor running with
      // its disk gone — a process holding gigabytes that answers to nobody.
      final dir = candidate(
        runRoot(),
        'rig-live',
        owner: owner(rigId: 'rig-live', qemuPid: 3131),
      );
      probe.alive[3131] =
          'qemu-system-aarch64 -name ccrig-rig-live -drive '
          'file=/x/rig-live/overlay.qcow2';
      probe.dieOnSignal.add(3131);
      var stateWasStillThereAtKill = false;
      probe.observe = (_) => stateWasStillThereAtKill = dir.existsSync();

      expect(await backend.sweepOrphanedRuntimes(), 1);
      expect(
        probe.signalled,
        [(3131, ProcessSignal.sigterm)],
        reason: 'A polite SIGTERM first; it left, so no SIGKILL was needed.',
      );
      expect(
        stateWasStillThereAtKill,
        isTrue,
        reason: 'The kill must happen BEFORE the delete, never after.',
      );
      expect(dir.existsSync(), isFalse);
    });

    test('escalates to SIGKILL when SIGTERM is ignored', () async {
      final dir = candidate(
        runRoot(),
        'rig-stubborn',
        owner: owner(rigId: 'rig-stubborn', qemuPid: 71),
      );
      probe.alive[71] = 'qemu-system-x86_64 -name ccrig-rig-stubborn';
      probe.dieOnSignal.add(-1); // nothing dies on SIGTERM
      probe.dieOnKill.add(71);

      expect(await backend.sweepOrphanedRuntimes(), 1);
      expect(probe.signalled, [
        (71, ProcessSignal.sigterm),
        (71, ProcessSignal.sigkill),
      ]);
      expect(dir.existsSync(), isFalse);
    });

    test('leaves a directory owned by a LIVE sibling server alone', () async {
      // Two servers sharing a data dir is the case that made the old sweep
      // destructive: it deleted a running VM's overlay out from under it.
      final dir = candidate(
        runRoot(),
        'rig-sibling',
        owner: owner(rigId: 'rig-sibling', qemuPid: 555, serverPid: 4321),
      );
      probe.alive[4321] = '/opt/cc/cc_server --data-dir /shared';
      probe.alive[555] = 'qemu-system-aarch64 -name ccrig-rig-sibling';

      expect(await backend.sweepOrphanedRuntimes(), 0);
      expect(dir.existsSync(), isTrue);
      expect(
        probe.signalled,
        isEmpty,
        reason: "A sibling's hypervisor must never be signalled.",
      );
    });

    test('sweeps a directory whose owner pid was recycled by something else',
        () async {
      // The pid is live but it is not the server that wrote the marker, so the
      // owner really is gone.
      final dir = candidate(
        runRoot(),
        'rig-recycled',
        owner: owner(rigId: 'rig-recycled', serverPid: 4321),
      );
      probe.alive[4321] = '/usr/bin/vim notes.md';

      expect(await backend.sweepOrphanedRuntimes(), 1);
      expect(dir.existsSync(), isFalse);
    });

    test('never signals a QEMU pid that was reused by an unrelated process',
        () async {
      final dir = candidate(
        runRoot(),
        'rig-reused',
        owner: owner(rigId: 'rig-reused', qemuPid: 88),
      );
      probe.alive[88] = '/usr/bin/vim rig-reused-notes.md';

      expect(await backend.sweepOrphanedRuntimes(), 1);
      expect(
        probe.signalled,
        isEmpty,
        reason:
            'The pid matches but the command line does not: signalling it '
            "would kill a stranger's process.",
      );
      expect(dir.existsSync(), isFalse);
    });

    test('leaves a directory whose QEMU survived SIGKILL', () async {
      final dir = candidate(
        runRoot(),
        'rig-immortal',
        owner: owner(rigId: 'rig-immortal', qemuPid: 12),
      );
      probe.alive[12] = 'qemu-system-x86_64 -name ccrig-rig-immortal';

      expect(await backend.sweepOrphanedRuntimes(), 0);
      expect(
        dir.existsSync(),
        isTrue,
        reason:
            'Removing the overlay of a hypervisor that would not die is the '
            'exact state this sweep exists to prevent.',
      );
    });

    test('skips a symlink planted in the runtime root', () async {
      final outside = Directory(p.join(temp.path, 'precious'))
        ..createSync(recursive: true);
      File(p.join(outside.path, 'keep.txt')).writeAsStringSync('do not delete');
      Directory(runRoot()).createSync(recursive: true);
      Link(p.join(runRoot(), 'sneaky')).createSync(outside.path);

      expect(await backend.sweepOrphanedRuntimes(), 0);
      expect(
        File(p.join(outside.path, 'keep.txt')).existsSync(),
        isTrue,
        reason: 'A recursive delete must never follow a symlink.',
      );
    });

    test('a candidate that cannot be probed does not abort the sweep',
        () async {
      final broken = candidate(
        runRoot(),
        'rig-broken',
        owner: owner(rigId: 'rig-broken', qemuPid: 7),
      );
      probe.throwFor.add(7);
      final fine = candidate(
        runRoot(),
        'rig-fine',
        owner: owner(rigId: 'rig-fine'),
      );

      expect(await backend.sweepOrphanedRuntimes(), 1);
      expect(
        broken.existsSync(),
        isTrue,
        reason: 'An unanswerable probe is "unknown", never a licence to delete.',
      );
      expect(fine.existsSync(), isFalse);
    });

    test('leaves a directory this very server process still owns', () async {
      // `sweepOrphanedRuntimes` is safe to call at any time, so a rig booted by
      // THIS process must survive it — including when its own pid is the one
      // in the marker.
      final dir = Directory(p.join(runRoot(), 'rig-mine'))
        ..createSync(recursive: true);
      await RigRuntimeOwner.forThisServer(
        rigId: 'rig-mine',
        qemuPid: 4040,
      ).writeTo(dir.path);
      probe.alive[4040] = 'qemu-system-aarch64 -name ccrig-rig-mine';

      expect(await backend.sweepOrphanedRuntimes(), 0);
      expect(dir.existsSync(), isTrue);
      expect(probe.signalled, isEmpty);
    });

    test('sweeps a directory that shares our pid but not our run', () async {
      // A dead predecessor whose pid the host handed back to us is NOT a live
      // sibling, and the instance id is the only thing that can tell them
      // apart.
      final dir = candidate(
        runRoot(),
        'rig-ghost',
        owner: owner(
          rigId: 'rig-ghost',
          serverPid: pid,
          instance: 'some-older-run',
          command: p.basename(Platform.resolvedExecutable),
        ),
      );

      expect(await backend.sweepOrphanedRuntimes(), 1);
      expect(dir.existsSync(), isFalse);
    });

    test('still sweeps an unmarked directory from before the marker existed',
        () async {
      final dir = candidate(runRoot(), 'rig-legacy');
      expect(await backend.sweepOrphanedRuntimes(), 1);
      expect(dir.existsSync(), isFalse);
    });

    test('treats an unreadable marker as unowned', () async {
      final dir = candidate(runRoot(), 'rig-corrupt', rawMarker: '{not json');
      expect(await backend.sweepOrphanedRuntimes(), 1);
      expect(dir.existsSync(), isFalse);
    });

    test('applies the same ownership rules to the ccrig socket namespace',
        () async {
      final mine = candidate(
        ccrigRoot(),
        'rig-old-sock',
        owner: owner(rigId: 'rig-old-sock'),
      );
      final sibling = candidate(
        ccrigRoot(),
        'rig-sibling-sock',
        owner: owner(rigId: 'rig-sibling-sock', serverPid: 4321),
      );
      probe.alive[4321] = '/opt/cc/cc_server --data-dir /shared';

      expect(await backend.sweepOrphanedRuntimes(), 1);
      expect(mine.existsSync(), isFalse);
      expect(
        sibling.existsSync(),
        isTrue,
        reason:
            'A shared /tmp is where two servers are GUARANTEED to collide, so '
            'the socket namespace needs the ownership check most of all.',
      );
    });

    test('refuses a ccrig namespace that is itself a symlink', () async {
      final outside = Directory(p.join(temp.path, 'elsewhere'))
        ..createSync(recursive: true);
      candidate(outside.path, 'rig-victim');
      Link(ccrigRoot()).createSync(outside.path);

      expect(await backend.sweepOrphanedRuntimes(), 0);
      expect(
        Directory(p.join(outside.path, 'rig-victim')).existsSync(),
        isTrue,
        reason:
            'A symlink planted at the namespace would redirect the sweep '
            'wherever the planter chose.',
      );
    });

    test('an absent runtime root is not an error', () async {
      expect(await backend.sweepOrphanedRuntimes(), 0);
    });
  });

  group('delete guard', () {
    test('permits only directories inside the rig runtime and socket roots',
        () {
      expect(backend.isRigDeletablePath(p.join(runRoot(), 'rig-a')), isTrue);
      expect(backend.isRigDeletablePath(p.join(ccrigRoot(), 'rig-a')), isTrue);
      expect(
        backend.isRigDeletablePath('/tmp/ccrig/rig-a'),
        isTrue,
        reason:
            'buildRigSocketPath falls back to /tmp when every configured root '
            'would overflow sun_path, so sockets can legitimately be there.',
      );
    });

    test('refuses the roots themselves, the data dir and anything outside', () {
      for (final hostile in [
        '/',
        '/etc',
        temp.path,
        dataDir.path,
        runRoot(),
        ccrigRoot(),
        '',
        p.join(temp.path, 'elsewhere', 'rig-a'),
      ]) {
        expect(
          backend.isRigDeletablePath(hostile),
          isFalse,
          reason: '$hostile must never reach a recursive delete.',
        );
      }
    });

    test('refuses the image store, including by traversal', () {
      final images = RigImageStore(dataDir: dataDir.path);
      expect(backend.isRigDeletablePath(images.root), isFalse);
      expect(
        backend.isRigDeletablePath(p.join(images.root, 'cc-exec-linux')),
        isFalse,
        reason:
            'A base image is gigabytes an operator downloaded once; no rig '
            'lifecycle path may delete one.',
      );
      expect(
        backend.isRigDeletablePath(
          p.join(runRoot(), '..', 'images', 'cc-exec-linux'),
        ),
        isFalse,
        reason: 'A path that climbs out of the runtime root is still outside it.',
      );
    });
  });

  group('destroy', () {
    test('escalates past a throwing step and still kills the process',
        () async {
      // Nested try/catch meant a QMP client that threw on `quit` took the
      // SIGKILL with it and left the hypervisor running.
      final machine = _machine(
        rigId: 'rig-teardown',
        runtimeDir: p.join(runRoot(), 'rig-teardown'),
        socketDir: p.join(ccrigRoot(), 'rig-teardown'),
        qmp: _FakeQmp(failPowerdown: true, failQuit: true),
        process: _FakeProcess(pid: 6001),
      );
      Directory(machine.runtimeDir).createSync(recursive: true);
      Directory(machine.socketDir).createSync(recursive: true);

      await backend.destroy(machine);

      expect((machine.process as _FakeProcess).signals, [ProcessSignal.sigkill]);
      expect(Directory(machine.runtimeDir).existsSync(), isFalse);
      expect(Directory(machine.socketDir).existsSync(), isFalse);
    });

    test('removes the runtime AND socket directories once the process is dead',
        () async {
      final machine = _machine(
        rigId: 'rig-clean',
        runtimeDir: p.join(runRoot(), 'rig-clean'),
        socketDir: p.join(ccrigRoot(), 'rig-clean'),
        process: _FakeProcess(pid: 6002),
      );
      Directory(machine.runtimeDir).createSync(recursive: true);
      File(
        p.join(machine.runtimeDir, 'overlay.qcow2'),
      ).writeAsStringSync('x' * 64);
      Directory(machine.socketDir).createSync(recursive: true);

      await backend.destroy(machine);

      expect(Directory(machine.runtimeDir).existsSync(), isFalse);
      expect(
        Directory(machine.socketDir).existsSync(),
        isFalse,
        reason:
            'The socket dir sits OUTSIDE the runtime tree, so removing the '
            'runtime tree cannot reach it.',
      );
    });

    test('is idempotent — a second destroy neither throws nor re-kills',
        () async {
      final machine = _machine(
        rigId: 'rig-twice',
        runtimeDir: p.join(runRoot(), 'rig-twice'),
        socketDir: p.join(ccrigRoot(), 'rig-twice'),
        process: _FakeProcess(pid: 6003),
      );
      Directory(machine.runtimeDir).createSync(recursive: true);
      Directory(machine.socketDir).createSync(recursive: true);

      await backend.destroy(machine);
      await backend.destroy(machine);

      expect(Directory(machine.runtimeDir).existsSync(), isFalse);
      expect(probe.signalled, isEmpty);
    });

    test('a delete that fails is logged, not thrown out of destroy', () async {
      // Teardown must finish: the caller's only alternative is leaking a VM.
      final machine = _machine(
        rigId: 'rig-gone',
        runtimeDir: p.join(runRoot(), 'rig-gone'),
        socketDir: p.join(ccrigRoot(), 'rig-gone'),
        qmp: _FakeQmp(failPowerdown: true, failQuit: true, failClose: true),
        process: _FakeProcess(pid: 6004),
      );
      // Neither directory exists at all.
      await expectLater(backend.destroy(machine), completes);
    });

    test('falls back to the recorded pid when the handle is unusable',
        () async {
      // The pathological case: `kill` reports no such process and the exit
      // code never arrives, but the pidfile still names a live QEMU.
      final machine = _machine(
        rigId: 'rig-orphan',
        runtimeDir: p.join(runRoot(), 'rig-orphan'),
        socketDir: p.join(ccrigRoot(), 'rig-orphan'),
        qmp: _FakeQmp(failPowerdown: true, failQuit: true),
        process: _FakeProcess(pid: 6005, deaf: true),
      );
      Directory(machine.runtimeDir).createSync(recursive: true);
      Directory(machine.socketDir).createSync(recursive: true);
      File(p.join(machine.runtimeDir, RigRuntimeOwner.fileName))
          .writeAsStringSync(
        jsonEncode(
          owner(rigId: 'rig-orphan', qemuPid: 9090).toJson(),
        ),
      );
      probe.alive[9090] = 'qemu-system-aarch64 -name ccrig-rig-orphan';
      probe.dieOnSignal.add(9090);

      await backend.destroy(machine);

      expect(probe.signalled, [(9090, ProcessSignal.sigterm)]);
      expect(Directory(machine.runtimeDir).existsSync(), isFalse);
    });

    test('keeps the runtime directory when the hypervisor survives everything',
        () async {
      final machine = _machine(
        rigId: 'rig-undead',
        runtimeDir: p.join(runRoot(), 'rig-undead'),
        socketDir: p.join(ccrigRoot(), 'rig-undead'),
        qmp: _FakeQmp(failPowerdown: true, failQuit: true),
        process: _FakeProcess(pid: 6006, deaf: true),
      );
      Directory(machine.runtimeDir).createSync(recursive: true);
      Directory(machine.socketDir).createSync(recursive: true);
      File(p.join(machine.runtimeDir, RigRuntimeOwner.fileName))
          .writeAsStringSync(
        jsonEncode(owner(rigId: 'rig-undead', qemuPid: 9191).toJson()),
      );
      probe.alive[9191] = 'qemu-system-aarch64 -name ccrig-rig-undead';

      await backend.destroy(machine);

      expect(
        Directory(machine.runtimeDir).existsSync(),
        isTrue,
        reason:
            'Deleting the overlay under a running hypervisor is the hazard the '
            'sweep was fixed for; the next boot sweep kills first.',
      );
    });

    test('refuses to delete a runtime directory outside the rig roots',
        () async {
      // A refactor bug that hands teardown the data dir must not be able to
      // delete it.
      final hostileRuntime = Directory(p.join(temp.path, 'not-a-rig'))
        ..createSync(recursive: true);
      File(p.join(hostileRuntime.path, 'important')).writeAsStringSync('keep');
      final hostileSocket = Directory(p.join(temp.path, 'not-a-socket'))
        ..createSync(recursive: true);

      await backend.destroy(
        _machine(
          rigId: 'rig-hostile',
          runtimeDir: hostileRuntime.path,
          socketDir: hostileSocket.path,
          process: _FakeProcess(pid: 6007),
        ),
      );

      expect(hostileRuntime.existsSync(), isTrue);
      expect(
        File(p.join(hostileRuntime.path, 'important')).existsSync(),
        isTrue,
      );
      expect(hostileSocket.existsSync(), isTrue);
    });
  });

  group('commandLineMatchesRig', () {
    // This decides whether a recorded pid gets SIGTERM then SIGKILL, so the
    // false positives matter more than the false negatives: a missed
    // hypervisor leaks a VM, a wrong match kills whatever now holds that pid.
    const cmd = 'qemu-system-aarch64 -name ccrig-rig-7 -drive '
        'file=/d/rigs/run/rig-7/overlay.qcow2';

    test('matches this rig\'s hypervisor', () {
      expect(
        QemuEnclosureBackend.commandLineMatchesRig(cmd, 'rig-7'),
        isTrue,
      );
    });

    test('matches an absolute binary path', () {
      expect(
        QemuEnclosureBackend.commandLineMatchesRig(
          '/opt/homebrew/bin/qemu-system-aarch64 -name ccrig-rig-7',
          'rig-7',
        ),
        isTrue,
      );
    });

    test('refuses a process that merely MENTIONS the rig', () {
      for (final line in const [
        'vim rig-7.md',
        'grep rig-7 /var/log/cc.log',
        'tail -f /d/rigs/run/qemu-stderr-rig-7',
      ]) {
        expect(
          QemuEnclosureBackend.commandLineMatchesRig(line, 'rig-7'),
          isFalse,
          reason: line,
        );
      }
    });

    test('refuses qemu-img on this rig\'s own overlay', () {
      // The exact command an operator runs to inspect an orphaned overlay
      // after a crash — it contains "qemu" and the rig id both, which is what
      // the old substring pair matched.
      expect(
        QemuEnclosureBackend.commandLineMatchesRig(
          'qemu-img info /d/rigs/run/rig-7/overlay.qcow2',
          'rig-7',
        ),
        isFalse,
      );
    });

    test("refuses another rig's hypervisor", () {
      expect(
        QemuEnclosureBackend.commandLineMatchesRig(
          'qemu-system-aarch64 -name ccrig-rig-8',
          'rig-7',
        ),
        isFalse,
        reason: "Killing another rig's hypervisor reads as a crash to whoever "
            'was driving it.',
      );
    });

    test('refuses a rig id that is only a PREFIX of the running one', () {
      // Whole-token matching, not `contains`: two ids sharing a prefix must
      // not share a reaper.
      expect(
        QemuEnclosureBackend.commandLineMatchesRig(
          'qemu-system-x86_64 -name ccrig-rig-70',
          'rig-7',
        ),
        isFalse,
      );
    });

    test('refuses an empty rig id and an empty command line', () {
      expect(
        QemuEnclosureBackend.commandLineMatchesRig('qemu-system-x86_64', ''),
        isFalse,
      );
      expect(
        QemuEnclosureBackend.commandLineMatchesRig('', 'rig-7'),
        isFalse,
      );
    });
  });

  group('runHostTool', () {
    test('a non-zero exit throws a typed error naming the tool and its stderr',
        () async {
      // A `chmod` whose exit code nobody read is the documented crash-loop.
      await expectLater(
        QemuEnclosureBackend.runHostTool('sh', [
          '-c',
          'echo "chmod: nope" >&2; exit 3',
        ], hint: 'do the thing'),
        throwsA(
          isA<RigToolException>()
              .having((e) => e.tool, 'tool', 'sh')
              .having((e) => e.exitCode, 'exitCode', 3)
              .having((e) => e.stderr, 'stderr', contains('chmod: nope'))
              .having((e) => e.message, 'message', contains('do the thing')),
        ),
      );
    }, skip: Platform.isWindows ? 'POSIX shell only' : null);

    test('a tool that cannot be started is named, not swallowed', () async {
      await expectLater(
        QemuEnclosureBackend.runHostTool('cc-no-such-tool', const []),
        throwsA(
          isA<RigToolException>()
              .having((e) => e.tool, 'tool', 'cc-no-such-tool')
              .having((e) => e.exitCode, 'exitCode', isNull)
              .having((e) => e.message, 'message', contains('on PATH')),
        ),
      );
    });

    test('is a RigLaunchException, so existing catches still see it', () async {
      await expectLater(
        QemuEnclosureBackend.runHostTool('cc-no-such-tool', const []),
        throwsA(isA<RigLaunchException>()),
      );
    });

    test('a zero exit returns the result', () async {
      final result = await QemuEnclosureBackend.runHostTool('sh', [
        '-c',
        'echo ok',
      ]);
      expect('${result.stdout}'.trim(), 'ok');
    }, skip: Platform.isWindows ? 'POSIX shell only' : null);
  });

  group('RigRuntimeOwner', () {
    test('round-trips through its wire form', () async {
      final dir = Directory(p.join(temp.path, 'marker'))
        ..createSync(recursive: true);
      const written = RigRuntimeOwner(
        rigId: 'rig-1',
        serverPid: 42,
        serverInstance: 'abc',
        serverCommand: 'cc_server',
        qemuPid: 43,
      );
      await written.writeTo(dir.path);

      final read = RigRuntimeOwner.readSync(dir.path);
      expect(read, isNotNull);
      expect(read!.rigId, 'rig-1');
      expect(read.serverPid, 42);
      expect(read.qemuPid, 43);
      expect(read.serverInstance, 'abc');
      expect(read.serverCommand, 'cc_server');
      expect(
        File(p.join(dir.path, '${RigRuntimeOwner.fileName}.tmp')).existsSync(),
        isFalse,
        reason: 'The marker is renamed into place, never left half-written.',
      );
    });

    test('an absent marker reads as unowned', () {
      expect(RigRuntimeOwner.readSync(temp.path), isNull);
    });
  });
}

/// A [RigProcessProbe] whose answers the test dictates.
class _FakeProcessProbe implements RigProcessProbe {
  /// pid -> command line, for processes that are alive.
  final Map<int, String> alive = {};

  /// pids that exit on SIGTERM.
  final Set<int> dieOnSignal = {};

  /// pids that exit on SIGKILL.
  final Set<int> dieOnKill = {};

  /// pids whose probe blows up (a host with no `ps`, a /proc read that races).
  final Set<int> throwFor = {};

  final List<(int, ProcessSignal)> signalled = [];

  /// Called the moment a signal is delivered, so a test can observe the world
  /// as it was at that instant (ordering, not just outcome).
  void Function(int pid)? observe;

  @override
  Future<String?> commandLine(int pid) async {
    if (throwFor.contains(pid)) {
      throw const ProcessException('ps', [], 'no such tool');
    }
    return alive[pid];
  }

  @override
  Future<bool> isAlive(int pid) async {
    if (throwFor.contains(pid)) {
      throw const ProcessException('ps', [], 'no such tool');
    }
    return alive.containsKey(pid);
  }

  @override
  Future<bool> signal(int pid, ProcessSignal signal) async {
    signalled.add((pid, signal));
    observe?.call(pid);
    final dies = signal == ProcessSignal.sigkill
        ? dieOnKill.contains(pid)
        : dieOnSignal.contains(pid);
    if (dies) {
      alive.remove(pid);
    }
    return true;
  }
}

QemuMachine _machine({
  required String rigId,
  required String runtimeDir,
  required String socketDir,
  _FakeQmp? qmp,
  required _FakeProcess process,
}) => QemuMachine(
  rigId: rigId,
  process: process,
  qmp: qmp ?? _FakeQmp(),
  agent: _FakeGuestAgent(),
  backend: EnclosureBackend.qemuTcg,
  sshPort: 0,
  agentPort: 0,
  overlayPath: p.join(runtimeDir, 'overlay.qcow2'),
  runtimeDir: runtimeDir,
  socketDir: socketDir,
  guestSecret: 'secret',
  display: RigDisplaySize(1280, 800),
);

class _FakeProcess implements Process {
  _FakeProcess({required this.pid, this.deaf = false});

  @override
  final int pid;

  /// A handle that never reports an exit — the case the pidfile fallback is
  /// for.
  final bool deaf;

  final List<ProcessSignal> signals = [];
  final Completer<int> _exit = Completer<int>();

  @override
  Future<int> get exitCode => _exit.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    signals.add(signal);
    if (deaf) {
      return false;
    }
    if (!_exit.isCompleted) {
      _exit.complete(-9);
    }
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} is not used here');
}

class _FakeQmp implements QmpClient {
  _FakeQmp({
    this.failPowerdown = false,
    this.failQuit = false,
    this.failClose = false,
  });

  final bool failPowerdown;
  final bool failQuit;
  final bool failClose;

  @override
  Future<void> systemPowerdown() async {
    if (failPowerdown) {
      throw const QmpException('socket is gone');
    }
  }

  @override
  Future<void> quit() async {
    if (failQuit) {
      throw const QmpException('socket is gone');
    }
  }

  @override
  Future<void> close() async {
    if (failClose) {
      throw const QmpException('already closed');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} is not used here');
}

class _FakeGuestAgent implements GuestAgentClient {
  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} is not used here');
}
