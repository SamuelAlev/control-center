@TestOn('browser')
library;

import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/phone_widgets_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/inbox/approval_card.dart';
import 'package:cc_remote/widgets/messaging/ask_user_card.dart';
import 'package:cc_remote/widgets/messaging/pending_approvals.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const script =
      'git push origin feature/approval\n'
      'echo "second step"\n'
      '```bash\n'
      '  \n'
      'echo "embedded fence"\n'
      '```\n'
      'echo "final step"\n';

  Widget host(Widget child, {Locale locale = const Locale('en')}) {
    return ProviderScope(
      child: WidgetsApp(
        color: const Color(0xFF000000),
        locale: locale,
        supportedLocales: kSupportedRemoteLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          PhoneWidgetsLocalizationsDelegate(),
        ],
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF111111),
            decoration: TextDecoration.none,
          ),
          child: Center(child: SizedBox(width: 360, child: child)),
        ),
      ),
    );
  }

  testWidgets(
    'inline approval bounds long source while answers stay reachable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final longScript =
          '$script${List.filled(80, 'echo inspect-me').join('\n')}\n';
      AgentQuestionAnswer? answer;
      await tester.pumpWidget(
        host(
          AskUserCard(
            question: 'Push to feature/approval?',
            contextText:
                'The agent will publish the branch and run the script.',
            scrollableBody: true,
            allowSkip: false,
            extraBody: PhoneApprovalCodeBlock(source: longScript),
            options: const [
              AgentQuestionOption(label: 'Deny', value: 'deny'),
              AgentQuestionOption(label: 'Approve', value: 'approve'),
            ],
            onSubmit: (value) => answer = value,
          ),
          locale: const Locale('ar'),
        ),
      );

      expect(find.text(longScript), findsOneWidget);
      final viewport = find.descendant(
        of: find.byType(AskUserCard),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      final position = tester.state<ScrollableState>(viewport).position;
      await tester.dragFrom(
        tester.getRect(viewport).center,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      expect(
        tester.getBottomRight(find.text(longScript)).dy,
        lessThanOrEqualTo(tester.getBottomRight(viewport).dy + 1),
      );
      final codeDirection = tester.widget<Directionality>(
        find.descendant(
          of: find.byType(PhoneApprovalCodeBlock),
          matching: find.byType(Directionality),
        ),
      );
      expect(codeDirection.textDirection, TextDirection.ltr);
      expect(find.text('Approve').hitTestable(), findsOneWidget);
      expect(find.text('Deny').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Deny'));
      expect(answer?.selectedLabels, ['deny']);
    },
  );

  testWidgets('inline queue exposes the oldest request and counts the rest', (
    tester,
  ) async {
    const oldest = ConfirmationRequestDto(
      id: 'old',
      spaceId: 'space-1',
      title: 'Push to feature/old?',
      detail: 'Publish the older branch.',
      severity: 'warning',
      command: 'git push origin feature/old',
      createdAt: '2025-01-01T00:00:00Z',
    );
    const newer = ConfirmationRequestDto(
      id: 'new',
      spaceId: 'space-1',
      title: 'Push to feature/new?',
      detail: 'Publish the newer branch.',
      severity: 'warning',
      command: 'git push origin feature/new',
      createdAt: '2025-01-02T00:00:00Z',
    );
    await tester.pumpWidget(
      host(
        ProviderScope(
          overrides: [
            pendingConfirmationsProvider(
              'space-1',
            ).overrideWith((ref) => Stream.value([newer, oldest])),
          ],
          child: const PendingApprovals(spaceId: 'space-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(oldest.title), findsOneWidget);
    expect(find.text(oldest.command!), findsOneWidget);
    expect(find.text(newer.title), findsNothing);
    expect(find.text(newer.command!), findsNothing);
    expect(find.text('Approval required, 1 waiting'), findsOneWidget);
  });

  testWidgets('inbox card scrolls full explanation and code above actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final longScript =
        '$script${List.filled(80, 'echo inspect-me').join('\n')}\n';
    const title = 'Push to feature/approval after review';
    final detail =
        'Publishing changes will affect the shared branch. '
        '${List.filled(30, 'Inspect the full command before deciding.').join(' ')}';
    await tester.pumpWidget(
      host(
        ApprovalCard(
          request: ConfirmationRequestDto(
            id: 'approval-1',
            spaceId: '',
            title: title,
            detail: detail,
            severity: 'destructive',
            command: longScript,
            createdAt: '',
          ),
        ),
      ),
    );

    expect(find.text(title), findsOneWidget);
    expect(find.text(detail), findsOneWidget);
    expect(find.text(longScript), findsOneWidget);
    final viewport = find.descendant(
      of: find.byType(ApprovalCard),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    final position = tester.state<ScrollableState>(viewport).position;
    await tester.dragFrom(
      tester.getRect(viewport).center,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(
      tester.getBottomRight(find.text(longScript)).dy,
      lessThanOrEqualTo(tester.getBottomRight(viewport).dy + 1),
    );
    expect(find.text('Approve').hitTestable(), findsOneWidget);
    expect(find.text('Deny').hitTestable(), findsOneWidget);
  });
}
