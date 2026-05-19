import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig_action_log_entry.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/repositories/rig_repository.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/browser_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/computer_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/src/rigs/cdp_client.dart';
import 'package:cc_infra/src/rigs/guest_agent_client.dart';
import 'package:cc_infra/src/rigs/qemu_enclosure_backend.dart';
import 'package:cc_infra/src/rigs/qmp_client.dart';
import 'package:cc_infra/src/rigs/rig_drivers.dart';
import 'package:cc_infra/src/rigs/rig_image_store.dart';
import 'package:cc_infra/src/rigs/rig_service.dart';
import 'package:cc_infra/src/rigs/smolvm_enclosure_backend.dart';
import 'package:test/test.dart';

/// An in-memory [RigRepository].
class _FakeRigRepository implements RigRepository {
  final Map<String, Rig> rigs = {};
  final List<RigActionLogEntry> actionLog = [];
  int _seq = 0;

  @override
  Future<void> save(String workspaceId, Rig rig) async {
    rigs[rig.id] = rig;
  }

  @override
  Future<Rig?> getById(String workspaceId, String rigId) async {
    final rig = rigs[rigId];
    return rig != null && rig.workspaceId == workspaceId ? rig : null;
  }

  @override
  Future<List<Rig>> list(
    String workspaceId, {
    bool includeClosed = true,
  }) async => rigs.values.where((r) => r.workspaceId == workspaceId).toList();

  @override
  Future<List<Rig>> listLive(String workspaceId) async => rigs.values
      .where((r) => r.workspaceId == workspaceId && r.status.isLive)
      .toList();

  @override
  Future<List<Rig>> listAllLive() async =>
      rigs.values.where((r) => r.status.isLive).toList();

  @override
  Stream<List<Rig>> watch(String workspaceId) => Stream.value(
    rigs.values.where((r) => r.workspaceId == workspaceId).toList(),
  );

  @override
  Future<RigActionLogEntry> appendAction(
    String workspaceId,
    RigActionLogEntry entry,
  ) async {
    final stamped = RigActionLogEntry(
      id: entry.id,
      workspaceId: entry.workspaceId,
      rigId: entry.rigId,
      seq: ++_seq,
      verb: entry.verb,
      args: entry.args,
      summary: entry.summary,
      actor: entry.actor,
      isTakeOver: entry.isTakeOver,
      isError: entry.isError,
      resultText: entry.resultText,
      createdAt: entry.createdAt,
    );
    actionLog.add(stamped);
    return stamped;
  }

  @override
  Future<List<RigActionLogEntry>> actions(
    String workspaceId,
    String rigId, {
    int limit = 200,
  }) async => actionLog.where((a) => a.rigId == rigId).toList();

  @override
  Stream<List<RigActionLogEntry>> watchActions(
    String workspaceId,
    String rigId, {
    int limit = 200,
  }) => Stream.value(actionLog.where((a) => a.rigId == rigId).toList());

  @override
  Future<int> purgeClosedBefore(String workspaceId, DateTime before) async => 0;
}

/// A backend that hands out inert machines, optionally holding `launch` open.
///
/// The close-during-boot window is only reachable when the launch can be
/// suspended: with a real backend the machine either exists before the close
/// or the launch has already failed, and the leak lives strictly between the
/// two.
class _FakeQemu extends QemuEnclosureBackend {
  _FakeQemu({this.gate})
    : super(
        dataDir: '/nonexistent-rig-root',
        images: RigImageStore(dataDir: '/nonexistent-rig-root'),
      );

  /// Held until the test completes it. Null launches immediately.
  final Completer<void>? gate;

  final List<String> launched = [];
  final List<String> destroyed = [];

  @override
  Future<RigBackendCapabilities> probe({bool refresh = false}) async =>
      const RigBackendCapabilities(
        backend: EnclosureBackend.qemuHvf,
        available: true,
        surfaces: {RigSurface.computer},
      );

  @override
  Future<QemuMachine> launch({
    required String rigId,
    required RigSpec spec,
    void Function(String step)? onProgress,
  }) async {
    await gate?.future;
    launched.add(rigId);
    return QemuMachine(
      rigId: rigId,
      process: _FakeProcess(),
      qmp: _FakeQmp(),
      agent: _FakeGuestAgent(),
      backend: EnclosureBackend.qemuHvf,
      sshPort: 0,
      agentPort: 0,
      overlayPath: '/nonexistent-rig-root/overlay.qcow2',
      runtimeDir: '/nonexistent-rig-root/run',
      socketDir: '/nonexistent-rig-root/sock',
      guestSecret: 's',
      display: RigDisplaySize(1280, 800),
    );
  }

  @override
  Future<void> destroy(QemuMachine machine) async =>
      destroyed.add(machine.rigId);

  @override
  Future<int> sweepOrphanedRuntimes() async => 0;
}

/// The microVM side of the enclosure pair.
///
/// Inert in exactly the way `_FakeQemu` is: machines are fake processes, and
/// an exec rig booted through it never touches a hypervisor. The desktop
/// tests above drive QEMU; the microVM group below drives this.
class _FakeSmolvm extends SmolvmEnclosureBackend {
  _FakeSmolvm() : super(dataDir: '/nonexistent-rig-root');

  final List<String> launched = [];
  final List<String> destroyed = [];

  /// The spec each [launch] received, in order.
  final List<RigSpec> specs = [];

  /// So `shellArgvFor` has a binary to hand the terminal path.
  @override
  String? get resolvedBinary => '/fake/smolvm';

  @override
  Future<RigBackendCapabilities> probe({bool refresh = false}) async =>
      const RigBackendCapabilities(
        backend: EnclosureBackend.smolvm,
        available: true,
        surfaces: {RigSurface.browser},
        supportsTerminals: true,
      );

  @override
  Future<SmolvmMachine> launch({
    required String rigId,
    required RigSpec spec,
    String? imageOverride,
    void Function(String step)? onProgress,
  }) async {
    launched.add(rigId);
    specs.add(spec);
    return SmolvmMachine(
      rigId: rigId,
      name: smolvmMachineNameFor(rigId),
      process: _FakeProcess(),
      guestSecret: 's',
      runtimeDir: '/nonexistent-rig-root/run',
      display: RigDisplaySize(1280, 800),
      devtoolsPort: spec.surface == RigSurface.browser ? 9222 : null,
    );
  }

