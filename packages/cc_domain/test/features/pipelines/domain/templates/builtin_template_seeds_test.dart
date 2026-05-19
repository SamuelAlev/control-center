import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_validator.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:test/test.dart';

/// Calls each built-in template seed and asserts the returned
/// [PipelineDefinition] has the expected structural invariants: a leading
/// `trigger` entry node, a trailing `terminal` node and the right step
/// count + trigger wiring for each template. These seeds ship the default
/// pipelines on every workspace, so a structural drift here silently changes
/// what new workspaces get.
void main() {
  const workspaceId = 'ws-1';
  const agentIds = BuiltInAgentIds(
    qa: 'qa-id',
    architect: 'arch-id',
    engineer: 'eng-id',
    librarian: 'lib-id',
    ceo: 'ceo-id',
  );

  group('BuiltInAgentIds', () {
    test('defaults coder to engineer when not separately seeded', () {
      const ids = BuiltInAgentIds(
        qa: 'qa',
        architect: 'arch',
        engineer: 'eng',
        librarian: 'lib',
        ceo: 'ceo',
      );
      expect(ids.coder, 'eng');
    });

    test('honors an explicit coder override', () {
      const ids = BuiltInAgentIds(
        qa: 'qa',
        architect: 'arch',
        engineer: 'eng',
        librarian: 'lib',
        ceo: 'ceo',
        coder: 'dedicated-coder',
      );
      expect(ids.coder, 'dedicated-coder');
    });
  });

  group('builtInTemplateSeeds', () {
    final seeds = builtInTemplateSeeds(
      workspaceId: workspaceId,
      agentIds: agentIds,
    );

    // The structural invariants below must cover EVERY template a workspace
    // gets, not just the ones in `builtInTemplateSeeds`. The two agentless
    // templates are seeded through their own entry points
    // (`WorkspaceSeeder.ensureSkillAnalysisTemplate` /
    // `_ensureIndexCodeTemplate`) and so sat outside this loop — which is how
    // `skill_analysis` shipped with no terminal node, leaving every run of it
    // stuck at "Running" forever and its dedup key blocking the next one.
    final allSeeds = <PipelineDefinition>[
      ...seeds,
      skillAnalysisTemplate(workspaceId),
      indexCodeTemplate(workspaceId),
    ];

    test('returns one seed per known template', () {
      expect(seeds.map((d) => d.templateId).toSet(), {
        'pr_review',
        'external_pr_welcome',
        'pr_merged_cleanup',
        'cross_review',
        'ticket_to_pr',
        'pr_triage',
        'pre_merge_gate',
        'release_notes',
        'dep_audit',
        'pr_digest',
        'index_code',
        'meeting_summary',
      });
    });

    test('index_code is the only capped built-in, and it is capped at 1', () {
      // Indexing is the one built-in that is CPU-bound end to end, so N repos
      // must go through it back to back rather than fight over the cores and
      // the workspace's single DB writer. Every other built-in is unlimited on
      // purpose: a cap silently queues work, which is the wrong default for a
      // review or a digest.
      final capped = {
        for (final def in allSeeds)
          if (def.maxParallelRuns != null) def.templateId: def.maxParallelRuns,
      };
      expect(capped, {'index_code': 1});
    });

    test('every seed is built-in, belongs to the workspace and has a name', () {
      for (final def in seeds) {
        expect(def.workspaceId, workspaceId);
        expect(def.isBuiltIn, isTrue);
        expect(def.name, isNotEmpty);
        expect(def.description, isNotEmpty);
      }
    });

    test('every seed begins with a trigger node', () {
      for (final def in allSeeds) {
        expect(
          def.steps.first.kind,
          StepKind.trigger,
          reason: '${def.templateId} must begin with a trigger step',
        );
        expect(def.steps.first.bodyKey, BuiltInBodyKeys.trigger);
        expect(def.steps.first.id, 'trigger');
      }
    });

    test('every seed has exactly one trigger and at least one terminal', () {
      for (final def in allSeeds) {
        final triggers = def.steps
            .where((s) => s.kind == StepKind.trigger)
            .toList();
        expect(triggers, hasLength(1), reason: def.templateId);

        // The terminal node is the join sink of the DAG. Without one,
        // `planDownstream` can never report `terminalReached`, so the run
        // never leaves `running` — see `skill_analysis` below.
        final terminals = def.steps
            .where((s) => s.kind == StepKind.terminal)
            .toList();
        expect(terminals, isNotEmpty, reason: def.templateId);
      }
    });

    test('every seed passes the author-time validator with no errors', () {
      // The validator already knows "Pipeline has no terminal step, so it can
      // never complete" — but built-in seeds bypass it (the repository only
      // validates user-owned templates), so nothing ever asked it about them.
      const validator = PipelineValidator();
      for (final def in allSeeds) {
        final errors = validator
            .validate(def)
            .where((i) => i.isError)
            .map((i) => '${i.stepId ?? '-'}: ${i.message}')
            .toList();
        expect(errors, isEmpty, reason: def.templateId);
      }
    });

    test('every terminal is reachable from a completable step', () {
      // A terminal with no inbound edge is as unreachable as no terminal at
      // all: `planDownstream` only reports `terminalReached` for a terminal
      // whose trigger names sources that actually completed.
      for (final def in allSeeds) {
        final ids = def.steps.map((s) => s.id).toSet();
        for (final terminal in def.steps.where(
          (s) => s.kind == StepKind.terminal,
        )) {
          expect(
            terminal.triggers,
            isNotEmpty,
            reason: '${def.templateId}:${terminal.id} has no inbound edge',
          );
          for (final t in terminal.triggers) {
            expect(
              t.sourceStepIds,
              isNotEmpty,
              reason:
                  '${def.templateId}:${terminal.id} trigger names no '
                  'source step',
            );
            for (final src in t.sourceStepIds) {
              expect(
                ids,
                contains(src),
                reason:
                    '${def.templateId}:${terminal.id} lists upstream '
                    '"$src" which does not exist',
              );
            }
          }
        }
      }
    });

    test('the original entry node is rewired to fire from the trigger', () {
      // For every seed, exactly one non-terminal step listens on the trigger.
      for (final def in allSeeds) {
        final triggerListeners = def.listenersOf('trigger');
        expect(
          triggerListeners,
          isNotEmpty,
          reason: '${def.templateId} has nothing wired off the trigger',
        );
      }
    });

    test('entryStep resolves to the trigger node for every seed', () {
      for (final def in allSeeds) {
        expect(def.entryStep.kind, StepKind.trigger);
      }
    });

    test('every non-trigger step has an inbound edge', () {
      // Sanity: every non-trigger step must declare at least one trigger
      // (listen on some upstream source), otherwise the engine would never
      // fire it. The trigger node itself is the single root with no triggers.
      for (final def in allSeeds) {
        for (final step in def.steps) {
          if (step.kind == StepKind.trigger) {
            continue;
          }
          expect(
            step.triggers,
            isNotEmpty,
            reason: '${def.templateId}:${step.id} has no inbound edge',
          );
        }
      }
    });

    test('pr_review fans out its reviewers then joins', () {
      final pr = seeds.firstWhere((d) => d.templateId == 'pr_review');
      final listenersOfSetup = pr.listenersOf('setup');
      final consolidate = pr.steps.firstWhere((s) => s.id == 'consolidate');
      expect(listenersOfSetup.map((s) => s.id).toSet(), {
        'qa_review',
        'architect_review',
        'engineer_review',
        'security_review',
        'perf_review',
      });
      expect(consolidate.kind, StepKind.join);
      // The join waits on EVERY reviewer, including the ones a given level
      // gates off — a join resolves on completed-or-skipped, so waiting on a
      // gated reviewer is what lets one template serve every level.
      expect(consolidate.waitForStepIds, [
        'qa_review',
        'architect_review',
        'engineer_review',
        'security_review',
        'perf_review',
      ]);
      // The pipeline no longer posts to GitHub directly — publishing is
      // user-gated via publish_review_to_github, so there is no comment step.
      // Consolidation is followed by the deterministic close-out, which turns
      // the filed `review_node` findings into the verdict the PR's review tab
      // reads; the DAG terminates after THAT, not after consolidation.
      expect(pr.step('comment'), isNull);
      expect(pr.step('finalize'), isNotNull);
      final terminal = pr.steps.firstWhere((s) => s.kind == StepKind.terminal);
      expect(terminal.triggers.expand((t) => t.sourceStepIds).toSet(), {
        'finalize',
      });
      expect(pr.inputs.map((i) => i.key).toList(), [
        'repo_full_name',
        'pr_number',
      ]);
    });

    test('pr_review gates its reviewers by review level', () {
      final pr = seeds.firstWhere((d) => d.templateId == 'pr_review');
      List<Object?>? gateOf(String stepId) =>
          pr.step(stepId)?.config.runWhen?.allowed;

      // The engineer reviewer is ungated: a light review is still a review.
      expect(pr.step('engineer_review')?.config.runWhen, isNull);

      // A null entry is what keeps runs that carry no level — started before
      // levels existed, or off the pipeline canvas — behaving as balanced.
      expect(gateOf('qa_review'), ['balanced', 'thorough', null]);
      expect(gateOf('architect_review'), ['balanced', 'thorough', null]);
      expect(gateOf('security_review'), ['thorough']);
      expect(gateOf('perf_review'), ['thorough']);
    });

    test('pr_review balanced runs exactly the historical three', () {
      // The default must be byte-identical in behaviour to what every review
      // ran as before levels existed.
      final pr = seeds.firstWhere((d) => d.templateId == 'pr_review');
      final active = pr
          .listenersOf('setup')
          .where((s) {
            final gate = s.config.runWhen;
            return gate == null || gate.allows('balanced');
          })
          .map((s) => s.id)
          .toSet();
      expect(active, {'qa_review', 'architect_review', 'engineer_review'});
    });

    test('every gated pr_review reviewer declares a skipped output', () {
      // Without one, a downstream `{{placeholder}}` naming a skipped
      // reviewer's output would not resolve, and an unresolved placeholder
      // fails its step — taking consolidation down with it.
      final pr = seeds.firstWhere((d) => d.templateId == 'pr_review');
      for (final step in pr.listenersOf('setup')) {
        final gate = step.config.runWhen;
        if (gate == null) {
          continue;
        }
        expect(gate.skippedOutput, isNotNull, reason: step.id);
        expect(gate.key, 'review_level', reason: step.id);
        expect(step.config.outputKey, isNotNull, reason: step.id);
      }
    });

    test('consolidate reads every reviewer output key', () {
      // A reviewer whose output the consolidation never reads is a reviewer
      // whose findings silently do not reach the report.
      final pr = seeds.firstWhere((d) => d.templateId == 'pr_review');
      final consolidate = pr.steps.firstWhere((s) => s.id == 'consolidate');
      for (final step in pr.listenersOf('setup')) {
        expect(
          consolidate.config.inputKeys,
          contains(step.config.outputKey),
          reason: step.id,
        );
        expect(
          consolidate.config.prompt,
          contains('{{${step.config.outputKey}}}'),
          reason: step.id,
        );
      }
    });

    test('pr_review names a conversation for every step that runs in the '
        'review space', () {
      // A pipeline-made review space holds exactly the streams the pipeline
      // opened — one per reviewer plus the consolidate one — and no "main"
      // standing conversation. Every prompt step that names the space as its
      // room must therefore also name its stream; one that does not writes
      // into the standing stream and mints it.
      final pr = seeds.firstWhere((d) => d.templateId == 'pr_review');
      final inSpace = pr.steps.where(
        (s) => s.config.extras['spaceId'] == '{{review_space_id}}',
      );
      expect(inSpace, isNotEmpty);
      for (final step in inSpace) {
        expect(
          step.config.extras['conversationTitle'],
          isNotNull,
          reason: step.id,
        );
      }
      final consolidate = pr.steps.firstWhere((s) => s.id == 'consolidate');
      expect(
        consolidate.config.extras['conversationTitle'],
        BuiltInBodyKeys.reviewConsolidateConversationTitle,
      );
    });

    test('external_pr_welcome ships disabled with a greet step', () {
      final welcome = seeds.firstWhere(
        (d) => d.templateId == 'external_pr_welcome',
      );
      expect(welcome.isEnabled, isFalse);
      expect(welcome.step('greet')?.bodyKey, BuiltInBodyKeys.bashScript);
    });

    test('pr_merged_cleanup uses the cleanupRepos body', () {
      final cleanup = seeds.firstWhere(
        (d) => d.templateId == 'pr_merged_cleanup',
      );
      expect(cleanup.step('cleanup')?.bodyKey, BuiltInBodyKeys.cleanupRepos);
    });

    test('cross_review has security / perf / a11y branches', () {
      final cross = seeds.firstWhere((d) => d.templateId == 'cross_review');
      expect(cross.isEnabled, isFalse);
      // The specialists fan out off the space node, not a clone node: the PR
      // checkout is the room's.
      expect(cross.step('clone'), isNull);
      expect(cross.listenersOf('space').map((s) => s.id).toSet(), {
        'security_review',
        'perf_review',
        'a11y_review',
      });
      final consolidate = cross.step('consolidate')!;
      expect(consolidate.kind, StepKind.join);
      expect(consolidate.waitForStepIds, [
        'security_review',
        'perf_review',
        'a11y_review',
      ]);
    });

    test('ticket_to_pr implements then opens a draft PR in parallel', () {
      final t2p = seeds.firstWhere((d) => d.templateId == 'ticket_to_pr');
      expect(t2p.isEnabled, isFalse);
      expect(t2p.step('implement')?.config.agentId, agentIds.coder);
      expect(t2p.step('open_pr')?.kind, StepKind.listen);
      expect(t2p.step('self_review')?.config.agentId, agentIds.engineer);
      // Comment joins open_pr + self_review.
      final comment = t2p.step('comment')!;
      expect(comment.kind, StepKind.join);
      expect(comment.waitForStepIds, ['open_pr', 'self_review']);
      // Declared manual-run inputs.
      expect(
        t2p.inputs.map((i) => i.key),
        containsAll(['repo_full_name', 'ticket_id', 'ticket_title', 'ticket_body']),
      );
    });

    test('pr_triage routes on prClass via a router node', () {
      final triage = seeds.firstWhere((d) => d.templateId == 'pr_triage');
      expect(triage.isEnabled, isFalse);
      final route = triage.step('route')!;
      expect(route.kind, StepKind.router);
      expect(route.bodyKey, BuiltInBodyKeys.condition);
      expect(route.config.extras['switchKey'], 'pr_class');
      expect(route.config.extras['cases'], ['docs', 'security', 'standard']);
      // Each branch review listens with its routeKey.
      final docsReview = triage.step('docs_review')!;
      expect(docsReview.triggers.single.routeKey, 'docs');
      final securityReview = triage.step('security_review')!;
      expect(securityReview.triggers.single.routeKey, 'security');
      final standardReview = triage.step('standard_review')!;
      expect(standardReview.triggers.single.routeKey, 'standard');
      // Three comment branches converge at the terminal.
      final terminal = triage.steps.firstWhere(
        (s) => s.kind == StepKind.terminal,
      );
      expect(terminal.triggers.expand((t) => t.sourceStepIds).toSet(), {
        'docs_comment',
        'security_comment',
        'standard_comment',
      });
    });

    test('pre_merge_gate routes approved/rejected then merges or notifies', () {
      final gate = seeds.firstWhere((d) => d.templateId == 'pre_merge_gate');
      expect(gate.isEnabled, isFalse);
      expect(gate.step('gate')?.bodyKey, BuiltInBodyKeys.humanGate);
      final route = gate.step('route')!;
      expect(route.kind, StepKind.router);
      expect(route.config.extras['cases'], ['approved', 'rejected']);
      expect(gate.step('merge')?.triggers.single.routeKey, 'approved');
      expect(gate.step('merge')?.config.extras['idempotent'], false);
      expect(gate.step('notify_changes')?.triggers.single.routeKey, 'rejected');
    });

    test('release_notes collects commits then drafts', () {
      final release = seeds.firstWhere((d) => d.templateId == 'release_notes');
      expect(release.isEnabled, isFalse);
      expect(release.step('collect')?.bodyKey, BuiltInBodyKeys.bashScript);
      expect(release.step('draft')?.config.agentId, agentIds.librarian);
    });

    test('dep_audit checks each ecosystem manifest before auditing', () {
      final dep = seeds.firstWhere((d) => d.templateId == 'dep_audit');
      expect(dep.isEnabled, isFalse);
      // Five check routers fan off the space node — the clone step is gone;
      // they probe the room's copy-on-write checkout instead.
      expect(dep.step('clone'), isNull);
      expect(dep.listenersOf('space').map((s) => s.id).toSet(), {
        'check_dart',
        'check_rust',
        'check_npm',
        'check_pnpm',
        'check_yarn',
      });
      // The consolidate join waits for all five audits.
      final consolidate = dep.step('consolidate')!;
      expect(consolidate.kind, StepKind.join);
      expect(consolidate.waitForStepIds, hasLength(5));
      // Each audit is gated on its router's "true" edge.
      expect(dep.step('audit_dart')?.triggers.single.routeKey, 'true');
      expect(dep.step('audit_rust')?.triggers.single.routeKey, 'true');
    });

    test('pr_digest gathers, summarizes, then posts to a space', () {
      final digest = seeds.firstWhere((d) => d.templateId == 'pr_digest');
      expect(digest.isEnabled, isFalse);
      expect(digest.step('post')?.bodyKey, BuiltInBodyKeys.messagingPostSpace);
      expect(digest.inputs.map((i) => i.key), contains('space_id'));
    });

    test('index_code dispatches the librarian when one is provided', () {
      final index = seeds.firstWhere((d) => d.templateId == 'index_code');
      expect(index.step('index')?.bodyKey, BuiltInBodyKeys.indexCode);
      expect(index.step('analyze')?.config.agentId, agentIds.librarian);
      expect(index.step('analyze')?.triggers.single.sourceStepIds, ['space']);
      // The room opens AFTER the indexer: a run only earns a conversation —
      // and the checkout that comes with it — once there is a graph for the
      // librarian to read.
      final space = index.step('space')!;
      expect(space.bodyKey, BuiltInBodyKeys.createSpace);
      expect(space.triggers.single.sourceStepIds, ['index']);
      expect(index.step('index')?.triggers.single.sourceStepIds, ['trigger']);
      // The room checks out only the repo being indexed, not every workspace
      // repo (heavy IO/FS) — repoId is always in the payload (RepoAdded event /
      // required repo input) — and opens with only the librarian.
      expect(space.config.repoIds, ['{{repo_id}}']);
      expect(space.config.extras['agentIds'], [agentIds.librarian]);
      expect(
        index.step('analyze')?.config.extras['spaceId'],
        '{{$kPipelineSpaceStateKey}}',
      );
    });

    test('index_code opens its room already holding the analysis stream', () {
      // The analysis starts minutes after the room does (it waits for the
      // index), and a room with NO conversation mints an untitled standing one
      // the first time anything reads it — the sidebar, the step-detail panel.
      // Opening the librarian's stream up front, under the title the `analyze`
      // step reuses, is what keeps the room at one conversation.
      final index = seeds.firstWhere((d) => d.templateId == 'index_code');
      final space = index.step('space')!;
      final analyze = index.step('analyze')!;
      expect(space.config.createsConversation, isTrue);
      expect(
        space.config.conversationTitle,
        analyze.config.conversationTitle,
        reason:
            'the space node and the agent step must name the SAME stream, or '
            'the room ends up holding two',
      );
    });

    test('every agent-bearing seed opens exactly one shared room', () {
      // A step that dispatches an agent WITHOUT naming a room mints its own
      // hidden conversation — invisible in the sidebar, and one checkout of
      // the same repos per step. Every built-in that dispatches must therefore
      // carry a space node and point its agent steps at it.
      const dispatchBodies = {
        BuiltInBodyKeys.promptAgent,
        BuiltInBodyKeys.teamDispatch,
        BuiltInBodyKeys.humanGate,
        BuiltInBodyKeys.forEach,
      };
      for (final def in allSeeds) {
        final dispatchSteps = def.steps
            .where((s) => dispatchBodies.contains(s.bodyKey))
            .toList();
        if (dispatchSteps.isEmpty) {
          continue;
        }
        final spaceNodes = def.steps
            .where((s) => s.bodyKey == BuiltInBodyKeys.createSpace)
            .toList();
        expect(spaceNodes, hasLength(1), reason: def.templateId);
        // `pr_review` opens the same node in its pull-request lane, which
        // resolves the PR's OWN room — so its id lands under `review_space_id`
        // rather than the generic run-room key. Every other built-in opens a
        // room of its own under the standard key.
        final roomKey = spaceNodes.single.config.outputKey;
        expect(
          roomKey,
          def.templateId == 'pr_review'
              ? 'review_space_id'
              : kPipelineSpaceStateKey,
          reason: def.templateId,
        );
        for (final step in dispatchSteps) {
          expect(
            step.config.spaceId,
            '{{$roomKey}}',
            reason: '${def.templateId}:${step.id} does not name the run room',
          );
          // Sharing a room means sharing its standing stream unless each step
          // names its own — otherwise a fan-out interleaves every agent's turn
          // into one thread.
          expect(
            step.config.conversationTitle,
            isNotNull,
            reason: '${def.templateId}:${step.id} names no stream',
          );
        }
        // A step that reuses a room ignores its own `repoIds`, so declaring
        // one there is a scope nobody applies. The space node owns it.
        for (final step in dispatchSteps) {
          expect(
            step.config.repoIds,
            isEmpty,
            reason: '${def.templateId}:${step.id} declares a dead repo scope',
          );
        }
      }
    });

    test('no built-in opens with a full clone of a repository', () {
      // Every checkout a pipeline works in is the room's copy-on-write copy of
      // the linked repo (scrubbed, fetched, switched). A clone step
      // re-downloads the whole repository per run.
      for (final def in allSeeds) {
        for (final step in def.steps) {
          final script = step.config.script ?? '';
          expect(
            script,
            isNot(anyOf(contains('repo clone'), contains('git clone'))),
            reason: '${def.templateId}:${step.id} clones a repository',
          );
        }
      }
    });

    test('a step that works in the checkout waits for it', () {
      // Dropping the clone steps moved `repoLocalPath` onto the space node,
      // which only publishes it when it waits for the checkout. A step that
      // ADDRESSES the tree through that key — a script, a file-existence
      // router, a prompt that tells an agent where the code is — would
      // otherwise fall back to whatever the trigger payload carried: on a
      // manual run, the operator's own checkout on its own branch.
      //
      // Declaring the key in `inputKeys` alone is not that: `index_code`'s
      // analyzer lists it because the indexer reads the LINKED checkout, and
      // studies the resulting graph through the code tools.
      for (final def in allSeeds) {
        final readers = def.steps.where(
          (s) =>
              (s.config.script ?? '').contains('{{repo_local_path}}') ||
              (s.config.prompt ?? '').contains('{{repo_local_path}}') ||
              s.config.extras['predicate'].toString().contains('repo_local_path'),
        );
        if (readers.isEmpty) {
          continue;
        }
        final space = def.steps
            .where((s) => s.bodyKey == BuiltInBodyKeys.createSpace)
            .firstOrNull;
        if (space == null) {
          continue;
        }
        expect(
          space.config.extras['awaitReady'],
          isTrue,
          reason:
              '${def.templateId} reads repoLocalPath but its space node does '
              'not wait for the checkout that produces it',
        );
      }
    });

    test(
      'indexCodeTemplate produces the standalone template without analyze',
      () {
        final standalone = indexCodeTemplate(workspaceId);
        expect(standalone.templateId, 'index_code');
        expect(standalone.step('index'), isNotNull);
        expect(standalone.step('analyze'), isNull);
        expect(standalone.step('index\$terminal'), isNotNull);
      },
    );

    test('skillAnalysisTemplate scans, then terminates off the scan', () {
      final skills = skillAnalysisTemplate(workspaceId);
      expect(skills.templateId, SkillAnalysisTemplate.id);
      expect(
        skills.step(SkillAnalysisTemplate.scanStepId)?.bodyKey,
        BuiltInBodyKeys.skillAnalysis,
      );
      // The terminal is what lets the run reach `completed`. It shipped
      // missing once, and every `skill_analysis` run then read "Running"
      // forever while its dedup key blocked the next scan of the same skill.
      final terminal = skills.step(
        '${SkillAnalysisTemplate.scanStepId}\$terminal',
      );
      expect(terminal, isNotNull);
      expect(terminal!.kind, StepKind.terminal);
      expect(terminal.triggers.single.sourceStepIds, [
        SkillAnalysisTemplate.scanStepId,
      ]);
    });

    test('meeting_summary fans out three parallel persists off the summary', () {
      final meeting = seeds.firstWhere(
        (d) => d.templateId == 'meeting_summary',
      );
      final summarize = meeting.step('summarize')!;
      expect(summarize.config.outputKey, 'meeting_outcome');
      expect(summarize.config.extras['mode'], 'chat');
      // save_notes / add_action_items / add_decisions all listen to summarize.
      expect(meeting.listenersOf('summarize').map((s) => s.id).toSet(), {
        'save_notes',
        'add_action_items',
        'add_decisions',
      });
      expect(
        meeting.step('save_notes')?.bodyKey,
        BuiltInBodyKeys.meetingSaveNotes,
      );
      expect(
        meeting.step('add_action_items')?.bodyKey,
        BuiltInBodyKeys.meetingAddActionItems,
      );
      expect(
        meeting.step('add_decisions')?.bodyKey,
        BuiltInBodyKeys.meetingAddDecisions,
      );
      // The diarize / identify / transcript-update / playback chain.
      expect(meeting.step('diarize')?.bodyKey, BuiltInBodyKeys.meetingDiarize);
      expect(
        meeting.step('identify_speakers')?.bodyKey,
        BuiltInBodyKeys.meetingIdentifySpeakers,
      );
      expect(meeting.step('summarize')?.triggers.single.sourceStepIds, [
        'identify_speakers',
      ]);
      // The terminal joins all five sources.
      final terminal = meeting.steps.firstWhere(
        (s) => s.kind == StepKind.terminal,
      );
      expect(terminal.triggers.single.sourceStepIds.toSet(), {
        'save_notes',
        'add_action_items',
        'add_decisions',
        'update_transcript',
        'assemble_playback',
      });
    });

  });

  group('builtInTriggerSeeds', () {
    final triggerSeeds = builtInTriggerSeeds();

    test('pr_review ships a manual trigger', () {
      final pr = triggerSeeds['pr_review']!;
      expect(pr, hasLength(1));
      expect(pr.single.eventType, 'manual');
      expect(pr.single.enabled, isTrue);
    });

    test('external_pr_welcome ships an ExternalPrDetected event trigger', () {
      final ext = triggerSeeds['external_pr_welcome']!;
      expect(ext.single.eventType, 'ExternalPrDetected');
    });

    test('pr_merged_cleanup ships manual + events + an enabled daily GC sweep', () {
      final cleanup = triggerSeeds['pr_merged_cleanup']!;
      expect(cleanup.map((t) => t.eventType).toSet(), {
        'manual',
        'PullRequestStatusChanged',
        'TicketCompleted',
        'TicketCancelled',
        // Deleting a conversation orphans its worktrees + folder, so the
        // cleanup pipeline reclaims them on SpaceDeleted rather than waiting
        // for the (opt-in, weekly) sweep.
        'SpaceDeleted',
        'schedule',
      });
      // The PR-status event filters to merged/closed/approved.
      final prStatus = cleanup.firstWhere(
        (t) => t.eventType == 'PullRequestStatusChanged',
      );
      expect(prStatus.match['status'], ['merged', 'closed', 'approved']);
      // Unlike every other scheduled seed this one is ENABLED and DAILY: it is
      // garbage collection, not a convenience. Left opt-in and weekly, orphaned
      // worktree rows accumulate (117 measured on a real host), each costing a
      // watcher, a code-graph partition and a CoW copy on disk. The events above
      // cover the normal path; this catches what they missed while the server
      // was down.
      final schedule = cleanup.firstWhere((t) => t.eventType == 'schedule');
      expect(schedule.enabled, isTrue);
      expect(schedule.cronExpression, 'every:86400');
    });

    test('ticket_to_pr ships manual + TicketAssigned', () {
      final t2p = triggerSeeds['ticket_to_pr']!;
      expect(t2p.map((t) => t.eventType).toSet(), {'manual', 'TicketAssigned'});
    });

    test('release_notes ships a PullRequestStatusChanged(merged) filter', () {
      final release = triggerSeeds['release_notes']!;
      final event = release.firstWhere(
        (t) => t.eventType == 'PullRequestStatusChanged',
      );
      expect(event.match['status'], ['merged']);
    });

    test('dep_audit ships manual + a weekly opt-in schedule', () {
      final dep = triggerSeeds['dep_audit']!;
      final schedule = dep.firstWhere((t) => t.eventType == 'schedule');
      expect(schedule.enabled, isFalse);
      expect(schedule.cronExpression, 'every:604800');
    });

    test('index_code ships manual + RepoAdded', () {
      final index = triggerSeeds['index_code']!;
      expect(index.map((t) => t.eventType).toSet(), {'manual', 'RepoAdded'});
    });

    test('meeting_summary ships MeetingRecordingStopped + manual', () {
      final meeting = triggerSeeds['meeting_summary']!;
      expect(meeting.map((t) => t.eventType).toSet(), {
        'MeetingRecordingStopped',
        'manual',
      });
    });

    test('every BuiltInTriggerSeed constructor is covered', () {
      // Exercise all three named constructors directly.
      const manual = BuiltInTriggerSeed.manual();
      expect(manual.eventType, 'manual');
      expect(manual.enabled, isTrue);

      const event = BuiltInTriggerSeed.event('Foo', match: {'a': 'b'});
      expect(event.eventType, 'Foo');
      expect(event.match, {'a': 'b'});
      expect(event.cronExpression, isNull);

      const schedule = BuiltInTriggerSeed.schedule('every:60', enabled: true);
      expect(schedule.eventType, 'schedule');
      expect(schedule.cronExpression, 'every:60');
      expect(schedule.enabled, isTrue);
    });
  });

  group('manualRunnableBuiltInTemplateIds', () {
    test('includes every template with a manual trigger', () {
      final manual = manualRunnableBuiltInTemplateIds;
      expect(
        manual,
        containsAll([
          'pr_review',
          'pr_merged_cleanup',
          'cross_review',
          'ticket_to_pr',
          'pr_triage',
          'pre_merge_gate',
          'release_notes',
          'dep_audit',
          'pr_digest',
          'index_code',
          'meeting_summary',
        ]),
      );
      // external_pr_welcome has no manual trigger, so it is NOT runnable by hand.
      expect(manual, isNot(contains('external_pr_welcome')));
    });
  });

  group('BuiltInBodyKeys', () {
    test('every key is a non-empty stable string', () {
      // Coverage of the const field getters.
      for (final key in [
        BuiltInBodyKeys.trigger,
        BuiltInBodyKeys.bashScript,
        BuiltInBodyKeys.promptAgent,
        BuiltInBodyKeys.prReviewComment,
        BuiltInBodyKeys.messagingPostSpace,
        BuiltInBodyKeys.condition,
        BuiltInBodyKeys.teamDispatch,
        BuiltInBodyKeys.humanGate,
        BuiltInBodyKeys.cleanupRepos,
        BuiltInBodyKeys.forEach,
        BuiltInBodyKeys.callFlow,
        BuiltInBodyKeys.indexCode,
        BuiltInBodyKeys.meetingSaveNotes,
        BuiltInBodyKeys.meetingAddActionItems,
        BuiltInBodyKeys.meetingAddDecisions,
        BuiltInBodyKeys.meetingDiarize,
        BuiltInBodyKeys.meetingIdentifySpeakers,
        BuiltInBodyKeys.meetingUpdateTranscript,
        BuiltInBodyKeys.meetingAssemblePlayback,
        BuiltInBodyKeys.orchestrationMarkPhase,
        BuiltInBodyKeys.orchestrationPersistDeliverable,
        BuiltInBodyKeys.orchestrationAwaitApproval,
      ]) {
        expect(key, isNotEmpty);
      }
    });
  });
}
