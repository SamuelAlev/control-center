part of 'wake_rule_service.dart';

/// One watched event as a rule sees it: what to match, how to check the
/// rule may see it, and what the wake says about it.
class _WatchEvent {
  _WatchEvent({
    required this.kind,
    required this.workspaceId,
    required this.matches,
    required this.visible,
    this.status,
    this.subject,
    this.item,
    this.exitCode,
    this.ticketId,
    this.pipelineRunId,
    this.details = const [],
  });

  final WakeEventKind kind;
  final String workspaceId;
  final bool Function(WakeRule rule) matches;
  final Future<bool> Function(WakeRule rule) visible;
  final String? status;
  final String? subject;
  final String? item;
  final int? exitCode;
  final String? ticketId;
  final String? pipelineRunId;

  /// Lines of the latest state (a check's link, a comment's preview, an
  /// error), carried in the payload after the note.
  final List<String> details;
}

/// A watch's events gathered while it waits to write one wake.
class _Gathered {
  _Gathered({required this.first, required this.latest});

  final DateTime first;
  _WatchEvent latest;
  int count = 1;
  Timer? timer;
}

/// The watch half of [WakeRuleService]: one subscription per event type,
/// matched against the workspace's active watches of its kind, debounced
/// into one wake per burst.
extension on WakeRuleService {
  void _subscribeWatches() {
    void on<T extends DomainEvent>(_WatchEvent? Function(T event) read) {
      _subs.add(
        _eventBus.on<T>().listen(
          _guarded<T>((event) async {
            final watched = read(event);
            if (watched != null) {
              await _watched(watched);
            }
          }),
        ),
      );
    }

    final access = _ports.watchAccess;
    String prSubject(PrWatchEvent e) =>
        '${e.repoOwner}/${e.repoName}#${e.prNumber}';
    // A watch that names a pull request hears only that one; one that names
    // none hears the space's own (the server decides which those are).
    bool prMatches(WakeRule rule, PrWatchEvent e) =>
        _pullRequestOf(rule)?.names(e.repoOwner, e.repoName, e.prNumber) ??
        true;
    Future<bool> Function(WakeRule) prWatched(PrWatchEvent e) =>
        (rule) => access.prWatched(
          workspaceId: rule.workspaceId,
          spaceId: rule.spaceId,
          userId: rule.requestedByUserId,
          target: _pullRequestOf(rule),
          repoOwner: e.repoOwner,
          repoName: e.repoName,
          number: e.prNumber,
          headRef: e.headRef,
        );

    on<PrWatchChecksSettled>(
      (e) => _WatchEvent(
        kind: WakeEventKind.prChecks,
        workspaceId: e.workspaceId,
        matches: (rule) => prMatches(rule, e),
        visible: prWatched(e),
        status: e.passing ? 'passing' : 'failing',
        subject: prSubject(e),
        item: e.failedChecks.isEmpty ? null : e.failedChecks.first,
        details: [
          'Pull request: ${e.prTitle}',
          if (!e.passing)
            e.failedChecks.isEmpty
                ? 'Failed checks: the forge named none'
                : 'Failed checks: ${e.failedChecks.join(', ')}',
          if (e.failedCheckUrl != null) 'Failing check: ${e.failedCheckUrl}',
        ],
      ),
    );
    on<PrWatchReviewActivity>(
      (e) => _WatchEvent(
        kind: WakeEventKind.prReview,
        workspaceId: e.workspaceId,
        matches: (rule) => prMatches(rule, e),
        visible: prWatched(e),
        status: e.decisionChanged
            ? switch (e.decision) {
                'changesRequested' => 'changes_requested',
                'reviewRequired' => 'review_required',
                final other => other,
              }
            : 'commented',
        subject: prSubject(e),
        details: [
          'Pull request: ${e.prTitle}',
          if (e.decisionChanged) 'Review decision: ${e.decision}',
          if (e.newComments > 0)
            'New comments: ${e.newComments} (unattributed)',
        ],
      ),
    );
    on<PrWatchClosed>(
      (e) => _WatchEvent(
        kind: WakeEventKind.prMerged,
        workspaceId: e.workspaceId,
        matches: (rule) => prMatches(rule, e),
        visible: prWatched(e),
        status: e.merged ? 'merged' : 'closed',
        subject: prSubject(e),
        details: [
          'Pull request: ${e.prTitle}',
          if (!e.merged) 'It was closed without merging.',
        ],
      ),
    );
    on<EnvironmentProcessExited>(
      (e) => _WatchEvent(
        kind: WakeEventKind.environment,
        workspaceId: e.workspaceId,
        matches: (rule) => rule.spaceId == e.spaceId,
        visible: (_) async => true,
        status: 'exited',
        subject: 'environment ${e.environmentId}',
        item: e.componentId,
        exitCode: e.exitCode,
      ),
    );
    on<EnvironmentReady>(
      (e) => _WatchEvent(
        kind: WakeEventKind.environment,
        workspaceId: e.workspaceId,
        matches: (rule) => rule.spaceId == e.spaceId,
        visible: (_) async => true,
        status: 'ready',
        subject: 'environment ${e.environmentId}',
        details: [if (e.url != null) 'URL: ${e.url}'],
      ),
    );
    _WatchEvent ticket(String ws, String id, String status, [String? error]) =>
        _WatchEvent(
          kind: WakeEventKind.ticket,
          workspaceId: ws,
          matches: (rule) => _targetOf(rule) == id,
          visible: (rule) => access.ticketWatchable(
            workspaceId: rule.workspaceId,
            agentId: rule.agentId,
            ticketId: id,
          ),
          status: status,
          subject: 'ticket $id',
          ticketId: id,
          details: [if (error != null) 'Error: $error'],
        );
    on<TicketCompleted>((e) => ticket(e.workspaceId, e.ticketId, 'completed'));
    on<TicketFailed>(
      (e) => ticket(e.workspaceId, e.ticketId, 'failed', e.errorMessage),
    );
    on<TicketCancelled>((e) => ticket(e.workspaceId, e.ticketId, 'cancelled'));
    _WatchEvent run(String ws, String id, String status, [String? error]) =>
        _WatchEvent(
          kind: WakeEventKind.pipelineRun,
          workspaceId: ws,
          matches: (rule) => _targetOf(rule) == id,
          visible: (rule) => access.pipelineRunWatchable(
            workspaceId: rule.workspaceId,
            spaceId: rule.spaceId,
            userId: rule.requestedByUserId,
            runId: id,
          ),
          status: status,
          subject: 'pipeline run $id',
          pipelineRunId: id,
          details: [if (error != null) 'Error: $error'],
        );
    on<PipelineRunCompleted>(
      (e) => run(e.workspaceId, e.pipelineRunId, 'completed'),
    );
    on<PipelineRunFailed>(
      (e) => run(e.workspaceId, e.pipelineRunId, 'failed', e.errorMessage),
    );
    on<PipelineRunCancelled>(
      (e) => run(e.workspaceId, e.pipelineRunId, 'cancelled'),
    );
  }

