import 'package:control_center/features/memory/presentation/widgets/knowledge_graph.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Top-level memory panel used by the agents/workspace UI.
///
/// Currently wraps the existing [KnowledgeGraph]. Reinstate richer
/// surfaces (facts, policies, access matrix) here as the memory feature
/// regrows.
class MemoryPanel extends StatelessWidget {
  /// Creates a [MemoryPanel].
  const MemoryPanel({super.key, required this.workspaceId});

  /// The workspace whose memory is shown.
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      color: colors.background,
      child: KnowledgeGraph(workspaceId: workspaceId),
    );
  }
}
