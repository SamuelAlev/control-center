import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/usecases/harmonize_memory_use_case.dart';

/// MCP tool that runs cross-agent SHMR belief harmonization: clusters
/// semantically-similar facts across agents, emits corroborated beliefs, and
/// flags cross-agent contradictions as conflicts.
class HarmonizeMemoryTool extends McpTool {
  /// Creates a [HarmonizeMemoryTool].
  HarmonizeMemoryTool({required HarmonizeMemoryUseCase useCase})
      : _useCase = useCase;

  final HarmonizeMemoryUseCase _useCase;

  @override
  String get name => 'harmonize_memory';

  @override
  String get description =>
      'Runs cross-agent belief harmonization (SHMR): clusters similar facts '
      'across agents, emits corroborated beliefs, and flags cross-agent '
      'contradictions so two agents never act on conflicting conclusions.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
        },
        'required': ['workspace_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final summary = await _useCase.harmonize(workspaceId);
    return CallResult.success(jsonEncode({
      'beliefs_emitted': summary.beliefsEmitted,
      'contradictions_flagged': summary.contradictionsFlagged,
    }));
  }
}