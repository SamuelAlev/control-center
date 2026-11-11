import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/features/connect/domain/value_objects/connect_health_error.dart';
import 'package:collection/collection.dart';

/// The server's own Connect choice, as a workspace that follows it sees it.
enum ServerConnectChoice {
  /// The server owner has not chosen; the server's own apps apply.
  unset,

  /// Control Center's hosted Connect.
  hosted,

  /// A Connect at the server owner's URL.
  custom,

  /// Connect is off; the server's own apps apply.
  off;

  /// Parses a wire value; [unset] for anything unknown.
  static ServerConnectChoice fromWire(Object? wire) {
    for (final choice in values) {
      if (choice.name == wire) {
        return choice;
      }
    }
    return unset;
  }
}

/// What a workspace actually runs on once `inherit` is resolved.
enum WorkspaceConnectEffective {
  /// Control Center's hosted Connect (the workspace's or the server's).
  hosted,

  /// A custom Connect (the workspace's or the server's).
  custom,

  /// The workspace follows a server that runs on its own apps.
  serverOwn,

  /// The workspace's own apps.
  own,

  /// Nothing can sign anyone in.
  off;

  /// Parses a wire value; [off] for anything unknown.
  static WorkspaceConnectEffective fromWire(Object? wire) => switch (wire) {
    'hosted' => hosted,
    'custom' => custom,
    'server_own' => serverOwn,
    'own' => own,
    _ => off,
  };

  /// Whether sign-ins run through a Connect.
  bool get usesConnect => this == hosted || this == custom;
}

/// Whether the Connect a workspace runs on is answering.
enum WorkspaceConnectHealth {
  /// No Connect is in use.
  off,

  /// Connect answers with a verified configuration.
  ok,

  /// Connect is in use but not usable.
  down;

  /// Parses a wire value; [off] for anything unknown.
  static WorkspaceConnectHealth fromWire(Object? wire) => switch (wire) {
    'ok' => ok,
    'down' => down,
    _ => off,
  };
}

/// Where one provider's sign-ins and requests run for a workspace.
enum WorkspaceLaneSource {
  /// The workspace's own app.
  workspaceOwn,

  /// The server's own app.
  serverOwn,

  /// A Control Center Connect.
  connect,

  /// Nothing: the provider is off here.
  off;

  /// Parses a wire value; [off] for anything unknown.
  static WorkspaceLaneSource fromWire(Object? wire) => switch (wire) {
    'workspace_own' => workspaceOwn,
    'server_own' => serverOwn,
    'connect' => connect,
    _ => off,
  };
}

/// One provider lane in `workspaceConnect.status`.
final class WorkspaceConnectLane {
  /// Creates a [WorkspaceConnectLane]. [provider] must not be empty.
  WorkspaceConnectLane({
    required this.provider,
    required this.source,
    this.error = '',
  }) {
    if (provider.isEmpty) {
      throw ArgumentError.value(provider, 'provider', 'must not be empty');
    }
  }

  /// The provider's wire id (`github`, `google`, `linear`, `slack`, `klipy`).
  final String provider;

  /// Where it runs.
  final WorkspaceLaneSource source;

  /// Why it does not work, already phrased for a person; empty when it does.
  final String error;

  @override
  bool operator ==(Object other) =>
      other is WorkspaceConnectLane &&
      other.provider == provider &&
      other.source == source &&
      other.error == error;

  @override
  int get hashCode => Object.hash(provider, source, error);
}

/// One workspace's Control Center Connect choice and how it is doing.
///
/// [installId] and [pendingPins] are admin-only: the server omits them for
/// members, so they are null (not empty) then.
final class WorkspaceConnectStatus {
  /// Creates a [WorkspaceConnectStatus]. The epoch is never negative.
  WorkspaceConnectStatus({
    required this.mode,
    this.url = '',
    this.serverMode = ServerConnectChoice.unset,
    this.serverUrl = '',
    this.effectiveMode = WorkspaceConnectEffective.off,
    this.locked = false,
    this.health = WorkspaceConnectHealth.off,
    this.error = ConnectHealthError.none,
    this.stale = false,
    this.epoch,
    List<WorkspaceConnectLane> lanes = const [],
    this.installId,
    Map<String, String>? pendingPins,
  }) : lanes = List.unmodifiable(lanes),
       pendingPins = pendingPins == null
           ? null
           : Map.unmodifiable(pendingPins) {
    final epoch = this.epoch;
    if (epoch != null && epoch < 0) {
      throw ArgumentError.value(epoch, 'epoch', 'must not be negative');
    }
  }

  /// The workspace's own choice.
  final WorkspaceConnectMode mode;

  /// The workspace's custom Connect URL; empty unless [mode] is custom.
  final String url;

  /// The server's own choice, which [WorkspaceConnectMode.inherit] follows.
  final ServerConnectChoice serverMode;

  /// The server's Connect base URL when it uses one; else empty.
  final String serverUrl;

  /// What the workspace actually runs on.
  final WorkspaceConnectEffective effectiveMode;

  /// Whether `CC_CONNECT_URL` forbids a Connect of the workspace's own.
  final bool locked;

  /// Whether the Connect in use answers.
  final WorkspaceConnectHealth health;

  /// Why it does not.
  final ConnectHealthError error;

  /// Whether the configuration in use is a cached copy past its refresh.
  final bool stale;

  /// The configuration epoch in use, or null before the first fetch.
  final int? epoch;

  /// Every provider and where it runs, in the server's order.
  final List<WorkspaceConnectLane> lanes;

  /// This server's install id on the Connect in use; null for members.
  final String? installId;

  /// New signing pins waiting for an admin, or null.
  final Map<String, String>? pendingPins;

  /// The lane for [provider], or null when the server did not report one.
  WorkspaceConnectLane? laneFor(String provider) =>
      lanes.firstWhereOrNull((lane) => lane.provider == provider);

  @override
  bool operator ==(Object other) =>
      other is WorkspaceConnectStatus &&
      other.mode == mode &&
      other.url == url &&
      other.serverMode == serverMode &&
      other.serverUrl == serverUrl &&
      other.effectiveMode == effectiveMode &&
      other.locked == locked &&
      other.health == health &&
      other.error == error &&
      other.stale == stale &&
      other.epoch == epoch &&
      const ListEquality<WorkspaceConnectLane>().equals(other.lanes, lanes) &&
      other.installId == installId &&
      const MapEquality<String, String>().equals(
        other.pendingPins,
        pendingPins,
      );

  @override
  int get hashCode => Object.hash(
    mode,
    url,
    serverMode,
    serverUrl,
    effectiveMode,
    locked,
    health,
    error,
    stale,
    epoch,
    const ListEquality<WorkspaceConnectLane>().hash(lanes),
    installId,
    const MapEquality<String, String>().hash(pendingPins),
  );
}
