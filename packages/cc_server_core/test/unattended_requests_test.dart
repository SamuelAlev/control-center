import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/unattended_policy.dart';
import 'package:cc_domain/features/sandboxing/domain/entities/sandbox_exec_grant.dart';
import 'package:cc_domain/features/sandboxing/domain/repositories/sandbox_exec_grant_repository.dart';
import 'package:cc_domain/features/sandboxing/domain/services/sandbox_exec_grant_service.dart';
import 'package:cc_host/cc_host.dart'
    show PendingConfirmationRegistry, RemoteConfirmationPort;
import 'package:cc_server_core/src/unattended/unattended_requests.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026, 11, 19, 8);

/// The server around [UnattendedRequests]: a real approvals registry, an
/// in-memory question service, run log, goal store and settings.
class _World {
  _World(this.async, {Map<String, String>? settings})
    : settings = settings ?? {};

  final FakeAsync async;
  final bus = DomainEventBus();
  late final registry = PendingConfirmationRegistry(
    timeout: const Duration(hours: 1),
    clock: now,
  );
  final Map<String, String> settings;
  final runs = <String, AgentRunLog>{};
  final goals = <String, AgentGoalRun>{};
  final pendingQuestions = <String>{};
  final questionDeadlines = <String, DateTime>{};
  final released = <String, AgentQuestionAnswer>{};
  final told = <(String, String)>[];
  final rows = <String>[];
  final settled = <AgentGoalRun>[];
  final cancelledWakes = <String>[];
  bool stopping = false;

  /// When set, every settings read waits for it (a slow database).
  Completer<void>? slowReads;
  late UnattendedRequests service;

  DateTime now() => _t0.add(async.elapsed);

  UnattendedRequests start() {
    final s = _start();
    // As the wiring does.
    registry.refuseUnasked = s.refuseApproval;
    return s;
  }

  UnattendedRequests _start() => service = UnattendedRequests(
    eventBus: bus,
    now: now,
    ports: UnattendedRequestPorts(
      readSetting: (ws, key) async {
        await slowReads?.future;
        return settings['$ws/$key'];
      },
      writeSetting: (ws, key, value) async {
        if (value == null) {
          settings.remove('$ws/$key');
        } else {
          settings['$ws/$key'] = value;
        }
      },
      runById: (ws, id) async => runs[id],
      approval: (waitId) {
        final p = registry.pendingById(waitId);
        return p == null
            ? null
            : (
                title: p.request.title,
                runId: p.request.runId,
                createdAt: p.createdAt,
              );
      },
      denyApprovalAfter: registry.denyAfter,
      // As the wiring does: an expiry, told to the producer as unanswered.
      denyApproval: registry.expire,
      questionWaitUntil: (id, until) async {
        questionDeadlines[id] = until;
        return pendingQuestions.contains(id);
      },
      questionPending: pendingQuestions.contains,
      releaseQuestion: (id, answer) {
        if (!pendingQuestions.remove(id)) {
          return false;
        }
        released[id] = answer;
        return true;
      },
      segmentGoalOf: (ws, runId) async {
        for (final g in goals.values) {
          if (g.activeRunId == runId) {
            return g;
          }
        }
        return null;
      },
      transitionGoal: (goal, next) async {
        final current = goals[goal.id];
        if (current == null) {
          return null;
        }
        final moved = next(current);
        if (moved != null) {
          goals[goal.id] = moved;
        }
        return moved;
      },
      cancelGoalWakes: (goal) async => cancelledWakes.add(goal.id),
      publishGoalSettled: settled.add,
      postRow:
          ({
            required workspaceId,
            required spaceId,
            required conversationId,
            required content,
          }) async => rows.add(content),
      tellRun: (runId, notice) async {
        told.add((runId, notice));
        return true;
      },
      stopping: () => stopping,
    ),
  )..start();

