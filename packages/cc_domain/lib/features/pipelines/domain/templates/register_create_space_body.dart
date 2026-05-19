import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_label.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pipelines/domain/templates/dispatch_conversation_step.dart'
    show priorStepRunSpaceId, resolveConfiguredSpaceId;
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';

/// Registers the generic `messaging.createSpace` body — the node every
/// agent-bearing pipeline opens with.
///
/// It resolves ONE conversation for the whole run, up front, and writes its id
/// to `config.outputKey` (default [kPipelineSpaceStateKey]) so each downstream
/// agent step names it as its room (`extras['spaceId']`) and opens its own
/// titled stream inside it. That is the shape the `pr_review` template already
/// had, generalized: without it every agent step minted its OWN hidden
/// conversation, which meant one checkout of the same repo per branch of a
/// fan-out and as many rooms nobody could see.
///
/// **The room's checkout replaces the clone.** A space's worktree is a
/// copy-on-write copy of the linked checkout (rift), scrubbed to a pristine
/// tree and — for a pull request — fetched and checked out at the PR head. That
/// is seconds and no network transfer, where a clone re-downloads the whole
/// repository per run. With `extras['awaitReady']` the node waits for that
/// checkout and publishes its path as `repoLocalPath`, so the scripts, routers
/// and prompts that already read that key keep working — pointed at the CoW
/// worktree instead of a fresh clone.
///
/// Three further properties are the point of the node:
///
/// * **The conversation is visible.** No `pipelineRunId` is stamped on a space
///   it creates, so it is a normal room in the sidebar rather than a
///   pipeline-managed one only the step-detail panel can reach.
/// * **The work starts early.** `createSpace` returns as soon as the row is
///   written and provisioning runs in the background, so a node that does not
///   need the path (`awaitReady` unset) lets the checkout happen while the
///   deterministic steps ahead of the agents are still running.
/// * **The scope is stated, never inferred.** `config.repoIds` is the exact set
///   of repos the room checks out and `extras['agentIds']` the exact roster it
///   opens with. An empty repo scope means NO repos, not every repo — the
///   opposite of `dispatchConversationStep`'s legacy fallback, because a node
///   that exists to declare a scope must not silently escalate to checking out
///   the whole workspace when a `{{placeholder}}` fails to resolve. Pass
///   `extras['allRepos'] == true` to ask for every workspace repo explicitly.
///
/// **A room is not a stream.** The node opens the SPACE — the checkout, the
/// roster, the provisioning — and by default opens no conversation inside it,
/// because the agent steps downstream each open their own named one and a
/// second, unwritten stream is exactly the "Untitled conversation" nobody
/// asked for. `extras['createConversation']` turns that into an explicit
/// choice: with it the node also opens ONE conversation, titled
/// `extras['conversationTitle']` (falling back to the room's own name), and
/// publishes its id as [kPipelineConversationStateKey] alongside the space id.
/// Turn it on for a template with a single agent step and give that step the
/// same title — the step's own `createConversation(reuseExisting: true)` then
/// resolves back to this one. Left off, the room stands empty until its first
/// agent step runs, and anything that READS the room in that window (the
/// sidebar, the step-detail panel) mints an untitled standing conversation
/// beside the named one the agent later opens.
///
/// Agents that only run on SOME paths (a router branch, a level-gated reviewer)
/// are deliberately left off the roster: `dispatchConversationStep` adds an
/// agent to the room when it actually dispatches it, so seeding them here would
/// only fill the participant list with agents that never spoke.
///
/// [ensureReviewSpace] backs `extras['pr']`: it resolves the pull request's ONE
/// backing space — the same room the PR page opens — through the same closure
/// `messaging.createSpace` uses, so a template that reviews a PR and a human
/// opening that PR can never end up looking at two different checkouts. Absent
/// on a host that wires no resolver, which fails the node rather than silently
/// falling back to a room checked out on the default branch.
void registerCreateSpaceBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required AgentRepository agentRepository,
  required MessagingPort messagingPort,
  required MessagingRepository messagingRepository,
  required IsolatedRepoRepository isolatedRepoRepository,
  required StepProcessRegistry stepProcessRegistry,
  required PipelineRunRepository runRepository,
  Future<String?> Function({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String title,
  })?
  ensureReviewSpace,
}) {
  registry.registerBody(BuiltInBodyKeys.createSpace, (ctx) async {
    final workspaceId = ctx.workspaceId;
    final def = await templateRepository.getById(workspaceId, ctx.templateId);
    final config = def?.step(ctx.stepId)?.config;
    if (config == null) {
      return StepResult.failed(
        'createSpace: step "${ctx.stepId}" missing config',
      );
    }
    final outputKey = _outputKeyOf(config);

    if (ctx.dryRun) {
      return StepResult.ok(
        mutatedState: {
          outputKey: '[dry-run] ${ctx.stepId}',
          if (config.createsConversation)
            kPipelineConversationStateKey:
                '[dry-run] ${ctx.stepId} conversation',
        },
      );
    }

    // Registered BEFORE any work: resolving the room starts its checkout, so a
    // stop landing in that window must still find something to cancel.
    var stopped = false;
    // The room this step OWNS — torn off its checkout when the run is stopped.
    // A PR's room and an operator's room outlive the run that borrowed them, so
    // they are never registered here. Distinct from [justCreated]: a room this
    // step opened on a PREVIOUS attempt is ours to stop but already has its
    // roster.
    String? createdSpaceId;
    var justCreated = false;
    stepProcessRegistry.register(ctx.stepRunId, () async {
      stopped = true;
      // Only a space this step CREATED is torn off its checkout. A PR's room
      // and an operator's room outlive the run that borrowed them.
      final spaceToStop = createdSpaceId;
      if (spaceToStop != null) {
        try {
          await messagingPort.cancelSpaceProvisioning(workspaceId, spaceToStop);
        } on Object catch (e, st) {
          CcDomainLog.error(
            'createSpace: cancelSpaceProvisioning failed',
            e,
            st,
          );
        }
      }
    });

    try {
      final extraState = <String, dynamic>{};
      // Resolved ONCE: every branch below needs it (the roster a new room opens
      // with, the idempotent join into a room this step did not create, and the
      // owner of the conversation it may open), and each resolution costs one
      // agent read per declared id.
      final agentIds = await _resolveAgentIds(
        config,
        ctx,
        agentRepository: agentRepository,
        definition: def,
      );
      final String spaceId;

      if (config.extras['pr'] == true) {
        final resolved = await _resolvePrSpace(
          ctx,
          ensureReviewSpace: ensureReviewSpace,
        );
        if (resolved.error != null) {
          return StepResult.failed(resolved.error!);
        }
        spaceId = resolved.spaceId!;
        extraState['pr_external_id'] = resolved.prExternalId;
        // Normalize the review level into run state here, at the one step every
        // review passes through. The reviewer gates and the finalizer both read
        // state, so a run that arrived without a level — one started before
        // levels existed, a manual run off the pipeline canvas, an
        // event-triggered run — resolves to the default here and behaves as a
        // balanced review. Publishing the reporting brief alongside it is what
        // keeps the `{{review_level_reporting_brief}}` placeholder in every
        // reviewer prompt resolvable; an unresolved placeholder fails its step.
        final level = _resolveReviewLevel(ctx);
        extraState[kReviewLevelStateKey] = level.wireName;
        extraState[kReviewLevelBriefStateKey] = level.profile.reportingBrief;
      } else {
        // Reuse before create, in the order that keeps a run addressing ONE
        // room: the space a previous attempt of this same step already opened
        // (a retry or a crash-resume re-fires the body on the row it owns),
        // then a room the node explicitly names — which is how a generated plan
        // pipeline keeps its work in the conversation the plan was authored in.
        final prior = await priorStepRunSpaceId(runRepository, ctx);
        final configured =
            prior ?? resolveConfiguredSpaceId(config.spaceId, ctx);
        if (configured.isNotEmpty &&
            await messagingPort.spaceExists(workspaceId, configured)) {
          spaceId = configured;
          if (prior != null) {
            // Our own room from a previous attempt — still ours to tear down.
            createdSpaceId = configured;
          }
        } else {
          final scope = _resolveRepoScope(config, ctx);
          final space = await messagingPort.createSpace(
            workspaceId,
            _resolveName(config, ctx),
            agentIds,
            mode: _resolveMode(config),
            repoIds: scope.ids,
            repoBranches: scope.branches,
          );
          spaceId = space.id;
          createdSpaceId = space.id;
          justCreated = true;
        }
      }

      if (stopped) {
        final spaceToStop = createdSpaceId;
        if (spaceToStop != null) {
          await messagingPort.cancelSpaceProvisioning(workspaceId, spaceToStop);
        }
        return StepResult.failed(
          'createSpace: the step was stopped while opening the conversation',
        );
      }

      // A room this step did not just create (a PR's, an operator's, its own
      // from a previous attempt) keeps its roster; add the agents the template
      // declared, idempotently, so the sidebar shows who is working here before
      // the first turn starts. A freshly created room already has them.
      if (!justCreated) {
        for (final agentId in agentIds) {
          try {
            await messagingPort.addAgentToSpace(
              workspaceId,
              spaceId,
              agentId,
              renameForGroup: false,
            );
          } on Object catch (e, st) {
            CcDomainLog.warning(
              'createSpace: could not add agent $agentId to space $spaceId: '
              '$e\n$st',
            );
          }
        }
      }

      // The room's ONE stream, when the node was asked for one. Opened here
      // rather than left to the first agent step so the room never stands
      // conversation-less: `ensureStandingConversation` mints an untitled row
      // for a room that has none, and every read path lands there — so a room
      // whose agent starts minutes later (an analysis behind an index) shows an
      // empty "Untitled conversation" next to the named one.
      //
      // `reuseExisting` because this body re-fires on retry and crash-resume,
      // and because the agent step downstream opens the SAME title: whichever
      // runs second must find this row, not open a second one beside it.
      if (config.createsConversation) {
        try {
          final conversationId = await messagingPort.createConversation(
            workspaceId: workspaceId,
            spaceId: spaceId,
            title: _resolveConversationTitle(config, ctx),
            // Whose stream it is. A single-agent room hands it to that agent,
            // so a human replying in it wakes THAT agent rather than whichever
            // one the space's roster lists first.
            createdByPrincipalId: agentIds.length == 1 ? agentIds.single : null,
            reuseExisting: true,
          );
          if (conversationId != null && conversationId.isNotEmpty) {
            extraState[kPipelineConversationStateKey] = conversationId;
          } else {
            // A host with no conversation store wired (a bare test host) — the
            // key stays absent, so a downstream `{{...}}` reference simply does
            // not resolve and the step falls back to the standing stream.
            CcDomainLog.warning(
              'createSpace: no conversation was opened in space $spaceId — '
              'downstream steps will use its standing stream',
            );
          }
        } on Object catch (e, st) {
          CcDomainLog.warning(
            'createSpace: could not open a conversation in space $spaceId: '
            '$e\n$st',
          );
        }
      }

      // Link the room onto the step run: it is what the step-detail panel opens,
      // and what `priorStepRunSpaceId` reads back so a retry reuses this space
      // instead of provisioning a second one.
      try {
        await runRepository.updateStepRun(
          workspaceId,
          ctx.stepRunId,
          spaceId: spaceId,
        );
      } on Object catch (e, st) {
        CcDomainLog.warning(
          'createSpace: failed to link space $spaceId to step run '
          '${ctx.stepRunId}: $e\n$st',
        );
      }

      // Steps that are NOT agent dispatches — a bash script, a `fileExists`
      // router — read the checkout by path, and only exist once provisioning
      // has finished. (An agent step needs no wait: dispatch already gates on
      // the space being ready.)
      if (config.extras['awaitReady'] == true) {
        // Handed back to the engine for the length of the poll: this node does
        // nothing but ask, every 400ms, whether someone else's checkout has
        // finished — for up to three minutes. Holding a step-concurrency permit
        // through that turns the engine's cap into a queue, and a handful of
        // repos provisioning at once stalls every other pipeline on the host
        // behind work that is not running.
        final failure = await ctx.whileWaiting(
          () => _awaitReady(
            workspaceId: workspaceId,
            spaceId: spaceId,
            messagingRepository: messagingRepository,
            timeout: _readyTimeout(config),
            isStopped: () => stopped,
          ),
        );
        if (failure != null) {
          return StepResult.failed(failure);
        }
        extraState.addAll(
          await _worktreePaths(
            workspaceId: workspaceId,
            spaceId: spaceId,
            config: config,
            isolatedRepoRepository: isolatedRepoRepository,
          ),
        );
      }

      return StepResult.ok(mutatedState: {outputKey: spaceId, ...extraState});
    } on Object catch (e, st) {
      CcDomainLog.error('createSpace: could not open the conversation', e, st);
      return StepResult.failed('createSpace: $e');
    } finally {
      stepProcessRegistry.unregister(ctx.stepRunId);
    }
  });
}

