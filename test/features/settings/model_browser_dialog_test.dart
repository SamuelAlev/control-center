import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/model_browser_dialog.dart';
import 'package:control_center/features/settings/providers/model_browser_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

void main() {
  const groups = [
    ModelBrowserGroup(
      id: 'anthropic',
      name: 'Anthropic',
      models: [
        ModelBrowserEntry(
          id: 'anthropic/claude-fable-5',
          name: 'Claude Fable 5',
          providerId: 'anthropic',
          providerName: 'Anthropic',
          contextWindow: 1000000,
          maxOutput: 128000,
          inputCost: 1.4,
          outputCost: 4.4,
          thinkingLevels: [
            ThinkingLevel(id: 'low', label: 'Low'),
            ThinkingLevel(id: 'medium', label: 'Medium'),
            ThinkingLevel(id: 'high', label: 'High'),
            ThinkingLevel(id: 'xhigh', label: 'X-High'),
          ],
          defaultThinkingLevel: 'medium',
        ),
        ModelBrowserEntry(
          id: 'anthropic/claude-haiku-4-5',
          name: 'Claude Haiku 4.5',
          providerId: 'anthropic',
          providerName: 'Anthropic',
          contextWindow: 200000,
        ),
      ],
    ),
    ModelBrowserGroup(
      id: 'openai',
      name: 'OpenAI',
      models: [
        ModelBrowserEntry(
          id: 'openai/gpt-5.6',
          name: 'GPT-5.6',
          providerId: 'openai',
          providerName: 'OpenAI',
          contextWindow: 272000,
          inputCost: 0,
          outputCost: 0,
        ),
      ],
    ),
  ];

  /// Pumps a screen with a button that opens the browser and records what it
  /// resolves to — the dialog's contract is the id it pops with.
  Future<Future<void> Function()> pumpBrowser(
    WidgetTester tester, {
    String? selectedModelId,
    void Function(String?)? onResult,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          modelBrowserGroupsProvider.overrideWith(
            (ref, adapterId) async => groups,
          ),
        ],
        child: testWrap(
          Builder(
            builder: (context) => CcButton(
              onPressed: () async {
                final picked = await showModelBrowserDialog(
                  context: context,
                  adapterId: 'cc-harness',
                  selectedModelId: selectedModelId,
                );
                onResult?.call(picked);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    return () async {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    };
  }

  testWidgets('lists models grouped by provider with a rail and counts', (
    tester,
  ) async {
    final open = await pumpBrowser(tester);
    await open();

    // Rail: all-models item plus one item per provider, with counts.
    expect(find.text('All models'), findsOneWidget);
    expect(find.text('Anthropic'), findsNWidgets(2)); // rail + group header
    expect(find.text('OpenAI'), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget);

    // Rows carry name, id and metadata (the highlighted first model is echoed
    // in the footer, hence two).
    expect(find.text('Claude Fable 5'), findsNWidgets(2));
    expect(find.text('anthropic/claude-fable-5'), findsOneWidget);
    expect(find.text('GPT-5.6'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('\$1.4/4.4'), findsOneWidget);

    // Footer details the first (highlighted) model, effort vocabulary included.
    expect(
      find.textContaining('Reasoning effort: Low · Medium · High · X-High'),
      findsOneWidget,
    );
    expect(find.textContaining('1M context'), findsOneWidget);
    expect(find.textContaining('128k output'), findsOneWidget);
  });

  testWidgets('rail filters to one provider', (tester) async {
    final open = await pumpBrowser(tester);
    await open();

    await tester.tap(find.text('OpenAI').first);
    await tester.pumpAndSettle();

    // Row + footer echo of the (re-)highlighted first model.
    expect(find.text('GPT-5.6'), findsNWidgets(2));
    expect(find.text('Claude Fable 5'), findsNothing);
  });

  testWidgets('search narrows the list', (tester) async {
    final open = await pumpBrowser(tester);
    await open();

    await tester.enterText(find.byType(EditableText), 'haiku');
    await tester.pumpAndSettle();

    // Row + footer echo of the sole remaining (highlighted) model.
    expect(find.text('Claude Haiku 4.5'), findsNWidgets(2));
    expect(find.text('Claude Fable 5'), findsNothing);
    expect(find.text('GPT-5.6'), findsNothing);

    // Rail counts follow the query: All models=1, Anthropic=1, OpenAI=0.
    expect(find.text('3'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('a query matching nothing is offered as a custom id', (
    tester,
  ) async {
    String? picked;
    final open = await pumpBrowser(tester, onResult: (v) => picked = v);
    await open();

    await tester.enterText(
      find.byType(EditableText),
      'anthropic/claude-6-preview',
    );
    await tester.pumpAndSettle();

    final custom = find.textContaining('anthropic/claude-6-preview');
    expect(custom, findsWidgets);
    await tester.tap(
      find.textContaining('Use \u201canthropic/claude-6-preview\u201d'),
    );
    await tester.pumpAndSettle();

    expect(picked, 'anthropic/claude-6-preview');
  });

  testWidgets('arrow keys move the highlight and Enter commits it', (
    tester,
  ) async {
    String? picked;
    final open = await pumpBrowser(tester, onResult: (v) => picked = v);
    await open();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    // Highlight moved off the first model; the footer follows it.
    expect(find.textContaining('200k context'), findsWidgets);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(picked, 'anthropic/claude-haiku-4-5');
  });

  testWidgets('tapping a row resolves with its id', (tester) async {
    String? picked;
    final open = await pumpBrowser(tester, onResult: (v) => picked = v);
    await open();

    await tester.tap(find.text('GPT-5.6'));
    await tester.pumpAndSettle();

    expect(picked, 'openai/gpt-5.6');
  });

  testWidgets('the saved model is marked and seeds the highlight', (
    tester,
  ) async {
    final open = await pumpBrowser(tester, selectedModelId: 'openai/gpt-5.6');
    await open();

    expect(find.byIcon(CcIcons.check), findsOneWidget);
    // Footer opens on the saved model, not the first row.
    expect(find.textContaining('272k context'), findsOneWidget);
  });
}
