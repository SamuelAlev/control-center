import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_domain/core/domain/value_objects/username_check.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_you_step.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// A brand-new person whose name the server derived from their OS account.
class _Identity implements RemoteIdentityRepository {
  UserDto user = UserDto(id: 'u-1', handle: 'sam', displayName: 'Sam');
  UsernameRefusal? refuseSave;
  final saves = <Map<String, String?>>[];

  @override
  Future<IdentityMe> me({String? workspaceId}) async => IdentityMe(
    user: user,
    deviceId: 'd-1',
    isServerOwner: true,
    memberships: const [],
  );

  @override
  Future<UsernameCheck> checkHandle(String handle) async => handle == 'ada'
      ? UsernameCheck(
          available: false,
          normalized: handle,
          reason: UsernameRefusal.taken,
        )
      : UsernameCheck(available: true, normalized: handle);

  @override
  Future<UserDto> updateProfile({
    String? handle,
    String? displayName,
    String? email,
    String? avatarRef,
    String? gitAuthorName,
    String? gitAuthorEmail,
  }) async {
    saves.add({'handle': handle, 'display_name': displayName});
    if (refuseSave case final reason?) {
      throw UsernameRefusedException(reason);
    }
    return user = UserDto(
      id: user.id,
      handle: handle ?? user.handle,
      displayName: displayName ?? user.displayName,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppLocalizations l10n;
  late _Identity identity;
  late int continued;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  setUp(() {
    identity = _Identity();
    continued = 0;
  });

  Future<void> pump(WidgetTester tester, {TextDirection? direction}) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [identityRepositoryProvider.overrideWithValue(identity)],
        child: testWrap(
          OnboardingYouStep(onContinue: () => continued++),
          textDirection: direction,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder continueButton() => find.widgetWithText(CcButton, l10n.continueLabel);

  bool canContinue(WidgetTester tester) =>
      tester.widget<CcButton>(continueButton()).onPressed != null;

  Future<void> type(WidgetTester tester, int field, String text) async {
    await tester.enterText(find.byType(CcTextField).at(field), text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('is prefilled with the derived name and continues without a '
      'write when it is kept', (tester) async {
    await pump(tester);
    expect(find.text('sam'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    await tester.tap(continueButton());
    await tester.pumpAndSettle();
    expect(continued, 1);
    expect(identity.saves, isEmpty);
  });

  testWidgets('saves a changed name, then continues', (tester) async {
    await pump(tester);
    await type(tester, 0, 'samuel');
    await type(tester, 1, 'Samuel Smith');
    await tester.tap(continueButton());
    await tester.pumpAndSettle();
    expect(identity.saves.single, {
      'handle': 'samuel',
      'display_name': 'Samuel Smith',
    });
    expect(continued, 1);
  });

  testWidgets('cannot be passed with a refused name', (tester) async {
    await pump(tester);
    await type(tester, 0, 'ada');
    expect(find.text(l10n.usernameTaken), findsOneWidget);
    expect(canContinue(tester), isFalse);

    await type(tester, 0, 'system');
    expect(find.text(l10n.usernameReserved), findsOneWidget);
    expect(canContinue(tester), isFalse);

    await type(tester, 0, 'Sam Smith');
    expect(find.text(l10n.usernameInvalid), findsOneWidget);
    expect(canContinue(tester), isFalse);
  });

  testWidgets('a name taken after the check stops on this step', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, 0, 'samuel');
    identity.refuseSave = UsernameRefusal.taken;
    await tester.tap(continueButton());
    await tester.pumpAndSettle();
    expect(find.text(l10n.usernameTaken), findsOneWidget);
    expect(continued, 0);
    expect(canContinue(tester), isFalse);
  });

  testWidgets('needs a display name', (tester) async {
    await pump(tester);
    await type(tester, 1, '  ');
    expect(find.text(l10n.accountDisplayNameRequired), findsOneWidget);
    expect(canContinue(tester), isFalse);
  });

  testWidgets('right to left on a phone: no overflow, the name stays left '
      'to right', (tester) async {
    await pump(tester, direction: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    final field = find.ancestor(
      of: find.byType(CcTextField).first,
      matching: find.byType(Directionality),
    );
    expect(
      tester.widget<Directionality>(field.first).textDirection,
      TextDirection.ltr,
    );
  });
}
