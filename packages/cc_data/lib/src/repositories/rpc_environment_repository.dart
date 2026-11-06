import 'dart:convert';

import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A proposed definition, not stored until an admin saves it.
class EnvironmentDraft {
  /// Creates an [EnvironmentDraft].
  const EnvironmentDraft({required this.definition, this.notes = const []});

  /// The proposed definition, as JSON.
  final Map<String, dynamic> definition;

  /// What the scan wants the admin to know.
  final List<String> notes;
}

/// What a linked file holds now, next to what was approved.
class EnvironmentSourceUpdate {
  /// Creates an [EnvironmentSourceUpdate].
  const EnvironmentSourceUpdate({
    required this.currentHash,
    required this.approvedHash,
    required this.content,
    required this.hasUpdate,
    this.approvedContent,
  });

  /// The blob on the default branch.
  final String currentHash;

  /// The blob an admin approved, or null before any approval.
  final String? approvedHash;

  /// The file's current text.
  final String content;

  /// The approved definition's text, when the server sends it.
  final String? approvedContent;

  /// Whether the file moved past the approved blob.
  final bool hasUpdate;
}

/// Parses `environments.sourceUpdate`. An empty object means the definition
/// has no source.
EnvironmentSourceUpdate? environmentSourceUpdateFromWire(
  Map<String, dynamic> json,
) {
  final current = json['blob_hash'];
  if (current is! String) {
    return null;
  }
  final approved = json['approved_blob_hash'] as String?;
  return EnvironmentSourceUpdate(
    currentHash: current,
    approvedHash: approved,
    content: (json['text'] as String?) ?? '',
    approvedContent: json['approved_text'] as String?,
    hasUpdate: json['update_available'] is bool
        ? json['update_available'] as bool
        : current != approved,
  );
}

/// One line of process or service output.
typedef EnvironmentLogLine = ({String line, int? seq});

/// How long the server may take, per kind of work. The RPC default is 30 s,
/// and a compose build or a CLI's create runs for minutes.
abstract final class EnvironmentCallBudgets {
  /// Start, reset, refresh, recreate and destroy: whole stacks.
  static const lifecycle = Duration(minutes: 30);

  /// One task, or a desktop app's prepare task.
  static const task = Duration(minutes: 30);

  /// A command in a service.
  static const exec = Duration(minutes: 10);

  /// Host checks, each bounded by the server.
  static const check = Duration(minutes: 5);

  /// A repo scan or a test kick-off.
  static const scan = Duration(minutes: 2);
}