  @override
  Future<void> destroy(SmolvmMachine machine) async =>
      destroyed.add(machine.rigId);

  @override
  Future<int> sweepOrphanedRuntimes() async => 0;
}

class _FakeProcess implements Process {
  @override
  Future<int> get exitCode => Completer<int>().future;

  // Everything else would be a real hypervisor's; nothing under test calls it.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQmp implements QmpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGuestAgent implements GuestAgentClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The same seam `cdp_client_test.dart` uses: canned replies keyed by CDP
/// method, so a service test can drive a real [BrowserRigDriver] without
/// Chromium.
class _FakeCdpSocket implements CdpSocket {
  final StreamController<dynamic> _incoming =
      StreamController<dynamic>.broadcast();

  final List<Map<String, dynamic>> sent = [];
  final Map<String, Map<String, dynamic>> autoReply = {};

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  void add(String data) {
    final decoded = jsonDecode(data) as Map<String, dynamic>;
    sent.add(decoded);
    final reply = autoReply[decoded['method']];
    if (reply != null) {
      scheduleMicrotask(
        () => _incoming.add(jsonEncode({'id': decoded['id'], 'result': reply})),
      );
    }
  }

  @override
  Future<void> close() async {
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }

  /// Pushes a raw frame from the "browser" (an event, not a reply).
  void push(Map<String, dynamic> frame) {
    if (!_incoming.isClosed) {
      _incoming.add(jsonEncode(frame));
    }
  }
}

/// A driver whose watch lane stays open until the test closes it.
class _FakeDriver implements RigDriver {
  _FakeDriver({this.codec = RigStreamCodec.mjpeg, this.watchFailure});

  final StreamController<List<int>> frames = StreamController<List<int>>();
  int watchOpens = 0;
  bool disposed = false;

  /// What this surface claims to emit.
  final RigStreamCodec codec;

  /// Thrown by [openWatchStream] instead of opening a lane, so the "the rig is
  /// fine, the host is not" path is reachable without a real driver.
  final Object? watchFailure;

  @override
  RigStreamCodec get watchCodec => codec;

  @override
  RigDisplaySize get display => RigDisplaySize(1280, 800);

  @override
  Future<RigActionResult> perform(RigAction action) async =>
      RigActionResult.ok('done');

  @override
  Future<RigActionResult> captureForAgent() async => RigActionResult.ok('');

  @override
  Future<Stream<List<int>>?> openWatchStream(RigWatchRequest request) async {
    watchOpens++;
    final failure = watchFailure;
    if (failure != null) {
      throw failure;
    }
    return frames.stream;
  }

  @override
  Future<Stream<List<int>>?> openAudioStream() async => null;

