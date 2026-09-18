import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('a single-select option submits immediately', (tester) async {
    AgentQuestionAnswer? got;
    await tester.pumpWidget(
      testWrap(
        AskUserCard(
          question: 'How will you use this?',
          options: const [
            AgentQuestionOption(
              label: 'Designer',
              description: 'Prototyping flows and pages',
            ),
            AgentQuestionOption(
              label: 'Engineer',
              description: 'Shipping production UI',
            ),
          ],
          onSubmit: (a) => got = a,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('ask-user-option-1')));
    await tester.pump();

    expect(got?.selectedLabels, ['Engineer']);
    expect(got?.skipped, isFalse);
  });

  testWidgets('multi-select waits for continue', (tester) async {
    AgentQuestionAnswer? got;
    await tester.pumpWidget(
      testWrap(
        AskUserCard(
          question: 'Which features should we prioritize?',
          multiSelect: true,
          options: const [
            AgentQuestionOption(label: 'Dark mode'),
            AgentQuestionOption(label: 'Accessibility'),
            AgentQuestionOption(label: 'Performance'),
          ],
          onSubmit: (a) => got = a,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('ask-user-option-0')));
    await tester.tap(find.byKey(const ValueKey('ask-user-option-2')));
    await tester.pump();
    expect(got, isNull);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(got?.selectedLabels, ['Dark mode', 'Performance']);
  });

  testWidgets('skip is a deliberate empty-handed answer', (tester) async {
    AgentQuestionAnswer? got;
    await tester.pumpWidget(
      testWrap(
        AskUserCard(
          question: 'How will you use this?',
          options: const [AgentQuestionOption(label: 'Designer')],
          onSubmit: (a) => got = a,
        ),
      ),
    );

    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(got?.skipped, isTrue);
  });

  testWidgets('a standalone typed answer submits from continue', (
    tester,
  ) async {
    AgentQuestionAnswer? got;
    await tester.pumpWidget(
      testWrap(
        AskUserCard(
          question: 'What should we call your workspace?',
          allowFreeText: true,
          onSubmit: (a) => got = a,
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('ask-user-free-text')),
      'Acme',
    );
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(got?.freeText, 'Acme');
  });

  testWidgets('an answered card is read-only', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      testWrap(
        AskUserCard(
          question: 'How will you use this?',
          options: const [AgentQuestionOption(label: 'Designer')],
          answered: const AgentQuestionAnswer(selectedLabels: ['Designer']),
          onSubmit: (_) => calls++,
        ),
      ),
    );

    expect(find.text('Answered'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('ask-user-option-0')));
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('digit keys pick a numbered option', (tester) async {
    AgentQuestionAnswer? got;
    await tester.pumpWidget(
      testWrap(
        AskUserCard(
          question: 'How will you use this?',
          options: const [
            AgentQuestionOption(label: 'Designer'),
            AgentQuestionOption(label: 'Engineer'),
          ],
          onSubmit: (a) => got = a,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();
    expect(got?.selectedLabels, ['Engineer']);
  });

  testWidgets('a permission-style card has no skip', (tester) async {
    await tester.pumpWidget(
      testWrap(
        const AskUserCard(
          question: 'Push to main',
          caption: 'Approval required',
          allowSkip: false,
          options: [
            AgentQuestionOption(label: 'Deny', value: 'deny'),
            AgentQuestionOption(label: 'Approve', value: 'approve'),
          ],
        ),
      ),
    );

    expect(find.text('Approval required'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(find.byKey(const ValueKey('ask-user-option-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('ask-user-option-1')), findsOneWidget);
  });
}
