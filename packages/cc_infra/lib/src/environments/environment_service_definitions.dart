part of 'environment_service.dart';

/// Stored definitions: reading, validating, saving, approving, drafting.
mixin _DefinitionOps on _EnvironmentServiceBase {
  /// The most a draft reads from one file.
  static const int _maxDraftFileBytes = 1024 * 1024;

  Future<Set<String>> _linkedRepoIds(String workspaceId) async => {
    for (final repo in await _d.directory.workspaceRepos(workspaceId)) repo.id,
  };

  /// [record] as it runs: the stored text with overrides on top.
  EnvironmentDefinition _parse(EnvironmentDefinitionRecord record) {
    final decoded = jsonDecode(record.definitionJson);
    if (decoded is! Map) {
      throw const FormatException('A definition must be a JSON object');
    }
    final overrides = record.overridesJson;
    final base = Map<String, dynamic>.from(decoded);
    final merged = overrides == null
        ? base
        : mergeEnvironmentOverrides(
            base,
            Map<String, dynamic>.from(jsonDecode(overrides) as Map),
          );
    return EnvironmentDefinition.fromJson(merged);
  }

  /// Parses and validates [record]. Everything that runs comes through here,
  /// because a stored row may predate today's rules or be edited by hand.
  ///
  /// Throws [ValidationException] listing the issues.
  _Loaded _validated(EnvironmentDefinitionRecord record, Set<String> linked) {
    final EnvironmentDefinition definition;
    try {
      definition = _parse(record);
    } on FormatException catch (e) {
      throw ValidationException('definition: ${e.message}');
    }
    final issues = validateEnvironmentDefinition(
      definition,
      linkedRepoIds: linked,
    );
    if (issues.isNotEmpty) {
      throw ValidationException(issues.join('\n'));
    }
    return _Loaded(record, definition);
  }

  Future<_Loaded> _load(String workspaceId, String definitionId) async {
    final record = await _d.definitions.get(workspaceId, definitionId);
    if (record == null) {
      throw NotFoundException(
        'Environment definition not found: $definitionId',
      );
    }
    return _validated(record, await _linkedRepoIds(workspaceId));
  }

  /// Every definition that can run, dropping the rest with a log line.
  Future<List<_Loaded>> _loadAll(String workspaceId) async {
    final linked = await _linkedRepoIds(workspaceId);
    final loaded = <_Loaded>[];
    for (final record in await _d.definitions.list(workspaceId)) {
      try {
        loaded.add(_validated(record, linked));
      } on ValidationException catch (e) {
        CcInfraLog.warning('definition ${record.id} is invalid: ${e.message}');
      }
    }
    return loaded;
  }

  /// The definitions [space] can start.
  Future<List<_Loaded>> _eligible(EnvironmentSpaceInfo space) async {
    final present = {for (final repo in space.repos) repo.repoId};
    return [
      for (final loaded in await _loadAll(space.workspaceId))
        if (loaded.definition.hasStack &&
            loaded.definition.repos.any(
              (role) => role.anchor && present.contains(role.repoId),
            ))
          loaded,
    ];
  }

  /// The roles of [definition] that have provision or archive tasks.
  Iterable<String> _worktreeRepoIds(EnvironmentDefinition definition) sync* {
    for (final task
        in definition.components.whereType<TaskEnvironmentComponent>()) {
      if (task.isWorktreeTask) {
        final role = _worktreeRole(definition, task);
        if (role != null) {
          yield role.repoId;
        }
      }
    }
  }

  EnvironmentRole? _worktreeRole(
    EnvironmentDefinition definition,
    TaskEnvironmentComponent task,
  ) {
    final named = task.cwd?.role;
    for (final role in definition.repos) {
      if (named == null || role.key == named) {
        return role;
      }
    }
    return null;
  }

  /// Provisioning can't ask which definition to use, so a repo's worktree tasks
  /// live in one definition. Throws [ValidationException] listing clashes.
  Future<void> _assertOneOwner(
    String workspaceId,
    String? definitionId,
    EnvironmentDefinition definition,
  ) async {
    final mine = _worktreeRepoIds(definition).toSet();
    if (mine.isEmpty) {
      return;
    }
    final issues = <String>[];
    for (final record in await _d.definitions.list(workspaceId)) {
      if (record.id == definitionId) {
        continue;
      }
      final EnvironmentDefinition other;
      try {
        other = _parse(record);
      } on FormatException {
        continue;
      }
      for (final repoId in _worktreeRepoIds(other).toSet().intersection(mine)) {
        issues.add(
          'components: Repo $repoId already has provision or archive tasks '
          'in ${record.name}',
        );
      }
    }
    if (issues.isNotEmpty) {
      throw ValidationException(issues.join('\n'));
    }
  }

  /// See [EnvironmentPort.listDefinitions].
  Future<List<EnvironmentDefinitionRecord>> listDefinitions(
    String workspaceId,
  ) => _d.definitions.list(workspaceId);

  /// See [EnvironmentPort.definition].
  Future<EnvironmentDefinitionRecord?> definition(
    String workspaceId,
    String definitionId,
  ) => _d.definitions.get(workspaceId, definitionId);

  /// See [EnvironmentPort.eligibleDefinitions].
  Future<List<EnvironmentDefinitionRecord>> eligibleDefinitions(
    String workspaceId,
    String spaceId,
  ) async => [
    for (final loaded in await _eligible(await _space(workspaceId, spaceId)))
      loaded.record,
  ];

  /// See [EnvironmentPort.saveDefinition].
  /// A definition read without admin rights has placeholders for its values.
  /// Saved back, they would replace the real ones.
  void _refuseRedacted(Map<String, dynamic>? json) {
    if (environmentHoldsRedaction(json)) {
      throw const ValidationException(
        'definition: This copy has hidden values. Open it again as an admin',
      );
    }
  }

  Future<EnvironmentDefinitionRecord> saveDefinition({
    required String workspaceId,
    String? definitionId,
    required Map<String, dynamic> definition,
    required Principal by,
  }) async {
    _refuseRedacted(definition);
    final source = definition['source'];
    if (source is Map) {
      return approveSource(
        workspaceId: workspaceId,
        definitionId: definitionId,
        repoId: '${source['repoId']}',
        path: '${source['path']}',
        overrides: definition['overrides'] is Map
            ? Map<String, dynamic>.from(definition['overrides'] as Map)
            : null,
        by: by,
      );
    }
    final EnvironmentDefinition parsed;
    try {
      parsed = EnvironmentDefinition.fromJson(definition);
    } on FormatException catch (e) {
      throw ValidationException('definition: ${e.message}');
    }
    final issues = validateEnvironmentDefinition(
      parsed,
      linkedRepoIds: await _linkedRepoIds(workspaceId),
    );
    if (issues.isNotEmpty) {
      throw ValidationException(issues.join('\n'));
    }
    await _assertOneOwner(workspaceId, definitionId, parsed);
    final existing = definitionId == null
        ? null
        : await _d.definitions.get(workspaceId, definitionId);
    final now = _d.now();
    final record = EnvironmentDefinitionRecord(
      id: definitionId ?? _uuid.v4(),
      workspaceId: workspaceId,
      name: parsed.name,
      definitionJson: jsonEncode(definition),
      createdBy: existing?.createdBy ?? by.wire,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _d.definitions.save(record);
    return record;
  }

  Future<EnvironmentWorkspaceRepo> _workspaceRepo(
    String workspaceId,
    String repoId,
  ) async {
    for (final repo in await _d.directory.workspaceRepos(workspaceId)) {
      if (repo.id == repoId) {
        return repo;
      }
    }
    throw ValidationException(
      'repoId: $repoId is not linked to this workspace',
    );
  }

  /// The file at [path] on the default branch, by reading git's objects: no
  /// checkout, nothing in the working tree, and never the space's branch.
  Future<({String text, String hash})> _readDefaultBranch(
    EnvironmentWorkspaceRepo repo,
    String path,
  ) async {
    final object = '${repo.defaultBranch}:$path';
    final hash = await _d.runner.runArgv([
      'git',
      'rev-parse',
      object,
    ], workingDirectory: repo.sourcePath);
    final text = await _d.runner.runArgv([
      'git',
      'show',
      object,
    ], workingDirectory: repo.sourcePath);
    if (!hash.succeeded || !text.succeeded) {
      throw ValidationException(
        'source.path: $path does not exist on ${repo.defaultBranch}',
      );
    }
    return (text: text.stdout, hash: hash.stdout.trim());
  }

  /// See [EnvironmentPort.approveSource].
  Future<EnvironmentDefinitionRecord> approveSource({
    required String workspaceId,
    String? definitionId,
    required String repoId,
    required String path,
    Map<String, dynamic>? overrides,
    String? expectedBlobHash,
    required Principal by,
  }) async {
    _refuseRedacted(overrides);
    if (!isSafeRelativePath(path)) {
      throw const ValidationException(
        'source.path: Must be a relative path inside the repo',
      );
    }
    final existing = definitionId == null
        ? null
        : await _d.definitions.get(workspaceId, definitionId);
    // An admin approves what they reviewed. Re-approving the stored blob (an
    // overrides-only edit) keeps its text; anything else must still be the
    // blob the admin saw, or a push between review and click would be
    // approved unseen.
    final ({String text, String hash}) file;
    if (expectedBlobHash != null &&
        existing?.approvedBlobHash == expectedBlobHash &&
        existing?.sourceRepoId == repoId &&
        existing?.sourcePath == path) {
      file = (text: existing!.definitionJson, hash: expectedBlobHash);
    } else {
      final repo = await _workspaceRepo(workspaceId, repoId);
      final current = await _readDefaultBranch(repo, path);
      if (expectedBlobHash != null && current.hash != expectedBlobHash) {
        throw const ValidationException(
          'The file changed since you reviewed it. Review the new version.',
        );
      }
      file = (text: current.text, hash: current.hash);
    }
    final merged = overrides ?? _storedOverrides(existing);
    final now = _d.now();
    final draft = EnvironmentDefinitionRecord(
      id: definitionId ?? _uuid.v4(),
      workspaceId: workspaceId,
      name: existing?.name ?? p.basename(path),
      definitionJson: file.text,
      sourceRepoId: repoId,
      sourcePath: path,
      approvedBlobHash: file.hash,
      overridesJson: merged == null ? null : jsonEncode(merged),
      createdBy: existing?.createdBy ?? by.wire,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final loaded = _validated(draft, await _linkedRepoIds(workspaceId));
    await _assertOneOwner(workspaceId, definitionId, loaded.definition);
    final record = EnvironmentDefinitionRecord(
      id: draft.id,
      workspaceId: workspaceId,
      name: loaded.definition.name,
      definitionJson: draft.definitionJson,
      sourceRepoId: repoId,
      sourcePath: path,
      approvedBlobHash: draft.approvedBlobHash,
      overridesJson: draft.overridesJson,
      createdBy: draft.createdBy,
      createdAt: draft.createdAt,
      updatedAt: now,
    );
    await _d.definitions.save(record);
    return record;
  }

  Map<String, dynamic>? _storedOverrides(EnvironmentDefinitionRecord? record) {
    final json = record?.overridesJson;
    return json == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(json) as Map);
  }

  /// See [EnvironmentPort.sourceUpdate].
  Future<Map<String, dynamic>?> sourceUpdate(
    String workspaceId,
    String definitionId,
  ) async {
    final record = await _d.definitions.get(workspaceId, definitionId);
    final repoId = record?.sourceRepoId;
    final path = record?.sourcePath;
    if (record == null || repoId == null || path == null) {
      return null;
    }
    final repo = await _workspaceRepo(workspaceId, repoId);
    final file = await _readDefaultBranch(repo, path);
    return {
      'blob_hash': file.hash,
      'approved_blob_hash': record.approvedBlobHash,
      'update_available': file.hash != record.approvedBlobHash,
      'text': file.text,
      'approved_text': record.definitionJson,
    };
  }

  /// See [EnvironmentPort.deleteDefinition].
  Future<void> deleteDefinition(String workspaceId, String definitionId) async {
    final rows = await _d.environments.list(workspaceId);
    final used = rows.where((row) => row.definitionId == definitionId);
    if (used.isNotEmpty) {
      throw ValidationException(
        'definition: Still used by ${used.map((row) => row.name).join(', ')}. '
        'Destroy those environments first',
      );
    }
    await _d.definitions.delete(workspaceId, definitionId);
  }

  /// See [EnvironmentPort.draftDefinition].
  Future<Map<String, dynamic>> draftDefinition(
    String workspaceId,
    String repoId,
  ) async {
    final repo = await _workspaceRepo(workspaceId, repoId);
    final files = <String, String>{};
    for (final name in kEnvironmentDraftFiles) {
      final path = p.join(repo.sourcePath, name);
      if (!File(path).existsSync() ||
          !resolvesInsideRoots(path, [repo.sourcePath])) {
        continue;
      }
      // A lock file only has to exist. Past the cap, its presence is the fact.
      files[name] = File(path).lengthSync() > _maxDraftFileBytes
          ? ''
          : await File(
              path,
            ).readAsString(encoding: const Utf8Codec(allowMalformed: true));
    }
    return draftEnvironmentDefinition(
      repoId: repoId,
      repoName: repo.name,
      files: files,
    );
  }

  /// See [EnvironmentPort.check].
  Future<List<EnvironmentCheckResult>> check(
    String workspaceId,
    String definitionId,
  ) async {
    final loaded = await _load(workspaceId, definitionId);
    return _runChecks(workspaceId, loaded.definition);
  }

  Future<List<EnvironmentCheckResult>> _runChecks(
    String workspaceId,
    EnvironmentDefinition definition,
  ) async {
    final repos = await _d.directory.workspaceRepos(workspaceId);
    final sources = {for (final repo in repos) repo.id: repo.sourcePath};
    final values = EnvironmentValues({
      'home': _d.home,
      for (final role in definition.repos)
        if (sources[role.repoId] != null) ...{
          'source.${role.key}': sources[role.repoId]!,
          'repo.${role.key}': sources[role.repoId]!,
        },
    });
    String? directory;
    for (final role in definition.repos) {
      directory ??= sources[role.repoId];
    }
    final results = <EnvironmentCheckResult>[];
    for (final check in definition.checks) {
      var ok = false;
      try {
        final file = check.file;
        final command = check.command;
        if (file != null) {
          ok = File(values.expand(file)).existsSync();
        } else if (command != null) {
          final result = await _d.runner.run(
            command,
            values: values,
            workingDirectory: directory,
            timeout: const Duration(seconds: 30),
          );
          final expected = check.expectOutput;
          ok = expected == null
              ? result.succeeded
              : RegExp(expected).hasMatch(result.stdout);
        }
      } on EnvironmentTemplateException catch (e) {
        CcInfraLog.warning('check ${check.id} is unusable: ${e.message}');
      }
      results.add(
        EnvironmentCheckResult(
          id: check.id,
          label: check.label,
          ok: ok,
          hint: ok ? null : check.hint,
          fix: ok ? null : check.fix,
        ),
      );
    }
    if (definition.components.any((c) => c is ComposeEnvironmentComponent)) {
      results.add(await _d.compose.versionCheck());
    }
    final skipped = _d.allocator.skippedBlocks;
    results.add(
      EnvironmentCheckResult(
        id: 'free-ports',
        label: skipped.isEmpty
            ? 'Port range is free'
            : 'Something listens on ${skipped.values.join(', ')}',
        ok: skipped.isEmpty,
        hint: skipped.isEmpty ? null : 'Those port blocks are skipped',
      ),
    );
    return results;
  }
}
