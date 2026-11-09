part of 'rig_service.dart';

/// Booting a machine on each backend: QEMU, smolvm, Android and the iOS
/// simulator, and watching it die afterwards. Every launch goes through
/// `_launch` and every Ready through `_markReady`, so a close that lands
/// mid-boot is honoured the same way everywhere.
extension _RigServiceBoot on RigService {
  Future<void> _boot(_LiveRig live) async {
    final rig = live.rig;
    try {
      switch (rig.backend) {
        case EnclosureBackend.androidEmulator:
          await _bootMobile(live);
        case EnclosureBackend.iosSimulator:
          await _bootIos(live);
        case EnclosureBackend.hostWindow:
          // `open` refuses this surface before anything reaches a boot.
          throw StateError('A window rig has nothing to boot.');
        case EnclosureBackend.smolvm:
          await _bootSmolvm(live);
        case EnclosureBackend.qemuHvf:
        case EnclosureBackend.qemuKvm:
        case EnclosureBackend.qemuTcg:
          await _bootQemu(live);
      }
    } on Object catch (e, st) {
      CcInfraLog.error('rig/${rig.id}: boot failed: $e', e, st);
      await _updateStatus(live, RigFailed('$e'));
      // A failed boot must release everything it took, or a host that cannot
      // start rigs slowly fills with half-built ones.
      await _teardown(live, RigCloseReason.backendFailure, alreadyFailed: true);
    }
  }

  /// Whether the rig this boot is building has already been torn down.
  ///
  /// Three ways it can be: an explicit close, `disposeAll`, or the entry being
  /// replaced in `_live`. All three mean the same thing — nothing holds this
  /// object any more, so anything the boot produces from here on is the boot's
  /// own to release.
  bool _bootAborted(_LiveRig live) =>
      live.closing || _disposed || !_isCurrent(live);

  Future<void> _bootQemu(_LiveRig live) async {
    final rig = live.rig;
    // A close that lands while QEMU starts would otherwise hand the machine
    // to an object nobody holds: the hypervisor and its egress proxies would
    // run, unreferenced, until the next server start swept them.
    final machine = await _launch(
      live,
      () => _qemu.launch(
        rigId: rig.id,
        spec: rig.spec,
        onProgress: (step) =>
            unawaited(_updateStatus(live, RigProvisioning(step: step))),
      ),
      discard: (machine) => _discardMachine(rig.id, machine),
      adopt: (machine) => live.machine = machine,
    );
    if (machine == null) {
      return;
    }

    // Watch the machine's death sentinel (the hypervisor itself on QEMU).
    _watchMachineDeath(live, machine);

    _credentials?.registerRig(
      rigId: rig.id,
      workspaceId: rig.workspaceId,
      conversationId: rig.conversationId ?? rig.id,
      secret: machine.guestSecret,
      // The rig's OWN scope, not a default: an agent-opened rig reads, which
      // is the right floor — a guest's credential helper cannot tell a push
      // from a fetch, so the push rule cannot be asked per push in there. A
      // terminal rig is a human at a shell and carries write, which is what
      // makes `git push` work there.
      scope: rig.spec.forgeTokenScope,
      repoOwner: rig.spec.repoOwner,
      repoName: rig.spec.repoName,
      // Whose forge access the guest's credentials are bounded by. The spec's
      // scope is a ceiling, not an authorization.
      actingUserId: rig.spec.openedByUserId,
      // The credential allowlist and the egress allowlist are one policy: a
      // host the guest cannot reach must never be one we hand it a token for.
      // Note the direction of the implication — being reachable does NOT by
      // itself grant a credential; `scope` above is what does.
      allowedHosts: rig.spec.egressAllowlist
          .where((h) => !h.startsWith('*'))
          .toSet(),
    );

    if (rig.spec.worktreePath != null) {
      final sync = WorktreeSync(
        sshPort: machine.sshPort,
        privateKeyPath: machine.privateKeyPath,
      );
      // The shell is usable before the worktree lands; the status line says
      // which stage it is in rather than making the user wait on a blank panel
      // while a multi-gigabyte repo copies.
      final result = await sync.syncIn(
        hostPath: rig.spec.worktreePath!,
        onProgress: (step) =>
            unawaited(_updateStatus(live, RigProvisioning(step: step))),
      );
      if (!result.ok) {
        CcInfraLog.warning('rig/${rig.id}: ${result.message}');
      }
    }

    // QEMU boots exactly one surface now: the desktop. Browser rigs are
    // smolvm's — a headless Chromium behind a forwarded CDP port needs no
    // display device, and the microVM boots it in a fraction of the time.
    final driver = ComputerRigDriver(machine);
    if (_bootAborted(live)) {
      // Teardown already read `driver` (it was null then) and destroyed the
      // machine, so this one — and the DevTools socket a browser driver holds
      // — is ours to close. The check and the assignment below share a turn,
      // so exactly one side owns it.
      await driver.dispose();
      return;
    }
    live.driver = driver;
    await _markReady(live, machine.display);
  }

