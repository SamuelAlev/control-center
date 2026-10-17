import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_read_repository.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/message_feed.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_route_selection.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/active_workspace.dart';

/// Uses the real persisted acknowledgement rather than counting cursor calls.
class _PersistedReads implements SpaceReadRepository {
  _PersistedReads(this.dao);

  final NotificationFeedDao dao;

  @override
  Future<void> markSpaceRead(
    String workspaceId,
    String spaceId,
    String userId, {
    String? conversationId,
  }) async {
    if (conversationId != null) {
      await dao.markConversationMessagesRead(
        workspaceId,
        userId,
        spaceId: spaceId,
        conversationId: conversationId,
        readAt: DateTime(2026, 10, 13, 12),
      );
    }
  }

  @override
  Stream<DateTime?> watchUserLastReadAt(
    String workspaceId,
    String spaceId,
    String userId,
  ) => Stream.value(null);

  @override
  Stream<Map<String, DateTime>> watchUserSpaceReads(
    String workspaceId,
    String userId,
  ) => Stream.value(const {});
}

void main() {
  for (final (leaveSpace, refresh) in [
    (true, true),
    (true, false),
    (false, true),
  ]) {
    testWidgets(
      leaveSpace
          ? 'sidebar return acknowledges ${refresh ? 'a completed turn' : 'an unchanged cached turn'}'
          : 'visible completion acknowledges a turn with the same id',
      (tester) async {
        final db = WorkspaceDatabase.forTesting(
          NativeDatabase.memory(),
          workspaceId: 'ws-1',
        );
        addTearDown(db.close);
        final dao = db.notificationFeedDao;
        final window =
            StreamController<
              ({List<Message> messages, bool hasMore})
            >.broadcast();
        addTearDown(window.close);
        final unfinished = Message(
          id: 'turn-1',
          spaceId: 'space-1',
          conversationId: 'conv-1',
          senderId: 'agent-1',
          senderType: SenderType.agent,
          content: refresh ? 'Partial answer' : 'Final answer',
          messageType: MessageType.agentTurn,
          metadata: {'streamComplete': !refresh},
          createdAt: DateTime(2026, 10, 13, 10),
        );
        final router = GoRouter(
          initialLocation: '/workspaces/ws-1/spaces/space-1',
          routes: [
            GoRoute(
              path: '/workspaces/:workspaceId/spaces/:spaceId',
              builder: (context, state) => Scaffold(
                body: CcTheme(
                  data: CcThemeData.light(),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          CcButton(
                            onPressed: () =>
                                openSpaceFromSidebar(context, 'space-1'),
                            child: const Text('Agent space'),
                          ),
                          CcButton(
                            onPressed: () =>
                                openSpaceFromSidebar(context, 'space-2'),
                            child: const Text('Other space'),
                          ),
                        ],
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: state.pathParameters['spaceId'] == 'space-1'
                              ? 0
                              : 1,
                          sizing: StackFit.expand,
                          children: const [
                            SpaceMessageFeed(
                              spaceId: 'space-1',
                              conversationId: 'conv-1',
                            ),
                            Center(child: Text('Other conversation')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeWorkspaceIdOverride('ws-1'),
              currentUserIdProvider.overrideWithValue('user-1'),
              spaceFeedWindowedProvider((
                spaceId: 'space-1',
                conversationId: 'conv-1',
              )).overrideWith((ref) async* {
                // A cached unfinished row can precede the fresh completion.
                yield (messages: [unfinished], hasMore: false);
                yield* window.stream;
              }),
              spaceTurnRelayProvider('space-1').overrideWith((ref) {}),
              codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
              spaceUserLastReadAtProvider(
                'space-1',
              ).overrideWith((ref) => Stream.value(null)),
              spaceReadRepositoryProvider.overrideWithValue(
                _PersistedReads(dao),
              ),
              agentDetailProvider('agent-1').overrideWith((ref) async => null),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
        expect(
          find.text(
            refresh ? 'Partial answer' : 'Final answer',
            findRichText: true,
          ),
          findsOneWidget,
        );

        if (leaveSpace) {
          await tester.tap(find.text('Other space'));
          await tester.pumpAndSettle();
          expect(find.text('Other conversation'), findsOneWidget);
        }
        await tester.runAsync(() async {
          for (final conversation in ['conv-1', 'conv-2']) {
            await dao.insertAndPrune(
              NotificationFeedTableCompanion.insert(
                id: 'completed-$conversation',
                workspaceId: 'ws-1',
                method: NotificationFeedDao.messageReceivedMethod,
                paramsJson: jsonEncode({
                  'workspace_id': 'ws-1',
                  'space_id': 'space-1',
                  'conversation_id': conversation,
                }),
                createdAt: Value(DateTime(2026, 10, 13, 11)),
              ),
            );
          }
          expect(await dao.watchItemStates('ws-1', 'user-1').first, isEmpty);
        });

        if (leaveSpace) {
          await tester.tap(find.text('Agent space'));
          await tester.pumpAndSettle();
        }
        if (refresh) {
          window.add((
            messages: [
              unfinished.copyWith(
                content: 'Final answer',
                metadata: const {'streamComplete': true},
              ),
            ],
            hasMore: false,
          ));
        }
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Final answer', findRichText: true), findsOneWidget);
        await tester.runAsync(() async {
          final states = await dao.watchItemStates('ws-1', 'user-1').first;
          expect(
            {
              for (final state in states)
                if (state.readAt != null) state.itemId,
            },
            {'completed-conv-1'},
            reason: 'Reading the completed turn clears only its notification',
          );
          expect(await dao.watchItemStates('ws-1', 'user-2').first, isEmpty);
        });
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
