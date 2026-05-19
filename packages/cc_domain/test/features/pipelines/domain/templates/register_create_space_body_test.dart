import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pipelines/domain/templates/register_create_space_body.dart';
import 'package:test/test.dart';

class _FakeMessagingPort implements MessagingPort {
  _FakeMessagingPort({this.existingSpaces = const {}, this.onCreateSpace});

  final Set<String> existingSpaces;
  final void Function()? onCreateSpace;

  final List<
    ({
      String name,
      List<String> agentIds,
      Mode mode,
      List<String>? repoIds,
      Map<String, String>? repoBranches,
      String? pipelineRunId,
    })
  >
  created = [];
  final List<({String spaceId, String agentId, bool rename})> addedAgents = [];
  final List<String> cancelledProvisioning = [];
  final List<({String spaceId, String title, String? principalId, bool reuse})>
  conversations = [];

  /// Returned by [createConversation]; null models a host with no conversation
  /// store wired.
  String? conversationId = 'conv-1';

  @override
  Future<String?> createConversation({
    required String workspaceId,
    required String spaceId,
    required String title,
    String? createdByPrincipalId,
    bool reuseExisting = false,
  }) async {
    conversations.add((
      spaceId: spaceId,
      title: title,
      principalId: createdByPrincipalId,
      reuse: reuseExisting,
    ));
    return conversationId;
  }

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async =>
      existingSpaces.contains(spaceId);

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
  }) async {
    created.add((
      name: name,
      agentIds: agentIds,
      mode: mode,
      repoIds: repoIds,
      repoBranches: repoBranches,
      pipelineRunId: pipelineRunId,
    ));
    onCreateSpace?.call();
    return Space(
      id: 'space-${created.length}',
      name: name,
      workspaceId: workspaceId,
      pipelineRunId: pipelineRunId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  Future<void> addAgentToSpace(
    String workspaceId,
    String spaceId,
    String agentId, {
    bool renameForGroup = true,
  }) async => addedAgents.add((
    spaceId: spaceId,
    agentId: agentId,
    rename: renameForGroup,
  ));

  @override
  Future<void> cancelSpaceProvisioning(
    String workspaceId,
    String spaceId,
  ) async => cancelledProvisioning.add(spaceId);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');

  /// Context and branch surfaces this fake does not exercise.
  @override
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target = 'tool_output',
  }) async => const ConversationShakeResult();

  @override
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input = '',
  }) async => const ConversationSideChannelResult();

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
  }) async => const GuidedGoalStepResult();
}

class _FakeMessagingRepository implements MessagingRepository {
  _FakeMessagingRepository({this.statuses = const []});

