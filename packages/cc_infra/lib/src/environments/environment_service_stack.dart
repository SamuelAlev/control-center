part of 'environment_service.dart';

/// Bringing a stack up: everything between a request and `ready`.
mixin _StackOps on _EnvironmentServiceBase, _DefinitionOps, _ComponentOps {
  /// The newest environment of a space, or null.
  Future<SpaceEnvironment?> _current(String workspaceId, String spaceId) async {
    final rows = await _d.environments.forSpace(workspaceId, spaceId);
    final live = rows.where((row) => row.status != EnvironmentStatus.gone);
    SpaceEnvironment? newest;
    for (final row in live.isEmpty ? rows : live) {
      if (newest == null || row.lastUsedAt.isAfter(newest.lastUsedAt)) {
        newest = row;
      }
    }
    return newest;
  }

  Future<SpaceEnvironment> _require(String workspaceId, String spaceId) async {
    final row = await _current(workspaceId, spaceId);
    if (row == null) {
      throw NotFoundException('This space has no environment: $spaceId');
    }
    return row;
  }

  /// Binds roles to what the space has, adding repos when [apply] is set.
  Future<List<_BoundRole>> _bindRoles(
    EnvironmentSpaceInfo space,
    EnvironmentDefinition definition, {
    required bool apply,
  }) async {
    final ws = space.workspaceId;
    final repos = await _d.directory.workspaceRepos(ws);
    final bound = <_BoundRole>[];
    for (final role in definition.repos) {
      var repo = space.repo(role.repoId);
      if (repo == null &&
          apply &&
          role.whenMissing == EnvironmentWhenMissing.addToSpace) {
        repo = await _d.directory.addRepoToSpace(ws, space.id, role.repoId);
      }
      if (repo != null) {
        bound.add(
          _BoundRole(
            role,
            EnvironmentContractRepo(
              role: role.key,
              repoId: repo.repoId,
              name: repo.name,
              slug: repo.slug,
              path: repo.worktreePath,
              sourcePath: repo.sourcePath,
              branch: repo.branch,
            ),
          ),
        );
        continue;
      }
      if (role.whenMissing == EnvironmentWhenMissing.useSource) {
        final source = repos.where((item) => item.id == role.repoId);
        if (source.isNotEmpty) {
          bound.add(
            _BoundRole(
              role,
              EnvironmentContractRepo(
                role: role.key,
                repoId: role.repoId,
                name: source.first.name,
                slug: source.first.name,
                path: source.first.sourcePath,
                sourcePath: source.first.sourcePath,
              ),
              isSource: true,
            ),
          );
          continue;
        }
      }
      if (role.required && apply) {
        throw _EnvironmentServiceBase._failure(
          'role-missing',
          'This space has no repo for the required role ${role.key}',
        );
      }
    }
    return bound;
  }

  Future<EnvironmentLease> _lease(
    EnvironmentSpaceInfo space,
    _Loaded loaded,
  ) async {
    final pool = loaded.definition.naming.pool;
    if (pool == null) {
      return _d.allocator.acquire(
        workspaceId: space.workspaceId,
        spaceId: space.id,
        definitionId: loaded.id,
      );
    }
    return _d.allocator.acquirePoolSlot(
      workspaceId: space.workspaceId,
      spaceId: space.id,
      definitionId: loaded.id,
      poolKey: loaded.definition.naming.project ?? loaded.id,
      poolSize: pool.size,
    );
  }

  /// A readable name, unique among this definition's environments.
  Future<String> _nameFor(
    EnvironmentSpaceInfo space,
    _Loaded loaded,
    EnvironmentLease lease,
  ) async {
    final naming = loaded.definition.naming;
    final pool = naming.pool;
    final slot = lease.poolSlot;
    if (pool != null && slot != null) {
      return pool.nameFor(slot);
    }
    final name = environmentNameFor(
      template: naming.template,
      branch: space.branch,
      prNumber: space.prNumber,
      maxLength: naming.maxLength,
    );
    final rows = await _d.environments.list(space.workspaceId);
    final taken = rows.any(
      (row) =>
          row.definitionId == loaded.id &&
          row.spaceId != space.id &&
          row.name == name,
    );
    return taken
        ? environmentSlug('$name-${space.id}', maxLength: naming.maxLength)
        : name;
  }

  String _projectOf(EnvironmentDefinition definition) =>
      definition.naming.project ??
      environmentSlug(definition.name, maxLength: 20);

  String _routerUrl(
    EnvironmentDefinition definition,
    String name,
    String endpoint,
    int routerPort,
  ) {
    final label = environmentRouterLabel(
      endpoint: endpoint,
      name: name,
      project: _projectOf(definition),
    );
    return 'http://$label.localhost:$routerPort';
  }

  /// Compose services' roles: the service, or `<service>-<target>` when it
  /// publishes several ports.
  Map<String, int> _composeRoles(Iterable<ComposePublishedPort> published) {
    final roles = <String, int>{};
    final ports = {for (final port in published) port.key: port};
    for (final port in ports.values) {
      final siblings = ports.values.where((p) => p.service == port.service);
      final role = siblings.length == 1
          ? port.service
          : '${port.service}-${port.target}';
      if (port.protocol == 'tcp') {
        roles[role] = port.hostPort;
      }
    }
    return roles;
  }

  bool _usesRouter(EnvironmentDefinition definition) =>
      definition.components.any(
        (component) =>
            component is ComposeEnvironmentComponent ||
            (component is ProcessEnvironmentComponent &&
                component.endpoint != null),
      );

  EnvironmentContract _contract({
    required EnvironmentSpaceInfo space,
    required _Loaded loaded,
    required List<_BoundRole> roles,
    required String id,
    required String name,
    required String stateDir,
    required Map<String, int> ports,
    required Map<String, dynamic> options,
    required int? routerPort,
    Map<String, String> compose = const {},
    Iterable<ComposePublishedPort> published = const [],
    Map<String, String> extraEnvironment = const {},
    bool expandDefinitionEnv = true,
  }) {
    final definition = loaded.definition;
    final urls = <String, String>{};
    String? primary;
    if (routerPort != null) {
      for (final process
          in definition.components.whereType<ProcessEnvironmentComponent>()) {
        final endpoint = process.endpoint;
        if (endpoint != null) {
          final url = _routerUrl(definition, name, endpoint.role, routerPort);
          urls[endpoint.role] = url;
          if (endpoint.primary) {
            primary = url;
          }
        }
      }
      // A declared endpoint keeps its name over a guess about a compose port.
      for (final role in _composeRoles(published).keys) {
        urls.putIfAbsent(
          role,
          () => _routerUrl(definition, name, role, routerPort),
        );
      }
    }
    final pr = space.prNumber;
    return EnvironmentContract(
      EnvironmentContractInput(
        name: name,
        id: id,
        stateDir: stateDir,
        home: _d.home,
        branch: space.branch,
        spaceId: space.id,
        spaceName: space.name,
        spaceKind: space.kind,
        repos: [for (final role in roles) role.repo],
        ports: ports,
        urls: urls,
        primaryUrl: primary ?? urls.values.firstOrNull,
        options: options,
        definitionEnv: expandDefinitionEnv
            ? {...definition.env, ...extraEnvironment}
            : const {},
        pr: pr == null
            ? null
            : EnvironmentContractPr(
                number: pr,
                repo: space.prRepo ?? '',
                headSha: space.prHeadSha ?? '',
                isFork: space.isFork,
              ),
        compose: compose,
      ),
    );
  }

  /// Placeholder values known before compose has run: everything but its
  /// ports and URLs.
  Map<String, String> _draftValues({
    required EnvironmentSpaceInfo space,
    required _Loaded loaded,
    required List<_BoundRole> roles,
    required String id,
    required String name,
    required String stateDir,
    required Map<String, int> ports,
    required Map<String, dynamic> options,
  }) => _contract(
    space: space,
    loaded: loaded,
    roles: roles,
    id: id,
    name: name,
    stateDir: stateDir,
    ports: ports,
    options: options,
    routerPort: null,
    expandDefinitionEnv: false,
  ).values.values;

  /// [env] expanded with [values], and `0` for whatever isn't known yet.
  Map<String, String> _leniently(
    Map<String, String> env,
    Map<String, String> values,
  ) => {
    for (final entry in env.entries)
      entry.key: entry.value.replaceAllMapped(
        RegExp(r'(?<!\{)\{([a-zA-Z_][a-zA-Z0-9_.\-]*)\}(?!\})'),
        (match) => values[match.group(1)] ?? '0',
      ),
  };

  /// A contract with no placeholders resolved, good for directories only:
  /// compose has to be planned before the ports exist.
  EnvironmentContract _bareContract(
    EnvironmentSpaceInfo space,
    List<_BoundRole> roles,
  ) => EnvironmentContract(
    EnvironmentContractInput(
      name: 'pending',
      id: 'pending',
      stateDir: '',
      home: _d.home,
      branch: space.branch,
      spaceId: space.id,
      spaceName: space.name,
      spaceKind: space.kind,
      repos: [for (final role in roles) role.repo],
    ),
  );

  ComposeContext _composeContext(
    EnvironmentSpaceInfo space,
    List<_BoundRole> roles,
    ComposeEnvironmentComponent component,
    String environmentId,
    String stateDir,
    Map<String, String> environment,
  ) => ComposeContext(
    component: component,
    environmentId: environmentId,
    workspaceId: space.workspaceId,
    spaceId: space.id,
    stateDir: stateDir,
    workingDirectory: _bareContract(
      space,
      roles,
    ).workingDirectory(component.cwd),
    environment: environment,
    allowedRoots: [
      for (final role in roles)
        if (!role.isSource) role.repo.path,
    ],
    untrusted: space.isFork,
  );

  Future<SpaceEnvironment> _bringUp({
    required EnvironmentSpaceInfo space,
    required _Loaded loaded,
    required Map<String, dynamic> options,
    required Principal by,
    required SpaceEnvironment? existing,
    required EnvironmentPlacement placement,
    required _StartMode mode,
    Map<String, String> extraEnvironment = const {},
  }) async {
    final ws = space.workspaceId;
    final definition = loaded.definition;
    final id = existing?.id ?? _uuid.v4();
    final _Stack stack;
    final List<String> warnings;
    final String name;
    final Map<String, int> ports;
    try {
      final roles = await _bindRoles(space, definition, apply: true);
      await _seed(space, definition, roles);
      final lease = await _lease(space, loaded);
      name = existing?.name ?? await _nameFor(space, loaded, lease);
      final stateDir = await _stateDir(ws, id);
      if (mode != _StartMode.resume) {
        await _clearCreateMarkers(stateDir);
      }
      await _writeBoundRoles(stateDir, roles);

      // Kept only inside the lease: after an archive released it, the ports
      // that lived elsewhere are someone else's now.
      var assigned = assignEnvironmentPorts(
        lease: lease,
        keys: definition.namedPorts,
        existing: {
          for (final entry
              in (existing?.ports ?? const <String, int>{}).entries)
            if (lease.ports.contains(entry.value)) entry.key: entry.value,
        },
      );
      final onHost = placement == EnvironmentPlacement.host;
      final plans = <String, ComposePlan>{};
      final notes = <String>[];
      if (onHost) {
        for (final component
            in definition.components.whereType<ComposeEnvironmentComponent>()) {
          final role = component.cwd?.role;
          if (role != null && !roles.any((item) => item.role.key == role)) {
            // Only a disabled component may get here: starting an enabled one
            // finds no plan and says so.
            continue;
          }
          // A first pass finds the ports. Its variables can't be complete,
          // since ports are what it is for, so unknown ones stand in as `0`:
          // a `${VAR:?}` in the file must not fail on a value CC hasn't
          // decided yet. The second pass, below, runs with the real ones.
          final draft = _draftValues(
            space: space,
            loaded: loaded,
            roles: roles,
            id: id,
            name: name,
            stateDir: stateDir,
            ports: assigned,
            options: options,
          );
          final context = _composeContext(
            space,
            roles,
            component,
            id,
            stateDir,
            _leniently({...definition.env, ...component.env}, draft),
          );
          final plan = await _d.compose.plan(
            context,
            lease: lease,
            existingPorts: assigned,
          );
          assigned = plan.ports;
          plans[component.id] = plan;
        }
      }
      final routerPort = _usesRouter(definition)
          ? await _d.routing.ensureRouter()
          : null;
      final contract = _contract(
        space: space,
        loaded: loaded,
        roles: roles,
        id: id,
        name: name,
        stateDir: stateDir,
        ports: assigned,
        options: options,
        routerPort: routerPort,
        compose: plans.values.firstOrNull?.variables ?? const {},
        published: plans.values.expand((plan) => plan.published),
        extraEnvironment: extraEnvironment,
      );
      stack = _Stack(
        space: space,
        loaded: loaded,
        roles: roles,
        contract: contract,
        stateDir: stateDir,
      );
      final enabledPlans = <String, ComposePlan>{};
      for (final component
          in definition.components.whereType<ComposeEnvironmentComponent>()) {
        if (plans[component.id] == null) {
          continue;
        }
        // Resolved again with the real variables, so the model, and the hash
        // a later refresh compares against, are what `up` will really see.
        final full = await _d.compose.plan(
          _composeContext(
            space,
            roles,
            component,
            id,
            stateDir,
            contract.forComponent(component),
          ),
          lease: lease,
          existingPorts: assigned,
        );
        if (full.ports.length != assigned.length) {
          throw _EnvironmentServiceBase._failure(
            'compose-unstable',
            '${component.displayName} publishes different ports once its '
                'variables are set. Make its ports independent of them',
          );
        }
        enabledPlans[component.id] = full;
        if (stack.isEnabled(component)) {
          // Before the row, and before any component: a stack that can't pass
          // this must not get as far as starting its first half.
          final preflight = await _d.compose.preflight(full);
          preflight.throwIfBlocked();
          notes.addAll(preflight.warnings.map((finding) => finding.message));
          await _d.compose.writeOverride(full);
        }
      }
      _plans[id] = enabledPlans;
      warnings = notes;
      ports = assigned;
    } on Exception catch (e) {
      if (existing != null && !_isRefusal(e)) {
        await _update(
          ws,
          id,
          (row) => row.copyWith(
            status: EnvironmentStatus.failed,
            lastError: _EnvironmentServiceBase._errorOf(e),
          ),
        );
      }
      if (existing == null) {
        // Nothing refers to this id, so nothing would ever clean up after it.
        try {
          await _d.allocator.release(
            workspaceId: ws,
            spaceId: space.id,
            definitionId: loaded.id,
          );
        } on Object catch (e) {
          CcInfraLog.warning('lease of a failed start not released: $e');
        }
        _plans.remove(id);
        final directory = Directory(_d.stateDirFor(ws, id));
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      }
      rethrow;
    }

    final now = _d.now();
    final startable = _startable(stack);
    final initial = SpaceEnvironment(
      id: id,
      workspaceId: ws,
      spaceId: space.id,
      definitionId: loaded.id,
      name: name,
      status: mode == _StartMode.create
          ? EnvironmentStatus.creating
          : EnvironmentStatus.starting,
      ports: ports,
      endpoints: _processEndpoints(stack, ports),
      components: [
        for (final component in startable.followedBy(_apps(stack)))
          EnvironmentComponentState(
            id: component.id,
            kind: component.kind,
            label: component.label,
            state: component is AppEnvironmentComponent ? 'closed' : 'pending',
          ),
      ],
      options: options,
      warnings: warnings,
      placement: placement.name,
      rigId: existing?.rigId,
      createdBy: existing?.createdBy ?? by.wire,
      createdAt: existing?.createdAt ?? now,
      lastUsedAt: now,
    );
    await _d.environments.save(initial);
    _announce(existing, initial);

    final log = <String>[];
    final run = await _beginRun(
      initial,
      mode == _StartMode.reset
          ? EnvironmentRunKind.reset
          : EnvironmentRunKind.start,
    );
    EnvironmentError? failure;
    try {
      await _applyRoutes(initial, stack);
      if (placement == EnvironmentPlacement.rig) {
        await _startRig(initial, stack);
      }
      await _startComponents(initial, stack, startable, mode, log);
      final row = await _d.environments.get(ws, id);
      if (row != null) {
        await _applyRoutes(row, stack);
      }
    } on Object catch (e, st) {
      failure = _EnvironmentServiceBase._errorOf(e);
      if (e is! EnvironmentDriverException) {
        CcInfraLog.error('environment $id failed to start', e, st);
      }
    }
    await _endRun(initial, run, failure: failure, log: log);

    final done = await _update(
      ws,
      id,
      (row) => row.copyWith(
        status: failure == null
            ? EnvironmentStatus.ready
            : EnvironmentStatus.failed,
        lastError: failure,
        clearLastError: failure == null,
        lastUsedAt: _d.now(),
      ),
    );
    if (failure == null && done != null) {
      _d.events.publish(
        EnvironmentReady(
          workspaceId: ws,
          spaceId: space.id,
          environmentId: id,
          url: done.primaryEndpoint?.url,
          occurredAt: _d.now(),
        ),
      );
    }
    return done ?? initial;
  }

  /// Whether [error] is a verdict on the request rather than on the stack.
  bool _isRefusal(Exception error) =>
      error is ValidationException || error is WorkspaceMismatchException;

  File _boundRolesFile(String stateDir) =>
      File(p.join(stateDir, 'bound_roles.json'));

  /// Remembers which roles this stack runs on, to notice a space dropping one.
  Future<void> _writeBoundRoles(String stateDir, List<_BoundRole> roles) =>
      _boundRolesFile(stateDir).writeAsString(
        jsonEncode([
          for (final role in roles)
            if (!role.isSource) role.role.key,
        ]),
      );

  /// Rebuilds what a running environment needs, without touching Docker.
  ///
  /// Throws [ValidationException] when its definition no longer passes, which
  /// is what stops a bad row from running anything.
  Future<_Stack> _stackOf(SpaceEnvironment env) async {
    final ws = env.workspaceId;
    final space = await _space(ws, env.spaceId);
    final loaded = await _load(ws, env.definitionId);
    final definition = loaded.definition;
    final roles = await _bindRoles(space, definition, apply: false);
    final stateDir = await _stateDir(ws, env.id);
    final composes = definition.components
        .whereType<ComposeEnvironmentComponent>()
        .toList(growable: false);
    var compose = const <String, String>{};
    final bound = {for (final role in roles) role.role.key};
    final usable = composes.where(
      (component) =>
          component.cwd?.role == null || bound.contains(component.cwd!.role),
    );
    if (usable.isNotEmpty && env.placement == 'host') {
      final component = usable.first;
      try {
        final context = _composeContext(
          space,
          roles,
          component,
          env.id,
          stateDir,
          const {},
        );
        compose = composeVariables(
          environmentId: env.id,
          stateDir: stateDir,
          composeFile: discoverComposeFile(
            context.workingDirectory,
            explicit: component.file,
          ),
        );
      } on Exception catch (e) {
        // The worktree lost its compose file. Terminals and tasks lose
        // COMPOSE_*, and everything else still works.
        CcInfraLog.warning('no compose file for ${env.id}: $e');
      }
    }
    final contract = _contract(
      space: space,
      loaded: loaded,
      roles: roles,
      id: env.id,
      name: env.name,
      stateDir: stateDir,
      ports: env.ports,
      options: env.options,
      routerPort: _usesRouter(definition)
          ? await _d.routing.ensureRouter()
          : null,
      compose: compose,
      published: _publishedFromPorts(composes, env.ports),
    );
    return _Stack(
      space: space,
      loaded: loaded,
      roles: roles,
      contract: contract,
      stateDir: stateDir,
    );
  }

  /// What teardown can still do for [env] once its space has gone: a tool's
  /// `destroy` needs a name, not a worktree.
  Future<_Stack> _stackWithoutSpace(SpaceEnvironment env) async {
    final loaded = await _load(env.workspaceId, env.definitionId);
    final stateDir = await _stateDir(env.workspaceId, env.id);
    final space = EnvironmentSpaceInfo(
      id: env.spaceId,
      workspaceId: env.workspaceId,
      name: env.name,
      branch: env.name,
    );
    return _Stack(
      space: space,
      loaded: loaded,
      roles: const [],
      contract: _contract(
        space: space,
        loaded: loaded,
        roles: const [],
        id: env.id,
        name: env.name,
        stateDir: stateDir,
        ports: env.ports,
        options: env.options,
        routerPort: null,
      ),
      stateDir: stateDir,
    );
  }

  /// Published ports as far as a row knows them, so `{url.*}` survives a
  /// restart without asking Docker. Falls back to the cached plan.
  Iterable<ComposePublishedPort> _publishedFromPorts(
    List<ComposeEnvironmentComponent> composes,
    Map<String, int> ports,
  ) sync* {
    if (composes.isEmpty) {
      return;
    }
    for (final entry in ports.entries) {
      final split = entry.key.lastIndexOf('.');
      final target = split <= 0
          ? null
          : int.tryParse(entry.key.substring(split + 1));
      if (target != null) {
        yield ComposePublishedPort(
          service: entry.key.substring(0, split),
          target: target,
          protocol: 'tcp',
          hostPort: entry.value,
        );
      }
    }
  }

  /// [component]'s plan, from cache, or resolved again after a restart.
  Future<ComposePlan> _planOf(
    SpaceEnvironment env,
    _Stack stack,
    ComposeEnvironmentComponent component,
  ) async {
    final cached = _plans[env.id]?[component.id];
    if (cached != null) {
      return cached;
    }
    final lease = await _lease(stack.space, stack.loaded);
    final plan = await _d.compose.plan(
      _composeContext(
        stack.space,
        stack.roles,
        component,
        env.id,
        stack.stateDir,
        stack.contract.forComponent(component),
      ),
      lease: lease,
      existingPorts: env.ports,
    );
    (_plans[env.id] ??= {})[component.id] = plan;
    return plan;
  }

  /// Seed files, for every role with a worktree. Never for a fork PR.
  Future<void> _seed(
    EnvironmentSpaceInfo space,
    EnvironmentDefinition definition,
    List<_BoundRole> roles,
  ) async {
    if (definition.seedFiles.isEmpty) {
      return;
    }
    for (final role in roles) {
      if (!role.isSource) {
        await _d.seeds.copy(
          sourceRoot: role.repo.sourcePath,
          worktreeRoot: role.repo.path,
          seedFiles: definition.seedFiles,
          isForkPr: space.isFork,
        );
      }
    }
  }
}
