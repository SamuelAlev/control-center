/// The server's lines of the "Still in flight" block (plan section 12, D24;
/// section 17 "After a compaction"): the goal, the wake rules, the pending
/// asks and the stored keys, read from rows rather than from the model's
/// memory, each ending with the call that refreshes it.
///
/// The harness kernel adds its own lines (background commands, the
/// checklist), orders the kinds, caps the block at 1,500 characters and
/// writes it after every compaction of a built-in harness run
/// (`renderStillInFlightBlock`). The conversation lane renders the same
/// lines into a system row (`StillInFlightNotes`).
library;

import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_block.dart'
    show formatGoalUsd, goalMaxVerificationRounds;
import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart'
    show formatWakeDuration, formatWakeWhen;
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_harness/context.dart' show ToolCallForm, toolCallText;

/// A question an agent put to a person that nobody has answered yet.
typedef PendingPersonQuestion = ({String text, DateTime askedAt});

/// Where the lines' rows come from. Every read takes the workspace.
class StillInFlightPorts {
  /// Creates the ports.
  const StillInFlightPorts({
    required this.activeGoal,
    required this.rules,
    required this.pendingAsks,
    required this.messageText,
    required this.agentName,
    required this.personQuestions,
    required this.storedKeys,
  });

  /// The agent's active goal in the workspace, or null.
  final Future<AgentGoalRun?> Function(String workspaceId, String agentId)
  activeGoal;

  /// The conversation's wake rules (any status, newest first).
  final Future<List<WakeRule>> Function(
    String workspaceId,
    String conversationId,
  )
  rules;

  /// The asks the agent made from the conversation that are still pending.
  final Future<List<PeerAsk>> Function(
    String workspaceId,
    String agentId,
    String conversationId,
  )
  pendingAsks;

  /// A message's text (an ask's question), or null.
  final Future<String?> Function(String workspaceId, String messageId)
  messageText;

  /// An agent's display name, or null.
  final Future<String?> Function(String workspaceId, String agentId) agentName;

  /// The agent's unanswered questions to a person in the conversation.
  final Future<List<PendingPersonQuestion>> Function(
    String workspaceId,
    String agentId,
    String conversationId,
  )
  personQuestions;

  /// The keys the agent kept with code mode's `store()` in the conversation.
  final Future<List<String>> Function(
    String workspaceId,
    String agentId,
    String conversationId,
  )
  storedKeys;
}

/// Builds the server's lines of the "Still in flight" block.
class StillInFlightLines {
  /// Creates the builder. [localTime] renders a time in a line (`HH:MM UTC`
  /// by default, as wake frames write it).
  StillInFlightLines({
    required this.ports,
    String Function(DateTime at)? localTime,
    DateTime Function()? now,
  }) : _time = localTime ?? _hhmm,
       _now = now ?? DateTime.now;

  /// Where the rows come from.
  final StillInFlightPorts ports;
  final String Function(DateTime at) _time;
  final DateTime Function() _now;

  /// The most rules the `Wakes:` line names; the rest are counted.
  static const int maxRules = 6;

  /// The most asks and questions the `Asked:` line names.
  static const int maxAsks = 5;

  /// The most stored keys the `Stored:` line names (plan: 20).
  static const int maxStoredKeys = 20;

  /// How much of a question the `Asked:` line quotes (A11: 80 characters).
  static const int questionChars = 80;

  /// How much of a stored key the `Stored:` line shows.
  static const int storedKeyChars = 40;

  /// The characters a stored key may have to be printed; any other key is
  /// counted, not shown (a script chose it, and the block is the server's).
  static final RegExp printableKey = RegExp(r'^[A-Za-z0-9_.-]+$');

  /// The lines for [agentId] in [conversationId]: `Goal:`, `Wakes:`,
  /// `Asked:` and, with [stored], `Stored:`. A kind with nothing open has
  /// no line; a read that fails leaves its line out.
  Future<List<String>> linesFor({
    required String workspaceId,
    required String agentId,
    required String conversationId,
    required ToolCallForm style,
    required bool stored,
  }) async {
    final lines = <String>[];
    Future<void> add(Future<String?> Function() line) async {
      try {
        final text = await line();
        if (text != null) {
          lines.add(text);
        }
      } on Object {
        // A line is a convenience: the block goes out with the others.
      }
    }

    await add(() => _goal(workspaceId, agentId, conversationId, style));
    await add(() => _wakes(workspaceId, agentId, conversationId, style));
    await add(() => _asked(workspaceId, agentId, conversationId, style));
    if (stored) {
      await add(() => _stored(workspaceId, agentId, conversationId, style));
    }
    return lines;
  }

  /// How the refresh calls are written ([ToolCallForm]): a built-in
  /// harness run with `repl` calls them from a script
  /// (`await tools.goal_status({})`); any other run calls the tool by name
  /// (`goal_status`).
  static String _call(ToolCallForm style, String tool, [String? args]) =>
      toolCallText(style, tool, args);

  Future<String?> _goal(
    String workspaceId,
    String agentId,
    String conversationId,
    ToolCallForm style,
  ) async {
    final goal = await ports.activeGoal(workspaceId, agentId);
    if (goal == null ||
        goal.status != AgentGoalStatus.active ||
        goal.conversationId != conversationId ||
        goal.workspaceId != workspaceId) {
      return null;
    }
    final spent = formatGoalUsd(goal.costMicros < 0 ? 0 : goal.costMicros);
    final cap = formatGoalUsd(goal.costCapMicros);
    final round = goal.verificationRounds + 1;
    final hold = goal.hold;
    final held = hold == null ? '' : ', waiting (${hold.wire})';
    return 'Goal: segment ${goal.runCount + 1}, $spent of $cap USD, '
        'round $round of $goalMaxVerificationRounds$held '
        '→ ${_call(style, 'goal_status')}';
  }

