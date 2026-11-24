import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_approval_mode_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_servers_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → MCP servers: the built-in MCP server, the reader's own MCP
/// servers in the current workspace, the workspace's, and — for the server
/// owner — the standing tool-approval posture.
///
/// Every member manages their own servers; the workspace's are the admins'.
/// The approval posture is the host's, so nobody else is shown it, and a
/// demo has none.
class McpServersSettingsScreen extends ConsumerWidget {
  /// Creates an [McpServersSettingsScreen].
  const McpServersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.mcpServers,
      subtitle: l10n.mcpServersSettingsSubtitle,
      sections: [
        const McpSection(),
        const McpServersSection(scope: McpServerScope.personal),
        const McpServersSection(scope: McpServerScope.workspace),
        if (ref.watch(canUseHostProvider) && !ref.watch(isDemoServerProvider))
          const McpApprovalModeSection(),
      ],
    );
  }
}
