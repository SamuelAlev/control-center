import 'package:cc_domain/features/messaging/domain/value_objects/thread_summary.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/thread_indicator.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The "N replies" row under a message that started a thread.
///
/// It is the ONLY trace a thread leaves in the stream it branched from, so the
/// count, the recency line and — above all — the tap that opens the thread are
/// what these tests pin.
void main() {
  Widget host(ThreadSummary summary, {void Function(String)? onOpen}) =>
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CcTheme(
              data: CcThemeData.light(),
              child: ThreadIndicator(
                summary: summary,
                onOpen: onOpen ?? (_) {},
              ),
            ),
          ),
        ),
      );

  ThreadSummary summary({
    int replyCount = 3,
    DateTime? lastReplyAt,
    List<String> participantIds = const ['agent-1', 'user-1'],
  }) => ThreadSummary(
    threadId: 't-1',
    anchorMessageId: 'm-1',
    title: 'Fix the flake',
    replyCount: replyCount,
    lastReplyAt: lastReplyAt,
    participantIds: participantIds,
  );

  testWidgets('pluralizes the reply count', (tester) async {
    await tester.pumpWidget(host(summary(replyCount: 3)));
    await tester.pump();
    expect(find.text('3 replies'), findsOneWidget);

    await tester.pumpWidget(host(summary(replyCount: 1)));
    await tester.pump();
    expect(find.text('1 reply'), findsOneWidget);
  });

  testWidgets('shows the last reply time, and omits it while empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        summary(lastReplyAt: DateTime.now().subtract(const Duration(days: 10))),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Last reply'), findsOneWidget);

    await tester.pumpWidget(host(summary()));
    await tester.pump();
    expect(find.textContaining('Last reply'), findsNothing);
  });

  testWidgets('one avatar per distinct speaker, capped at three', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(summary(participantIds: const ['a', 'b', 'c', 'd', 'e'])),
    );
    await tester.pump();
    // The stack is a handful of faces, not an audit trail.
    expect(find.byType(CcAvatar), findsNWidgets(3));
  });

  testWidgets('tapping the row opens the thread, not the anchor', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(host(summary(), onOpen: opened.add));
    await tester.pump();

    await tester.tap(find.byType(ThreadIndicator));
    await tester.pump();

    expect(opened, ['t-1']);
  });
}