  Future<String?> _wakes(
    String workspaceId,
    String agentId,
    String conversationId,
    ToolCallForm style,
  ) async {
    final rules = [
      for (final r in await ports.rules(workspaceId, conversationId))
        if (r.agentId == agentId &&
            r.workspaceId == workspaceId &&
            r.status != WakeRuleStatus.ended)
          r,
    ];
    if (rules.isEmpty) {
      return null;
    }
    final shown = [for (final r in rules.take(maxRules)) _rule(r)];
    final more = rules.length - shown.length;
    return 'Wakes: ${shown.join('; ')}${more > 0 ? '; +$more more' : ''} '
        '→ ${_call(style, 'list_wakes')}';
  }

  String _rule(WakeRule rule) {
    final when = switch (rule.trigger) {
      OnceAt() => 'once',
      final other => formatWakeWhen(other),
    };
    final label = noteLabel(rule.note);
    final facts = <String>[
      if (rule.status == WakeRuleStatus.paused) 'paused',
      if (rule.status == WakeRuleStatus.active && rule.nextFireAt != null)
        'next ${_time(rule.nextFireAt!)}',
      if (rule.maxRuns case final max?)
        'run ${(rule.runCount + 1).clamp(1, max)} of $max',
    ];
    return [
      when,
      if (label.isNotEmpty) '"$label"',
      if (facts.isNotEmpty) '(${facts.join(', ')})',
    ].join(' ');
  }

  /// A short label from the first words of a rule's [note]: at most three
  /// words and 24 characters.
  static String noteLabel(String note) {
    final words = note
        .replaceAll('"', "'")
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(3)
        .join(' ');
    if (words.length <= 24) {
      return words;
    }
    return '${words.substring(0, 23)}…';
  }

  Future<String?> _asked(
    String workspaceId,
    String agentId,
    String conversationId,
    ToolCallForm style,
  ) async {
    final asks = [
      for (final a in await ports.pendingAsks(
        workspaceId,
        agentId,
        conversationId,
      ))
        if (a.workspaceId == workspaceId &&
            a.askerAgentId == agentId &&
            a.askerConversationId == conversationId)
          a,
    ];
    final questions = await ports.personQuestions(
      workspaceId,
      agentId,
      conversationId,
    );
    if (asks.isEmpty && questions.isEmpty) {
      return null;
    }
    final items = <String>[];
    for (final ask in asks.take(maxAsks)) {
      final name =
          await ports.agentName(workspaceId, ask.recipientAgentId) ??
          'an agent';
      final messageId = ask.questionMessageId;
      final text = messageId == null
          ? null
          : await ports.messageText(workspaceId, messageId);
      final since = _time(ask.createdAt);
      final left = ask.expiresAt.difference(_now());
      final expires = left > Duration.zero
          ? 'expires in ${formatWakeDuration(left)}'
          : 'expiring now';
      items.add(
        [
          _oneLine(name),
          if (text != null && text.trim().isNotEmpty) '"${quote(text)}"',
          '(pending since $since, $expires)',
        ].join(' '),
      );
    }
    for (final q in questions.take(maxAsks - items.length.clamp(0, maxAsks))) {
      items.add(
        'a person "${quote(q.text)}" (unanswered since ${_time(q.askedAt)})',
      );
    }
    final more = asks.length + questions.length - items.length;
    final calls = <String>[
      if (asks.isNotEmpty) ...[
        'you will be woken',
        _call(
          style,
          'agent_activity',
          'agent_id: "${asks.first.recipientAgentId}"',
        ),
      ],
      if (asks.isEmpty) 'the answer comes back to you',
    ];
    return 'Asked: ${items.join('; ')}${more > 0 ? '; +$more more' : ''} '
        '→ ${calls.join('; ')}';
  }

  /// [text] on one line, cut to [questionChars] characters.
  static String quote(String text) {
    final line = _oneLine(text).replaceAll('"', "'");
    return line.length <= questionChars
        ? line
        : '${line.substring(0, questionChars)}…';
  }

  Future<String?> _stored(
    String workspaceId,
    String agentId,
    String conversationId,
    ToolCallForm style,
  ) async {
    final keys = [
      ...await ports.storedKeys(workspaceId, agentId, conversationId),
    ]..sort();
    if (keys.isEmpty) {
      return null;
    }
    final printable = [
      for (final k in keys)
        if (printableKey.hasMatch(k)) k,
    ];
    final other = keys.length - printable.length;
    final shown = [
      for (final k in printable.take(maxStoredKeys))
        k.length <= storedKeyChars
            ? '"$k"'
            : '"${k.substring(0, storedKeyChars)}…"',
    ];
    final more = printable.length - shown.length;
    final call = switch (style) {
      ToolCallForm.script => 'await load(key)',
      ToolCallForm.direct ||
      ToolCallForm.plain => 'load(key) in a repl script',
    };
    final parts = [
      if (shown.isNotEmpty) shown.join(', '),
      if (more > 0) '(+$more more)',
      if (other > 0)
        '($other ${other == 1 ? 'key' : 'keys'} with other characters)',
    ];
    return 'Stored: ${parts.join(' ')} → $call';
  }
}

String _oneLine(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

String _hhmm(DateTime at) {
  final utc = at.toUtc();
  return '${utc.hour.toString().padLeft(2, '0')}:'
      '${utc.minute.toString().padLeft(2, '0')} UTC';
}
