import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/peer_ask_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_harness/context.dart' show newWakeDataNonce;
import 'package:cc_harness/loop.dart' show WouldStop, WouldStopContinue;
import 'package:cc_harness/messages.dart' show HarnessMessageOrigin;
import 'package:cc_infra/src/dispatch/peer_wakes.dart';
import 'package:cc_infra/src/dispatch/server_turn_hooks.dart'
    show ServerWouldStop;
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:uuid/uuid.dart';

export 'package:cc_infra/src/dispatch/peer_wakes.dart';

/// Whether [runId] (of [agentId], in [conversationId]) set a wake with
/// `wake_me` that is still pending: an active rule it created. The
/// promise check of A3.3 reads it.
typedef PeerRunSetWake =
    Future<bool> Function(
      String workspaceId, {
      required String conversationId,
      required String agentId,
      required String runId,
    });

/// [PeerRunSetWake] over the wake rules: an active rule the run created.
PeerRunSetWake peerRunSetWakeFrom(WakeRuleRepository rules) =>
    (
      workspaceId, {
      required conversationId,
      required agentId,
      required runId,
    }) async {
      final created = await rules.listCreatedByRun(
        workspaceId,
        conversationId: conversationId,
        agentId: agentId,
        runId: runId,
      );
      return created.any((rule) => rule.status == WakeRuleStatus.active);
    };

/// A refusal of an ask, with the `data.kind` the client and the model read.
class PeerAskRefusal {
  /// Creates a refusal.
  const PeerAskRefusal(this.kind, this.message, {this.askId});

  /// The `data.kind` (`PeerAskRefusals`).
  final String kind;

  /// What the caller reads.
  final String message;

  /// The pending ask a duplicate repeats.
  final String? askId;
}

/// What an ask came to, for the tool that made it.
sealed class PeerAskResult {
  const PeerAskResult();
}

/// The ask was refused before its row was written (the caller may have
/// posted the question already; nobody is woken for it).
final class PeerAskRefused extends PeerAskResult {
  /// Creates the result.
  const PeerAskRefused(this.refusal);

  /// Why.
  final PeerAskRefusal refusal;
}

/// The ask settled inside the call: the answer (or the failure) is inline
/// and nobody is woken.
final class PeerAskSettledInline extends PeerAskResult {
  /// Creates the result.
  const PeerAskSettledInline(
    this.ask, {
    required this.status,
    this.reply,
    this.error,
  });

  /// The ask as it was made.
  final PeerAsk ask;

  /// `answered`, `failed`, `expired` or `cancelled`.
  final PeerAskStatus status;

  /// The recipient's final message, for `answered`.
  final String? reply;

  /// Why it failed (`PeerAskErrors`), for `failed`.
  final String? error;
}

/// The ask is pending: the asker is woken when it settles.
final class PeerAskPending extends PeerAskResult {
  /// Creates the result.
  const PeerAskPending(
    this.ask, {
    required this.why,
    this.receipt,
    this.requestKind,
  });

  /// The ask.
  final PeerAsk ask;

  /// `background`, `timeout`, `blocked_on_person` or `queued_behind_run`.
  final String why;

  /// What the question's delivery came to.
  final WakeReceipt? receipt;

  /// For `blocked_on_person`: what the recipient waits for.
  final String? requestKind;
}

/// One ask to make ([PeerAskService.ask]).
class PeerAskRequest {
  /// Creates a request. The question is already posted
  /// ([questionMessageId]) in the recipient's conversation.
  const PeerAskRequest({
    required this.workspaceId,
    required this.kind,
    required this.mode,
    required this.askerAgentId,
    required this.askerName,
    required this.askerConversationId,
    required this.recipientAgentId,
    required this.recipientSpaceId,
    required this.recipientConversationId,
    required this.questionMessageId,
    required this.question,
    required this.chain,
    this.askerRunId,
    this.payload,
    this.wait,
  });

  /// The workspace.
  final String workspaceId;

  /// `ask`, `consult` or `review`.
  final PeerAskKind kind;

  /// `wait` or `background`.
  final PeerAskMode mode;

  /// Who asks.
  final String askerAgentId;

  /// The asker's display name.
  final String askerName;

  /// The asker's run (attested), when it has one.
  final String? askerRunId;

  /// The conversation the reply wakes the asker in.
  final String askerConversationId;

  /// Who is asked.
  final String recipientAgentId;

  /// Where the question was posted.
  final String recipientSpaceId;

  /// See [recipientSpaceId].
  final String recipientConversationId;

  /// The posted question.
  final String questionMessageId;

  /// The question's text (the duplicate hash and the stall reminder).
  final String question;

  /// What the recipient's wake carries, when not the question itself (a
  /// consult's brief).
  final String? payload;

  /// The new ask's chain: the asker's chain plus the asker.
  final List<String> chain;

  /// How long a blocking ask waits; null for none (`background`).
  final Duration? wait;
}

/// The outcome a blocking ask's waiter is completed with.
sealed class _WaitOutcome {
  const _WaitOutcome();
}

final class _Settled extends _WaitOutcome {
  const _Settled(this.status, {this.reply, this.error});
  final PeerAskStatus status;
  final String? reply;
  final String? error;
}

final class _Blocked extends _WaitOutcome {
  const _Blocked(this.kind);
  final String kind;
}

final class _TimedOut extends _WaitOutcome {
  const _TimedOut();
}

/// What a settled run means for one ask.
sealed class _Verdict {
  const _Verdict();
}