const TemplateRenderer _renderer = TemplateRenderer();

/// The review level a PR-lane run is executing at.
///
/// Reads state first, then the trigger payload, then falls back to the default.
/// An unrecognized value falls back too rather than failing the step: the level
/// changes how much of a review is reported, and refusing to review at all
/// because a stored string was misspelled is the worse failure.
ReviewLevel _resolveReviewLevel(PipelineContext ctx) {
  final raw =
      ctx.state[kReviewLevelStateKey] ??
      ctx.triggerPayload?[kReviewLevelStateKey];
  return ReviewLevel.fromWire(raw is String ? raw : null) ??
      ReviewLevel.defaultLevel;
}

String _outputKeyOf(PipelineNodeConfig config) {
  final declared = config.outputKey?.trim() ?? '';
  return declared.isEmpty ? kPipelineSpaceStateKey : declared;
}

/// The name of the conversation the node opens: `extras['conversationTitle']`
/// rendered against run state, falling back to the room's own name.
///
/// Rendered through [renderStepLabel] like the room's name is, so a title can
/// carry the same `{{repo_name}}` placeholders the label does.
String _resolveConversationTitle(
  PipelineNodeConfig config,
  PipelineContext ctx,
) {
  final declared = config.conversationTitle;
  if (declared == null) {
    return _resolveName(config, ctx);
  }
  return renderStepLabel(
    declared,
    state: ctx.renderState,
    trigger: ctx.triggerPayload,
    fallback: _resolveName(config, ctx),
  );
}

