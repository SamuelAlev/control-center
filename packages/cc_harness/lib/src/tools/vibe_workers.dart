import 'dart:async';

import 'package:cc_harness/src/tools/subagent_profile.dart';
import 'package:cc_harness/src/tools/subagent_spawner.dart';
import 'package:cc_harness/src/tools/tool.dart';

/// Which model tier a worker runs on.
enum VibeTier {
  /// Cheap and fast: mechanical execution, drafts, mass edits.
  fast,

  /// The strong model: design, judgment, reviewing `fast` output.
  good;

  /// What to tell the model about picking one.
  String get guidance => switch (this) {
    VibeTier.fast =>
      'mechanical work with a clear specification — edits, renames, drafts, '
          'running commands',
    VibeTier.good =>
      'design, judgment, or reviewing what a fast worker produced',
  };
}

/// What a worker is doing.
enum VibeWorkerStatus {
  /// Started, no result yet.
  running,

  /// Finished with a result.
  done,

  /// Finished with an error.
  failed,

  /// Killed by the director or by mode exit.
  killed,
}

/// One background worker.
class VibeWorker {
  /// Creates a [VibeWorker].
  VibeWorker({
    required this.id,
    required this.label,
    required this.tier,
    required this.brief,
    required this.startedAt,
  });

  /// Stable handle the director addresses it by.
  final String id;

  /// Short human label.
  final String label;

  /// Which model tier it runs on.
  final VibeTier tier;

  /// The brief it was started with.
  final String brief;

  /// When it started.
  final DateTime startedAt;

  /// Current status.
  VibeWorkerStatus status = VibeWorkerStatus.running;

  /// Its last result, once it has one.
  String? result;

  /// The child run id, for opening its activity.
  String? runId;

  /// Everything sent to it after the initial brief.
  final List<String> followUps = [];

  /// Completes when the current turn settles.
  Completer<void> settled = Completer<void>();

  /// Whether it is still working.
  bool get isRunning => status == VibeWorkerStatus.running;
}

/// The director's roster of background workers.
///
/// **What vibe mode actually changes.** Not the machinery — spawning subagents
/// is something the `task` tool already does. What changes is the INTERACTION
/// SHAPE: the session stops doing the work and starts directing it. Its own
/// toolset drops to `read` plus these five verbs, so the only way it can affect
/// the repo is through a worker, and the only way it can know what happened is
/// by reading the files a worker touched. That is the point — a director that
/// can grep and edit will do the work itself under pressure, and a director
/// that takes a worker's word for it is a summarizer, not a reviewer.
///
/// **Workers start blank.** A worker never sees the director's conversation;
/// the brief is its entire context. That is what keeps a worker's context small
/// and is the whole reason the pattern scales — twenty workers each holding the
/// director's history would cost twenty times the director's context.
///
/// **A worker never outlives the mode.** Exiting kills every one of them.
/// A background agent still editing files after the conversation that started
/// it has moved on is the failure this must not have.
class VibeRoster {
  /// Creates a [VibeRoster].
  VibeRoster({this.maxWorkers = 8});

  /// How many workers may run at once.
  ///
  /// A ceiling on concurrent spend, not a technical limit: each worker is a
  /// full model session, and a director that fans out twenty is one that has
  /// stopped tracking what they are all doing.
  final int maxWorkers;

  final Map<String, VibeWorker> _workers = {};
  int _counter = 0;

  /// Every worker, oldest first.
  List<VibeWorker> get workers => _workers.values.toList();

  /// The workers still running.
  List<VibeWorker> get running =>
      _workers.values.where((w) => w.isRunning).toList();

  /// The worker with [id], or null.
  VibeWorker? operator [](String id) => _workers[id];

  /// Registers a new worker, or throws when the roster is full.
  VibeWorker add({
    required String label,
    required VibeTier tier,
    required String brief,
    required DateTime now,
  }) {
    if (running.length >= maxWorkers) {
      throw StateError(
        'Already running ${running.length} workers (the cap). Wait for one to '
        'finish or kill it before starting another.',
      );
    }
    // Deterministic and monotonic, not random: the id goes into a tool result
    // the model reads back and later names, and a replayed session has to
    // produce the same one.
    final id = 'w${++_counter}';
    final worker = VibeWorker(
      id: id,
      label: label,
      tier: tier,
      brief: brief,
      startedAt: now,
    );
    _workers[id] = worker;
    return worker;
  }

