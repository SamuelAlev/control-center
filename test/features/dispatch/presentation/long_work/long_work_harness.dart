import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_inbox_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_view.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/features/messaging/providers/goal_card_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/test_wrap.dart';
import '../../../messaging/presentation/widgets/work/work_test_harness.dart';

export '../../../../helpers/active_workspace.dart' show kTestWorkspaceId;
export '../../../messaging/presentation/widgets/work/work_test_harness.dart'
    show FakeGoalRepository, refusal;

/// A fixed creation instant.
final DateTime t0 = DateTime.utc(2026, 11, 19, 9);

/// Far enough ahead that nothing in a fixture is due.
final DateTime later = DateTime.now().toUtc().add(const Duration(days: 3));

/// A goal for the fakes.
AgentGoalRun goalFixture({
  String id = 'goal-1',
  AgentGoalStatus status = AgentGoalStatus.active,
  GoalHold? hold,
  GoalContract? contract,
  GoalVerification? verification,
  int noProgressStreak = 0,
  String? checkerAgentId,
  String userText = 'Keep the changelog current',
}) => AgentGoalRun(
  id: id,
  workspaceId: kTestWorkspaceId,
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  userText: userText,
  status: status,
  hold: hold,
  contract: contract,
  verification: verification,
  noProgressStreak: noProgressStreak,
  checkerAgentId: checkerAgentId,
  deadlineAt: later,
  costCapMicros: 5000000,
  costMicros: 1250000,
  maxRuns: 10,
  runCount: 3,
  createdAt: t0,
  updatedAt: t0,
);

/// A schedule for the fakes.
WakeRuleView ruleFixture({
  String id = 'rule-1',
  String trigger = 'every:2h',
  String triggerKind = 'every',
  WakeRuleStatus status = WakeRuleStatus.active,
  bool canChange = true,
  String? timeZone,
  String? rootRuleId,
  int? lineageRunsLeft,
  DateTime? lineageEndsAt,
  String? goalId,
  WakeRuleOrigin noteAuthor = WakeRuleOrigin.person,
  List<DateTime> nextFires = const [],
}) => WakeRuleView(
  id: id,
  workspaceId: kTestWorkspaceId,
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  agentId: 'agent-2',
  ownerUserId: 'user-1',
  origin: noteAuthor,
  trigger: trigger,
  triggerKind: triggerKind,
  timeZone: timeZone,
  note: 'Check the release notes',
  deliver: WakeDeliver.run,
  whenBusy: WakeWhenBusy.queue,
  runCount: 4,
  maxRuns: 20,
  skipCount: 1,
  costMicros: 750000,
  costCapMicros: 10000000,
  status: status,
  nextFireAt: later,
  expiresAt: later.add(const Duration(days: 20)),
  createdAt: t0,
  canChange: canChange,
  noteAuthor: noteAuthor,
  rootRuleId: rootRuleId,
  lineageRunsLeft: lineageRunsLeft,
  lineageEndsAt: lineageEndsAt,
  goalId: goalId,
  nextFires: nextFires,
);

/// A proposal for the fakes.
ImprovementProposal proposalFixture({
  String id = 'prop-1',
  ImprovementKind kind = ImprovementKind.memoryFact,
  ImprovementOperation operation = ImprovementOperation.replace,
  ImprovementStatus status = ImprovementStatus.proposed,
  ImprovementCampaignState campaignState = ImprovementCampaignState.none,
  String? candidateRevisionId,
  String? beforeText = 'Release on Fridays',
  String? afterText = 'Release on Thursdays',
  String change = 'Move the release day to Thursday',
}) => ImprovementProposal(
  id: id,
  workspaceId: kTestWorkspaceId,
  agentId: 'agent-2',
  spaceId: 'sp-1',
  kind: kind,
  scope: ImprovementScope.agent,
  operation: operation,
  targetRef: 'fact-9',
  change: change,
  evidence: ImprovementEvidence(runIds: ['run-7'], messageIds: ['msg-3']),
  expected: 'Fewer weekend incidents',
  status: status,
  beforeText: beforeText,
  afterText: afterText,
  candidateRevisionId: candidateRevisionId,
  campaignState: campaignState,
  createdAt: t0,
  expiresAt: later,
);

/// Records every schedule call; [rules] feeds the watch.
class FakeWakeRuleRepository implements WakeRuleScheduleRepository {
  /// Calls, as `op:args`.
  final calls = <String>[];

  /// What the watch emits (null leaves it loading).
  List<WakeRuleView>? rules = const [];

  /// Thrown by the watch (refused state) when set.
  Object? watchError;

  /// Thrown by the next mutation when set.
  Object? error;

  /// The saved limits.
  WakeRuleLimits saved = WakeRuleLimits();