Duration _readyTimeout(PipelineNodeConfig config) {
  final raw = config.extras['readyTimeoutMs'];
  final ms = raw is num ? raw.toInt() : 0;
  return ms > 0 ? Duration(milliseconds: ms) : const Duration(seconds: 180);
}

typedef _PrSpace = ({String? spaceId, String prExternalId, String? error});

/// Resolves the pull request's ONE backing space through the shared resolver.
///
/// Reads `repo_full_name` + `pr_number` off the run,
/// including the canonical `owner/repo#number` fallback for the forge id, so a
/// manually-started run reuses the same room as a webhook-driven one.
Future<_PrSpace> _resolvePrSpace(
  PipelineContext ctx, {
  required Future<String?> Function({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String title,
  })?
  ensureReviewSpace,
}) async {
  final ensure = ensureReviewSpace;
  if (ensure == null) {
    return (
      spaceId: null,
      prExternalId: '',
      error:
          'createSpace: this node asks for the pull request\'s room but no '
          'PR-space resolver is wired on this host',
    );
  }
  final String repoFullName;
  try {
    repoFullName = ctx.requireString('repo_full_name');
  } on Object {
    return (
      spaceId: null,
      prExternalId: '',
      error: 'createSpace: repo_full_name missing',
    );
  }
  final rawPrNumber =
      ctx.state['pr_number'] ?? ctx.triggerPayload?['pr_number'];
  final prNumber = rawPrNumber is int
      ? rawPrNumber
      : int.tryParse('$rawPrNumber'.trim());
  if (prNumber == null) {
    return (
      spaceId: null,
      prExternalId: '',
      error: 'createSpace: pr_number missing or not numeric',
    );
  }
  final declaredExternalId =
      ctx.optional<String>('pr_external_id')?.trim() ?? '';
  final prExternalId = declaredExternalId.isNotEmpty
      ? declaredExternalId
      : '$repoFullName#$prNumber';

  final spaceId = await ensure(
    workspaceId: ctx.workspaceId,
    repoFullName: repoFullName,
    prNumber: prNumber,
    prExternalId: prExternalId,
    title: ctx.optional<String>('pr_title') ?? '',
  );
  if (spaceId == null || spaceId.isEmpty) {
    return (
      spaceId: null,
      prExternalId: prExternalId,
      error:
          'createSpace: could not resolve a room for $repoFullName#$prNumber',
    );
  }
  return (spaceId: spaceId, prExternalId: prExternalId, error: null);
}

