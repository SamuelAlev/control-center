import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_words.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Runs one row action on an MCP server, then [refresh]es the list. A refusal
/// is toasted in the app's words (read by `data.kind`); [success], when
/// given, is toasted after it worked.
Future<void> runMcpServerAction(
  BuildContext context, {
  required Future<void> Function() action,
  required void Function() refresh,
  String? success,
}) async {
  final l10n = AppLocalizations.of(context);
  try {
    await action();
    if (success != null && context.mounted) {
      CcToastScope.of(context).show(success, variant: CcToastVariant.success);
    }
  } on Object catch (e) {
    if (context.mounted) {
      CcToastScope.of(
        context,
      ).show(mcpServerRefusalMessage(l10n, e), variant: CcToastVariant.danger);
    }
  } finally {
    if (context.mounted) {
      refresh();
    }
  }
}

/// Asks before removing [definition]: its stored values go with it, and runs
/// lose its tools.
Future<bool> confirmRemoveMcpServer(
  BuildContext context,
  McpServerDefinition definition,
) {
  final l10n = AppLocalizations.of(context);
  return showCcConfirmDialog(
    context: context,
    title: l10n.mcpRemoveServerTitle(definition.name),
    message: l10n.mcpRemoveServerBody,
    confirmLabel: l10n.mcpRemoveServer,
    cancelLabel: l10n.cancel,
    danger: true,
  );
}

/// How [definition] is reached, as one machine line: the command and its
/// arguments, or the URL.
String mcpServerTarget(McpServerDefinition definition) => definition.runsOnHost
    ? [definition.command ?? '', ...definition.args].join(' ')
    : definition.url ?? '';
