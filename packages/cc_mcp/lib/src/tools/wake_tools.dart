import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, ValidationException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/peer_ask_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/context.dart' show ToolCallForm, toolCallText;
import 'package:cc_infra/cc_infra.dart'
    show WakeLineageStatus, WakeRuleRequest, WakeRuleService, wakeRuleNoteGist;
import 'package:cc_mcp/src/mcp_scoped_tool.dart';

/// The text the first `wake_me` result of a run carries, and every refusal:
/// plan section 17's description, then the grammar with one example per
/// form, the limits and what happens when the agent is busy. Pinned by
/// `wake_tools_test.dart`.
const String wakeMeReference =
    'Arrange to be woken in this conversation later, then end your turn. Use '
    'it in place of sleeping, polling or re-running a command to see '
    'whether something changed. `when`: `in:20m`, `at:<ISO time>`, '
    '`every:30m`, `cron:0 9 * * 1-5`, `next` (in a loop: you choose the '
    'delay each time), or an event: `on:pr_checks`, `on:pr_review`, '
    '`on:pr_merged`, `on:environment`, `on:ticket:<id>`, '
    '`on:pipeline_run:<id>`. Prefer an event to a timer when one fits. '
    '`note`: what your future self needs: what you were waiting for, what to '
    'check first, what to do next. It comes back to you as your own note. A '
    'repeating wake needs `max_runs` or `expires_in`, and ends after 7 days '
    'unless a person extends it. The result says when it fires and whether '
    'the prompt cache will still be warm then. A wake inside the cache '
    'window is cheap; one after it re-reads the conversation. You are woken '
    'without asking when an agent you asked or delegated to finishes.\n'
    '\n'
    'Grammar: $wakeWhenGrammar\n'
    '\n'
    'Limits: every: is 60 s or more apart. max_runs is at most 500 (50 for '
    'a repeating wake that gives only expires_in; 10 for a watch). '
    'expires_in is at most 30d (default 7d); a one-off is at most 30 days '
    'ahead and still fires up to a day late. Each run is capped at 5 USD; '
    'a wake ends when its runs cost its cap (50 USD unless the workspace '
    'says otherwise). A slot missed while the server was down is skipped, '
    'not replayed.\n'
    '\n'
    'Busy: when_busy "skip" (a timer\'s default) skips a fire that finds you '
    'still running and counts it; "queue" (a watch\'s default) waits until '
    'your run ends, then starts its own run. deliver "notify" posts the note '
    'for the person and starts no run.';

/// The call that cancels the rule [id], in a form its caller can use: from
/// a script when the caller's run has `repl` ([hasRepl]), since
/// `cancel_wake` is then script-only (it is in no mode's direct set), and
/// otherwise in plain words, which a harness run without `repl` calls
/// directly and a Claude Code or ACP run calls as an MCP tool under its own
/// name.
String cancelWakeCall(String id, {required bool hasRepl}) => toolCallText(
  hasRepl ? ToolCallForm.script : ToolCallForm.plain,
  'cancel_wake',
  'id: "$id"',
);

CallResult _refusal(String message, String kind, {bool reference = true}) =>
    CallResult(
      content: [
        CallResultContent(
          type: 'text',
          text: reference ? '$message\n\n$wakeMeReference' : message,
        ),
      ],
      isError: true,
      structured: {'kind': kind},
    );

String? _string(Map<String, dynamic> args, String key) {
  final value = args[key];
  return value is String && value.trim().isNotEmpty ? value.trim() : null;
}

Map<String, dynamic> _identityProps() => {
  'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
  'agent_id': {
    'type': 'string',
    'description': 'Your own agent id (filled from your run).',
  },
  'conversation_id': {
    'type': 'string',
    'description': "Your run's conversation (filled from your run).",
  },
};

/// The canonical error for the first identity argument a call lacks. The
/// three are spelled out in each schema's `required` list, which the
/// workspace_id ratchet reads as text.
CallResult _missingIdentity(String? workspaceId, String? agentId) =>
    CallResult.error(
      McpTool.missingArgument(
        workspaceId == null
            ? 'workspace_id'
            : agentId == null
            ? 'agent_id'
            : 'conversation_id',
      ),
    );

