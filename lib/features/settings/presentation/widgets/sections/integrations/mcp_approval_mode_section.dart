import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/mcp/providers/mcp_approval_mode_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → MCP servers: the host's standing tool-approval posture, the one
/// setting here that changes what an agent may do without asking. It is the
/// server owner's, so only they are shown it.
class McpApprovalModeSection extends ConsumerWidget {
  /// Creates an [McpApprovalModeSection].
  const McpApprovalModeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode =
        ref.watch(mcpApprovalModeProvider).value ?? ApprovalMode.alwaysAsk;
    return SectionCard(
      child: SettingsField(
        label: l10n.mcpApprovalMode,
        description: l10n.mcpApprovalModeDescription,
        controlWidth: 220,
        trailingControl: true,
        child: CcSelect<ApprovalMode>(
          options: [
            CcSelectOption(
              value: ApprovalMode.alwaysAsk,
              label: l10n.mcpApprovalAlwaysAsk,
            ),
            CcSelectOption(
              value: ApprovalMode.write,
              label: l10n.mcpApprovalWrite,
            ),
            CcSelectOption(
              value: ApprovalMode.yolo,
              label: l10n.mcpApprovalYolo,
            ),
          ],
          value: mode,
          onChanged: (v) async {
            await ref.read(mcpClientControlProvider).setApprovalMode(v);
            ref.invalidate(mcpApprovalModeProvider);
          },
        ),
      ),
    );
  }
}
