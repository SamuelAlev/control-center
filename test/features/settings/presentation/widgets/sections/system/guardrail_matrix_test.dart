import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_matrix.dart';
import 'package:control_center/features/settings/providers/guardrail_policy_providers.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:riverpod/misc.dart' show Override;

import '../../../../../../helpers/active_workspace.dart';
import '../../../../../../helpers/test_wrap.dart';

const _ws = 'ws-1';

/// Records writes instead of reaching a server.
class _FakeRepository implements ActionPolicyRepository {
  final upserts = <ActionPolicyRule>[];
  final deletes = <String>[];

  @override
  Future<void> upsertRule(ActionPolicyRule rule) async => upserts.add(rule);

  @override
  Future<void> deleteRule(String workspaceId, String id) async =>
      deletes.add(id);

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => const [];

  @override
  Stream<List<ActionPolicyRule>> watchRules(String workspaceId) =>
      const Stream.empty();

  @override
  Future<List<ActionPolicyRule>> rulesForScope(
    String workspaceId,
    ActionScopeType scopeType,
    String scopeId,
  ) async => const [];

  @override
  Future<ActionPolicyRule?> ruleById(String workspaceId, String id) async =>
      null;
}

/// An approval given on the approval card: "allow this, for the next hours".
ActionPolicyRule _approval({
  String id = 'approval-1',
  ActionClass actionClass = ActionClass.prPublish,
  required DateTime expiresAt,
  ActionConstraint? constraint,
  ActionScopeType scopeType = ActionScopeType.workspace,
  String scopeId = '',
  String? createdBy,
}) => ActionPolicyRule(
  id: id,
  workspaceId: _ws,
  scopeType: scopeType,
  scopeId: scopeId,
  actionClass: actionClass,
  decision: ActionDecision.allow,
  provenance: 'remembered',
  constraint: constraint,
  expiresAt: expiresAt,
  createdBy: createdBy,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// A rule set with the picker: permanent, for the whole class.
ActionPolicyRule _plain(String id, ActionClass cls, ActionDecision decision) =>
    ActionPolicyRule(
      id: id,
      workspaceId: _ws,
      scopeType: ActionScopeType.workspace,
      scopeId: '',
      actionClass: cls,
      decision: decision,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

DateTime _inHours(int hours) => DateTime.now().add(Duration(hours: hours));

const _pushToFeature = ActionConstraint(refs: ['feature/**']);

Future<_FakeRepository> _pump(
  WidgetTester tester,
  List<ActionPolicyRule> rules, {
  TextDirection? textDirection,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = _FakeRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeWorkspaceIdOverride(_ws),
        actionPolicyRepositoryProvider.overrideWithValue(repository),
        ...overrides,
      ],
      child: testWrap(
        SingleChildScrollView(
          child: GuardrailMatrix(
            rules: rules,
            currentScope: const (ActionScopeType.workspace, ''),
            scopeKind: ActionScopeType.workspace,
          ),
        ),
        textDirection: textDirection,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

/// The row (and the list under it) for the action labelled [label].
Finder _row(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(CcConfigRow));

/// The decision tag on the row labelled [label].
String _decision(WidgetTester tester, String label) {
  final tag = find.descendant(
    of: _row(label),
    matching: find.byType(CcStatusTag),
  );
  return tester.widget<CcStatusTag>(tag).label;
}

CcSelect<ActionDecision> _select(WidgetTester tester, String label) =>
    tester.widget<CcSelect<ActionDecision>>(
      find.descendant(
        of: _row(label),
        matching: find.byType(CcSelect<ActionDecision>),
      ),
    );

Finder _revokeButton(String entryText) => find.byWidgetPredicate(
  (w) => w is CcIconButton && w.semanticLabel == 'Revoke: $entryText',
);

String _endLabel(DateTime at) {
  final now = DateTime.now();
  final today =
      at.year == now.year && at.month == now.month && at.day == now.day;
  return today
      ? DateFormat.jm('en').format(at)
      : DateFormat.MMMd('en').add_jm().format(at);
}

const _publish = 'Update or merge a pull request';
const _push = 'Push to a remote';
const _commit = 'Create a commit';
const _feature = 'Allowed for branches \u2068feature/**\u2069';

void main() {
  testWidgets('an approval that is still running shows as allowed here', (
    tester,
  ) async {
    await _pump(tester, [_approval(expiresAt: _inHours(8))]);

    expect(_decision(tester, _publish), 'Allow');
    // The badge names what decided, not a rule someone set with the picker.
    expect(find.text('Standing approval'), findsOneWidget);
    expect(find.text('This scope'), findsNothing);
    expect(
      find.textContaining('Allowed for every action of this kind'),
      findsOneWidget,
    );
  });

  testWidgets('an approval that ran out is neither applied nor listed', (
    tester,
  ) async {
    await _pump(tester, [
      _approval(
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        actionClass: ActionClass.gitPush,
        constraint: _pushToFeature,
      ),
    ]);

    // Enforcement asks again once the approval expires, and so does the
    // matrix: the row is back on the built-in default with nothing listed.
    expect(_decision(tester, _push), 'Ask first');
    expect(find.textContaining('feature/**'), findsNothing);
    expect(find.byType(AppTimestamp), findsNothing);
    expect(_select(tester, _push).enabled, isTrue);
  });

  testWidgets(
    'an entry says what it allows, that it stands, and when it ends',
    (tester) async {
      final ends = _inHours(3);
      await _pump(tester, [
        _approval(
          actionClass: ActionClass.gitPush,
          constraint: _pushToFeature,
          expiresAt: ends,
        ),
      ]);

      final entry = find.textContaining(_feature);
      expect(entry, findsOneWidget);
      expect(find.textContaining('Standing approval · '), findsOneWidget);
      expect(find.text('ends ${_endLabel(ends)}'), findsOneWidget);
      expect(find.byType(AppTimestamp), findsOneWidget);
      // The class still asks first, and the row points at what gets through.
      expect(_decision(tester, _push), 'Ask first');
      expect(find.text('Allowed in 1 case listed below'), findsOneWidget);
    },
  );

  testWidgets('the picker writes the plain rule beside a standing approval', (
    tester,
  ) async {
    final repository = await _pump(tester, [
      _approval(
        actionClass: ActionClass.gitPush,
        constraint: _pushToFeature,
        expiresAt: _inHours(8),
      ),
    ]);

    // The approval is its own rule on the server: the picker stays usable
    // and writes only the plain rule.
    final select = _select(tester, _push);
    expect(select.enabled, isTrue);
    select.onChanged(ActionDecision.deny);
    await tester.pumpAndSettle();
    expect(repository.deletes, isEmpty);
    final written = repository.upserts.single;
    expect(
      written.id,
      stableActionPolicyRuleId(
        workspaceId: _ws,
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        actionClass: ActionClass.gitPush,
      ),
    );
    expect(written.provenance, 'user');
    expect(written.constraint, isNull);
    expect(written.expiresAt, isNull);
  });

  testWidgets('an approval of a denied action says it is not in effect', (
    tester,
  ) async {
    await _pump(tester, [
      _plain('plain-push', ActionClass.gitPush, ActionDecision.deny),
      _approval(
        actionClass: ActionClass.gitPush,
        constraint: _pushToFeature,
        expiresAt: _inHours(8),
      ),
    ]);

    // An approval spares a question; it never overrides a deny.
    expect(_decision(tester, _push), 'Deny');
    expect(
      find.textContaining('Standing approval · not in effect while denied'),
      findsOneWidget,
    );
    expect(find.textContaining('Allowed in'), findsNothing);
    // Still revocable.
    expect(_revokeButton(_feature), findsOneWidget);
  });

  testWidgets('a conditional rule is an exception under the row\'s setting', (
    tester,
  ) async {
    await _pump(tester, [
      _plain('plain-push', ActionClass.gitPush, ActionDecision.allow),
      ActionPolicyRule(
        id: 'protect-main',
        workspaceId: _ws,
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        actionClass: ActionClass.gitPush,
        decision: ActionDecision.deny,
        constraint: const ActionConstraint(refs: ['main']),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ]);

    // The row reads what the picker set, not the question a push with an
    // unknown branch would get; the tally counts the same.
    expect(_decision(tester, _push), 'Allow');
    expect(_select(tester, _push).value, ActionDecision.allow);
    expect(
      find.textContaining('Denied for branches \u2068main\u2069'),
      findsOneWidget,
    );
    expect(find.textContaining('not in effect'), findsNothing);
  });

  testWidgets('a person\'s conditional allow still applies under a deny', (
    tester,
  ) async {
    await _pump(tester, [
      _plain('plain-push', ActionClass.gitPush, ActionDecision.deny),
      ActionPolicyRule(
        id: 'allow-feature',
        workspaceId: _ws,
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        actionClass: ActionClass.gitPush,
        decision: ActionDecision.allow,
        constraint: _pushToFeature,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ]);

    expect(_decision(tester, _push), 'Deny');
    expect(find.text('Allowed in 1 case listed below'), findsOneWidget);
    expect(find.textContaining('not in effect'), findsNothing);
  });

  testWidgets('the picker writes the plain rule under its stable id', (
    tester,
  ) async {
    final repository = await _pump(tester, [
      // A plain rule from a template carries a random id.
      _plain('template-rule', ActionClass.gitCommit, ActionDecision.allow),
    ]);

    _select(tester, _commit).onChanged(ActionDecision.deny);
    await tester.pumpAndSettle();

    expect(repository.upserts, hasLength(1));
    final written = repository.upserts.single;
    expect(
      written.id,
      stableActionPolicyRuleId(
        workspaceId: _ws,
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        actionClass: ActionClass.gitCommit,
      ),
    );
    expect(written.decision, ActionDecision.deny);
    expect(written.provenance, 'user');
    expect(written.constraint, isNull);
    expect(written.expiresAt, isNull);
    expect(written.createdAt, DateTime(2025));
  });

  testWidgets('reset and clear all leave standing approvals alone', (
    tester,
  ) async {
    final repository = await _pump(tester, [
      _plain('plain-commit', ActionClass.gitCommit, ActionDecision.deny),
      _plain('plain-delete', ActionClass.fileDelete, ActionDecision.allow),
      _approval(
        id: 'approval-push',
        actionClass: ActionClass.gitPush,
        constraint: _pushToFeature,
        expiresAt: _inHours(8),
      ),
      _approval(id: 'approval-publish', expiresAt: _inHours(8)),
    ]);

    // The tally counts the picker's rules only.
    final summary = tester.widget<SettingsSummary>(
      find.byType(SettingsSummary),
    );
    expect(summary.facts.firstWhere((f) => f.label == 'Set here').value, '2');

    final reset = find.descendant(
      of: _row(_commit),
      matching: find.byWidgetPredicate(
        (w) => w is CcIconButton && w.semanticLabel == 'Clear to inherited',
      ),
    );
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(repository.deletes, ['plain-commit']);

    // No reset on a row whose only rule here is a standing approval.
    final pushReset = tester.widget<CcIconButton>(
      find.descendant(
        of: _row(_push),
        matching: find.byWidgetPredicate(
          (w) => w is CcIconButton && w.semanticLabel == 'Clear to inherited',
        ),
      ),
    );
    expect(pushReset.onPressed, isNull);

    repository.deletes.clear();
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(
      repository.deletes,
      unorderedEquals(['plain-commit', 'plain-delete']),
    );
  });

  testWidgets('revoke deletes exactly that approval', (tester) async {
    final repository = await _pump(tester, [
      _approval(
        id: 'approval-feature',
        actionClass: ActionClass.gitPush,
        constraint: _pushToFeature,
        expiresAt: _inHours(8),
      ),
      _approval(
        id: 'approval-release',
        actionClass: ActionClass.gitPush,
        constraint: const ActionConstraint(refs: ['release/*']),
        expiresAt: _inHours(2),
      ),
    ]);

    expect(find.text('Allowed in 2 cases listed below'), findsOneWidget);
    await tester.tap(_revokeButton(_feature));
    await tester.pumpAndSettle();
    expect(repository.deletes, ['approval-feature']);
    expect(repository.upserts, isEmpty);
  });

  testWidgets('names who gave an approval when it was somebody else', (
    tester,
  ) async {
    await _pump(
      tester,
      [
        _approval(
          id: 'from-alex',
          actionClass: ActionClass.gitPush,
          constraint: _pushToFeature,
          expiresAt: _inHours(8),
          createdBy: 'u-alex',
        ),
        _approval(id: 'mine', expiresAt: _inHours(8), createdBy: 'u-me'),
      ],
      overrides: [
        currentUserIdProvider.overrideWithValue('u-me'),
        usersByIdProvider.overrideWith(
          (ref) => Stream.value({
            'u-alex': UserDto(
              id: 'u-alex',
              handle: 'alex',
              displayName: 'Alex',
            ),
            'u-me': UserDto(id: 'u-me', handle: 'me', displayName: 'Me'),
          }),
        ),
      ],
    );

    expect(find.textContaining('by Alex'), findsOneWidget);
    expect(find.textContaining('by Me'), findsNothing);
  });

  testWidgets('command rules here are listed in their own group', (
    tester,
  ) async {
    final repository = await _pump(tester, [
      ActionPolicyRule(
        id: 'cmd-push',
        workspaceId: _ws,
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        commandPrefix: 'git push',
        decision: ActionDecision.deny,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ]);

    const entry = 'Denied for commands starting with \u2068git push\u2069';
    expect(find.text('Commands'), findsOneWidget);
    expect(find.textContaining('$entry · until revoked'), findsOneWidget);
    await tester.tap(_revokeButton(entry));
    await tester.pumpAndSettle();
    expect(repository.deletes, ['cmd-push']);
  });

  testWidgets('approvals for single spaces are counted on the workspace', (
    tester,
  ) async {
    await _pump(tester, [
      _approval(
        scopeType: ActionScopeType.space,
        scopeId: 'space-1',
        expiresAt: _inHours(8),
      ),
    ]);

    // Not listed (it does not apply to the workspace), but not hidden either.
    expect(find.textContaining('every action of this kind'), findsNothing);
    expect(
      find.text(
        '1 standing approval is set for a single space or agent. '
        'Pick Space or Agent above to see it.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an entry lays out right to left', (tester) async {
    await _pump(tester, [
      _approval(
        actionClass: ActionClass.gitPush,
        constraint: _pushToFeature,
        expiresAt: _inHours(8),
      ),
    ], textDirection: TextDirection.rtl);

    expect(tester.takeException(), isNull);
    final text = tester.getRect(find.textContaining(_feature));
    final revoke = tester.getRect(_revokeButton(_feature));
    // The revoke action sits at the end of the line, which is the left.
    expect(revoke.right, lessThanOrEqualTo(text.left));
  });
}
