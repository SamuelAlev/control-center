import 'dart:io';

import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/ports/goal_turn_text_port.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_review_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_verification_notice.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/dispatch/goal_activity.dart';
import 'package:cc_infra/src/dispatch/goal_changes.dart';
import 'package:cc_infra/src/dispatch/goal_owed_work.dart';
import 'package:cc_infra/src/dispatch/goal_turn_texts.dart';
import 'package:test/test.dart';

import 'fake_wake_repository.dart';

final _t0 = DateTime.utc(2026, 11, 19, 12);

AgentGoalRun _goal({
  String id = 'goal-1',
  String workspaceId = 'ws-1',
  GoalHold? hold,
  GoalVerification? verification,
  GoalContract? contract,
  GoalStartRefs? startRefs,
}) => AgentGoalRun(
  id: id,
  workspaceId: workspaceId,
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  userText: 'Ship the parser',
  costCapMicros: 20000000,
  hold: hold,
  verification: verification,
  contract: contract,
  startRefs: startRefs,
  createdAt: _t0,
  updatedAt: _t0,
);

const _sha1 = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

Wake _wake(
  String id, {
  String workspaceId = 'ws-1',
  String agentId = 'agent-1',
  WakeReason reason = WakeReason.peerReply,
  String? goalId,
  Map<String, Object?> fields = const {},
}) => Wake(
  id: id,
  workspaceId: workspaceId,
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  agentId: agentId,
  reason: reason,
  payload: 'p',
  detail: WakeDetail(goalId: goalId, fields: fields),
  dedupKey: id,
  notBefore: _t0,
  createdAt: _t0,
);

class _Rules implements WakeRuleRepository {
  _Rules(this.rules);

  final List<WakeRule> rules;

