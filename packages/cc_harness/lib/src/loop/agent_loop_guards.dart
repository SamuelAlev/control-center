part of 'agent_loop_runner.dart';

/// Doom-loop detection: identical tool-call sets this many turns in a row
/// inject a corrective reminder. With no turn ceiling (the default) this is the
/// primary bound on a spinning run.
const int _repetitionLimit = 3;

/// Returns-to-two-back before the alternation guard fires: 4 = A-B-A-B-A-B
/// (the ping-pong has cycled three times).
const int _alternationLimit = 4;

/// How many turns before the ceiling the wrap-up warning fires. Skipped
/// entirely for ceilings at or below this — a tiny budget needs every turn for
/// work, not warnings.
const int _turnPressureLead = 5;

/// The cross-turn guards: budgets, turn pressure, stream rules, doom-loop and
/// checklist supervision, and the advisor cadence.
class _RunGuards {
  _RunGuards(this.s)
    : checklist = s.config.steering.checklistStaleAfterTurns > 0
          ? ChecklistSupervisor(
              staleAfterTurns: s.config.steering.checklistStaleAfterTurns,
            )
          : null,
      _advisorEveryTurns = s.config.steering.advisorEveryTurns < 1
          ? 1
          : s.config.steering.advisorEveryTurns {
    // Seeded so the first eligible turn reviews, then it throttles.
    _turnsSinceAdvice = _advisorEveryTurns - 1;
  }

  final _RunState s;

  /// Checklist staleness: an agent that opens a task list and then never
  /// transitions anything leaves the user watching a list of `pending` items.
  /// Deterministic (a turn count, not a second model); disabled with
  /// `checklistStaleAfterTurns: 0`.
  final ChecklistSupervisor? checklist;
  final Set<StreamRule> firedRules = <StreamRule>{};
  final int _advisorEveryTurns;
  late int _turnsSinceAdvice;
  String? _lastTurnSignature;
  String? _prevTurnSignature;
  var _repeatedTurns = 0;
  var _alternatingTurns = 0;
  var _pressureNotified = false;

  /// One-shot latch for the host-priced soft budget steer.
  var _externalPressureSteered = false;

  AgentLoopConfig get config => s.config;

  /// Whether a HARD budget (host-priced or the loop's own) is spent.
  bool hardBudgetExhausted() {
    if (config.guards.externalBudgetExceeded?.call() ?? false) {
      return true;
    }
    final budget = config.guards.budget;
    return budget.hardStop &&
        ((budget.tokenBudget != null &&
                s.billableTokensNow() >= budget.tokenBudget!) ||
            (budget.timeBudget != null &&
                s.stopwatch.elapsed >= budget.timeBudget!));
  }

  /// The first stream rule that matches [text] and has not yet fired, or null.
  StreamRule? firstUnfiredRule(String text) {
    for (final rule in config.steering.streamRules) {
      if (!firedRules.contains(rule) && rule.matches(text)) {
        return rule;
      }
    }
    return null;
  }

  /// Turn-pressure steering: with only a few turns left, warn the model while
  /// it can still ACT. The ceiling otherwise stops the run mid-task with every
  /// finding still in volatile history.
  Stream<AgentLoopEvent> turnPressure() async* {
    final maxTurns = config.maxTurns;
    if (maxTurns != null &&
        maxTurns > _turnPressureLead &&
        s.turn == maxTurns - _turnPressureLead) {
      const steer =
          'You are nearing this run\'s turn limit — only a few turns left. '
          'Wrap up NOW: save durable findings to your notes or memory tools, '
          'and make your final answer a handoff — what you learned, the '
          'current state and the exact next steps. Anything not written '
          'down is lost when the run stops.';
      s.history.add(HarnessMessage.system(steer));
      yield const LoopNotice(steer);
    }
  }

  /// Doom-loop + checklist supervision after a tool-bearing turn.
  ///
  /// Period-1 (A-A-A): this turn's calls are byte-identical to the previous
  /// turn's. Period-2 (A-B-A-B): the classic "edit, revert, edit, revert"
  /// loop a period-1 check never sees. Past the limit, nudge the model to
  /// change approach (fires once per breach, then re-arms).
  Stream<AgentLoopEvent> afterToolTurn(List<_PendingTool> pending) async* {
    final signature = [
      for (final t in pending) '${t.name}:${jsonEncode(t.args)}',
    ].join('|');
    if (signature == _lastTurnSignature) {
      _repeatedTurns++;
      _alternatingTurns = 0;
    } else if (signature == _prevTurnSignature) {
      _alternatingTurns++;
      _repeatedTurns = 1;
    } else {
      _repeatedTurns = 1;
      _alternatingTurns = 0;
    }
    _prevTurnSignature = _lastTurnSignature;
    _lastTurnSignature = signature;
    if (_repeatedTurns >= _repetitionLimit ||
        _alternatingTurns >= _alternationLimit) {
      final alternating = _alternatingTurns >= _alternationLimit;
      _repeatedTurns = 0;
      _alternatingTurns = 0;
      s.history.add(
        HarnessMessage.system(
          alternating
              ? 'You are alternating between the same two tool call sets '
                    'and getting nowhere — a ping-pong loop. Stop cycling: '
                    'pick a different approach, or explain what is blocking '
                    'you and ask for guidance.'
              : 'You have repeated the same tool call(s) with identical '
                    'arguments $_repetitionLimit turns in a row and are '
                    'getting the same result. Stop repeating — change your '
                    'approach, or explain what is blocking you and ask for '
                    'guidance.',
        ),
      );
      yield const LoopNotice(
        'Repetition detected; steering the agent to change approach.',
      );
    }

    final checklist = this.checklist;
    if (checklist != null) {
      final steer = checklist.observeTurn([
        for (final t in pending) (name: t.name, args: t.args),
      ]);
      if (steer != null) {
        s.history.add(HarnessMessage.system(steer));
        yield const LoopNotice(
          'Task checklist is stale; steering the agent to update it.',
        );
      }
    }
  }

