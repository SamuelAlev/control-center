import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:control_center/features/memory/presentation/widgets/agent_working_memory_panel.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// What `memory` puts into settings: the working-memory panel, as a tab on the
/// agent registry's detail pane.
///
/// The workspace comes off the [Agent] rather than the route — an agent belongs
/// to exactly one workspace and that is what scopes the read, so a panel opened
/// from anywhere addresses the same memory.
const List<AgentSettingsTab> memoryAgentSettingsTabs = [
  AgentSettingsTab(
    id: 'memory.working-memory',
    label: _memoryLabel,
    order: 10,
    builder: _buildWorkingMemory,
  ),
];

Widget _buildWorkingMemory(BuildContext context, Agent agent) =>
    AgentWorkingMemoryPanel(
      workspaceId: agent.workspaceId,
      agentId: agent.id,
    );

// Tear-off, so the contribution list stays `const`.
String _memoryLabel(AppLocalizations l) => l.memoryLabel;