/// The calling run, when its scope is attested.
Future<AgentRunLog?> _callingRun(
  AgentRunLogRepository runs,
  String workspaceId,
  McpCallContext context,
) async {
  final scope = context.scope;
  final runId = scope?.attested == true ? scope?.runLogId : null;
  return runId == null ? null : runs.getById(workspaceId, runId);
}

/// `wake_me`: the calling agent arranges to be woken later in its own
/// conversation (plan section 9): at a time, on an interval, at its own pace
/// (`next`, inside a loop), or when something happens. The agent and the
/// conversation are forced from the run's scope; the rule acts for the
/// person the run acts for (none for a bot run).
class WakeMeTool extends McpScopedTool {
  /// Creates the tool. `cacheTtl` is the prompt-cache lifetime the
  /// conversation's last turn reported, when known.
  WakeMeTool({
    required this._service,
    required this._runs,
    required this._cacheTtl,
    required this._hasRepl,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final WakeRuleService _service;

  /// Whether the run of a scope has `repl` (`McpRunToolSurface.hasRepl`), so
  /// the result names `cancel_wake` in a form that run can call.
  final bool Function(McpCallScope scope) _hasRepl;
  final AgentRunLogRepository _runs;
  final Duration? Function(String workspaceId, String conversationId) _cacheTtl;
  final DateTime Function() _now;

  /// Runs that already received [wakeMeReference] (bounded).
  final Set<String> _referenced = <String>{};

  /// The most runs remembered as referenced.
  static const int maxReferencedRuns = 2048;

  @override
  String get name => 'wake_me';

  /// Setting a wake and ending the turn is a script's natural last step.
  @override
  bool get scriptCallable => true;

  @override
  Future<CallResult> callForRun(
    Map<String, dynamic> arguments,
    McpCallScope scope, {
    Future<void>? abandoned,
  }) =>
      callScoped(arguments, McpCallContext(scope: scope), abandoned: abandoned);

  @override
  Set<String> get forcedScopeKeys => const {'agent_id', 'conversation_id'};

  @override
  Set<String> get requiredScopeKeys => const {'agent_id', 'conversation_id'};

  /// The rule records which run made it and acts for that run's person.
  @override
  bool get requiresRunGrant => true;

  @override
  String get description =>
      'Arrange to be woken later instead of sleeping or polling: at a time, '
      'on an interval, at your own pace, or when something happens (a pull '
      "request's checks, a review, a merge, an environment, a ticket, a "
      'pipeline run).';

  @override
  String get resultNote =>
      'JSON {rule_id, when, fires_at, expires_at, max_runs, cancel, '
      'cache_warm, reference, watching, chain}: fires_at is null for a '
      'watch; cache_warm is present when the prompt cache lifetime is known; '
      'reference is on the first result of a run; a cron also gives its tz; '
      'watching (a pull request watch) says which pull request it hears; '
      'chain (a wake set in a run another wake started) is {root, '
      'runs_left, ends_at}: the chain shares its first wake\'s end and runs. '
      'With when "next": {rule_id, next_delay_seconds, cancel}.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      ..._identityProps(),
      'when': {
        'type': 'string',
        'description':
            'in:20m | at:<ISO time> | every:30m | cron:0 9 * * 1-5 | next | '
            'on:pr_checks | on:pr_review | on:pr_merged | on:environment | '
            'on:ticket:<id> | on:pipeline_run:<id>',
      },
      'note': {
        'type': 'string',
        'description':
            'What your future self needs (at most 4,000 characters).',
      },
      'max_runs': {'type': 'integer', 'description': 'Run cap, 1 to 500.'},
      'expires_in': {
        'type': 'string',
        'description': 'How long it lives, such as 2d (at most 30d).',
      },
      'when_busy': {
        'type': 'string',
        'enum': ['skip', 'queue'],
      },
      'deliver': {
        'type': 'string',
        'enum': ['run', 'notify'],
      },
      'delay': {
        'type': 'string',
        'description': 'With when "next": the delay, 1m to 1h.',
      },
      'tz': {
        'type': 'string',
        'description': "A cron's IANA time zone (default the workspace's).",
      },
    },
    'required': ['workspace_id', 'agent_id', 'conversation_id', 'when'],
  };

  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
    final ws = _string(arguments, 'workspace_id');
    final agentId = _string(arguments, 'agent_id');
    final conversationId = _string(arguments, 'conversation_id');
    final when = _string(arguments, 'when');
    final scope = context.scope;
    final hasRepl = scope != null && _hasRepl(scope);
    if (ws == null || agentId == null || conversationId == null) {
      return _missingIdentity(ws, agentId);
    }
    if (when == null) {
      return _refusal(
        'Say when: the when argument is missing.',
        WakeRuleRefusals.invalidWhen,
      );
    }
    final run = await _callingRun(_runs, ws, context);
    try {
      if (when == 'next') {
        return await _next(ws, run, arguments, hasRepl: hasRepl);
      }
      final maxRuns = arguments['max_runs'];
      if (maxRuns != null && maxRuns is! int) {
        return _refusal(
          'max_runs is a whole number.',
          WakeRuleRefusals.limitOutOfRange,
        );
      }
      final expiresRaw = _string(arguments, 'expires_in');
      final expiresIn = expiresRaw == null
          ? null
          : parseWakeDuration(expiresRaw);
      if (expiresRaw != null && expiresIn == null) {
        return _refusal(
          'expires_in "$expiresRaw" is not a duration (2d, 12h).',
          WakeRuleRefusals.invalidWhen,
        );
      }
      final whenBusy = switch (_string(arguments, 'when_busy')) {
        null => null,
        final raw =>
          WakeWhenBusyWire.tryParse(raw) ??
              (throw const ValidationException(
                'when_busy is "skip" or "queue".',
                code: WakeRuleRefusals.invalidWhen,
              )),
      };
      final deliver = switch (_string(arguments, 'deliver')) {
        null => WakeDeliver.run,
        final raw =>
          WakeDeliverWire.tryParse(raw) ??
              (throw const ValidationException(
                'deliver is "run" or "notify".',
                code: WakeRuleRefusals.invalidWhen,
              )),
      };
      final rule = await _service.create(
        WakeRuleRequest(
          workspaceId: ws,
          conversationId: conversationId,
          agentId: agentId,
          when: when,
          timeZone: _string(arguments, 'tz'),
          note: (arguments['note'] as String?) ?? '',
          origin: WakeRuleOrigin.agent,
          maxRuns: maxRuns as int?,
          expiresIn: expiresIn,
          whenBusy: whenBusy,
          deliver: deliver,
          createdByRunId: run?.id,
          requestedByUserId: run?.requestedByUserId,
        ),
      );
      final firesAt = _service.nextFireOf(rule);
      final ttl = _cacheTtl(ws, conversationId);
      final chain = await _service.lineageStatus(rule);
      final result = <String, Object?>{
        'rule_id': rule.id,
        'when': formatWakeWhen(rule.trigger),
        'tz': ?formatWakeZone(rule.trigger),
        'fires_at': firesAt?.toUtc().toIso8601String(),
        'expires_at': rule.expiresAt.toUtc().toIso8601String(),
        'max_runs': rule.maxRuns,
        'cancel': cancelWakeCall(rule.id, hasRepl: hasRepl),
        'watching': ?wakeWatching(rule.trigger),
        'chain': ?wakeChainJson(chain),
        if (ttl != null && firesAt != null)
          'cache_warm':
              !firesAt.difference(_now().toUtc()).isNegative &&
              firesAt.difference(_now().toUtc()) <= ttl,
        if (_firstFor(run?.id ?? 'unattested:$conversationId'))
          'reference': wakeMeReference,
      };
      return CallResult.success(jsonEncode(result));
    } on ValidationException catch (e) {
      return _refusal(e.message, e.code ?? WakeRuleRefusals.invalidWhen);
    } on WorkspaceMismatchException catch (e) {
      return _refusal(e.message, 'workspace_mismatch', reference: false);
    }
  }

  Future<CallResult> _next(
    String ws,
    AgentRunLog? run,
    Map<String, dynamic> arguments, {
    required bool hasRepl,
  }) async {
    final loop = run == null ? null : await _service.loopOfRun(ws, run.wakeIds);
    if (loop == null || loop.agentId != run?.agentId) {
      return _refusal(
        'next works only inside a run your self-paced loop started (a '
        'person\'s /loop without "every"); this run was not started by one. '
        'To be woken after a delay, use in:<duration>; to repeat, use every: '
        'with max_runs or expires_in.',
        WakeRuleRefusals.nextOutsideLoop,
      );
    }
    final raw = _string(arguments, 'delay');
    final delay = raw == null ? null : parseWakeDuration(raw);
    if (delay == null) {
      return _refusal(
        'With when "next", delay says how long to wait before the next run '
        '(1m to 1h), such as delay: "10m".',
        WakeRuleRefusals.nextOutsideLoop,
      );
    }
    final set = await _service.setNextDelay(ws, loop.id, delay);
    return CallResult.success(
      jsonEncode({
        'rule_id': loop.id,
        'next_delay_seconds': set.inSeconds,
        'cancel': cancelWakeCall(loop.id, hasRepl: hasRepl),
      }),
    );
  }

  bool _firstFor(String runKey) {
    if (_referenced.contains(runKey)) {
      return false;
    }
    _referenced.add(runKey);
    if (_referenced.length > maxReferencedRuns) {
      _referenced.remove(_referenced.first);
    }
    return true;
  }
}

