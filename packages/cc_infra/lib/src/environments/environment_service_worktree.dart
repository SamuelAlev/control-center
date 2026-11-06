part of 'environment_service.dart';

/// Tasks that follow a worktree instead of an environment.
mixin _WorktreeOps
    on
        _EnvironmentServiceBase,
        _DefinitionOps,
        _ComponentOps,
        _StackOps,
        _EnsureOps,
        _OperationOps {
  /// Definitions binding [repoId]. A row that doesn't parse can't be said to
  /// bind anything, so it can't fail an unrelated repo's provisioning.
  Future<List<EnvironmentDefinitionRecord>> _recordsBinding(
    String workspaceId,
    String repoId,
  ) async => [
    for (final record in await _d.definitions.list(workspaceId))
      if (_binds(record, repoId)) record,
  ];

  bool _binds(EnvironmentDefinitionRecord record, String repoId) {
    try {
      return _parse(record).repos.any((role) => role.repoId == repoId);
    } on FormatException {
      CcInfraLog.warning('definition ${record.id} does not parse');
      return false;
    }
  }

  Iterable<TaskEnvironmentComponent> _tasksFor(
    EnvironmentDefinition definition,
    String repoId,
    EnvironmentTaskTrigger trigger,
  ) => definition
      .worktreeTasks(trigger)
      .where((task) => _worktreeRole(definition, task)?.repoId == repoId);

  /// See [WorktreeTaskPort.reposWithEnvironments].
  Future<Set<String>> reposWithEnvironments(String workspaceId) async {
    final repos = <String>{};
    for (final record in await _d.definitions.list(workspaceId)) {
      try {
        final definition = _parse(record);
        if (definition.hasStack) {
          repos.addAll(definition.repos.map((role) => role.repoId));
        }
      } on FormatException {
        CcInfraLog.warning('definition ${record.id} does not parse');
      }
    }
    return repos;
  }

  /// See [WorktreeTaskPort.hasProvisionTasks].
  Future<bool> hasProvisionTasks(String workspaceId, String repoId) async {
    for (final record in await _recordsBinding(workspaceId, repoId)) {
      final definition = _parse(record);
      if (definition.seedFiles.isNotEmpty ||
          _tasksFor(
            definition,
            repoId,
            EnvironmentTaskTrigger.provision,
          ).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// See [WorktreeTaskPort.runProvision].
  Future<void> runProvision(
    WorktreeTaskContext requested, {
    void Function(String line)? onOutput,
  }) async {
    final context = await _withForkStatus(requested);
    final ws = context.workspaceId;
    final linked = await _linkedRepoIds(ws);
    final loaded = <_Loaded>[];
    for (final record in await _recordsBinding(ws, context.repoId)) {
      try {
        loaded.add(_validated(record, linked));
      } on ValidationException catch (e) {
        // Only the definition that owns this repo's tasks can fail its
        // provisioning. A broken neighbour is skipped, or one bad row would
        // stop every space that shares the repo.
        if (_worktreeRepoIds(_parse(record)).contains(context.repoId)) {
          throw WorktreeTaskException(
            '${record.name} is invalid:\n${e.message}',
          );
        }
        CcInfraLog.warning('skipped ${record.name}, invalid: ${e.message}');
      }
    }
    final owners = [
      for (final item in loaded)
        if (_worktreeRepoIds(item.definition).contains(context.repoId)) item,
    ];
    if (owners.length > 1) {
      throw WorktreeTaskException(
        'Repo ${context.repoId} has provision or archive tasks in '
        '${owners.map((item) => item.record.name).join(' and ')}. Only one '
        'definition may own them',
      );
    }
    if (!context.isForkPr && loaded.isNotEmpty) {
      final included = await _worktreeIncludeFiles(context);
      for (final item in loaded) {
        final files = {...item.definition.seedFiles, ...included};
        if (files.isEmpty) {
          continue;
        }
        onOutput?.call('Copying ${files.length} seed file(s)');
        try {
          await _d.seeds.copy(
            sourceRoot: context.sourcePath,
            worktreeRoot: context.worktreePath,
            seedFiles: files.toList(),
          );
        } on WorktreeSeedException catch (e) {
          throw WorktreeTaskException(e.message);
        }
      }
    }
    if (owners.isEmpty) {
      return;
    }
    final owner = owners.single;
    for (final task in _tasksFor(
      owner.definition,
      context.repoId,
      EnvironmentTaskTrigger.provision,
    )) {
      onOutput?.call('Running ${task.displayName}');
      final EnvironmentRun? run;
      try {
        run = await _runWorktreeTask(context, owner, task, onOutput: onOutput);
      } on Exception catch (e) {
        throw WorktreeTaskException('${task.displayName} failed: $e');
      }
      if (run != null && run.status != EnvironmentRunStatus.succeeded) {
        final tail = run.output.isEmpty ? '' : '\n${run.output}';
        throw WorktreeTaskException(
          '${task.displayName} failed: ${run.error ?? 'exit ${run.exitCode}'}'
          '$tail',
        );
      }
    }
  }

  /// See [WorktreeTaskPort.runArchive].
  Future<void> runArchive(WorktreeTaskContext requested) async {
    try {
      final context = await _withForkStatus(requested);
      final ws = context.workspaceId;
      final linked = await _linkedRepoIds(ws);
      for (final record in await _recordsBinding(ws, context.repoId)) {
        final _Loaded loaded;
        try {
          loaded = _validated(record, linked);
        } on ValidationException catch (e) {
          CcInfraLog.warning('archive skipped ${record.name}: ${e.message}');
          continue;
        }
        for (final task in _tasksFor(
          loaded.definition,
          context.repoId,
          EnvironmentTaskTrigger.archive,
        )) {
          try {
            final run = await _runWorktreeTask(context, loaded, task);
            if (run != null && run.status != EnvironmentRunStatus.succeeded) {
              CcInfraLog.warning(
                'archive task ${task.id} failed, deletion continues: '
                '${run.error}',
              );
            }
          } on Object catch (e) {
            CcInfraLog.warning('archive task ${task.id} failed: $e');
          }
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('archive of ${requested.worktreePath} failed: $e');
    }
  }

  /// Runs [task], or returns null when a fork PR's policy skips it.
  ///
  /// These tasks see the 7.1 variables and nothing else: no environment exists
  /// yet, and the definition's `env` may name one.
  Future<EnvironmentRun?> _runWorktreeTask(
    WorktreeTaskContext context,
    _Loaded owner,
    TaskEnvironmentComponent task, {
    bool isTest = false,
    void Function(String line)? onOutput,
  }) async {
    final definition = owner.definition;
    if (context.isForkPr &&
        definition.forkPolicy != EnvironmentForkPolicy.rig) {
      CcInfraLog.info('skipped ${task.id}: fork PR, policy is not rig');
      return null;
    }
    final space = await _optionalSpace(context);
    final variables = worktreeTaskVariables(
      worktreePath: context.worktreePath,
      sourcePath: context.sourcePath,
      repoName:
          space?.repo(context.repoId)?.name ?? p.basename(context.sourcePath),
      spaceId: context.spaceId,
      spaceName: space?.name,
      spaceKind: space?.kind,
      isTest: isTest,
    );
    final role = _worktreeRole(definition, task);
    final values = EnvironmentValues({
      'home': _d.home,
      if (role != null) ...{
        'repo.${role.key}': context.worktreePath,
        'source.${role.key}': context.sourcePath,
      },
    });
    final relative = task.cwd?.path;
    final directory = relative == null
        ? context.worktreePath
        : p.join(context.worktreePath, relative);
    if (context.isForkPr) {
      final spaceId = context.spaceId;
      if (spaceId == null) {
        return null;
      }
      final run = await _runInRig(
        task: task,
        workspaceId: context.workspaceId,
        spaceId: spaceId,
        definitionId: owner.id,
        repoId: context.repoId,
        argv: EnvironmentCommandRunner.argvFor(task.command, values),
        environment: variables,
      );
      // A rig hands back its output when the command ends, not as it runs.
      if (run.output.isNotEmpty) {
        onOutput?.call(run.output);
      }
      return run;
    }
    final outcome = await _d.tasks.runInWorktree(
      task: task,
      workspaceId: context.workspaceId,
      workingDirectory: directory,
      variables: variables,
      values: values,
      spaceId: context.spaceId,
      definitionId: owner.id,
      repoId: context.repoId,
      kind: isTest ? EnvironmentRunKind.test : EnvironmentRunKind.task,
      onEvent: onOutput == null
          ? null
          : (event) => onOutput(switch (event) {
              EnvironmentCommandOutput(:final line) => line,
              EnvironmentCommandProgress(:final progress) =>
                '[${progress.type}] ${progress.label ?? ''}',
            }),
    );
    return outcome.run;
  }

  /// [context] with the space's real fork status.
  ///
  /// The provisioner doesn't know about forks, so this is what stops seed
  /// files, which are usually secrets, reaching a fork's worktree. When the
  /// space can't be read, a PR worktree counts as a fork. A deleted space
  /// lands here too, which is why an ordinary branch doesn't: its `archive`
  /// tasks still have to run.
  Future<WorktreeTaskContext> _withForkStatus(
    WorktreeTaskContext context,
  ) async {
    final spaceId = context.spaceId;
    var isFork = context.isForkPr;
    if (spaceId != null && !isFork) {
      try {
        isFork = (await _d.directory.space(
          context.workspaceId,
          spaceId,
        )).isFork;
      } on NotFoundException {
        isFork = context.isPrWorktree;
      } on WorkspaceMismatchException {
        rethrow;
      } on Exception {
        isFork = true;
      }
    }
    return WorktreeTaskContext(
      workspaceId: context.workspaceId,
      repoId: context.repoId,
      worktreePath: context.worktreePath,
      sourcePath: context.sourcePath,
      spaceId: spaceId,
      isForkPr: isFork,
      isPrWorktree: context.isPrWorktree,
    );
  }

  /// Literal paths from `.worktreeinclude` on the repo's default branch.
  ///
  /// Read from the copy, never the source checkout, and never from the working
  /// tree: a branch must not be able to name what gets copied into it.
  Future<List<String>> _worktreeIncludeFiles(
    WorktreeTaskContext context,
  ) async {
    final String branch;
    try {
      final repos = await _d.directory.workspaceRepos(context.workspaceId);
      branch = repos
          .firstWhere((repo) => repo.id == context.repoId)
          .defaultBranch;
    } on StateError {
      return const [];
    }
    final result = await Process.run(
      'git',
      RigWorktreeGuard.gitArgs([
        '-C',
        context.worktreePath,
        'show',
        'origin/$branch:.worktreeinclude',
      ]),
    );
    if (result.exitCode != 0) {
      return const [];
    }
    return [
      for (final line in const LineSplitter().convert('${result.stdout}'))
        if (_isLiteralInclude(line.trim())) line.trim(),
    ];
  }

  static bool _isLiteralInclude(String line) =>
      line.isNotEmpty &&
      !line.startsWith('#') &&
      !line.contains(RegExp(r'[*?\[!]')) &&
      isSafeRelativePath(line);

  Future<EnvironmentSpaceInfo?> _optionalSpace(
    WorktreeTaskContext context,
  ) async {
    final spaceId = context.spaceId;
    if (spaceId == null) {
      return null;
    }
    try {
      return await _space(context.workspaceId, spaceId);
    } on NotFoundException {
      // Archive runs while a space is going away.
      return null;
    }
  }

  /// See [WorktreeTaskPort.beforeRelease].
  Future<void> beforeRelease(String workspaceId, String spaceId) async {
    final space = '$workspaceId/$spaceId';
    _releasing.add(space);
    try {
      await _release(workspaceId, spaceId);
    } finally {
      _releasing.remove(space);
    }
  }

  Future<void> _release(String workspaceId, String spaceId) async {
    // A first start may not have written its row yet. Wait for it, so the row
    // it writes is one this tears down instead of one outliving the space.
    final prefix = '$workspaceId/$spaceId/';
    await Future.wait([
      for (final entry in _ensures.entries)
        if (entry.key.startsWith(prefix))
          entry.value.then<void>((_) {}, onError: (Object _) {}),
    ]);
    try {
      for (final row in await _d.environments.forSpace(workspaceId, spaceId)) {
        await _exclusive(_lockOf(row), () async {
          final current = await _d.environments.get(workspaceId, row.id);
          if (current != null) {
            await _teardown(current, force: true);
          }
        });
      }
    } on Object catch (e, st) {
      CcInfraLog.error('teardown of space $spaceId failed', e, st);
    }
    try {
      await _d.allocator.releaseSpace(
        workspaceId: workspaceId,
        spaceId: spaceId,
      );
    } on Object catch (e) {
      CcInfraLog.warning('lease release of space $spaceId failed: $e');
    }
  }

  /// See [EnvironmentPort.testDefinition].
  Future<String> testDefinition(String workspaceId, String definitionId) async {
    final loaded = await _load(workspaceId, definitionId);
    final id = _uuid.v4();
    await _d.runs.start(
      EnvironmentRun(
        id: id,
        workspaceId: workspaceId,
        definitionId: definitionId,
        kind: EnvironmentRunKind.test,
        label: loaded.definition.name,
        status: EnvironmentRunStatus.running,
        startedAt: _d.now(),
      ),
    );
    unawaited(_runTest(id, workspaceId, loaded));
    return id;
  }

  Future<void> _runTest(String id, String workspaceId, _Loaded loaded) async {
    final log = <String>[];
    Future<void> note(String line) async {
      log.add(line);
      await _d.runs.updateOutput(workspaceId, id, log.join('\n'));
    }

    Future<void> finish(EnvironmentRunStatus status, {String? error}) =>
        _d.runs.finish(
          workspaceId,
          id,
          status: status,
          completedAt: _d.now(),
          error: error,
          output: log.join('\n'),
        );

    final provider = _d.testClone;
    if (provider == null) {
      await finish(
        EnvironmentRunStatus.failed,
        error: 'Test runs are not available on this server',
      );
      return;
    }
    EnvironmentTestClone? clone;
    try {
      final definition = loaded.definition;
      await note('Running checks');
      final failed = [
        for (final check in await _runChecks(workspaceId, definition))
          if (!check.ok) check.label,
      ];
      if (failed.isNotEmpty) {
        throw _EnvironmentServiceBase._failure(
          'checks-failed',
          'Checks failed: ${failed.join(', ')}',
        );
      }
      await note('Cloning');
      clone = await provider(workspaceId, definition);
      final space = clone.space;
      _testSpaces[space.id] = space;
      await _testWorktreeTasks(
        space,
        loaded,
        EnvironmentTaskTrigger.provision,
        note,
      );
      if (definition.hasStack) {
        await note('Starting');
        final env = await _ensureIn(
          space,
          loaded,
          const {},
          _EnvironmentServiceBase._system,
          extraEnvironment: const {'CC_ENV_TEST': '1', 'CC_SCRIPT_TEST': '1'},
        );
        await note('Destroying');
        final failure = env.status == EnvironmentStatus.ready
            ? null
            : env.lastError?.message ?? 'Ended ${env.status.wire}';
        await _exclusive(_lockOf(env), () => _teardown(env, force: true));
        if (failure != null) {
          throw _testFailure(failure);
        }
      }
      await _testWorktreeTasks(
        space,
        loaded,
        EnvironmentTaskTrigger.archive,
        note,
      );
      await finish(EnvironmentRunStatus.succeeded);
    } on Object catch (e) {
      await finish(
        EnvironmentRunStatus.failed,
        error: _EnvironmentServiceBase._errorOf(e).message,
      );
    } finally {
      final used = clone;
      if (used != null) {
        _testSpaces.remove(used.space.id);
        try {
          await used.dispose();
        } on Object catch (e) {
          CcInfraLog.warning('test clone cleanup failed: $e');
        }
      }
    }
  }

  EnvironmentDriverException _testFailure(String message) =>
      _EnvironmentServiceBase._failure('test-failed', message);

  Future<void> _testWorktreeTasks(
    EnvironmentSpaceInfo space,
    _Loaded loaded,
    EnvironmentTaskTrigger trigger,
    Future<void> Function(String line) note,
  ) async {
    for (final task in loaded.definition.worktreeTasks(trigger)) {
      final role = _worktreeRole(loaded.definition, task);
      final repo = role == null ? null : space.repo(role.repoId);
      if (repo == null) {
        continue;
      }
      await note('Running ${task.displayName}');
      final run = await _runWorktreeTask(
        WorktreeTaskContext(
          workspaceId: space.workspaceId,
          repoId: repo.repoId,
          worktreePath: repo.worktreePath,
          sourcePath: repo.sourcePath,
          spaceId: space.id,
        ),
        loaded,
        task,
        isTest: true,
      );
      if (run != null &&
          run.status != EnvironmentRunStatus.succeeded &&
          trigger == EnvironmentTaskTrigger.provision) {
        throw _testFailure(run.error ?? '${task.displayName} failed');
      }
    }
  }
}
