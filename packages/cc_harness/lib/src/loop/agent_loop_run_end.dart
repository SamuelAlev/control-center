part of 'agent_loop_runner.dart';

/// The turn end (the would-stop seam and the park), background commands'
/// lifetime, and what a compaction keeps in flight.
extension _RunEnd on _RunState {
  /// Binds the run's background commands to this run: their exit notices go
  /// to the run's notice lane, and new commands may start.
  void openBackground() {
    final bg = background;
    if (bg == null) {
      return;
    }
    bg
      ..reopen()
      ..onNotice = ((notice, handle) {
        noticeLane.pushAside(notice, source: '$backgroundNoticeSource$handle');
      })
      ..onNotify = ((delivery, handle) {
        noticeLane.pushAside(delivery, source: 'notify:$handle');
      });
  }

  /// Moves the background commands' waiting `notify` deliveries onto the
  /// notice lane (a turn boundary).
  void collectNotify() {
    for (final d
        in background?.takeNotifyDeliveries() ??
            const <BackgroundNotifyDelivery>[]) {
      noticeLane.pushAside(d.text, source: 'notify:${d.handle}');
    }
  }

  /// Kills every live background command of the run. Every terminal path
  /// passes here; safe to call more than once.
  Future<void> closeBackground() async {
    final bg = background;
    if (bg == null) {
      return;
    }
    bg
      ..onNotice = null
      ..onNotify = null;
    await bg.killAll();
  }

  /// The model answered with no tool calls and nothing cut it off: run the
  /// follow-up lane, the completion contract and the would-stop seam, in that
  /// order, and end the turn only when all three let it.
  Stream<AgentLoopEvent> wouldStop(String lastAssistantText) async* {
    final queue = config.steering.queue;
    var parked = false;
    while (true) {
      // Follow-up lane: queued messages meant to run once the agent finishes.
      final followUps = queue?.drainFollowUp() ?? const [];
      if (followUps.isNotEmpty) {
        for (final msg in followUps) {
          if (msg.content.trim().isNotEmpty) {
            history.add(
              HarnessMessage.user(
                msg.content.trim(),
                origin: laneMessageOrigin(msg),
              ),
            );
          }
        }
        // A new user prompt: its answer gets a fresh truncation allowance.
        consecutiveTruncations = 0;
        yield const LoopNotice('Follow-up message injected; continuing.');
        return;
      }
      // A server notice the model has not seen yet (a command's exit, its
      // `notify` lines) is the next turn's input, and so is what a person
      // sent while the run was parked.
      collectNotify();
      if (noticeLane.hasAside ||
          (parked && queue != null && (queue.hasSteering || queue.hasAside))) {
        yield LoopNotice(
          parked
              ? 'Resumed after a park; continuing.'
              : 'A background command notice arrived; continuing.',
        );
        return;
      }
      // Completion contract: if a deliverable is owed and missing, nudge
      // (bounded) then end `contractUnmet`. After follow-up drain so user
      // steering outranks the reminder.
      if (ledger.isActive && !await ledger.resolveSatisfied()) {
        if (ledger.canNudge) {
          history.add(HarnessMessage.system(ledger.takeNudge()));
          yield LoopNotice(
            'Completion contract "${ledger.contract!.id}" unmet — '
            'steering the agent to deliver.',
          );
          return;
        }
        yield* finish(LoopDoneReason.contractUnmet);
        return;
      }
      final answer = await _askWouldStop(lastAssistantText);
      if (cancel.isCancelled) {
        yield* finish(LoopDoneReason.cancelled);
        return;
      }
      // A notice that arrived while the hooks were asked is the next turn's
      // input, whatever they answered.
      collectNotify();
      if (noticeLane.hasAside) {
        continue;
      }
      switch (answer) {
        case WouldStopEnd():
          // The final answer is in [history] and a model that answered with
          // no tool calls leaves no dangling `tool_use`, so [finish] saves
          // it: without that the next run resumed from the turn BEFORE the
          // answer.
          yield* finish(LoopDoneReason.completed);
          return;
        case WouldStopContinue(:final message, :final origin):
          history.add(HarnessMessage.system(message, origin: origin));
          yield const LoopNotice('The turn end was held; continuing.');
          return;
        case WouldStopPark(:final until, :final reason):
          parked = true;
          yield LoopPark(parked: true, reason: reason);
          await Future.any<void>([
            until.then<void>((_) {}, onError: (Object _) {}),
            cancel.whenCancelled,
            ?queue?.nextArrival(),
          ]);
          yield LoopPark(parked: false, reason: reason);
          if (cancel.isCancelled) {
            yield* finish(LoopDoneReason.cancelled);
            return;
          }
      }
    }
  }

