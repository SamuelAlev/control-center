import 'dart:async';
import 'dart:convert';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:flutter_test/flutter_test.dart';

const kWorkspace = 'ws-test';
const kSpace = 'space-1';

/// A stored definition, one compose component unless [components] says else.
EnvironmentDefinitionRecord definitionRecord({
  String id = 'def-1',
  String name = 'Shop',
  List<Map<String, dynamic>>? components,
  List<Map<String, dynamic>> options = const [],
  bool runsOnHost = false,
  bool hostApproved = false,
}) => EnvironmentDefinitionRecord(
  id: id,
  workspaceId: kWorkspace,
  name: name,
  definitionJson: jsonEncode({
    'contract': 1,
    'name': name,
    'repos': {
      'app': {'repoId': 'repo-1', 'anchor': true, 'required': true},
    },
    'options': options,
    'components':
        components ??
        [
          {'kind': 'compose', 'id': 'stack'},
        ],
  }),
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  runsOnHost: runsOnHost,
  hostApproved: hostApproved,
);

/// An environment in [status] with [components].
SpaceEnvironment environment({
  EnvironmentStatus status = EnvironmentStatus.ready,
  List<EnvironmentComponentState> components = const [],
  List<EnvironmentEndpoint> endpoints = const [],
  EnvironmentError? lastError,
  bool needsRecreate = false,
  Map<String, dynamic> options = const {},
}) => SpaceEnvironment(
  id: 'env-1',
  workspaceId: kWorkspace,
  spaceId: kSpace,
  definitionId: 'def-1',
  name: 'fix-login',
  status: status,
  components: components,
  endpoints: endpoints,
  lastError: lastError,
  needsRecreate: needsRecreate,
  options: options,
  createdBy: 'user-1',
  createdAt: DateTime.utc(2026),
  lastUsedAt: DateTime.utc(2026),
);

