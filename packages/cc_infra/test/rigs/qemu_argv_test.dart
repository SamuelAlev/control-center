import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/src/rigs/qemu_argv.dart';
import 'package:test/test.dart';

/// The QEMU command line is where a rig's containment actually lives. A
/// missing `restrict=on` or a forward bound to 0.0.0.0 does not fail any
/// test that only checks behaviour — the rig boots, the agent drives it, and
/// the enclosure is simply not one. So the flags are pinned here.
void main() {
  QemuLaunchPlan plan({
    RigSurface surface = RigSurface.computer,
    EnclosureBackend backend = EnclosureBackend.qemuHvf,
    int? httpProxyPort = 4001,
    int? socksProxyPort = 4002,
    int? credentialPort = 4003,
    String? firmwarePath,
  }) => QemuLaunchPlan(
    rigId: 'abc',
    backend: backend,
    overlayPath: '/data/rigs/run/abc/overlay.qcow2',
    memoryMb: 2048,
    cpuCount: 2,
    display: RigDisplaySize(1280, 800),
    qmpSocketPath: '/data/rigs/run/abc/qmp.sock',
    sshHostPort: 5001,
    agentHostPort: 5002,
    surface: surface,
    httpProxyHostPort: httpProxyPort,
    socksProxyHostPort: socksProxyPort,
    credentialHostPort: credentialPort,
    firmwarePath: firmwarePath,
  );

  String netdevOf(List<String> argv) {
    final i = argv.indexOf('-netdev');
    expect(i, greaterThanOrEqualTo(0), reason: 'a rig must have a netdev');
    return argv[i + 1];
  }

  group('network containment', () {
    test('the guest NIC is restricted', () {
      final netdev = netdevOf(buildQemuArgv(plan()));
      expect(
        netdev,
        contains('restrict=on'),
        reason:
            'Without restrict=on the guest reaches the host LAN and the '
            'internet directly, and every egress control in this system is '
            'decoration.',
      );
    });

    test('every host-facing forward binds loopback explicitly', () {
      final netdev = netdevOf(buildQemuArgv(plan()));
      final forwards = netdev
          .split(',')
          .where((part) => part.startsWith('hostfwd='))
          .toList();
      expect(forwards, isNotEmpty);
      for (final forward in forwards) {
        expect(
          forward,
          startsWith('hostfwd=tcp:127.0.0.1:'),
          reason:
              'A bare hostfwd listens on 0.0.0.0 and publishes a shell on the '
              'rig to the local network. Found: $forward',
        );
      }
    });

    test('guest egress is only the proxies and the credential broker', () {
      final netdev = netdevOf(buildQemuArgv(plan()));
      final guestForwards = netdev
          .split(',')
          .where((part) => part.startsWith('guestfwd='))
          .toList();
      expect(guestForwards, hasLength(3));
      expect(
        guestForwards.every((f) => f.contains('-tcp:127.0.0.1:')),
        isTrue,
        reason: 'A guest hole must terminate on host loopback, nowhere else.',
      );
    });

    test('a rig with no proxies gets no outbound holes at all', () {
      final netdev = netdevOf(
        buildQemuArgv(
          plan(httpProxyPort: null, socksProxyPort: null, credentialPort: null),
        ),
      );
      expect(netdev, contains('restrict=on'));
      expect(
        netdev,
        isNot(contains('guestfwd=')),
        reason:
            'No proxy running means the guest reaches nothing — that is the '
            'deny-by-default floor, not a reason to open the network.',
      );
    });
  });

  group('storage containment', () {
    test('the machine boots the per-session overlay, never a base image', () {
      final argv = buildQemuArgv(plan());
      final drive = argv[argv.indexOf('-drive') + 1];
      expect(drive, contains('overlay.qcow2'));
      expect(drive, contains('format=qcow2'));
    });

    test('no host filesystem is passed through', () {
      final argv = buildQemuArgv(plan());
      expect(
        argv,
        isNot(contains('-virtfs')),
        reason: 'The worktree is copied in, never mounted.',
      );
      expect(argv, isNot(contains('-fsdev')));
    });
  });

  group('input and display', () {
    test('a desktop rig gets an absolute pointing device', () {
      final argv = buildQemuArgv(plan());
      expect(
        argv.join(' '),
        contains('virtio-tablet-pci'),
        reason:
            'A relative mouse cannot implement "click at (412, 180)"; the '
            'pointer drifts out of sync with the screenshots the model sees.',
      );
    });

    test('the boot display matches the requested mode', () {
      final argv = buildQemuArgv(plan());
      expect(argv.join(' '), contains('xres=1280'));
      expect(argv.join(' '), contains('yres=800'));
    });

    test('every DISPLAY surface gets absolute pointer + keyboard', () {
      // The invariant, not the absence: a machine with a screen a human
      // watches must be clickable, and `virtio-tablet-pci` is what makes
      // "click at (412, 180)" expressible at all — a relative PS/2 mouse
      // cannot implement it.
      for (final surface in const [RigSurface.computer, RigSurface.mobile]) {
        final argv = buildQemuArgv(plan(surface: surface)).join(' ');
        expect(argv, contains('virtio-tablet-pci'), reason: surface.wire);
        expect(argv, contains('virtio-keyboard-pci'), reason: surface.wire);
        expect(argv, contains('virtio-gpu-pci'), reason: surface.wire);
      }
    });

    test('a surface without a display needs no GPU or input devices', () {
      final argv = buildQemuArgv(plan(surface: RigSurface.browser));
      expect(argv.join(' '), isNot(contains('virtio-gpu')));
      expect(argv.join(' '), isNot(contains('virtio-tablet')));
    });

    test('no host window is ever opened', () {
      final argv = buildQemuArgv(plan());
      final display = argv[argv.indexOf('-display') + 1];
      expect(
        display,
        'none',
        reason:
            'A rig that opened a window on the operator\'s desktop would be '
            'startling on a laptop and unusable on a headless server.',
      );
    });
  });

  group('accelerator selection', () {
    test('each backend asks for its own accelerator', () {
      for (final (backend, accel) in [
        (EnclosureBackend.qemuHvf, 'hvf'),
        (EnclosureBackend.qemuKvm, 'kvm'),
        (EnclosureBackend.qemuTcg, 'tcg'),
      ]) {
        final argv = buildQemuArgv(plan(backend: backend));
        expect(argv[argv.indexOf('-accel') + 1], accel);
      }
    });

    test('an explicit CPU model rides along with the accelerator', () {
      // Recent QEMU resolves a default under hvf/kvm; older builds refuse the
      // aarch64 virt machine's 32-bit default CPU outright. host/max is
      // correct everywhere, so it is always stated.
      for (final (backend, cpu) in [
        (EnclosureBackend.qemuHvf, 'host'),
        (EnclosureBackend.qemuKvm, 'host'),
        (EnclosureBackend.qemuTcg, 'max'),
      ]) {
        final argv = buildQemuArgv(plan(backend: backend));
        expect(argv[argv.indexOf('-cpu') + 1], cpu);
      }
    });
  });

  group('firmware', () {
    test('a plan with firmware boots through it', () {
      final argv = buildQemuArgv(
        plan(firmwarePath: '/opt/qemu/share/qemu/edk2-aarch64-code.fd'),
      );
      expect(
        argv[argv.indexOf('-bios') + 1],
        '/opt/qemu/share/qemu/edk2-aarch64-code.fd',
        reason:
            'The aarch64 virt machine has NO built-in firmware. Without '
            '-bios the vCPU starts on empty memory and the guest never '
            'executes an instruction — the boot does not fail, it silently '
            'does nothing until the readiness probe gives up.',
      );
    });

    test('no firmware flag when the binary carries its own default', () {
      expect(buildQemuArgv(plan()), isNot(contains('-bios')));
    });

    test('aarch64 requires EDK2, x86_64 uses built-in SeaBIOS', () {
      expect(qemuFirmwareFileFor('arm64'), 'edk2-aarch64-code.fd');
      expect(qemuFirmwareFileFor('aarch64'), 'edk2-aarch64-code.fd');
      expect(qemuFirmwareFileFor('x64'), isNull);
    });
  });

  group('binary + machine selection', () {
    test('the architecture picks the binary', () {
      expect(qemuBinaryFor('arm64'), 'qemu-system-aarch64');
      expect(qemuBinaryFor('x64'), 'qemu-system-x86_64');
    });

    test('aarch64 always names a machine', () {
      // QEMU exits with "no machine specified" on aarch64 without one, so a
      // null here would be a boot failure rather than a default.
      expect(qemuMachineFor('arm64'), isNotNull);
      expect(qemuMachineFor('x64'), isNull);
    });
  });

  group('control socket path', () {
    // The bug this pins: the QMP socket used to live in the rig runtime
    // directory, under an operator-chosen data dir. On a checkout one level
    // deeper than the developer's, the path passed 104 bytes and QEMU refused
    // to start — every rig, every surface, with no degraded mode.
    const rigId = '2a1e10b2-0dd5-411e-9089-48cb212ccfbe';

    test('a deep data directory can no longer produce a too-long path', () {
      final path = buildRigSocketPath(
        candidateRoots: defaultRigSocketRoots({
          'TMPDIR': '/Users/somebody/Library/Containers/com.example.app/Data/tmp',
        }),
        rigId: rigId,
      );
      expect(path.length, lessThan(kMaxUnixSocketPathBytes));
    });

    test('the real failing path from the field now fits', () {
      // The reported failure was 112 bytes.
      const reported =
          '/Users/samuel.alev/dev/control-center/apps/cc_server/data/rigs/run/'
          '$rigId/qmp.sock';
      expect(reported.length, greaterThan(kMaxUnixSocketPathBytes));
      final fixed = buildRigSocketPath(
        candidateRoots: defaultRigSocketRoots(const {}),
        rigId: rigId,
      );
      expect(fixed.length, lessThan(kMaxUnixSocketPathBytes));
    });

    test('every root is rejected until one fits, /tmp being the last resort',
        () {
      final path = buildRigSocketPath(
        candidateRoots: ['/${'x' * 200}', '/tmp'],
        rigId: rigId,
      );
      expect(path, startsWith('/tmp/ccrig/'));
      expect(path.length, lessThan(kMaxUnixSocketPathBytes));
    });

    test('the rig id is never truncated', () {
      // Two rigs sharing a shortened prefix would share a control socket, and
      // the second would silently clobber the first.
      final path = buildRigSocketPath(
        candidateRoots: defaultRigSocketRoots(const {}),
        rigId: rigId,
      );
      expect(path, contains(rigId));
    });

    test('a private per-user root is preferred over shared /tmp', () {
      final path = buildRigSocketPath(
        candidateRoots: defaultRigSocketRoots({'XDG_RUNTIME_DIR': '/run/user/1000'}),
        rigId: rigId,
      );
      expect(path, startsWith('/run/user/1000/ccrig/'));
    });
  });

  group('per-session overlay', () {
    // This is where "a rig cannot change what the next rig boots from" is
    // actually decided, and it is decided by three flags nobody would notice
    // going missing — the rig boots either way.
    const base = '/data/rigs/images/desktop/disk.qcow2';
    const overlay = '/data/rigs/run/abc/overlay.qcow2';

    test('the base image is the BACKING file, not the target', () {
      final args = buildQemuOverlayArgs(basePath: base, overlayPath: overlay);
      final backingAt = args.indexOf('-b');
      expect(backingAt, greaterThanOrEqualTo(0), reason: 'no backing file');
      expect(
        args[backingAt + 1],
        base,
        reason:
            'Without -b the overlay is a blank disk and the rig boots to '
            'nothing; with the base as the TARGET the guest writes straight '
            'into the shared image and every later rig inherits it.',
      );
      expect(args.last, overlay);
    });

    test('both formats are stated explicitly', () {
      final args = buildQemuOverlayArgs(basePath: base, overlayPath: overlay);
      // qemu-img refuses to PROBE a backing file's format, so omitting -F
      // fails the create on current QEMU rather than guessing.
      expect(args, containsAllInOrder(['-f', 'qcow2']));
      expect(args, containsAllInOrder(['-F', 'qcow2']));
    });

    test('it is a create, never anything else', () {
      expect(
        buildQemuOverlayArgs(basePath: base, overlayPath: overlay).first,
        'create',
      );
    });
  });
}