  /// The last draft sent to `create`.
  WakeRuleDraft? draft;

  T _record<T>(String call, T value) {
    calls.add(call);
    if (error case final e?) {
      throw e;
    }
    return value;
  }

  @override
  Stream<List<WakeRuleView>> watchForConversation(String w, String c) =>
      const Stream.empty();

  @override
  Stream<List<WakeRuleView>> watchForWorkspace(String workspaceId) {
    if (watchError case final e?) {
      return Stream.error(e);
    }
    final r = rules;
    return r == null ? const Stream.empty() : Stream.value(r);
  }

  @override
  Future<WakeRuleView> get(String workspaceId, String ruleId) async =>
      _record('get:$ruleId', ruleFixture(id: ruleId));

  /// What `previewCron` answers, the zones it calls unknown, and the drafts
  /// it was asked about.
  List<DateTime> preview = const [];
  Set<String> unknownZones = {};
  final previews = <String>[];

  @override
  Future<CronPreview> previewCron(
    String workspaceId, {
    required String expression,
    required String timeZone,
  }) async {
    previews.add('$expression@$timeZone');
    return (
      nextFires: preview,
      zoneKnown: !unknownZones.contains(timeZone),
    );
  }

  /// What `listRuns` answers, by cursor (null: the first page).
  Map<String?, WakeRuleRunPage> runPages = {};

  /// The `listRuns` reads, as `ruleId:cursor` (kept apart from [calls]).
  final runCalls = <String>[];

  /// When set, `listRuns` fails with it.
  Object? runsError;

  @override
  Future<WakeRuleRunPage> listRuns(
    String workspaceId,
    String ruleId, {
    String? cursor,
  }) async {
    runCalls.add('$ruleId:${cursor ?? ''}');
    if (runsError case final e?) {
      throw e;
    }
    return runPages[cursor] ??
        (wakes: const <WakeRuleRunView>[], nextCursor: null);
  }

  @override
  Future<WakeRuleView> create(String workspaceId, WakeRuleDraft draft) async {
    this.draft = draft;
    return _record('create:$workspaceId', ruleFixture(id: 'rule-new'));
  }

  @override
  Future<WakeRuleView> update(
    String workspaceId,
    String ruleId, {
    String? note,
    WakeWhenBusy? whenBusy,
    int? maxRuns,
    bool clearMaxRuns = false,
    int? costCapMicros,
    DateTime? expiresAt,
  }) async => _record(
    'update:$ruleId:max=$maxRuns:cap=$costCapMicros:'
    'expires=${expiresAt != null}',
    ruleFixture(id: ruleId),
  );

  @override
  Future<bool> pause(String workspaceId, String ruleId) async =>
      _record('pause:$workspaceId:$ruleId', true);

  @override
  Future<bool> resume(String workspaceId, String ruleId) async =>
      _record('resume:$workspaceId:$ruleId', true);

  @override
  Future<bool> delete(String workspaceId, String ruleId) async =>
      _record('delete:$workspaceId:$ruleId', true);

  /// When set, `getLimits` fails with it; [limitsGate] holds it pending.
  Object? limitsError;
  Completer<void>? limitsGate;

  @override
  Future<WakeRuleLimits> limits(String workspaceId) async {
    await limitsGate?.future;
    if (limitsError case final e?) {
      throw e;
    }
    return saved;
  }

  @override
  Future<WakeRuleLimits> setLimits(
    String workspaceId,
    WakeRuleLimits limits,
  ) async {
    saved = _record('setLimits:${limits.perConversation}', limits);
    return limits;
  }
}

/// Records every inbox call; [views] feeds the watch.
class FakeInboxRepository implements ImprovementInboxRepository {
  /// Calls, as `op:args`.
  final calls = <String>[];

  /// What the watch emits (null leaves it loading).
  List<ImprovementProposalView>? views = const [];

  /// Thrown by the watch when set.
  Object? watchError;

  /// When set, the watch is this controller's stream (frames a test pushes),
  /// in place of [views]. The test that sets it closes it.
  // ignore: close_sinks
  StreamController<List<ImprovementProposalView>>? live;

  /// Thrown by the next mutation when set.
  Object? error;

  Future<ImprovementProposalView> _record(String call, String id) async {
    calls.add(call);
    if (error case final e?) {
      throw e;
    }
    return ImprovementProposalView(
      proposal: proposalFixture(id: id),
      needsAdmin: false,
      evaluation: null,
    );
  }

  @override
  Stream<List<ImprovementProposalView>> watchForWorkspace(
    String workspaceId, {
    ImprovementStatus? status,
  }) {
    if (watchError case final e?) {
      return Stream.error(e);
    }
    if (live case final c?) {
      return c.stream;
    }
    final v = views;
    return v == null ? const Stream.empty() : Stream.value(v);
  }

