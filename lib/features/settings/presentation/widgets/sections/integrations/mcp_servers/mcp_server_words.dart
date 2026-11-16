import 'package:cc_domain/core/domain/value_objects/server_owner_required.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';

/// An MCP server lifecycle as a design-system tone plus a word. Never colour
/// alone.
({String label, CcStatusTone tone}) mcpLifecycleState(
  AppLocalizations l10n,
  String lifecycle,
) => switch (lifecycle) {
  'connected' => (label: l10n.mcpStatusConnected, tone: CcStatusTone.positive),
  'connecting' => (label: l10n.mcpStatusConnecting, tone: CcStatusTone.neutral),
  'needs_auth' || 'needs_client_registration' => (
    label: l10n.mcpStatusNeedsAuth,
    tone: CcStatusTone.caution,
  ),
  WorkspaceMcpServerEntry.awaitingApproval => (
    label: l10n.mcpStatusAwaitingApproval,
    tone: CcStatusTone.caution,
  ),
  'failed' => (label: l10n.mcpStatusFailed, tone: CcStatusTone.negative),
  'circuit_open' => (
    label: l10n.mcpStatusCircuitOpen,
    tone: CcStatusTone.negative,
  ),
  _ => (label: l10n.mcpStatusDisabled, tone: CcStatusTone.neutral),
};

/// Whether a server in [lifecycle] can be retried by hand.
bool mcpLifecycleCanReconnect(String lifecycle) =>
    lifecycle == 'failed' || lifecycle == 'circuit_open';

/// The editor field a refused save points at, read from its `data.kind`.
enum McpServerRefusalField {
  /// `mcp_server.invalid_name` or `mcp_server.name_taken`.
  name,

  /// `mcp_server.invalid_command` or `mcp_server.invalid_args`.
  command,

  /// `mcp_server.invalid_url`.
  url,

  /// `mcp_server.invalid_env`.
  env,

  /// `mcp_server.invalid_header`.
  header,
}

/// The field [error] refuses, or null when it names none.
McpServerRefusalField? mcpServerRefusalField(Object error) =>
    switch (refusalKindOf(error)) {
      'mcp_server.invalid_name' ||
      'mcp_server.name_taken' => McpServerRefusalField.name,
      'mcp_server.invalid_command' ||
      'mcp_server.invalid_args' => McpServerRefusalField.command,
      'mcp_server.invalid_url' => McpServerRefusalField.url,
      'mcp_server.invalid_env' => McpServerRefusalField.env,
      'mcp_server.invalid_header' => McpServerRefusalField.header,
      _ => null,
    };

/// What a refused MCP server action says, read by `data.kind`, never by the
/// message: the `mcp_server.*` refusals and the owner-only one in the app's
/// words, anything else as [failureMessage] words it.
String mcpServerRefusalMessage(AppLocalizations l10n, Object error) {
  final kind = refusalKindOf(error);
  return switch (kind) {
    'mcp_server.name_taken' => l10n.mcpServerNameTaken,
    'mcp_server.invalid_name' => l10n.mcpServerNameInvalid,
    'mcp_server.invalid_command' => l10n.mcpServerCommandRequired,
    'mcp_server.invalid_url' => l10n.mcpServerUrlInvalid,
    'mcp_server.not_found' => l10n.mcpServerNotFound,
    serverOwnerRequiredKind => l10n.serverOwnerOnly,
    final String k when k.startsWith('mcp_server.') =>
      l10n.mcpServerRefusedInvalid,
    _ => failureMessage(l10n, error),
  };
}
