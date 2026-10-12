import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_evaluation_dialog.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

Future<AppLocalizations> _open(
  WidgetTester tester, {
  bool nativeAvailable = true,
  bool rtl = false,
}) async {
  tester.view.physicalSize = const Size(1000, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        skillCorporaProvider('workspace').overrideWith(
          (ref) async => SkillCorporaView(
            corpora: const [
              SkillCorpusView(
                id: 'utility',
                name: 'Utility pilot',
                description: 'Fixture',
                taskCount: 24,
                tags: [],
              ),
            ],
            capabilities: SkillCampaignCapabilities(
              available: true,
              reason: null,
              backends: ['builtin', if (nativeAvailable) 'claude-cli'],
              unavailableBackends: nativeAvailable
                  ? const {}
                  : const {'claude-cli': 'Claude account is signed out'},
              usageBudgetProviders: const ['codex'],
            ),
          ),
        ),
        harnessModelsProvider.overrideWith(
          (ref) async => const [
            HarnessModelInfo(
              id: 'codex/gpt-5.6-terra',
              providerId: 'codex',
              displayName: 'GPT-5.6-Terra',
            ),
          ],
        ),
        adapterModelsProvider('claude-code').overrideWith(
          (ref) async => const [
            AcpModel(id: 'sonnet', name: 'Sonnet (latest)'),
            AcpModel(id: 'claude-sonnet-4-6', name: 'Claude Sonnet 4.6'),
          ],
        ),
      ],
      child: testWrap(
        Builder(
          builder: (context) => CcButton(
            onPressed: () => showSkillEvaluationDialog(
              context,
              workspaceId: 'workspace',
              skillSlug: 'candidate',
              currentHash: 'hash',
              availableSkills: const ['candidate'],
              history: const [],
            ),
            child: const Text('open'),
          ),
        ),
        locale: Locale(rtl ? 'ar' : 'en'),
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(CcDialog)));
}

Finder _select(String label) => find.byWidgetPredicate(
  (widget) => widget is CcSelect<String> && widget.label == label,
);

Future<void> _choose(WidgetTester tester, String label, String choice) async {
  final control = _select(label);
  await tester.ensureVisible(control);
  await tester.tap(control);
  await tester.pumpAndSettle();
  await tester.tap(find.text(choice).last);
  await tester.pumpAndSettle();
}

CcButton _start(WidgetTester tester, AppLocalizations l) =>
    tester.widget<CcButton>(
      find.ancestor(
        of: find.text(l.skillEvalStart),
        matching: find.byType(CcButton),
      ),
    );

void main() {
  testWidgets('adapter changes cannot submit a stale model selection', (
    tester,
  ) async {
    final l = await _open(tester);
    await _choose(tester, l.skillEvalCorpus, 'Utility pilot · 24');
    await _choose(tester, l.skillEvalProvider(''), 'codex');
    await _choose(tester, l.skillEvalModel, 'GPT-5.6-Terra');
    final budget = find.byWidgetPredicate(
      (w) => w is CcTextField && w.label == l.skillEvalBudgetCents,
    );
    await tester.ensureVisible(budget);
    await tester.enterText(
      find.descendant(of: budget, matching: find.byType(EditableText)),
      '100',
    );
    await tester.pump();
    expect(_start(tester, l).onPressed, isNotNull);
    expect(find.text(l.skillEvalUsageBudgetNote), findsOneWidget);

    await _choose(tester, l.adapter, l.guardrailAdapterClaudeCli);
    expect(_start(tester, l).onPressed, isNull);
    expect(find.text('GPT-5.6-Terra'), findsNothing);
    await tester.ensureVisible(_select(l.skillEvalModel));
    await tester.tap(_select(l.skillEvalModel));
    await tester.pumpAndSettle();
    expect(find.text('Sonnet (latest)'), findsNothing);
    await tester.tap(find.text('Claude Sonnet 4.6').last);
    await tester.pumpAndSettle();
    expect(_start(tester, l).onPressed, isNotNull);
    expect(tester.widget<CcTextField>(budget).controller!.text, '100');

    await _choose(tester, l.adapter, l.guardrailAdapterHarness);
    expect(_start(tester, l).onPressed, isNull);
    expect(find.text('Claude Sonnet 4.6'), findsNothing);
  });

  testWidgets(
    'unavailable native adapter stays blocked and explains why in RTL',
    (tester) async {
      final l = await _open(tester, nativeAvailable: false, rtl: true);
      await _choose(tester, l.adapter, l.guardrailAdapterClaudeCli);
      expect(
        find.text(l.skillEvalUnavailable('Claude account is signed out')),
        findsOneWidget,
      );
      expect(
        tester.widget<CcSelect<String>>(_select(l.skillEvalModel)).enabled,
        isFalse,
      );
      expect(_start(tester, l).onPressed, isNull);
      await _choose(tester, l.adapter, l.guardrailAdapterHarness);
      expect(
        find.text(l.skillEvalUnavailable('Claude account is signed out')),
        findsNothing,
      );
      expect(
        tester
            .widget<CcSelect<String>>(_select(l.skillEvalProvider('')))
            .enabled,
        isTrue,
      );
    },
  );
}