/// Parses a stored definition from its wire form.
EnvironmentDefinitionRecord environmentDefinitionRecordFromWire(
  Map<String, dynamic> json,
) {
  final overrides = json['overrides'];
  return EnvironmentDefinitionRecord(
    id: json['id'] as String,
    workspaceId: json['workspace_id'] as String,
    name: json['name'] as String,
    definitionJson: jsonEncode(json['definition']),
    sourceRepoId: json['source_repo_id'] as String?,
    sourcePath: json['source_path'] as String?,
    approvedBlobHash: json['approved_blob_hash'] as String?,
    overridesJson: overrides == null ? null : jsonEncode(overrides),
    createdBy: json['created_by'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

/// Parses a recorded run from its wire form.
EnvironmentRun environmentRunFromWire(Map<String, dynamic> json) {
  final completedAt = json['completed_at'] as String?;
  return EnvironmentRun(
    id: json['id'] as String,
    workspaceId: json['workspace_id'] as String,
    spaceId: json['space_id'] as String?,
    environmentId: json['environment_id'] as String?,
    definitionId: json['definition_id'] as String?,
    repoId: json['repo_id'] as String?,
    kind: EnvironmentRunKind.parse(json['kind'] as String?),
    label: json['label'] as String?,
    status: EnvironmentRunStatus.parse(json['status'] as String?),
    startedAt: DateTime.parse(json['started_at'] as String),
    completedAt: completedAt == null ? null : DateTime.parse(completedAt),
    exitCode: (json['exit_code'] as num?)?.toInt(),
    error: json['error'] as String?,
    output: (json['output'] as String?) ?? '',
  );
}

/// Splits a validation failure into its `path: message` lines.
///
/// Lines without a path are kept with an empty one, so nothing the server said
/// goes missing from the editor.
List<EnvironmentDefinitionIssue> environmentIssuesFromMessage(String message) {
  final pattern = RegExp(r'^([A-Za-z][\w.\[\]-]*): (.+)$');
  return [
    for (final raw in const LineSplitter().convert(message))
      if (raw.trim().isNotEmpty)
        switch (pattern.firstMatch(raw.trim())) {
          final match? => EnvironmentDefinitionIssue(
            match.group(1)!,
            match.group(2)!,
          ),
          null => EnvironmentDefinitionIssue('', raw.trim()),
        },
  ];
}

/// The client half of the environment feature.
///
/// Reads definitions and live state and forwards actions. The server owns
/// persistence, process supervision and Docker: nothing here runs anything.
class RpcEnvironmentRepository {
  /// Creates a [RpcEnvironmentRepository] over the RPC client.
  RpcEnvironmentRepository(this._client);

  final RemoteRpcClient _client;

  List<EnvironmentDefinitionRecord> _definitions(Map<String, dynamic> data) => [
    for (final raw in (data['definitions'] as List?) ?? const [])
      if (raw is Map)
        environmentDefinitionRecordFromWire(raw.cast<String, dynamic>()),
  ];

  List<EnvironmentRun> _runs(Map<String, dynamic> data) => [
    for (final raw in (data['runs'] as List?) ?? const [])
      if (raw is Map) environmentRunFromWire(raw.cast<String, dynamic>()),
  ];

  /// Every definition in [workspaceId].
  Future<List<EnvironmentDefinitionRecord>> listDefinitions(
    String workspaceId,
  ) async => _definitions(
    await _client.call('environments.listDefinitions', {
      'workspace_id': workspaceId,
    }),
  );

  /// One definition.
  Future<EnvironmentDefinitionRecord> getDefinition(
    String workspaceId,
    String definitionId,
  ) async => environmentDefinitionRecordFromWire(
    await _client.call('environments.getDefinition', {
      'workspace_id': workspaceId,
      'definition_id': definitionId,
    }),
  );

  /// Validates and stores [definition], creating one without [definitionId].
  Future<EnvironmentDefinitionRecord> setDefinition(
    String workspaceId,
    Map<String, dynamic> definition, {
    String? definitionId,
  }) async => environmentDefinitionRecordFromWire(
    await _client.call('environments.setDefinition', {
      'workspace_id': workspaceId,
      'definition_id': ?definitionId,
      'definition': definition,
    }),
  );

  /// Deletes one definition.
  Future<void> deleteDefinition(String workspaceId, String definitionId) =>
      _client.call('environments.deleteDefinition', {
        'workspace_id': workspaceId,
        'definition_id': definitionId,
      });

  /// Scans a repo and proposes a definition. Stores nothing.
  Future<EnvironmentDraft> draftDefinition(
    String workspaceId,
    String repoId,
  ) async {
    final data = await _client.call('environments.draftDefinition', {
      'workspace_id': workspaceId,
      'repo_id': repoId,
    }, timeout: EnvironmentCallBudgets.scan);
    return EnvironmentDraft(
      definition: Map<String, dynamic>.from(data['definition'] as Map),
      notes: [for (final note in (data['notes'] as List?) ?? const []) '$note'],
    );
  }

  /// Links a definition to a file on a repo's default branch and approves the
  /// blob it holds now.
  ///
  /// [blobHash] pins the approval to a blob the admin has seen: saving
  /// overrides passes the already approved hash, so it can't also approve a
  /// newer file nobody reviewed.
  Future<EnvironmentDefinitionRecord> approveSource(
    String workspaceId, {
    String? definitionId,
    required String repoId,
    required String path,
    Map<String, dynamic>? overrides,
    String? blobHash,
  }) async => environmentDefinitionRecordFromWire(
    await _client.call('environments.approveSource', {
      'workspace_id': workspaceId,
      'definition_id': ?definitionId,
      'repo_id': repoId,
      'path': path,
      'overrides': ?overrides,
      'blob_hash': ?blobHash,
    }),
  );

  /// What a linked definition's file holds now, or null when it has no source.
  Future<EnvironmentSourceUpdate?> sourceUpdate(
    String workspaceId,
    String definitionId,
  ) async {
    final data = await _client.call('environments.sourceUpdate', {
      'workspace_id': workspaceId,
      'definition_id': definitionId,
    });
    return environmentSourceUpdateFromWire(data);
  }

  /// Runs a throwaway environment end to end. Returns the run id at once.
  Future<String> testDefinition(String workspaceId, String definitionId) async {
    final data = await _client.call('environments.testDefinition', {
      'workspace_id': workspaceId,
      'definition_id': definitionId,
    }, timeout: EnvironmentCallBudgets.scan);
    return data['run_id'] as String;
  }

  /// Runs a definition's host-readiness checks.
  Future<List<EnvironmentCheckResult>> check(
    String workspaceId,
    String definitionId,
  ) async {
    final data = await _client.call('environments.check', {
      'workspace_id': workspaceId,
      'definition_id': definitionId,
    }, timeout: EnvironmentCallBudgets.check);
    return [
      for (final raw in (data['checks'] as List?) ?? const [])
        if (raw is Map)
          EnvironmentCheckResult(
            id: raw['id'] as String,
            label: raw['label'] as String,
            ok: raw['ok'] == true,
            hint: raw['hint'] as String?,
            fix: raw['fix'] as String?,
          ),
    ];
  }

  /// Recent runs of a definition, newest first.
  Future<List<EnvironmentRun>> listRuns(
    String workspaceId,
    String definitionId,
  ) async => _runs(
    await _client.call('environments.listRuns', {
      'workspace_id': workspaceId,
      'definition_id': definitionId,
    }),
  );

  /// What [definitionId] still holds, in every space.
  Future<List<EnvironmentInstance>> listInstances(
    String workspaceId,
    String definitionId,
  ) async {
    final result = await _client.call('environments.listInstances', {
      'workspace_id': workspaceId,
      'definition_id': definitionId,
    });
    return [
      for (final raw in (result['instances'] as List?) ?? const [])
        if (raw is Map)
          (
            environment: SpaceEnvironment.fromJson(raw.cast<String, dynamic>()),
            spaceName: raw['space_name'] as String?,
          ),
    ];
  }

  /// The definitions [spaceId] can start.
  Future<List<EnvironmentDefinitionRecord>> eligible(
    String workspaceId,
    String spaceId,
  ) async => _definitions(
    await _client.call('environments.eligible', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
    }),
  );

  /// Live environments of a space.
  Stream<List<SpaceEnvironment>> watch(String workspaceId, String spaceId) =>
      _client
          .subscribe('environment.watch', {
            'workspace_id': workspaceId,
            'space_id': spaceId,
          })
          .map(
            (data) => [
              for (final raw in (data['environments'] as List?) ?? const [])
                if (raw is Map)
                  SpaceEnvironment.fromJson(raw.cast<String, dynamic>()),
            ],
          );

  /// Recent runs of a space, live.
  Stream<List<EnvironmentRun>> watchRuns(String workspaceId, String spaceId) =>
      _client
          .subscribe('environment.watchRuns', {
            'workspace_id': workspaceId,
            'space_id': spaceId,
          })
          .map(_runs);

  /// One process or service's output, line by line. Attaches and reads only:
  /// it never starts anything.
  ///
  /// An event stream, so a burst arrives whole rather than as its last line.
  /// `EnvironmentLogLine.seq` is the server's line number when it sends one; a
  /// resubscribe replays the tail, and the seq is what drops the repeats.
  /// [target] is a process, a service, or a compose component's id for all of
  /// its services.
  Stream<EnvironmentLogLine> watchLogs(
    String workspaceId,
    String spaceId, {
    required String target,
    int? tail,
  }) => _client
      .subscribeEvents('environment.watchLogs', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
        'target': target,
        'tail': ?tail,
      })
      .map(
        (data) => (
          line: (data['line'] as String?) ?? '',
          seq: (data['seq'] as num?)?.toInt(),
        ),
      );

  Future<SpaceEnvironment> _environment(
    String op,
    String workspaceId,
    String spaceId,
  ) async => SpaceEnvironment.fromJson(
    await _client.call(op, {
      'workspace_id': workspaceId,
      'space_id': spaceId,
    }, timeout: EnvironmentCallBudgets.lifecycle),
  );

  /// Starts, or reuses, the space's environment.
  Future<SpaceEnvironment> ensure(
    String workspaceId,
    String spaceId, {
    String? definitionId,
    Map<String, dynamic>? options,
  }) async => SpaceEnvironment.fromJson(
    await _client.call('environment.ensure', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'definition_id': ?definitionId,
      'options': ?options,
    }, timeout: EnvironmentCallBudgets.lifecycle),
  );

  /// Runs the tool's `setup` verb on a terminal, returning its session id.
  Future<String> startSetup(String workspaceId, String spaceId) async {
    final result = await _client.call('environment.startSetup', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
    });
    return result['session_id'] as String;
  }

  /// Stops it, keeping what its tools keep.
  Future<SpaceEnvironment> down(String workspaceId, String spaceId) =>
      _environment('environment.down', workspaceId, spaceId);

  /// Returns its data to the baseline.
  Future<SpaceEnvironment> reset(String workspaceId, String spaceId) =>
      _environment('environment.reset', workspaceId, spaceId);

  /// Re-applies the worktree's current state.
  Future<SpaceEnvironment> refresh(String workspaceId, String spaceId) =>
      _environment('environment.refresh', workspaceId, spaceId);

  /// Destroys it.
  Future<void> destroy(String workspaceId, String spaceId) => _client.call(
    'environment.destroy',
    {'workspace_id': workspaceId, 'space_id': spaceId},
    timeout: EnvironmentCallBudgets.lifecycle,
  );

  /// Runs [command] in a service and returns what it printed.
  Future<EnvironmentExecResult> exec(
    String workspaceId,
    String spaceId, {
    required String service,
    required List<String> command,
  }) async {
    final data = await _client.call('environment.exec', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'service': service,
      'command': command,
    }, timeout: EnvironmentCallBudgets.exec);
    return EnvironmentExecResult(
      exitCode: (data['exit_code'] as num?)?.toInt() ?? 0,
      stdout: (data['stdout'] as String?) ?? '',
      stderr: (data['stderr'] as String?) ?? '',
    );
  }

  /// Restarts one component or service. A compose component's id restarts
  /// the whole stack.
  Future<void> restartProcess(
    String workspaceId,
    String spaceId,
    String target,
  ) => _client.call('environment.restartProcess', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'target': target,
  }, timeout: EnvironmentCallBudgets.lifecycle);

  /// Stops one process.
  Future<void> stopProcess(
    String workspaceId,
    String spaceId,
    String componentId,
  ) => _client.call('environment.stopProcess', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'component_id': componentId,
  });

  /// Launches a desktop app, running its prepare task first when [rebuild].
  Future<void> launchApp(
    String workspaceId,
    String spaceId,
    String componentId, {
    bool rebuild = false,
  }) => _client.call('environment.launchApp', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'component_id': componentId,
    if (rebuild) 'rebuild': true,
  }, timeout: EnvironmentCallBudgets.task);

  /// Closes a desktop app.
  Future<void> stopApp(
    String workspaceId,
    String spaceId,
    String componentId,
  ) => _client.call('environment.stopApp', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'component_id': componentId,
  });

  /// Runs a task by id and returns the finished run.
  Future<EnvironmentRun> runTask(
    String workspaceId,
    String spaceId,
    String taskId, {
    List<String>? arguments,
  }) async => environmentRunFromWire(
    await _client.call('environment.runTask', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'task_id': taskId,
      'arguments': ?arguments,
    }, timeout: EnvironmentCallBudgets.task),
  );
}
