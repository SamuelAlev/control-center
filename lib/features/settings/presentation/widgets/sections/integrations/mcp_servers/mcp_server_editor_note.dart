import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// What saving means for who may use the server, under the transport picker.
///
/// A workspace server that runs a command waits on the server owner; a remote
/// one reaches only public addresses until then. The owner's own save
/// approves it, so they are told that instead. A personal server is used only
/// in the runs its member starts in this workspace; nobody approves another
/// member's, so theirs reaches only public addresses.
class McpServerEditorNote extends StatelessWidget {
  /// Creates the note.
  const McpServerEditorNote({
    super.key,
    required this.scope,
    required this.transport,
    required this.owner,
  });

  /// Whose server is being edited.
  final McpServerScope scope;

  /// The transport picked.
  final McpServerTransport transport;

  /// Whether the person editing is the server owner.
  final bool owner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stdio = transport == McpServerTransport.stdio;
    final text = switch ((scope, owner, stdio)) {
      (McpServerScope.personal, true, _) => l10n.mcpServerEditorPersonalOwner,
      (McpServerScope.personal, false, _) => l10n.mcpServerEditorPersonalMember,
      (McpServerScope.workspace, true, true) => l10n.mcpServerEditorStdioOwner,
      (McpServerScope.workspace, true, false) =>
        l10n.mcpServerEditorRemoteOwner,
      (McpServerScope.workspace, false, true) =>
        l10n.mcpServerEditorStdioMember,
      (McpServerScope.workspace, false, false) =>
        l10n.mcpServerEditorRemoteMember,
    };
    return McpServerNoteLine(
      text: text,
      caution: scope == McpServerScope.workspace && !owner,
    );
  }
}

/// A quiet line with a leading glyph: information, or a [caution] the reader
/// should weigh before acting.
class McpServerNoteLine extends StatelessWidget {
  /// Creates the line.
  const McpServerNoteLine({super.key, required this.text, this.caution = true});

  /// What it says.
  final String text;

  /// Whether it warns rather than informs.
  final bool caution;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 1),
          child: Icon(
            AppIcons.info,
            size: 14,
            color: caution ? t.fgWarningPrimary : t.fgTertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        ),
      ],
    );
  }
}
