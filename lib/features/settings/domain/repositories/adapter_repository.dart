import 'package:control_center/features/settings/domain/entities/adapter.dart';

/// Adapter repository.
/// Repository for detecting installed adapter CLIs on the local machine.
abstract class AdapterRepository {
  /// Probes a single [adapter] and returns its detection status.
  Future<DetectedAdapter> detectOne(Adapter adapter);

  /// Probes every adapter in [adapters] and returns their statuses.
  Future<List<DetectedAdapter>> detectAll(List<Adapter> adapters);
}

