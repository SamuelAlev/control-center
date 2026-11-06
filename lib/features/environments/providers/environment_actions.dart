import 'package:cc_data/cc_data.dart' show RpcEnvironmentRepository;
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which actions are in flight for one space, by key (`start`, `restart:web`).
///
/// The server allows one mutation per environment at a time; this only stops a
/// second press and lets the pressed control show its spinner.
class EnvironmentActionsNotifier extends Notifier<Set<String>> {
  /// Creates the notifier for [key].
  EnvironmentActionsNotifier(this.key);

  /// The space acted on.
  final EnvironmentSpaceKey key;

  @override
  Set<String> build() => const {};

  /// Forwards one action. Rethrows, so the caller decides how to show a
  /// failure. Does nothing when [action] is already running.
  Future<void> run(
    String action,
    Future<void> Function(RpcEnvironmentRepository repository) body,
  ) async {
    if (state.contains(action)) {
      return;
    }
    final repository = ref.read(environmentRepositoryProvider);
    state = {...state, action};
    try {
      await body(repository);
    } finally {
      if (ref.mounted) {
        state = {...state}..remove(action);
      }
    }
  }
}

/// The in-flight actions of one space.
final environmentActionsProvider = NotifierProvider.autoDispose
    .family<EnvironmentActionsNotifier, Set<String>, EnvironmentSpaceKey>(
      EnvironmentActionsNotifier.new,
    );
