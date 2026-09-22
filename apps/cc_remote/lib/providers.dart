import 'dart:async';
import 'dart:convert';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/feed_window.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/live_turns.dart';
import 'package:cc_remote/media_proxy.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:cc_remote/feed_window.dart';
export 'package:cc_remote/live_turns.dart';

/// Owns the phone→server connection lifecycle (the cc_rpc connection
/// supervisor + the stable [RemoteRpcClient] facade). Constructed once;
/// [RemoteSession.start] is kicked off in `main`.
final remoteSessionProvider = Provider<RemoteSession>((ref) {
  final session = RemoteSession();
  ref.onDispose(session.dispose);
  return session;
});

/// The latest [RemoteUiState], reactively. Screens and the connection chip
/// watch this; fall back to [RemoteSession.currentUiState] before the first
/// emission.
final remoteUiStateProvider = StreamProvider<RemoteUiState>(
  (ref) => ref.watch(remoteSessionProvider).uiState,
);

/// The stable [RemoteRpcClient], reactively. The session's `ResilientRpcClient`
/// survives reconnects (its `subscribe()` streams re-register transparently and
/// resume with a fresh snapshot), so it is emitted ONCE per pairing session —
/// feature providers never need to re-bind on a reconnect. A new client appears
/// only when the pairing itself is replaced (unpair → re-pair).
///
/// [RemoteSession.clientStream] is a non-replaying broadcast stream that emits
/// the client *before* the `connected` UI state that triggers navigation to the
/// feature screens. By the time those screens mount and watch this provider,
/// that single emission is gone. So we seed the controller with the current
/// client (if any) and forward subsequent emissions — late subscribers see the
/// already-connected client instead of hanging forever.
final rpcClientProvider = StreamProvider<RemoteRpcClient>((ref) {
  final session = ref.watch(remoteSessionProvider);
  final controller = StreamController<RemoteRpcClient>();
  final current = session.client;
  if (current != null) {
    controller.add(current);
  }
  final sub = session.clientStream.listen(
    controller.add,
    onError: controller.addError,
    onDone: controller.close,
  );
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

/// The active workspace id (persisted across refresh), reactively.
///
/// Seeded with [RemoteSession.activeWorkspaceId] for the same reason as
/// [rpcClientProvider]: the underlying stream is a non-replaying broadcast.
final activeWorkspaceIdProvider = StreamProvider<String?>((ref) {
  final session = ref.watch(remoteSessionProvider);
  final controller = StreamController<String?>();
  controller.add(session.activeWorkspaceId);
  final sub = session.activeWorkspaceStream.listen(
    controller.add,
    onError: controller.addError,
    onDone: controller.close,
  );
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

/// The live connection's signed-media origin, reactively — how the phone loads
/// a forge avatar without ever dialling an upstream itself.
///
/// Null until connected, and for the whole life of a broker-relayed session
/// (see [RemoteMediaEndpoint]); consumers fall back to a monogram rather than
/// showing a broken image. Avatars stay on this lane rather than moving to the
/// RPC channel the way [workspaceLogoProvider] did, because a PR list holds
/// dozens of them: one identity-carrying mark per workspace is worth a
/// base64 frame, a screenful of 22px faces is not.
///
/// Seeded with the session's current value for the same reason as
/// [rpcClientProvider]: the underlying stream is a non-replaying broadcast.
final mediaEndpointProvider = StreamProvider<RemoteMediaEndpoint?>((ref) {
  final session = ref.watch(remoteSessionProvider);
  final controller = StreamController<RemoteMediaEndpoint?>();
  controller.add(session.mediaEndpoint);
  final sub = session.mediaEndpointStream.listen(
    controller.add,
    onError: controller.addError,
    onDone: controller.close,
  );
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Workspace logo bytes via RPC (`workspace.logo`).
///
/// Signed HTTP `/workspace/logo` is preferred when reachable, but HTTPS PWAs
/// cannot open plaintext LAN sockets (mixed content) and often use the broker
/// relay (no HTTP origin). Kept alive for the session (small; avoid re-fetch).
/// Null → render the initial.
final workspaceLogoProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  workspaceId,
) async {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) {
    return null;
  }
  try {
    final data = await client.call('workspace.logo', {
      'workspace_id': workspaceId,
    });
    final encoded = data['bytes'];
    if (encoded is! String || encoded.isEmpty) {
      return null;
    }
    return base64Decode(encoded);
  } on Object {
    // A server too old to declare the op answers `opUnknown`; a decode failure
    // means the file is not an image. Both mean "no mark to draw".
    return null;
  }
});

/// A [ChangeNotifier] that fires whenever the session's UI state changes, so a
/// `GoRouter` can re-run its redirect (e.g. not-paired → `/connect`). Paired
/// with `GoRouter(refreshListenable: …)`.
class RouterRefresh extends ChangeNotifier {
  /// Creates a [RouterRefresh] wired to [session].
  RouterRefresh(this._session) {
    _sub = _session.uiState.listen((_) => notifyListeners());
  }

  final RemoteSession _session;
  late final StreamSubscription<RemoteUiState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// --- Feature data providers ---------------------------------------------
//
// Each subscribes via the cc_data remote repository over the stable RPC
// client. Reconnects are handled INSIDE the client (subscriptions re-register
// and resume with a fresh snapshot), so these rebuild only on first connect or
// when the pairing is replaced; until connected they yield an empty stream so
// the UI shows its loading state.
//
// EVERY workspace-scoped stream watches [activeWorkspaceIdProvider] and passes
// the id EXPLICITLY. Neither half is optional. `RemoteRpcClient` injects its
// ambient `activeWorkspaceId` only into args that do not already name one, and
// a subscription captures its args ONCE — so a stream opened before a workspace
// switch keeps re-registering with the OLD workspace for the rest of the
// session. That is how both workspaces came to show the same spaces.

/// All workspaces the device may switch between (live).
final workspacesProvider = StreamProvider<List<WorkspaceDto>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) return const Stream.empty();
  return RemoteWorkspaceRepository(client).watchAll();
});

/// Agents in the active workspace (live) — backs the messaging composer's
/// sender selection + ticket assignment.
final agentsProvider = StreamProvider<List<AgentDto>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  if (client == null || workspaceId == null) return const Stream.empty();
  return RemoteAgentRepository(client).watch(workspaceId);
});

