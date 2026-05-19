import 'dart:async';

import 'package:cc_harness/tools.dart';

/// Base for the five director verbs, so they share the roster and the runner.
abstract class _VibeTool extends HarnessTool {
  _VibeTool(this.roster, this.runner, this.now);

  /// The director's workers.
  final VibeRoster roster;

  /// Starts them.
  final VibeWorkerRunner runner;

  /// Injectable clock, so elapsed times are testable.
  final DateTime Function() now;

  /// Read tier across the board.
  ///
  /// **Deliberate, and the load-bearing part of vibe mode.** Spawning a worker
  /// looks like a write — it ends in files changing — but the gate belongs on
  /// the WORKER's tools, where the actual edit happens and where the guardrail
  /// policy already applies. Putting it here too would prompt twice for one
  /// decision. It is the same reasoning that makes `task` read-tier.
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  /// The gating happens on the child's tools, which leaves the loop nothing to
  /// serialize — so these opt back into ordering the way `task` does.
  @override
  bool get selfGuards => true;

  /// The worker named by [args], or an error result explaining what is there.
  ({VibeWorker? worker, HarnessToolResult? error}) _resolve(
    Map<String, dynamic> args,
  ) {
    final id = args['worker_id'];
    if (id is! String || id.isEmpty) {
      return (
        worker: null,
        error: HarnessToolResult.error('Missing argument: worker_id'),
      );
    }
    final worker = roster[id];
    if (worker == null) {
      final live = roster.running.map((w) => w.id).join(', ');
      return (
        worker: null,
        error: HarnessToolResult.error(
          'No worker "$id". '
          '${live.isEmpty ? 'None are running.' : 'Running: $live.'}',
        ),
      );
    }
    return (worker: worker, error: null);
  }
}

/// Starts a background worker on a complete, self-contained brief.
class VibeSpawnTool extends _VibeTool {
  /// Creates a [VibeSpawnTool].
  VibeSpawnTool(super.roster, super.runner, super.now);

  @override
  String get name => 'vibe_spawn';

  @override
  String get description =>
      'Start a background worker. `brief` is its ENTIRE context — it has not '
      'seen this conversation and never will, so write it for someone who has '
      'read nothing. Returns immediately; the result arrives on its own.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'brief': {
        'type': 'string',
        'description':
            'The complete, self-contained task. Name files and commands '
            'explicitly; the worker cannot ask about anything outside it.',
      },
      'label': {
        'type': 'string',
        'description': 'Short name for the roster (e.g. "migrate-auth").',
      },
      'tier': {
        'type': 'string',
        'enum': ['fast', 'good'],
        'description':
            'fast: mechanical work with a clear spec. good: design, judgment, '
            'or reviewing a fast worker.',
      },
    },
    'required': ['brief', 'label'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final brief = args['brief'];
    if (brief is! String || brief.trim().isEmpty) {
      return HarnessToolResult.error('Missing argument: brief');
    }
    final label = args['label'];
    if (label is! String || label.trim().isEmpty) {
      return HarnessToolResult.error('Missing argument: label');
    }
    final tier = args['tier'] == 'good' ? VibeTier.good : VibeTier.fast;

    final VibeWorker worker;
    try {
      worker = roster.add(
        label: label.trim(),
        tier: tier,
        brief: brief.trim(),
        now: now(),
      );
    } on StateError catch (e) {
      return HarnessToolResult.error(e.message);
    }

    _start(worker, context);
    return HarnessToolResult.success(
      'Started ${worker.id} [${tier.name}] ${worker.label}. It is running in '
      'the background — carry on, and check `vibe_list` for its result.',
    );
  }

  /// Runs the worker without blocking the director's turn.
  ///
  /// Async by default is the whole ergonomic difference from `task`: a
  /// director that blocks on every spawn is running workers one at a time,
  /// which is a slower way to do what it was already doing itself.
  void _start(VibeWorker worker, HarnessToolContext context) {
    unawaited(() async {
      try {
        final result = await runner.run(
          worker: worker,
          brief: buildVibeBrief(
            brief: worker.brief,
            tier: worker.tier,
            followUps: worker.followUps,
          ),
          context: context,
          // A worker does the work, so it gets the writing profile. Its tools
          // are still gated by the run's guardrail policy — the tier is a
          // ceiling, not a grant.
          type: SubagentType.general,
        );
        worker.runId = result.childRunId;
        roster.settle(
          worker.id,
          result: result.text,
          isError: result.isError,
        );
      } on Object catch (e) {
        roster.settle(worker.id, result: '$e', isError: true);
      }
    }());
  }
}

/// Sends a follow-up turn to a worker.
class VibeSendTool extends _VibeTool {
  /// Creates a [VibeSendTool].
  VibeSendTool(super.roster, super.runner, super.now);