  AgentRunLog run(
    String id, {
    WakeReason? reason = WakeReason.goalContinuation,
    List<String> wakeIds = const ['wake-1'],
    String? person,
  }) => runs[id] = AgentRunLog(
    id: id,
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    spaceId: 'sp-1',
    startedAt: now(),
    status: RunStatus.running,
    wakeReason: reason,
    wakeIds: wakeIds,
    requestedByUserId: person,
  );

  AgentGoalRun goal(
    String runId, {
    GoalUnattendedPolicy unattended = GoalUnattendedPolicy.wait,
  }) => goals['goal-1'] = AgentGoalRun(
    id: 'goal-1',
    workspaceId: 'ws-1',
    spaceId: 'sp-1',
    conversationId: 'conv-1',
    agentId: 'agent-1',
    userText: 'Ship the parser',
    costCapMicros: 50000000,
    activeRunId: runId,
    unattended: unattended,
    requestedByUserId: 'user-1',
    createdAt: _t0,
    updatedAt: _t0,
  );

  /// An approval of the agent's live run, as the publisher announces it.
  Future<bool> approval({String? runId = 'run-1'}) {
    final reg = registry.register(
      ConfirmationRequest(
        spaceId: 'sp-1',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        title: 'Push to main',
        detail: 'git push',
        runId: runId,
      ),
    );
    bus.publish(
      AgentAwaitingInput(
        workspaceId: 'ws-1',
        waitId: reg.id,
        kind: AgentInputKind.approval,
        summary: 'Push to main',
        spaceId: 'sp-1',
        agentId: 'agent-1',
        occurredAt: now(),
      ),
    );
    async.flushMicrotasks();
    return reg.approved;
  }

  /// A question of [runId], as the question service announces it.
  void question(String waitId, String runId) {
    pendingQuestions.add(waitId);
    bus.publish(
      AgentAwaitingInput(
        workspaceId: 'ws-1',
        waitId: waitId,
        kind: AgentInputKind.question,
        summary: 'Postgres or SQLite?',
        spaceId: 'sp-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        runId: runId,
        occurredAt: now(),
      ),
    );
    async.flushMicrotasks();
  }

  void settle(String runId, RunEndReason reason) {
    final r = runs[runId]!;
    bus.publish(
      AgentRunSettled(
        agentId: r.agentId,
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        conversationId: 'conv-1',
        runId: runId,
        status: RunStatus.completed,
        endReason: reason,
        costMicros: 0,
        limitResetsAt: null,
        wakeIds: r.wakeIds,
        requestedByUserId: null,
        wakeReason: r.wakeReason,
        occurredAt: now(),
      ),
    );
    async.flushMicrotasks();
  }

  String? get marker =>
      settings['ws-1/${UnattendedRequests.markerKeyOf('agent-1', 'conv-1')}'];

  void dispose() {
    async.flushMicrotasks();
    registry.dispose();
    bus.dispose();
  }
}

