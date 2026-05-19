import 'package:control_center/features/memory/providers/memory_providers.dart'
    show memoryWorkspacePanelProvider;
import 'package:control_center/shared/widgets/workspace_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:control_center/features/memory/providers/memory_providers.dart'
    show memoryWorkspacePanelProvider;

final workspacePanelRegistryProvider = Provider<List<WorkspacePanel>>((ref) {
  return [
    ref.watch(memoryWorkspacePanelProvider),
  ];
});
