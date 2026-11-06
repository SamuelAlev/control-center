import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/remote_control/presentation/settings/own_devices_section.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ownDevicesProvider.overrideWith(
          (ref) => Stream.value([
            {
              'device_id': 'device-1',
              'label': 'Oneplus',
              'platform': 'android',
              'status': 'active',
            },
          ]),
        ),
      ],
      child: testWrap(const SingleChildScrollView(child: OwnDevicesSection())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(SettingsHoverReveal.debugForgetMouse);

  testWidgets('clicking a row opens the rename dialog', (tester) async {
    await _pump(tester);

    expect(find.byIcon(AppIcons.pencil), findsNothing);
    await tester.tap(find.text('Oneplus'));
    await tester.pumpAndSettle();

    expect(find.byType(CcDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CcDialog),
        matching: find.text('Rename device'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the trash asks to revoke without opening rename', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byIcon(AppIcons.trash2));
    await tester.pumpAndSettle();

    expect(find.text('Rename device'), findsNothing);
    expect(
      find.descendant(of: find.byType(CcDialog), matching: find.text('Revoke')),
      findsOneWidget,
    );
  });

  testWidgets('with a mouse, the trash waits for hover', (tester) async {
    await _pump(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pumpAndSettle();
    double opacity() => tester
        .widget<AnimatedOpacity>(
          find
              .descendant(
                of: find.byType(SettingsHoverReveal),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity;

    expect(opacity(), 0);
    await mouse.moveTo(tester.getCenter(find.text('Oneplus')));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });
}