  @override
  Future<List<WakeRule>> listForConversation(
    String workspaceId,
    String conversationId, {
    Set<WakeRuleStatus>? statuses,
  }) async => [
    for (final r in rules)
      if (r.workspaceId == workspaceId &&
          r.conversationId == conversationId &&
          (statuses == null || statuses.contains(r.status)))
        r,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

WakeRule _rule(String id, WakeTrigger trigger) => WakeRule(
  id: id,
  workspaceId: 'ws-1',
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  trigger: trigger,
  note: 'check',
  costCapMicros: 1000000,
  expiresAt: _t0.add(const Duration(days: 1)),
  origin: WakeRuleOrigin.agent,
  createdAt: _t0,
  updatedAt: _t0,
);

class _Goals implements AgentGoalRunRepository {
  final rows = <String, AgentGoalRun>{};

  @override
  Future<AgentGoalRun?> getById(String workspaceId, String id) async {
    final g = rows[id];
    return g != null && g.workspaceId == workspaceId ? g : null;
  }

  @override
  Future<AgentGoalRun?> getActiveForAgent(
    String workspaceId,
    String agentId,
  ) async => rows.values
      .where(
        (g) =>
            g.workspaceId == workspaceId &&
            g.agentId == agentId &&
            g.status == AgentGoalStatus.active,
      )
      .firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Conversations implements ConversationRepository {
  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async => workspaceId != 'ws-1'
      ? null
      : Conversation(
          id: conversationId,
          workspaceId: workspaceId,
          spaceId: 'sp-1',
          title: 't',
          createdAt: _t0,
          updatedAt: _t0,
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Filesystem implements WorkspaceFilesystemPort {
  _Filesystem(this.root);

  final String root;

  @override
  Future<String> spaceDir(String workspaceId, String spaceId) async =>
      '$root/$workspaceId/$spaceId';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Todos implements TodoRepository {
  final items = <TodoItem>[];

  @override
  Future<List<TodoItem>> list(
    String workspaceId,
    String conversationId,
  ) async => [
    for (final i in items)
      if (i.workspaceId == workspaceId && i.conversationId == conversationId) i,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoalVerification _failedRound() => GoalVerification(
  round: 1,
  claimSummary: 'Parser shipped',
  checks: [
    GoalCheckResult(
      run: 'make test',
      where: GoalCheckLocation.worktree,
      exitCode: 1,
      outputTail: 'FAILED parser_test',
    ),
  ],
  at: _t0,
);

void main() {
  group('segment activity (A2)', () {
    Set<ActionClass>? mcp(String name) => switch (name) {
      'create_ticket' => {ActionClass.processSpawn},
      'get_ticket' => const <ActionClass>{},
      _ => null,
    };

    test('the same successful state-changing calls twice have one digest; '
        'the same command after an edit is new', () {
      const bash = RunToolCall(
        name: 'bash',
        arguments: {'command': 'make test'},
        ok: true,
      );
      const edit = RunToolCall(
        name: 'Edit',
        arguments: {'file_path': 'a.dart'},
        ok: true,
      );
      final first = SegmentActivity.of(const [bash], mcpClassesOf: mcp);
      final again = SegmentActivity.of(const [bash], mcpClassesOf: mcp);
      final afterEdit = SegmentActivity.of(const [
        edit,
        bash,
      ], mcpClassesOf: mcp);
      expect(first.progressAgainst(null), isTrue);
      expect(again.progressAgainst(first.digest), isFalse);
      expect(afterEdit.progressAgainst(again.digest), isTrue);
    });

    test('reads, unknown tools and failed calls are not progress', () {
      final reads = SegmentActivity.of(const [
        RunToolCall(name: 'web_fetch', arguments: {'url': 'x'}, ok: true),
        RunToolCall(name: 'Read', arguments: {'p': 'a'}, ok: true),
        RunToolCall(
          name: 'mcp__control-center__get_ticket',
          arguments: {},
          ok: true,
        ),
      ], mcpClassesOf: mcp);
      expect(reads.anyCall, isTrue);
      expect(reads.digest, isNull);
      expect(reads.progressAgainst(null), isFalse);
      final failed = SegmentActivity.of(const [
        RunToolCall(name: 'write', arguments: {'p': 'a'}, ok: false),
      ], mcpClassesOf: mcp);
      expect(failed.progressAgainst(null), isFalse);
      final none = SegmentActivity.of(const [], mcpClassesOf: mcp);
      expect(none.anyCall, isFalse);
    });

    test('an MCP tool counts by its declared classes, whatever the prefix', () {
      expect(
        bareToolName('mcp__control-center__create_ticket'),
        'create_ticket',
      );
      expect(bareToolName('create_ticket'), 'create_ticket');
      expect(
        toolChangesState('mcp__cc__create_ticket', mcpClassesOf: mcp),
        isTrue,
      );
      expect(
        toolChangesState('mcp__cc__get_ticket', mcpClassesOf: mcp),
        isFalse,
      );
    });

    test('the record is per workspace, read once, and bounded', () {
      final activity = RunToolActivity(capacity: 2);
      const call = RunToolCall(name: 'bash', arguments: {}, ok: true);
      for (final run in ['a', 'b', 'c']) {
        activity.record(workspaceId: 'ws-1', runId: run, calls: const [call]);
      }
      expect(activity.take(workspaceId: 'ws-1', runId: 'a'), isNull);
      expect(activity.take(workspaceId: 'ws-2', runId: 'b'), isNull);
      expect(activity.take(workspaceId: 'ws-1', runId: 'b'), hasLength(1));
      expect(activity.take(workspaceId: 'ws-1', runId: 'b'), isNull);
    });
  });

  group('owed work', () {
    test('counts the agent\'s other wakes in the conversation, not the '
        'goal\'s own, another agent\'s or another workspace\'s', () async {
      final wakes = FakeWakeRepository();
      for (final w in [
        _wake('own', reason: WakeReason.goalContinuation, goalId: 'goal-1'),
        _wake('other-agent', agentId: 'agent-2'),
        _wake('elsewhere', workspaceId: 'ws-2'),
      ]) {
        await wakes.insertIfAbsent(w);
      }
      var asked = <String>[];
      final owed = GoalOwedWork(
        wakes: wakes,
        rules: null,
        asks: null,
        openDelegations:
            (ws, {required conversationId, required agentId}) async {
              asked = [ws, conversationId, agentId];
              return const [];
            },
      );
      final none = await owed.of(_goal());
      expect(none.isOwed, isFalse);
      expect(asked, ['ws-1', 'conv-1', 'agent-1']);
      await wakes.insertIfAbsent(_wake('reply'));
      final some = await owed.of(_goal());
      expect(some.isOwed, isTrue);
      expect(some.wakes.single.id, 'reply');
      expect(some.describe(), '1 pending wake(s)');
    });

    test('a held wake is not owed work (only a person releases it), and a '
        "repeating or self-paced rule's wake or rule is not either; a one-off "
        'or event rule is', () async {
      final wakes = FakeWakeRepository();
      await wakes.insertIfAbsent(_wake('held'));
      await wakes.hold('ws-1', ids: ['held'], reason: 'stopped');
      final rules = _Rules([
        _rule('every', Every(const Duration(hours: 1))),
        _rule('cron', Cron('0 9 * * *', 'UTC')),
        _rule('paced', const SelfPaced()),
        _rule('once', OnceAt(_t0.add(const Duration(hours: 2)))),
        _rule('watch', OnEvent(WakeEventKind.prMerged)),
      ]);
      await wakes.insertIfAbsent(
        _wake('tick').copyWith(detail: WakeDetail(ruleId: 'every')),
      );
      await wakes.insertIfAbsent(
        _wake('noon').copyWith(detail: WakeDetail(ruleId: 'once')),
      );
      final owed = await GoalOwedWork(
        wakes: wakes,
        rules: rules,
        asks: null,
        openDelegations: null,
      ).of(_goal());
      expect(owed.wakes.map((w) => w.id), ['noon']);
      expect(owed.rules.map((r) => r.id), unorderedEquals(['once', 'watch']));
      // The rule's pending wake is the rule's work, not a second piece.
      expect(owed.setUp, ['rule:once', 'rule:watch']);
      expect(
        [
          for (final t in [
            Every(const Duration(hours: 1)),
            Cron('0 9 * * *', 'UTC'),
            const SelfPaced(),
            OnceAt(_t0),
            OnEvent(WakeEventKind.prMerged),
          ])
            triggerRepeats(t),
        ],
        [true, true, true, false, false],
      );
    });

    test('open delegations are owed work, keyed by ticket', () async {
      final owed = GoalOwedWork(
        wakes: FakeWakeRepository(),
        rules: null,
        asks: null,
        openDelegations:
            (ws, {required conversationId, required agentId}) async => [
              't-2',
              't-1',
            ],
      );
      final result = await owed.of(_goal());
      expect(result.isOwed, isTrue);
      expect(result.describe(), '2 open delegated ticket(s)');
      expect(result.setUp, ['ticket:t-1', 'ticket:t-2']);
    });

    test('a pending wake that delivers what the agent set up is that work; '
        'one that arrived on its own is not set up', () async {
      final wakes = FakeWakeRepository();
      for (final w in [
        _wake('reply').copyWith(detail: WakeDetail(askId: 'a-1')),
        _wake(
          'done',
          reason: WakeReason.childCompleted,
        ).copyWith(detail: WakeDetail(ticketId: 't-1')),
        _wake('message', reason: WakeReason.peerMessage),
        _wake(
          'asked-me',
          reason: WakeReason.peerMessage,
        ).copyWith(detail: WakeDetail(askId: 'theirs')),
      ]) {
        await wakes.insertIfAbsent(w);
      }
      final owed = await GoalOwedWork(
        wakes: wakes,
        rules: null,
        asks: null,
        openDelegations: null,
      ).of(_goal());
      expect(owed.wakes, hasLength(4));
      expect(owed.isOwed, isTrue);
      expect(owed.setUp, ['ask:a-1', 'ticket:t-1']);
    });
  });

  group('goal turn texts', () {
    late _Goals goals;
    late _Todos todos;
    late Directory root;
    late GoalTurnTexts texts;

    setUp(() {
      goals = _Goals();
      todos = _Todos();
      root = Directory.systemTemp.createTempSync('goal_parts_');
      texts = GoalTurnTexts(
        goals: goals,
        changes: GoalChanges(
          conversations: _Conversations(),
          filesystem: _Filesystem(root.path),
          todos: todos,
          git: (args, {required workingDirectory}) async => ProcessResult(
            0,
            0,
            args.first == 'diff' ? ' a.dart | 3 ++-' : '',
            '',
          ),
        ),
        now: () => _t0,
      );
    });

    tearDown(() => root.deleteSync(recursive: true));

    Future<GoalTurnText?> forWakes(
      List<Wake> wakes, {
      String workspaceId = 'ws-1',
      bool hasRepl = false,
    }) => texts.forRun(
      workspaceId: workspaceId,
      agentId: 'agent-1',
      conversationId: 'conv-1',
      wakeContext: WakeContext.fromWakes(wakes, nonce: 'nonce1'),
      hasRepl: hasRepl,
    );

    test('a segment wake gets the goal block with its audit, every transport '
        'alike', () async {
      goals.rows['goal-1'] = _goal();
      final text = await forWakes([
        _wake('w', reason: WakeReason.goalContinuation, goalId: 'goal-1'),
      ]);
      expect(text!.section, contains('## Your goal'));
      expect(text.section, contains('Ship the parser'));
      expect(text.wakeItems, isEmpty);
      final repl = await forWakes([
        _wake('w', reason: WakeReason.goalContinuation, goalId: 'goal-1'),
      ], hasRepl: true);
      expect(repl!.section, isNot(text.section));
    });

    test(
      'a verification wake becomes the failed-verification notice',
      () async {
        goals.rows['goal-1'] = _goal(verification: _failedRound());
        final text = await forWakes([
          _wake('v', reason: WakeReason.goalVerification, goalId: 'goal-1'),
        ]);
        expect(text!.wakeItems['v'], contains(goalVerificationFailedTag));
        expect(text.wakeItems['v'], contains('nonce1'));
      },
    );

    test('a review wake gets the review prompt with what changed', () async {
      Directory('${root.path}/ws-1/sp-1/repos/app').createSync(recursive: true);
      goals.rows['goal-1'] = _goal(
        hold: GoalHold.verifying,
        verification: GoalVerification(
          round: 1,
          claimSummary: 'Parser shipped',
          at: _t0,
        ),
        startRefs: GoalStartRefs({'app': _sha1}),
      );
      final text = await forWakes([
        _wake('r', reason: WakeReason.goalReview, goalId: 'goal-1'),
      ]);
      expect(
        text!.section,
        startsWith('$goalReviewHeading\n\n$goalReviewIntro'),
      );
      expect(text.section, contains('repos/app'));
      expect(text.section, contains('a.dart | 3 ++-'));
    });

    test('another workspace\'s goal, a closed goal, and an ordinary wake of '
        'a goal that does not wait get nothing', () async {
      goals.rows['goal-1'] = _goal();
      expect(
        await forWakes([
          _wake(
            'w',
            workspaceId: 'ws-2',
            reason: WakeReason.goalContinuation,
            goalId: 'goal-1',
          ),
        ], workspaceId: 'ws-2'),
        isNull,
      );
      expect(await forWakes([_wake('peer')]), isNull);
      goals.rows['goal-1'] = _goal().copyWith(
        status: AgentGoalStatus.completed,
      );
      expect(
        await forWakes([
          _wake('w', reason: WakeReason.goalContinuation, goalId: 'goal-1'),
        ]),
        isNull,
      );
    });

    test(
      'a goal that waits makes the first wake of its agent its segment',
      () async {
        goals.rows['goal-1'] = _goal(hold: GoalHold.waiting);
        final text = await forWakes([_wake('peer')]);
        expect(text!.section, contains('## Your goal'));
      },
    );
  });

  group('what changed since the goal started', () {
    test(
      'without a checkout, the checklist items changed since the start',
      () async {
        final todos = _Todos()
          ..items.addAll([
            TodoItem(
              id: 'old',
              workspaceId: 'ws-1',
              conversationId: 'conv-1',
              content: 'before',
              createdAt: _t0.subtract(const Duration(days: 1)),
              updatedAt: _t0.subtract(const Duration(days: 1)),
            ),
            TodoItem(
              id: 'new',
              workspaceId: 'ws-1',
              conversationId: 'conv-1',
              content: 'parser',
              createdAt: _t0.add(const Duration(minutes: 5)),
              updatedAt: _t0.add(const Duration(minutes: 5)),
            ),
          ]);
        final root = Directory.systemTemp.createTempSync('goal_changes_');
        addTearDown(() => root.deleteSync(recursive: true));
        final changes = GoalChanges(
          conversations: _Conversations(),
          filesystem: _Filesystem(root.path),
          todos: todos,
          git: (args, {required workingDirectory}) async =>
              throw StateError('no checkout, no git'),
        );
        expect(
          await changes.of(_goal()),
          'Checklist items added or changed since the goal started:\n'
          '- [pending] parser',
        );
        expect(await changes.of(_goal(workspaceId: 'ws-2')), '');
      },
    );

    GoalChanges withCheckouts(
      List<String> names,
      List<List<String>> seen, {
      ProcessResult Function(List<String> args)? answer,
    }) {
      final root = Directory.systemTemp.createTempSync('goal_changes_');
      addTearDown(() => root.deleteSync(recursive: true));
      for (final name in names) {
        Directory(
          '${root.path}/ws-1/sp-1/repos/$name',
        ).createSync(recursive: true);
      }
      return GoalChanges(
        conversations: _Conversations(),
        filesystem: _Filesystem(root.path),
        todos: null,
        git: (args, {required workingDirectory}) async {
          // Either separator: the lib joins with the host's (`\` on Windows).
          seen.add([workingDirectory.split(RegExp(r'[/\\]')).last, ...args]);
          return answer?.call(args) ??
              ProcessResult(
                0,
                0,
                args.first == 'status' ? '?? new.dart\n M a.dart\n' : '',
                '',
              );
        },
      );
    }

    test('the base is the commit recorded at the start, or the empty tree; '
        'a checkout added later says so', () async {
      final seen = <List<String>>[];
      final changes = withCheckouts(['app', 'empty', 'late'], seen);
      expect(
        await changes.of(
          _goal(
            startRefs: GoalStartRefs({
              'app': _sha1,
              'empty': GoalStartRefs.noCommit,
            }),
          ),
        ),
        'repos/app:\nNot tracked by git yet: new.dart\n\n'
        'repos/empty:\nNot tracked by git yet: new.dart\n\n'
        'repos/late:\nadded after the goal started',
      );
      expect(seen, [
        ['app', 'diff', '--stat', _sha1],
        ['app', 'status', '--porcelain', '--untracked-files=all'],
        ['app', 'diff', '--name-status', '--no-renames', '-z', _sha1],
        ['empty', 'diff', '--stat', GoalChanges.emptyTree],
        ['empty', 'status', '--porcelain', '--untracked-files=all'],
        [
          'empty',
          'diff',
          '--name-status',
          '--no-renames',
          '-z',
          GoalChanges.emptyTree,
        ],
      ]);
    });

    group('G3: tests and files the checks name', () {
      final start = GoalStartRefs({'app': _sha1});
      const testDiff =
          'diff --git a/test/upload_test.dart b/test/upload_test.dart\n'
          '--- a/test/upload_test.dart\n'
          '+++ b/test/upload_test.dart\n'
          '@@ -3 +3 @@\n'
          '-  expect(x, 42);\n'
          '+  expect(x, isNotNull);\n';

      /// git as a checkout whose [names] (`--name-status -z`) changed, each
      /// diff from [diffs] by path.
      ProcessResult Function(List<String>) gitWith(
        String names, {
        Map<String, String> diffs = const {},
        String stat = 'lib/a.dart | 2 +-\n',
      }) => (args) {
        if (args.contains('--stat')) {
          return ProcessResult(0, 0, stat, '');
        }
        if (args.contains('--name-status')) {
          return ProcessResult(0, 0, names, '');
        }
        if (args.first == 'diff') {
          return ProcessResult(0, 0, diffs[args.last] ?? '', '');
        }
        return ProcessResult(0, 0, '', '');
      };

      test('a modified test file\'s diff comes first, ahead of the stat; a '
          'deleted one is listed by name; other files get no diff', () async {
        final seen = <List<String>>[];
        final changes = withCheckouts(
          ['app'],
          seen,
          answer: gitWith(
            'M\x00lib/a.dart\x00M\x00test/upload_test.dart\x00'
            'D\x00src/old.spec.ts\x00',
            diffs: {'test/upload_test.dart': testDiff},
          ),
        );
        final text = await changes.of(_goal(startRefs: start));
        expect(
          text,
          '$goalReviewTestDiffHeading\n'
          'repos/app/test/upload_test.dart:\n'
          '${testDiff.trimRight()}\n'
          'repos/app/src/old.spec.ts: deleted\n'
          '\n'
          'repos/app:\n'
          'lib/a.dart | 2 +-',
        );
        final diffed = [
          for (final call in seen)
            if (call.contains('--')) call.last,
        ];
        expect(diffed, ['test/upload_test.dart']);
        expect(
          seen.firstWhere((c) => c.contains('--')),
          containsAll(['--no-textconv', '--no-color']),
        );
      });

      test('a file a check command names is included, and the file its '
          'runner reads', () async {
        final changes = withCheckouts(
          ['app'],
          [],
          answer: gitWith(
            'M\x00scripts/verify.sh\x00M\x00Makefile\x00M\x00lib/x.dart\x00',
            diffs: {
              'scripts/verify.sh': '-exit 1\n+exit 0\n',
              'Makefile': '-lint: analyze\n+lint:\n',
            },
          ),
        );
        final text = await changes.of(
          _goal(
            startRefs: start,
            contract: GoalContract(
              checks: [GoalCheck(run: './scripts/verify.sh && make lint')],
            ),
          ),
        );
        expect(text, startsWith(goalReviewTestDiffHeading));
        expect(
          text,
          contains('repos/app/scripts/verify.sh:\n-exit 1\n+exit 0'),
        );
        expect(text, contains('repos/app/Makefile:\n-lint: analyze'));
        expect(text, isNot(contains('repos/app/lib/x.dart:')));
        expect(
          GoalChanges.namedByChecks('Makefile', const ['make lint']),
          isTrue,
        );
        expect(
          GoalChanges.namedByChecks('lib/x.dart', const ['make lint']),
          isFalse,
        );
      });

      test('the cap cuts a file with a marker that says how many lines are '
          'missing; a later file is counted, not diffed', () async {
        final long = [for (var i = 0; i < 3000; i++) '+line $i'].join('\n');
        final changes = withCheckouts(
          ['app'],
          [],
          answer: gitWith(
            'M\x00test/a_test.go\x00M\x00test/b_test.go\x00',
            diffs: {'test/a_test.go': long, 'test/b_test.go': '+b\n'},
          ),
        );
        final text = await changes.of(_goal(startRefs: start));
        final section = text.substring(0, text.indexOf('\n\nrepos/app:\n'));
        expect(
          section.length,
          lessThanOrEqualTo(
            goalReviewTestDiffHeading.length + 1 + GoalChanges.maxTestDiffChars,
          ),
        );
        final kept = RegExp(
          r'^\+line \d+$',
          multiLine: true,
        ).allMatches(section).length;
        expect(kept, greaterThan(100));
        expect(
          section,
          contains(
            "[cut: ${3000 - kept} more lines of this file's diff not shown]",
          ),
        );
        expect(
          section,
          endsWith(
            '(and 1 more modified or deleted test or check file not '
            'listed: the limit was reached)',
          ),
        );
        expect(text, endsWith('repos/app:\nlib/a.dart | 2 +-'));
      });

      test('nothing changes for a goal that touched no test', () async {
        final changes = withCheckouts(
          ['app'],
          [],
          answer: gitWith('M\x00lib/a.dart\x00'),
        );
        expect(
          await changes.of(_goal(startRefs: start)),
          'repos/app:\nlib/a.dart | 2 +-',
        );
      });

      test('test paths across languages', () {
        for (final path in [
          'test/a.dart',
          'pkg/tests/x.py',
          'src/__tests__/a.js',
          'a_test.go',
          'test_upload.py',
          'web/a.spec.ts',
          'web/a.test.tsx',
          'src/FooTest.java',
          'src/BarTests.cs',
          'conftest.py',
          'ui/__snapshots__/a.snap',
          'spec/models/user_spec.rb',
        ]) {
          expect(GoalChanges.isTestPath(path), isTrue, reason: path);
        }
        for (final path in ['lib/a.dart', 'src/latest.ts', 'contest.py']) {
          expect(GoalChanges.isTestPath(path), isFalse, reason: path);
        }
      });
    });

    test('a goal whose start was not recorded gets no diff summary, never '
        'one by date', () async {
      final seen = <List<String>>[];
      final changes = withCheckouts(['app'], seen);
      expect(await changes.of(_goal()), '');
      expect(seen, isEmpty);
    });

    test(
      'a start commit that is gone gives that checkout no summary',
      () async {
        final seen = <List<String>>[];
        final changes = withCheckouts(
          ['app'],
          seen,
          answer: (args) => ProcessResult(0, 128, '', 'bad revision'),
        );
        expect(
          await changes.of(_goal(startRefs: GoalStartRefs({'app': _sha1}))),
          '',
        );
      },
    );

    test('startRefs records each checkout\'s HEAD, the empty entry for one '
        'without a commit, and nothing when one cannot be read', () async {
      final seen = <List<String>>[];
      final changes = withCheckouts(
        ['app', 'empty'],
        seen,
        answer: (args) => ProcessResult(0, 0, '$_sha1\n', ''),
      );
      expect(
        await changes.startRefs('ws-1', 'conv-1'),
        GoalStartRefs({'app': _sha1, 'empty': _sha1}),
      );
      expect(seen.first, [
        'app',
        'rev-parse',
        '--verify',
        '-q',
        'HEAD^{commit}',
      ]);
      final noCommit = withCheckouts(
        ['app'],
        [],
        answer: (args) => ProcessResult(0, 1, '', ''),
      );
      expect(
        await noCommit.startRefs('ws-1', 'conv-1'),
        GoalStartRefs({'app': GoalStartRefs.noCommit}),
      );
      final broken = withCheckouts(
        ['app'],
        [],
        answer: (args) => ProcessResult(0, 128, '', 'not a git repository'),
      );
      expect(await broken.startRefs('ws-1', 'conv-1'), isNull);
      expect(await broken.startRefs('ws-2', 'conv-1'), isNull);
      expect(await withCheckouts([], []).startRefs('ws-1', 'conv-1'), isNull);
    });
  });
}
