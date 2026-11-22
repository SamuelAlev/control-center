import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_authority.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_checker_choice.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_command.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_server_core/src/catalog/agent_goal_run_ops.dart'
    show agentGoalRunToWireFor;

/// The refusal kind of a contract or checker change to a goal that is not
/// paused: a person edits what done means only while no segment runs.
const String goalNotPausedKind = 'goal_not_paused';

/// The refusal kind of a contract that is not one (wrong shape, past its
/// limits).
const String goalContractInvalidKind = 'goal_contract_invalid';

/// What done means for a durable goal, as data (plan section 8): reading a
/// goal, changing its contract and its checker while it is paused, and the
/// guided `/goal` interview, which takes explicit checks and a checker.
///
/// Authorization: the goal is looked up in the connection's workspace (a
/// foreign goal id is not found) and every op needs the space gate of the
/// goal's space ([requireSpace]), like `agentGoalRuns.pause` / `resume`.
/// `setContract` and `setChecker` decide what runs over the space's
/// repositories, so they also need the write grant on every repository the
/// space exposes ([reposExposedBy]), as the other mutating code ops do. And
/// they change what done means for work that runs with the requester's
/// sign-in and budget, so only the person the goal acts for may make them
/// (for a goal nobody requested, a workspace admin; [mayResumeGoal]),
/// refused with `goal_not_yours` otherwise.
///
/// Wire shapes:
/// - `agentGoalRuns.get {goal_id}` → `{goal}` (`agentGoalRunToWireFor`).
/// - `agentGoalRuns.setContract {goal_id, contract}`: `contract` is the
///   contract's JSON (`criteria`, a list of strings; `checks`, a list of
///   `{run, in, timeoutSeconds}` with `in` one of `worktree` and
///   `environment`; `boundaries`; `stopWhen`), or null to clear it.
///   → `{goal}`. Refused unless the goal is paused (`goal_not_paused`) and
///   the contract is valid (`goal_contract_invalid`).
/// - `agentGoalRuns.setChecker {goal_id, checker_agent_id}`: an agent id of
///   the workspace other than the goal's own, or null to clear (the goal's
///   own agent reviews then). → `{goal}`. Refused unless the goal is paused,
///   with `goal_checker_unknown` or `goal_checker_is_goal_agent`.
/// - `dispatch.guidedGoalStep {rough, transcript?, checks?,
///   checker_agent_id?, agent_id?}`: `checks` as in the contract,
///   `agent_id` the agent that will pursue the goal (refused as its own
///   checker). → `{question?, objective?, missing, weaknesses, unavailable,
///   contract?, checker_agent_id?}`. When ready, `objective` is the text the
///   client sends as `/goal <objective>`: the interview's sections, a
///   `## Checks` section for the checks and a `--checker <id>` flag, which
///   `/goal` turns into the contract; `contract` is that contract's JSON.
List<RepoOp> buildAgentGoalContractOps({
  required AgentGoalRunRepository goals,
  required AgentRepository agents,
  required Future<void> Function(
    String workspaceId,
    String userId,
    String spaceId,
  )
  requireSpace,
  required Future<List<String>> Function(String workspaceId, String spaceId)
  reposExposedBy,
  required MessagingPort? guidedGoals,
}) {
  Future<AgentGoalRun> goalOf(RepoOpContext ctx) async {
    final id = ctx.args['goal_id'];
    if (id is! String || id.isEmpty) {
      throw const ValidationException('goal_id must be a goal id');
    }
    final goal = await goals.getById(ctx.workspaceId!, id);
    if (goal == null) {
      throw NotFoundException('No goal $id in this workspace.');
    }
    await requireSpace(ctx.workspaceId!, ctx.userId, goal.spaceId);
    return goal;
  }

  // The write grant on every repository the goal's space exposes.
  Future<List<String>> goalRepos(RepoOpContext ctx) async =>
      reposExposedBy(ctx.workspaceId!, (await goalOf(ctx)).spaceId);

  Future<AgentGoalRun> pausedGoalOf(RepoOpContext ctx) async {
    final goal = await goalOf(ctx);
    if (!mayResumeGoal(goal, userId: ctx.userId, role: ctx.role)) {
      throw const AuthException(
        'Only the person this goal works for can change what done means for '
        'it (for a goal nobody asked for, a workspace admin).',
        code: goalNotYoursKind,
      );
    }
    if (goal.status != AgentGoalStatus.paused) {
      throw ValidationException(
        'Pause the goal before changing what done means; it is '
        '${goal.status.wire}.',
        code: goalNotPausedKind,
      );
    }
    return goal;
  }

  /// Writes [changed] only while the stored goal is still exactly [goal].
  Future<Map<String, Object?>> save(
    RepoOpContext ctx,
    AgentGoalRun goal,
    AgentGoalRun changed,
  ) async {
    final wrote = await goals.replaceIf(changed, expected: goal);
    if (!wrote) {
      throw const ValidationException(
        'The goal changed while this was being saved. Reload it and try '
        'again.',
        code: goalNotPausedKind,
      );
    }
    return {'goal': agentGoalRunToWireFor(ctx, changed)};
  }

  Future<List<Agent>> agentsOf(String workspaceId) =>
      agents.watchByWorkspace(workspaceId).first;

  return [
    RepoOp(
      name: 'agentGoalRuns.get',
      kind: RepoOpKind.read,
      requiredArgs: const ['goal_id'],
      handler: (ctx) async {
        return {'goal': agentGoalRunToWireFor(ctx, await goalOf(ctx))};
      },
    ),
    RepoOp(
      name: 'agentGoalRuns.setContract',
      kind: RepoOpKind.mutate,
      requiredArgs: const ['goal_id'],
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: goalRepos,
      handler: (ctx) async {
        // Absent is not null: clearing what done means is said explicitly.
        if (!ctx.args.containsKey('contract')) {
          throw const ValidationException(
            'contract is required: the contract, or null to clear it.',
            code: goalContractInvalidKind,
          );
        }
        final goal = await pausedGoalOf(ctx);
        final raw = ctx.args['contract'];
        final GoalContract? contract;
        try {
          contract = raw == null ? null : GoalContract.fromJson(raw);
        } on FormatException catch (e) {
          throw ValidationException(
            'The contract is not valid: ${e.message}',
            code: goalContractInvalidKind,
          );
        } on ArgumentError catch (e) {
          throw ValidationException(
            'The contract is not valid: ${e.message}',
            code: goalContractInvalidKind,
          );
        }
        final now = DateTime.now().toUtc();
        return save(
          ctx,
          goal,
          contract == null
              ? goal.copyWith(removeContract: true, updatedAt: now)
              : goal.copyWith(contract: contract, updatedAt: now),
        );
      },
    ),
    RepoOp(
      name: 'agentGoalRuns.setChecker',
      kind: RepoOpKind.mutate,
      requiredArgs: const ['goal_id'],
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: goalRepos,
      handler: (ctx) async {
        if (!ctx.args.containsKey('checker_agent_id')) {
          throw const ValidationException(
            'checker_agent_id is required: an agent id, or null to clear it.',
            code: goalCheckerUnknownKind,
          );
        }
        final goal = await pausedGoalOf(ctx);
        final raw = ctx.args['checker_agent_id'];
        final now = DateTime.now().toUtc();
        if (raw == null) {
          return save(
            ctx,
            goal,
            goal.copyWith(removeCheckerAgentId: true, updatedAt: now),
          );
        }
        if (raw is! String || raw.trim().isEmpty) {
          throw const ValidationException(
            'checker_agent_id must be an agent id, or null to clear it.',
            code: goalCheckerUnknownKind,
          );
        }
        final checker = _checkerById(
          raw.trim(),
          agents: await agentsOf(ctx.workspaceId!),
          goalAgentId: goal.agentId,
        );
        return save(
          ctx,
          goal,
          goal.copyWith(checkerAgentId: checker.id, updatedAt: now),
        );
      },
    ),
    if (guidedGoals != null)
      // One step of the `/goal` objective interview. A read: it spends a
      // model call and persists nothing; the objective only becomes real
      // when the person sends it.
      RepoOp(
        name: 'dispatch.guidedGoalStep',
        kind: RepoOpKind.read,
        requiredArgs: const ['rough'],
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final checks = _checksArg(ctx.args['checks']);
          final checkerArg = ctx.args['checker_agent_id'];
          Agent? checker;
          if (checkerArg != null) {
            if (checkerArg is! String || checkerArg.trim().isEmpty) {
              throw const ValidationException(
                'checker_agent_id must be an agent id.',
                code: goalCheckerUnknownKind,
              );
            }
            final goalAgent = ctx.args['agent_id'];
            checker = _checkerById(
              checkerArg.trim(),
              agents: await agentsOf(workspaceId),
              goalAgentId: goalAgent is String ? goalAgent : '',
            );
          }
          final step = await guidedGoals.guidedGoalStep(
            workspaceId: workspaceId,
            requestedByUserId: ctx.userId,
            rough: ctx.args['rough'] as String,
            transcript: [
              for (final line in (ctx.args['transcript'] as List?) ?? const [])
                if (line is String) line,
            ],
          );
          final base = {
            'missing': step.missing,
            'weaknesses': step.weaknesses,
            'unavailable': step.unavailable,
          };
          final drafted = step.objective;
          if (drafted == null) {
            return {'question': ?step.question, ...base};
          }
          final objective = [
            drafted.trim(),
            if (checks.isNotEmpty) GoalCommand.checksSection(checks),
            if (checker != null) '--checker ${checker.id}',
          ].join('\n\n');
          final GoalCommand command;
          try {
            command = GoalCommand.parse(objective);
          } on ValidationException catch (e) {
            // The interview's sections and the checks together are past a
            // limit: ask for the fix, never cut.
            return {'question': e.message, ...base};
          }
          return {
            'objective': objective,
            ...base,
            'contract': ?command.contract?.toJson(),
            'checker_agent_id': ?checker?.id,
          };
        },
      ),
  ];
}

