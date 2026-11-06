import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_summary.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_evaluation_panel.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

const _hash =
    '501b48b9e634b33a58dfea5cd107e11a009019868820bf31a1ab2026b858aebe';
const _oldHash =
    '9f2c11d07ab3e64c58dfea5cd107e11a009019868820bf31a1ab2026b858aaaa';

SkillCampaignView _campaign({
  String id = 'c1',
  String hash = _hash,
  String status = 'completed',
  bool coverageComplete = true,
  String? staleReason,
}) => SkillCampaignView.fromWire({
  'id': id,
  'workspaceId': 'ws',
  'skillKey': 'workspace:reviewer',
  'skillSlug': 'reviewer',
  'skillHash': hash,
  'corpusId': 'utility',
  'providerId': 'codex',
  'modelId': 'gpt-5.6-terra',
  'configurationHash': 'cfg',
  'baselineHash': null,
  'repoId': null,
  'comparison': SkillCampaignComparison.values.first.name,
  'status': status,
  'repetitions': 3,
  'budgetMicros': 5000000,
  'plannedAttempts': 24,
  'completedAttempts': 24,
  'spentMicros': 1200000,
  'createdAt': '2026-11-01T10:00:00Z',
  'startedAt': null,
  'finishedAt': null,
  'actor': 'user:u1',
  'triggeredBy': 'manual',
  'staleReason': staleReason,
  'error': null,
  'configuration': <String, dynamic>{},
  'report': {'coverageComplete': coverageComplete},
});

SkillCampaignPolicyView _policy({required bool enabled}) =>
    SkillCampaignPolicyView.fromWire({
      'workspaceId': 'ws',
      'skillKey': 'workspace:reviewer',
      'enabled': enabled,
      'actor': 'user:u1',
      'configuration': <String, dynamic>{'corpusId': 'utility'},
      'updatedAt': '2026-11-01T10:00:00Z',
    });

class _FakeEvalsClient implements RpcEvalsClient {
  final calls = <({bool enabled, Map<String, dynamic> configuration})>[];