  /// Records a worker's outcome and releases anything waiting on it.
  void settle(String id, {required String result, required bool isError}) {
    final worker = _workers[id];
    if (worker == null) {
      return;
    }
    worker
      ..result = result
      ..status = isError ? VibeWorkerStatus.failed : VibeWorkerStatus.done;
    if (!worker.settled.isCompleted) {
      worker.settled.complete();
    }
  }

  /// Marks a worker killed.
  bool kill(String id) {
    final worker = _workers[id];
    if (worker == null || !worker.isRunning) {
      return false;
    }
    worker.status = VibeWorkerStatus.killed;
    if (!worker.settled.isCompleted) {
      worker.settled.complete();
    }
    return true;
  }

  /// Kills everything. Called on mode exit.
  int killAll() {
    var killed = 0;
    for (final worker in _workers.values) {
      if (worker.isRunning) {
        worker.status = VibeWorkerStatus.killed;
        if (!worker.settled.isCompleted) {
          worker.settled.complete();
        }
        killed++;
      }
    }
    return killed;
  }

  /// Renders the roster the way the director should read it back.
  String describe({required DateTime now}) {
    if (_workers.isEmpty) {
      return 'No workers.';
    }
    final buffer = StringBuffer();
    for (final worker in _workers.values) {
      final elapsed = now.difference(worker.startedAt).inSeconds;
      buffer.writeln(
        '${worker.id} [${worker.tier.name}] ${worker.label} — '
        '${worker.status.name} (${elapsed}s)'
        '${worker.status == VibeWorkerStatus.running ? '' : worker.result == null ? '' : ': ${_oneLine(worker.result!)}'}',
      );
    }
    return buffer.toString().trimRight();
  }

  static String _oneLine(String text, {int max = 100}) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length > max ? '${flat.substring(0, max)}…' : flat;
  }
}

/// Builds the brief a worker is started with.
///
/// **Self-contained by construction.** The director writes the brief for
/// somebody who has read nothing — not a follow-up to a conversation the worker
/// was never in. The framing here is what stops a director from writing "now do
/// the other one too", which reads as a complete instruction to the director
/// and as nothing at all to a fresh session.
String buildVibeBrief({
  required String brief,
  required VibeTier tier,
  List<String> followUps = const [],
}) {
  final buffer = StringBuffer()
    ..writeln(
      'You are a worker in a directed session. You have NOT seen the '
      'conversation that started you — this brief is your entire context, so '
      'do not ask about anything outside it.',
    )
    ..writeln()
    ..writeln(brief.trim());
  if (followUps.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('Follow-up instructions, in order:');
    for (final followUp in followUps) {
      buffer.writeln('- ${followUp.trim()}');
    }
  }
  buffer
    ..writeln()
    ..writeln(
      'Report what you actually did, naming every file you changed. The '
      'director verifies by reading those files, so a claim you cannot point '
      'at is worse than saying you did not get there.',
    );
  return buffer.toString();
}

/// The director's system-prompt addendum.
///
/// Says the one thing the toolset cannot enforce: that a worker's report is a
/// claim, not evidence. The tool surface stops the director from EDITING; only
/// the prompt can stop it from believing.
const String vibeDirectorPrompt = '''
You are directing this work rather than doing it.

Your own tools are read-only plus the five worker verbs. To change anything you
spawn a worker with a COMPLETE, SELF-CONTAINED brief: the worker has not seen
this conversation and never will.

Two tiers. Use `fast` for mechanical work with a clear specification, and
`good` for design, judgment, or reviewing what a fast worker produced.

Spawning and sending are asynchronous — they return immediately and the result
arrives on its own. Only use `vibe_wait` when you genuinely cannot proceed
without a specific worker's answer.

Verify by READING THE FILES a worker touched. A worker's report is a claim
about what it did, not evidence that it worked. Taking that claim at face value
makes you a summarizer of other agents' optimism.

Kill a worker that has lost the thread rather than sending it more
instructions; a fresh brief is cheaper than an argument.''';

/// Starts a worker on the director's behalf.
///
/// The port the `vibe_*` tools call, implemented by the dispatch layer where
/// the provider factory and run-log writer live — the same seam
/// [SubagentSpawner] uses, and for the same reason.
abstract interface class VibeWorkerRunner {
  /// Runs a worker to completion and returns its result.
  Future<SubagentResult> run({
    required VibeWorker worker,
    required String brief,
    required HarnessToolContext context,
    required SubagentType type,
    String? modelOverride,
  });
}
