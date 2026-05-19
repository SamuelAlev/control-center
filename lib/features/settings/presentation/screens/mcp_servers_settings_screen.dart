import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/external_mcp_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → MCP servers: the built-in MCP server and external MCP servers.
class McpServersSettingsScreen extends StatelessWidget {
  /// Creates an [McpServersSettingsScreen].
  const McpServersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.mcpServers,
      subtitle: l10n.mcpServersSettingsDescription,
      sections: const [McpSection(), ExternalMcpSection()],
    );
  }
}
