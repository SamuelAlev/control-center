import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
// Playbooks (PRD 17 §10) have no cc_data repository yet, so their wire shape
// is parsed straight from cc_domain's pure-Dart entity — see [PlaybookDto].
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_remote/app_connection.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// A saved, parameterized plan template (PRD 17 §10), as seen by the phone.
///
/// Mirrors the `playbookToWire` wire shape the host emits for
/// `playbook.list`/`playbook.watchForWorkspace`. There is no cc_data
/// repository for playbooks yet, so this parses the raw map directly instead
/// of going through a generated Dto — `params` reuses cc_domain's own typed
/// [PlaybookParam] so the string/enumeration/repoRef/agentRef distinction (and
/// defaults/choices) come straight from the same model the server validates
/// against.
class PlaybookDto {
  /// Creates a [PlaybookDto].
  const PlaybookDto({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.description,
    required this.params,
    required this.version,
  });

  /// Parses the `playbook.*` wire shape.
  factory PlaybookDto.fromJson(Map<String, dynamic> json) => PlaybookDto(
    id: json['id'] as String? ?? '',
    workspaceId: json['workspace_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    params: Playbook.paramsFromJsonString(
      json['params_json'] as String? ?? '[]',
    ),
    version: json['version'] as int? ?? 1,
  );

  /// Unique id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Display name.
  final String name;

  /// What the playbook does / when to use it.
  final String description;

  /// Typed parameters, in declaration order.
  final List<PlaybookParam> params;

  /// Monotonic version, bumped on each save-over.
  final int version;
}

/// Playbooks in the active workspace (live; `playbook.watchForWorkspace`).
/// Running one only PROPOSES a plan — the operator still approves on the
/// desktop/web Plan Studio before anything executes or spends, which is what
/// makes triggering a playbook safe from the phone tier.
final playbooksProvider = StreamProvider<List<PlaybookDto>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) return const Stream.empty();
  return client
      .subscribe('playbook.watchForWorkspace', const {})
      .map(
        (data) => ((data['playbooks'] as List?) ?? const [])
            .whereType<Map>()
            .map((p) => PlaybookDto.fromJson(p.cast<String, dynamic>()))
            .toList(),
      );
});

/// Live messages in a channel's main conversation (`messaging.watchMessages`).
/// Family so a conversation screen subscribes to exactly its channel and
/// auto-resubscribes on reconnect. The remote client renders the `main`
/// conversation (id == channel id); parentheses are a desktop/web surface.
final channelMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageDto>, String>((ref, channelId) {
      final client = ref.watch(rpcClientProvider).value;
      final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || workspaceId == null) return const Stream.empty();
      return RemoteMessagingRepository(
        client,
      ).watchMessages(workspaceId, channelId, channelId);
    });

/// Live active run logs for a conversation (`agent_run_log.watchActiveByConversation`)
/// — the run-level status/liveness/cost for an in-flight agent turn. The
/// conversation id is the channel id.
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
    .family<List<ConfirmationRequestDto>, String>((ref, conversationId) {
      final client = ref.watch(rpcClientProvider).value;
      if (client == null) return const Stream.empty();
      return RemoteConfirmationRepository(
        client,
      ).watchPending(conversationId: conversationId);
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