  @override
  String get name => 'vibe_send';

  @override
  String get description =>
      'Send a follow-up instruction to a worker. It is appended to that '
      'worker\'s brief and re-run. Prefer killing and re-briefing a worker '
      'that has lost the thread — a fresh brief is cheaper than an argument.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'worker_id': {'type': 'string', 'description': 'From vibe_list.'},
      'message': {
        'type': 'string',
        'description': 'The follow-up instruction.',
      },
    },
    'required': ['worker_id', 'message'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final resolved = _resolve(args);
    final worker = resolved.worker;
    if (worker == null) {
      return resolved.error!;
    }
    final message = args['message'];
    if (message is! String || message.trim().isEmpty) {
      return HarnessToolResult.error('Missing argument: message');
    }
    if (worker.isRunning) {
      return HarnessToolResult.error(
        '${worker.id} is still working. Wait for it, or kill it and start '
        'again with a corrected brief.',
      );
    }
    worker
      ..followUps.add(message.trim())
      ..status = VibeWorkerStatus.running
      ..settled = Completer<void>();

    unawaited(() async {
      try {
        final result = await runner.run(
          worker: worker,
          brief: buildVibeBrief(
            brief: worker.brief,
            tier: worker.tier,
            followUps: worker.followUps,
          ),
          context: context,
          type: SubagentType.general,
        );
        worker.runId = result.childRunId;
        roster.settle(worker.id, result: result.text, isError: result.isError);
      } on Object catch (e) {
        roster.settle(worker.id, result: '$e', isError: true);
      }
    }());

    return HarnessToolResult.success('Sent to ${worker.id}. Running again.');
  }
}

/// Blocks until a worker settles.
class VibeWaitTool extends _VibeTool {
  /// Creates a [VibeWaitTool].
  VibeWaitTool(super.roster, super.runner, super.now);

  @override
  String get name => 'vibe_wait';

  @override
  String get description =>
      'Block until a worker finishes and return its result. Only use this when '
      'you genuinely cannot proceed without that answer — waiting is how a '
      'directed session becomes a sequential one.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'worker_id': {'type': 'string', 'description': 'From vibe_list.'},
      'timeout_seconds': {
        'type': 'integer',
        'description': 'How long to wait. Default 300, max 1800.',
      },
    },
    'required': ['worker_id'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final resolved = _resolve(args);
    final worker = resolved.worker;
    if (worker == null) {
      return resolved.error!;
    }
    final raw = args['timeout_seconds'];
    final timeout = Duration(
      seconds: raw is int ? raw.clamp(1, 1800) : 300,
    );
    if (worker.isRunning) {
      try {
        await worker.settled.future.timeout(timeout);
      } on TimeoutException {
        return HarnessToolResult.success(
          '${worker.id} is still running after ${timeout.inSeconds}s. It has '
          'not failed — carry on with something else and check vibe_list.',
        );
      }
    }
    return HarnessToolResult.success(
      '${worker.id} ${worker.status.name}.\n\n${worker.result ?? '(no result)'}'
      '\n\nVerify by reading the files it named — that report is a claim, not '
      'evidence.',
    );
  }
}

/// Kills a worker.
class VibeKillTool extends _VibeTool {
  /// Creates a [VibeKillTool].
  VibeKillTool(super.roster, super.runner, super.now);

  @override
  String get name => 'vibe_kill';

  @override
  String get description =>
      'Stop a worker. Use this on one that has lost the thread rather than '
      'arguing with it.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'worker_id': {'type': 'string', 'description': 'From vibe_list.'},
    },
    'required': ['worker_id'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final resolved = _resolve(args);
    final worker = resolved.worker;
    if (worker == null) {
      return resolved.error!;
    }
    return roster.kill(worker.id)
        ? HarnessToolResult.success('Killed ${worker.id}.')
        : HarnessToolResult.success(
            '${worker.id} had already ${worker.status.name}.',
          );
  }
}

/// Shows the roster.
class VibeListTool extends _VibeTool {
  /// Creates a [VibeListTool].
  VibeListTool(super.roster, super.runner, super.now);

  @override
  String get name => 'vibe_list';

  @override
  String get description =>
      'Show every worker, its tier, status, elapsed time and last result.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success(roster.describe(now: now()));
}

/// The five director verbs over one roster.
List<HarnessTool> buildVibeTools({
  required VibeRoster roster,
  required VibeWorkerRunner runner,
  DateTime Function()? now,
}) {
  final clock = now ?? DateTime.now;
  return [
    VibeSpawnTool(roster, runner, clock),
    VibeSendTool(roster, runner, clock),
    VibeWaitTool(roster, runner, clock),
    VibeKillTool(roster, runner, clock),
    VibeListTool(roster, runner, clock),
  ];
}