/// `list_wakes`: what the calling agent has waiting in its conversation:
/// its rules (schedules, loops, watches), its pending wakes and its pending
/// asks of other agents.
class ListWakesTool extends McpScopedTool {
  /// Creates the tool.
  ListWakesTool({
    required this._service,
    required this._wakes,
    required this._asks,
    required this._runs,
  });

  final WakeRuleService _service;
  final WakeRepository _wakes;
  final PeerAskRepository _asks;
  final AgentRunLogRepository _runs;

  @override
  String get name => 'list_wakes';

  /// A read.
  @override
  bool get scriptCallable => true;

  @override
  Future<CallResult> callForRun(
    Map<String, dynamic> arguments,
    McpCallScope scope, {
    Future<void>? abandoned,
  }) =>
      callScoped(arguments, McpCallContext(scope: scope), abandoned: abandoned);

  @override
  Set<String> get forcedScopeKeys => const {'agent_id', 'conversation_id'};

  @override
  Set<String> get requiredScopeKeys => const {'agent_id', 'conversation_id'};

  @override
  String get description =>
      'List what you have waiting in this conversation: your scheduled and '
      'repeating wakes, event watches, pending wakes and unanswered '
      'questions to other agents.';

  @override
  String get resultNote =>
      'JSON {rows: [{type, id, when, fires_at, status, runs, max_runs, '
      'expires_at, what, can_cancel, chain}]}: type is "rule", "wake" or '
      '"ask"; can_cancel is true for what you made yourself; chain is '
      '{root, runs_left, ends_at} for a rule in a chain of wakes (null for '
      'others); pass type to list one kind.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      ..._identityProps(),
      'type': {
        'type': 'string',
        'enum': ['rule', 'wake', 'ask'],
        'description': 'Only rows of this type.',
      },
    },
    'required': ['workspace_id', 'agent_id', 'conversation_id'],
  };

  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
    final ws = _string(arguments, 'workspace_id');
    final agentId = _string(arguments, 'agent_id');
    final conversationId = _string(arguments, 'conversation_id');
    if (ws == null || agentId == null || conversationId == null) {
      return _missingIdentity(ws, agentId);
    }
    final only = _string(arguments, 'type');
    final rows = <Map<String, Object?>>[];
    try {
      final run = await _callingRun(_runs, ws, context);
      bool cancellable(WakeRule? rule) =>
          rule != null &&
          run != null &&
          wakeRuleCancellableBy(
            rule,
            agentId: agentId,
            conversationId: conversationId,
            requestedByUserId: run.requestedByUserId,
          );
      final rules = await _service.openRulesOf(
        ws,
        conversationId: conversationId,
        agentId: agentId,
      );
      if (only == null || only == 'rule') {
        for (final rule in rules) {
          rows.add(
            _ruleRow(
              rule,
              canCancel: cancellable(rule),
              chain: await _service.lineageStatus(rule),
            ),
          );
        }
      }
      if (only == null || only == 'wake') {
        final byId = {for (final r in rules) r.id: r};
        for (final wake in await _wakes.listForConversation(
          ws,
          conversationId,
          states: {WakeState.pending, WakeState.held},
        )) {
          if (wake.agentId == agentId) {
            rows.add(
              _wakeRow(wake, canCancel: cancellable(byId[wake.detail.ruleId])),
            );
          }
        }
      }
      if (only == null || only == 'ask') {
        for (final ask in await _asks.listPending(
          ws,
          askerAgentId: agentId,
          askerConversationId: conversationId,
        )) {
          rows.add({
            'type': 'ask',
            'id': ask.id,
            'when': null,
            'fires_at': null,
            'status': ask.status.wire,
            'runs': null,
            'max_runs': null,
            'expires_at': ask.expiresAt.toUtc().toIso8601String(),
            'what': 'a ${ask.kind.wire} to agent ${ask.recipientAgentId}',
            'can_cancel': false,
          });
        }
      }
    } on WorkspaceMismatchException catch (e) {
      return _refusal(e.message, 'workspace_mismatch', reference: false);
    }
    return CallResult.success(jsonEncode({'rows': rows}));
  }

  Map<String, Object?> _ruleRow(
    WakeRule rule, {
    required bool canCancel,
    required WakeLineageStatus? chain,
  }) => {
    'type': 'rule',
    'id': rule.id,
    'when': formatWakeWhen(rule.trigger),
    'fires_at': _service.nextFireOf(rule)?.toUtc().toIso8601String(),
    'status': rule.status.wire,
    'runs': rule.runCount,
    'max_runs': rule.maxRuns,
    'expires_at': rule.expiresAt.toUtc().toIso8601String(),
    'what': wakeRuleNoteGist(rule.note),
    'can_cancel': canCancel,
    'chain': wakeChainJson(chain),
  };

  Map<String, Object?> _wakeRow(Wake wake, {required bool canCancel}) => {
    'type': 'wake',
    'id': wake.id,
    'when': wake.detail.ruleId == null ? null : 'rule ${wake.detail.ruleId}',
    'fires_at': wake.notBefore.toUtc().toIso8601String(),
    'status': wake.state.wire,
    'runs': null,
    'max_runs': null,
    'expires_at': wake.expiresAt?.toUtc().toIso8601String(),
    'what': '[${wakeLabel(wake)}] ${wakeHeadline(wake)}',
    'can_cancel': canCancel,
  };
}

