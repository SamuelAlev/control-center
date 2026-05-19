import 'package:control_center/core/providers/server_switch_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_pairing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings-side view of the client's paired-server list (PRD 15 §10).
class ServerListState {
  /// Creates a [ServerListState].
  const ServerListState({
    required this.mode,
    required this.entries,
    required this.activeServerId,
    this.busy = false,
  });

  /// Local spawn vs remote server.
  final ServerConnectionMode mode;

  /// Every paired server.
  final List<ServerEntry> entries;

  /// The active remote server's id (meaningful in remote mode).
  final String? activeServerId;

  /// Whether an add/switch operation is in flight.
  final bool busy;

  /// The id the switcher treats as current: `local` in local mode, else the
  /// active entry.
  String get currentServerId =>
      mode == ServerConnectionMode.local ? 'local' : (activeServerId ?? '');

  /// Copy with fields replaced.
  ServerListState copyWith({
    ServerConnectionMode? mode,
    List<ServerEntry>? entries,
    String? activeServerId,
    bool? busy,
  }) => ServerListState(
    mode: mode ?? this.mode,
    entries: entries ?? this.entries,
    activeServerId: activeServerId ?? this.activeServerId,
    busy: busy ?? this.busy,
  );
}

/// The paired-server list + actions (add via invite/URL, switch, remove).
final serverListProvider =
    NotifierProvider<ServerListNotifier, ServerListState>(
      ServerListNotifier.new,
    );

/// Notifier backing [serverListProvider]. Persists through the same
/// [ServerConnectionStore] the boot resolver reads; switching delegates to
/// the platform's switch handler (desktop rebuilds the provider tree, web
/// remounts the gate).
class ServerListNotifier extends Notifier<ServerListState> {
  late ServerConnectionStore _store;

  @override
  ServerListState build() {
    _store = ServerConnectionStore(
      ref.read(appPreferencesProvider),
      ref.read(secureStoreProvider),
    );
    return _read();
  }

  ServerListState _read() => ServerListState(
    // The web client can never run a local server (a browser cannot spawn a
    // subprocess), so it is always in remote mode.
    mode: kIsWeb ? ServerConnectionMode.remote : _store.readMode(),
    entries: _store.readEntries(),
    activeServerId: _store.readActive()?.serverId,
  );

  /// Re-reads the store (after external changes).
  void refresh() => state = _read().copyWith(busy: state.busy);

  /// Pairs with a new server (invite code, or manual URL + credentials),
  /// then switches the app to it.
  Future<void> addServer({
    required String rawUrl,
    String inviteCode = '',
    String deviceId = '',
    String psk = '',
  }) async {
    state = state.copyWith(busy: true);
    try {
      final connection = await pairWithServer(
        store: _store,
        rawUrl: rawUrl,
        platform: kIsWeb ? 'web' : 'desktop',
        inviteCode: inviteCode,
        deviceId: deviceId,
        psk: psk,
      );
      final serverId = connection.entry.serverId;
      // The pairing connection was only the verification vehicle; the switch
      // builds the app's real session.
      await connection.dispose();
      await ref.read(serverSwitchHandlerProvider)(serverId);
      _refreshIfAlive();
    } finally {
      _clearBusyIfAlive();
    }
  }

  /// Switches the app to [serverId] (a paired server id, or `local`).
  Future<void> switchTo(String serverId) async {
    state = state.copyWith(busy: true);
    try {
      // The switch handler owns persistence: the desktop's
      // `resolveServerBackend(forceServerId:)` and the web gate's `_switchTo`
      // both flip the stored mode / active server as part of connecting.
      // Writing it again here would run AFTER the switch has already replaced
      // this provider tree, on a container that no longer exists.
      await ref.read(serverSwitchHandlerProvider)(serverId);
      _refreshIfAlive();
    } finally {
      _clearBusyIfAlive();
    }
  }

  /// Re-reads the store into [state], but only while this notifier is still
  /// alive.
  ///
  /// A successful switch rebuilds the whole app around the new session, which
  /// disposes the container this notifier lives in — so by the time the
  /// handler's future completes there may be no notifier left to update.
  /// Touching `state` then throws a "Ref used after dispose" [StateError],
  /// which the settings UI would surface as "Could not switch server" even
  /// though the switch succeeded.
  void _refreshIfAlive() {
    if (ref.mounted) {
      state = _read();
    }
  }

  /// Clears the in-flight flag, unless the operation replaced this container
  /// (see [_refreshIfAlive]).
  void _clearBusyIfAlive() {
    if (ref.mounted) {
      state = state.copyWith(busy: false);
    }
  }

  /// Removes a paired server (refused for the currently active one — switch
  /// away first; the UI disables the control).
  Future<void> remove(String serverId) async {
    if (serverId == state.currentServerId) {
      throw StateError('Switch to another server before removing this one.');
    }
    await _store.removeEntry(serverId);
    state = _read();
  }
}
