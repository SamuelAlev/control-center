import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversation_permission_prompt.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

ConfirmationRequestDto _req({
  String spaceId = 'space-1',
  bool rememberable = false,
  String id = 'req-1',
  String title = 'Push to main',
  String detail = 'The agent wants to push this branch.',
  String command = 'git push origin main',
  String severity = 'warning',
}) => ConfirmationRequestDto(
  id: id,
  spaceId: spaceId,
  title: title,
  detail: detail,
  severity: severity,
  command: command,
  createdAt: '2026-01-01T00:00:00Z',
  rememberScope: rememberable ? 'space' : null,
  actionClasses: rememberable ? const ['gitPush'] : const [],
);

Future<void> _pump(
  WidgetTester tester, {
  required List<ConfirmationRequestDto> pending,
  String spaceId = 'space-1',
  Size size = const Size(1200, 900),
  TextDirection textDirection = TextDirection.ltr,
  Stream<List<ConfirmationRequestDto>>? pendingChanges,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pendingConfirmationsProvider.overrideWith(
          (ref) => pendingChanges ?? Stream.value(pending),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CcTheme(
            data: CcThemeData.light(),
            child: Directionality(
              textDirection: textDirection,
              child: Column(
                children: [
                  const Expanded(child: SizedBox()),
                  ConversationPermissionPrompt(spaceId: spaceId),
                  const SizedBox(height: 80),
                ],
              ),
            ),
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

  testWidgets('a rememberable request offers the standing approval', (
    tester,
  ) async {
    await _pump(tester, pending: [_req(rememberable: true)]);
    expect(find.byKey(const ValueKey('ask-user-option-2')), findsOneWidget);
  });
  for (final (size, direction) in [
    (const Size(1200, 900), TextDirection.ltr),
    (const Size(390, 640), TextDirection.rtl),
    (const Size(480, 480), TextDirection.ltr),
  ]) {
    testWidgets('long Bash approval stays readable at $size $direction', (
      tester,
    ) async {
      final script = [
        "python3 - <<'PY'",
        for (var i = 0; i < 80; i++) '    print("line $i")',
        '    print("${List.filled(30, 'a long source line').join(' ')}")',
        'PY',
      ].join('\n');
      await _pump(
        tester,
        size: size,
        textDirection: direction,
        pending: [
          _req(command: script, rememberable: true),
          _req(id: 'req-2', title: 'Next request'),
        ],
      );

      final deny = find.byKey(const ValueKey('ask-user-option-0'));
      final approve = find.byKey(const ValueKey('ask-user-option-1'));
      final remember = find.byKey(const ValueKey('ask-user-option-2'));
      expect(deny.hitTestable(), findsOneWidget);
      expect(approve.hitTestable(), findsOneWidget);
      expect(remember.hitTestable(), findsOneWidget);
      expect(find.text('Next request'), findsNothing);
      final actionRect = tester.getRect(approve);
      expect(actionRect.bottom, lessThan(size.height - 80));

      final source = find.text(script, findRichText: true);
      expect(source, findsOneWidget);
      final vertical = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      final position = tester.state<ScrollableState>(vertical).position;
      final viewport = tester.getRect(vertical);
      await tester.drag(vertical, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(tester.getRect(approve), actionRect);

      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      final sourceRect = tester.getRect(source);
      expect(sourceRect.bottom, lessThanOrEqualTo(viewport.bottom));
      expect(sourceRect.bottom, greaterThan(viewport.top));
      expect(approve.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      final horizontal = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
      );
      expect(horizontal, findsOneWidget);
      final sideways = tester.state<ScrollableState>(horizontal).position;
      expect(sideways.maxScrollExtent, greaterThan(0));
      await tester.dragFrom(viewport.center, const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(sideways.pixels, greaterThan(0));
      expect(tester.getRect(approve), actionRect);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('the next approval opens at the start after the front resolves', (
    tester,
  ) async {
    final changes = StreamController<List<ConfirmationRequestDto>>();
    addTearDown(changes.close);
    final script = List.generate(80, (i) => 'echo line-$i').join('\n');
    await _pump(tester, pending: const [], pendingChanges: changes.stream);
    changes.add([_req(command: script), _req(id: 'req-2')]);
    await tester.pumpAndSettle();
    final vertical = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    final firstPosition = tester.state<ScrollableState>(vertical).position;
    firstPosition.jumpTo(firstPosition.maxScrollExtent);
    await tester.pumpAndSettle();
    changes.add([_req(id: 'req-2', command: script)]);
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(vertical).position.pixels, 0);
    expect(
      find.byKey(const ValueKey('ask-user-option-1')).hitTestable(),
      findsOneWidget,
    );
  });
}
