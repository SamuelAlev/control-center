import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/repositories/environment_repositories.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_infra/src/environments/cli_driver.dart';
import 'package:cc_infra/src/environments/compose_driver.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_lease_allocator.dart';
import 'package:cc_infra/src/environments/environment_process_supervisor.dart';
import 'package:cc_infra/src/environments/environment_service.dart';
import 'package:cc_infra/src/environments/environment_service_ports.dart';
import 'package:cc_infra/src/environments/environment_task_runner.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart' show RigEnvironmentRoute;

import 'environment_fakes.dart';

/// A throwaway CA, for the routes that re-encrypt to a tool's proxy.
const testCaPem = '''
-----BEGIN CERTIFICATE-----
MIICEjCCAbgCCQDAmI1EUaAb8DAKBggqhkjOPQQDAjAXMRUwEwYDVQQDDAxhY21l
LXRlc3QtY2EwHhcNMjYxMTA2MDA0MTAwWhcNMzYxMTAzMDA0MTAwWjAXMRUwEwYD
VQQDDAxhY21lLXRlc3QtY2EwggFLMIIBAwYHKoZIzj0CATCB9wIBATAsBgcqhkjO
PQEBAiEA/////wAAAAEAAAAAAAAAAAAAAAD///////////////8wWwQg/////wAA
AAEAAAAAAAAAAAAAAAD///////////////wEIFrGNdiqOpPns+u9VXaYhrxlHQaw
zFOw9jvOPD4n0mBLAxUAxJ02CIbnBJNqZnjhE50mt4GffpAEQQRrF9Hy4SxCR/i8
5uVjpEDydwN9gS3rM6D0oTlF2JjClk/jQuL+Gn+bjufrSnwPnhYrzjNXazFezsu2
QGg3v1H1AiEA/////wAAAAD//////////7zm+q2nF56E87nKwvxjJVECAQEDQgAE
nS9Jzi4tlRdh2qoOuSEErXKNY616xhp5g3BvQvDoktXc+z1tWdyInvGSG7Am3Q6T
nLWZO98SSlhxdhXbw0IQZzAKBggqhkjOPQQDAgNIADBFAiBI+7d1dAfkyUVIk8E0
f42zoGSuN8XNqD08Lrr+2mlytAIhAITrl8huy3CFYZxyT/g1Oszh+tQhHRcPxpMn
hTWxgUZ9
-----END CERTIFICATE-----
''';

/// Definitions in a map.
class InMemoryDefinitions implements EnvironmentDefinitionRepository {
  final Map<String, EnvironmentDefinitionRecord> records = {};

  @override
  Future<List<EnvironmentDefinitionRecord>> list(String workspaceId) async => [
    for (final record in records.values)
      if (record.workspaceId == workspaceId) record,
  ];

  @override
  Future<EnvironmentDefinitionRecord?> get(
    String workspaceId,
    String id,
  ) async {
    final record = records[id];
    return record?.workspaceId == workspaceId ? record : null;
  }

  @override
  Future<void> save(EnvironmentDefinitionRecord record) async =>
      records[record.id] = record;

  @override
  Future<void> delete(String workspaceId, String id) async =>
      records.remove(id);
}

/// Environments in a map.
class InMemoryEnvironments implements SpaceEnvironmentRepository {
  final Map<String, SpaceEnvironment> rows = {};

  /// Workspaces whose database can't be read.
  final Set<String> broken = {};

  @override
  Future<List<SpaceEnvironment>> list(String workspaceId) async => [
    if (broken.contains(workspaceId)) throw StateError('database is gone'),
    for (final row in rows.values)
      if (row.workspaceId == workspaceId) row,
  ];

  @override
  Future<List<SpaceEnvironment>> forSpace(
    String workspaceId,
    String spaceId,
  ) async => [
    for (final row in rows.values)
      if (row.workspaceId == workspaceId && row.spaceId == spaceId) row,
  ];

  @override
  Future<SpaceEnvironment?> get(String workspaceId, String id) async {
    final row = rows[id];
    return row?.workspaceId == workspaceId ? row : null;
  }

  @override
  Future<void> save(SpaceEnvironment environment) async =>
      rows[environment.id] = environment;

  @override
  Future<void> delete(String workspaceId, String id) async => rows.remove(id);
}

/// Spaces in a map, enforcing the workspace rule the real one must.
class FakeDirectory implements EnvironmentSpaceDirectory {
  final Map<String, EnvironmentSpaceInfo> spaces = {};
  final Map<String, List<EnvironmentWorkspaceRepo>> repos = {};
  final Map<String, EnvironmentSpaceRepo> addable = {};
  final List<String> added = [];

