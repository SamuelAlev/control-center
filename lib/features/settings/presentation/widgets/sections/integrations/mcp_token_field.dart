import 'package:cc_domain/cc_domain.dart' show ServerOwnerRequiredException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/mcp/providers/mcp_server_control_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_login_command_block.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The server owner's MCP token: hidden until asked for, shown as the
/// `Authorization: Bearer` header MCP clients send, and rotatable behind a
/// confirm.
///
/// The token always exists (the server mints it on first start and never
/// clears it), so there is no "no token" state and nothing to set by hand.
/// A refusal for not being the server owner turns into [onOwnerOnly], which
/// the section words as an owner-only endpoint, not an error.
class McpTokenField extends ConsumerStatefulWidget {
  /// Creates the field.
  const McpTokenField({required this.onOwnerOnly, super.key});

  /// Called when the server answers that only its owner may see the token.
  final VoidCallback onOwnerOnly;

  @override
  ConsumerState<McpTokenField> createState() => _McpTokenFieldState();
}

class _McpTokenFieldState extends ConsumerState<McpTokenField> {
  String? _token;
  bool _shown = false;
  bool _busy = false;

  /// Fetches a token and shows it; whether it arrived.
  Future<bool> _load(Future<String> Function() fetch) async {
    setState(() => _busy = true);
    try {
      final token = await fetch();
      if (mounted) {
        setState(() {
          _token = token;
          _shown = true;
        });
      }
      return true;
    } on ServerOwnerRequiredException {
      widget.onOwnerOnly();
      return false;
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _toggle() async {
    if (_shown) {
      setState(() => _shown = false);
      return;
    }
    if (_token != null) {
      setState(() => _shown = true);
      return;
    }
    await _load(ref.read(mcpServerControlProvider).token);
  }

  Future<void> _rotate() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.mcpRotateTokenTitle,
      message: l10n.mcpRotateTokenBody,
      confirmLabel: l10n.mcpRotateToken,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final rotated = await _load(ref.read(mcpServerControlProvider).rotateToken);
    if (rotated && mounted) {
      CcToastScope.of(context).show(l10n.mcpTokenRotated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final token = _token;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsField(
          label: l10n.authenticationToken,
          description: l10n.mcpTokenDescription,
          controlWidth: 260,
          trailingControl: true,
          // Wraps rather than overflowing when a translation is long.
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              CcButton(
                onPressed: _busy ? null : _toggle,
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                child: Text(_shown ? l10n.mcpHideToken : l10n.mcpShowToken),
              ),
              CcButton(
                onPressed: _busy ? null : _rotate,
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                child: Text(l10n.mcpRotateToken),
              ),
            ],
          ),
        ),
        if (_shown && token != null) ...[
          const SizedBox(height: AppSpacing.sm),
          // The header exactly as an MCP client sends it; the copy control
          // copies this whole line.
          ClaudeLoginCommandBlock(line: 'Authorization: Bearer $token'),
        ],
      ],
    );
  }
}
