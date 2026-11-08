import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The account each provider's usage block in the tray panel shows, by
/// provider id: the panel is rebuilt on every open, and paging to the same
/// account each time would be a chore. Held for the session, not persisted.
final trayUsageAccountProvider =
    NotifierProvider<TrayUsageAccountNotifier, Map<String, String>>(
      TrayUsageAccountNotifier.new,
    );

/// Holds [trayUsageAccountProvider].
class TrayUsageAccountNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  /// Shows [accountId] for [providerId] from now on.
  void show(String providerId, String accountId) {
    state = {...state, providerId: accountId};
  }
}
