import 'package:cc_harness/tools.dart';

/// Marks the current point in the conversation so a later `rewind` can return to
/// it. Handled by the loop itself (it owns the history), so [execute] is never
/// invoked — the class exists to advertise the tool schema to the model.
class CheckpointTool extends HarnessTool {
  /// Creates a [CheckpointTool].
  CheckpointTool();

  @override
  String get name => 'checkpoint';

  @override
  String get description =>
      'Mark the current conversation state with a label so you can rewind to '
      'it later after an exploration. Use before a risky or exploratory detour.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'label': {
        'type': 'string',
        'description': 'A short name for this checkpoint.',
      },
    },
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.error('checkpoint is handled by the loop.');
}

/// Prunes the exploratory conversation since a checkpoint (or since the original
/// task), replacing it with a concise summary and continuing. Handled by the
/// loop; [execute] is never invoked.
class RewindTool extends HarnessTool {
  /// Creates a [RewindTool].
  RewindTool();

  @override
  String get name => 'rewind';

  @override
  String get description =>
      'Discard the exploratory turns since a checkpoint (or since the task '
      'started) once you have what you need, keeping only a concise summary. '
      'Reclaims context so you can continue cleanly.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'checkpoint': {
        'type': 'string',
        'description':
            'The checkpoint label to rewind to. Omit to rewind to the '
            'original task.',
      },
    },
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.error('rewind is handled by the loop.');
}
