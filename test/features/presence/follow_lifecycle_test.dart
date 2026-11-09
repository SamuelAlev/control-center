import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/presence/providers/follow_providers.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/active_workspace.dart';

const _ada = UserPrincipal('ada');

ParticipantPresence _adaAt({String? spaceId, String? spotlight}) =>
    ParticipantPresence(
      principal: _ada,
      displayName: 'Ada',
      availability: PresenceAvailability.online,
      locus: spaceId == null ? null : SpaceLocus(spaceId: spaceId),
      spotlightSpaceId: spotlight,
    );

/// A shell stand-in: mounts the two sync providers over a minimal router.
Future<
  ({
    ProviderContainer container,
    GoRouter router,
    StreamController<List<ParticipantPresence>> roster,
  })
>
_pump(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/elsewhere', builder: (_, _) => const SizedBox()),
      GoRoute(
        path: '/workspaces/:ws/spaces/:space',
        builder: (_, _) => const SizedBox(),
      ),
    ],
  );
  addTearDown(router.dispose);
  final roster = StreamController<List<ParticipantPresence>>.broadcast();
  addTearDown(roster.close);
  final container = ProviderContainer(
    overrides: [
      activeWorkspaceIdOverride(),
      currentUserIdProvider.overrideWithValue('me'),
      routerProvider.overrideWithValue(router),
      presenceRosterProvider(
        kTestWorkspaceId,
      ).overrideWith((ref) => roster.stream),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          ref
            ..watch(followSyncProvider)
            ..watch(spotlightSyncProvider);
          return WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, router: router, roster: roster);
}

String _at(GoRouter router) => router.state.uri.toString();

void main() {
  testWidgets('a target with no locus never yanks the user back later', (
    tester,
  ) async {
    final h = await _pump(tester);
    h.roster.add([_adaAt()]);
    await tester.pumpAndSettle();
    h.container.read(followedPrincipalProvider.notifier).follow(_ada);
    await tester.pumpAndSettle();

    h.router.go('/elsewhere');
    await tester.pumpAndSettle();
    expect(h.container.read(followedPrincipalProvider), isNull);

    h.roster.add([_adaAt(spaceId: 's1')]);
    await tester.pumpAndSettle();
    expect(_at(h.router), '/elsewhere');
  });

  testWidgets('a followed locus drives navigation until the user acts', (
    tester,
  ) async {
    final h = await _pump(tester);
    h.roster.add([_adaAt(spaceId: 's1')]);
    await tester.pumpAndSettle();
    h.container.read(followedPrincipalProvider.notifier).follow(_ada);
    await tester.pumpAndSettle();
    expect(_at(h.router), '/workspaces/$kTestWorkspaceId/spaces/s1');
    expect(h.container.read(followedPrincipalProvider), _ada);
  });

  testWidgets('a spotlight does not end an active follow', (tester) async {
    final h = await _pump(tester);
    h.roster.add([_adaAt(spaceId: 's1')]);
    await tester.pumpAndSettle();
    h.container.read(followedPrincipalProvider.notifier).follow(_ada);
    await tester.pumpAndSettle();

    h.roster.add([
      _adaAt(spaceId: 's1'),
      ParticipantPresence(
        principal: const UserPrincipal('bo'),
        displayName: 'Bo',
        availability: PresenceAvailability.online,
        spotlightSpaceId: 's9',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(h.container.read(followedPrincipalProvider), _ada);
    expect(_at(h.router), '/workspaces/$kTestWorkspaceId/spaces/s1');
  });

  testWidgets('switching workspace ends the follow', (tester) async {
    final h = await _pump(tester);
    h.container.read(followedPrincipalProvider.notifier).follow(_ada);
    expect(h.container.read(followedPrincipalProvider), _ada);
    await h.container.read(activeWorkspaceIdProvider.notifier).setActive('ws2');
    expect(h.container.read(followedPrincipalProvider), isNull);
  });
}
