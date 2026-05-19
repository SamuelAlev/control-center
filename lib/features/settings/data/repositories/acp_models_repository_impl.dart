import 'package:control_center/features/settings/data/services/acp_models_service.dart';
import 'package:control_center/features/settings/domain/entities/acp_model.dart';
import 'package:control_center/features/settings/domain/repositories/acp_model_repository.dart';

/// Acp model repository impl.
class AcpModelRepositoryImpl implements AcpModelRepository {
  /// Creates a new [Acp model repository impl].
  AcpModelRepositoryImpl(this._service);

  final AcpModelsService _service;

  @override
  Future<List<AcpModel>> listModels(String adapterId, {String? cliPath}) =>
      _service.listModels(adapterId, cliPath: cliPath);
}