  @override
  Future<SkillCampaignPolicyView> setSkillPolicy({
    required String workspaceId,
    required String skillKey,
    required bool enabled,
    required Map<String, dynamic> configuration,
  }) async {
    calls.add((enabled: enabled, configuration: configuration));
    return _policy(enabled: enabled);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  Stream<List<SkillCampaignView>>? history,
  SkillCampaignPolicyView? policy,
  _FakeEvalsClient? client,
  String hash = _hash,
  bool dirty = false,
  bool demo = false,
  double width = 900,
  Locale locale = const Locale('en'),
  TextDirection? textDirection,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        skillCampaignClientProvider.overrideWithValue(
          client ?? _FakeEvalsClient(),
        ),
        skillCampaignsProvider((
          workspaceId: 'ws',
          skillKey: 'workspace:reviewer',
        )).overrideWith((ref) => history ?? Stream.value(const [])),
        skillCampaignPolicyProvider((
          workspaceId: 'ws',
          skillKey: 'workspace:reviewer',
        )).overrideWith((ref) async => policy),
      ],
      child: testWrap(
        SingleChildScrollView(
          child: SkillEvaluationPanel(
            workspaceId: 'ws',
            slug: 'reviewer',
            currentHash: hash,
            availableSkills: const ['reviewer'],
            dirty: dirty,
          ),
        ),
        locale: locale,
        textDirection: textDirection,
        isDemo: demo,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return AppLocalizations.of(tester.element(find.byType(SkillEvaluationPanel)));
}

CcSwitch _switch(WidgetTester tester) =>
    tester.widget<CcSwitch>(find.byType(CcSwitch));

CcButton _button(WidgetTester tester, String label) => tester.widget<CcButton>(
  find.ancestor(of: find.text(label), matching: find.byType(CcButton)),
);

void main() {
  testWidgets('an unevaluated revision states so and explains the locks', (
    tester,
  ) async {
    final l = await _pump(tester);

    expect(find.text(l.skillEvalNotEvaluated), findsOneWidget);
    expect(find.byType(SettingsSummary), findsNothing);
    expect(find.text(_hash), findsOneWidget);
    expect(find.text(l.skillEvalPolicyNeedsCampaign), findsOneWidget);
    expect(_switch(tester).onChanged, isNull);
    expect(_button(tester, l.skillEvalStart).onPressed, isNotNull);
  });

  testWidgets('unsaved edits explain why evaluating is blocked', (
    tester,
  ) async {
    final l = await _pump(
      tester,
      dirty: true,
      history: Stream.value([_campaign()]),
    );

    expect(find.text(l.skillEvalUnsaved), findsOneWidget);
    expect(_button(tester, l.skillEvalStart).onPressed, isNull);
    expect(_switch(tester).onChanged, isNull);
  });

  testWidgets('history that has not loaded claims nothing about evidence', (
    tester,
  ) async {
    final pending = StreamController<List<SkillCampaignView>>();
    addTearDown(pending.close);
    final l = await _pump(tester, history: pending.stream);

    expect(find.byType(CcSpinner), findsOneWidget);
    expect(find.text(l.skillEvalNotEvaluated), findsNothing);
    expect(find.text(l.skillEvalPolicyNeedsCampaign), findsNothing);
  });

  testWidgets('a failed history load is an error, not an unevaluated skill', (
    tester,
  ) async {
    final l = await _pump(tester, history: Stream.error(StateError('boom')));

    expect(find.byType(CcAlert), findsOneWidget);
    expect(find.text(l.skillEvalNotEvaluated), findsNothing);
    expect(_button(tester, l.skillEvalStart).onPressed, isNull);
  });

  testWidgets('a missing hash disables evaluation and hides the hash field', (
    tester,
  ) async {
    final l = await _pump(tester, hash: '');

    expect(
      find.widgetWithText(CcAlert, l.skillEvalHashUnavailable),
      findsOneWidget,
    );
    expect(find.text(l.skillEvalHashLabel), findsNothing);
    expect(find.text(l.skillEvalNotEvaluated), findsNothing);
    expect(_button(tester, l.skillEvalStart).onPressed, isNull);
  });

  testWidgets('only older revisions read as stale evidence', (tester) async {
    final l = await _pump(
      tester,
      history: Stream.value([_campaign(hash: _oldHash)]),
    );

    expect(find.text(l.skillEvalStale), findsOneWidget);
    expect(find.text(l.skillEvalNotEvaluated), findsOneWidget);
  });

  testWidgets('evidence for the installed revision fills the summary', (
    tester,
  ) async {
    final l = await _pump(
      tester,
      history: Stream.value([
        _campaign(coverageComplete: false),
        _campaign(id: 'old', hash: _oldHash, status: 'failed'),
      ]),
    );

    expect(find.text(l.skillEvalProgress(24, 24)), findsOneWidget);
    expect(find.text(l.skillEvalCoverage('utility', 3)), findsOneWidget);
    expect(find.text(_oldHash.substring(0, 12)), findsOneWidget);
    expect(find.text(l.skillEvalFailed), findsOneWidget);
    // Partial coverage never reads as completed, in the summary or the row.
    expect(find.text(l.skillEvalCompleted), findsNothing);
    expect(find.text(l.skillEvalPartial), findsOneWidget);
    expect(find.text(l.skillEvalIncomplete), findsOneWidget);
  });

  testWidgets('turning updates on sends the chosen configuration', (
    tester,
  ) async {
    final client = _FakeEvalsClient();
    await _pump(
      tester,
      client: client,
      history: Stream.value([_campaign()]),
      policy: _policy(enabled: false),
    );

    await tester.tap(find.byType(CcSwitch));
    await tester.pump();
    await tester.pump();

    expect(client.calls.single.enabled, isTrue);
    expect(client.calls.single.configuration['corpusId'], 'utility');
    expect(client.calls.single.configuration['skillSlug'], 'reviewer');
  });

  testWidgets('an active policy hides the configuration it cannot apply', (
    tester,
  ) async {
    final client = _FakeEvalsClient();
    final l = await _pump(
      tester,
      client: client,
      history: Stream.value([_campaign()]),
      policy: _policy(enabled: true),
    );

    expect(find.text(l.skillEvalPolicyTemplate), findsNothing);
    expect(_switch(tester).value, isTrue);

    await tester.tap(find.byType(CcSwitch));
    await tester.pump();
    await tester.pump();

    expect(client.calls.single.enabled, isFalse);
    expect(client.calls.single.configuration, {'corpusId': 'utility'});
  });

  testWidgets('a demo server keeps both controls locked', (tester) async {
    final l = await _pump(
      tester,
      demo: true,
      history: Stream.value([_campaign()]),
      policy: _policy(enabled: false),
    );

    expect(_button(tester, l.skillEvalStart).onPressed, isNull);
    expect(_switch(tester).onChanged, isNull);
    expect(_button(tester, l.skillEvalOpenQuality).onPressed, isNotNull);
  });

  testWidgets('a phone width stacks the actions under the evidence', (
    tester,
  ) async {
    final l = await _pump(
      tester,
      width: 360,
      history: Stream.value([_campaign(coverageComplete: false)]),
    );

    final heading = tester.getTopLeft(find.text(l.skillEvalTitle));
    final start = tester.getTopLeft(find.text(l.skillEvalStart));
    final hash = tester.getTopLeft(find.text(l.skillEvalHashLabel));
    expect(start.dy, greaterThan(heading.dy));
    expect(start.dy, greaterThan(hash.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL keeps the hash left to right and lays out cleanly', (
    tester,
  ) async {
    final l = await _pump(
      tester,
      locale: const Locale('ar'),
      textDirection: TextDirection.rtl,
      history: Stream.value([_campaign()]),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.widget<Text>(find.text(_hash)).textDirection,
      TextDirection.ltr,
    );
    // The heading starts at the right-hand edge in RTL.
    expect(
      tester.getTopRight(find.text(l.skillEvalTitle)).dx,
      greaterThan(tester.getTopRight(find.text(l.skillEvalStart)).dx),
    );
  });
}