/// A chain of wakes as a tool result shows it: its first wake, the runs it
/// has left, when it ends. Null for a rule in none.
Map<String, Object?>? wakeChainJson(WakeLineageStatus? chain) => chain == null
    ? null
    : {
        'root': chain.rootRuleId,
        'runs_left': chain.runsLeft,
        'ends_at': chain.endsAt.toUtc().toIso8601String(),
      };

/// Which pull request a pull request watch hears, for the model: the named
/// one, or the space's own, which may not be open yet. Null for any other
/// trigger.
String? wakeWatching(WakeTrigger trigger) => switch (trigger) {
  final OnEvent on when OnEvent.isPullRequest(on.eventKind) =>
    on.pullRequest == null
        ? "this space's pull request: one opened from its branch, or one it "
              'reviews. If none is open yet, the watch waits for one.'
        : 'pull request ${on.pullRequest} only.',
  _ => null,
};

/// Whether the agent [agentId], in a run acting for [requestedByUserId]
/// (null: a bot run), may cancel [rule] with `cancel_wake`: only a rule it
/// made itself in [conversationId], for the same person. A person's rule, a
/// goal's or a peer's wake, and anything made for someone else is not its
/// to cancel.
bool wakeRuleCancellableBy(
  WakeRule rule, {
  required String agentId,
  required String conversationId,
  required String? requestedByUserId,
}) =>
    rule.agentId == agentId &&
    rule.conversationId == conversationId &&
    rule.origin == WakeRuleOrigin.agent &&
    rule.requestedByUserId == requestedByUserId;