  @override
  Future<List<String>> workspaceIds() async => repos.keys.toList();

  @override
  Future<EnvironmentSpaceInfo> space(String workspaceId, String spaceId) async {
    final space = spaces[spaceId];
    if (space == null) {
      throw NotFoundException('No space $spaceId');
    }
    if (space.workspaceId != workspaceId) {
      throw const WorkspaceMismatchException('Other workspace');
    }
    return space;
  }

  @override
  Future<EnvironmentSpaceRepo> addRepoToSpace(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    added.add(repoId);
    final repo = addable[repoId]!;
    final space = spaces[spaceId]!;
    spaces[spaceId] = EnvironmentSpaceInfo(
      id: space.id,
      workspaceId: space.workspaceId,
      name: space.name,
      branch: space.branch,
      kind: space.kind,
      repos: [...space.repos, repo],
      prNumber: space.prNumber,
      prRepo: space.prRepo,
      prHeadSha: space.prHeadSha,
      isFork: space.isFork,
    );
    return repo;
  }

  @override
  Future<bool> isRepoLinked(String workspaceId, String repoId) async =>
      (repos[workspaceId] ?? const []).any((repo) => repo.id == repoId);

  @override
  Future<List<EnvironmentWorkspaceRepo>> workspaceRepos(
    String workspaceId,
  ) async => repos[workspaceId] ?? const [];
}

/// Routes in a map.
class FakeRouting implements EnvironmentRoutingPort {
  final Map<String, Map<String, RigEnvironmentRoute>> routes = {};
  int started = 0;

  @override
  Future<int> ensureRouter() async {
    started++;
    return 7355;
  }

  @override
  void setRoutes(
    String environmentId,
    Map<String, RigEnvironmentRoute> routes,
  ) => this.routes[environmentId] = routes;

  @override
  void clearRoutes(String environmentId) => routes.remove(environmentId);
}

/// Records viewers.
class FakeWindows implements EnvironmentHostWindows {
  final List<List<int>> opened = [];
  final List<String> closed = [];

  @override
  Future<String> open({
    required String workspaceId,
    required String spaceId,
    required String environmentId,
    required String componentId,
    required List<int> pids,
    required EnvironmentAppInputMode inputMode,
  }) async {
    opened.add(pids);
    return 'rig-window';
  }

  @override
  Future<void> close(String rigId) async => closed.add(rigId);
}

/// Records rig calls.
class FakeRigHost implements EnvironmentRigHost {
  final List<String> calls = [];
  final List<List<String>> execs = [];
  final List<Map<String, String>> worktrees = [];
  bool running = true;

  @override
  Future<bool> isRunning({
    required String workspaceId,
    required String rigId,
  }) async => running;

  @override
  Future<EnvironmentRigInstance> start({
    required String workspaceId,
    required String spaceId,
    required String environmentId,
    required EnvironmentDefinition definition,
    required Map<String, String> worktrees,
    required Map<String, String> environment,
  }) async {
    calls.add('start');
    this.worktrees.add(worktrees);
    return const EnvironmentRigInstance(rigId: 'rig-env');
  }

  @override
  Future<void> stop({
    required String workspaceId,
    required String rigId,
  }) async => calls.add('stop');

  @override
  Future<void> destroy({
    required String workspaceId,
    required String rigId,
  }) async => calls.add('destroy');

  @override
  Future<EnvironmentExecResult> exec({
    required String workspaceId,
    required String spaceId,
    required List<String> argv,
    String? rigId,
    String? workingDirectory,
    Map<String, String> environment = const {},
    Duration? timeout,
  }) async {
    execs.add(argv);
    return const EnvironmentExecResult(exitCode: 0, stdout: '', stderr: '');
  }
}

const principal = UserPrincipal('member');

/// Everything an [EnvironmentService] test needs, with nothing real behind it
/// but files in a temp directory.
class ServiceHarness {
  ServiceHarness(this.root, {this.rigHost}) {
    runner = FakeCommandRunner(answer);
    groups.onSignal = (group, signal) {
      for (final session in terminals.sessions) {
        if (session.pid == group && !session.exit.isCompleted) {
          session.exit.complete(0);
        }
      }
    };
    directory.repos['ws-a'] = [
      EnvironmentWorkspaceRepo(
        id: 'repo-app',
        name: 'Shop',
        sourcePath: sourcePath,
        defaultBranch: 'main',
      ),
      EnvironmentWorkspaceRepo(
        id: 'repo-e2e',
        name: 'E2E',
        sourcePath: '$root/source-e2e',
        defaultBranch: 'main',
      ),
    ];
    directory.repos['ws-b'] = [
      EnvironmentWorkspaceRepo(
        id: 'repo-b',
        name: 'Other',
        sourcePath: sourcePath,
        defaultBranch: 'main',
      ),
    ];
    Directory(sourcePath).createSync(recursive: true);
    Directory('$root/source-e2e').createSync(recursive: true);
    addSpace('space-1');
    addSpace('space-b', workspace: 'ws-b', repoId: 'repo-b');
  }

