import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversation_permission_prompt.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ConfirmationRequestDto _req({
  String spaceId = 'space-1',
  bool rememberable = false,
}) => ConfirmationRequestDto(
  id: 'req-1',
  spaceId: spaceId,
  title: 'Push to main',
  detail: 'The agent wants to push this branch.',
  severity: 'warning',
  command: 'git push origin main',
  createdAt: '2026-01-01T00:00:00Z',
  rememberScope: rememberable ? 'space' : null,
  actionClasses: rememberable ? const ['gitPush'] : const [],
);

Future<void> _pump(
  WidgetTester tester, {
  required List<ConfirmationRequestDto> pending,
  String spaceId = 'space-1',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pendingConfirmationsProvider.overrideWith(
          (ref) => Stream.value(pending),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CcTheme(
            data: CcThemeData.light(),
            child: ConversationPermissionPrompt(spaceId: spaceId),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders nothing when this space has no pending request', (
    tester,
  ) async {
    await _pump(tester, pending: [_req(spaceId: 'other')]);
    expect(find.text('Push to main'), findsNothing);
    expect(find.text('Deny'), findsNothing);
  });

  testWidgets('a pending request is an ask-user card in the conversation', (
    tester,
  ) async {
    await _pump(tester, pending: [_req()]);

    expect(find.text('Approval required'), findsOneWidget);
    expect(find.text('Push to main'), findsOneWidget);
    expect(find.text('git push origin main'), findsOneWidget);
    expect(find.byKey(const ValueKey('ask-user-option-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('ask-user-option-1')), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('a rememberable request offers the standing approval', (
    tester,
  ) async {
    await _pump(tester, pending: [_req(rememberable: true)]);
    expect(find.byKey(const ValueKey('ask-user-option-2')), findsOneWidget);
  });
}