/// Records what the UI forwards.
class FakeEnvironmentRepository extends Fake
    implements RpcEnvironmentRepository {
  FakeEnvironmentRepository({
    this.environments = const [],
    this.runs = const [],
    this.eligibleDefinitions = const [],
    this.definitions,
    this.checks = const [],
    this.setDefinitionError,
    this.draft,
  });

  List<SpaceEnvironment> environments;
  List<EnvironmentRun> runs;
  List<EnvironmentDefinitionRecord> eligibleDefinitions;
  List<EnvironmentDefinitionRecord>? definitions;
  List<EnvironmentCheckResult> checks;
  Object? setDefinitionError;
  EnvironmentDraft? draft;

  final List<String> calls = [];

  /// What `ensure` answers, when it isn't a ready environment.
  SpaceEnvironment? ensureResult;

  /// Holds `ensure` open until completed, like a real start would.
  Completer<void>? ensureGate;

  /// What `watch` streams instead of [environments], for rows that land while
  /// something else is in flight. Every subscriber starts from the rows last
  /// published, as the server's watch does.
  Stream<List<SpaceEnvironment>>? liveRows;

  Stream<List<SpaceEnvironment>>? _liveSource;
  final _live = StreamController<List<SpaceEnvironment>>.broadcast();
  List<SpaceEnvironment>? _liveLast;

  Stream<List<SpaceEnvironment>> _liveFrom(
    Stream<List<SpaceEnvironment>> source,
  ) {
    if (!identical(_liveSource, source)) {
      _liveSource = source;
      source.listen((rows) {
        _liveLast = rows;
        _live.add(rows);
      });
    }
    return Stream.multi((subscriber) {
      final last = _liveLast;
      if (last != null) {
        subscriber.add(last);
      }
      final rows = _live.stream.listen(subscriber.add);
      subscriber.onCancel = rows.cancel;
    });
  }

  /// Whether the last start said someone is there to answer a terminal.
  bool? lastAttended;

  /// The `can_operate` every `watch` frame carries.
  bool canOperate = true;
  Map<String, dynamic>? lastOptions;
  String? lastDefinitionId;
  Map<String, dynamic>? savedDefinition;

  /// What `listInstances` answers.
  List<EnvironmentInstance> instances = const [];

  @override
  Future<List<EnvironmentInstance>> listInstances(
    String workspaceId,
    String definitionId,
  ) async => instances;

  @override
  Future<void> destroy(String workspaceId, String spaceId) async {
    calls.add('destroy');
  }

  @override
  Stream<SpaceEnvironmentsFrame> watch(String workspaceId, String spaceId) {
    calls.add('watch');
    final error = readError;
    if (error != null) {
      return Stream.error(error);
    }
    final live = liveRows;
    return (live == null ? Stream.value(environments) : _liveFrom(live)).map(
      (rows) => (environments: rows, canOperate: canOperate),
    );
  }

  @override
  Stream<List<EnvironmentRun>> watchRuns(String workspaceId, String spaceId) =>
      Stream.value(runs);

  /// Lines [watchLogs] replays, as the server would after a reconnect.
  List<EnvironmentLogLine> logLines = const [];

  /// Thrown by every read, to stand in for a server without the ops.
  Object? readError;

  @override
  Stream<EnvironmentLogLine> watchLogs(
    String workspaceId,
    String spaceId, {
    required String target,
    int? tail,
  }) {
    calls.add('watchLogs:$target');
    return Stream.fromIterable(logLines);
  }

  @override
  Future<List<EnvironmentDefinitionRecord>> eligible(
    String workspaceId,
    String spaceId,
  ) async {
    calls.add('eligible');
    final error = readError;
    if (error != null) {
      throw error;
    }
    return eligibleDefinitions;
  }

  @override
  Future<List<EnvironmentDefinitionRecord>> listDefinitions(
    String workspaceId,
  ) async {
    final error = readError;
    if (error != null) {
      throw error;
    }
    return definitions ?? eligibleDefinitions;
  }

  @override
  Future<void> deleteDefinition(String workspaceId, String id) async {
    definitions = [...?definitions]..removeWhere((each) => each.id == id);
  }

  @override
  Future<List<EnvironmentCheckResult>> check(
    String workspaceId,
    String definitionId,
  ) async => checks;

  @override
  Future<SpaceEnvironment> ensure(
    String workspaceId,
    String spaceId, {
    String? definitionId,
    Map<String, dynamic>? options,
    bool attended = false,
  }) async {
    calls.add('ensure');
    lastAttended = attended;
    await ensureGate?.future;
    lastDefinitionId = definitionId;
    lastOptions = options;
    return ensureResult ?? environment();
  }

  @override
  Future<SpaceEnvironment> reset(
    String workspaceId,
    String spaceId, {
    bool attended = false,
  }) async {
    calls.add('reset');
    lastAttended = attended;
    return environment();
  }

  @override
  Future<SpaceEnvironment> down(String workspaceId, String spaceId) async {
    calls.add('down');
    return environment(status: EnvironmentStatus.stopped);
  }

  @override
  Future<SpaceEnvironment> refresh(String workspaceId, String spaceId) async {
    calls.add('refresh');
    return environment();
  }

  @override
  Future<void> restartProcess(
    String workspaceId,
    String spaceId,
    String target,
  ) async => calls.add('restart:$target');

  @override
  Future<void> launchApp(
    String workspaceId,
    String spaceId,
    String componentId, {
    bool rebuild = false,
  }) async => calls.add('launch:$componentId:$rebuild');

  @override
  Future<EnvironmentRun> runTask(
    String workspaceId,
    String spaceId,
    String taskId, {
    List<String>? arguments,
  }) async {
    calls.add('run:$taskId');
    return EnvironmentRun(
      id: 'run',
      workspaceId: workspaceId,
      kind: EnvironmentRunKind.task,
      status: EnvironmentRunStatus.succeeded,
      startedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<EnvironmentDefinitionRecord> setDefinition(
    String workspaceId,
    Map<String, dynamic> definition, {
    String? definitionId,
  }) async {
    calls.add('setDefinition');
    final error = setDefinitionError;
    if (error != null) {
      throw error;
    }
    savedDefinition = definition;
    return definitionRecord(id: definitionId ?? 'def-new');
  }
}

/// Records what the section asks its host to open.
class RecordingHost {
  final List<String> opened = [];

  /// Whether the surface is still on the space that started.
  bool onSpace = true;

  late final EnvironmentHost host = EnvironmentHost(
    openUrl: ({required url, required label}) => opened.add('url:$url'),
    openBrowserVm: ({required spaceId}) => opened.add('vm:$spaceId'),
    openLogs: ({required spaceId, required target, required label}) =>
        opened.add('logs:$target'),
    openProvisioningLogs: ({required spaceId}) =>
        opened.add('provisioning-logs:$spaceId'),
    openProcess: ({required spaceId, required sessionId, required label}) =>
        opened.add('process:$sessionId'),
    openStartTerminal:
        ({required spaceId, required sessionId, required label}) =>
            opened.add('start-terminal:$sessionId'),
    openViewer: ({required spaceId, required componentId, required label}) =>
        opened.add('viewer:$componentId'),
    openPrefilledTerminal: ({required spaceId, required command}) =>
        opened.add('terminal:$command'),
    showsSpace: (spaceId) => onSpace,
  );
}
