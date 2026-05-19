import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_connection.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the phone→Mac connection lifecycle (signaling + WebRTC/relay + PSK
/// handshake + the [RemoteRpcClient]). Constructed once; [RemoteSession.start]
/// is kicked off in `main`.
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

/// The active [RemoteRpcClient], reactively. Emits a fresh client on every
/// successful (re)connect; feature providers watch this so they re-subscribe on
/// the new transport automatically (a reconnect swaps the client).
///
/// [RemoteSession.clientStream] is a non-replaying broadcast stream that emits
/// the client exactly once, *before* the `connected` UI state that triggers
/// navigation to the feature screens. By the time those screens mount and watch
/// this provider, that single emission is gone. So we seed the controller with
/// the current client (if any) and forward subsequent emissions — late
/// subscribers see the already-connected client instead of hanging forever.
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
// Each subscribes via the cc_data remote repository over the live RPC client.
// They rebuild whenever [rpcClientProvider] emits a new client (a reconnect),
// re-subscribing on the fresh transport; until connected they yield an empty
// stream so the UI shows its loading state.

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
  if (client == null) return const Stream.empty();
  return RemoteAgentRepository(client).watch();
});

/// Tickets in the active workspace (live).
final ticketsProvider = StreamProvider<List<TicketDto>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) return const Stream.empty();
  return RemoteTicketRepository(client).watch();
});

/// Channels in the active workspace (live).
final channelsProvider = StreamProvider<List<ChannelDto>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) return const Stream.empty();
  return RemoteMessagingRepository(client).watchChannels();
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

/// Live messages in a channel (`messaging.watchMessages`). Family so a thread
/// screen subscribes to exactly its channel and auto-resubscribes on reconnect.
final channelMessagesProvider =
    StreamProvider.autoDispose.family<List<MessageDto>, String>((ref, channelId) {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) return const Stream.empty();
  return RemoteMessagingRepository(client).watchMessages(channelId);
});

/// Live active run logs for a conversation (`agent_run_log.watchActiveByConversation`)
/// — the run-level status/liveness/cost for an in-flight agent turn. The
/// conversation id is the channel id.
final activeRunLogsProvider =
    StreamProvider.autoDispose.family<List<AgentRunLogDto>, String>((
  ref,
  conversationId,
) {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) return const Stream.empty();
  return RemoteAgentRunLogRepository(client)
      .watchActiveByConversation(conversationId);
});

/// Live pending agent-action approvals for a conversation
/// (`confirmation.watchPending`, host-global, filtered to this conversation).
/// Each entry is a destructive command the agent is waiting on the phone to
/// approve or decline.
final pendingConfirmationsProvider =
    StreamProvider.autoDispose.family<List<ConfirmationRequestDto>, String>((
  ref,
  conversationId,
) {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) return const Stream.empty();
  return RemoteConfirmationRepository(client)
      .watchPending()
      .map((list) => list
          .where((c) => c.conversationId == conversationId)
          .toList());
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

/// Persisted locale preference (a language code, or null to follow the
/// platform). The phone PWA's chrome is English today; this stores the choice
/// and applies the locale so translated strings take effect once added.
final appLocaleProvider =
    NotifierProvider<AppLocaleNotifier, String?>(AppLocaleNotifier.new);

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
    return ref.watch(sharedPrefsProvider).getString('app_locale');
  }

  void set(String? code) {
    final prefs = ref.read(sharedPrefsProvider);
    if (code == null) {
      prefs.remove('app_locale');
    } else {
      prefs.setString('app_locale', code);
    }
    state = code;
  }
}
