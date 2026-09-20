import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/general_panel.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
// `flutter_riverpod` does not re-export `Override`; `misc.dart` is its public
// home in riverpod 3.
import 'package:riverpod/misc.dart' show Override;

const _spaceId = 'space-1';
const _standingId = 'standing-1';
const _otherId = 'conv-2';

List<Override> _overrides() => [
  standingConversationIdProvider(
    _spaceId,
  ).overrideWith((ref) async => _standingId),
];

void main() {
  testWidgets(
    'falls back to the standing conversation when there is no router',
    (tester) async {
      String? resolved;
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                resolved = focusedConversationId(context, ref, _spaceId);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(resolved, _standingId);
    },
  );

  testWidgets(
    'uses the standing conversation when the URL names the space chat tab',
    (tester) async {
      String? resolved;
      final router = GoRouter(
        initialLocation: '/?tab=${MessagingTabKinds.chatSpaceTabKey(_spaceId)}',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Consumer(
              builder: (context, ref, _) {
                resolved = focusedConversationId(context, ref, _spaceId);
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(resolved, _standingId);
    },
  );

  testWidgets(
    'follows the focused chat tab in the URL when a router is present',
    (tester) async {
      String? resolved;
      final router = GoRouter(
        initialLocation: '/?tab=${MessagingTabKinds.chatTabKey(_otherId)}',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Consumer(
              builder: (context, ref, _) {
                resolved = focusedConversationId(context, ref, _spaceId);
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(resolved, _otherId);
    },
  );
}
