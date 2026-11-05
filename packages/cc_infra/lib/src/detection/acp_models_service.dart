import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_infra/src/detection/claude_code_model_catalog.dart';

/// Resolves the model catalog an adapter advertises.
///
/// Claude Code's comes live from the installed CLI ([ClaudeCodeModelCatalog]);
/// no other adapter has a catalog of its own.
class AcpModelsService {
  /// Creates a new [AcpModelsService]. Without [claudeCode] the Claude Code
  /// catalog is empty.
  AcpModelsService({this.claudeCode});

  /// The live Claude Code catalog.
  final ClaudeCodeModelCatalog? claudeCode;

  /// Returns the list of models advertised by the given [adapterId].
  Future<List<AcpModel>> listModels(String adapterId) async {
    final claude = claudeCode;
    if (adapterId == 'claude-code' && claude != null) {
      return claude.models();
    }
    return const <AcpModel>[];
  }
}