  /// Statuses handed out in order, the last one repeating — so a test can make
  /// the space provision after N polls.
  final List<SpaceProvisioningStatus> statuses;
  int reads = 0;

  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async {
    final status = statuses.isEmpty
        ? SpaceProvisioningStatus.ready
        : statuses[reads.clamp(0, statuses.length - 1)];
    reads++;
    return Space(
      id: spaceId,
      name: 'room',
      workspaceId: workspaceId,
      provisioningStatus: status,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

class _FakeIsolatedRepos implements IsolatedRepoRepository {
  _FakeIsolatedRepos([this.rows = const []]);

  final List<IsolatedRepo> rows;

  @override
  Future<List<IsolatedRepo>> forSpace(
    String workspaceId,
    String spaceId,
  ) async => rows;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _FakeAgentRepository implements AgentRepository {
  _FakeAgentRepository(this.known);

  final Set<String> known;

  @override
  Future<Agent?> getById(String workspaceId, String agentId) async {
    if (!known.contains(agentId)) {
      return null;
    }
    return Agent(
      id: agentId,
      name: agentId,
      title: 'Specialist',
      agentMdPath: '/agents/$agentId.md',
      workspaceId: workspaceId,
      skills: AgentSkills(const []),
      createdAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _FakeTemplateRepository implements PipelineTemplateRepository {
  _FakeTemplateRepository(this.config, {this.extraSteps = const []});

  final PipelineNodeConfig config;

  /// Steps beside the space node — the agent steps whose roster the space node
  /// derives.
  final List<PipelineStepDefinition> extraSteps;

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async => PipelineDefinition(
    templateId: templateId,
    workspaceId: workspaceId,
    name: 'T',
    description: 'T',
    steps: [
      PipelineStepDefinition(
        id: 'space',
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.createSpace,
        config: config,
      ),
      ...extraSteps,
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _FakeRunRepository implements PipelineRunRepository {
  _FakeRunRepository({this.priorSpaceId});

  final String? priorSpaceId;
  final List<String?> linked = [];

  @override
  Future<void> updateStepRun(
    String workspaceId,
    String stepRunId, {
    Object? status,
    String? inputJson,
    String? outputJson,
    String? spaceId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async => linked.add(spaceId);

  @override
  Future<PipelineStepRun?> getStepRunById(
    String workspaceId,
    String stepRunId,
  ) async => PipelineStepRun(
    id: stepRunId,
    pipelineRunId: 'run-1',
    stepId: 'space',
    status: PipelineStepStatus.running,
    spaceId: priorSpaceId,
    startedAt: DateTime(2026),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

PipelineContext _ctx({
  Map<String, dynamic> state = const {},
  Map<String, dynamic>? trigger,
  bool dryRun = false,
}) => PipelineContext(
  pipelineRunId: 'run-1',
  templateId: 'index_code',
  stepId: 'space',
  stepRunId: 'steprun-1',
  workspaceId: 'ws-1',
  state: state,
  triggerPayload: trigger,
  dryRun: dryRun,
);

typedef _Harness = ({
  StepBodyFn body,
  _FakeMessagingPort messaging,
  _FakeRunRepository runs,
  StepProcessRegistry stepProcess,
});

_Harness _harness({
  required PipelineNodeConfig config,
  List<PipelineStepDefinition> extraSteps = const [],
  Set<String> agents = const {'librarian'},
  Set<String> existingSpaces = const {},
  String? priorSpaceId,
  List<SpaceProvisioningStatus> statuses = const [],
  List<IsolatedRepo> worktrees = const [],
  void Function()? onCreateSpace,
  Future<String?> Function({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String title,
  })?
  ensureReviewSpace,
}) {
  final registry = PipelineBodyRegistry();
  final messaging = _FakeMessagingPort(
    existingSpaces: existingSpaces,
    onCreateSpace: onCreateSpace,
  );
  final runs = _FakeRunRepository(priorSpaceId: priorSpaceId);
  final stepProcess = StepProcessRegistry();
  registerCreateSpaceBody(
    registry,
    templateRepository: _FakeTemplateRepository(config, extraSteps: extraSteps),
    agentRepository: _FakeAgentRepository(agents),
    messagingPort: messaging,
    messagingRepository: _FakeMessagingRepository(statuses: statuses),
    isolatedRepoRepository: _FakeIsolatedRepos(worktrees),
    stepProcessRegistry: stepProcess,
    runRepository: runs,
    ensureReviewSpace: ensureReviewSpace,
  );
  return (
    body: registry.body(BuiltInBodyKeys.createSpace),
    messaging: messaging,
    runs: runs,
    stepProcess: stepProcess,
  );
}

IsolatedRepo _worktree(String repoId, String path) => IsolatedRepo(
  id: 'iso-$repoId',
  workspaceId: 'ws-1',
  spaceId: 'space-1',
  repoId: repoId,
  path: path,
  branch: 'conv/abc',
  backend: RepoIsolationBackend.rift,
  sourcePath: '/src/$repoId',
  createdAt: DateTime(2026),
);

void main() {
  group('messaging.createSpace — the room it opens', () {
    test('creates a VISIBLE space: no pipelineRunId is stamped on it', () async {
      // A space carrying a pipelineRunId is filtered out of the sidebar. That
      // is what made every pipeline conversation invisible, reachable only from
      // the step-detail panel.
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          repoIds: ['repo-1'],
          outputKey: kPipelineSpaceStateKey,
          extras: {
            'agentIds': ['librarian'],
          },
        ),
      );

      final result = await h.body(_ctx());

      expect(result.isFailed, isFalse);
      expect(h.messaging.created.single.pipelineRunId, isNull);
      expect(result.mutatedState![kPipelineSpaceStateKey], 'space-1');
      // Linked onto the step run, so the panel can open it and a retry reuses
      // it rather than provisioning a second checkout.
      expect(h.runs.linked, ['space-1']);
    });

    test('checks out only the declared repos', () async {
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          repoIds: ['{{repo_id}}'],
          extras: {
            'agentIds': ['librarian'],
          },
        ),
      );

      await h.body(_ctx(trigger: {'repo_id': 'repo-42'}));

      expect(h.messaging.created.single.repoIds, ['repo-42']);
      expect(h.messaging.created.single.repoBranches, isEmpty);
    });

    test('a repo entry can pin the branch its worktree is cut from', () async {
      // `repoId@branch`: the whole entry is rendered first, so either half can
      // come from the trigger. Without this a template could only ever review
      // the default branch, which is the wrong tree for a release check.
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Release audit',
          repoIds: ['{{repo_id}}@{{head_ref}}', 'repo-2@release/1.2'],
          extras: {
            'agentIds': ['librarian'],
          },
        ),
      );

      await h.body(
        _ctx(trigger: {'repo_id': 'repo-42', 'head_ref': 'hotfix/login'}),
      );

      final created = h.messaging.created.single;
      // The id is the id: the branch is carried beside it, never folded in.
      expect(created.repoIds, ['repo-42', 'repo-2']);
      expect(created.repoBranches, {
        'repo-42': 'hotfix/login',
        'repo-2': 'release/1.2',
      });
    });

    test('a repo entry with no branch half is taken verbatim', () async {
      // A bare `@branch` or a trailing `@` is a typo, and reading either as
      // "no repo" / "no branch" hides it — the id keeps the whole string and
      // the provision fails loudly on an id that does not exist.
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          repoIds: ['repo-1@', '@release/1.2'],
          extras: {
            'agentIds': ['librarian'],
          },
        ),
      );

      await h.body(_ctx());

      expect(h.messaging.created.single.repoIds, ['repo-1@', '@release/1.2']);
      expect(h.messaging.created.single.repoBranches, isEmpty);
    });

    test(
      'an unresolved repo scope checks out NOTHING, never everything',
      () async {
        final h = _harness(
          config: const PipelineNodeConfig(
            label: 'Code analysis',
            repoIds: ['{{repo_id}}'],
            extras: {
              'agentIds': ['librarian'],
            },
          ),
        );

        await h.body(_ctx());

        expect(h.messaging.created.single.repoIds, isEmpty);
      },
    );

    test('an empty repo scope checks out nothing', () async {
      // Meeting summaries and PR digests reshape text; they used to drag every
      // workspace repo onto disk to do it.
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Meeting',
          extras: {
            'agentIds': ['librarian'],
            'mode': 'chat',
          },
        ),
      );

      await h.body(_ctx());

      expect(h.messaging.created.single.repoIds, isEmpty);
      expect(h.messaging.created.single.mode, Mode.chat);
    });

    test('opts into every workspace repo only when asked explicitly', () async {
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Everything',
          extras: {'agentIds': <String>[], 'allRepos': true},
        ),
      );

      await h.body(_ctx());

      expect(h.messaging.created.single.repoIds, isNull);
    });

    test('opens with only the declared agents, dropping unknown ones', () async {
      // Deleting one specialist must not fail every run of the template at its
      // first step; the agents that do run join on dispatch anyway.
      final h = _harness(
        agents: {'librarian'},
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          extras: {
            'agentIds': ['librarian', 'deleted-agent', 'librarian'],
          },
        ),
      );

      await h.body(_ctx());

      expect(h.messaging.created.single.agentIds, ['librarian']);
    });

    test(
      'names the room from state, tidying an unresolved placeholder',
      () async {
        final h = _harness(
          config: const PipelineNodeConfig(
            label: 'Code analysis · {{repo_name}}',
            extras: {
              'agentIds': ['librarian'],
            },
          ),
        );

        await h.body(_ctx(trigger: {'repo_name': 'control-center'}));
        await h.body(_ctx());

        expect(h.messaging.created.map((c) => c.name), [
          'Code analysis · control-center',
          // The dangling separator is dropped rather than shipped as a name.
          'Code analysis',
        ]);
      },
    );
  });

  group('messaging.createSpace — the roster it opens with', () {
    PipelineStepDefinition agentStep({
      required String id,
      required String agentId,
      String room = '{{$kPipelineSpaceStateKey}}',
      Map<String, dynamic>? runWhen,
    }) => PipelineStepDefinition(
      id: id,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      config: PipelineNodeConfig(
        agentId: agentId,
        label: id,
        extras: {'spaceId': room, 'runWhen': ?runWhen},
      ),
    );

    test('takes the agents its own steps dispatch into it', () async {
      // The node does not have to repeat a roster its agent steps already
      // state. Adding a reviewer wires it into the sidebar by adding the step.
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Review',
          outputKey: kPipelineSpaceStateKey,
          repoIds: ['repo-1'],
        ),
        agents: const {'qa', 'architect'},
        extraSteps: [
          agentStep(id: 'qa_review', agentId: 'qa'),
          agentStep(id: 'arch_review', agentId: 'architect'),
        ],
      );

      await h.body(_ctx());

      expect(h.messaging.created.single.agentIds, ['qa', 'architect']);
    });

    test('leaves a gated step\'s agent off until it is dispatched', () async {
      // A `runWhen` branch may never fire on this run; seeding it fills the
      // sidebar with an agent that never speaks. It joins on dispatch.
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Review',
          outputKey: kPipelineSpaceStateKey,
          repoIds: ['repo-1'],
        ),
        agents: const {'qa', 'architect'},
        extraSteps: [
          agentStep(id: 'qa_review', agentId: 'qa'),
          agentStep(
            id: 'deep_review',
            agentId: 'architect',
            runWhen: const {
              'key': 'level',
              'in': ['deep'],
            },
          ),
        ],
      );

      await h.body(_ctx());

      expect(h.messaging.created.single.agentIds, ['qa']);
    });

    test('ignores steps that work in a different room', () async {
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Review',
          outputKey: kPipelineSpaceStateKey,
          repoIds: ['repo-1'],
        ),
        agents: const {'qa', 'architect'},
        extraSteps: [
          agentStep(id: 'qa_review', agentId: 'qa'),
          agentStep(
            id: 'elsewhere',
            agentId: 'architect',
            room: '{{someOtherRoom}}',
          ),
        ],
      );

      await h.body(_ctx());

      expect(h.messaging.created.single.agentIds, ['qa']);
    });

    test('keeps an explicitly declared roster and adds to it', () async {
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Review',
          outputKey: kPipelineSpaceStateKey,
          repoIds: ['repo-1'],
          extras: {
            'agentIds': ['ceo'],
          },
        ),
        agents: const {'ceo', 'qa'},
        extraSteps: [agentStep(id: 'qa_review', agentId: 'qa')],
      );

      await h.body(_ctx());

      expect(h.messaging.created.single.agentIds, ['ceo', 'qa']);
    });
  });

  group('messaging.createSpace — reuse', () {
    test('a retry reuses the room the first attempt opened', () async {
      // Re-firing the body on the row it owns must not mint a second room and
      // a second checkout of the same repo.
      final h = _harness(
        priorSpaceId: 'space-from-attempt-1',
        existingSpaces: {'space-from-attempt-1'},
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          extras: {
            'agentIds': ['librarian'],
          },
        ),
      );

      final result = await h.body(_ctx());

      expect(h.messaging.created, isEmpty);
      expect(
        result.mutatedState![kPipelineSpaceStateKey],
        'space-from-attempt-1',
      );
    });

    test('a room that was deleted falls back to a fresh one', () async {
      final h = _harness(
        priorSpaceId: 'deleted-space',
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          extras: {
            'agentIds': ['librarian'],
          },
        ),
      );

      final result = await h.body(_ctx());

      expect(result.mutatedState![kPipelineSpaceStateKey], 'space-1');
    });

    test('seeds the roster of a room it did not create', () async {
      final h = _harness(
        priorSpaceId: 'existing',
        existingSpaces: {'existing'},
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          extras: {
            'agentIds': ['librarian'],
          },
        ),
      );

      await h.body(_ctx());

      expect(h.messaging.addedAgents.single.agentId, 'librarian');
      // Never renames a room that belongs to someone else.
      expect(h.messaging.addedAgents.single.rename, isFalse);
    });
  });

  group('messaging.createSpace — the checkout', () {
    test('publishes the copy-on-write worktree as repoLocalPath', () async {
      // The scripts and routers downstream keep reading `repoLocalPath`,
      // pointed at the room's CoW checkout instead of a fresh network clone.
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Dependency audit',
          repoIds: ['repo-1'],
          extras: {
            'agentIds': ['librarian'],
            'awaitReady': true,
          },
        ),
        worktrees: [_worktree('repo-1', '/data/ws-1/spaces/s1/repos/app')],
      );

      final result = await h.body(_ctx());

      expect(
        result.mutatedState!['repo_local_path'],
        '/data/ws-1/spaces/s1/repos/app',
      );
      expect(result.mutatedState!['space_repo_paths'], {
        'repo-1': '/data/ws-1/spaces/s1/repos/app',
      });
    });

    test('waits for provisioning before publishing the path', () async {
      final messagingRepo = _FakeMessagingRepository(
        statuses: const [
          SpaceProvisioningStatus.provisioning,
          SpaceProvisioningStatus.provisioning,
          SpaceProvisioningStatus.ready,
        ],
      );
      final registry = PipelineBodyRegistry();
      registerCreateSpaceBody(
        registry,
        templateRepository: _FakeTemplateRepository(
          const PipelineNodeConfig(
            label: 'Audit',
            repoIds: ['repo-1'],
            extras: {'agentIds': <String>[], 'awaitReady': true},
          ),
        ),
        agentRepository: _FakeAgentRepository(const {}),
        messagingPort: _FakeMessagingPort(),
        messagingRepository: messagingRepo,
        isolatedRepoRepository: _FakeIsolatedRepos([
          _worktree('repo-1', '/data/repos/app'),
        ]),
        stepProcessRegistry: StepProcessRegistry(),
        runRepository: _FakeRunRepository(),
      );

      final result = await registry.body(BuiltInBodyKeys.createSpace)(_ctx());

      expect(result.isFailed, isFalse);
      expect(messagingRepo.reads, 3);
      expect(result.mutatedState!['repo_local_path'], '/data/repos/app');
    });

    test('fails the step when the checkout fails', () async {
      // Continuing would hand a manifest router an empty `repos/` and read the
      // resulting "no Cargo.toml here" as an answer about the repository.
      final registry = PipelineBodyRegistry();
      registerCreateSpaceBody(
        registry,
        templateRepository: _FakeTemplateRepository(
          const PipelineNodeConfig(
            label: 'Audit',
            repoIds: ['repo-1'],
            extras: {'agentIds': <String>[], 'awaitReady': true},
          ),
        ),
        agentRepository: _FakeAgentRepository(const {}),
        messagingPort: _FakeMessagingPort(),
        messagingRepository: _FakeMessagingRepository(
          statuses: const [SpaceProvisioningStatus.failed],
        ),
        isolatedRepoRepository: _FakeIsolatedRepos(),
        stepProcessRegistry: StepProcessRegistry(),
        runRepository: _FakeRunRepository(),
      );

      final result = await registry.body(BuiltInBodyKeys.createSpace)(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('failed to provision'));
    });

    test(
      'leaves repoLocalPath alone when the room holds no worktree',
      () async {
        // Overwriting it with an empty string would replace the value a manual
        // run's repo picker put there with one that resolves to nothing.
        final h = _harness(
          config: const PipelineNodeConfig(
            label: 'Digest',
            extras: {'agentIds': <String>[], 'awaitReady': true},
          ),
        );

        final result = await h.body(
          _ctx(state: {'repo_local_path': '/from/form'}),
        );

        expect(result.mutatedState!.containsKey('repo_local_path'), isFalse);
      },
    );
  });

  group('messaging.createSpace — the pull request lane', () {
    test('resolves the PR room through the shared resolver', () async {
      // The room a human opening that PR gets: one checkout, fetched and
      // switched to the PR head, instead of a clone per pipeline.
      final asked = <String>[];
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'PR triage #{{pr_number}}',
          extras: {
            'agentIds': ['librarian'],
            'pr': true,
          },
        ),
        ensureReviewSpace:
            ({
              required String workspaceId,
              required String repoFullName,
              required int prNumber,
              required String prExternalId,
              String title = '',
            }) async {
              asked.add(prExternalId);
              return 'pr-space';
            },
      );

      final result = await h.body(
        _ctx(trigger: {'repo_full_name': 'acme/app', 'pr_number': 42}),
      );

      expect(result.mutatedState![kPipelineSpaceStateKey], 'pr-space');
      // The canonical forge id, so a manual run reuses the same room as a
      // webhook-driven one.
      expect(asked, ['acme/app#42']);
      expect(result.mutatedState!['pr_external_id'], 'acme/app#42');
      expect(h.messaging.created, isEmpty);
    });

    test('fails loudly when no resolver is wired', () async {
      // Never a silent fall back to a room checked out on the default branch:
      // that is a review of the wrong tree, reported as a review.
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'PR triage',
          extras: {'agentIds': <String>[], 'pr': true},
        ),
      );

      final result = await h.body(
        _ctx(trigger: {'repo_full_name': 'acme/app', 'pr_number': 42}),
      );

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('no PR-space resolver'));
    });

    test('fails when the PR number is missing', () async {
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'PR triage',
          extras: {'agentIds': <String>[], 'pr': true},
        ),
        ensureReviewSpace:
            ({
              required String workspaceId,
              required String repoFullName,
              required int prNumber,
              required String prExternalId,
              String title = '',
            }) async => 'pr-space',
      );

      final result = await h.body(
        _ctx(trigger: {'repo_full_name': 'acme/app'}),
      );

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('pr_number'));
    });
  });

  group('messaging.createSpace — stopping', () {
    test('a stop during creation cancels the checkout it started', () async {
      // `createSpace` starts provisioning in the background, so a stop landing
      // in that window has to reach it — otherwise the clone runs to completion
      // for a run that was already cancelled.
      late final _Harness h;
      h = _harness(
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          repoIds: ['repo-1'],
          extras: {
            'agentIds': ['librarian'],
          },
        ),
        onCreateSpace: () => h.stepProcess.kill('steprun-1'),
      );

      final result = await h.body(_ctx());

      expect(result.isFailed, isTrue);
      expect(h.messaging.cancelledProvisioning, ['space-1']);
    });

    test('dry run opens nothing', () async {
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          extras: {
            'agentIds': ['librarian'],
          },
        ),
      );

      final result = await h.body(_ctx(dryRun: true));

      expect(result.isFailed, isFalse);
      expect(h.messaging.created, isEmpty);
    });
  });

  group('messaging.createSpace — the conversation it does (not) open', () {
    test('opens NO conversation by default', () async {
      // A room and a stream are different things. The agent steps downstream
      // each open their own named conversation, so a second one opened here
      // would be the empty "Untitled conversation" beside the real one.
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          extras: {
            'agentIds': ['librarian'],
          },
        ),
      );

      final result = await h.body(_ctx());

      expect(h.messaging.conversations, isEmpty);
      expect(
        result.mutatedState,
        isNot(contains(kPipelineConversationStateKey)),
      );
    });

    test('opens the named one when asked, and publishes its id', () async {
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          outputKey: kPipelineSpaceStateKey,
          extras: {
            'agentIds': ['librarian'],
            'createConversation': true,
            'conversationTitle': 'Architecture analysis',
          },
        ),
      );

      final result = await h.body(_ctx());

      expect(h.messaging.conversations, hasLength(1));
      expect(h.messaging.conversations.single.spaceId, 'space-1');
      expect(h.messaging.conversations.single.title, 'Architecture analysis');
      // A one-agent room hands the stream to that agent, so a human replying
      // in it wakes THAT agent rather than the roster's first entry.
      expect(h.messaging.conversations.single.principalId, 'librarian');
      // The agent step downstream opens the SAME title: whichever runs second
      // must find this row rather than open a second one beside it.
      expect(h.messaging.conversations.single.reuse, isTrue);
      expect(result.mutatedState?[kPipelineSpaceStateKey], 'space-1');
      expect(result.mutatedState?[kPipelineConversationStateKey], 'conv-1');
    });

    test('renders the title against run state, like the room name', () async {
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          extras: {
            'agentIds': ['librarian'],
            'createConversation': true,
            'conversationTitle': 'Analysis · {{repo_name}}',
          },
        ),
      );

      await h.body(_ctx(state: {'repo_name': 'control-center'}));

      expect(
        h.messaging.conversations.single.title,
        'Analysis · control-center',
      );
    });

    test('falls back to the room name when no title is given', () async {
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          extras: {
            'agentIds': ['librarian'],
            'createConversation': true,
          },
        ),
      );

      await h.body(_ctx());

      expect(h.messaging.conversations.single.title, 'Code analysis');
    });

    test('leaves the key absent when no conversation store answers', () async {
      // A bare host (no conversation repository wired) returns null. The step
      // still succeeds: a downstream `{{...}}` reference simply does not
      // resolve and the dispatch falls back to the standing stream.
      final h = _harness(
        config: const PipelineNodeConfig(
          label: 'Code analysis',
          extras: {
            'agentIds': ['librarian'],
            'createConversation': true,
          },
        ),
      );
      h.messaging.conversationId = null;

      final result = await h.body(_ctx());

      expect(result.isFailed, isFalse);
      expect(
        result.mutatedState,
        isNot(contains(kPipelineConversationStateKey)),
      );
    });
  });
}
