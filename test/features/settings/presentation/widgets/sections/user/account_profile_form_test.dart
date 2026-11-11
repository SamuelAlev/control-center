import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/value_objects/username_check.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/account_profile_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/account_profile_form.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_wrap.dart';

/// The email field says when single sign-on will not match the address yet.
void main() {
  const hint =
      "Only you have entered this address. Single sign-on won't match it "
      "until the server's owner confirms it.";

  Future<void> pump(WidgetTester tester, UserDto user) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usernameCheckProvider.overrideWithValue(
            (handle) async => UsernameCheck.fromJson(const {'available': true}),
          ),
        ],
        child: testWrap(
          SingleChildScrollView(child: AccountProfileForm(user: user)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('an address nobody confirmed carries the hint', (tester) async {
    await pump(
      tester,
      UserDto(
        id: 'u-1',
        handle: 'sam',
        displayName: 'Sam',
        email: 'sam@example.com',
      ),
    );
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('a confirmed address does not, until it is changed', (
    tester,
  ) async {
    await pump(
      tester,
      UserDto(
        id: 'u-1',
        handle: 'sam',
        displayName: 'Sam',
        email: 'sam@example.com',
        emailVerified: true,
      ),
    );
    expect(find.text(hint), findsNothing);

    final email = find.widgetWithText(CcTextField, 'sam@example.com');
    await tester.enterText(
      find.descendant(of: email, matching: find.byType(EditableText)),
      'sam@elsewhere.example',
    );
    await tester.pump();
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('no address, no hint', (tester) async {
    await pump(tester, UserDto(id: 'u-1', handle: 'sam', displayName: 'Sam'));
    expect(find.text(hint), findsNothing);
  });
}