/// Repos linked to the active workspace (live) — the join target for the PR
/// list's per-repo groups, which carry only a `repo_id`.
final workspaceReposProvider = StreamProvider<List<Repo>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  if (client == null || workspaceId == null) return const Stream.empty();
  return RpcWorkspaceRepository(client).watchReposForWorkspace(workspaceId);
});

/// Tickets in the active workspace (live).
final ticketsProvider = StreamProvider<List<TicketDto>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  if (client == null || workspaceId == null) return const Stream.empty();
  return RemoteTicketRepository(client).watch(workspaceId: workspaceId);
});

/// Spaces in the active workspace (live).
final spacesProvider = StreamProvider<List<SpaceDto>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  if (client == null || workspaceId == null) return const Stream.empty();
  return RemoteMessagingRepository(
    client,
  ).watchSpaces(workspaceId: workspaceId);
});

/// Newsfeed articles across all feeds (live; newsfeed is global).
final newsfeedArticlesProvider = StreamProvider<List<ArticleDto>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) return const Stream.empty();
  return RemoteNewsfeedRepository(client).watch();
});

/// Newsfeed feeds (live).
final newsfeedFeedsProvider = StreamProvider<List<FeedDto>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) return const Stream.empty();
  return RemoteNewsfeedRepository(client).watchFeeds();
});