  @override
  Future<void> dispose() async {
    disposed = true;
    if (!frames.isClosed) {
      // Not awaited: closing a single-subscription controller nobody listened
      // to never completes, and most of these tests never open the lane.
      unawaited(frames.close());
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRigRepository repository;
  late RigService service;

  setUp(() {
    repository = _FakeRigRepository();
    service = RigService(
      repository: repository,
      // A backend pointed at a directory with no images: `launch` fails fast,
      // which is exactly what these tests want — they exercise the service's
      // own bookkeeping, not a hypervisor.
      qemu: QemuEnclosureBackend(
        dataDir: '/nonexistent-rig-root',
        images: RigImageStore(dataDir: '/nonexistent-rig-root'),
      ),
      smolvm: _FakeSmolvm(),
      images: RigImageStore(dataDir: '/nonexistent-rig-root'),
      // Long enough that nothing reaps mid-test.
      reapInterval: const Duration(hours: 1),
    );
  });

  tearDown(() => service.disposeAll());

  group('capability probe', () {
    test('reports the mobile backend even when nothing is installed', () async {
      // The regression this pins: the probe used to omit the android backend
      // entirely when adb was missing, which is indistinguishable from "we do
      // not support mobile" — leaving an operator whose Phone tab is greyed
      // out with nowhere to find out what it needs.
      final caps = await service.probe();
      final android = caps.backends.where(
        (b) => b.backend == EnclosureBackend.androidEmulator,
      );
      expect(
        android,
        hasLength(1),
        reason: 'The mobile backend must be reported in every host state.',
      );
    });

    test('an unavailable mobile backend always says how to fix it', () async {
      final caps = await service.probe();
      final android = caps.backends.firstWhere(
        (b) => b.backend == EnclosureBackend.androidEmulator,
      );
      if (android.available) {
        // A device is attached on this host; there is nothing to fix.
        expect(android.surfaces, contains(RigSurface.mobile));
        return;
      }
      expect(
        android.surfaces,
        isEmpty,
        reason: 'Do not offer what cannot run.',
      );
      expect(android.note, isNotNull);
      expect(
        android.installHint,
        isNotNull,
        reason:
            'Every not-ready state has a different fix, so each must name it '
            'rather than leaving the operator to guess which one they are in.',
      );
    });

    test('mobile never claims the enforced egress the VM surfaces have', () {
      // A caveat that goes missing is worse than one nobody reads: the whole
      // premise of a rig is that its network is deny-by-default, and mobile is
      // the one surface where that is not true.
      expect(EnclosureBackend.androidEmulator.hasEnforcedEgress, isFalse);
      expect(EnclosureBackend.qemuHvf.hasEnforcedEgress, isTrue);
    });
  });

  Rig seed({
    String id = 'r1',
    String workspaceId = 'ws1',
    RigStatus status = const RigReady(),
    RigSurface surface = RigSurface.computer,
    String? conversationId,
    bool exec = false,
    Duration? idleTimeout,
    RigDriver? driver,
  }) {
    final rig = Rig(
      id: id,
      workspaceId: workspaceId,
      surface: surface,
      backend: EnclosureBackend.qemuHvf,
      status: status,
      spec: exec
          ? RigSpec.exec(conversationId: conversationId ?? 'c1')
          : RigSpec(
              surface: surface,
              conversationId: conversationId,
              idleTimeout: idleTimeout ?? const Duration(minutes: 15),
            ),
      createdBy: const AgentPrincipal('a1'),
      conversationId: conversationId,
      createdAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
    );
    repository.rigs[rig.id] = rig;
    service.debugRegister(rig, driver: driver);
    return rig;
  }

  group('workspace isolation', () {
    test(
      'acting on a rig from another workspace reports it as absent',
      () async {
        seed(workspaceId: 'other');
        final result = await service.act(
          workspaceId: 'ws1',
          rigId: 'r1',
          action: const ComputerScreenshot(),
          actor: const AgentPrincipal('a1'),
        );
        expect(result.isError, isTrue);
        expect(result.text, contains('not open in this workspace'));
      },
    );

    test(
      'taking control of a foreign rig is not-found, not forbidden',
      () async {
        seed(workspaceId: 'other');
        await expectLater(
          service.takeControl(
            workspaceId: 'ws1',
            rigId: 'r1',
            actor: const UserPrincipal('u1'),
          ),
          throwsA(anything),
        );
      },
    );
  });

  group('closing', () {
    test('closing a rig with no live machine still closes its row', () async {
      // The regression this pins: a `ready` row left by a previous server
      // process (or another server sharing the database) has no `_live`
      // entry, and `close()` silently no-opped on it — the panel showed a
      // machine whose stop button did nothing, forever.
      final rig = seed();
      // Simulate "the process that owned this machine is gone": the row
      // exists, the live entry does not.
      await service.disposeAll();
      final fresh = RigService(
        repository: repository,
        qemu: QemuEnclosureBackend(
          dataDir: '/nonexistent-rig-root',
          images: RigImageStore(dataDir: '/nonexistent-rig-root'),
        ),
        smolvm: _FakeSmolvm(),
        images: RigImageStore(dataDir: '/nonexistent-rig-root'),
        reapInterval: const Duration(hours: 1),
      );
      // Reset the row to ready: disposeAll marked it closed via the live
      // entry, which is not the case under test.
      repository.rigs[rig.id] = rig.copyWith(status: const RigReady());
      await fresh.close(workspaceId: 'ws1', rigId: rig.id);
      expect(
        repository.rigs[rig.id]!.status.phase.isTerminal,
        isTrue,
        reason: 'A dead row must still be closable from the UI.',
      );
      await fresh.disposeAll();
    });
  });

  group('take-over', () {
    test('a human takes control FROM an agent unconditionally', () async {
      // The machine is ultimately the person's: "the agent holds the lock"
      // must never be a reason a human cannot intervene.
      seed();
      await service.takeControl(
        workspaceId: 'ws1',
        rigId: 'r1',
        actor: const AgentPrincipal('a1'),
      );
      final rig = await service.takeControl(
        workspaceId: 'ws1',
        rigId: 'r1',
        actor: const UserPrincipal('u1'),
      );
      expect(rig.controller, const UserPrincipal('u1'));
    });

    test('an agent cannot take control from a human', () async {
      seed();
      await service.takeControl(
        workspaceId: 'ws1',
        rigId: 'r1',
        actor: const UserPrincipal('u1'),
      );
      await expectLater(
        service.takeControl(
          workspaceId: 'ws1',
          rigId: 'r1',
          actor: const AgentPrincipal('a1'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('a human hold blocks an agent mutation but not observation', () async {
      seed();
      await service.takeControl(
        workspaceId: 'ws1',
        rigId: 'r1',
        actor: const UserPrincipal('u1'),
      );

      final blocked = await service.act(
        workspaceId: 'ws1',
        rigId: 'r1',
        action: const ComputerClick(button: RigMouseButton.left),
        actor: const AgentPrincipal('a1'),
      );
      expect(blocked.isError, isTrue);
      expect(blocked.text, contains('taken control'));

      // Observation is still allowed while a human drives — that is what lets
      // the agent keep narrating what the person is doing. It fails here for a
      // DIFFERENT reason (no driver in this fixture), which is the point: it
      // got past the take-over gate.
      final observed = await service.act(
        workspaceId: 'ws1',
        rigId: 'r1',
        action: const ComputerScreenshot(),
        actor: const AgentPrincipal('a1'),
      );
      expect(observed.text, isNot(contains('taken control')));
    });

    test('only the holder can release', () async {
      seed();
      await service.takeControl(
        workspaceId: 'ws1',
        rigId: 'r1',
        actor: const UserPrincipal('u1'),
      );
      await expectLater(
        service.releaseControl(
          workspaceId: 'ws1',
          rigId: 'r1',
          actor: const UserPrincipal('u2'),
        ),
        throwsA(anything),
        reason: 'Releasing someone else\'s hold makes the lock advisory.',
      );
    });

    test('the holder can release and the agent is free again', () async {
      seed();
      await service.takeControl(
        workspaceId: 'ws1',
        rigId: 'r1',
        actor: const UserPrincipal('u1'),
      );
      final released = await service.releaseControl(
        workspaceId: 'ws1',
        rigId: 'r1',
        actor: const UserPrincipal('u1'),
      );
      expect(released.controller, isNull);
      expect(released.agentMayAct, isTrue);
    });

    // The clipboard and file lanes sit OUTSIDE `act` — they carry bytes, and
    // an action's arguments are persisted. Being outside `act` is exactly why
    // they need their own coverage: the take-over rule has to be enforced in
    // both places, and nothing but a test says it is.

    test('a human hold blocks an agent clipboard WRITE', () async {
      seed();
      await service.takeControl(
        workspaceId: 'ws1',
        rigId: 'r1',
        actor: const UserPrincipal('u1'),
      );

      final blocked = await service.writeClipboard(
        workspaceId: 'ws1',
        rigId: 'r1',
        data: RigClipboardData.ofText('hello'),
        actor: const AgentPrincipal('a1'),
      );

      expect(blocked.isError, isTrue);
      expect(blocked.text, contains('taken control'));
    });

    test('a human hold blocks an agent DROP', () async {
      seed();
      await service.takeControl(
        workspaceId: 'ws1',
        rigId: 'r1',
        actor: const UserPrincipal('u1'),
      );

      final blocked = await service.dropFiles(
        workspaceId: 'ws1',
        rigId: 'r1',
        request: RigDropRequest(
          files: [RigFilePayload(name: 'a.txt', bytes: Uint8List(4))],
        ),
        actor: const AgentPrincipal('a1'),
      );

      expect(blocked.isError, isTrue);
      expect(blocked.summary, contains('taken control'));
    });

    test('a human hold does NOT block reading the clipboard', () async {
      // Reading is observation, like a screenshot: an agent that can still
      // look can still narrate what the person is doing, which is the whole
      // point of watching.
      seed();
      await service.takeControl(
        workspaceId: 'ws1',
        rigId: 'r1',
        actor: const UserPrincipal('u1'),
      );

      final read = await service.readClipboard(
        workspaceId: 'ws1',
        rigId: 'r1',
        actor: const AgentPrincipal('a1'),
      );

      // Empty because this fixture has no driver — the point is that it got
      // PAST the take-over gate rather than being refused by it.
      expect(read.isEmpty, isTrue);
    });

    test('a rig in another workspace is absent, not refused', () async {
      // Distinguishing "not yours" from "not there" would let a caller
      // enumerate another workspace's rig ids.
      seed();

      final read = await service.readClipboard(
        workspaceId: 'ws2',
        rigId: 'r1',
        actor: const UserPrincipal('u1'),
      );
      final written = await service.writeClipboard(
        workspaceId: 'ws2',
        rigId: 'r1',
        data: RigClipboardData.ofText('x'),
        actor: const UserPrincipal('u1'),
      );

      expect(read.isEmpty, isTrue);
      expect(written.isError, isTrue);
      expect(written.text, contains('not open in this workspace'));
    });

    test('an oversized drop is refused before anything is written', () async {
      // Validated as a WHOLE: half a drop looks exactly like a whole one in
      // the guest's folder.
      seed();

      final refused = await service.dropFiles(
        workspaceId: 'ws1',
        rigId: 'r1',
        request: RigDropRequest(
          files: List.generate(
            RigFilePayload.maxFiles + 1,
            (_) => RigFilePayload(name: 'a.txt', bytes: Uint8List(1)),
          ),
        ),
        actor: const UserPrincipal('u1'),
      );

      expect(refused.isError, isTrue);
      expect(refused.summary, contains('Too many files'));
    });

    test('an empty clipboard write is refused with a reason', () async {
      seed();

      final refused = await service.writeClipboard(
        workspaceId: 'ws1',
        rigId: 'r1',
        data: RigClipboardData.empty,
        actor: const UserPrincipal('u1'),
      );

      expect(refused.isError, isTrue);
      expect(refused.text, contains('nothing on the clipboard'));
    });
  });

  group('exec rig lookup', () {
    test('a booting exec rig is found, so a retry does not boot a second', () {
      // The bug this pins: matching on `isLive` excluded `provisioning`, so a
      // second terminal opened during the ~60s boot window started another VM.
      seed(
        id: 'exec1',
        conversationId: 'c1',
        exec: true,
        status: const RigProvisioning(step: 'Starting'),
      );
      expect(service.execRigFor('ws1', 'c1')?.id, 'exec1');
    });

    test('a desktop rig is never returned as the conversation exec rig', () {
      // Same surface, same conversation, no display server — handing this to a
      // terminal would work, but handing it to `computer_use` would not, and
      // the reverse case is what this guards.
      seed(id: 'desktop1', conversationId: 'c1');
      expect(service.execRigFor('ws1', 'c1'), isNull);
    });

    test('a closed rig is not reused', () {
      seed(
        id: 'exec1',
        conversationId: 'c1',
        exec: true,
        status: const RigClosed(RigCloseReason.idleTimeout),
      );
      expect(service.execRigFor('ws1', 'c1'), isNull);
    });
  });

  group('pins', () {
    test('a pinned rig survives the reaper past its idle timeout', () async {
      // A terminal's keystrokes never reach this service, so idle time is not
      // evidence that nobody is using the machine.
      final rig = seed(id: 'exec1', conversationId: 'c1', exec: true);
      final release = service.pin('ws1', 'exec1');
      repository.rigs['exec1'] = rig.copyWith(
        lastActivityAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      service.debugRegister(repository.rigs['exec1']!);
      // Re-pin: debugRegister replaced the live entry.
      final release2 = service.pin('ws1', 'exec1');

      await service.debugReap();
      expect(
        repository.rigs['exec1']!.status.phase.isTerminal,
        isFalse,
        reason: 'Someone has a terminal open in it.',
      );
      release();
      release2();

      // Releasing the pin restarts the idle grace from the moment the consumer
      // let go: a terminal's keystrokes never reached this service, so its
      // stale `lastActivityAt` is not evidence the machine is idle, and closing
      // it the instant the last terminal detaches would destroy a rig with no
      // grace (the same reasoning the watch lane uses). So an immediate reap
      // does NOT close it...
      await service.debugReap();
      expect(
        repository.rigs['exec1']!.status.phase.isTerminal,
        isFalse,
        reason: 'Releasing restarts the idle grace, it does not close now.',
      );

      // ...but once it is GENUINELY idle past its window, ordinary idle rules
      // do close it.
      service.debugRegister(
        repository.rigs['exec1']!.copyWith(
          lastActivityAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      await service.debugReap();
      expect(
        repository.rigs['exec1']!.status.phase,
        RigPhase.closed,
        reason: 'With the pin released and genuinely idle, it closes.',
      );
    });

    test('releasing twice is harmless', () {
      seed();
      final release = service.pin('ws1', 'r1')..call();
      release();
    });

    test('pinning an unknown rig yields a no-op release', () {
      expect(() => service.pin('ws1', 'nope')(), returnsNormally);
    });
  });

  group('ttl', () {
    test('a rig past its hard TTL is closed even while pinned', () async {
      final rig = seed(id: 'r1', conversationId: 'c1');
      service.pin('ws1', 'r1');
      repository.rigs['r1'] = rig.copyWith(lastActivityAt: DateTime.now());
      // Rebuild with a creation time far in the past so the TTL has expired.
      final expired = Rig(
        id: 'r1',
        workspaceId: 'ws1',
        surface: RigSurface.computer,
        backend: EnclosureBackend.qemuHvf,
        status: const RigReady(),
        spec: RigSpec(
          surface: RigSurface.computer,
          ttl: const Duration(seconds: 1),
        ),
        createdBy: const AgentPrincipal('a1'),
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        lastActivityAt: DateTime.now(),
      );
      repository.rigs['r1'] = expired;
      service.debugRegister(expired);
      service.pin('ws1', 'r1');

      await service.debugReap();
      expect(
        repository.rigs['r1']!.status.closeReason,
        RigCloseReason.ttlExpired,
        reason:
            'A pin says "somebody is using this", not "this may live forever".',
      );
    });
  });

  group('closing during boot', () {
    test('a close mid-launch destroys the machine the launch produces', () async {
      // The leak this pins: teardown removed the rig from `_live` and found
      // `machine` still null (the launch had not returned), so when it did the
      // machine was assigned to an object nobody held — an orphaned hypervisor
      // and its egress proxies running until the next server start.
      final qemu = _FakeQemu(gate: Completer<void>());
      service = RigService(
        repository: repository,
        qemu: qemu,
        smolvm: _FakeSmolvm(),
        images: RigImageStore(dataDir: '/nonexistent-rig-root'),
        reapInterval: const Duration(hours: 1),
      );
      final rig = await service.open(
        workspaceId: 'ws1',
        spec: RigSpec(surface: RigSurface.computer),
        openedBy: const UserPrincipal('u1'),
      );
      expect(qemu.launched, isEmpty, reason: 'The launch is still suspended.');

      final closing = service.close(workspaceId: 'ws1', rigId: rig.id);
      await pumpEventQueue();
      qemu.gate!.complete();
      await closing;

      expect(qemu.destroyed, [
        rig.id,
      ], reason: 'The machine that arrived after the close is still ours.');
      expect(repository.rigs[rig.id]!.status.phase.isTerminal, isTrue);

      // And exactly once: the boot path and the teardown must not both claim
      // it, and the boot must not resurrect the row as ready.
      await pumpEventQueue();
      expect(qemu.destroyed, [rig.id]);
      expect(repository.rigs[rig.id]!.status.phase.isTerminal, isTrue);
    });

    test('disposeAll waits for an in-flight launch and destroys it', () async {
      // Server shutdown is the case that matters most: a hypervisor that
      // outlives the process holds gigabytes and answers to nobody.
      final qemu = _FakeQemu(gate: Completer<void>());
      service = RigService(
        repository: repository,
        qemu: qemu,
        smolvm: _FakeSmolvm(),
        images: RigImageStore(dataDir: '/nonexistent-rig-root'),
        reapInterval: const Duration(hours: 1),
      );
      final rig = await service.open(
        workspaceId: 'ws1',
        spec: RigSpec(surface: RigSurface.computer),
        openedBy: const UserPrincipal('u1'),
      );
      final disposing = service.disposeAll();
      await pumpEventQueue();
      qemu.gate!.complete();
      await disposing;

      expect(qemu.destroyed, [rig.id]);
    });
  });

  group('watch lane negotiation', () {
    test(
      'the negotiated codec comes from the DRIVER, not the request',
      () async {
        // The regression this pins: a client never sends `codec`, so every
        // request defaulted to MJPEG and the service reported that back —
        // labelling the mobile lane's raw H.264 as JPEG frames. The viewer then
        // scanned it for SOI markers forever and painted nothing.
        final driver = _FakeDriver(codec: RigStreamCodec.h264);
        seed(id: 'r1', driver: driver);

        final stream = await service.watchStream(
          workspaceId: 'ws1',
          rigId: 'r1',
          request: RigWatchRequest(
            size: RigDisplaySize(1280, 800),
            // What the viewer said it wanted, which is not evidence of anything.
            codec: RigStreamCodec.mjpeg,
          ),
        );

        expect(stream!.negotiated.codec, RigStreamCodec.h264);
        expect(
          stream.negotiated.codec.contentType,
          'video/h264',
          reason:
              'The relay sets Content-Type from this; it must be the truth.',
        );
        await stream.bytes.listen((_) {}).cancel();
      },
    );

    test('an MJPEG driver still negotiates MJPEG', () async {
      final driver = _FakeDriver();
      seed(id: 'r1', driver: driver);
      final stream = await service.watchStream(
        workspaceId: 'ws1',
        rigId: 'r1',
        request: RigWatchRequest(size: RigDisplaySize(1280, 800)),
      );
      expect(stream!.negotiated.codec, RigStreamCodec.mjpeg);
      expect(
        stream.negotiated.codec.contentType,
        'video/x-motion-jpeg',
        reason:
            'Every surface emits concatenated JPEGs with no multipart framing '
            '— declaring a boundary nothing emits is a header that lies.',
      );
      await stream.bytes.listen((_) {}).cancel();
    });

    test('the other negotiated fields still come from the clamp', () async {
      final driver = _FakeDriver();
      seed(id: 'r1', driver: driver);
      final stream = await service.watchStream(
        workspaceId: 'ws1',
        rigId: 'r1',
        request: RigWatchRequest(
          size: RigDisplaySize(6000, 4000),
          fps: 240,
          quality: 900,
        ),
      );
      expect(stream!.negotiated.fps, 60);
      expect(stream.negotiated.quality, 100);
      // Fitted inside the ceiling with its aspect ratio kept, not stretched
      // to it.
      expect(stream.negotiated.size, RigDisplaySize(2400, 1600));
      await stream.bytes.listen((_) {}).cancel();
    });

    test(
      'a host that cannot serve the lane says so instead of 404ing',
      () async {
        // Two different sentences for a person: "the machine is gone" and "the
        // machine is fine and this host is missing a tool". Returning null for
        // the second reads to the viewer as the first.
        final driver = _FakeDriver(
          watchFailure: const RigStreamUnavailable(
            code: 'ffmpeg-missing',
            message: 'needs ffmpeg',
          ),
        );
        seed(id: 'r1', driver: driver);
        await expectLater(
          service.watchStream(
            workspaceId: 'ws1',
            rigId: 'r1',
            request: RigWatchRequest(size: RigDisplaySize(1280, 800)),
          ),
          throwsA(
            isA<RigStreamUnavailable>().having(
              (e) => e.code,
              'code',
              'ffmpeg-missing',
            ),
          ),
        );
      },
    );
  });

  group('watch lanes', () {
    test(
      'an open lane keeps the reaper off, closing it lets the reaper back',
      () async {
        // A person watching a guest work sends no actions, so idle time is not
        // evidence that nobody is there: the viewer's rig used to park at the
        // idle timeout and be destroyed at twice it, mid-frame.
        final driver = _FakeDriver();
        seed(
          id: 'r1',
          idleTimeout: const Duration(milliseconds: 1),
          driver: driver,
        );
        final stream = await service.watchStream(
          workspaceId: 'ws1',
          rigId: 'r1',
          request: RigWatchRequest(size: RigDisplaySize(1280, 800)),
        );
        final sub = stream!.bytes.listen((_) {});
        await pumpEventQueue();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await service.debugReap();
        expect(
          repository.rigs['r1']!.status.phase.isTerminal,
          isFalse,
          reason: 'Somebody is looking at it.',
        );

        await sub.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await service.debugReap();
        expect(
          repository.rigs['r1']!.status.phase,
          RigPhase.closed,
          reason: 'With the lane closed, ordinary idle rules apply again.',
        );
      },
    );

    test('a lane that ends by failing still releases the rig', () async {
      // Only decrementing on the happy path leaves a rig immortal after any
      // stream error — the failure mode nobody notices until a host is full.
      final driver = _FakeDriver();
      seed(
        id: 'r1',
        idleTimeout: const Duration(milliseconds: 1),
        driver: driver,
      );
      final stream = await service.watchStream(
        workspaceId: 'ws1',
        rigId: 'r1',
        request: RigWatchRequest(size: RigDisplaySize(1280, 800)),
      );
      stream!.bytes.listen((_) {}, onError: (Object _) {});
      await pumpEventQueue();
      driver.frames.addError(StateError('the guest agent died'));
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await service.debugReap();
      expect(repository.rigs['r1']!.status.phase, RigPhase.closed);
    });

    test('a watched rig is not evicted to make room', () async {
      final qemu = _FakeQemu();
      service = RigService(
        repository: repository,
        qemu: qemu,
        smolvm: _FakeSmolvm(),
        images: RigImageStore(dataDir: '/nonexistent-rig-root'),
        // Exactly one computer rig's worth (4096 MB), so the second open can
        // only succeed by evicting the first.
        maxResidentMb: 4096,
        reapInterval: const Duration(hours: 1),
      );
      final driver = _FakeDriver();
      seed(id: 'watched', driver: driver);
      final stream = await service.watchStream(
        workspaceId: 'ws1',
        rigId: 'watched',
        request: RigWatchRequest(size: RigDisplaySize(1280, 800)),
      );
      final sub = stream!.bytes.listen((_) {});
      await pumpEventQueue();

      await expectLater(
        service.open(
          workspaceId: 'ws1',
          spec: RigSpec(surface: RigSurface.computer),
          openedBy: const UserPrincipal('u1'),
        ),
        throwsA(isA<StateError>()),
        reason: 'Reclaiming memory from under an open viewer is not a trade.',
      );
      expect(repository.rigs['watched']!.status.phase.isTerminal, isFalse);

      await sub.cancel();
      await service.open(
        workspaceId: 'ws1',
        spec: RigSpec(surface: RigSurface.computer),
        openedBy: const UserPrincipal('u1'),
      );
      expect(
        repository.rigs['watched']!.status.phase.isTerminal,
        isTrue,
        reason: 'With nobody watching it is an ordinary eviction candidate.',
      );
    });

    test('two concurrent opens cannot both pass the same budget', () async {
      // The race the reservation lock closes. The check awaits evictions, so
      // split from the reservation, two opens for DIFFERENT conversations both
      // read a total that excluded the other and both passed — and the
      // `_opening` join never saw them, because it only dedupes the same
      // conversation and kind. The host then committed twice its budget.
      service = RigService(
        repository: repository,
        qemu: _FakeQemu(),
        smolvm: _FakeSmolvm(),
        images: RigImageStore(dataDir: '/nonexistent-rig-root'),
        // Exactly one computer rig's worth.
        maxResidentMb: 4096,
        reapInterval: const Duration(hours: 1),
      );

      final results = await Future.wait([
        for (final conversation in const ['c1', 'c2'])
          service
              .open(
                workspaceId: 'ws1',
                spec: RigSpec(
                  surface: RigSurface.computer,
                  conversationId: conversation,
                ),
                openedBy: const UserPrincipal('u1'),
              )
              .then<Object?>((rig) => rig)
              .catchError((Object e) => e),
      ]);

      final opened = results.whereType<Rig>().toList();
      final refused = results.whereType<StateError>().toList();
      expect(
        opened,
        hasLength(1),
        reason: 'Exactly one of two 4096 MB rigs fits a 4096 MB budget.',
      );
      expect(refused, hasLength(1));
      expect('${refused.single}', contains('memory budget'));
    });
  });

  group('backend attribution', () {
    test(
      'a mobile rig records the android backend, not the host QEMU',
      () async {
        // The row is where `hasEnforcedEgress` is read from later. Stamping a
        // mobile rig `qemu-hvf` has it claim the deny-by-default NIC that the
        // Android emulator — which owns its own networking — does not have.
        final qemu = _FakeQemu();
        service = RigService(
          repository: repository,
          qemu: qemu,
          smolvm: _FakeSmolvm(),
          images: RigImageStore(dataDir: '/nonexistent-rig-root'),
          reapInterval: const Duration(hours: 1),
        );
        final rig = await service.open(
          workspaceId: 'ws1',
          spec: RigSpec(surface: RigSurface.mobile),
          openedBy: const UserPrincipal('u1'),
        );
        expect(rig.backend, EnclosureBackend.androidEmulator);
        expect(rig.backend.hasEnforcedEgress, isFalse);
        expect(
          repository.rigs[rig.id]!.backend,
          EnclosureBackend.androidEmulator,
          reason: 'The persisted row is what every later reader trusts.',
        );
      },
    );

    test('a computer rig still records the probed QEMU backend', () async {
      final qemu = _FakeQemu();
      service = RigService(
        repository: repository,
        qemu: qemu,
        smolvm: _FakeSmolvm(),
        images: RigImageStore(dataDir: '/nonexistent-rig-root'),
        reapInterval: const Duration(hours: 1),
      );
      final rig = await service.open(
        workspaceId: 'ws1',
        spec: RigSpec(surface: RigSurface.computer),
        openedBy: const UserPrincipal('u1'),
      );
      expect(rig.backend, EnclosureBackend.qemuHvf);
    });
  });

  group('workspace browser egress', () {
    // The launch captures the spec; the browser's CDP handshake never
    // completes against the fake process, so wait for the LAUNCH, not
    // readiness.
    Future<void> awaitLaunched(_FakeSmolvm smolvm) async {
      for (var i = 0; i < 200; i++) {
        if (smolvm.specs.isNotEmpty) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('smolvm never launched a machine');
    }

    RigService serviceWithEgress(
      _FakeSmolvm smolvm,
      List<String> workspaceHosts,
    ) => RigService(
      repository: repository,
      qemu: _FakeQemu(),
      smolvm: smolvm,
      images: RigImageStore(dataDir: '/nonexistent-rig-root'),
      browserEgressHosts: (_) async => workspaceHosts,
      reapInterval: const Duration(hours: 1),
    );

    test(
      'a browser rig admits the workspace\'s hosts on top of the caller\'s',
      () async {
        final smolvm = _FakeSmolvm();
        final local = serviceWithEgress(smolvm, [
          'internal.example.com',
          // Overlaps the caller's list on purpose: the union must dedupe.
          'usectrl.dev',
        ]);
        addTearDown(local.disposeAll);

        await local.open(
          workspaceId: 'ws1',
          spec: RigSpec(
            surface: RigSurface.browser,
            conversationId: 'c1',
            egressAllowlist: const ['usectrl.dev'],
          ),
          openedBy: const UserPrincipal('u1'),
        );
        await awaitLaunched(smolvm);

        expect(
          smolvm.specs.single.egressAllowlist,
          // Set semantics: the workspace's host joined, the shared entry once.
          unorderedEquals(['usectrl.dev', 'internal.example.com']),
        );
      },
    );

    test('an exec rig keeps its own envelope', () async {
      // Exec egress is the forge + apt mirrors (`execRigEgressAllowlist`), a
      // different policy for a different job — the browser workspace setting
      // must not leak into it.
      final smolvm = _FakeSmolvm();
      final local = serviceWithEgress(smolvm, ['internal.example.com']);
      addTearDown(local.disposeAll);

      await local.open(
        workspaceId: 'ws1',
        spec: RigSpec.exec(conversationId: 'c1'),
        openedBy: const UserPrincipal('u1'),
      );
      await awaitLaunched(smolvm);

      expect(smolvm.specs.single.egressAllowlist, isEmpty);
    });
  });

  group('microVM routing', () {
    Future<Rig> awaitReady(Rig rig) async {
      // The boot is fire-and-forget; wait for the row to settle.
      for (var i = 0; i < 200; i++) {
        final current = repository.rigs[rig.id];
        if (current != null && current.status is! RigProvisioning) {
          return current;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('rig ${rig.id} never left provisioning');
    }

    test(
      'an exec rig boots on the smolvm backend and serves a shell argv',
      () async {
        final qemu = _FakeQemu();
        final smolvm = _FakeSmolvm();
        service = RigService(
          repository: repository,
          qemu: qemu,
          smolvm: smolvm,
          images: RigImageStore(dataDir: '/nonexistent-rig-root'),
          reapInterval: const Duration(hours: 1),
        );
        final rig = await awaitReady(
          await service.open(
            workspaceId: 'ws1',
            spec: RigSpec.exec(conversationId: 'c1'),
            openedBy: const UserPrincipal('u1'),
          ),
        );
        expect(rig.status, isA<RigReady>());
        expect(rig.backend, EnclosureBackend.smolvm);
        expect(
          smolvm.launched,
          contains(rig.id),
          reason:
              'The terminal rig must boot on the microVM, not the desktop '
              'hypervisor.',
        );
        expect(qemu.launched, isEmpty);

        final argv = service.shellArgvFor('ws1', rig.id);
        expect(argv, isNotNull);
        expect(argv!.first, '/fake/smolvm');
        expect(argv, contains('exec'));
        expect(
          argv,
          contains(smolvmMachineNameFor(rig.id)),
          reason: 'The shell must name THIS rig\'s machine.',
        );
      },
    );

    test(
      'a spec naming a backend its surface does not run on is refused',
      () async {
        final qemu = _FakeQemu();
        service = RigService(
          repository: repository,
          qemu: qemu,
          smolvm: _FakeSmolvm(),
          images: RigImageStore(dataDir: '/nonexistent-rig-root'),
          reapInterval: const Duration(hours: 1),
        );
        await expectLater(
          service.open(
            workspaceId: 'ws1',
            spec: RigSpec(
              surface: RigSurface.computer,
              backend: EnclosureBackend.smolvm,
            ),
            openedBy: const UserPrincipal('u1'),
          ),
          throwsA(isA<ArgumentError>()),
          reason:
              'Naming the microVM backend for the desktop surface must fail '
              'loudly, never silently downgrade to whatever is installed.',
        );
        await expectLater(
          service.open(
            workspaceId: 'ws1',
            spec: RigSpec.exec(
              conversationId: 'c2',
              backend: EnclosureBackend.qemuHvf,
            ),
            openedBy: const UserPrincipal('u1'),
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(qemu.launched, isEmpty);
      },
    );
  });

  group('action log redaction', () {
    test('typed text never reaches the database', () async {
      // A person takes over to type a password; the take-over path sends it as
      // `type`. Verbatim arguments would put it in plaintext in the workspace
      // database, where it outlives the rig by the retention window.
      seed(id: 'r1', driver: _FakeDriver());
      await service.act(
        workspaceId: 'ws1',
        rigId: 'r1',
        action: const ComputerType('hunter2!'),
        actor: const UserPrincipal('u1'),
      );
      final entry = repository.actionLog.single;
      final text = entry.args['text'] as Map<String, dynamic>;
      expect(text['textLength'], 8);
      expect(text['textSha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(jsonEncode(entry.args), isNot(contains('hunter2')));
      expect(
        entry.summary,
        isNot(contains('hunter2')),
        reason: 'The summary column sits right next to the arguments.',
      );
      expect(entry.summary, contains('8 characters'));
      expect(entry.verb, 'type', reason: 'The audit still says what happened.');
    });

    test('an agent pasting a secret is redacted too', () async {
      seed(id: 'r1', driver: _FakeDriver());
      await service.act(
        workspaceId: 'ws1',
        rigId: 'r1',
        action: const ComputerType('ghp_tokentokentoken'),
        actor: const AgentPrincipal('a1'),
      );
      expect(
        jsonEncode(repository.actionLog.single.args),
        isNot(contains('ghp_')),
        reason: 'Same leak, different author.',
      );
    });

    test('a browser fill keeps its selector and loses its value', () async {
      seed(id: 'r1', driver: _FakeDriver());
      await service.act(
        workspaceId: 'ws1',
        rigId: 'r1',
        action: const BrowserFill(selector: '#password', text: 'letmein'),
        actor: const UserPrincipal('u1'),
      );
      final entry = repository.actionLog.single;
      expect(entry.args['selector'], '#password');
      expect((entry.args['text'] as Map<String, dynamic>)['textLength'], 7);
      expect(jsonEncode(entry.args), isNot(contains('letmein')));
      expect(entry.summary, contains('#password'));
      expect(entry.summary, isNot(contains('letmein')));
    });

    test('a key combination is kept — it is what the log exists for', () async {
      seed(id: 'r1', driver: _FakeDriver());
      await service.act(
        workspaceId: 'ws1',
        rigId: 'r1',
        action: const ComputerKey(combo: 'ctrl+s'),
        actor: const UserPrincipal('u1'),
      );
      expect(repository.actionLog.single.args['text'], 'ctrl+s');
    });

    test('coordinates and modifiers survive redaction', () async {
      seed(id: 'r1', driver: _FakeDriver());
      await service.act(
        workspaceId: 'ws1',
        rigId: 'r1',
        action: const ComputerClick(
          button: RigMouseButton.left,
          x: 412,
          y: 180,
          modifiers: ['ctrl'],
        ),
        actor: const UserPrincipal('u1'),
      );
      final entry = repository.actionLog.single;
      expect(entry.args['coordinate'], [412, 180]);
      expect(entry.args['text'], ['ctrl']);
    });

    test('an oversized argument payload is capped', () async {
      seed(id: 'r1', driver: _FakeDriver());
      await service.act(
        workspaceId: 'ws1',
        rigId: 'r1',
        action: BrowserNavigate(Uri.parse('https://e.test/${'x' * 8000}')),
        actor: const UserPrincipal('u1'),
      );
      final entry = repository.actionLog.single;
      expect(entry.args['argsTruncated'], isTrue);
      expect(jsonEncode(entry.args).length, lessThan(4096));
    });
  });

  group('browser pointer stream', () {
    test('hover moves are sampled like the computer surface', () async {
      seed(id: 'r1', surface: RigSurface.browser, driver: _FakeDriver());
      for (var i = 0; i < 5; i++) {
        final result = await service.act(
          workspaceId: 'ws1',
          rigId: 'r1',
          action: BrowserMouseMove(x: i, y: i),
          actor: const UserPrincipal('u1'),
        );
        expect(result.isError, isFalse);
      }
      expect(
        repository.actionLog,
        hasLength(1),
        reason:
            'A hover stream is ~30 events/second; the audit keeps one '
            'sampled move per second rather than a row per pixel.',
      );
    });

    test('presses between moves are still logged one-to-one', () async {
      // A drag to select is move, down, moves, up — the sampling may only
      // thin the MOVES; the halves of the press are what the audit exists for.
      seed(id: 'r1', surface: RigSurface.browser, driver: _FakeDriver());
      for (final action in <RigAction>[
        const BrowserMouseMove(x: 1, y: 1),
        const BrowserMouseButtonHold(pressed: true, x: 1, y: 1),
        const BrowserMouseMove(x: 40, y: 1),
        const BrowserMouseButtonHold(pressed: false, x: 40, y: 1),
      ]) {
        await service.act(
          workspaceId: 'ws1',
          rigId: 'r1',
          action: action,
          actor: const UserPrincipal('u1'),
        );
      }
      expect(repository.actionLog.map((e) => e.verb), [
        'mouse_move',
        'left_mouse_down',
        'left_mouse_up',
      ]);
    });
  });

  group('browserState', () {
    test('a rig in another workspace reads as absent', () async {
      seed(
        id: 'r1',
        workspaceId: 'other',
        surface: RigSurface.browser,
        driver: _FakeDriver(),
      );
      expect(
        await service.browserState(workspaceId: 'ws1', rigId: 'r1'),
        isNull,
      );
    });

    test('a non-browser rig has no navigation state', () async {
      seed(id: 'r1', driver: _FakeDriver());
      expect(
        await service.browserState(workspaceId: 'ws1', rigId: 'r1'),
        isNull,
      );
    });

    test('a live browser rig reports its history position', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Page.getNavigationHistory'] = const {
          'currentIndex': 1,
          'entries': [
            {'id': 1, 'url': 'https://a.test'},
            {'id': 2, 'url': 'https://b.test'},
          ],
        };
      final driver = BrowserRigDriver(
        cdp: CdpClient.over(socket),
        viewport: RigDisplaySize(1280, 800),
      );
      addTearDown(driver.dispose);
      seed(id: 'r1', surface: RigSurface.browser, driver: driver);

      final state = await service.browserState(workspaceId: 'ws1', rigId: 'r1');

      expect(state, isNotNull);
      expect(state!.url, 'https://b.test');
      expect(state.canGoBack, isTrue);
      expect(state.canGoForward, isFalse);
      expect(state.loading, isFalse);
    });

    test('a mid-load browser rig reports loading', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Page.getNavigationHistory'] = const {
          'currentIndex': 0,
          'entries': [
            {'id': 1, 'url': 'https://a.test'},
          ],
        };
      final driver = BrowserRigDriver(
        cdp: CdpClient.over(socket),
        viewport: RigDisplaySize(1280, 800),
      );
      addTearDown(driver.dispose);
      seed(id: 'r1', surface: RigSurface.browser, driver: driver);
      socket.push({
        'method': 'Page.frameNavigated',
        'params': {
          'frame': {'id': 'main', 'url': 'https://a.test'},
        },
      });
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final state = await service.browserState(workspaceId: 'ws1', rigId: 'r1');

      expect(state!.loading, isTrue);
    });
  });
}
