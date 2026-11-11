import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_templates.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// "Approve for 8 hours": what the card offers, what it writes, and what the
/// written approval may and may not answer.
void main() {
  const resolver = PolicyResolver();
  final now = DateTime.now();

  ActionPolicyRule rule(
    String id, {
    required ActionDecision decision,
    ActionScopeType scope = ActionScopeType.space,
    String? scopeId,
    ActionClass cls = ActionClass.fileDelete,
    ActionConstraint? constraint,
    bool remembered = false,
    DateTime? expiresAt,
  }) => ActionPolicyRule(
    id: id,
    workspaceId: 'ws',
    scopeType: scope,
    scopeId: scopeId ?? (scope == ActionScopeType.space ? 's1' : ''),
    actionClass: cls,
    decision: decision,
    provenance: remembered ? 'remembered' : 'user',
    constraint: constraint,
    expiresAt:
        expiresAt ?? (remembered ? now.add(const Duration(hours: 8)) : null),
    createdAt: now,
    updatedAt: now,
  );

  ActionPolicyRule standing({
    ActionScopeType scope = ActionScopeType.space,
    ActionClass cls = ActionClass.fileDelete,
    ActionConstraint constraint = const ActionConstraint(paths: ['/w/a/**']),
    DateTime? expiresAt,
  }) => rule(
    'standing',
    decision: ActionDecision.allow,
    scope: scope,
    cls: cls,
    constraint: constraint,
    remembered: true,
    expiresAt: expiresAt,
  );

  const inA = ActionRequest(paths: ['/w/a/x.txt']);

  PolicyResolution resolve(
    List<ActionPolicyRule> rules, {
    ActionRequest request = inA,
    ActionClass cls = ActionClass.fileDelete,
    Mode mode = Mode.chat,
  }) => resolver.resolveClass(
    cls,
    rules: rules,
    spaceId: 's1',
    agentId: 'a1',
    mode: mode,
    request: request,
    now: now,
  );

  group('resolver', () {
    test('answers the built-in ask for the class', () {
      final res = resolve([standing()]);
      expect(res.decision, ActionDecision.allow);
      expect(res.rule?.id, 'standing');
      expect(res.standingApproval?.id, 'standing');
    });

    test('outranks an equally specific ask at its own scope', () {
      final res = resolve([
        rule(
          'ask',
          decision: ActionDecision.prompt,
          constraint: const ActionConstraint(paths: ['/w/**']),
        ),
        standing(),
      ]);
      expect(res.decision, ActionDecision.allow);
    });

    test('answers an unconstrained ask at its own scope', () {
      final res = resolve([
        rule('ask', decision: ActionDecision.prompt),
        standing(),
      ]);
      expect(res.decision, ActionDecision.allow);
    });

    test('loses to a deny at its own scope', () {
      final res = resolve([
        rule('deny', decision: ActionDecision.deny),
        standing(),
      ]);
      expect(res.decision, ActionDecision.deny);
      expect(res.rule?.id, 'deny');
    });

    test('loses to a deny at a lower scope it would outrank as a rule', () {
      final res = resolve([
        rule(
          'deny',
          decision: ActionDecision.deny,
          scope: ActionScopeType.workspace,
          constraint: const ActionConstraint(paths: ['/w/a/x.txt']),
        ),
        standing(),
      ]);
      expect(res.decision, ActionDecision.deny);
    });

    test('loses to a mode preset that denies the class', () {
      final res = resolve(
        [standing(cls: ActionClass.processSpawn)],
        cls: ActionClass.processSpawn,
        mode: Mode.plan,
      );
      expect(res.decision, ActionDecision.deny);
    });

    test('does not answer the ask an unevaluable deny raises', () {
      final res = resolve(
        [
          rule(
            'deny-main',
            decision: ActionDecision.deny,
            scope: ActionScopeType.workspace,
            cls: ActionClass.gitPush,
            constraint: const ActionConstraint(refs: ['main']),
          ),
          standing(
            cls: ActionClass.gitPush,
            constraint: const ActionConstraint(commands: ['git push']),
          ),
        ],
        cls: ActionClass.gitPush,
        request: const ActionRequest(command: 'git push'),
      );
      expect(res.decision, ActionDecision.prompt);
      expect(res.standingApproval, isNull);
    });

    test('does not answer an ask from a scope that outranks its own', () {
      final res = resolve([
        rule('space-ask', decision: ActionDecision.prompt),
        standing(scope: ActionScopeType.workspace),
      ]);
      expect(res.decision, ActionDecision.prompt);
    });

    test('an expired one asks again', () {
      final res = resolve([
        standing(expiresAt: now.subtract(const Duration(seconds: 1))),
      ]);
      expect(res.decision, ActionDecision.prompt);
    });

    test('another directory asks again', () {
      final res = resolve([
        standing(),
      ], request: const ActionRequest(paths: ['/w/b/x.txt']));
      expect(res.decision, ActionDecision.prompt);
    });

    test('a command approval covers that command only, not a prefix', () {
      final approval = standing(
        cls: ActionClass.processSpawn,
        constraint: const ActionConstraint(commands: ['npm test']),
      );
      final ask = rule(
        'ask',
        decision: ActionDecision.prompt,
        cls: ActionClass.processSpawn,
      );
      expect(
        resolve(
          [ask, approval],
          cls: ActionClass.processSpawn,
          request: const ActionRequest(command: 'npm test'),
        ).decision,
        ActionDecision.allow,
      );
      expect(
        resolve(
          [ask, approval],
          cls: ActionClass.processSpawn,
          request: const ActionRequest(command: 'npm test && ./other.sh'),
        ).decision,
        ActionDecision.prompt,
      );
    });

    test('a tool approval covers that tool only', () {
      final approval = standing(
        cls: ActionClass.vendorSyncWrite,
        constraint: const ActionConstraint(tools: ['update_ticket']),
      );
      expect(
        resolve(
          [approval],
          cls: ActionClass.vendorSyncWrite,
          request: const ActionRequest(tool: 'update_ticket'),
        ).decision,
        ActionDecision.allow,
      );
      expect(
        resolve(
          [approval],
          cls: ActionClass.vendorSyncWrite,
          request: const ActionRequest(tool: 'delete_project'),
        ).decision,
        ActionDecision.prompt,
      );
    });

    test('a plain allow rule is not a standing approval', () {
      final res = resolver.resolveAction(
        {ActionClass.processSpawn},
        rules: [
          rule(
            'allow',
            decision: ActionDecision.allow,
            cls: ActionClass.processSpawn,
          ),
        ],
        spaceId: 's1',
        command: 'npm test',
        now: now,
      );
      expect(res.decision, ActionDecision.allow);
      expect(res.standingApprovals, isEmpty);
      expect(res.standingApprovalCovers(command: 'npm test'), isFalse);
    });

    test('a whole call is covered only when every class is', () {
      final spawn = standing(
        cls: ActionClass.processSpawn,
        constraint: const ActionConstraint(commands: ['npm install left-pad']),
      );
      final install = standing(
        cls: ActionClass.packageInstall,
        constraint: const ActionConstraint(commands: ['npm install left-pad']),
      );
      ActionResolution call(List<ActionPolicyRule> rules) =>
          resolver.resolveAction(
            {ActionClass.processSpawn, ActionClass.packageInstall},
            rules: rules,
            spaceId: 's1',
            command: 'npm install left-pad',
            now: now,
          );
      expect(
        call([spawn]).standingApprovalCovers(command: 'npm install left-pad'),
        isFalse,
      );
      expect(
        call([
          spawn,
          install,
        ]).standingApprovalCovers(command: 'npm install left-pad'),
        isTrue,
      );
    });

    test('an install-wide ask is neither answered nor offered', () {
      final res = resolver.resolveAction(
        {ActionClass.fileDelete},
        rules: [standing()],
        managedRules: [
          rule(
            'managed',
            decision: ActionDecision.prompt,
            scope: ActionScopeType.workspace,
          ),
        ],
        spaceId: 's1',
        request: inA,
        now: now,
      );
      expect(res.decision, ActionDecision.prompt);
      expect(res.rememberable, isFalse);
    });

    test('a command passed beside the request is what rules see', () {
      final res = resolver.resolveAction(
        {ActionClass.processSpawn},
        rules: [
          rule(
            'ask',
            decision: ActionDecision.prompt,
            cls: ActionClass.processSpawn,
          ),
          standing(
            cls: ActionClass.processSpawn,
            constraint: const ActionConstraint(commands: ['make docs']),
          ),
        ],
        spaceId: 's1',
        command: 'make docs',
        now: now,
      );
      expect(res.decision, ActionDecision.allow);
    });
  });

  group('the setting a permissions page shows for a class', () {
    final allowWithProtectedBranch = [
      rule('allow', decision: ActionDecision.allow, cls: ActionClass.gitPush),
      rule(
        'protect',
        decision: ActionDecision.deny,
        cls: ActionClass.gitPush,
        constraint: const ActionConstraint(refs: ['main']),
      ),
    ];

    test('is the plain rule, not the ask a conditional deny raises', () {
      // With no request nobody can tell whether the deny applies, so the
      // class reads as an ask; the page shows the setting and lists the deny.
      expect(
        resolver
            .resolveClass(
              ActionClass.gitPush,
              rules: allowWithProtectedBranch,
              spaceId: 's1',
            )
            .decision,
        ActionDecision.prompt,
      );
      final setting = resolver.resolveClassSetting(
        ActionClass.gitPush,
        rules: allowWithProtectedBranch,
        spaceId: 's1',
      );
      expect(setting.decision, ActionDecision.allow);
      expect(setting.rule?.id, 'allow');
    });

    test('ignores an approval of one branch family', () {
      final setting = resolver.resolveClassSetting(
        ActionClass.gitPush,
        rules: [
          standing(
            cls: ActionClass.gitPush,
            constraint: const ActionConstraint(refs: ['feature/**']),
          ),
        ],
        spaceId: 's1',
        now: now,
      );
      expect(setting.decision, ActionDecision.prompt);
      expect(setting.source, 'default');
    });

    test('is an approval of the class itself, a commit\'s, while it runs', () {
      // It covers the whole class, so the page shows the class as allowed and
      // names the approval as what decided.
      final rules = [
        rule('ask', decision: ActionDecision.prompt, cls: ActionClass.gitCommit),
        rule(
          'standing',
          decision: ActionDecision.allow,
          cls: ActionClass.gitCommit,
          remembered: true,
          expiresAt: now.add(const Duration(hours: 8)),
        ),
      ];
      expect(
        resolver
            .resolveClass(
              ActionClass.gitCommit,
              rules: rules,
              spaceId: 's1',
              now: now,
            )
            .decision,
        ActionDecision.allow,
      );
      final setting = resolver.resolveClassSetting(
        ActionClass.gitCommit,
        rules: rules,
        spaceId: 's1',
        now: now,
      );
      expect(setting.decision, ActionDecision.allow);
      expect(setting.rule?.isStandingApproval, isTrue);
      expect(
        resolver
            .resolveClassSetting(
              ActionClass.gitCommit,
              rules: rules,
              spaceId: 's1',
              now: now.add(const Duration(hours: 9)),
            )
            .rule
            ?.id,
        'ask',
      );
    });

    test('still falls back to a broader scope and the mode preset', () {
      final setting = resolver.resolveClassSetting(
        ActionClass.gitPush,
        rules: [
          rule(
            'workspace',
            decision: ActionDecision.deny,
            scope: ActionScopeType.workspace,
            cls: ActionClass.gitPush,
          ),
        ],
        spaceId: 's1',
      );
      expect(setting.decision, ActionDecision.deny);
      expect(setting.source, 'workspace');
      expect(
        resolver
            .resolveClassSetting(
              ActionClass.gitPush,
              rules: const [],
              mode: Mode.plan,
            )
            .source,
        'preset',
      );
    });
  });

  group('builder', () {
    ActionResolution policy(
      Set<ActionClass> classes, {
      ActionRequest request = ActionRequest.empty,
      String? command,
      List<ActionPolicyRule> rules = const [],
    }) => resolver.resolveAction(
      classes,
      rules: rules,
      spaceId: 's1',
      request: request,
      command: command,
      now: now,
    );

    ConfirmationRequest build(
      Set<ActionClass> classes, {
      ActionRequest request = ActionRequest.empty,
      String? command,
      bool askedByPolicy = true,
      ActionResolution? resolution,
      bool resolve = true,
    }) => ActionGuardService.approvalRequest(
      resolution: resolve
          ? resolution ?? policy(classes, request: request, command: command)
          : null,
      classes: classes,
      askedByPolicy: askedByPolicy,
      request: request,
      command: command,
      spaceId: 's1',
      workspaceId: 'ws',
      agentId: 'a1',
    );

    test('a tool call with paths remembers its directory and tool', () {
      final card = build(
        {ActionClass.fileDelete},
        request: const ActionRequest(
          paths: ['/w/a/x.txt'],
          tool: 'delete_file',
        ),
      );
      expect(card.rememberChoice, isNotNull);
      expect(card.actionClasses, ['fileDelete']);
      expect(
        ActionConstraint.decode(card.constraintJson),
        const ActionConstraint(paths: ['/w/a/**'], tools: ['delete_file']),
      );
    });

    test('a command remembers the exact command, for the classes that '
        'asked', () {
      final card = build({
        ActionClass.fileDelete,
        ActionClass.processSpawn,
      }, command: '  rm -rf build ');
      expect(card.actionClasses, ['fileDelete']);
      expect(
        ActionConstraint.decode(card.constraintJson),
        const ActionConstraint(commands: ['rm -rf build']),
      );
    });

    test('a push with a branch remembers the branch family only', () {
      final card = build(
        {ActionClass.gitPush},
        request: const ActionRequest(refs: ['feature/login']),
        command: 'git push origin feature/login',
      );
      expect(
        ActionConstraint.decode(card.constraintJson),
        const ActionConstraint(refs: ['feature/**']),
      );
    });

    test('a push without a branch remembers its exact command', () {
      final card = build({ActionClass.gitPush}, command: 'git push');
      expect(card.rememberChoice, isNotNull);
      expect(
        ActionConstraint.decode(card.constraintJson),
        const ActionConstraint(commands: ['git push']),
      );
    });

    test('a push with neither a branch nor a command offers nothing', () {
      final card = build({ActionClass.gitPush});
      expect(card.rememberChoice, isNull);
      expect(card.constraintJson, isNull);
    });

    test('a push among other effects is never remembered without a branch '
        'or command', () {
      final card = build({
        ActionClass.gitPush,
        ActionClass.fileDelete,
      }, request: const ActionRequest(paths: ['/w/a/x.txt']));
      expect(card.rememberChoice, isNull);
    });

    test('an MCP tool with no arguments remembers the tool, for every '
        'declared class', () {
      const classes = {ActionClass.vendorSyncWrite, ActionClass.prPublish};
      const request = ActionRequest(tool: 'sync_now');
      final card = build(
        classes,
        request: request,
        askedByPolicy: false,
        resolution: policy(
          classes,
          rules: [
            rule(
              'allow-sync',
              decision: ActionDecision.allow,
              scope: ActionScopeType.workspace,
              cls: ActionClass.vendorSyncWrite,
            ),
            rule(
              'allow-publish',
              decision: ActionDecision.allow,
              scope: ActionScopeType.workspace,
              cls: ActionClass.prPublish,
            ),
          ],
          request: request,
        ),
      );
      expect(card.rememberChoice, isNotNull);
      expect(
        card.actionClasses,
        unorderedEquals(['vendorSyncWrite', 'prPublish']),
      );
      expect(
        ActionConstraint.decode(card.constraintJson),
        const ActionConstraint(tools: ['sync_now']),
      );
    });

    test('a call with nothing to narrow it offers nothing', () {
      final card = build({ActionClass.fileDelete});
      expect(card.rememberChoice, isNull);
    });

    group('a commit', () {
      final askFirst = [
        rule(
          'ask',
          decision: ActionDecision.prompt,
          cls: ActionClass.gitCommit,
        ),
      ];
      const first = 'git commit -m "one"';
      // What the shell hook and the signing route hand over for a commit.
      const commits = ActionRequest(classes: {ActionClass.gitCommit});

      test('that something merely needs the capability for (a skill '
          'install) offers nothing', () {
        final card = build({
          ActionClass.gitCommit,
        }, resolution: policy({ActionClass.gitCommit}, rules: askFirst));
        expect(card.rememberChoice, isNull);
      });

      test('the policy asks about is remembered for the class alone: it has '
          'no branch or folder, and its command differs every time', () {
        final card = build(
          {ActionClass.gitCommit},
          request: commits,
          command: first,
          resolution: policy(
            {ActionClass.gitCommit},
            command: first,
            rules: askFirst,
          ),
        );
        expect(card.rememberChoice, isNotNull);
        expect(card.constraintJson, isNull);
        expect(card.actionClasses, ['gitCommit']);
      });

      test('approved for 8 hours covers the next one, whatever its message, '
          'and still loses to a deny', () {
        final approved = [
          ...askFirst,
          rule(
            'standing',
            decision: ActionDecision.allow,
            cls: ActionClass.gitCommit,
            remembered: true,
          ),
        ];
        ActionDecision next(List<ActionPolicyRule> rules) => policy(
          {ActionClass.gitCommit},
          command: 'git commit -m "two"',
          rules: rules,
        ).decision;
        expect(next(approved), ActionDecision.allow);
        expect(
          next([
            rule(
              'deny',
              decision: ActionDecision.deny,
              cls: ActionClass.gitCommit,
            ),
            approved.last,
          ]),
          ActionDecision.deny,
        );
      });

      test('a gate asks about on its own is remembered by its exact '
          'command', () {
        final card = build(
          {ActionClass.gitCommit},
          command: first,
          askedByPolicy: false,
        );
        expect(
          ActionConstraint.decode(card.constraintJson),
          const ActionConstraint(commands: [first]),
        );
      });

      test('among other effects is narrowed like any other call', () {
        final classes = {ActionClass.gitCommit, ActionClass.fileDelete};
        const request = ActionRequest(paths: ['/w/a/x.txt']);
        final card = build(
          classes,
          request: request,
          resolution: policy(classes, request: request, rules: askFirst),
        );
        expect(card.actionClasses, containsAll(['gitCommit', 'fileDelete']));
        expect(
          ActionConstraint.decode(card.constraintJson),
          const ActionConstraint(paths: ['/w/a/**']),
        );
      });

      test('is the only class that stands without a constraint', () {
        expect(
          ActionGuardService.standsWithoutConstraint(['gitCommit']),
          isTrue,
        );
        for (final cls in ActionClass.values) {
          if (cls == ActionClass.gitCommit) {
            continue;
          }
          expect(
            ActionGuardService.standsWithoutConstraint([cls.wire]),
            isFalse,
            reason: cls.wire,
          );
          expect(
            ActionGuardService.standsWithoutConstraint(['gitCommit', cls.wire]),
            isFalse,
            reason: cls.wire,
          );
        }
        expect(ActionGuardService.standsWithoutConstraint(const []), isFalse);
      });
    });

    test('without a policy answer nothing is offered', () {
      final card = build(
        {ActionClass.fileDelete},
        request: inA,
        resolve: false,
      );
      expect(card.rememberChoice, isNull);
    });

    test('a denied call offers nothing', () {
      final card = build(
        {ActionClass.fileDelete},
        request: inA,
        askedByPolicy: false,
        resolution: policy(
          {ActionClass.fileDelete},
          request: inA,
          rules: [rule('deny', decision: ActionDecision.deny)],
        ),
      );
      expect(card.rememberChoice, isNull);
    });

    test('an unevaluable deny offers nothing', () {
      final card = build(
        {ActionClass.gitPush},
        command: 'git push',
        resolution: policy(
          {ActionClass.gitPush},
          command: 'git push',
          rules: [
            rule(
              'deny-main',
              decision: ActionDecision.deny,
              scope: ActionScopeType.workspace,
              cls: ActionClass.gitPush,
              constraint: const ActionConstraint(refs: ['main']),
            ),
          ],
        ),
      );
      expect(card.rememberChoice, isNull);
    });
  });

  group('a gate that asks about a command on its own', () {
    late _Rules rules;
    late _Approver approver;
    late ActionGuardService guard;

    setUp(() {
      rules = _Rules();
      approver = _Approver();
      guard = ActionGuardService(repository: rules, confirmationPort: approver);
    });

    Future<bool> ask(String command) => ActionGuardService.confirmCommand(
      guard: guard,
      port: approver,
      workspaceId: 'ws',
      classes: {ActionClass.processSpawn},
      command: command,
      spaceId: 's1',
      agentId: 'a1',
    );

    test('is spared the same command after approving for 8 hours, not '
        'another', () async {
      expect(await ask('make deploy'), isTrue);
      final card = approver.requests.single;
      expect(card.actionClasses, ['processSpawn']);
      rules.remember(card);
      expect(await ask('make deploy'), isTrue);
      expect(approver.requests, hasLength(1));
      await ask('make deploy-all');
      expect(approver.requests, hasLength(2));
    });

    test('a policy deny is not turned into an allow', () async {
      await ask('make deploy');
      rules.remember(approver.requests.single);
      rules.list.add(
        rule(
          'deny',
          decision: ActionDecision.deny,
          scope: ActionScopeType.workspace,
          cls: ActionClass.processSpawn,
        ),
      );
      await ask('make deploy');
      expect(approver.requests, hasLength(2));
      expect(approver.requests.last.rememberChoice, isNull);
    });

    test('an expired approval asks again', () async {
      await ask('make deploy');
      rules.remember(
        approver.requests.single,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      await ask('make deploy');
      expect(approver.requests, hasLength(2));
    });

    test('without a guard nothing is consulted or offered', () async {
      await ActionGuardService.confirmCommand(
        guard: null,
        port: approver,
        workspaceId: 'ws',
        classes: {ActionClass.processSpawn},
        command: 'make deploy',
      );
      expect(approver.requests.single.rememberChoice, isNull);
    });
  });

  group('guard', () {
    late _Rules rules;
    late _Approver approver;
    late ActionGuardService guard;

    setUp(() {
      rules = _Rules();
      approver = _Approver();
      guard = ActionGuardService(repository: rules, confirmationPort: approver);
    });

    Future<GuardVerdict> push(String command, {List<String> refs = const []}) =>
        guard.check(
          workspaceId: 'ws',
          classes: {ActionClass.gitPush, ActionClass.processSpawn},
          command: command,
          spaceId: 's1',
          agentId: 'a1',
          request: ActionRequest(command: command, refs: refs),
        );

    test('after approving for 8 hours the same push does not ask again; '
        'another branch does', () async {
      await push('git push origin feature/a', refs: ['feature/a']);
      expect(approver.requests, hasLength(1));
      rules.remember(approver.requests.single);

      final again = await push(
        'git push origin feature/b',
        refs: ['feature/b'],
      );
      expect(again.allowed, isTrue);
      expect(approver.requests, hasLength(1));

      await push('git push origin main', refs: ['main']);
      expect(approver.requests, hasLength(2));
    });

    test('a command approval spares that command, not another', () async {
      await push('git push');
      rules.remember(approver.requests.single);
      await push('git push');
      expect(approver.requests, hasLength(1));
      await push('git push --force');
      expect(approver.requests, hasLength(2));
    });

    test('a deny still denies', () async {
      await push('git push origin feature/a', refs: ['feature/a']);
      rules.remember(approver.requests.single);
      rules.list.add(
        rule(
          'deny',
          decision: ActionDecision.deny,
          scope: ActionScopeType.workspace,
          cls: ActionClass.gitPush,
        ),
      );
      final verdict = await push(
        'git push origin feature/a',
        refs: ['feature/a'],
      );
      expect(verdict.allowed, isFalse);
      expect(approver.requests, hasLength(1));
    });

    test('an expired approval asks again', () async {
      await push('git push origin feature/a', refs: ['feature/a']);
      rules.remember(
        approver.requests.single,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      await push('git push origin feature/a', refs: ['feature/a']);
      expect(approver.requests, hasLength(2));
    });
  });

  group('rule identity', () {
    final plain = rule('plain', decision: ActionDecision.prompt);
    final approval = standing();

    test('a plain rule and a standing approval of one class differ', () {
      expect(plain.isPlain, isTrue);
      expect(approval.isPlain, isFalse);
      expect(plain.sharesIdentityWith(approval), isFalse);
      expect(approval.sharesIdentityWith(plain), isFalse);
    });

    test('two plain rules at one scope share it, whatever they decide', () {
      expect(
        plain.sharesIdentityWith(rule('other', decision: ActionDecision.deny)),
        isTrue,
      );
    });

    test('approving the same thing again shares it, another thing does '
        'not', () {
      expect(
        approval.sharesIdentityWith(
          standing(expiresAt: now.add(const Duration(hours: 9))),
        ),
        isTrue,
      );
      expect(
        approval.sharesIdentityWith(
          standing(constraint: const ActionConstraint(paths: ['/w/b/**'])),
        ),
        isFalse,
      );
      expect(
        approval.sharesIdentityWith(standing(scope: ActionScopeType.workspace)),
        isFalse,
      );
    });

    test('a person\'s conditioned rule is not an approval of the same '
        'condition', () {
      final conditioned = rule(
        'deny',
        decision: ActionDecision.deny,
        constraint: const ActionConstraint(paths: ['/w/a/**']),
      );
      expect(conditioned.sharesIdentityWith(approval), isFalse);
    });
  });

  test('an export leaves out rules that end', () {
    final exported = const PolicyTemplates().export([
      rule('plain', decision: ActionDecision.prompt),
      standing(),
      rule(
        'until',
        decision: ActionDecision.allow,
        expiresAt: now.add(const Duration(hours: 1)),
      ),
    ]);
    expect(exported, hasLength(1));
    expect(exported.single['decision'], 'prompt');
  });
}

/// Writes what `confirmation.respond` writes for a space-scoped remember.
class _Rules implements ActionPolicyRepository {
  final list = <ActionPolicyRule>[];

  void remember(ConfirmationRequest request, {DateTime? expiresAt}) {
    expect(request.rememberChoice, isNotNull);
    final now = DateTime.now();
    for (final wire in request.actionClasses) {
      list.add(
        ActionPolicyRule(
          id: 'remembered-$wire-${list.length}',
          workspaceId: request.workspaceId!,
          scopeType: ActionScopeType.space,
          scopeId: request.spaceId,
          actionClass: ActionClass.fromWire(wire),
          decision: ActionDecision.allow,
          provenance: 'remembered',
          constraint: ActionConstraint.decode(request.constraintJson),
          expiresAt: expiresAt ?? now.add(const Duration(hours: 8)),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => list;

  @override
  Stream<List<ActionPolicyRule>> watchRules(String workspaceId) =>
      Stream.value(list);

  @override
  Future<List<ActionPolicyRule>> rulesForScope(
    String workspaceId,
    ActionScopeType scopeType,
    String scopeId,
  ) async => list;

  @override
  Future<ActionPolicyRule?> ruleById(String workspaceId, String id) async =>
      null;

  @override
  Future<void> upsertRule(ActionPolicyRule rule) async => list.add(rule);

  @override
  Future<void> deleteRule(String workspaceId, String id) async =>
      list.removeWhere((r) => r.id == id);
}

class _Approver implements ConfirmationPort {
  final requests = <ConfirmationRequest>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    return true;
  }
}