void main() {
  test('an approval nobody answers is denied at the workspace expiry, never '
      'approved; the run is told and the goal waits for review', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w
        ..run('run-1')
        ..goal('run-1');
      bool? decision;
      w.approval().then((v) => decision = v);
      // The registry's own hour is not the deadline any more.
      async.elapse(const Duration(hours: 71, minutes: 59));
      expect(decision, isNull);
      // The goal supervisor alone holds a segment on its approvals.
      expect(w.goals['goal-1']!.hold, isNull);
      async.elapse(const Duration(minutes: 2));
      expect(decision, isFalse);
      expect(w.registry.snapshot, isEmpty);
      final goal = w.goals['goal-1']!;
      expect(goal.status, AgentGoalStatus.paused);
      expect(goal.hold, GoalHold.needsReview);
      expect(goal.holdDetail, goalHoldUnanswered);
      expect(w.settled.single.id, 'goal-1');
      expect(w.cancelledWakes, ['goal-1']);
      expect(w.told.single.$1, 'run-1');
      expect(w.told.single.$2, contains('counts as denied'));
      expect(
        w.rows.single,
        contains('within 3 days, so it counts as denied'),
      );
      expect(w.marker, isNull);
      w.dispose();
    });
  });

  test('an approval answered while its wait is being set up leaves no hold '
      'on the goal', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w
        ..run('run-1')
        ..goal('run-1')
        ..slowReads = Completer<void>();
      bool? decision;
      w.approval().then((v) => decision = v);
      final id = w.registry.snapshot.single.id;
      expect(w.registry.respond(id, approved: true), isTrue);
      w.bus.publish(
        AgentInputResolved(
          workspaceId: 'ws-1',
          waitId: id,
          occurredAt: w.now(),
        ),
      );
      async.flushMicrotasks();
      w.slowReads!.complete();
      async.flushMicrotasks();
      expect(decision, isTrue);
      expect(w.goals['goal-1']!.hold, isNull);
      expect(w.goals['goal-1']!.status, AgentGoalStatus.active);
      async.elapse(const Duration(hours: 25));
      expect(w.goals['goal-1']!.status, AgentGoalStatus.active);
      expect(w.rows, isEmpty);
      w.dispose();
    });
  });

  test('every expiry path only denies: across many requests and expiries, '
      'not one approval resolves true', () {
    fakeAsync((async) {
      final w = _World(
        async,
        settings: {
          'ws-1/$unattendedPolicySettingKey': '{"expiry_minutes": 60}',
        },
      )..start();
      w.run('run-1');
      final decisions = <bool>[];
      for (var i = 0; i < 5; i++) {
        w.approval().then(decisions.add);
        async.elapse(const Duration(minutes: 7));
      }
      async.elapse(const Duration(hours: 3));
      expect(decisions, hasLength(5));
      expect(decisions, everyElement(isFalse));
      w.dispose();
    });
  });

  test('a question nobody answers is withdrawn as unanswered and the goal '
      'goes to needsReview', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w
        ..run('run-1')
        ..goal('run-1')
        ..question('q-1', 'run-1');
      expect(
        w.questionDeadlines['q-1'],
        _t0.add(const Duration(hours: 72, minutes: 5)),
      );
      async.elapse(const Duration(hours: 71));
      expect(w.released, isEmpty);
      async.elapse(const Duration(hours: 1, seconds: 1));
      final answer = w.released['q-1']!;
      expect(answer.serverNotice, contains('counts as unanswered'));
      expect(answer.proceed, isFalse);
      expect(AskUserOutcome.fromAnswer(answer).isError, isTrue);
      expect(w.goals['goal-1']!.status, AgentGoalStatus.paused);
      expect(w.goals['goal-1']!.hold, GoalHold.needsReview);
      expect(w.goals['goal-1']!.holdDetail, 'unanswered');
      expect(w.told, isEmpty, reason: 'the tool result tells the run');
      w.dispose();
    });
  });

  test('an approval is matched to its run by id only: a person\'s run '
      'beside a goal segment of the same agent keeps the defaults, and an '
      'approval with no run is never the segment\'s', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w
        ..run('segment-1')
        ..goal('segment-1');
      w.runs['chat-1'] = AgentRunLog(
        id: 'chat-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-other',
        spaceId: 'sp-1',
        startedAt: w.now(),
        status: RunStatus.running,
        wakeReason: WakeReason.userMessage,
      );
      bool? chat;
      bool? unknown;
      w.approval(runId: 'chat-1').then((v) => chat = v);
      w.approval(runId: null).then((v) => unknown = v);
      expect(w.service.tracked, isEmpty);
      expect(w.goals['goal-1']!.hold, isNull);
      // Both keep the registry's own hour.
      async.elapse(const Duration(hours: 1, minutes: 1));
      expect(chat, isFalse);
      expect(unknown, isFalse);
      expect(w.goals['goal-1']!.status, AgentGoalStatus.active);
      expect(w.told, isEmpty);
      expect(w.rows, isEmpty);
      w.dispose();
    });
  });

  test('a run a person started never expires', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w.run('run-1', reason: WakeReason.userMessage);
      w.goal('run-1');
      w.question('q-1', 'run-1');
      async.elapse(const Duration(days: 8));
      expect(w.released, isEmpty);
      expect(w.questionDeadlines, isEmpty);
      expect(w.service.tracked, isEmpty);
      expect(w.goals['goal-1']!.status, AgentGoalStatus.active);

      w.runs.clear();
      w.run('run-2', reason: null);
      w.question('q-2', 'run-2');
      async.elapse(const Duration(days: 8));
      expect(w.released, isEmpty);
      w.dispose();
    });
  });

  test('the expiry survives a restart: the resumed segment\'s request keeps '
      'the first request\'s start', () {
    fakeAsync((async) {
      final settings = <String, String>{};
      final before = _World(async, settings: settings)..start();
      before
        ..run('run-1')
        ..goal('run-1')
        ..question('q-1', 'run-1');
      expect(before.marker, isNotNull);
      async.elapse(const Duration(hours: 20));
      // The server stops: the wait is abandoned, the run settles stopped.
      before.stopping = true;
      before.bus.publish(
        AgentInputResolved(
          workspaceId: 'ws-1',
          waitId: 'q-1',
          occurredAt: before.now(),
        ),
      );
      before.settle('run-1', RunEndReason.serverStopped);
      expect(before.marker, isNotNull, reason: 'a server stop is no answer');
      before.service.dispose();
      before.dispose();

      // The next boot resumes the goal; its new segment asks again.
      final after = _World(async, settings: settings)..start();
      // The interrupted run's wake is delivered again (reopened as
      // server_stopped): the new run carries it.
      after
        ..run('run-2', wakeIds: const ['wake-1'])
        ..goal('run-2')
        ..question('q-2', 'run-2');
      async.elapse(const Duration(hours: 51, minutes: 59));
      expect(after.released, isEmpty);
      async.elapse(const Duration(minutes: 2));
      expect(after.released['q-2']?.serverNotice, isNotNull);
      expect(after.goals['goal-1']!.hold, GoalHold.needsReview);
      after.dispose();
    });
  });

  test('a stale stretch never withdraws a fresh request: a goal paused '
      'across a restart and resumed days later asks afresh', () {
    fakeAsync((async) {
      final settings = <String, String>{};
      final before = _World(async, settings: settings)..start();
      before
        ..run('run-1')
        ..goal('run-1')
        ..question('q-1', 'run-1');
      async.elapse(const Duration(hours: 1));
      before.stopping = true;
      before.bus.publish(
        AgentInputResolved(
          workspaceId: 'ws-1',
          waitId: 'q-1',
          occurredAt: before.now(),
        ),
      );
      before.settle('run-1', RunEndReason.serverStopped);
      before.service.dispose();
      before.dispose();
      expect(before.marker, isNotNull);

      // Days after the restart (the person paused and resumed the goal),
      // its new segment, started by a new wake, asks: it does not inherit.
      async.elapse(const Duration(days: 3));
      final after = _World(async, settings: settings)..start();
      after
        ..run('run-2', wakeIds: const ['wake-segment-9'])
        ..goal('run-2')
        ..question('q-2', 'run-2');
      async.flushMicrotasks();
      expect(after.released, isEmpty, reason: 'not withdrawn at once');
      async.elapse(const Duration(hours: 71));
      expect(after.released, isEmpty);
      async.elapse(const Duration(hours: 1, minutes: 1));
      expect(after.released['q-2']?.serverNotice, isNotNull);
      after.dispose();
    });
  });

  test('a person pausing, resuming, cancelling or closing the goal forgets '
      'its stretch', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w
        ..run('run-1')
        ..goal('run-1')
        ..question('q-1', 'run-1');
      expect(w.marker, isNotNull);
      // Another goal's decision leaves it.
      w.service.forgetGoal(
        w.goals['goal-1']!.copyWith(id: 'goal-other'),
      );
      async.flushMicrotasks();
      expect(w.marker, isNotNull);
      w.service.forgetGoal(w.goals['goal-1']!);
      async.flushMicrotasks();
      expect(w.marker, isNull);
      w.dispose();
    });
  });

  test('an answer, or a run that ends, starts the next stretch afresh', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w
        ..run('run-1')
        ..question('q-1', 'run-1');
      async.elapse(const Duration(hours: 20));
      w.pendingQuestions.remove('q-1');
      w.bus.publish(
        AgentInputResolved(
          workspaceId: 'ws-1',
          waitId: 'q-1',
          occurredAt: w.now(),
        ),
      );
      async.flushMicrotasks();
      expect(w.marker, isNull);
      w.question('q-2', 'run-1');
      async.elapse(const Duration(hours: 71));
      expect(w.released, isEmpty, reason: 'the second question has 72 hours');
      w.settle('run-1', RunEndReason.completed);
      expect(w.marker, isNull);
      expect(w.service.tracked, isEmpty);
      w.dispose();
    });
  });

  test('--unattended assume releases a question after 10 minutes with the '
      'pinned answer, and never an approval', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w
        ..run('run-1')
        ..goal('run-1', unattended: GoalUnattendedPolicy.assume);
      bool? decision;
      w.approval().then((v) => decision = v);
      w.question('q-1', 'run-1');
      async.elapse(const Duration(minutes: 9, seconds: 59));
      expect(w.released, isEmpty);
      async.elapse(const Duration(seconds: 2));
      final answer = w.released['q-1']!;
      expect(answer.serverNotice, unattendedAssumeAnswer);
      expect(answer.proceed, isTrue);
      expect(AskUserOutcome.fromAnswer(answer).text, unattendedAssumeAnswer);
      expect(AskUserOutcome.fromAnswer(answer).isError, isFalse);
      // The goal goes on; the approval still waits for a person.
      expect(w.goals['goal-1']!.status, AgentGoalStatus.active);
      expect(decision, isNull);
      expect(w.registry.snapshot, hasLength(1));
      expect(
        w.service.expiredIn('ws-1', 'run-1'),
        isFalse,
        reason: 'an assumed answer is no expiry',
      );
      async.elapse(const Duration(hours: 73));
      expect(decision, isFalse);
      w.dispose();
    });
  });

  test('a review run waits too, then its question is withdrawn and no goal '
      'is paused (the verifier lands on cannot_verify)', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w
        ..run('review-1', reason: WakeReason.goalReview)
        ..goal('run-segment', unattended: GoalUnattendedPolicy.assume)
        ..question('q-1', 'review-1');
      async.elapse(const Duration(minutes: 11));
      expect(w.released, isEmpty, reason: 'assume never applies to a review');
      async.elapse(const Duration(hours: 72));
      expect(w.released['q-1']!.proceed, isFalse);
      expect(w.goals['goal-1']!.status, AgentGoalStatus.active);
      expect(w.settled, isEmpty);
      w.dispose();
    });
  });

  test("a schedule run's folder card waits the workspace's expiry, not the "
      'card\'s 90 seconds, and its expiry stores no decision: the next run '
      'is asked again', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w.run('run-1', reason: WakeReason.schedule);
      final grants = _Grants();
      // The server's folder port: its own short deadline over the registry.
      final service = SandboxExecGrantService(
        repository: grants,
        confirmationPort: RemoteConfirmationPort(
          w.registry,
          timeout: const Duration(seconds: 90),
        ),
        idFactory: () => 'g-1',
      );
      Future<List<String>> ask([String runId = 'run-1']) =>
          service.approvedRoots(
            workspaceId: 'ws-1',
            candidateRoots: const ['/repo/tools'],
            spaceId: 'sp-1',
            asker: (runId: runId, agentId: 'agent-1', conversationId: 'conv-1'),
          );
      // What the publisher announces for the card: its run, from the card.
      void announce() {
        final card = w.registry.snapshot.single;
        expect(card.request.runId, 'run-1');
        expect(card.request.conversationId, 'conv-1');
        w.bus.publish(
          AgentAwaitingInput(
            workspaceId: 'ws-1',
            waitId: card.id,
            kind: AgentInputKind.approval,
            summary: card.request.title,
            spaceId: 'sp-1',
            conversationId: card.request.conversationId,
            agentId: card.request.agentId,
            runId: card.request.runId,
            occurredAt: w.now(),
          ),
        );
        async.flushMicrotasks();
      }

      List<String>? roots;
      ask().then((r) => roots = r);
      async.flushMicrotasks();
      announce();
      async.elapse(const Duration(minutes: 5));
      expect(roots, isNull, reason: 'not the 90-second deadline');
      async.elapse(const Duration(hours: 72));
      expect(roots, isEmpty, reason: 'refused, never granted');
      expect(grants.rows, isEmpty, reason: 'an expiry is not a deny');
      expect(w.registry.snapshot, isEmpty);

      // The same run is not asked again; the next run is.
      ask().then((r) => roots = r);
      async.flushMicrotasks();
      expect(w.registry.snapshot, isEmpty);
      expect(grants.rows, isEmpty);
      w.run('run-2', reason: WakeReason.schedule);
      ask('run-2').then((r) => roots = r);
      async.flushMicrotasks();
      expect(w.registry.snapshot, hasLength(1));
      w.dispose();
    });
  });

  group('after a request of a run expired', () {
    // A schedule's run (no goal): the expiry of its first approval.
    _World expired(FakeAsync async) {
      final w = _World(async)..start();
      w.run('run-1', reason: WakeReason.schedule);
      w.approval();
      async.elapse(const Duration(hours: 72, minutes: 1));
      expect(w.service.expiredIn('ws-1', 'run-1'), isTrue);
      w.told.clear();
      return w;
    }

    test('a later approval of the run is refused at once, with no card, and '
        'its producer hears nobody answered', () {
      fakeAsync((async) {
        final w = expired(async);
        var unanswered = false;
        bool? decision;
        w.registry
            .register(
              ConfirmationRequest(
                spaceId: 'sp-1',
                workspaceId: 'ws-1',
                agentId: 'agent-1',
                title: 'Deploy',
                detail: 'deploy',
                runId: 'run-1',
                onUnanswered: () => unanswered = true,
              ),
            )
            .approved
            .then((v) => decision = v);
        async.flushMicrotasks();
        expect(decision, isFalse, reason: 'no wait');
        expect(unanswered, isTrue, reason: 'audited as nobody answering');
        expect(w.registry.snapshot, isEmpty, reason: 'no card');
        expect(w.told.single.$1, 'run-1');
        expect(
          w.told.single.$2,
          unattendedAfterExpiryApprovalNotice('Deploy'),
        );
        expect(w.told.single.$2, contains('nobody is there'));
        w.dispose();
      });
    });

    test('a later question of the run counts as unanswered at once', () {
      fakeAsync((async) {
        final w = expired(async);
        final answer = w.service.answerQuestion(
          const AgentQuestionRequest(
            workspaceId: 'ws-1',
            spaceId: 'sp-1',
            conversationId: 'conv-1',
            question: 'Which branch?',
            runId: 'run-1',
          ),
        );
        expect(answer?.serverNotice, unattendedAfterExpiryQuestionNotice);
        expect(answer?.proceed, isFalse);
        // Another workspace's run of the same id is not that run.
        expect(
          w.service.answerQuestion(
            const AgentQuestionRequest(
              workspaceId: 'ws-2',
              spaceId: 'sp-1',
              conversationId: 'conv-1',
              question: 'Which branch?',
              runId: 'run-1',
            ),
          ),
          isNull,
        );
        w.dispose();
      });
    });

    test("a person's answer in the run clears nothing; the run's end does",
        () {
      fakeAsync((async) {
        final w = expired(async);
        w.bus.publish(
          AgentInputResolved(
            workspaceId: 'ws-1',
            waitId: 'q-other',
            occurredAt: w.now(),
          ),
        );
        async.flushMicrotasks();
        expect(w.service.expiredIn('ws-1', 'run-1'), isTrue);
        w.settle('run-1', RunEndReason.completed);
        expect(w.service.expiredIn('ws-1', 'run-1'), isFalse);
        w.dispose();
      });
    });

    test("a person's own run is unaffected: its approval keeps the "
        "registry's hour", () {
      fakeAsync((async) {
        final w = expired(async);
        w.run('run-p', reason: WakeReason.userMessage);
        bool? decision;
        w.approval(runId: 'run-p').then((v) => decision = v);
        expect(w.registry.snapshot, hasLength(1));
        async.elapse(const Duration(minutes: 59));
        expect(decision, isNull);
        async.elapse(const Duration(minutes: 2));
        expect(decision, isFalse);
        w.dispose();
      });
    });
  });

  test('what waits, for the digest: a pending request with its run, person '
      'and deadline, in its own workspace only, until it is answered or '
      'expires', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w.run('run-1', reason: WakeReason.schedule, person: 'u-1');
      w.approval();
      final pending = w.service.pendingIn('ws-1').single;
      expect(pending.kind, AgentInputKind.approval);
      expect(pending.runId, 'run-1');
      expect(pending.requestedByUserId, 'u-1');
      expect(pending.goalId, isNull);
      expect(pending.summary, 'Push to main');
      expect(pending.conversationId, 'conv-1');
      expect(pending.deadline, _t0.add(const Duration(hours: 72)));
      expect(w.service.pendingIn('ws-2'), isEmpty);

      // Answered: gone.
      w.registry.respond(w.registry.snapshot.single.id, approved: true);
      w.bus.publish(
        AgentInputResolved(
          workspaceId: 'ws-1',
          waitId: pending.waitId,
          occurredAt: w.now(),
        ),
      );
      async.flushMicrotasks();
      expect(w.service.pendingIn('ws-1'), isEmpty);

      // Expired: gone.
      w.question('q-1', 'run-1');
      expect(w.service.pendingIn('ws-1').single.kind, AgentInputKind.question);
      async.elapse(const Duration(hours: 72, minutes: 1));
      expect(w.service.pendingIn('ws-1'), isEmpty);
      w.dispose();
    });
  });

  test('a run with no expiry waits in full for each request', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w.run('run-1', reason: WakeReason.schedule);
      bool? first;
      w.approval().then((v) => first = v);
      w.registry.respond(w.registry.snapshot.single.id, approved: true);
      async.flushMicrotasks();
      expect(first, isTrue);
      bool? second;
      w.approval().then((v) => second = v);
      expect(w.registry.snapshot, hasLength(1));
      async.elapse(const Duration(hours: 71, minutes: 59));
      expect(second, isNull);
      async.elapse(const Duration(minutes: 2));
      expect(second, isFalse);
      w.dispose();
    });
  });

  test('nothing expires during a shutdown', () {
    fakeAsync((async) {
      final w = _World(async)..start();
      w
        ..run('run-1')
        ..question('q-1', 'run-1');
      w.stopping = true;
      async.elapse(const Duration(hours: 25));
      expect(w.released, isEmpty);
      w.dispose();
    });
  });
}

/// The folder decisions, in memory.
class _Grants implements SandboxExecGrantRepository {
  final rows = <SandboxExecGrant>[];

  @override
  Future<List<SandboxExecGrant>> grants(String workspaceId) async => [
    for (final g in rows)
      if (g.workspaceId == workspaceId) g,
  ];

  @override
  Future<SandboxExecGrantPage> searchGrants(
    String workspaceId, {
    String? query,
    required int limit,
    int offset = 0,
  }) async => (grants: await grants(workspaceId), total: rows.length);

  @override
  Stream<List<SandboxExecGrant>> watchGrants(String workspaceId) =>
      Stream.fromFuture(grants(workspaceId));

  @override
  Future<SandboxExecGrant?> decisionFor(String workspaceId, String path) async {
    for (final g in await grants(workspaceId)) {
      if (g.covers(path)) {
        return g;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(SandboxExecGrant grant) async => rows.add(grant);

  @override
  Future<void> revoke(String workspaceId, String id) async =>
      rows.removeWhere((g) => g.id == id);
}
