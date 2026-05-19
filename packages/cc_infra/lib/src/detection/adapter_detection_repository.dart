import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:cc_infra/src/detection/adapter_detection_service.dart';

/// Repository that delegates adapter detection to the underlying [AdapterDetectionService].
class AdapterDetectionRepository implements AdapterRepository {
  /// Creates a new [AdapterDetectionRepository].
  const AdapterDetectionRepository(this._service);

  final AdapterDetectionService _service;

  @override
  Future<DetectedAdapter> detectOne(Adapter adapter) =>
      _service.detectOne(adapter);

  @override
  Future<List<DetectedAdapter>> detectAll(List<Adapter> adapters) async {
    final results = <DetectedAdapter>[];
    for (final adapter in adapters) {
      results.add(await _service.detectOne(adapter));
    }
    return results;
  }
}

