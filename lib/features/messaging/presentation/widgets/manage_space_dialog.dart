import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_participant_row.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_checker_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog for managing space participants.
class ManageSpaceDialog extends ConsumerStatefulWidget {
  /// Creates a new [ManageSpaceDialog].
  const ManageSpaceDialog({super.key, required this.spaceId});

  /// Space to manage.
  final String spaceId;

  @override
  ConsumerState<ManageSpaceDialog> createState() => _ManageSpaceDialogState();
}

class _ManageSpaceDialogState extends ConsumerState<ManageSpaceDialog> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final participants =
        ref.watch(spaceParticipantsProvider(widget.spaceId)).value ?? const [];
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agents = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const []
        : ref.watch(agentsProvider).value ?? const [];
    final l10n = AppLocalizations.of(context);
    final existingIds = participants.map((p) => p.principalId).toSet();
    final spaceParticipants = participants.where((p) => !p.isUser).toList();
    final spaceAgentIds = spaceParticipants.map((p) => p.principalId).toSet();
    final spaceAgents = agents
        .where((a) => spaceAgentIds.contains(a.id))
        .toList();

    return CcDialog(
      title: l10n.manageParticipants,
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spaceParticipants.isNotEmpty) ...[
              Text(
                l10n.currentParticipants,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              ...spaceParticipants.map(
                (p) => SpaceParticipantRow(
                  spaceId: widget.spaceId,
                  participant: p,
                  onRemove: () => _removeAgent(p.principalId),
                ),
              ),
              const SizedBox(height: 24, child: Center(child: CcDivider())),
            ],
            Text(
              l10n.inviteAgent,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: 8),
            _InviteSection(
              agents: agents,
              existingIds: existingIds,
              onInvite: _inviteAgent,
            ),
            const SizedBox(height: 24, child: Center(child: CcDivider())),
            _CheckerSection(spaceId: widget.spaceId, agents: spaceAgents),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Future<void> _removeAgent(String agentId) async {
    await ref
        .read(messagingServiceProvider)
        .removeParticipant(ref.requireWorkspaceId(), widget.spaceId, agentId);
  }

  Future<void> _inviteAgent(String agentId) async {
    await ref
        .read(messagingServiceProvider)
        .addAgentToSpace(ref.requireWorkspaceId(), widget.spaceId, agentId);
  }
}

/// The space's checker-agent row (PRD 16 §13): a select over the space's
/// own agent participants (+ "None"), bound to `checker.get`/
/// `checker.setForSpace`.
class _CheckerSection extends ConsumerWidget {
  const _CheckerSection({required this.spaceId, required this.agents});

  final String spaceId;
  final List<Agent> agents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentCheckerId = ref.watch(spaceCheckerProvider(spaceId)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcSelect<String?>(
          label: l10n.checkerLabel,
          options: [
            CcSelectOption(value: null, label: l10n.checkerNone),
            for (final a in agents) CcSelectOption(value: a.id, label: a.name),
          ],
          value: currentCheckerId,
          onChanged: (agentId) async {
            await setSpaceChecker(
              ref.read(rpcClientProvider),
              spaceId: spaceId,
              agentId: agentId,
            );
            ref.invalidate(spaceCheckerProvider(spaceId));
          },
        ),
        const SizedBox(height: 4),
        Text(
          l10n.checkerCaption,
          style: CcTypography.caption.copyWith(color: context.ds.textTertiary),
        ),
      ],
    );
  }
}

class _InviteSection extends StatefulWidget {
  const _InviteSection({
    required this.agents,
    required this.existingIds,
    required this.onInvite,
  });

  final List<Agent> agents;
  final Set<String> existingIds;
  final ValueChanged<String> onInvite;

  @override
  State<_InviteSection> createState() => _InviteSectionState();
}

class _InviteSectionState extends State<_InviteSection> {
  Agent? _selected;

  @override
  Widget build(BuildContext context) {
    final available = widget.agents
        .where((a) => !widget.existingIds.contains(a.id))
        .toList();
    final l10n = AppLocalizations.of(context);

    if (available.isEmpty) {
      return Text(
        l10n.allAgentsAlreadyInSpace,
        style: const TextStyle(fontSize: 12),
      );
    }

    return Column(
      children: [
        if (available.length <= 5)
          ...available.map(
            (a) => CcTile(
              leading: AgentAvatar(
                agentId: a.id,
                name: a.name,
                size: 22,
                showHoverCard: false,
              ),
              title: a.name,
              subtitle: a.title.isNotEmpty ? Text(a.title) : null,
              onTap: () {
                widget.onInvite(a.id);
                Navigator.of(context).pop();
              },
            ),
          )
        else ...[
          CcSelect<Agent>(
            value: _selected,
            options: available
                .map((a) => CcSelectOption<Agent>(value: a, label: a.name))
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
            hintText: l10n.selectAnAgent,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: CcButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      widget.onInvite(_selected!.id);
                      Navigator.of(context).pop();
                    },
              child: Text(l10n.invite),
            ),
          ),
        ],
      ],
    );
  }
}
