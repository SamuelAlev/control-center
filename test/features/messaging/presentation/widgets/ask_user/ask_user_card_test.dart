import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_option_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_summary.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
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

  testWidgets('a countdown drains and reports expiry once', (tester) async {
    var expired = 0;
    var now = DateTime(2026, 10, 8, 12);
    final expiresAt = now.add(const Duration(seconds: 2));
    Future<void> advance() async {
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.pumpWidget(
      testWrap(
        AskUserCard(
          question: 'How will you use this?',
          options: const [AgentQuestionOption(label: 'Designer')],
          expiresAt: expiresAt,
          timeout: const Duration(seconds: 4),
          onSubmit: (_) {},
          onExpired: () => expired++,
          now: () => now,
        ),
      ),
    );

    double fill() => tester
        .widget<CcProgressBar>(find.byKey(const ValueKey('ask-user-countdown')))
        .value!;
    expect(fill(), closeTo(0.5, 0.05));

    await advance();
    await tester.pump(const Duration(seconds: 1));
    expect(fill(), closeTo(0.25, 0.05));
    expect(expired, 0);

    await advance();
    await advance();
    expect(expired, 1);
  });

  testWidgets('no deadline, no countdown', (tester) async {
    await tester.pumpWidget(
      testWrap(
        AskUserCard(
          question: 'How will you use this?',
          options: const [AgentQuestionOption(label: 'Designer')],
          onSubmit: (_) {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('ask-user-countdown')), findsNothing);
  });

  testWidgets('the free-text row is as tall as an option row', (tester) async {
    await tester.pumpWidget(
      testWrap(
        AskUserCard(
          question: 'Who should take it?',
          options: const [AgentQuestionOption(label: 'You decide')],
          allowFreeText: true,
          onSubmit: (_) {},
        ),
      ),
    );
    final option = tester.getSize(
      find.byKey(const ValueKey('ask-user-option-0')),
    );
    final freeText = tester.getSize(
      find.byKey(const ValueKey('ask-user-free-text')),
    );
    expect(freeText.height, greaterThanOrEqualTo(kAskUserRowMinHeight));
    expect(freeText.height, option.height);
  });

  group('AskUserSummary', () {
    const options = [
      AgentQuestionOption(label: 'Designer', value: 'designer'),
      AgentQuestionOption(label: 'Engineer'),
    ];

    testWidgets('shows the question, the choice label and the note', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          const AskUserSummary(
            question: 'How will you use this?',
            options: options,
            answer: AgentQuestionAnswer(
              selectedLabels: ['designer'],
              freeText: 'mostly flows',
            ),
          ),
        ),
      );
      expect(find.text('How will you use this?'), findsOneWidget);
      expect(find.text('Designer'), findsOneWidget);
      expect(find.text('mostly flows'), findsOneWidget);
    });

    testWidgets('a skip and a timeout say so', (tester) async {
      await tester.pumpWidget(
        testWrap(
          const Column(
            children: [
              AskUserSummary(
                question: 'Skipped one',
                answer: AgentQuestionAnswer(skipped: true),
              ),
              AskUserSummary(question: 'Timed-out one', expired: true),
            ],
          ),
        ),
      );
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('Timed out'), findsOneWidget);
    });
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

  testWidgets('hovering a choice keeps every row the same height', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        const AskUserCard(
          question: 'Let agents run programs from this workspace copy?',
          caption: 'Approval required',
          allowSkip: false,
          options: [
            AgentQuestionOption(label: 'Deny', value: 'deny'),
            AgentQuestionOption(label: 'Approve', value: 'approve'),
          ],
        ),
      ),
    );

    final deny = find.byKey(const ValueKey('ask-user-option-0'));
    final approve = find.byKey(const ValueKey('ask-user-option-1'));
    final denyHeight = tester.getSize(deny).height;
    final approveHeight = tester.getSize(approve).height;
    final approveTop = tester.getTopLeft(approve).dy;

    expect(denyHeight, 44);
    expect(approveHeight, denyHeight);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(deny));
    await tester.pump();

    expect(
      find.descendant(of: deny, matching: find.byIcon(AppIcons.arrowRight)),
      findsOneWidget,
    );
    expect(tester.getSize(deny).height, denyHeight);
    expect(tester.getSize(approve).height, approveHeight);
    expect(tester.getTopLeft(approve).dy, approveTop);
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
