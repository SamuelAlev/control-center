import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/di/settings_registry.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/screens/account_profile_settings_screen.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/account_profile_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/identity_provider_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_wrap.dart';

/// The caller's account on a pretend server, answered when [gate] opens.
class _Identity implements RemoteIdentityRepository {
  String ssoIssuer = '';
  Completer<void>? gate;

  @override
  Future<IdentityMe> me({String? workspaceId}) async {
    await gate?.future;
    return IdentityMe(
      user: UserDto(id: 'u-1', handle: 'sam', displayName: 'Sam Smith'),
      deviceId: 'd-1',
      isServerOwner: false,
      memberships: const [],
      ssoIssuer: ssoIssuer,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// You → Profile holds two subjects on one page: the profile, which settings
/// owns, then the person's connected accounts under their own heading, which
/// the features contribute. Each shipped contribution renders as its id
/// here, so the page is tested without the providers behind the cards.
void main() {
  late AppLocalizations l10n;
  late SettingsRegistry shipped;
  late _Identity identity;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final container = ProviderContainer();
    shipped = container.read(settingsRegistryProvider);
    container.dispose();
  });

  setUp(() => identity = _Identity());

  SettingsRegistry stubbed() => SettingsRegistry(
    sections: [
      for (final s in shipped.sections)
        SettingsSectionContribution(
          id: s.id,
          slot: s.slot,
          order: s.order,
          builder: (_) => SizedBox(
            height: 40,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(s.id),
            ),
          ),
        ),
    ],
  );

  Future<GoRouter> pump(
    WidgetTester tester, {
    bool atAccounts = false,
    Size size = const Size(1200, 2400),
    TextDirection textDirection = TextDirection.ltr,
    bool settle = true,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: atAccounts
          ? settingsAccountsRoute('ws-1')
          : settingsAccountProfileRoute('ws-1'),
      routes: [
        GoRoute(
          path: settingsAccountProfileRoute(':workspaceId'),
          builder: (_, state) => Directionality(
            textDirection: textDirection,
            child: AccountProfileSettingsScreen(
              openAtAccounts: opensAtConnectedAccounts(state.uri),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRegistryProvider.overrideWithValue(stubbed()),
          identityRepositoryProvider.overrideWithValue(identity),
          // No GitHub sign-in: the avatar is the profile's or initials.
          githubUserProvider.overrideWith((ref) async => null),
        ],
        child: testRouterWrap(router),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return router;
  }

  const expectedOrder = [
    'forge.connections',
    'ticketing.account',
    'calendar.accounts',
    'chat_bridges.my-account-link',
    'chat_bridges.ticket-drafts',
  ];

  Finder heading() => find.text(l10n.linkedAccountsTitle);

  /// Where the page's scrolling area starts.
  double scrollTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(CustomScrollView)).dy;

  testWidgets('the profile, then the connected accounts under their heading, '
      'grouped by provider', (tester) async {
    await pump(tester);

    expect(find.text(l10n.accountProfileTitle), findsOneWidget);
    expect(find.text(l10n.accountProfileDescription), findsOneWidget);
    expect(find.text(l10n.settingsAccountsDescription), findsOneWidget);
    expect(tester.getSemantics(heading()).flagsCollection.isHeader, isTrue);

    final profile = find.byType(AccountProfileSection);
    expect(tester.getTopLeft(profile).dy, scrollTop(tester) + 8);
    final tops = [
      tester.getBottomLeft(profile).dy,
      tester.getTopLeft(heading()).dy,
      for (final id in expectedOrder) tester.getTopLeft(find.text(id)).dy,
    ];
    expect(tops, [...tops]..sort(), reason: 'cards render in band order');
    // What the workspace decides stays on Workspace → Integrations.
    for (final id in const [
      'connect.workspace',
      'forge.account-status',
      'forge.github-app',
      'forge.automation-tokens',
      'ticketing.connection',
      'chat_bridges.workspace-setup',
      'settings.gifs',
    ]) {
      expect(find.text(id), findsNothing, reason: id);
    }
  });

  testWidgets('the heading keeps twice the room above it that a card does', (
    tester,
  ) async {
    await pump(tester);
    // No identity provider: no empty card, so no second gap.
    expect(find.byType(IdentityProviderSection), findsNothing);
    expect(
      tester.getTopLeft(heading()).dy -
          tester.getBottomLeft(find.byType(AccountProfileSection)).dy,
      32,
    );
  });

  testWidgets('an identity provider card sits between the profile and the '
      'heading', (tester) async {
    identity.ssoIssuer = 'https://idp.acme.dev';
    await pump(tester);
    final sso = find.byType(IdentityProviderSection);
    expect(
      tester.getTopLeft(sso).dy -
          tester.getBottomLeft(find.byType(AccountProfileSection)).dy,
      16,
    );
    expect(tester.getTopLeft(heading()).dy - tester.getBottomLeft(sso).dy, 32);
  });

  testWidgets('a link about an account opens the page at the heading, with '
      'the profile one scroll above', (tester) async {
    await pump(tester, atAccounts: true, size: const Size(1200, 800));

    final top = scrollTop(tester);
    expect(tester.getTopLeft(heading()).dy, top + 16);
    expect(find.text('forge.connections').hitTestable(), findsOneWidget);
    expect(find.text('@sam').hitTestable(), findsNothing);

    // More than the profile is tall: the scroll stops at the page's top.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 900));
    await tester.pumpAndSettle();
    expect(find.text('@sam').hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(find.byType(AccountProfileSection)).dy, top + 8);
  });

  testWidgets('the profile filling in above does not move the accounts', (
    tester,
  ) async {
    identity.gate = Completer<void>();
    await pump(
      tester,
      atAccounts: true,
      size: const Size(1200, 800),
      settle: false,
    );
    final before = tester.getTopLeft(heading()).dy;
    expect(before, scrollTop(tester) + 16);

    // The spinner becomes the whole form, several hundred pixels taller.
    identity.gate!.complete();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(heading()).dy, before);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 900));
    await tester.pumpAndSettle();
    expect(find.text('@sam').hitTestable(), findsOneWidget);
  });

  testWidgets('going to the profile itself from there shows its top', (
    tester,
  ) async {
    final router = await pump(
      tester,
      atAccounts: true,
      size: const Size(1200, 800),
    );
    router.go(settingsAccountProfileRoute('ws-1'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byType(AccountProfileSection)).dy,
      scrollTop(tester) + 8,
    );
    expect(find.text('@sam').hitTestable(), findsOneWidget);
  });

  testWidgets('right to left keeps the order and mirrors the page', (
    tester,
  ) async {
    await pump(tester, textDirection: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    final tops = [
      tester.getTopLeft(heading()).dy,
      for (final id in expectedOrder) tester.getTopLeft(find.text(id)).dy,
    ];
    expect(tops, [...tops]..sort());
    final page = tester.getCenter(find.byType(AccountProfileSettingsScreen)).dx;
    expect(tester.getTopRight(heading()).dx, greaterThan(page));
    expect(
      tester.getTopRight(find.text('forge.connections')).dx,
      greaterThan(page),
    );
  });
}