/// The space's standing conversation (`conversation.ensure`), minted server-side
/// when the space has none yet.
///
/// The phone renders ONE stream per space — the standing conversation — and
/// leaves the multi-conversation strip and threads to desktop/web. It has to
/// be resolved rather than assumed: conversations own their own uuid, so the
/// old "the main conversation's id IS the space id" shortcut names no row and
/// every watch keyed on it comes back empty.
final spaceConversationIdProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, spaceId) async {
      final client = ref.watch(rpcClientProvider).value;
      final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || workspaceId == null) return null;
      final conversation = await RpcConversationRepository(
        client,
      ).ensure(workspaceId: workspaceId, spaceId: spaceId);
      return conversation.id;
    });

/// Live window of a space's standing conversation
/// (`messaging.watchMessagesWindow`).
///
/// Family so a conversation screen subscribes to exactly its space and
/// auto-resubscribes on reconnect. The wire is the newest
/// [remoteFeedWindowProvider] rows, not the whole thread — a long
/// conversation used to re-send its history on every write.
final spaceMessagesProvider = StreamProvider.autoDispose
    .family<({List<MessageDto> messages, bool hasMore}), String>((
      ref,
      spaceId,
    ) {
      final client = ref.watch(rpcClientProvider).value;
      final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
      final conversationId = ref
          .watch(spaceConversationIdProvider(spaceId))
          .value;
      final limit = ref.watch(remoteFeedWindowProvider(spaceId));
      if (client == null || workspaceId == null || conversationId == null) {
        return const Stream.empty();
      }
      return RemoteMessagingRepository(client)
          .watchMessagesWindow(
            workspaceId,
            spaceId,
            conversationId,
            limit: limit,
          )
          .map((window) {
            // A QUEUED steering card has not reached the agent yet — the desktop
            // renders it in the steering queue strip below the trail. The phone
            // has no strip (v1), so hide it here rather than showing it as a sent
            // bubble that did nothing. The moment it is injected (or converted
            // at run end) the row re-emits and renders as a normal user bubble.
            final messages = <MessageDto>[
              for (final m in window.messages)
                if (!(m.messageType == 'steering' &&
                    m.metadata is Map &&
                    (m.metadata as Map)['steerState'] == 'queued'))
                  m,
            ];
            return (
              messages: messages,
              hasMore: window.hasMore && limit < kRemoteFeedMaxWindow,
            );
          });
    });

/// Live turn relay for [spaceId], plus one-shot loads of finished transcripts.
///
/// List rows omit `segments`. Watching this starts the subscription even when
/// the thread is empty, so a turn that begins before its row arrives is
/// already folded when the tile builds. The value itself does not change per
/// token — tiles listen to one message's stream.
final phoneTurnRelayProvider = Provider.autoDispose
    .family<PhoneTurnRelay, String>((ref, spaceId) {
      final client = ref.watch(rpcClientProvider).value;
      final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
      final relay = PhoneTurnRelay(
        spaceId: spaceId,
        loadMessage: (messageId) async {
          if (client == null || workspaceId == null) {
            return const <TranscriptSegment>[];
          }
          final dto = await RemoteMessagingRepository(
            client,
          ).getMessageById(workspaceId, messageId);
          final metadata = dto?.metadata;
          if (metadata is! Map<dynamic, dynamic>) {
            return const <TranscriptSegment>[];
          }
          return decodeTranscript(metadata['segments']);
        },
      );
      if (client != null) {
        final sub = RemoteMessagingRepository(client)
            .watchSpaceTurns(spaceId)
            .listen((frame) {
              final event = spaceTurnEventFromWire(frame);
              if (event != null) {
                relay.applyEvent(event);
              }
            }, onError: (Object _, StackTrace _) {});
        ref.onDispose(() {
          unawaited(sub.cancel());
        });
      }
      return relay;
    });

/// Live active run logs for a conversation (`agent_run_log.watchActiveByConversation`)
/// — the run-level status/liveness/cost for an in-flight agent turn.
final activeRunLogsProvider = StreamProvider.autoDispose
    .family<List<AgentRunLogDto>, String>((ref, conversationId) {
      final client = ref.watch(rpcClientProvider).value;
      final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || workspaceId == null) return const Stream.empty();
      return RemoteAgentRunLogRepository(
        client,
      ).watchActiveByConversation(workspaceId, conversationId);
    });

