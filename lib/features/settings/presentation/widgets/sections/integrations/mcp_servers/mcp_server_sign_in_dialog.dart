import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show normaliseConfirmCode;
import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart'
    show externalUrlOpenerProvider;
import 'package:control_center/features/mcp/providers/workspace_mcp_servers_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_sign_in_parts.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_words.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The browser sign-in to one MCP server: the page opened, the code typed
/// back, a wrong code retried, an ended attempt started again. Pops true once
/// signed in.
class McpServerSignInDialog extends ConsumerStatefulWidget {
  /// Creates the dialog for an [authorization] already begun.
  const McpServerSignInDialog({
    super.key,
    required this.workspaceId,
    required this.scope,
    required this.definition,
    required this.authorization,
  });

  /// The workspace the server is configured in.
  final String workspaceId;

  /// Whose server it is.
  final McpServerScope scope;

  /// The server being signed in to.
  final McpServerDefinition definition;

  /// The attempt already begun (see `signInToMcpServer`).
  final McpServerAuthorization authorization;

  @override
  ConsumerState<McpServerSignInDialog> createState() =>
      _McpServerSignInDialogState();
}

class _McpServerSignInDialogState extends ConsumerState<McpServerSignInDialog> {
  final _code = TextEditingController();
  late McpServerAuthorization _attempt = widget.authorization;
  bool _opened = true;
  bool _busy = false;
  String? _error;

  bool get _ended => _attempt.status == McpServerAuthorizationStatus.failed;

  @override
  void initState() {
    super.initState();
    // After the dialog has painted: the browser takes focus as it opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _open() {
    if (!mounted) {
      return;
    }
    final opened = ref.read(externalUrlOpenerProvider)(_attempt.url);
    setState(() => _opened = opened);
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    // A code that cannot be one is not sent: the server would count it as
    // a wrong try.
    final code = normaliseConfirmCode(_code.text);
    if (code == null) {
      setState(() => _error = l10n.signInCodeMalformed);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(workspaceMcpServerControlProvider)
          .completeAuthorization(
            widget.workspaceId,
            widget.scope,
            _attempt.attemptId,
            code,
          );
      if (!mounted) {
        return;
      }
      if (result.status == McpServerAuthorizationStatus.done) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _busy = false;
        _attempt = McpServerAuthorization(
          attemptId: _attempt.attemptId,
          url: _attempt.url,
          status: result.status,
          triesLeft: result.triesLeft,
        );
        _error = result.status == McpServerAuthorizationStatus.wrongCode
            ? l10n.mcpServerSignInWrongCode(result.triesLeft)
            : null;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = mcpServerRefusalMessage(l10n, e);
        });
      }
    }
  }

  Future<void> _startAgain() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final attempt = await ref
          .read(workspaceMcpServerControlProvider)
          .beginAuthorization(
            widget.workspaceId,
            widget.scope,
            widget.definition.id,
          );
      if (!mounted) {
        return;
      }
      _code.clear();
      setState(() {
        _busy = false;
        _attempt = attempt;
      });
      _open();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = mcpServerRefusalMessage(l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final ended = _ended;
    final error = _error;
    return CcDialog(
      title: l10n.mcpServerSignInTitle(widget.definition.name),
      maxWidth: 480,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ended) ...[
            CcAlert(
              title: l10n.signInFailedTitle,
              description: Text(l10n.mcpServerSignInEnded),
              variant: CcAlertVariant.danger,
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              CcAlert(title: error, variant: CcAlertVariant.danger),
            ],
          ] else ...[
            Text(
              l10n.signInCodePrompt,
              style: CcTypography.body.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            McpServerSignInCodeField(
              controller: _code,
              enabled: !_busy,
              errorText: error,
              onSubmit: () => unawaited(_finish()),
            ),
            const SizedBox(height: AppSpacing.md),
            McpServerSignInLink(
              url: _attempt.url,
              opened: _opened,
              onReopen: _open,
            ),
          ],
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(ended ? l10n.close : l10n.cancel),
        ),
        CcButton(
          loading: _busy,
          onPressed: _busy
              ? null
              : () => unawaited(ended ? _startAgain() : _finish()),
          child: Text(ended ? l10n.mcpServerSignInStartAgain : l10n.finish),
        ),
      ],
    );
  }
}
