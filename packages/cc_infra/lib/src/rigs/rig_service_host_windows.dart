part of 'rig_service.dart';

/// Window rigs: views onto a desktop app's windows. Nothing boots, and closing
/// one leaves the app running.
extension RigServiceHostWindows on RigService {
  /// Whether window rigs work here. Not cached: a person can grant a
  /// permission between two looks at Settings.
  Future<RigBackendCapabilities> _probeHostWindows(HostWindowPort port) async {
    const backend = EnclosureBackend.hostWindow;
    const surfaces = {RigSurface.window};
    const caveat =
        'Apps run on this host with your account\'s access. Nothing contains '
        'them.';
    final HostWindowPermissions permissions;
    try {
      permissions = await port.permissions();
    } on Object catch (e) {
      return RigBackendCapabilities.unavailable(
        backend,
        surfaces: surfaces,
        note: 'App windows are not available on this host: $e',
      );
    }
    final missing = [
      if (!permissions.screenCapture.isUsable) 'Screen Recording',
      if (!permissions.input.isUsable) 'Accessibility',
    ];
    if (missing.isNotEmpty) {
      return RigBackendCapabilities.unavailable(
        backend,
        surfaces: surfaces,
        note: 'App windows need ${missing.join(' and ')}. $caveat',
      );
    }
    return const RigBackendCapabilities(
      backend: backend,
      available: true,
      surfaces: surfaces,
      note: caveat,
    );
  }

  /// Opens a rig over the windows of processes that are already running.
  ///
  /// There is no boot step: the rig is ready on return, even if the app has
  /// not mapped a window yet. [pids] are the launched roots; the native layer
  /// adds their descendants and refuses every window outside that tree, so it
  /// must never name this server or anything above it.
  ///
  /// One rig per ([workspaceId], [conversationId], [slotId]): a repeat call
  /// updates that rig's processes and returns it. [slotId] tells two app
  /// components in one space apart. [display] is the app's X display on Linux.
  /// [inputMode] is fixed for the rig's life; `foreground` takes over the
  /// operator's cursor, so only pass it when that is allowed.
  ///
  /// The rig never owns the app: closing it leaves the processes running, and
  /// the reaper and the memory budget leave it alone. Its opener closes it
  /// when the app exits, and [updateHostWindowPids] carries it across a
  /// relaunch.
  Future<Rig> openHostWindowRig({
    required String workspaceId,
    required Set<int> pids,
    required Principal openedBy,
    String? conversationId,
    String? slotId,
    String? agentId,
    String? display,
    HostWindowInputMode inputMode = HostWindowInputMode.background,
  }) async {
    if (_disposed) {
      throw StateError('The rig service is shutting down.');
    }
    final port = _hostWindows;
    if (port == null) {
      throw StateError('App windows are not configured on this server.');
    }
    final scope = HostWindowScope(pids: pids, display: display);
    final spec = RigSpec(
      surface: RigSurface.window,
      conversationId: conversationId,
      slotId: slotId,
      agentId: agentId,
    );
    final reusable = _reusableFor(workspaceId, spec);
    final existing = reusable?.driver;
    if (reusable != null && existing is HostWindowRigDriver) {
      existing.scope = scope;
      await _touch(reusable);
      return reusable.rig;
    }
    final now = DateTime.now();
    final live = _LiveRig(
      rig: Rig(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        surface: RigSurface.window,
        backend: EnclosureBackend.hostWindow,
        status: const RigReady(),
        spec: spec,
        createdBy: openedBy,
        conversationId: conversationId,
        agentId: agentId,
        createdAt: now,
        readyAt: now,
        lastActivityAt: now,
      ),
    );
    final driver = HostWindowRigDriver(
      port: port,
      scope: scope,
      inputMode: inputMode,
      onDisplayChanged: (size) => unawaited(_iosDisplayChanged(live, size)),
    );
    live.driver = driver;
    // Registered before the first await, so a concurrent open for the same
    // slot finds this rig instead of making a second one.
    _live[live.rig.id] = live;
    await _dismissFailedSiblings(workspaceId, spec);
    await driver.refreshDisplay();
    live.rig = live.rig.copyWith(display: driver.display);
    await _repository.save(workspaceId, live.rig);
    return live.rig;
  }

  /// Points an open window rig at new processes, as after a relaunch.
  ///
  /// Throws [NotFoundException] for a rig that is not open in [workspaceId] and
  /// [ArgumentError] for one that is not a window rig.
  Future<void> updateHostWindowPids({
    required String workspaceId,
    required String rigId,
    required Set<int> pids,
  }) async {
    final live = _requireLive(workspaceId, rigId);
    final driver = live.driver;
    if (driver is! HostWindowRigDriver) {
      throw ArgumentError.value(rigId, 'rigId', 'Not a window rig');
    }
    driver.scope = HostWindowScope(pids: pids, display: driver.scope.display);
    await _touch(live);
  }
}
