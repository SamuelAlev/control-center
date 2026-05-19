import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:test/test.dart';

/// Calls each built-in template seed and asserts the returned
/// [PipelineDefinition] has the expected structural invariants: a leading
/// `trigger` entry node, a trailing `terminal` node, and the right step
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
        'hello',
      });
    });

    test(
      'every seed is built-in, belongs to the workspace, and has a name',
      () {
        for (final def in seeds) {
          expect(def.workspaceId, workspaceId);
          expect(def.isBuiltIn, isTrue);
          expect(def.name, isNotEmpty);
          expect(def.description, isNotEmpty);
        }
      },
    );

    test('every seed begins with a trigger node', () {
      for (final def in seeds) {
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
      for (final def in seeds) {
        final triggers = def.steps
            .where((s) => s.kind == StepKind.trigger)
            .toList();
        expect(triggers, hasLength(1), reason: def.templateId);

        // The terminal node is the join sink of the DAG.
        final terminals = def.steps
            .where((s) => s.kind == StepKind.terminal)
            .toList();
        expect(terminals, isNotEmpty, reason: def.templateId);
      }
    });

    test('the original entry node is rewired to fire from the trigger', () {
      // For every seed, exactly one non-terminal step listens on the trigger.
      for (final def in seeds) {
        final triggerListeners = def.listenersOf('trigger');
        expect(
          triggerListeners,
          isNotEmpty,
          reason: '${def.templateId} has nothing wired off the trigger',
        );
      }
    });

    test('entryStep resolves to the trigger node for every seed', () {
      for (final def in seeds) {
        expect(def.entryStep.kind, StepKind.trigger);
      }
    });

    test('every non-trigger step has an inbound edge', () {
      // Sanity: every non-trigger step must declare at least one trigger
      // (listen on some upstream source), otherwise the engine would never
      // fire it. The trigger node itself is the single root with no triggers.
      for (final def in seeds) {
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

    test('pr_review fans out three reviewers then joins', () {
      final pr = seeds.firstWhere((d) => d.templateId == 'pr_review');
      final listenersOfSetup = pr.listenersOf('setup');
      final consolidate = pr.steps.firstWhere((s) => s.id == 'consolidate');
      expect(listenersOfSetup.map((s) => s.id).toSet(), {
        'qa_review',
        'architect_review',
        'engineer_review',
      });
      expect(consolidate.kind, StepKind.join);
      expect(consolidate.waitForStepIds, [
        'qa_review',
        'architect_review',
        'engineer_review',
      ]);
      // The pipeline no longer posts to GitHub directly — publishing is
      // user-gated via publish_review_to_github, so there is no comment step
      // and the DAG terminates right after consolidation.
      expect(pr.step('comment'), isNull);
      final terminal = pr.steps.firstWhere((s) => s.kind == StepKind.terminal);
      expect(terminal.triggers.expand((t) => t.sourceStepIds).toSet(), {
        'consolidate',
      });
      expect(pr.inputs.map((i) => i.key).toList(), [
        'repoFullName',
        'prNumber',
      ]);
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
      expect(cross.listenersOf('clone').map((s) => s.id).toSet(), {
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
        containsAll(['repoFullName', 'ticketId', 'ticketTitle', 'ticketBody']),
      );
    });

    test('pr_triage routes on prClass via a router node', () {
      final triage = seeds.firstWhere((d) => d.templateId == 'pr_triage');
      expect(triage.isEnabled, isFalse);
      final route = triage.step('route')!;
      expect(route.kind, StepKind.router);
      expect(route.bodyKey, BuiltInBodyKeys.condition);
      expect(route.config.extras['switchKey'], 'prClass');
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
      // Five check routers fan off clone.
      expect(dep.listenersOf('clone').map((s) => s.id).toSet(), {
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

    test('pr_digest gathers, summarizes, then posts to a channel', () {
      final digest = seeds.firstWhere((d) => d.templateId == 'pr_digest');
      expect(digest.isEnabled, isFalse);
      expect(
        digest.step('post')?.bodyKey,
        BuiltInBodyKeys.messagingPostChannel,
      );
      expect(digest.inputs.map((i) => i.key), contains('channelId'));
    });

    test('index_code dispatches the librarian when one is provided', () {
      final index = seeds.firstWhere((d) => d.templateId == 'index_code');
      expect(index.step('index')?.bodyKey, BuiltInBodyKeys.indexCode);
      expect(index.step('analyze')?.config.agentId, agentIds.librarian);
      expect(index.step('analyze')?.triggers.single.sourceStepIds, ['index']);
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

    test('meeting_summary fans out three parallel persists off the summary', () {
      final meeting = seeds.firstWhere(
        (d) => d.templateId == 'meeting_summary',
      );
      final summarize = meeting.step('summarize')!;
      expect(summarize.config.outputKey, 'meetingOutcome');
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

    test('hello is the minimal greet -> world -> terminal demo', () {
      final hello = seeds.firstWhere((d) => d.templateId == 'hello');
      expect(hello.step('greet')?.bodyKey, BuiltInBodyKeys.helloGreet);
      expect(hello.step('world')?.bodyKey, BuiltInBodyKeys.helloWorld);
      expect(hello.step('world')?.triggers.single.sourceStepIds, ['greet']);
      expect(hello.inputs, isEmpty);
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
        // cleanup pipeline reclaims them on ChannelDeleted rather than waiting
        // for the (opt-in, weekly) sweep.
        'ChannelDeleted',
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
          'hello',
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
        BuiltInBodyKeys.messagingPostChannel,
        BuiltInBodyKeys.condition,
        BuiltInBodyKeys.teamDispatch,
        BuiltInBodyKeys.humanGate,
        BuiltInBodyKeys.cleanupRepos,
        BuiltInBodyKeys.forEach,
        BuiltInBodyKeys.callFlow,
        BuiltInBodyKeys.helloGreet,
        BuiltInBodyKeys.helloWorld,
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
