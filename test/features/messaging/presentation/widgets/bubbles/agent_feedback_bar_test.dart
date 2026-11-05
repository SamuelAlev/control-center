import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/agent_feedback_bar.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final DesignSystemTokens _tokens = CcThemeData.light().tokens;

Message _turn({MessageFeedback? feedback}) {
  final base = Message(
    id: 'm1',
    spaceId: 'sp',
    conversationId: 'c1',
    senderId: 'agent',
    senderType: SenderType.user,
    messageType: MessageType.text,
    content: 'done',
    createdAt: DateTime.utc(2026),
  );
  return base.copyWith(
    metadata: base.metadataWithFeedback(feedback, atEpochMs: 0),
  );
}

Widget _host(Message message) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CcTheme(
        data: CcThemeData.light(),
        child: Align(
          alignment: Alignment.topCenter,
          child: AgentFeedbackBar(message: message),
        ),
      ),
    ),
  ),
);

Future<void> _hover(WidgetTester tester, IconData icon) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(find.byIcon(icon)));
  await tester.pumpAndSettle();
}

Color? _washOf(WidgetTester tester, IconData icon) {
  final box = find.ancestor(
    of: find.byIcon(icon),
    matching: find.byType(AnimatedContainer),
  );
  final decoration = tester.widget<AnimatedContainer>(box.first).decoration;
  return (decoration! as BoxDecoration).color;
}

Color? _glyphOf(WidgetTester tester, IconData icon) =>
    tester.widget<Icon>(find.byIcon(icon)).color;

void main() {
  group('AgentFeedbackBar', () {
    for (final icon in [AppIcons.thumbsUp, AppIcons.thumbsDown]) {
      testWidgets('$icon rests quiet and reads as a button on hover', (
        tester,
      ) async {
        await tester.pumpWidget(_host(_turn()));

        expect(_washOf(tester, icon)?.a, 0);
        expect(_glyphOf(tester, icon), _tokens.fgQuaternary);

        await _hover(tester, icon);

        expect(_washOf(tester, icon), _tokens.hover);
        expect(_glyphOf(tester, icon), _tokens.fg);
      });
    }

    testWidgets('the active thumb keeps its color on hover', (tester) async {
      await tester.pumpWidget(_host(_turn(feedback: MessageFeedback.helpful)));

      expect(_glyphOf(tester, AppIcons.thumbsUp), _tokens.success);
      expect(_glyphOf(tester, AppIcons.thumbsDown), _tokens.fgQuaternary);

      await _hover(tester, AppIcons.thumbsUp);

      expect(_washOf(tester, AppIcons.thumbsUp), _tokens.hover);
      expect(_glyphOf(tester, AppIcons.thumbsUp), _tokens.success);
    });
  });
}