/// Blocks until the space's checkout exists. Returns null on success, or the
/// step-failure message.
///
/// A failure and a timeout both fail the step rather than continuing: a caller
/// that went on would hand a script or a router an empty `repos/` and read the
/// resulting "no manifest here" as an answer about the repository.
Future<String?> _awaitReady({
  required String workspaceId,
  required String spaceId,
  required MessagingRepository messagingRepository,
  required Duration timeout,
  required bool Function() isStopped,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    if (isStopped()) {
      return 'createSpace: the step was stopped while the checkout was '
          'being prepared';
    }
    final space = await messagingRepository.getSpaceById(workspaceId, spaceId);
    final status = space?.provisioningStatus ?? SpaceProvisioningStatus.ready;
    if (status == SpaceProvisioningStatus.ready) {
      return null;
    }
    if (status == SpaceProvisioningStatus.failed) {
      return 'createSpace: the conversation\'s checkout failed to provision';
    }
    if (DateTime.now().isAfter(deadline)) {
      return 'createSpace: the conversation\'s checkout did not finish within '
          '${timeout.inSeconds}s';
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}

/// The state a downstream script / router needs to address the checkout:
/// `repoLocalPath` (overridable with `extras['pathOutputKey']`) when the room
/// holds exactly one repo, plus `spaceRepoPaths` keyed by repo id.
///
/// Nothing is published when the room holds no worktree — overwriting
/// `repoLocalPath` with an empty string would replace the value a manual run's
/// repo picker put there with one that resolves to nothing.
Future<Map<String, dynamic>> _worktreePaths({
  required String workspaceId,
  required String spaceId,
  required PipelineNodeConfig config,
  required IsolatedRepoRepository isolatedRepoRepository,
}) async {
  final List<IsolatedRepo> worktrees;
  try {
    worktrees = await isolatedRepoRepository.forSpace(workspaceId, spaceId);
  } on Object catch (e, st) {
    CcDomainLog.warning(
      'createSpace: could not read the worktrees of space $spaceId: $e\n$st',
    );
    return const {};
  }
  if (worktrees.isEmpty) {
    return const {};
  }
  final byRepo = <String, String>{for (final w in worktrees) w.repoId: w.path};
  final pathKey =
      (config.extras['pathOutputKey'] as String?)?.trim().isNotEmpty ?? false
      ? (config.extras['pathOutputKey'] as String).trim()
      : 'repo_local_path';
  return {
    'space_repo_paths': byRepo,
    if (byRepo.length == 1) pathKey: byRepo.values.single,
  };
}

/// The room's name: `extras['spaceName']` when the node overrides it, else the
/// node's own label, rendered against run state by [renderStepLabel] — the same
/// resolution the canvas and the run timeline show, so the room is called what
/// the step is called.
String _resolveName(PipelineNodeConfig config, PipelineContext ctx) {
  final override = config.extras['spaceName'];
  final raw = (override is String && override.trim().isNotEmpty)
      ? override.trim()
      : config.label;
  return renderStepLabel(
    raw,
    state: ctx.renderState,
    trigger: ctx.triggerPayload,
    fallback: ctx.stepId,
  );
}

/// The repos the room checks out and the branch each one is cut from.
///
/// `ids` is `null` for every workspace repo (opt-in via `extras['allRepos']`),
/// otherwise exactly the node's resolved `repoIds` — where an empty list means
/// the room checks out nothing. `branches` holds the entries that named one.
typedef _RepoScope = ({List<String>? ids, Map<String, String> branches});

_RepoScope _resolveRepoScope(PipelineNodeConfig config, PipelineContext ctx) {
  if (config.extras['allRepos'] == true) {
    return (ids: null, branches: const {});
  }
  return _resolveScopedRepoIds(config.repoIds, ctx);
}

/// Splits a resolved repo-scope entry into its repo id and the branch the
/// worktree is cut from: `<repoId>@<branch>`, or just `<repoId>`.
///
/// Split from the RIGHT so a branch containing `@` still parses, and only when
/// both halves are non-empty — a bare `@branch` or a trailing `@` is a typo,
/// and reading it as "no repo" or "no branch" hides it. The whole entry is
/// rendered before it gets here, so the branch can be a `{{placeholder}}` the
/// trigger fills in.
({String repoId, String? branch}) _splitRepoEntry(String entry) {
  final at = entry.lastIndexOf('@');
  if (at <= 0 || at == entry.length - 1) {
    return (repoId: entry, branch: null);
  }
  return (
    repoId: entry.substring(0, at),
    branch: entry.substring(at + 1),
  );
}

/// The roster the room opens with: `extras['agentIds']` (rendered, so a node can
/// name an agent chosen upstream), falling back to the node's own `agentId`.
///
/// An id that no longer resolves to an agent is dropped rather than thrown:
/// deleting one specialist must not make every run of the template fail at its
/// first step, and the agents that DO run add themselves on dispatch anyway.
Future<List<String>> _resolveAgentIds(
  PipelineNodeConfig config,
  PipelineContext ctx, {
  required AgentRepository agentRepository,
  PipelineDefinition? definition,
}) async {
  final declared = <String>[];
  void declare(String? value) {
    final id = value?.trim() ?? '';
    if (id.isNotEmpty && !declared.contains(id)) {
      declared.add(id);
    }
  }

  final raw = config.extras['agentIds'];
  if (raw is List) {
    for (final entry in raw) {
      if (entry is! String) {
        continue;
      }
      final result = _renderer.render(
        entry,
        state: ctx.renderState,
        trigger: ctx.triggerPayload,
      );
      if (result.isComplete) {
        declare(result.text);
      }
    }
  }
  if (declared.isEmpty) {
    declare(config.agentId);
  }
  // Whoever is going to work in this room, read off the template itself. The
  // node no longer has to repeat a roster that its own agent steps already
  // state, and the two cannot drift: adding a reviewer wires it into the
  // sidebar by adding the step, not by remembering a second list.
  for (final id in _agentsDispatchedInto(
    definition,
    roomKey: _outputKeyOf(config),
    ctx: ctx,
  )) {
    declare(id);
  }

  final resolved = <String>[];
  for (final agentId in declared) {
    try {
      if (await agentRepository.getById(ctx.workspaceId, agentId) != null) {
        resolved.add(agentId);
        continue;
      }
    } on Object catch (e, st) {
      CcDomainLog.warning(
        'createSpace: could not read agent $agentId: $e\n$st',
      );
      continue;
    }
    CcDomainLog.warning(
      'createSpace: agent $agentId is not in workspace ${ctx.workspaceId} — '
      'leaving it off the roster of "${ctx.stepId}"',
    );
  }
  return resolved;
}

/// The mode the room is created under. Mirrors `conversation.promptAgent`'s
/// resolution (`extras['mode']`, defaulting to `review`) so moving a step into
/// a pre-created room does not silently change the permissions its agent runs
/// with.
Mode _resolveMode(PipelineNodeConfig config) {
  return switch (config.modeName) {
    'chat' => Mode.chat,
    'review' => Mode.review,
    'plan' => Mode.plan,
    _ => Mode.review,
  };
}

/// Resolves a node's configured repo selection (the node config's `repoIds`)
/// against the pipeline state and trigger payload.
///
/// Entries support `{{key}}` placeholders; an entry that does not resolve
/// completely is dropped, because a seeded template's `['{{repo_id}}']` has to
/// survive trigger paths whose payload carries no repo (a scheduled sweep).
/// What survives is the scope; see [_resolveRepoScope] for what an empty
/// result means — NO repos, unless the node opted into `allRepos`.
///
/// An entry may name the branch its worktree is cut from as
/// `<repoId>@<branch>` — the placeholder pass runs over the WHOLE entry, so
/// either half can come from the trigger (`{{repo_id}}@{{head_ref}}`). The
/// branch is the BASE, not the working branch: the worktree still gets its own
/// `conv/<space>` branch cut from it, so nothing an agent commits lands there.
///
/// Private to this file: a conversation IS the checkout, so the node that
/// opens one is the only node that reads this.
_RepoScope _resolveScopedRepoIds(
  List<String> configured,
  PipelineContext ctx,
) {
  if (configured.isEmpty) {
    return (ids: const <String>[], branches: const {});
  }
  const renderer = TemplateRenderer();
  final resolved = <String>[];
  final branches = <String, String>{};
  final dropped = <String>[];
  for (final entry in configured) {
    final result = renderer.render(
      entry,
      state: ctx.renderState,
      trigger: ctx.triggerPayload,
    );
    final value = result.text.trim();
    if (!result.isComplete || value.isEmpty) {
      dropped.add(entry);
      continue;
    }
    final split = _splitRepoEntry(value);
    if (!resolved.contains(split.repoId)) {
      resolved.add(split.repoId);
    }
    if (split.branch != null) {
      branches[split.repoId] = split.branch!;
    }
  }
  if (dropped.isNotEmpty) {
    CcDomainLog.warning(
      'createSpace: repo scope entries did not resolve and were '
      'ignored: ${dropped.join(', ')}',
    );
    if (resolved.isEmpty) {
      CcDomainLog.warning(
        'createSpace: repo scope is empty after resolution — the room will '
        'check out nothing',
      );
    }
  }
  return (ids: resolved, branches: branches);
}

/// The agents that steps of [definition] dispatch INTO the room this node
/// opens — the ones whose `extras['spaceId']` is `{{roomKey}}`.
///
/// Gated steps are deliberately excluded. A `runWhen` branch or a level-gated
/// reviewer may never dispatch on this run, and seeding it would fill the
/// sidebar with agents that never speak. Those join when they are actually
/// dispatched, which is the moment they become real participants.
///
/// A placeholder `agentId` (`{{someKey}}`) that does not resolve yet is skipped
/// rather than guessed: it names an agent chosen further upstream, and that
/// step adds it on dispatch.
List<String> _agentsDispatchedInto(
  PipelineDefinition? definition, {
  required String roomKey,
  required PipelineContext ctx,
}) {
  if (definition == null) {
    return const [];
  }
  final ids = <String>[];
  for (final step in definition.steps) {
    if (!_dispatchesAgents(step.bodyKey) || step.config.runWhen != null) {
      continue;
    }
    final room = step.config.spaceId?.trim() ?? '';
    if (room.isEmpty || !_renderer.placeholders(room).contains(roomKey)) {
      continue;
    }
    final agent = step.config.agentId?.trim() ?? '';
    if (agent.isEmpty) {
      continue;
    }
    final rendered = _renderer.render(
      agent,
      state: ctx.renderState,
      trigger: ctx.triggerPayload,
    );
    final value = rendered.text.trim();
    if (rendered.isComplete && value.isNotEmpty && !ids.contains(value)) {
      ids.add(value);
    }
  }
  return ids;
}

/// Whether [bodyKey] dispatches agents into a conversation.
bool _dispatchesAgents(String bodyKey) => const {
  BuiltInBodyKeys.promptAgent,
  BuiltInBodyKeys.teamDispatch,
  BuiltInBodyKeys.forEach,
  BuiltInBodyKeys.humanGate,
}.contains(bodyKey);