  final String root;
  final FakeRigHost? rigHost;

  final definitions = InMemoryDefinitions();
  final environments = InMemoryEnvironments();
  final runs = InMemoryRuns();
  final leases = InMemoryLeases();
  final directory = FakeDirectory();
  final routing = FakeRouting();
  final windows = FakeWindows();
  final events = DomainEventBus();
  final terminals = FakeTerminals();
  final groups = FakeGroups();
  late final FakeCommandRunner runner;

  /// The compose model `config` prints.
  Map<String, dynamic> model = {
    'services': <String, dynamic>{
      'db': {
        'image': 'postgres',
        'ports': [
          {'target': 5432, 'protocol': 'tcp'},
        ],
      },
      'site': {
        'image': 'nginx',
        'ports': [
          {'target': 80, 'protocol': 'tcp'},
        ],
      },
    },
  };

  /// `ps` rows by project, or every service running.
  String Function(FakeCall call)? ps;

  /// Tool verbs by a word of their argv.
  final Map<String, EnvironmentCommandResult> tool = {};

  /// `git` answers by subcommand.
  final Map<String, EnvironmentCommandResult> git = {};

  /// HTTP-speaking ports.
  final Set<int> httpPorts = {};

  /// Set to refuse admin.
  bool admin = false;

  /// Runs when a start asks whether its caller is an admin.
  void Function()? onAdminCheck;

  /// What `syncWorktree` returns.
  List<String>? changedPaths = const [];

  /// How often `syncWorktree` ran.
  int syncs = 0;

  /// When spaces were last active.
  DateTime? activity;

  /// The clock.
  DateTime now = DateTime(2026, 11, 6, 12);

  /// Makes clones for `testDefinition`.
  EnvironmentTestCloneProvider? testClone;

  bool withSync = true;

  String get sourcePath => '$root/source';

  EnvironmentCommandResult answer(FakeCall call) {
    final argv = call.argv;
    if (argv.first == 'git') {
      return git[argv[1]] ?? ok();
    }
    if (argv.first == 'docker') {
      if (argv.contains('version')) {
        return ok('5.5.0');
      }
      if (argv.contains('config')) {
        return ok(jsonEncode(model));
      }
      if (argv.contains('ps')) {
        if (argv[1] == 'ps') {
          return tool['orphans'] ?? ok();
        }
        final custom = ps;
        if (custom != null) {
          return ok(custom(call));
        }
        final services = model['services'] as Map;
        return ok(
          [
            for (final name in services.keys)
              jsonEncode({'Service': name, 'State': 'running', 'Health': ''}),
          ].join('\n'),
        );
      }
      return ok();
    }
    for (final word in argv) {
      final result = tool[word];
      if (result != null) {
        return result;
      }
    }
    return ok();
  }

  late final EnvironmentService service = EnvironmentService(
    EnvironmentServiceDependencies(
      definitions: definitions,
      environments: environments,
      runs: runs,
      leases: leases,
      allocator: EnvironmentLeaseAllocator(
        repository: leases,
        hasListener: (_) async => false,
      ),
      directory: directory,
      routing: routing,
      events: events,
      compose: ComposeDriver(
        runner: runner,
        pollInterval: const Duration(milliseconds: 1),
        httpProbe: (uri) async => httpPorts.contains(uri.port) ? 200 : null,
      ),
      cli: CliDriver(
        runner: runner,
        pollInterval: const Duration(milliseconds: 1),
      ),
      supervisor: supervisor,
      tasks: EnvironmentTaskRunner(runs: runs, runner: runner),
      runner: runner,
      stateDirFor: (ws, id) => '$root/data/$ws/environments/$id',
      isAdmin: (ws, by) async {
        onAdminCheck?.call();
        return admin;
      },
      home: root,
      windows: windows,
      rigHost: rigHost,
      syncWorktree: withSync
          ? ({required workspaceId, required spaceId, required headSha}) async {
              syncs++;
              return changedPaths;
            }
          : null,
      lastActivity: (ws, spaceId) async => activity,
      testClone: testClone,
      now: () => now,
      maintenanceInterval: const Duration(hours: 1),
    ),
  );