/// `cancel_wake`: cancels a rule the calling agent made itself in its
/// conversation, for the person its run acts for ([wakeRuleCancellableBy]),
/// by the rule's id or its pending wake's. Anything else (another agent's, a
/// person's rule, a wake a goal, a peer or a recovery wrote) is "not found";
/// a rule that already fired, ended or was cancelled is a success that says
/// so.
class CancelWakeTool extends McpScopedTool {
  /// Creates the tool.
  CancelWakeTool({
    required this._service,
    required this._wakes,
    required this._runs,
  });

  final WakeRuleService _service;
  final WakeRepository _wakes;
  final AgentRunLogRepository _runs;

  @override
  String get name => 'cancel_wake';

  /// A script that set wakes may cancel them.
  @override
  bool get scriptCallable => true;

  /// Whose rules the run may cancel depends on the person it acts for.
  @override
  bool get requiresRunGrant => true;

  @override
  Future<CallResult> callForRun(
    Map<String, dynamic> arguments,
    McpCallScope scope, {
    Future<void>? abandoned,
  }) =>
      callScoped(arguments, McpCallContext(scope: scope), abandoned: abandoned);

  @override
  Set<String> get forcedScopeKeys => const {'agent_id', 'conversation_id'};

  @override
  Set<String> get requiredScopeKeys => const {'agent_id', 'conversation_id'};

