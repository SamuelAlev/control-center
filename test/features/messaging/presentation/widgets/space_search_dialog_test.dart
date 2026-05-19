import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_search_dialog.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_search_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Message _msg(String id, String content) => Message(
  id: id,
  spaceId: 'c1',
  conversationId: 'c1',
  senderId: 'u1',
  senderType: SenderType.user,
  content: content,
  messageType: MessageType.text,
  createdAt: DateTime(2026, 7, 1, 9, 30),
);

Future<void> _pump(
  WidgetTester tester, {
  required List<Message> results,
}) async {
  tester.view.physicalSize = const Size(700, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        spaceSearchProvider.overrideWith((ref, arg) async => results),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CcTheme(
            data: CcThemeData.light(),
            child: const SpaceSearchDialog(spaceId: 'c1'),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('typing a query shows matching results', (tester) async {
    await _pump(tester, results: [_msg('m1', 'the deployment pipeline broke')]);

    await tester.enterText(find.byType(EditableText), 'deployment');
    await tester.pump(const Duration(milliseconds: 350)); // debounce
    await tester.pump(); // resolve the (async) provider

    expect(
      find.textContaining('deployment pipeline broke', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('an empty result set shows the no-results state', (tester) async {
    await _pump(tester, results: const []);
    await tester.enterText(find.byType(EditableText), 'nothingmatches');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.text('No messages found'), findsOneWidget);
  });

  testWidgets('tapping a result sets the pending-focus message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final container = ProviderContainer(
      overrides: [
        spaceSearchProvider.overrideWith(
          (ref, arg) async => [_msg('m1', 'jump here please')],
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CcTheme(
              data: CcThemeData.light(),
              child: const SpaceSearchDialog(spaceId: 'c1'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'jump');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    await tester.tap(
      find.textContaining('jump here please', findRichText: true),
    );
    await tester.pump();

    final pending = container.read(pendingFocusMessageProvider);
    expect(pending?.messageId, 'm1');
    expect(pending?.spaceId, 'c1');
  });
}