/// The agent whose id is [id] among [agents]. Refused like a `--checker`
/// that names no agent (listing the candidates) or the goal's own agent.
/// Only ids match here: a client picked the agent, and a name could pick a
/// different one after a rename.
Agent _checkerById(
  String id, {
  required List<Agent> agents,
  required String goalAgentId,
}) {
  final byId = [
    for (final agent in agents)
      if (agent.id == id) agent,
  ];
  // With no agent of that id, the agents left match neither the id nor (by
  // construction) the name, so this throws the unknown-checker refusal with
  // the candidates.
  return chooseGoalChecker(
    id,
    agents: byId.isNotEmpty
        ? byId
        : [
            for (final agent in agents)
              if (agent.name.trim().toLowerCase() != id.toLowerCase()) agent,
          ],
    goalAgentId: goalAgentId,
  );
}

/// The guided step's `checks` arg: a list of `{run, in, timeoutSeconds}`.
List<GoalCheck> _checksArg(Object? raw) {
  if (raw == null) {
    return const [];
  }
  if (raw is! List) {
    throw const ValidationException(
      'checks must be a list of {run, in, timeoutSeconds}.',
      code: goalContractInvalidKind,
    );
  }
  if (raw.length > GoalContract.maxChecks) {
    throw ValidationException(
      'A goal has at most ${GoalContract.maxChecks} checks; this has '
      '${raw.length}.',
      code: goalContractInvalidKind,
    );
  }
  try {
    return [for (final check in raw) GoalCheck.fromJson(check)];
  } on FormatException catch (e) {
    throw ValidationException(
      'A check is not valid: ${e.message}',
      code: goalContractInvalidKind,
    );
  } on ArgumentError catch (e) {
    throw ValidationException(
      'A check is not valid: ${e.message}',
      code: goalContractInvalidKind,
    );
  }
}