  /// Opens the protocol client for whichever browser the machine booted.
  Future<BrowserEngineClient> _attachBrowser(SmolvmMachine machine) async {
    final port = machine.devtoolsPort;
    if (port == null) {
      throw StateError('The browser rig has no forwarded automation port.');
    }
    return attachBrowserEngine(
      engine: machine.engine,
      host: '127.0.0.1',
      port: port,
      guestPort:
          machine.automationGuestPort ?? browserRigEndpointPort(machine.engine),
    );
  }

  /// Watches the machine's death sentinel and fails the rig when it drops.
  ///
  /// On QEMU the sentinel IS the hypervisor process; on smolvm it is the held
  /// `machine exec` connection (the CLI spawns the VMM detached). Either way
  /// a machine that dies on its own otherwise leaves a `ready` row whose
  /// stream and actions all fail while the panel keeps promising a machine.
  /// A normal destroy also resolves this future, but by then teardown has
  /// removed the rig from `_live` and `_isCurrent` is false.
  void _watchMachineDeath(_LiveRig live, RigMachine machine) {
    unawaited(
      machine.process.exitCode.then((code) async {
        if (!_isCurrent(live)) {
          return;
        }
        // Stopped on purpose, with its disks kept. Resuming re-arms this.
        if (machine is SmolvmMachine && machine.stopped) {
          return;
        }
        CcInfraLog.warning(
          'rig/${live.rig.id}: machine exited unexpectedly (code $code)',
        );
        await _updateStatus(
          live,
          RigFailed('The virtual machine exited unexpectedly (code $code).'),
        );
        await _teardown(
          live,
          RigCloseReason.backendFailure,
          alreadyFailed: true,
        );
      }),
    );
  }