  static String? _targetOf(WakeRule rule) => switch (rule.trigger) {
    OnEvent(:final targetId) => targetId,
    _ => null,
  };

  static WakePullRequestRef? _pullRequestOf(WakeRule rule) =>
      switch (rule.trigger) {
        final OnEvent on => on.pullRequest,
        _ => null,
      };

  /// Matches [event] against the workspace's active watches of its kind:
  /// the target and the rule's right to see it. An event is never dropped
  /// because of timing: one that comes while a run of the agent is live is
  /// written as usual and waits in the queue until the run has ended
  /// ([_flushWatch] folds it into a wake still waiting). It would be dropped
  /// as the agent's own only if it named who caused it: a polled pull
  /// request names no reviewer or commenter, and an environment's events
  /// name no one who started, restarted or ran it, so none is.
  Future<void> _watched(_WatchEvent event) async {
    final ws = event.workspaceId;
    if (!await _ports.workspaceActive(ws)) {
      return;
    }
    for (final rule in await _rules.listActiveByEvent(ws, event.kind)) {
      if (rule.workspaceId != ws || !event.matches(rule)) {
        continue;
      }
      if (!await event.visible(rule)) {
        continue;
      }
      // While a run of the agent is live the wake is written at once: it
      // waits in the queue (a restart keeps it) and the next event of the
      // run is folded into it.
      _gather(
        rule,
        event,
        writeNow: await _ports.agentBusy(
          ws,
          rule.conversationId,
          rule.agentId,
        ),
      );
    }
  }