  @override
  String get description =>
      'Cancel a wake you set yourself in this conversation (a scheduled or '
      'repeating wake or a watch) by its id from wake_me or list_wakes.';

  @override
  String get resultNote =>
      'JSON {id, type, cancelled, status}: cancelled is false when it had '
      'already settled; status then says how.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      ..._identityProps(),
      'id': {'type': 'string', 'description': 'The rule or wake id to cancel.'},
    },
    'required': ['workspace_id', 'agent_id', 'conversation_id', 'id'],
  };

  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
    final ws = _string(arguments, 'workspace_id');
    final agentId = _string(arguments, 'agent_id');
    final conversationId = _string(arguments, 'conversation_id');
    final id = _string(arguments, 'id');
    if (ws == null || agentId == null || conversationId == null) {
      return _missingIdentity(ws, agentId);
    }
    if (id == null) {
      return CallResult.error(McpTool.missingArgument('id'));
    }
    try {
      final run = await _callingRun(_runs, ws, context);
      if (run == null) {
        return _notFound(id);
      }
      WakeRule? rule;
      try {
        rule = await _service.require(ws, id);
      } on NotFoundException {
        rule = null;
      }
      if (rule == null) {
        // A rule's pending wake stands for the rule; a wake no rule of the
        // agent's wrote is not the agent's to cancel.
        final wake = await _wakes.getById(ws, id);
        final ruleId = wake?.detail.ruleId;
        if (wake == null ||
            ruleId == null ||
            wake.agentId != agentId ||
            wake.conversationId != conversationId) {
          return _notFound(id);
        }
        try {
          rule = await _service.require(ws, ruleId);
        } on NotFoundException {
          return _notFound(id);
        }
      }
      if (!wakeRuleCancellableBy(
        rule,
        agentId: agentId,
        conversationId: conversationId,
        requestedByUserId: run.requestedByUserId,
      )) {
        return _notFound(id);
      }
      if (rule.status == WakeRuleStatus.ended) {
        return _done(
          rule.id,
          'rule',
          cancelled: false,
          status: 'ended (${rule.endReason?.wire ?? 'ended'})',
        );
      }
      final ended = await _service.end(
        ws,
        rule.id,
        WakeRuleEndReason.cancelled,
      );
      return _done(
        rule.id,
        'rule',
        cancelled: ended,
        status: ended ? 'cancelled' : 'ended',
      );
    } on WorkspaceMismatchException {
      return _notFound(id);
    }
  }

  static CallResult _notFound(String id) => _refusal(
    'No wake or wake rule $id of yours is in this conversation.',
    'wake_not_found',
    reference: false,
  );

  static CallResult _done(
    String id,
    String type, {
    required bool cancelled,
    required String status,
  }) => CallResult.success(
    jsonEncode({
      'id': id,
      'type': type,
      'cancelled': cancelled,
      'status': status,
    }),
  );
}