  Future<void> _bootSmolvm(_LiveRig live) async {
    final rig = live.rig;
    final machine = await _launch(
      live,
      () async {
        // The workspace's own image, when configured. Failure to READ the
        // setting degrades to the default image: a settings store hiccup
        // must not stop terminals from opening.
        String? imageOverride;
        try {
          imageOverride = rig.spec.isEnvironment
              ? null
              : await _smolvmImageOverride?.call(
                  rig.workspaceId,
                  exec: rig.spec.isExec,
                );
        } on Object catch (e) {
          CcInfraLog.warning(
            'rig/${rig.id}: could not read the workspace image override: $e',
          );
        }
        return _smolvm.launch(
          rigId: rig.id,
          spec: rig.spec,
          imageOverride: imageOverride,
          onProgress: (step) =>
              unawaited(_updateStatus(live, RigProvisioning(step: step))),
        );
      },
      discard: (machine) => _discardMachine(rig.id, machine),
      adopt: (machine) => live.machine = machine,
    );
    if (machine == null) {
      return;
    }

    _watchMachineDeath(live, machine);

    // An environment guest runs compose files nobody here reviewed, so it is
    // never registered: it holds no secret and can mint nothing.
    if (!rig.spec.isEnvironment) {
      _credentials?.registerRig(
        rigId: rig.id,
        workspaceId: rig.workspaceId,
        conversationId: rig.conversationId ?? rig.id,
        secret: machine.guestSecret,
        // Same floor as the QEMU path: the rig's OWN scope, so an agent-opened
        // rig reads by default.
        scope: rig.spec.forgeTokenScope,
        repoOwner: rig.spec.repoOwner,
        repoName: rig.spec.repoName,
        // Whose forge access the guest's credentials are bounded by. The spec's
        // scope is a ceiling, not an authorization.
        actingUserId: rig.spec.openedByUserId,
        // The credential allowlist and the egress allowlist are one policy: a
        // host the guest cannot reach must never be one we hand it a token for.
        allowedHosts: rig.spec.egressAllowlist
            .where((h) => !h.startsWith('*'))
            .toSet(),
      );
    }

    // An environment's worktree is a live mount, not a copy.
    if (rig.spec.worktreePath != null && !rig.spec.isEnvironment) {
      final binary = _smolvm.resolvedBinary;
      if (binary != null) {
        final sync = WorktreeSync.smolvm(
          smolvmPath: binary,
          machineName: machine.name,
        );
        final result = await sync.syncIn(
          hostPath: rig.spec.worktreePath!,
          onProgress: (step) =>
              unawaited(_updateStatus(live, RigProvisioning(step: step))),
        );
        if (!result.ok) {
          CcInfraLog.warning('rig/${rig.id}: ${result.message}');
        }
      }
    }

    if (rig.surface == RigSurface.browser) {
      final binary = _smolvm.resolvedBinary;
      final microphone = binary == null
          ? null
          : _SmolvmBrowserMicrophone(
              binary: binary,
              machineName: machine.name,
              rigId: rig.id,
            );
      final driver = BrowserRigDriver(
        client: await _attachBrowser(machine),
        viewport: rig.spec.display,
        onUrlChanged: (url) => unawaited(_browserNavigated(live, url)),
        audioStreamOpener: () => _openSmolvmBrowserAudio(machine),
        audioInputSender: microphone?.send,
        audioInputCloser: microphone?.close,
      );
      if (_bootAborted(live)) {
        await driver.dispose();
        return;
      }
      live.driver = driver;
      // The home page loaded BEFORE the driver attached, so no navigation
      // event will ever name it — seed the tracker with where the page is.
      unawaited(driver.seedCurrentUrl());
    }
    // An exec rig deliberately gets NO driver: there is no surface to drive,
    // and `act` says so rather than pretending a terminal can take a click.

    // Re-checked after every await above (the worktree sync alone can take
    // minutes): a close that landed mid-boot already wrote the closed row and
    // destroyed the machine, and saving `ready` over it here would resurrect
    // a rig the panel can never act on.
    if (_bootAborted(live)) {
      return;
    }

    // Ports: discovery + forwarding for the terminal machine, and the
    // guest-loopback listeners that let a browser rig in the same
    // conversation reach its forwarded ports as `localhost:<port>`.
    final muxPort = machine.portMuxHostPort;
    if (muxPort != null) {
      _ports.attachExec(
        rigId: rig.id,
        workspaceId: rig.workspaceId,
        machineName: machine.name,
        muxHostPort: muxPort,
        conversationId: rig.conversationId,
        brokerPort: rig.spec.isEnvironment ? null : _smolvm.credentialPort,
      );
    } else if (rig.surface == RigSurface.browser) {
      _ports.attachBrowser(
        rigId: rig.id,
        workspaceId: rig.workspaceId,
        machineName: machine.name,
        conversationId: rig.conversationId,
      );
    }

    await _markReady(live, machine.display);
  }