  late final EnvironmentProcessSupervisor supervisor =
      EnvironmentProcessSupervisor(
        terminals: terminals,
        groups: groups,
        binaryResolver: (name) async => '/usr/bin/$name',
        httpProbe: (uri) async => 200,
        tcpProbe: (host, port) async => true,
        hasGuiSession: () => true,
        backoffStart: const Duration(milliseconds: 1),
        backoffMax: const Duration(milliseconds: 2),
        sigtermAfter: const Duration(milliseconds: 20),
        sigkillAfter: const Duration(milliseconds: 40),
        probeInterval: const Duration(milliseconds: 1),
        exitPollInterval: const Duration(milliseconds: 1),
        reapGrace: const Duration(milliseconds: 1),
      );

  /// A space holding [repoId], with a real worktree and compose file.
  EnvironmentSpaceInfo addSpace(
    String id, {
    String workspace = 'ws-a',
    String repoId = 'repo-app',
    String kind = 'space',
    int? prNumber,
    String? prRepo,
    bool isFork = false,
    String? branch,
    String? prHeadSha,
    List<EnvironmentSpaceRepo>? extraRepos,
  }) {
    final worktree = '$root/worktrees/$id';
    Directory(worktree).createSync(recursive: true);
    File('$worktree/compose.yaml').writeAsStringSync('services: {}\n');
    final space = EnvironmentSpaceInfo(
      id: id,
      workspaceId: workspace,
      name: 'Space $id',
      branch: branch ?? 'fix/$id',
      kind: kind,
      repos: [
        EnvironmentSpaceRepo(
          repoId: repoId,
          name: 'Shop',
          slug: 'shop',
          worktreePath: worktree,
          sourcePath: sourcePath,
          branch: branch ?? 'fix/$id',
        ),
        ...?extraRepos,
      ],
      prNumber: prNumber,
      prRepo: prRepo,
      prHeadSha: prHeadSha,
      isFork: isFork,
    );
    directory.spaces[id] = space;
    return space;
  }

  /// Stores [json] as a definition, unchecked, the way an old row would be.
  String store(
    Map<String, dynamic> json, {
    String id = 'def-1',
    String workspace = 'ws-a',
  }) {
    definitions.records[id] = EnvironmentDefinitionRecord(
      id: id,
      workspaceId: workspace,
      name: '${json['name']}',
      definitionJson: jsonEncode(json),
      createdAt: now,
      updatedAt: now,
    );
    return id;
  }

  Future<SpaceEnvironment> ensure({
    String space = 'space-1',
    String? definitionId,
    Map<String, dynamic> options = const {},
    Principal by = principal,
  }) => service.ensure(
    workspaceId: directory.spaces[space]!.workspaceId,
    spaceId: space,
    definitionId: definitionId,
    options: options,
    by: by,
  );

  /// What ran, as lines, minus reads nobody cares about.
  List<String> get commands => [
    for (final call in runner.calls)
      if (call.argv.first != 'git' &&
          !call.argv.contains('config') &&
          !call.argv.contains('ps'))
        call.argv.contains('compose')
            ? 'compose ${call.argv.sublist(_verbAt(call.argv)).join(' ')}'
            : call.argv.join(' '),
  ];

  /// Where the verb starts: after any `-f <file>`, or else `-p <project>`.
  int _verbAt(List<String> argv) {
    final files = argv.lastIndexOf('-f');
    return (files < 0 ? argv.indexOf('-p') : files) + 2;
  }

  /// Waits for [condition].
  Future<void> until(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('condition not met');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }
}

/// A definition around [components], one role by default.
Map<String, dynamic> definitionJson(
  List<Map<String, dynamic>> components, {
  Map<String, dynamic>? repos,
  Map<String, dynamic> extra = const {},
}) => {
  'contract': 1,
  'name': 'Shop',
  'repos':
      repos ??
      {
        'app': {'repoId': 'repo-app', 'anchor': true, 'required': true},
      },
  'naming': {'template': '{branch}', 'project': 'shop'},
  'components': components,
  ...extra,
};

Map<String, dynamic> composeJson() => {
  'kind': 'compose',
  'id': 'stack',
  'build': false,
};

Map<String, dynamic> webJson({Map<String, dynamic> extra = const {}}) => {
  'kind': 'process',
  'id': 'web',
  'port': 'web',
  'endpoint': {'role': 'web', 'primary': true},
  'command': ['pnpm', 'dev', '--port', '{port.web}'],
  ...extra,
};

Map<String, dynamic> taskJson(
  String id,
  List<String> when, {
  Map<String, dynamic> extra = const {},
}) => {
  'kind': 'task',
  'id': id,
  'when': when,
  'command': ['tool', id],
  ...extra,
};
