part of 'rig_service.dart';

/// Environment rigs: microVMs that run an environment's compose stack and
/// tasks. Opened through `open` with `RigSpec.environment`; this is what
/// happens to one afterwards.
extension RigServiceEnvironments on RigService {
  /// The live environment rig of [environmentId] in [conversationId], or null.
  Rig? environmentRigFor(
    String workspaceId,
    String conversationId,
    String environmentId,
  ) {
    for (final live in _live.values) {
      if (live.rig.workspaceId == workspaceId &&
          live.rig.conversationId == conversationId &&
          live.rig.spec.isEnvironment &&
          live.rig.spec.slotId == environmentId &&
          live.rig.status.phase.holdsMachine) {
        return live.rig;
      }
    }
    return null;
  }

  /// A live environment rig of [conversationId], or null. Any environment's:
  /// a task with no environment of its own runs in whichever is there.
  Rig? environmentRigIn(String workspaceId, String conversationId) {
    for (final live in _live.values) {
      if (live.rig.workspaceId == workspaceId &&
          live.rig.conversationId == conversationId &&
          live.rig.spec.isEnvironment &&
          live.rig.status.phase.holdsMachine) {
        return live.rig;
      }
    }
    return null;
  }

  SmolvmMachine _environmentMachine(_LiveRig live) {
    final machine = live.machine;
    if (!live.rig.spec.isEnvironment || machine is! SmolvmMachine) {
      throw ArgumentError.value(live.rig.id, 'rigId', 'Not an environment rig');
    }
    return machine;
  }

  /// Runs [argv] in an environment rig. Not through a shell, and with no
  /// secrets in [environment]: it travels on the host command line.
  ///
  /// Throws [NotFoundException] for a rig not open in [workspaceId],
  /// [ArgumentError] for any other kind of rig and [StateError] for a stopped
  /// one.
  Future<ProcessResult> execInEnvironmentRig({
    required String workspaceId,
    required String rigId,
    required List<String> argv,
    String? workdir,
    Map<String, String> environment = const {},
    Duration timeout = const Duration(minutes: 10),
  }) async {
    final live = _requireLive(workspaceId, rigId);
    final machine = _environmentMachine(live);
    if (machine.stopped) {
      throw StateError('This environment rig is stopped.');
    }
    await _touch(live);
    return _smolvm.exec(
      machine,
      argv,
      workdir: workdir ?? kSmolvmEnvironmentWorkdir,
      environment: environment,
      timeout: timeout,
    );
  }

  /// Stops an environment rig's VM and keeps its disks, so a later start skips
  /// the image pulls. It stays in the resident budget and under its TTL.
  Future<void> stopEnvironmentRig({
    required String workspaceId,
    required String rigId,
  }) async {
    final live = _requireLive(workspaceId, rigId);
    final machine = _environmentMachine(live);
    if (machine.stopped) {
      return;
    }
    // The in-guest mux dies with the VM, and the bridges would keep dialling
    // it. Resuming attaches afresh, which bootstraps a new one.
    await _ports.detach(rigId);
    await _smolvm.stopKeepingDisks(machine);
    await _updateStatus(live, const RigParked());
  }

  /// Starts a stopped environment rig and waits for Docker.
  Future<void> resumeEnvironmentRig({
    required String workspaceId,
    required String rigId,
  }) async {
    final live = _requireLive(workspaceId, rigId);
    final machine = _environmentMachine(live);
    if (!machine.stopped) {
      return;
    }
    await _smolvm.resume(machine, spec: live.rig.spec);
    _watchMachineDeath(live, machine);
    final muxPort = machine.portMuxHostPort;
    if (muxPort != null) {
      _ports.attachExec(
        rigId: rigId,
        workspaceId: workspaceId,
        machineName: machine.name,
        muxHostPort: muxPort,
        conversationId: live.rig.conversationId,
      );
    }
    await _updateStatus(live, const RigReady());
  }
}