  Future<void> _bootMobile(_LiveRig live) async {
    final rig = live.rig;
    await _updateStatus(live, const RigProvisioning(step: 'Finding a device'));
    final adbPath = await AdbClient.locate();
    if (adbPath == null) {
      throw StateError(
        'adb is not installed, so the mobile surface is unavailable. Install '
        'the Android platform tools and start an emulator.',
      );
    }
    final devices = await AdbClient.devices(adbPath);
    if (devices.isEmpty) {
      throw StateError(
        'No Android device is attached. Start an emulator, then open the rig '
        'again.',
      );
    }
    // The serial is chosen ONCE and pinned for the rig's whole life. Every
    // later command carries `-s <serial>` and `ensureReady` re-checks it, so a
    // device that disconnects is reported rather than silently swapped for
    // whichever one ADB would have picked next.
    final adb = AdbClient(
      serial: devices.first,
      adbPath: adbPath,
      apkRoots: [
        if (rig.spec.worktreePath != null) rig.spec.worktreePath!,
        if (_dataDir != null) _dataDir,
      ],
    );
    final booted = await adb.awaitBoot(
      onProgress: (step) =>
          unawaited(_updateStatus(live, RigProvisioning(step: step))),
    );
    if (!booted) {
      throw StateError('The device never finished booting.');
    }
    final size = await adb.screenSize();
    final display = size == null
        ? RigDisplaySize.defaultMobile
        : RigDisplaySize(size.$1, size.$2);
    if (_bootAborted(live)) {
      // No machine of ours to leak here — the emulator was already running and
      // outlives the rig — but publishing `RigOpened` and a `ready` row for a
      // session that was closed while `awaitBoot` ran would leave the panel
      // showing a device it can never act on.
      return;
    }
    live.driver = MobileRigDriver(
      adb: adb,
      size: display,
      onDisplayChanged: (next) => unawaited(_mobileDisplayChanged(live, next)),
    );
    _ports.attachAndroid(
      rigId: live.rig.id,
      workspaceId: live.rig.workspaceId,
      conversationId: live.rig.conversationId,
      reverse: adb.reverse,
      removeReverse: adb.removeReverse,
      removeAllReverses: adb.removeAllReverses,
    );
    await _markReady(live, display);
  }

  Future<void> _bootIos(_LiveRig live) async {
    final backend = _ios;
    if (backend == null) {
      throw StateError('iOS Simulator is not configured on this server.');
    }
    final session = await _launch(
      live,
      () => backend.launch(
        rigId: live.rig.id,
        onProgress: (step) =>
            unawaited(_updateStatus(live, RigProvisioning(step: step))),
      ),
      discard: backend.close,
      adopt: (session) {
        live.iosSession = session;
        _watchIosDeath(live, session);
      },
    );
    if (session == null) {
      return;
    }
    final driver = IosRigDriver(
      session: session,
      backend: backend,
      appRoots: [
        if (live.rig.spec.worktreePath != null) live.rig.spec.worktreePath!,
        if (_dataDir != null) _dataDir,
      ],
      onDisplayChanged: (display) =>
          unawaited(_iosDisplayChanged(live, display)),
    );
    if (_bootAborted(live)) {
      await driver.dispose();
      await backend.close(session);
      return;
    }
    live.driver = driver;
    await _markReady(live, session.display);
  }

  Future<void> _iosDisplayChanged(_LiveRig live, RigDisplaySize display) async {
    if (!_isCurrent(live) || live.rig.display == display) {
      return;
    }
    live.rig = live.rig.copyWith(display: display);
    await _repository.save(live.rig.workspaceId, live.rig);
  }

  Future<void> _mobileDisplayChanged(
    _LiveRig live,
    RigDisplaySize display,
  ) async {
    if (!_isCurrent(live) || live.rig.display == display) {
      return;
    }
    live.rig = live.rig.copyWith(display: display);
    await _repository.save(live.rig.workspaceId, live.rig);
  }

  void _watchIosDeath(_LiveRig live, IosSimulatorSession session) {
    unawaited(
      session.runner.exitCode.then((code) async {
        if (!_isCurrent(live) || live.closing) {
          return;
        }
        CcInfraLog.warning(
          'rig/${live.rig.id}: WebDriverAgent exited unexpectedly (code $code)',
        );
        await _updateStatus(
          live,
          RigFailed('iOS automation exited unexpectedly (code $code).'),
        );
        await _teardown(
          live,
          RigCloseReason.backendFailure,
          alreadyFailed: true,
        );
      }),
    );
  }
}
