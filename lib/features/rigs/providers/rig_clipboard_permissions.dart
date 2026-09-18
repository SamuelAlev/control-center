import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persisted preference key for host-to-rig clipboard transfers.
const String rigClipboardHostToRigAlwaysKey =
    'rig_clipboard_host_to_rig_always';

/// Persisted preference key for rig-to-host clipboard transfers.
const String rigClipboardRigToHostAlwaysKey =
    'rig_clipboard_rig_to_host_always';

/// Which side of the enclosure boundary receives clipboard content.
enum RigClipboardDirection {
  /// Read the operator's local clipboard and send it into an enclosure.
  hostToRig,

  /// Read an enclosure clipboard and publish it on the operator's device.
  rigToHost,
}

/// The durable clipboard choices that follow the signed-in user.
class RigClipboardPreferences {
  /// Creates a clipboard preference snapshot. Sending clipboard content into
  /// an enclosure is allowed by default; reading content back out is not.
  const RigClipboardPreferences({
    this.alwaysAllowHostToRig = true,
    this.alwaysAllowRigToHost = false,
  });

  /// Whether host clipboard content may enter any enclosure without prompting.
  final bool alwaysAllowHostToRig;

  /// Whether enclosure clipboard content may reach this user's device without
  /// prompting.
  final bool alwaysAllowRigToHost;

  /// Whether [direction] is durably allowed.
  bool allows(RigClipboardDirection direction) => switch (direction) {
    RigClipboardDirection.hostToRig => alwaysAllowHostToRig,
    RigClipboardDirection.rigToHost => alwaysAllowRigToHost,
  };

  /// Returns a snapshot with [direction] changed to [allowed].
  RigClipboardPreferences withPermission(
    RigClipboardDirection direction, {
    required bool allowed,
  }) => switch (direction) {
    RigClipboardDirection.hostToRig => RigClipboardPreferences(
      alwaysAllowHostToRig: allowed,
      alwaysAllowRigToHost: alwaysAllowRigToHost,
    ),
    RigClipboardDirection.rigToHost => RigClipboardPreferences(
      alwaysAllowHostToRig: alwaysAllowHostToRig,
      alwaysAllowRigToHost: allowed,
    ),
  };

  @override
  bool operator ==(Object other) =>
      other is RigClipboardPreferences &&
      other.alwaysAllowHostToRig == alwaysAllowHostToRig &&
      other.alwaysAllowRigToHost == alwaysAllowRigToHost;

  @override
  int get hashCode => Object.hash(alwaysAllowHostToRig, alwaysAllowRigToHost);
}

/// The current durable clipboard policy for this user.
final rigClipboardPreferencesProvider =
    NotifierProvider<RigClipboardPreferencesNotifier, RigClipboardPreferences>(
      RigClipboardPreferencesNotifier.new,
    );

/// Loads and persists the user's durable clipboard choices.
class RigClipboardPreferencesNotifier
    extends Notifier<RigClipboardPreferences> {
  late AppPreferences _preferences;

  @override
  RigClipboardPreferences build() {
    _preferences = ref.watch(appPreferencesProvider);
    return RigClipboardPreferences(
      alwaysAllowHostToRig:
          _preferences.getBool(rigClipboardHostToRigAlwaysKey) ?? true,
      alwaysAllowRigToHost:
          _preferences.getBool(rigClipboardRigToHostAlwaysKey) ?? false,
    );
  }

  /// Changes whether [direction] is allowed without prompting.
  Future<void> setAlwaysAllowed(
    RigClipboardDirection direction, {
    required bool allowed,
  }) async {
    final key = switch (direction) {
      RigClipboardDirection.hostToRig => rigClipboardHostToRigAlwaysKey,
      RigClipboardDirection.rigToHost => rigClipboardRigToHostAlwaysKey,
    };
    await _preferences.setBool(key, value: allowed);
    state = state.withPermission(direction, allowed: allowed);
  }
}

/// In-memory grants made from a confirmation dialog.
///
/// A grant is scoped to one live rig and one direction. Destroying the client
/// process or closing the rig can only shorten the requested ten-minute window;
/// it can never silently turn a temporary grant into a durable one.
class RigClipboardSessionGrants {
  /// Creates an empty temporary grant store.
  RigClipboardSessionGrants({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Duration of a temporary dialog grant.
  static const Duration grantDuration = Duration(minutes: 10);

  final DateTime Function() _now;
  final Map<(String, RigClipboardDirection), DateTime> _expiresAt = {};

  /// Whether [rigId] currently has a temporary grant for [direction].
  bool allows(String rigId, RigClipboardDirection direction) {
    final key = (rigId, direction);
    final expiry = _expiresAt[key];
    if (expiry == null) {
      return false;
    }
    if (!_now().isBefore(expiry)) {
      _expiresAt.remove(key);
      return false;
    }
    return true;
  }

  /// Grants [direction] for [rigId] for exactly ten minutes.
  void allowForTenMinutes(String rigId, RigClipboardDirection direction) {
    _expiresAt[(rigId, direction)] = _now().add(grantDuration);
  }

  /// Removes every temporary grant for a rig that has been closed.
  void revokeRig(String rigId) {
    _expiresAt.removeWhere((key, _) => key.$1 == rigId);
  }
}

/// Temporary clipboard grants for this client process.
final rigClipboardSessionGrantsProvider = Provider<RigClipboardSessionGrants>(
  (ref) => RigClipboardSessionGrants(),
);
