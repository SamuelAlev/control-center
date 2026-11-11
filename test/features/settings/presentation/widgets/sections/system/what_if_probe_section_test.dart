import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/what_if_probe_section.dart';
import 'package:control_center/features/settings/providers/guardrail_policy_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_wrap.dart';

ActionPolicyRule _rule({required String provenance, DateTime? expiresAt}) =>
    ActionPolicyRule(
      id: 'rule-1',
      workspaceId: 'ws-1',
      scopeType: ActionScopeType.workspace,
      scopeId: '',
      // The probe opens on "Delete a file".
      actionClass: ActionClass.fileDelete,
      decision: ActionDecision.allow,
      provenance: provenance,
      expiresAt: expiresAt,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Future<void> _pump(WidgetTester tester, List<ActionPolicyRule> rules) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workspaceActionPoliciesProvider.overrideWith(
          (ref) => Stream.value(rules),
        ),
      ],
      child: testWrap(const SingleChildScrollView(child: WhatIfProbeSection())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('names a standing approval as the source when one decides', (
    tester,
  ) async {
    await _pump(tester, [
      _rule(
        provenance: 'remembered',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      ),
    ]);

    expect(find.text('Standing approval · Workspace'), findsOneWidget);
  });

  testWidgets('names the scope of a rule set with the picker', (tester) async {
    await _pump(tester, [_rule(provenance: 'user')]);

    expect(find.text('Workspace'), findsOneWidget);
    expect(find.textContaining('Standing approval'), findsNothing);
  });
}
