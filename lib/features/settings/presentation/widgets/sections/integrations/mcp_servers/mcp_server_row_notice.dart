import 'dart:async';

import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A line under an MCP server row saying what stands between the server and
/// its tools, lined up with the row's title, with the button that clears it
/// when the reader can.
class McpServerRowNotice extends StatefulWidget {
  /// Creates the notice.
  const McpServerRowNotice({
    super.key,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  /// What stands in the way.
  final String text;

  /// The button's label; no button without it.
  final String? actionLabel;

  /// What the button does. The button shows it is busy until this finishes.
  final Future<void> Function()? onAction;

  @override
  State<McpServerRowNotice> createState() => _McpServerRowNoticeState();
}

class _McpServerRowNoticeState extends State<McpServerRowNotice> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final label = widget.actionLabel;
    final action = widget.onAction;
    return Padding(
      // The row's start inset, its 28px glyph and the gap after it.
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg + 28 + AppSpacing.md,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 1),
            child: Icon(AppIcons.info, size: 14, color: t.fgWarningPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.text,
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ),
          if (label != null && action != null) ...[
            const SizedBox(width: AppSpacing.md),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              loading: _busy,
              onPressed: _busy ? null : () => unawaited(_run(action)),
              child: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}

/// What the server owner's approval would allow, under an unapproved
/// workspace server; the owner gets the button that grants it.
class McpServerApprovalNotice extends StatelessWidget {
  /// Creates the notice for [entry].
  const McpServerApprovalNotice({
    super.key,
    required this.entry,
    required this.owner,
    required this.onApprove,
  });

  /// The unapproved server.
  final WorkspaceMcpServerEntry entry;

  /// Whether the reader is the server owner.
  final bool owner;

  /// Records the approval.
  final Future<void> Function() onApprove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = switch ((entry.definition.runsOnHost, owner)) {
      (true, true) => l10n.mcpApprovalStdioOwner,
      (true, false) => l10n.mcpApprovalStdioMember,
      (false, true) => l10n.mcpApprovalRemoteOwner,
      (false, false) => l10n.mcpApprovalRemoteMember,
    };
    return McpServerRowNotice(
      text: text,
      actionLabel: owner ? l10n.mcpApproveServer : null,
      onAction: owner ? onApprove : null,
    );
  }
}
