part of 'environment_service.dart';

/// Deciding whether a start may happen, and sharing it when it does.
mixin _EnsureOps
    on _EnvironmentServiceBase, _DefinitionOps, _ComponentOps, _StackOps {
  /// See [EnvironmentPort.ensure].
  Future<SpaceEnvironment> ensure({
    required String workspaceId,
    required String spaceId,
    String? definitionId,
    Map<String, dynamic> options = const {},
    required Principal by,
  }) async {
    final space = await _space(workspaceId, spaceId);
    final loaded = await _pick(space, definitionId);
    return _ensureIn(space, loaded, options, by);
  }

  /// The definition to start: the one named, the one already running here, or
  /// the only one that fits. Two that fit is the caller's choice to make.
  Future<_Loaded> _pick(
    EnvironmentSpaceInfo space,
    String? definitionId,
  ) async {
    final ws = space.workspaceId;
    if (definitionId != null) {
      final eligible = await _eligible(space);
      for (final loaded in eligible) {
        if (loaded.id == definitionId) {
          return loaded;
        }
      }
      // Loading says why when the row itself is the problem.
      await _load(ws, definitionId);
      throw ValidationException(
        'definition: This space has no anchor repo of $definitionId',
      );
    }
    final current = await _current(ws, space.id);
    if (current != null) {
      return _load(ws, current.definitionId);
    }
    final eligible = await _eligible(space);
    if (eligible.length == 1) {
      return eligible.single;
    }
    if (eligible.isEmpty) {
      final records = await _d.definitions.list(ws);
      final linked = await _linkedRepoIds(ws);
      for (final record in records) {
        // An invalid row must surface its issues, not look like "no match".
        _validated(record, linked);
      }
      throw const ValidationException(
        'definition: No environment definition fits this space',
      );
    }
    throw ValidationException(
      'definition: Pick one of '
      '${eligible.map((loaded) => '${loaded.record.name} (${loaded.id})').join(', ')}',
    );
  }

  Future<SpaceEnvironment> _ensureIn(
    EnvironmentSpaceInfo space,
    _Loaded loaded,
    Map<String, dynamic> options,
    Principal by, {
    Map<String, String> extraEnvironment = const {},
  }) {
    if (_releasing.contains('${space.workspaceId}/${space.id}')) {
      throw _EnvironmentServiceBase._failure(
        'space-releasing',
        'This space is being deleted',
      );
    }
    if (_movingHeads.contains('${space.workspaceId}/${space.id}')) {
      throw _EnvironmentServiceBase._failure(
        'head-moving',
        'This space is syncing to its PR head. Start it when that finishes',
      );
    }
    final key = _lockKey(space.workspaceId, space.id, loaded.id);
    final running = _ensures[key];
    if (running != null) {
      return running;
    }
    final future =
        _exclusive(
          key,
          () => _ensureLocked(space, loaded, options, by, extraEnvironment),
        ).whenComplete(() {
          // A block, not an arrow: `remove` returns this very future, and
          // `whenComplete` waits for whatever its callback returns.
          _ensures.remove(key);
        });
    return _ensures[key] = future;
  }

  Future<SpaceEnvironment> _ensureLocked(
    EnvironmentSpaceInfo space,
    _Loaded loaded,
    Map<String, dynamic> given,
    Principal by,
    Map<String, String> extraEnvironment,
  ) async {
    final ws = space.workspaceId;
    final existing = await _rowOf(ws, space.id, loaded.id);
    final options = _resolveOptions(
      loaded.definition,
      given,
      by,
      stored: existing?.options,
    );
    if (existing?.status == EnvironmentStatus.ready) {
      final touched = await _update(
        ws,
        existing!.id,
        (row) => row.copyWith(lastUsedAt: _d.now()),
      );
      return touched ?? existing;
    }
    final placement = await _admit(space, loaded.definition, by);
    // Read here, not from [space]: that was read before this start was on
    // record, and [whileHeadMoves] holds the head still only from then on.
    final approvedHead = space.isFork && placement == EnvironmentPlacement.host
        ? (await _space(ws, space.id)).prHeadSha
        : null;
    await _reserve(space, loaded);
    try {
      final started = await _bringUp(
        space: space,
        loaded: loaded,
        options: options,
        by: by,
        existing: existing,
        placement: placement,
        mode: existing == null || existing.status == EnvironmentStatus.gone
            ? _StartMode.create
            : _StartMode.resume,
        extraEnvironment: extraEnvironment,
      );
      if (space.isFork && placement == EnvironmentPlacement.host) {
        // What the admin approved is this head, and nothing pushed after it.
        await _approvalFile(
          space.workspaceId,
          started.id,
        ).writeAsString(jsonEncode({'headSha': approvedHead, 'by': by.wire}));
      }
      return started;
    } finally {
      _reserved[loaded.id]?.remove(space.id);
    }
  }

  File _approvalFile(String workspaceId, String environmentId) => File(
    p.join(_d.stateDirFor(workspaceId, environmentId), 'fork_approval.json'),
  );

  /// The head a fork environment was approved at, or null.
  Future<String?> _approvedHead(SpaceEnvironment env) async {
    final file = _approvalFile(env.workspaceId, env.id);
    if (!file.existsSync()) {
      return null;
    }
    try {
      final json = jsonDecode(await file.readAsString());
      return json is Map ? json['headSha'] as String? : null;
    } on FormatException {
      return null;
    }
  }

  /// Forgets an approval, so the next start needs an admin again.
  Future<void> _revokeApproval(SpaceEnvironment env) async {
    final file = _approvalFile(env.workspaceId, env.id);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Admission again, for everything that runs code in an environment that
  /// already exists.
  ///
  /// Only a fork PR on the host needs it: there, code nobody reviewed runs as
  /// the server's user. The policy may have changed since the start, and an
  /// approval covers the head it was given for, not whatever was pushed next.
  Future<void> _readmit(
    SpaceEnvironment env,
    EnvironmentSpaceInfo space,
    Principal by,
  ) async {
    if (!space.isFork || env.placement != EnvironmentPlacement.host.name) {
      return;
    }
    final definition = (await _load(
      env.workspaceId,
      env.definitionId,
    )).definition;
    if (definition.forkPolicy != EnvironmentForkPolicy.approval) {
      throw _EnvironmentServiceBase._failure(
        'fork-denied',
        'This definition no longer runs fork PRs on the host',
      );
    }
    final approved = await _approvedHead(env);
    if (approved == null || approved != space.prHeadSha) {
      throw _EnvironmentServiceBase._failure(
        'fork-needs-approval',
        'This fork PR changed since an admin approved it. An admin has to '
            'start it again',
      );
    }
  }

  /// Runs [move], which takes a space's worktrees to a new head, unless that
  /// would put code nobody approved under a fork PR's host environment.
  ///
  /// Only the forge's head event stops such an environment, and until it
  /// arrives a dev watcher or a restart would run what [move] brought in.
  /// [EnvironmentStatus.stopped] and [EnvironmentStatus.gone] are the only
  /// states known to run nothing, so anything else refuses.
  Future<T> whileHeadMoves<T>(
    String workspaceId,
    String spaceId,
    Future<T> Function() move,
  ) async {
    final space = await _space(workspaceId, spaceId);
    if (!space.isFork) {
      return move();
    }
    final key = '$workspaceId/$spaceId';
    if (!_movingHeads.add(key)) {
      throw _EnvironmentServiceBase._failure(
        'head-moving',
        'This space is already syncing to its PR head',
      );
    }
    try {
      // After the claim, so a start either sees it or shows up in [_ensures].
      final rows = await _d.environments.forSpace(workspaceId, spaceId);
      final starting = _ensures.keys.any((id) => id.startsWith('$key/'));
      final running = rows.any(
        (row) =>
            row.placement == EnvironmentPlacement.host.name &&
            row.status != EnvironmentStatus.stopped &&
            row.status != EnvironmentStatus.gone,
      );
      if (starting || running) {
        throw _EnvironmentServiceBase._failure(
          'fork-running-on-host',
          'This fork PR has an environment on the host. Stop it first: an '
              'admin has to approve the new commits before they run there',
        );
      }
      return await move();
    } finally {
      _movingHeads.remove(key);
    }
  }

  Future<SpaceEnvironment?> _rowOf(
    String workspaceId,
    String spaceId,
    String definitionId,
  ) async {
    for (final row in await _d.environments.forSpace(workspaceId, spaceId)) {
      if (row.definitionId == definitionId) {
        return row;
      }
    }
    return null;
  }

  /// Agents get `agentDefault`, people `default`, and a stored environment
  /// keeps what it was started with. Unknown keys and values are refused.
  Map<String, dynamic> _resolveOptions(
    EnvironmentDefinition definition,
    Map<String, dynamic> given,
    Principal by, {
    Map<String, dynamic>? stored,
  }) {
    final issues = <String>[];
    final known = {for (final option in definition.options) option.key};
    for (final key in given.keys) {
      if (!known.contains(key)) {
        issues.add('options.$key: Unknown option');
      }
    }
    final resolved = <String, dynamic>{};
    for (final option in definition.options) {
      final fallback = by.isAgent
          ? option.agentDefault ?? option.defaultValue
          : option.defaultValue;
      final value = given.containsKey(option.key)
          ? given[option.key]
          : stored?[option.key] ?? fallback;
      if (value == null) {
        continue;
      }
      final problem = _optionProblem(option, value);
      if (problem != null) {
        issues.add('options.${option.key}: $problem');
      }
      resolved[option.key] = value;
    }
    if (issues.isNotEmpty) {
      throw ValidationException(issues.join('\n'));
    }
    return resolved;
  }

  String? _optionProblem(EnvironmentOption option, Object value) {
    switch (option.type) {
      case 'bool':
        return value is bool ? null : 'Must be true or false';
      case 'enum':
        return option.values.contains(value)
            ? null
            : 'Must be one of ${option.values.join(', ')}';
      case 'multi':
        return value is List && value.every(option.values.contains)
            ? null
            : 'Must be a list drawn from ${option.values.join(', ')}';
      default:
        return value is String ? null : 'Must be text';
    }
  }

  /// Where this start may run. Throws when a fork PR's policy forbids it.
  Future<EnvironmentPlacement> _admit(
    EnvironmentSpaceInfo space,
    EnvironmentDefinition definition,
    Principal by,
  ) async {
    var placement = definition.placement;
    if (space.isFork) {
      switch (definition.forkPolicy) {
        case EnvironmentForkPolicy.deny:
          throw _EnvironmentServiceBase._failure(
            'fork-denied',
            'This definition does not run fork PRs',
          );
        case EnvironmentForkPolicy.approval:
          if (!await _d.isAdmin(space.workspaceId, by)) {
            throw _EnvironmentServiceBase._failure(
              'fork-needs-admin',
              'Starting a fork PR runs its code on the host, so an admin has '
                  'to start it',
            );
          }
        case EnvironmentForkPolicy.rig:
          placement = EnvironmentPlacement.rig;
      }
    }
    if (placement == EnvironmentPlacement.rig && _d.rigHost == null) {
      throw _EnvironmentServiceBase._failure(
        'rig-unavailable',
        'This environment runs in a rig, and this server has no environment '
            'rigs',
      );
    }
    return placement;
  }

  /// Holds a `maxRunning` slot, or refuses before anything has started.
  ///
  /// The check and the hold are one synchronous step after the awaited read, so
  /// two spaces starting together can't both take the last slot.
  Future<void> _reserve(EnvironmentSpaceInfo space, _Loaded loaded) async {
    final limit = loaded.definition.policy.maxRunning;
    final rows = await _d.environments.list(space.workspaceId);
    final reserved = _reserved.putIfAbsent(loaded.id, () => {});
    final running = rows.where(
      (row) =>
          row.definitionId == loaded.id &&
          row.spaceId != space.id &&
          (row.status.isRunning || row.status.isBusy),
    );
    final taken = {for (final row in running) row.spaceId, ...reserved}
      ..remove(space.id);
    if (limit > 0 && taken.length >= limit) {
      final oldest = running.isEmpty
          ? null
          : running.reduce(
              (a, b) => b.lastUsedAt.isBefore(a.lastUsedAt) ? b : a,
            );
      throw EnvironmentDriverException(
        EnvironmentError(
          code: 'max-running',
          message: oldest == null
              ? '${loaded.record.name} already has $limit environments starting'
              : '${loaded.record.name} already has $limit running. The least '
                    'recently used is ${oldest.name}',
          hint: oldest == null ? null : 'Stop ${oldest.name} first',
        ),
      );
    }
    reserved.add(space.id);
  }
}