  /// The would-stop answer: the kernel's own park while a background command
  /// is unsettled, else the turn hooks', else "end".
  ///
  /// Unsettled, not merely running: a command that exited is still storing
  /// its output before its notice is queued, and the notice is queued in the
  /// same synchronous step that settles it. So once nothing is unsettled,
  /// every notice is already on the lane; while something is, the park wakes
  /// when it settles ([BackgroundCommandRegistry.whenAnyEvent]).
  Future<WouldStop> _askWouldStop(String lastAssistantText) async {
    final live = background?.unsettled ?? const <BackgroundCommand>[];
    if (live.isNotEmpty) {
      return WouldStopPark(
        background!.whenAnyEvent(),
        reason:
            'background command${live.length == 1 ? '' : 's'} '
            '${live.map((c) => c.handle).join(', ')}',
      );
    }
    final turnHooks = config.steering.turnHooks;
    if (turnHooks == null) {
      return const WouldStopEnd();
    }
    try {
      final answer = await raceCancellation(
        turnHooks.onWouldStop(
          WouldStopContext(turn: turn, lastAssistantText: lastAssistantText),
        ),
        cancel,
      );
      return answer ?? const WouldStopEnd();
    } on Object {
      // A broken hook must not hold the run open.
      return const WouldStopEnd();
    }
  }