/// Live pending agent-action approvals for a conversation
/// (`confirmation.watchPending`, narrowed SERVER-side to this conversation).
/// Each entry is a destructive command the agent is waiting on the phone to
/// approve or decline.
///
/// The narrowing used to happen here, in Dart, over a host-global stream — so
/// the command text and detail of every approval in every workspace this user
/// belongs to crossed the wire to the phone to be discarded on arrival.
final pendingConfirmationsProvider = StreamProvider.autoDispose
    .family<List<ConfirmationRequestDto>, String>((ref, spaceId) {
      final client = ref.watch(rpcClientProvider).value;
      if (client == null) return const Stream.empty();
      return RemoteConfirmationRepository(
        client,
      ).watchPending(spaceId: spaceId);
    });

/// Pending agent-action approvals in the ACTIVE workspace — the blocking half
/// of the inbox's attention strip. Each entry is an agent frozen mid-run,
/// waiting on a human.
///
/// `confirmation.watchPending` is host-global by design (a phone spans
/// workspaces, and the server already filters the stream to workspaces this
/// user is a member of). Narrowing to the active workspace here matches the
/// rest of the phone's chrome, which is workspace-scoped end to end: an
/// approval attributed to a workspace the header does not name is
/// unreadable — you cannot tell which agent, in which project, is stuck.
final workspacePendingConfirmationsProvider =
    StreamProvider<List<ConfirmationRequestDto>>((ref) {
      final client = ref.watch(rpcClientProvider).value;
      final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || workspaceId == null) return const Stream.empty();
      return RemoteConfirmationRepository(client).watchPending().map(
        (pending) => [
          for (final c in pending)
            if (c.workspaceId == null || c.workspaceId == workspaceId) c,
        ],
      );
    });

// --- Appearance settings (persisted) -----------------------------------

/// SharedPreferences singleton, overridden in `main` before `runApp` so the
/// appearance notifiers can read/write synchronously.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('sharedPrefsProvider must be overridden in main'),
);

/// Preferred brightness mode. `system` follows the platform; the other two pin
/// light/dark regardless of the OS setting.
enum ThemePreference { system, light, dark }

ThemePreference _themeFromString(String? raw) {
  return switch (raw) {
    'light' => ThemePreference.light,
    'dark' => ThemePreference.dark,
    _ => ThemePreference.system,
  };
}

/// Persisted theme preference. Drives the root [CcThemeData].
final themePreferenceProvider =
    NotifierProvider<ThemePreferenceNotifier, ThemePreference>(
      ThemePreferenceNotifier.new,
    );

/// Persisted locale preference (a BCP 47 tag like `ar-SA`, or null to follow
/// the platform). Same tag shape the desktop picker stores, so a shared
/// preference resolves on both clients.
final appLocaleProvider = NotifierProvider<AppLocaleNotifier, String?>(
  AppLocaleNotifier.new,
);

class ThemePreferenceNotifier extends Notifier<ThemePreference> {
  @override
  ThemePreference build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return _themeFromString(prefs.getString('theme_mode'));
  }

  void set(ThemePreference preference) {
    ref.read(sharedPrefsProvider).setString('theme_mode', preference.name);
    state = preference;
  }
}

class AppLocaleNotifier extends Notifier<String?> {
  @override
  String? build() {
    final saved = ref.watch(sharedPrefsProvider).getString('app_locale');
    return canonicalRemoteLocaleTag(saved);
  }

  void set(String? code) {
    final prefs = ref.read(sharedPrefsProvider);
    final tag = canonicalRemoteLocaleTag(code);
    if (tag == null) {
      prefs.remove('app_locale');
      state = null;
      return;
    }
    prefs.setString('app_locale', tag);
    state = tag;
  }
}
