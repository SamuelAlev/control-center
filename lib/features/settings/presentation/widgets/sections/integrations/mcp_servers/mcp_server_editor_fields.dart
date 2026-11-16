import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The MCP server editor's transport picker: a command, HTTP or SSE.
class McpServerTransportPicker extends StatelessWidget {
  /// Creates the picker.
  const McpServerTransportPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// The transport picked.
  final McpServerTransport value;

  /// Fired with a new pick; null disables the picker.
  final ValueChanged<McpServerTransport>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.mcpServerTransportLabel,
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        CcSegmentedToggle<McpServerTransport>(
          semanticLabel: l10n.mcpServerTransportLabel,
          value: value,
          onChanged: onChanged,
          segments: [
            CcSegment(
              value: McpServerTransport.stdio,
              label: l10n.mcpServerTransportStdio,
            ),
            CcSegment(
              value: McpServerTransport.http,
              label: l10n.mcpServerTransportHttp,
            ),
            CcSegment(
              value: McpServerTransport.sse,
              label: l10n.mcpServerTransportSse,
            ),
          ],
        ),
      ],
    );
  }
}

/// Whether the server is dialled at all, with what turning it off means.
class McpServerEnabledField extends StatelessWidget {
  /// Creates the field.
  const McpServerEnabledField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Whether it is on.
  final bool value;

  /// Fired with the new value; null disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.enabled,
                style: CcTypography.bodySm.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.mcpServerEnabledDescription,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        CcSwitch(
          value: value,
          semanticLabel: l10n.enabled,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