  /// The summarizer's focus for a compaction: the `compact` call's focus,
  /// then the owner's `preCompact` hook output (1,000 characters at most).
  Future<String?> compactionFocus(String? toolFocus) async {
    final parts = <String>[
      if (toolFocus != null && toolFocus.trim().isNotEmpty) toolFocus.trim(),
    ];
    final turnHooks = config.steering.turnHooks;
    if (turnHooks != null) {
      try {
        final extra = (await turnHooks.preCompact())?.trim();
        if (extra != null && extra.isNotEmpty) {
          parts.add(
            extra.length > maxPreCompactFocusChars
                ? extra.substring(0, maxPreCompactFocusChars)
                : extra,
          );
        }
      } on Object {
        // A broken hook adds nothing.
      }
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  /// Replaces the "Still in flight" block after a compaction: every earlier
  /// block is removed and a new one, built from live state, is appended when
  /// there is anything in flight.
  Future<void> writeStillInFlight() async {
    for (var i = history.length - 1; i >= 0; i--) {
      final m = history[i];
      if (m.role == HarnessRole.system && isStillInFlightBlock(m.textContent)) {
        history.removeAt(i);
        checkpoints.updateAll((_, at) => at > i ? at - 1 : at);
      }
    }
    final lines = <String>[
      ?_backgroundLine(),
      ?_checklistLine(),
      ...await _hostInFlightLines(),
    ];
    final block = renderStillInFlightBlock(
      at: (config.compaction.clock ?? DateTime.now)(),
      lines: lines,
    );
    if (block != null) {
      history.add(HarnessMessage.system(block));
    }
  }

  String? _backgroundLine() {
    final live = background?.live ?? const <BackgroundCommand>[];
    if (live.isEmpty) {
      return null;
    }
    String shown(String command) {
      final flat = command.replaceAll('\n', ' ').trim();
      return flat.length > 60 ? '${flat.substring(0, 59)}…' : flat;
    }

    String item(BackgroundCommand c) {
      final running = formatBackgroundDuration(c.elapsed);
      return '${c.handle} `${shown(c.command)}`, running $running';
    }

    final items = [for (final c in live) item(c)];
    return 'Background: ${items.join('; ')} → bash_output';
  }

  String? _checklistLine() {
    final counts = guards.checklistCounts;
    if (counts == null || counts.open == 0) {
      return null;
    }
    return 'Checklist: ${counts.open} of ${counts.total} open → todo_read';
  }

  Future<List<String>> _hostInFlightLines() async {
    final seam = config.compaction.inFlightLines;
    if (seam == null) {
      return const [];
    }
    try {
      return await seam().timeout(inFlightLinesTimeout);
    } on Object {
      return const [];
    }
  }

  /// Context use, once it passes 70% of the window (then 80% and 90%): one
  /// system line that names `compact`, so the model knows when calling it is
  /// worth it. Re-armed when a compaction brings use back under 70%. Only
  /// for a run that has `compact` and a compactor to run it.
  Stream<AgentLoopEvent> contextUseLine() async* {
    final window = config.compaction.contextWindow;
    if (window == null ||
        window <= 0 ||
        compactor == null ||
        !catalog.byName.containsKey(compactToolName)) {
      return;
    }
    final used = estimateHarnessHistory(history) + overheadTokensNow();
    final percent = used * 100 ~/ window;
    final level = percent >= 90
        ? 90
        : percent >= 80
        ? 80
        : percent >= 70
        ? 70
        : 0;
    if (level == 0) {
      contextLineLevel = 0;
      return;
    }
    if (level <= contextLineLevel) {
      return;
    }
    contextLineLevel = level;
    // A deferred `compact` is found with the run's own discovery tool, when
    // it has one; a resident one needs no pointer.
    final deferred =
        catalog.deferredByName.containsKey(compactToolName) &&
        !catalog.activatedNames.contains(compactToolName);
    final line = contextUseLineText(
      percent: percent,
      contextWindow: window,
      findWith: deferred
          ? contextLineFinders.where(catalog.byName.containsKey).firstOrNull
          : null,
    );
    // Last-observed state, like an exit notice: never pinned.
    history.add(
      HarnessMessage.system(line, origin: HarnessMessageOrigin.notice),
    );
    yield LoopNotice(line);
  }
}

/// The notice-lane source of a background command's exit notice, before its
/// handle.
const String backgroundNoticeSource = 'background:';

/// The lane source a wake frame carries ([SteeringMessage.source]).
const String wakeLaneSource = 'wake';

/// Where a message drained from a host lane came from.
///
/// The contract for every producer: a message a person sent goes into the
/// steering or follow-up lane with no [SteeringMessage.source]; anything
/// else carries a source ([wakeLaneSource] for a wake frame, any other
/// non-empty source for another agent's or an outside producer's text).
/// The aside lane never carries the person's words.
HarnessMessageOrigin laneMessageOrigin(SteeringMessage message) {
  final source = message.source;
  if (source == wakeLaneSource) {
    return HarnessMessageOrigin.wake;
  }
  if (source == null && message.channel != SteeringChannel.aside) {
    return HarnessMessageOrigin.person;
  }
  return HarnessMessageOrigin.peer;
}

/// The name of the loop-handled tool that schedules a compaction.
const String compactToolName = 'compact';

/// The most a `compact` focus may hold, in characters.
const int maxCompactFocusChars = 1000;

/// The most of the owner's `preCompact` hook output added to a focus.
const int maxPreCompactFocusChars = 1000;

/// How long the host's "Still in flight" lines may take.
const Duration inFlightLinesTimeout = Duration(seconds: 2);

/// The discovery tools the context-use line may point a deferred `compact`
/// at, in the order it prefers them: only one the run has is named.
const List<String> contextLineFinders = [
  'search_tools',
  'search_tool_bm25',
  'list_my_tools',
];

/// The context-use line, at [percent] of a [contextWindow]-token window.
/// [findWith] names the run's tool that finds a deferred `compact`; null
/// when `compact` is resident or the run has none.
String contextUseLineText({
  required int percent,
  required int contextWindow,
  required String? findWith,
}) {
  final window = contextWindow >= 1000
      ? '${contextWindow ~/ 1000}k'
      : '$contextWindow';
  final find = findWith == null ? '' : ' (find it with `$findWith`)';
  return 'Context: about $percent% of the $window-token context window is in '
      'use. If older work can be summarized now, call `compact` with a '
      '`focus` naming what must survive$find; otherwise the context is '
      'compacted on its own near the limit.';
}
