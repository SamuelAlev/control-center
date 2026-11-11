import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart'
    show invalidateForgeState;
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The owner-only `connect.*` ops.
final connectSettingsRepositoryProvider = Provider<RemoteConnectSettings>(
  (ref) => RemoteConnectSettings(ref.watch(rpcClientProvider)),
);

/// This server's Connect configuration and health, or null for anyone but
/// the server owner (the server refuses them, so there is nothing to show).
///
/// Errors surface as errors: an owner looking at this card needs to know the
/// status could not be read, not see a blank one.
final connectStatusProvider = FutureProvider<ConnectStatus?>((ref) async {
  if (!ref.watch(isServerOwnerProvider)) {
    return null;
  }
  return ref.watch(connectSettingsRepositoryProvider).status();
});

/// Runs one `connect.*` mutation and publishes the status it returns, so the
/// card shows the server's answer rather than a re-read that may race it.
///
/// Every mode change also changes who runs each sign-in lane, so the lane
/// list and the connection lists are re-read.
class ConnectSettingsActions {
  /// Creates the actions over [_ref].
  ConnectSettingsActions(this._ref);

  final WidgetRef _ref;

  RemoteConnectSettings get _repo =>
      _ref.read(connectSettingsRepositoryProvider);

  /// Switches to [mode] ([url] for a custom Connect).
  Future<ConnectStatus> configure(ConnectModeSetting mode, {String? url}) =>
      _apply(() => _repo.configure(mode, url: url));

  /// Forces a configuration refresh.
  Future<ConnectStatus> test() => _apply(_repo.test);

  /// Accepts Connect's new signing pins.
  Future<ConnectStatus> confirmPins() => _apply(_repo.confirmPins);

  /// Mints a new install key; every Connect sign-in must be redone. [force]
  /// replaces it even where a Connect could not retire the old one.
  Future<ConnectStatus> rotateKey({bool force = false}) =>
      _apply(() => _repo.rotateKey(force: force));

  Future<ConnectStatus> _apply(Future<ConnectStatus> Function() op) async {
    final status = await op();
    _ref.invalidate(connectStatusProvider);
    // A mode change or key rotation can void every Connect sign-in, so every
    // view of who is signed in to which forge re-reads, not just the lanes.
    invalidateForgeState(_ref.invalidate);
    return status;
  }
}