final class _Answer extends _Verdict {
  const _Answer(this.text);
  final String text;
}

final class _Fail extends _Verdict {
  const _Fail(this.error, {this.detail});
  final String error;
  final String? detail;
}

final class _Promise extends _Verdict {
  const _Promise(this.text);
  final String text;
}

final class _Parked extends _Verdict {
  const _Parked(this.until);
  final DateTime until;
}

/// Durable peer asks (plan section 10, D20 as amended): `ask_agent`,
/// `consult_agent` and `request_peer_review` write a [PeerAsk] row before
/// anything is dispatched, deliver the question as a `peerMessage` wake,
/// and settle the row when the recipient's run settles. The settling
/// notice (answered, failed, expired) reaches the asker exactly once: inline
/// when a blocking call is still waiting, otherwise as one `peerReply` wake
/// in the asker's own conversation. An interim notice (`promised`,
/// `blocked_on_person`, `parked_at_limit`) is at most one per kind per ask,
/// never settles it, and is dropped if the ask settles first.
///
/// Every terminal path goes through [_settle]: the conditional
/// `PeerAskRepository.settle` decides the one winner.
class PeerAskService {
  /// Creates the service. It subscribes to [AgentRunSettled] and
  /// [AgentAwaitingInput] on [eventBus] at once; [start] adds the sweep.
  PeerAskService({
    required this._asks,
    required this._wakes,
    required this._runLogs,
    required this._messages,
    required this._agents,
    required this._conversations,
    required this._runSetWake,
    required this._queue,
    DomainEventBus? eventBus,
    this._clock = DateTime.now,
    String Function()? newId,
  }) : _newId = newId ?? _uuid.v4 {
    if (eventBus != null) {
      _subs
        ..add(
          eventBus.on<AgentRunSettled>().listen(
            (event) =>
                unawaited(_guarded('run settled', () => onRunSettled(event))),
          ),
        )
        ..add(
          eventBus.on<AgentAwaitingInput>().listen(
            (event) => unawaited(
              _guarded('awaiting input', () => onAwaitingInput(event)),
            ),
          ),
        );
    }
  }

  final PeerAskRepository _asks;
  final WakeRepository _wakes;
  final AgentRunLogRepository _runLogs;
  final MessagingRepository _messages;
  final AgentRepository _agents;
  final ConversationRepository _conversations;
  final PeerRunSetWake _runSetWake;
  final WakeQueueService? Function() _queue;
  final DateTime Function() _clock;
  final String Function() _newId;
  final List<StreamSubscription<Object>> _subs = [];
  Timer? _sweepTimer;
  bool _attached = false;

  static const _uuid = Uuid();

  /// How often the sweep runs after [start].
  static const Duration sweepEvery = Duration(minutes: 5);

  /// A dispatched run that ended at least this long ago, with its ask still
  /// pending, is reconciled by the sweep (its settlement was missed).
  static const Duration missedSettleAfter = Duration(minutes: 1);

  /// Blocking callers waiting on an ask, by ask id. Removing an entry is
  /// claiming it: whoever removes it completes it.
  final Map<String, Completer<_WaitOutcome>> _waiters = {};

  /// Runs that already read the long `ask_agent` reference (A6).
  final Set<String> _referenced = {};

  /// The asks this service writes (the `peerAsks.*` ops read them).
  PeerAskRepository get repository => _asks;

  /// Whether the live run `runId` (in `conversationId`) is read-only: a
  /// review run, which may not wake anyone. Set by the server wiring from
  /// the live sessions; null reads every run as writable.
  bool Function(String? conversationId, String runId)? readOnlyRunOf;

  /// See [readOnlyRunOf].
  bool isReadOnlyRun(String? conversationId, String runId) =>
      readOnlyRunOf?.call(conversationId, runId) ?? false;

  /// Hooks the queue: a guard that drops an interim notice the ask outran,
  /// and a settled handler that records which run took a question and fails
  /// an ask whose question was never delivered. Idempotent.
  void attachQueue(WakeQueueService queue) {
    if (_attached) {
      return;
    }
    _attached = true;
    queue
      ..registerGuard(_InterimGuard(this))
      ..registerSettledHandler(onWakeSettled);
  }

  /// Runs the sweep now (boot) and every [sweepEvery].
  Future<void> start() async {
    final queue = _queue();
    if (queue != null) {
      attachQueue(queue);
    }
    await sweep();
    _sweepTimer ??= Timer.periodic(sweepEvery, (_) => unawaited(sweep()));
  }

  /// Stops listening and sweeping.
  Future<void> stop() async {
    _sweepTimer?.cancel();
    _sweepTimer = null;
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }

  // ---------------------------------------------------------------------------
  // Chains and refusals
  // ---------------------------------------------------------------------------

