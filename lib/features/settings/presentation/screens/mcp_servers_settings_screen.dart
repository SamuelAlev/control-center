import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/external_mcp_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/workspace_mcp_servers_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → MCP servers: the built-in MCP server, the current workspace's
/// MCP servers, and the server owner's personal (external) MCP servers.
///
/// Workspace admins reach the page for the workspace list; the personal list
/// is the owner's alone, so nobody else is shown it, and a demo has none.
class McpServersSettingsScreen extends ConsumerWidget {
  /// Creates an [McpServersSettingsScreen].
  const McpServersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.mcpServers,
      subtitle: l10n.mcpServersSettingsDescription,
      sections: [
        const McpSection(),
        const WorkspaceMcpServersSection(),
        if (ref.watch(canUseHostProvider) && !ref.watch(isDemoServerProvider))
          const ExternalMcpSection(),
      ],
    );
  }
}
