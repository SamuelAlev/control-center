import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_domain/core/domain/value_objects/username_check.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/account_profile_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/identity_provider_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/active_workspace.dart';
import '../../helpers/test_wrap.dart';

/// The caller's account on a pretend server.
class _Identity implements RemoteIdentityRepository {
  UserDto user = UserDto(
    id: 'u-1',
    handle: 'sam',
    displayName: 'Sam Smith',
    email: 'sam@example.com',
  );
  final taken = <String>{'ada'};
  Object? meError;
  String ssoIssuer = '';
  UsernameRefusal? refuseSave;
  final checks = <String>[];
  final saves = <Map<String, String?>>[];

  @override
  Future<IdentityMe> me({String? workspaceId}) async {
    if (meError case final error?) {
      throw error;
    }
    return IdentityMe(
      user: user,
      deviceId: 'd-1',
      isServerOwner: false,
      memberships: const [],
      ssoIssuer: ssoIssuer,
    );
  }

  @override
  Future<UsernameCheck> checkHandle(String handle) async {
    checks.add(handle);
    return taken.contains(handle)
        ? UsernameCheck(
            available: false,
            normalized: handle,
            reason: UsernameRefusal.taken,
          )
        : UsernameCheck(available: true, normalized: handle);
  }

  @override
  Future<UserDto> updateProfile({
    String? handle,
    String? displayName,
    String? email,
    String? avatarRef,
    String? gitAuthorName,
    String? gitAuthorEmail,
  }) async {
    saves.add({
      'handle': handle,
      'display_name': displayName,
      'email': email,
      'avatar_ref': avatarRef,
    });
    if (refuseSave case final reason?) {
      throw UsernameRefusedException(reason);
    }
    return user = UserDto(
      id: user.id,
      handle: handle ?? user.handle,
      displayName: displayName ?? user.displayName,
      email: email ?? user.email,
      avatarRef: avatarRef ?? user.avatarRef,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppLocalizations l10n;
  late _Identity identity;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() => identity = _Identity());

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool demo = false,
    TextDirection? textDirection,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          activeWorkspaceIdOverride('ws-a'),
          identityRepositoryProvider.overrideWithValue(identity),
          // No GitHub sign-in: the avatar is the profile's or initials.
          githubUserProvider.overrideWith((ref) async => null),
        ],
        child: testWrap(
          SingleChildScrollView(child: child),
          isDemo: demo,
          textDirection: textDirection,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder usernameInput() => find.byType(CcTextField).first;

  Future<void> typeUsername(WidgetTester tester, String text) async {
    await tester.enterText(usernameInput(), text);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Finder saveButton() => find.widgetWithText(CcButton, l10n.save);

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<CcButton>(saveButton()).onPressed != null;

  group('account', () {
    testWidgets('shows the account row, not a workspace overlay', (
      tester,
    ) async {
      await pump(tester, const AccountProfileSection());
      expect(find.text('@sam'), findsOneWidget);
      expect(find.text(l10n.usernameLabel), findsOneWidget);
      expect(find.text(l10n.usernameRule), findsOneWidget);
      expect(find.text('sam@example.com'), findsOneWidget);
      // Nothing changed, nothing to save.
      expect(saveButton(), findsNothing);
    });

    testWidgets('a broken name is refused on the spot, without asking', (
      tester,
    ) async {
      await pump(tester, const AccountProfileSection());
      await typeUsername(tester, 'a');
      expect(find.text(l10n.usernameInvalid), findsOneWidget);
      expect(identity.checks, isEmpty);
      expect(saveEnabled(tester), isFalse);

      await typeUsername(tester, 'everyone');
      expect(find.text(l10n.usernameReserved), findsOneWidget);
      expect(identity.checks, isEmpty);
    });

    testWidgets('a taken name says so and cannot be saved', (tester) async {
      await pump(tester, const AccountProfileSection());
      await typeUsername(tester, 'ada');
      expect(identity.checks, ['ada']);
      expect(find.text(l10n.usernameTaken), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('typing fast asks only about the last name', (tester) async {
      await pump(tester, const AccountProfileSection());
      await tester.enterText(usernameInput(), 'sa');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(usernameInput(), 'samuel');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(identity.checks, ['samuel']);
      expect(find.text(l10n.usernameAvailable), findsOneWidget);
    });

    testWidgets('a free name saves, normalised, with only what changed', (
      tester,
    ) async {
      await pump(tester, const AccountProfileSection());
      await typeUsername(tester, 'Samuel');
      expect(find.text(l10n.usernameAvailableAs('samuel')), findsOneWidget);
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(identity.saves.single, {
        'handle': 'samuel',
        'display_name': null,
        'email': null,
        'avatar_ref': null,
      });
      expect(find.text('@samuel'), findsOneWidget);
      expect(find.text(l10n.profileSaved), findsOneWidget);
    });

    testWidgets('a name taken between the check and the save is refused in '
        'place', (tester) async {
      await pump(tester, const AccountProfileSection());
      await typeUsername(tester, 'samuel');
      identity.refuseSave = UsernameRefusal.taken;
      await tester.tap(saveButton());
      await tester.pumpAndSettle();
      expect(find.text(l10n.usernameTaken), findsOneWidget);
      expect(find.text('@sam'), findsOneWidget);
    });

    testWidgets('a field the server cannot clear says so', (tester) async {
      await pump(tester, const AccountProfileSection());
      await tester.enterText(find.byType(CcTextField).at(2), '');
      await tester.pump();
      expect(find.text(l10n.accountFieldCannotBeCleared), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('a picture must be an https link', (tester) async {
      await pump(tester, const AccountProfileSection());
      await tester.enterText(find.byType(CcTextField).at(3), 'ftp://x');
      await tester.pump();
      expect(find.text(l10n.accountAvatarInvalid), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('a failed read says so and retries', (tester) async {
      identity.meError = StateError('down');
      await pump(tester, const AccountProfileSection());
      expect(find.textContaining('down'), findsOneWidget);
      identity.meError = null;
      await tester.tap(find.text(l10n.retry));
      await tester.pumpAndSettle();
      expect(find.text('@sam'), findsOneWidget);
    });

    testWidgets('right to left: the username stays left to right', (
      tester,
    ) async {
      await pump(
        tester,
        const AccountProfileSection(),
        textDirection: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      final field = find.ancestor(
        of: usernameInput(),
        matching: find.byType(Directionality),
      );
      expect(
        tester.widget<Directionality>(field.first).textDirection,
        TextDirection.ltr,
      );
      expect(
        tester.widget<Text>(find.text('@sam')).textDirection,
        TextDirection.ltr,
      );
    });
  });

  group('single sign-on identity', () {
    testWidgets('shows the identity provider the account is pinned to', (
      tester,
    ) async {
      identity.ssoIssuer = 'https://idp.acme.dev';
      await pump(tester, const IdentityProviderSection());

      expect(find.text(l10n.settingsServerSso.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.ssoIdentityDescription), findsOneWidget);
      expect(find.text(l10n.linkedAccountsIdentityProvider), findsOneWidget);
      expect(find.text('https://idp.acme.dev'), findsOneWidget);
      expect(find.text(l10n.connectedLabel), findsOneWidget);
    });

    testWidgets('no identity provider renders nothing', (tester) async {
      await pump(tester, const IdentityProviderSection());
      expect(find.byType(SectionCard), findsNothing);
    });

    testWidgets('nothing while identity cannot be read', (tester) async {
      identity
        ..ssoIssuer = 'https://idp.acme.dev'
        ..meError = StateError('down');
      await pump(tester, const IdentityProviderSection());
      expect(find.byType(SectionCard), findsNothing);
    });

    testWidgets('right to left: the issuer stays left to right', (
      tester,
    ) async {
      identity.ssoIssuer = 'https://idp';
      await pump(
        tester,
        const IdentityProviderSection(),
        textDirection: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Text>(find.text('https://idp')).textDirection,
        TextDirection.ltr,
      );
    });
  });

  testWidgets('a demo server shows the demo notice and asks nothing', (
    tester,
  ) async {
    identity.meError = StateError('must not be asked');
    await pump(tester, const AccountProfileSection(), demo: true);
    expect(find.byType(DemoUnavailable), findsOneWidget);
    expect(find.text(l10n.demoUnavailableAccount), findsOneWidget);
  });
}