  /// The agents above [agentId] (plan section 10, "Guards read rows"): the
  /// chains of the wakes its run [runId] took and of the pending asks that
  /// run (or this [conversationId]) answers make its lineage; every pending
  /// ask to [agentId], anywhere, names an agent that waits on it.
  Future<PeerChain> chainOf(
    String workspaceId,
    String agentId, {
    String? runId,
    String? conversationId,
  }) async {
    final lines = <List<String>>[];
    final waiting = <String>{};
    if (runId != null) {
      final run = await _runLogs.getById(workspaceId, runId);
      if (run != null && run.agentId == agentId) {
        for (final wakeId in run.wakeIds) {
          final wake = await _wakes.getById(workspaceId, wakeId);
          if (wake != null && wake.chain.isNotEmpty) {
            lines.add([
              for (final a in wake.chain)
                if (a != agentId) a,
            ]);
          }
        }
      }
    }
    for (final ask in await _asks.listPending(
      workspaceId,
      recipientAgentId: agentId,
    )) {
      waiting
        ..addAll(ask.chain)
        ..add(ask.askerAgentId);
      final answering =
          (runId != null && ask.dispatchedRunId == runId) ||
          (conversationId != null &&
              ask.recipientConversationId == conversationId);
      if (answering) {
        lines.add([
          for (final a in ask.chain)
            if (a != agentId) a,
          if (ask.chain.isEmpty || ask.chain.last != ask.askerAgentId)
            ask.askerAgentId,
        ]);
      }
    }
    var lineage = const <String>[];
    for (final line in lines) {
      if (line.length > lineage.length) {
        lineage = line;
      }
    }
    waiting.remove(agentId);
    return PeerChain(lineage: lineage, waiting: waiting);
  }

  /// The refusal of an ask from [askerAgentId] to [recipientAgentId], or
  /// null: the asker's conversation is this workspace's, the ask closes no
  /// loop and is not too deep ([chain]), it does not repeat a pending
  /// question, and neither side holds too many pending asks.
  Future<PeerAskRefusal?> refusalFor({
    required String workspaceId,
    required String askerAgentId,
    required String? askerConversationId,
    required String recipientAgentId,
    required String question,
    required PeerChain chain,
  }) async {
    if (askerConversationId == null ||
        await _conversationSpace(workspaceId, askerConversationId) == null) {
      return const PeerAskRefusal(
        PeerAskRefusals.noConversation,
        'An ask needs the conversation of the run that asks, so the answer '
        'can wake it there. Call it from an agent run.',
      );
    }
    if (chain.wouldCycle(recipientAgentId)) {
      return PeerAskRefusal(
        PeerAskRefusals.cycle,
        'Delegation refused: cycle detected '
        '(${[...chain.lineage, askerAgentId, recipientAgentId].join(' → ')}). '
        'That agent is already waiting on you; answer in your turn instead.',
      );
    }
    if (chain.depth + 1 > PeerAskLimits.maxDepth) {
      return PeerAskRefusal(
        PeerAskRefusals.depth,
        'Delegation refused: chain depth ${chain.depth + 1} exceeds the cap '
        'of ${PeerAskLimits.maxDepth}.',
      );
    }
    // A first look, so a refused question is not posted; [ask] holds the
    // same limits in one transaction with its insert.
    final now = _clock();
    final duplicate = await _asks.findPendingDuplicate(
      workspaceId,
      askerAgentId: askerAgentId,
      recipientAgentId: recipientAgentId,
      questionHash: peerQuestionHash(question),
      since: now.subtract(PeerAskLimits.duplicateWindow),
    );
    if (duplicate != null) {
      return _limitRefusal(
        PeerAskLimitHit(PeerAskLimit.duplicate, duplicateAskId: duplicate.id),
      );
    }
    if (await _asks.countPending(workspaceId, askerAgentId: askerAgentId) >=
        PeerAskLimits.maxPendingPerAsker) {
      return _limitRefusal(PeerAskLimitHit(PeerAskLimit.asker));
    }
    if (await _asks.countPending(
          workspaceId,
          recipientAgentId: recipientAgentId,
        ) >=
        PeerAskLimits.maxPendingPerRecipient) {
      return _limitRefusal(PeerAskLimitHit(PeerAskLimit.recipient));
    }
    return null;
  }

  static PeerAskRefusal _limitRefusal(PeerAskLimitHit hit) =>
      switch (hit.limit) {
        PeerAskLimit.duplicate => PeerAskRefusal(
          PeerAskRefusals.duplicate,
          'You asked this agent the same question less than 10 minutes ago '
          '(ask ${hit.duplicateAskId}); it is still pending and its answer '
          'wakes you.',
          askId: hit.duplicateAskId,
        ),
        PeerAskLimit.asker => const PeerAskRefusal(
          PeerAskRefusals.limitReached,
          'You have 10 asks pending. Wait for their answers before asking '
          'more.',
        ),
        PeerAskLimit.recipient => const PeerAskRefusal(
          PeerAskRefusals.limitReached,
          'That agent already has 20 asks pending. Ask later or ask another '
          'agent.',
        ),
      };

