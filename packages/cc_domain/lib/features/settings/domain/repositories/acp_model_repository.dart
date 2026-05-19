import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';

/// Acp model repository.
/// Repository for querying models advertised by an adapter.
abstract class AcpModelRepository {
  /// Lists available models for the given [adapterId], optionally using [cliPath].
  Future<List<AcpModel>> listModels(String adapterId, {String? cliPath});
}

