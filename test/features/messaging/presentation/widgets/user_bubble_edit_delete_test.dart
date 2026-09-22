import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/user_bubble.dart';
import 'package:control_center/features/messaging/providers/editing_message_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Message _userMsg({
  String content = 'Hello there',
  Map<String, dynamic>? metadata,
}) => Message(
  id: 'm1',
  spaceId: 'c1',
  conversationId: 'c1',
  senderId: 'u1',
  senderType: SenderType.user,
  content: content,
  messageType: MessageType.text,
  metadata: metadata,
  createdAt: DateTime(2026, 7, 1, 9, 30),
);

Future<void> _pump(WidgetTester tester, Message msg) async {
  tester.view.physicalSize = const Size(600, 400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CcTheme(
              data: CcThemeData.light(),
              child: UserBubble(message: msg, codeFont: 'monospace'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('a normal user message renders its content, no edited marker', (
    tester,
  ) async {
    await _pump(tester, _userMsg());
    expect(
      find.textContaining('Hello there', findRichText: true),
      findsWidgets,
    );
    expect(find.textContaining('edited'), findsNothing);
    expect(find.text('Message deleted'), findsNothing);
  });

  testWidgets('an edited message shows the "edited" marker', (tester) async {
    await _pump(tester, _userMsg(metadata: {'editedAt': 123}));
    expect(find.textContaining('edited'), findsOneWidget);
  });

  testWidgets('edit loads the message for the composer instead of a dialog', (
    tester,
  ) async {
    await _pump(tester, _userMsg());
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    // The row is right-aligned, so the bubble's center is empty padding. The
    // message itself is what reveals the rail.
    await gesture.moveTo(
      tester.getCenter(find.textContaining('Hello there', findRichText: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.pencil));
    await tester.pumpAndSettle();

    expect(find.byType(CcDialog), findsNothing);
    expect(find.text('Save'), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(UserBubble)),
    );
    final editing = container.read(
      editingMessageProvider((spaceId: 'c1', conversationId: 'c1')),
    );
    expect(editing?.message.content, 'Hello there');
  });

  testWidgets('a deleted message renders the placeholder, not the content', (
    tester,
  ) async {
    await _pump(
      tester,
      _userMsg(content: 'secret', metadata: {'deletedAt': 123}),
    );
    expect(find.text('Message deleted'), findsOneWidget);
    expect(find.textContaining('secret', findRichText: true), findsNothing);
  });
}