  @override
  Future<ImprovementProposalView> get(String w, String id) =>
      _record('get:$id', id);

  @override
  Future<ImprovementProposalView> accept(String w, String id) =>
      _record('accept:$w:$id', id);

  @override
  Future<ImprovementProposalView> reject(String w, String id) =>
      _record('reject:$w:$id', id);

  @override
  Future<ImprovementProposalView> rollback(String w, String id) =>
      _record('rollback:$w:$id', id);

  @override
  Future<ImprovementProposalView> startCampaign(
    String w,
    String id, {
    required String corpusId,
    required String providerId,
    required String modelId,
    required int repetitions,
    required int budgetMicros,
  }) => _record(
    'startCampaign:$id:$corpusId:$providerId:$modelId:$repetitions:'
    '$budgetMicros',
    id,
  );
}

/// Goal controls plus the contract and checker writes.
class FakeGoalWrites extends FakeGoalRepository {
  /// The last contract written.
  GoalContract? contract;

  @override
  Future<GoalRunView> setContract(
    String workspaceId,
    String goalId,
    GoalContract? contract,
  ) async {
    calls.add('setContract:$goalId:${contract?.criteria.length}');
    if (error case final e?) {
      throw e;
    }
    this.contract = contract;
    return GoalRunView(goal: goalFixture(id: goalId), canResume: true, canApprove: true);
  }

  @override
  Future<GoalRunView> setChecker(
    String workspaceId,
    String goalId,
    String? checkerAgentId,
  ) async {
    calls.add('setChecker:$goalId:$checkerAgentId');
    if (error case final e?) {
      throw e;
    }
    return GoalRunView(goal: goalFixture(id: goalId), canResume: true, canApprove: true);
  }
}

/// Two agents: `agent-1` (the goal's, on anthropic) and `agent-2` Ada (on
/// openai).
final List<Agent> testAgents = [
  Agent(
    id: 'agent-1',
    name: 'Rex',
    title: 'Worker',
    agentMdPath: 'agents/rex.md',
    workspaceId: kTestWorkspaceId,
    skills: AgentSkills(const []),
    modelId: 'anthropic/claude-x',
    createdAt: t0,
  ),
  Agent(
    id: 'agent-2',
    name: 'Ada',
    title: 'Reviewer',
    agentMdPath: 'agents/ada.md',
    workspaceId: kTestWorkspaceId,
    skills: AgentSkills(const []),
    modelId: 'openai/gpt-x',
    createdAt: t0,
  ),
];

/// The overrides every long-work test shares.
List<Override> longWorkOverrides({
  FakeWakeRuleRepository? rules,
  FakeInboxRepository? inbox,
  FakeGoalRepository? goals,
  List<GoalRunView>? goalViews = const [],
  Object? goalsError,
  List<WakeView> wakes = const [],
  WorkspaceRole role = WorkspaceRole.admin,
}) => [
  activeWorkspaceIdOverride(),
  wakeRuleScheduleRepositoryProvider.overrideWithValue(
    rules ?? FakeWakeRuleRepository(),
  ),
  improvementInboxRepositoryProvider.overrideWithValue(
    inbox ?? FakeInboxRepository(),
  ),
  agentGoalRunRepositoryProvider.overrideWithValue(goals ?? FakeGoalWrites()),
  workspaceGoalRunsProvider.overrideWith(
    (ref, ws) => goalsError != null
        ? Stream.error(goalsError)
        : goalViews == null
        ? const Stream.empty()
        : Stream.value(goalViews),
  ),
  conversationWakesProvider.overrideWith((ref, key) => Stream.value(wakes)),
  workspaceAgentsProvider.overrideWith((ref, ws) => Stream.value(testAgents)),
  agentRunLogsProvider.overrideWith((ref, key) => Stream.value(const [])),
  workAgentNameProvider.overrideWith(
    (ref, key) => const {'agent-1': 'Rex', 'agent-2': 'Ada'}[key.agentId],
  ),
  workMemberNameProvider.overrideWith(
    (ref, key) => const {'user-1': 'Sam'}[key.userId],
  ),
  workConversationLabelProvider.overrideWith((ref, key) => 'Ops · Releases'),
  myWorkspaceRoleProvider.overrideWith((ref, ws) => role),
  codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
];

/// Pumps [child] in a fresh scope with [overrides].
Future<void> pumpLongWork(
  WidgetTester tester,
  Widget child, {
  required List<Override> overrides,
  TextDirection? textDirection,
  bool settle = true,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.physicalSize = const Size(1400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: testWrap(child, textDirection: textDirection),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