  /// Holds [event] for [rule]: the wake is written once events stop for
  /// [WakeRuleBounds.watchQuiet], and no later than
  /// [WakeRuleBounds.watchMaxDelay] after the first, with the latest state;
  /// at once when [writeNow] (the agent's run is live: the wake waits in
  /// the queue, which keeps it over a restart, and gathers the rest).
  void _gather(WakeRule rule, _WatchEvent event, {bool writeNow = false}) {
    final at0 = _clock().toUtc();
    final held = _gathered[rule.id];
    final gathered = held ?? _Gathered(first: at0, latest: event);
    if (held != null) {
      gathered
        ..latest = event
        ..count += 1;
    }
    _gathered[rule.id] = gathered;
    gathered.timer?.cancel();
    final quietAt = at0.add(WakeRuleBounds.watchQuiet);
    final latestAt = gathered.first.add(WakeRuleBounds.watchMaxDelay);
    final at = quietAt.isBefore(latestAt) ? quietAt : latestAt;
    final wait = at.difference(at0);
    final ws = rule.workspaceId;
    final id = rule.id;
    void flush() {
      final before = _watchWrites[id] ?? Future<void>.value();
      late final Future<void> write;
      write = before
          .then((_) => _flushWatch(ws, id))
          .catchError((Object e, StackTrace st) {
            CcInfraLog.error('WakeRuleService: watch $id', e, st);
          })
          .whenComplete(() {
            if (identical(_watchWrites[id], write)) {
              _watchWrites.remove(id);
            }
          });
      _watchWrites[id] = write;
    }
    if (writeNow) {
      gathered.timer = null;
      flush();
      return;
    }
    gathered.timer = _timerFactory(
      wait.isNegative ? Duration.zero : wait,
      flush,
    );
  }

  /// Writes the wake of the burst gathered for the rule [id].
  Future<void> _flushWatch(String ws, String id) async {
    final gathered = _gathered.remove(id);
    if (gathered == null) {
      return;
    }
    final rule = await _rules.getById(ws, id);
    final event = gathered.latest;
    // Checked again now: the rule may have ended, or its person lost the
    // repository, while the burst was gathered.
    if (rule == null || !rule.isActive || !await event.visible(rule)) {
      return;
    }
    final now = _clock().toUtc();
    // A wake of this watch still waiting (the agent's run is live) is folded
    // into this one: one wake, the latest state, every event counted. One
    // already claimed is left to its run; this burst is the next wake.
    var count = gathered.count;
    for (final waiting in await _wakes.listPendingFor(
      ws,
      conversationId: rule.conversationId,
      agentId: rule.agentId,
    )) {
      if (waiting.reason != WakeReason.watch ||
          waiting.detail.ruleId != rule.id ||
          waiting.state != WakeState.pending) {
        continue;
      }
      final folded = await _wakes.cancel(
        ws,
        ids: [waiting.id],
        reason: '${WakeRuleService.ownReasonPrefix}folded',
        now: now,
      );
      if (folded > 0) {
        final before = waiting.detail.fields[WakeFields.events];
        count += before is int && before > 0 ? before : 1;
      }
    }
    final perRun = await _perRunCapInLineage(rule);
    final wakeId = _newId();
    final wake = Wake(
      id: wakeId,
      workspaceId: ws,
      spaceId: rule.spaceId,
      conversationId: rule.conversationId,
      agentId: rule.agentId,
      reason: WakeReason.watch,
      payload: _watchPayload(rule.note, event.details),
      detail: WakeDetail(
        ruleId: rule.id,
        eventKind: event.kind,
        status: event.status,
        ticketId: event.ticketId,
        pipelineRunId: event.pipelineRunId,
        fields: {
          ..._ruleFields(rule),
          if (event.subject != null) WakeFields.subject: event.subject,
          if (event.item != null) WakeFields.item: event.item,
          if (event.exitCode != null) WakeFields.exitCode: event.exitCode,
          WakeFields.events: count,
        },
      ),
      runOptions: WakeRunOptions(costCapMicros: perRun),
      // Each write is its own wake: a folded one keeps its key.
      dedupKey: 'rule:${rule.id}:watch:$wakeId',
      notBefore: now,
      // It may wait for a long run; it lives as long as its rule.
      expiresAt: rule.expiresAt.isAfter(now)
          ? rule.expiresAt
          : now.add(const Duration(minutes: 5)),
      requestedByUserId: rule.requestedByUserId,
      createdAt: now,
    );
    try {
      await _queue.enqueue(wake);
    } on WorkspaceMismatchException catch (e) {
      CcInfraLog.warning('WakeRuleService: watch ${rule.id} not written: $e');
    }
  }
}

/// The payload of a watch's wake: the note, then the latest state, cut to
/// the wake's limit.
String _watchPayload(String note, List<String> details) {
  final text = details.isEmpty
      ? note
      : '$note\n\nLatest:\n${details.map((d) => '- $d').join('\n')}';
  return text.length <= Wake.maxPayloadLength
      ? text
      : '${text.substring(0, Wake.maxPayloadLength - 1)}…';
}