  /// The longer `ask_agent` reference, once per run (A6): the first call in
  /// [runId] gets it, later calls get null.
  String? referenceOnce(String? runId) {
    if (runId == null || _referenced.add(runId)) {
      return askAgentReference;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Asking and plain messages
  // ---------------------------------------------------------------------------

  /// Makes the ask [request] describes: writes its row, delivers the
  /// question, and for a blocking ask waits up to [PeerAskRequest.wait].
  /// The caller ran [refusalFor] first and posted the question; the limits
  /// are held again, with the insert, so parallel asks cannot pass them.
  Future<PeerAskResult> ask(PeerAskRequest request) async {
    final ws = request.workspaceId;
    final askerSpaceId = await _conversationSpace(
      ws,
      request.askerConversationId,
    );
    if (askerSpaceId == null) {
      throw WorkspaceMismatchException(
        'Conversation ${request.askerConversationId} is not in workspace $ws',
      );
    }
    final askerRun = request.askerRunId == null
        ? null
        : await _runLogs.getById(ws, request.askerRunId!);
    final now = _clock();
    final ask = PeerAsk(
      id: _newId(),
      workspaceId: ws,
      kind: request.kind,
      mode: request.mode,
      askerAgentId: request.askerAgentId,
      askerRunId: askerRun?.id,
      askerConversationId: request.askerConversationId,
      askerSpaceId: askerSpaceId,
      recipientAgentId: request.recipientAgentId,
      recipientConversationId: request.recipientConversationId,
      recipientSpaceId: request.recipientSpaceId,
      questionMessageId: request.questionMessageId,
      questionHash: peerQuestionHash(request.question),
      chain: request.chain,
      // The reply continues the asker's run, for whoever that run acts for:
      // read from its row, never from an argument (null for a bot run).
      requestedByUserId: askerRun?.agentId == request.askerAgentId
          ? askerRun?.requestedByUserId
          : null,
      createdAt: now,
      expiresAt: now.add(PeerAskLimits.expiry),
    );
    final hit = await _asks.insertWithinLimits(
      ask,
      limits: PeerAskInsertLimits(
        duplicateSince: now.subtract(PeerAskLimits.duplicateWindow),
        perAsker: PeerAskLimits.maxPendingPerAsker,
        perRecipient: PeerAskLimits.maxPendingPerRecipient,
      ),
    );
    if (hit != null) {
      // Another ask got there first (the caller's [refusalFor] ran before
      // it was written). The question is posted but nobody is woken.
      return PeerAskRefused(_limitRefusal(hit));
    }
    // The waiter exists before the question can be answered, and for a
    // background ask while it is delivered: a delivery refused at once is
    // then the call's answer rather than a wake.
    final waiter = Completer<_WaitOutcome>();
    _waiters[ask.id] = waiter;
    WakeReceipt receipt;
    try {
      receipt = await _deliverQuestion(request, ask);
    } on Object catch (e) {
      // The question never reached the queue: the ask fails now, through
      // the one settlement path (the waiter hears it; nobody is woken).
      await _settle(
        ask,
        PeerAskStatus.failed,
        error: PeerAskErrors.notDelivered,
        errorDetail: '$e',
      );
      receipt = const WakeSkipped(PeerAskErrors.notDelivered);
    }
    if (receipt case WakeStarted(:final runId)) {
      await _asks.setDispatched(ws, id: ask.id, dispatchedRunId: runId);
    }
    final wait = request.mode == PeerAskMode.wait ? request.wait : null;
    final outcome = waiter.isCompleted || wait == null
        ? (_waiters.remove(ask.id) == null ? await waiter.future : null)
        : await _awaitWaiter(ask.id, waiter, wait);
    return switch (outcome) {
      null => PeerAskPending(
        ask,
        why: receipt is WakeWaiting ? 'queued_behind_run' : 'background',
        receipt: receipt,
      ),
      _TimedOut() => PeerAskPending(ask, why: 'timeout', receipt: receipt),
      _Blocked(:final kind) => PeerAskPending(
        ask,
        why: PeerReplyInterim.blockedOnPerson,
        receipt: receipt,
        requestKind: kind,
      ),
      _Settled(:final status, :final reply, :final error) =>
        PeerAskSettledInline(ask, status: status, reply: reply, error: error),
    };
  }

  static String _questionWakeId(String askId) => 'ask-$askId-message';

  Future<WakeReceipt> _deliverQuestion(PeerAskRequest request, PeerAsk ask) =>
      deliver(
        wakeId: _questionWakeId(ask.id),
        workspaceId: request.workspaceId,
        spaceId: request.recipientSpaceId,
        conversationId: request.recipientConversationId,
        recipientAgentId: request.recipientAgentId,
        payload: request.payload ?? request.question,
        messageId: request.questionMessageId,
        chain: request.chain,
        senderAgentId: request.askerAgentId,
        senderName: request.askerName,
        senderRunId: ask.askerRunId,
        senderConversationId: request.askerConversationId,
        ask: ask,
      );

  Future<_WaitOutcome> _awaitWaiter(
    String askId,
    Completer<_WaitOutcome> waiter,
    Duration wait,
  ) async {
    final timer = Timer(wait, () {
      if (identical(_waiters[askId], waiter)) {
        _waiters.remove(askId);
        waiter.complete(const _TimedOut());
      }
    });
    try {
      return await waiter.future;
    } finally {
      timer.cancel();
    }
  }

  /// Delivers a `peerMessage` wake for a message already posted in the
  /// recipient's conversation (`send_to_agent`, and an ask's question).
  /// [chain] is the sender's chain plus the sender. No requester.
  Future<WakeReceipt> deliver({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String recipientAgentId,
    required String payload,
    required String messageId,
    required List<String> chain,
    String? wakeId,
    String? senderAgentId,
    String? senderName,
    String? senderRunId,
    String? senderConversationId,
    PeerAsk? ask,
  }) async {
    final queue = _queue();
    if (queue == null) {
      return const WakeSkipped('no_wake_queue');
    }
    attachQueue(queue);
    final wake = peerMessageWake(
      id: wakeId ?? 'peer-$messageId',
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      recipientAgentId: recipientAgentId,
      payload: payload,
      messageId: messageId,
      chain: chain,
      now: _clock(),
      senderAgentId: senderAgentId,
      senderName: senderName,
      senderRunId: senderRunId,
      senderConversationId: senderConversationId,
      ask: ask,
    );
    return queue.enqueueAndDeliver(wake);
  }

  // ---------------------------------------------------------------------------
  // Settlement
  // ---------------------------------------------------------------------------

  /// A run settled: every pending ask it answers settles, is promised, or
  /// stays pending at a usage limit. A server stop changes nothing (the
  /// queue reopens the question's wake).
  Future<void> onRunSettled(AgentRunSettled event) async {
    if (event.endReason == RunEndReason.serverStopped) {
      return;
    }
    final ws = event.workspaceId;
    for (final ask in await _asksAnsweredBy(
      ws,
      runId: event.runId,
      agentId: event.agentId,
      conversationId: event.conversationId,
      wakeIds: event.wakeIds,
    )) {
      final verdict = await _verdict(
        ask,
        workspaceId: ws,
        runId: event.runId,
        endReason: event.endReason,
        limitResetsAt: event.limitResetsAt,
      );
      await _apply(ask, verdict, recipientRunId: event.runId);
    }
  }

  /// The pending asks run [runId] answers: the ones it was dispatched for,
  /// the ones whose question it took (from its lanes too), and the ones of
  /// its agent in its conversation whose earlier run ended without settling
  /// them (a promise, a usage-limit park).
  Future<List<PeerAsk>> _asksAnsweredBy(
    String ws, {
    required String runId,
    required String agentId,
    required String? conversationId,
    List<String>? wakeIds,
  }) async {
    final found = <String, PeerAsk>{};
    void take(PeerAsk? ask) {
      if (ask != null && ask.isPending && ask.recipientAgentId == agentId) {
        found[ask.id] = ask;
      }
    }

    take(await _asks.getByDispatchedRun(ws, runId));
    final ids =
        wakeIds ?? (await _runLogs.getById(ws, runId))?.wakeIds ?? const [];
    for (final wakeId in ids) {
      final wake = await _wakes.getById(ws, wakeId);
      final askId = wake?.detail.askId;
      if (wake != null &&
          (wake.reason == WakeReason.peerMessage ||
              wake.reason == WakeReason.limitReset) &&
          askId != null) {
        take(await _asks.getById(ws, askId));
      }
    }
    if (conversationId != null) {
      for (final ask in await _asks.listPendingForRecipientConversation(
        ws,
        recipientAgentId: agentId,
        recipientConversationId: conversationId,
      )) {
        final earlier = ask.dispatchedRunId;
        if (earlier == null || earlier == runId) {
          continue;
        }
        if (ask.promisedAt != null || await _runEnded(ws, earlier)) {
          take(ask);
        }
      }
    }
    return found.values.toList();
  }

  Future<bool> _runEnded(String ws, String runId) async {
    final run = await _runLogs.getById(ws, runId);
    return run != null &&
        (run.status == RunStatus.completed || run.status == RunStatus.error);
  }

  Future<_Verdict?> _verdict(
    PeerAsk ask, {
    required String workspaceId,
    required String runId,
    required RunEndReason? endReason,
    DateTime? limitResetsAt,
  }) async {
    switch (endReason) {
      case null || RunEndReason.serverStopped:
        return null;
      case RunEndReason.completed:
        final message = await _messages.getMessageById(workspaceId, runId);
        final text = message == null ? '' : finalAnswerOf(message);
        if (text.isEmpty) {
          return const _Fail(PeerAskErrors.noOutput);
        }
        final conversation = ask.recipientConversationId;
        if (ask.promisedAt == null &&
            text.length < PeerAskLimits.promiseMaxChars &&
            conversation != null &&
            await _runSetWake(
              workspaceId,
              conversationId: conversation,
              agentId: ask.recipientAgentId,
              runId: runId,
            )) {
          return _Promise(text);
        }
        return _Answer(text);
      case RunEndReason.usageLimit:
        // Parked only when the run resumes before the ask expires; else the
        // ask fails now, with the limit as its reason.
        final reset = LimitPark.honouredReset(limitResetsAt, _clock());
        return reset == null ||
                !LimitPark.resumeAt(reset).isBefore(ask.expiresAt)
            ? const _Fail(PeerAskErrors.usageLimit)
            : _Parked(reset);
      case RunEndReason.error:
        final run = await _runLogs.getById(workspaceId, runId);
        final detail = (run?.summary ?? run?.errorCode)?.trim();
        return _Fail(
          PeerAskErrors.runFailed,
          detail: detail == null || detail.isEmpty ? null : detail,
        );
      case RunEndReason.stoppedByUser:
        return const _Fail(PeerAskErrors.stoppedByPerson);
      case RunEndReason.budget:
        return const _Fail(PeerAskErrors.budget);
      case RunEndReason.silence:
        return const _Fail(PeerAskErrors.silence);
    }
  }

  Future<void> _apply(
    PeerAsk ask,
    _Verdict? verdict, {
    required String recipientRunId,
  }) async {
    switch (verdict) {
      case null:
        return;
      case _Answer(:final text):
        await _settle(
          ask,
          PeerAskStatus.answered,
          reply: text,
          replyMessageId: recipientRunId,
          recipientRunId: recipientRunId,
        );
      case _Fail(:final error, :final detail):
        await _settle(
          ask,
          PeerAskStatus.failed,
          error: error,
          errorDetail: detail,
          recipientRunId: recipientRunId,
        );
      case _Promise(:final text):
        if (await _asks.markPromised(
          ask.workspaceId,
          id: ask.id,
          now: _clock(),
        )) {
          await _interim(
            ask,
            PeerReplyInterim.promised,
            payload: text,
            recipientRunId: recipientRunId,
          );
        }
      case _Parked(:final until):
        if (!await _parkAtLimit(ask, runId: recipientRunId, reset: until)) {
          await _settle(
            ask,
            PeerAskStatus.failed,
            error: PeerAskErrors.usageLimit,
            recipientRunId: recipientRunId,
          );
          return;
        }
        await _interim(
          ask,
          PeerReplyInterim.parkedAtLimit,
          recipientRunId: recipientRunId,
          fields: {
            WakeFields.resetsAt: until.toUtc().toIso8601String(),
            WakeFields.resumesAt: LimitPark.resumeAt(until).toIso8601String(),
          },
        );
    }
  }

  /// Parks the recipient's run [runId], which reached its provider's usage
  /// limit, through the limit park: a `limitReset` wake under the park's key
  /// ([LimitPark.dedupKey]), due at [LimitPark.resumeAt], carries the
  /// question to a run after [reset], and that run answers the still-open
  /// ask. A settlement of the ask cancels the wake (it carries the ask's id).
  /// True when the run is parked, by this wake or by another park of the run
  /// under the same key.
  Future<bool> _parkAtLimit(
    PeerAsk ask, {
    required String runId,
    required DateTime reset,
  }) async {
    final queue = _queue();
    final space = ask.recipientSpaceId;
    final conversation = ask.recipientConversationId;
    if (queue == null ||
        queue.stopping ||
        space == null ||
        conversation == null) {
      return false;
    }
    final ws = ask.workspaceId;
    final question = await _wakes.getById(ws, _questionWakeId(ask.id));
    if (question == null) {
      return false;
    }
    final run = await _runLogs.getById(ws, runId);
    final key = LimitPark.dedupKey(runId);
    final wake = Wake(
      id: 'ask-${ask.id}-limit-$runId',
      workspaceId: ws,
      spaceId: space,
      conversationId: conversation,
      agentId: ask.recipientAgentId,
      reason: WakeReason.limitReset,
      lane: question.lane,
      payload: question.payload,
      detail: WakeDetail(
        askId: ask.id,
        sourceRunId: runId,
        messageId: question.detail.messageId,
        fields: LimitPark.wakeFields(
          provider: LimitPark.providerLabel(
            adapter: run?.adapter,
            modelId: run?.modelId,
          ),
          reset: reset,
        ),
      ),
      runOptions: question.runOptions,
      dedupKey: key,
      notBefore: LimitPark.resumeAt(reset),
      expiresAt: ask.expiresAt,
      // Whoever the parked run acted for: a bot run for one the question
      // started, the person's when it was pushed into their run.
      requestedByUserId: run?.requestedByUserId,
      chain: question.chain,
      expectsReply: true,
      createdAt: _clock(),
    );
    try {
      if (await queue.enqueue(wake)) {
        return true;
      }
    } on Object catch (e) {
      CcInfraLog.warning('peer asks: ${ask.id} not parked at the limit: $e');
      return false;
    }
    final existing = await _wakes.getByDedupKey(ws, key);
    return existing != null &&
        existing.reason == WakeReason.limitReset &&
        !existing.state.isSettled;
  }

  /// The one settlement path: the conditional update picks the winner; a
  /// waiting caller gets the outcome inline, otherwise the asker gets one
  /// `peerReply` wake (none for a cancel).
  Future<bool> _settle(
    PeerAsk ask,
    PeerAskStatus status, {
    String? reply,
    String? replyMessageId,
    String? error,
    String? errorDetail,
    String? recipientRunId,
  }) async {
    final ws = ask.workspaceId;
    // Claimed synchronously: a timeout that fires now finds no waiter.
    final waiter = _waiters.remove(ask.id);
    final stored = error == null
        ? null
        : _cut(errorDetail == null ? error : '$error: $errorDetail');
    final won = await _asks.settle(
      ws,
      id: ask.id,
      status: status,
      replyMessageId: replyMessageId,
      error: stored,
      replyInline: waiter != null,
      now: _clock(),
    );
    if (!won) {
      if (waiter != null) {
        final row = await _asks.getById(ws, ask.id);
        waiter.complete(_Settled(row?.status ?? status, error: row?.error));
      }
      return false;
    }
    // Whatever of this ask still waits in the queue (the question, an
    // interim notice) goes; the settling notice is inserted after.
    final queue = _queue();
    if (queue != null) {
      try {
        await queue.cancelWhere(ws, askId: ask.id, reason: 'ask_settled');
      } on Object catch (e) {
        CcInfraLog.warning('peer asks: cancelling the wakes of ${ask.id}: $e');
      }
    }
    if (waiter != null) {
      waiter.complete(_Settled(status, reply: reply, error: error));
      return true;
    }
    if (status == PeerAskStatus.cancelled) {
      return true;
    }
    await _enqueue(
      peerReplyWake(
        ask: ask,
        status: status.wire,
        recipientName: await _nameOf(ws, ask.recipientAgentId),
        now: _clock(),
        payload: reply ?? '',
        recipientRunId: recipientRunId,
        replyMessageId: replyMessageId,
        fields: {
          WakeFields.error: ?error,
          if (errorDetail != null) WakeFields.errorDetail: _cut(errorDetail),
        },
      ),
    );
    return true;
  }

  /// One interim notice (`promised`, `blocked_on_person`, `parked_at_limit`)
  /// to the asker; its dedup key makes it one per kind per ask.
  Future<void> _interim(
    PeerAsk ask,
    String status, {
    String payload = '',
    String? recipientRunId,
    Map<String, Object?> fields = const {},
  }) async {
    await _enqueue(
      peerReplyWake(
        ask: ask,
        status: status,
        recipientName: await _nameOf(ask.workspaceId, ask.recipientAgentId),
        now: _clock(),
        payload: payload,
        recipientRunId: recipientRunId,
        fields: fields,
      ),
    );
  }

  Future<void> _enqueue(Wake wake) async {
    final queue = _queue();
    if (queue == null) {
      return;
    }
    try {
      await queue.enqueue(wake);
    } on Object catch (e) {
      CcInfraLog.warning('peer asks: could not wake ${wake.agentId}: $e');
    }
  }

  /// A wake settled: a question taken by a run records that run on its ask,
  /// and so does the limit park's wake (the resumed run answers now); a
  /// question never delivered fails its ask (the asker is woken with the
  /// reason), and a park that never resumed fails it on the usage limit,
  /// unless the ask already settled.
  Future<void> onWakeSettled(WakeSettlement settled) async {
    final wake = settled.wake;
    final askId = wake.detail.askId;
    final park = wake.reason == WakeReason.limitReset;
    if (park && askId == null) {
      await _otherParkEnded(settled);
      return;
    }
    if (askId == null || !(park || wake.reason == WakeReason.peerMessage)) {
      return;
    }
    final ws = wake.workspaceId;
    final ask = await _asks.getById(ws, askId);
    if (ask == null || !ask.isPending) {
      return;
    }
    switch (settled.state) {
      case WakeState.delivered:
        final runId = settled.runId;
        if (runId != null && (park || ask.dispatchedRunId == null)) {
          await _asks.setDispatched(ws, id: ask.id, dispatchedRunId: runId);
        }
      case WakeState.expired when !_clock().isBefore(ask.expiresAt):
        await _settle(ask, PeerAskStatus.expired);
      case WakeState.skipped || WakeState.expired || WakeState.cancelled:
        await _settle(
          ask,
          PeerAskStatus.failed,
          error: park ? PeerAskErrors.usageLimit : PeerAskErrors.notDelivered,
          errorDetail: settled.reason ?? settled.state.wire,
        );
      default:
        return;
    }
  }

  /// Another owner's park of an ask's dispatched run (a person's park won
  /// the run's `limit:<runId>` key) ended without running: the ask fails at
  /// once with the usage limit, and the asker is woken, instead of waiting
  /// for its expiry.
  Future<void> _otherParkEnded(WakeSettlement settled) async {
    final source = settled.wake.detail.sourceRunId;
    if (source == null ||
        settled.wake.dedupKey != LimitPark.dedupKey(source) ||
        !(settled.state == WakeState.cancelled ||
            settled.state == WakeState.expired ||
            settled.state == WakeState.skipped)) {
      return;
    }
    final ask = await _asks.getByDispatchedRun(
      settled.wake.workspaceId,
      source,
    );
    if (ask == null || !ask.isPending) {
      return;
    }
    await _settle(
      ask,
      PeerAskStatus.failed,
      error: PeerAskErrors.usageLimit,
      errorDetail: settled.reason ?? settled.state.wire,
    );
  }

  // ---------------------------------------------------------------------------
  // A person in the way (A5), a blank stop (A4), a cancel
  // ---------------------------------------------------------------------------

  /// The run answering an ask waits on a person: the asker hears it once
  /// (`blocked_on_person`), inline when it is still blocked in the call.
  Future<void> onAwaitingInput(AgentAwaitingInput event) async {
    final runId = event.runId;
    final agentId = event.agentId;
    if (runId == null || agentId == null) {
      return;
    }
    final ws = event.workspaceId;
    for (final ask in await _asksAnsweredBy(
      ws,
      runId: runId,
      agentId: agentId,
      conversationId: event.conversationId,
    )) {
      if (!await _asks.markBlockedNoticed(ws, id: ask.id, now: _clock())) {
        continue;
      }
      final waiter = _waiters.remove(ask.id);
      if (waiter != null) {
        waiter.complete(_Blocked(event.kind.name));
        continue;
      }
      await _interim(
        ask,
        PeerReplyInterim.blockedOnPerson,
        recipientRunId: runId,
        fields: {WakeFields.requestKind: event.kind.name},
      );
    }
  }

  /// The server's would-stop handler (A4): the [stallReminder] as a
  /// continuation tagged [HarnessMessageOrigin.peer], because it carries the
  /// asker's question, which a compaction must never pin as steering.
  Future<WouldStop?> onWouldStop(ServerWouldStop stop) async {
    final reminder = await stallReminder(
      workspaceId: stop.workspaceId,
      agentId: stop.agentId,
      conversationId: stop.conversationId,
      runId: stop.runId,
      lastAssistantText: stop.loop.lastAssistantText,
    );
    return reminder == null
        ? null
        : WouldStopContinue(reminder, origin: HarnessMessageOrigin.peer);
  }

  /// The reminder a run answering an ask reads when it would stop with a
  /// blank final message (A4), once per ask; null when nobody waits on it.
  Future<String?> stallReminder({
    required String workspaceId,
    required String agentId,
    required String? conversationId,
    required String runId,
    required String lastAssistantText,
  }) async {
    if (lastAssistantText.trim().isNotEmpty) {
      return null;
    }
    for (final ask in await _asksAnsweredBy(
      workspaceId,
      runId: runId,
      agentId: agentId,
      conversationId: conversationId,
    )) {
      if (!await _asks.markStallNoticed(
        workspaceId,
        id: ask.id,
        runId: runId,
      )) {
        continue;
      }
      final questionId = ask.questionMessageId;
      final question = questionId == null
          ? null
          : await _messages.getMessageById(workspaceId, questionId);
      return peerAskStallReminder(
        askerName: await _nameOf(workspaceId, ask.askerAgentId),
        question: question?.content ?? '',
        nonce: newWakeDataNonce(),
      );
    }
    return null;
  }

  /// Cancels a pending ask of [workspaceId] (a person's action): the asker
  /// is not woken, the recipient's run is not stopped, the question's wake
  /// is withdrawn if it still waits. False when it already settled. Throws
  /// [WorkspaceMismatchException] for an ask not in [workspaceId].
  Future<bool> cancel(String workspaceId, String askId) async {
    final ask = await _asks.getById(workspaceId, askId);
    if (ask == null || ask.workspaceId != workspaceId) {
      throw WorkspaceMismatchException(
        'Ask $askId is not in workspace $workspaceId',
      );
    }
    if (!ask.isPending) {
      return false;
    }
    return _settle(ask, PeerAskStatus.cancelled);
  }

  // ---------------------------------------------------------------------------
  // Sweep
  // ---------------------------------------------------------------------------

  /// Settles what nothing else will: asks past their expiry (`expired`, the
  /// asker woken), and asks whose dispatched run ended while nobody listened
  /// (the server was down, or its settlement was missed).
  Future<void> sweep() async {
    final List<String> workspaces;
    try {
      workspaces = await _asks.workspacesWithPendingAsks();
    } on Object catch (e) {
      CcInfraLog.warning('peer asks: sweep could not list workspaces: $e');
      return;
    }
    for (final ws in workspaces) {
      await _guarded('sweep $ws', () => _sweepWorkspace(ws));
    }
  }

  Future<void> _sweepWorkspace(String ws) async {
    final now = _clock();
    for (final ask in await _asks.listExpired(ws, now: now)) {
      await _settle(ask, PeerAskStatus.expired);
    }
    for (final ask in await _asks.listPending(ws)) {
      final runId = ask.dispatchedRunId;
      if (runId == null || ask.promisedAt != null) {
        continue;
      }
      final run = await _runLogs.getById(ws, runId);
      if (run == null || !_settledLongAgo(run, now)) {
        continue;
      }
      final reason = run.endReason;
      if (reason == null || reason == RunEndReason.serverStopped) {
        continue;
      }
      if (reason == RunEndReason.usageLimit) {
        // Parked (by the ask or the run's other park): the resumed run
        // answers. Missed with no park: the reset is gone, the ask fails.
        final park = await _wakes.getByDedupKey(ws, LimitPark.dedupKey(runId));
        if (park != null && !park.state.isSettled) {
          continue;
        }
      }
      await _apply(
        ask,
        await _verdict(ask, workspaceId: ws, runId: runId, endReason: reason),
        recipientRunId: runId,
      );
    }
  }

  bool _settledLongAgo(AgentRunLog run, DateTime now) {
    final ended = run.completedAt;
    return (run.status == RunStatus.completed ||
            run.status == RunStatus.error) &&
        ended != null &&
        !ended.add(missedSettleAfter).isAfter(now);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Whether [askId]'s interim notice is still worth delivering.
  Future<bool> _stillPending(String workspaceId, String askId) async =>
      (await _asks.getById(workspaceId, askId))?.isPending ?? false;

  Future<String?> _conversationSpace(String ws, String conversationId) async {
    final conversation = await _conversations.getById(
      workspaceId: ws,
      conversationId: conversationId,
    );
    if (conversation == null ||
        (conversation.workspaceId != null && conversation.workspaceId != ws)) {
      return null;
    }
    return conversation.spaceId;
  }

  Future<String> _nameOf(String ws, String agentId) async =>
      (await _agents.getById(ws, agentId))?.name ?? agentId;

  static String _cut(String text) => text.length <= PeerAsk.maxErrorLength
      ? text
      : text.substring(0, PeerAsk.maxErrorLength);

  Future<void> _guarded(String what, Future<void> Function() body) async {
    try {
      await body();
    } on Object catch (e, st) {
      CcInfraLog.error('peer asks: $what failed: $e', e, st);
    }
  }
}

/// Drops an interim `peerReply` notice whose ask settled before it was
/// delivered (the amended D20), and a limit park's wake whose ask settled
/// before the run resumed.
class _InterimGuard implements WakeAdmissionGuard {
  _InterimGuard(this._service);

  final PeerAskService _service;

  @override
  Future<WakeAdmission> admit(Wake wake, {required DateTime now}) async {
    final askId = wake.detail.askId;
    final interim =
        wake.reason == WakeReason.peerReply &&
        PeerReplyInterim.all.contains(wake.detail.status);
    // A limit park's wake restarts nothing once its ask settled.
    final park = wake.reason == WakeReason.limitReset;
    if (askId == null || !(interim || park)) {
      return const WakeAdmission.admit();
    }
    return await _service._stillPending(wake.workspaceId, askId)
        ? const WakeAdmission.admit()
        : const WakeAdmission.skip('ask_settled');
  }
}