  /// Advisor: a second model reviews the turn and may inject a steering note
  /// before the next turn. Rate-limited to once per `advisorEveryTurns`
  /// tool-turns. The review is raced against cancellation and handed the
  /// run's token, so a cancelled run neither waits on nor pays for it.
  Stream<AgentLoopEvent> advise() async* {
    final advisor = config.steering.advisor;
    _turnsSinceAdvice++;
    if (advisor == null || _turnsSinceAdvice < _advisorEveryTurns) {
      return;
    }
    _turnsSinceAdvice = 0;
    AdvisorNote? note;
    try {
      note = await raceCancellation<AdvisorNote?>(
        advisor.review(s.history, cancel: s.cancel),
        s.cancel,
      );
    } on Object catch (e) {
      // Advice is optional by construction; a failing reviewer costs the
      // note, not the run.
      yield LoopNotice('Advisor review failed and was skipped: $e');
      note = null;
    }
    if (s.cancel.isCancelled) {
      yield* s.finish(LoopDoneReason.cancelled);
      return;
    }
    if (note != null) {
      s.history.add(HarnessMessage.system(_formatAdvisory(note)));
      yield LoopAdvisorNote(note.note, severity: note.severity);
    }
  }

  /// Budget enforcement after a tool-bearing turn. A hard budget stops the
  /// run; a soft budget steers once at the pressure threshold and again when
  /// exhausted. The host-priced external budget steers once on pressure and
  /// stops on exhaustion.
  Stream<AgentLoopEvent> budgetAfterTurn() async* {
    final budget = config.guards.budget;
    if (budget.isActive) {
      final timeBudget = budget.timeBudget;
      final tokenBudget = budget.tokenBudget;
      final timeExhausted =
          timeBudget != null && s.stopwatch.elapsed >= timeBudget;
      final tokenExhausted =
          tokenBudget != null && s.billableTokensNow() >= tokenBudget;
      if (timeExhausted || tokenExhausted) {
        if (budget.hardStop) {
          yield LoopNotice(
            tokenExhausted
                ? 'Token budget exhausted.'
                : 'Time budget exhausted.',
          );
          yield* s.finish(LoopDoneReason.budgetExhausted);
          return;
        }
        if (!_pressureNotified) {
          _pressureNotified = true;
          const steer =
              'Your budget is exhausted. Wrap up and deliver your result now.';
          s.history.add(HarnessMessage.system(steer));
          yield const LoopNotice(steer);
        }
      } else if (!_pressureNotified) {
        final timePressure =
            timeBudget != null &&
            s.stopwatch.elapsed >= timeBudget * budget.pressureFraction;
        final tokenPressure =
            tokenBudget != null &&
            s.billableTokensNow() >= tokenBudget * budget.pressureFraction;
        if (timePressure || tokenPressure) {
          _pressureNotified = true;
          const steer =
              'You are approaching your budget. Wrap up your work and deliver '
              'your result now.';
          s.history.add(HarnessMessage.system(steer));
          yield const LoopNotice(steer);
        }
      }
    }
    // External budget (host-priced): the dispatch layer alone can price usage,
    // so it hands the loop a poll instead of a number.
    if (!_externalPressureSteered &&
        (config.guards.externalBudgetPressure?.call() ?? false)) {
      _externalPressureSteered = true;
      const steer =
          'You are approaching this run’s cost budget. Wrap up your work '
          'NOW: persist important notes, leave the worktree in a coherent '
          'state and deliver your result — a follow-up run continues '
          'from what you leave behind.';
      s.history.add(HarnessMessage.system(steer));
      yield const LoopNotice(steer);
    }
    if (config.guards.externalBudgetExceeded?.call() ?? false) {
      yield const LoopNotice('External budget exhausted.');
      yield* s.finish(LoopDoneReason.budgetExhausted);
    }
  }

  /// Frames an advisor note as the agent-facing `<advisory>` block. The
  /// `guidance` attribute is the model's only cue for how to treat it: advice
  /// to weigh, not an order to obey.
  static String _formatAdvisory(AdvisorNote note) =>
      '<advisory severity="${note.severity.name}" '
      'guidance="weigh, do not blindly obey">\n'
      '${note.note}\n'
      '</advisory>';
}
