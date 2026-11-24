import 'dart:async';

import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/mcp/providers/workspace_mcp_servers_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_sign_in_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_words.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signs the reader in to [definition], a server of [scope] in
/// [workspaceId], through their browser.
///
/// The sign-in starts here; a refusal (the server offers no browser sign-in,
/// or the reader may not) is toasted and nothing opens. Otherwise the dialog
/// sends the browser to the provider and takes the confirmation code the
/// server's page shows afterwards. Once signed in the server has already
/// reconnected, so the list is only re-read.
///
/// Completes once the dialog is up (or the start was refused), so whatever
/// started it is busy only while the sign-in begins.
Future<void> signInToMcpServer(
  BuildContext context,
  WidgetRef ref, {
  required String workspaceId,
  required McpServerScope scope,
  required McpServerDefinition definition,
}) async {
  final l10n = AppLocalizations.of(context);
  final toasts = CcToastScope.maybeOf(context);
  final McpServerAuthorization authorization;
  try {
    authorization = await ref
        .read(workspaceMcpServerControlProvider)
        .beginAuthorization(workspaceId, scope, definition.id);
  } on Object catch (e) {
    toasts?.show(
      mcpServerRefusalMessage(l10n, e),
      variant: CcToastVariant.danger,
    );
    return;
  }
  if (context.mounted) {
    unawaited(
      _showSignInDialog(
        context,
        ref,
        workspaceId: workspaceId,
        scope: scope,
        definition: definition,
        authorization: authorization,
      ),
    );
  }
}

Future<void> _showSignInDialog(
  BuildContext context,
  WidgetRef ref, {
  required String workspaceId,
  required McpServerScope scope,
  required McpServerDefinition definition,
  required McpServerAuthorization authorization,
}) async {
  final l10n = AppLocalizations.of(context);
  final toasts = CcToastScope.maybeOf(context);
  // The scrim does not dismiss: the click that brings the window back from
  // the browser would otherwise land on it.
  final signedIn = await showCcDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(dialogContext).maybePop(),
      },
      child: McpServerSignInDialog(
        workspaceId: workspaceId,
        scope: scope,
        definition: definition,
        authorization: authorization,
      ),
    ),
  );
  if (signedIn ?? false) {
    toasts?.show(
      l10n.mcpServerSignedIn(definition.name),
      variant: CcToastVariant.success,
    );
  }
  if (context.mounted) {
    ref.invalidate(
      workspaceMcpServersProvider((workspaceId: workspaceId, scope: scope)),
    );
  }
}
