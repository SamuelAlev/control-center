import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

/// Renders the body of a [ChannelMessageType.hireProposal] in the side
/// detail panel. Approving calls the agent repository directly (the
/// equivalent of `hire_agent`) and replaces the proposal status; rejecting
/// just records the decision. Both transitions post a system message so
/// the audit trail lives in the conversation.
class HireProposalBubble extends ConsumerStatefulWidget {
  /// Creates a [HireProposalBubble].
  const HireProposalBubble({
    super.key,
    required this.channelId,
    required this.message,
    required this.onClose,
  });

  /// The channel the proposal lives in.
  final String channelId;

  /// The hire-proposal message.
  final ChannelMessage message;

  /// Called when the panel close affordance is tapped.
  final VoidCallback onClose;

  @override
  ConsumerState<HireProposalBubble> createState() => _HireProposalBubbleState();
}

class _HireProposalBubbleState extends ConsumerState<HireProposalBubble> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context);

    final meta = widget.message.metadata ?? const <String, dynamic>{};
    final name = meta['name'] as String? ?? 'unnamed';
    final title = meta['title'] as String? ?? 'specialist';
    final rationale = meta['rationale'] as String? ?? widget.message.content;
    final skills =
        (meta['skills'] as List?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const <String>[];
    final status = meta['status'] as String? ?? 'pending';

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(onClose: widget.onClose),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusBanner(status: status),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                if (skills.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final s in skills) _SkillChip(label: s)],
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  rationale,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.foreground),
                ),
              ],
            ),
          ),
          if (status == 'pending')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FButton(
                      variant: FButtonVariant.outline,
                      onPress: _busy ? null : _reject,
                      child: Text(l10n.reject),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FButton(
                      onPress: _busy ? null : _approve,
                      child: _busy
                          ? const SizedBox(
                              height: 12,
                              width: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.approveAndHire),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      final meta = widget.message.metadata ?? const <String, dynamic>{};
      final name = meta['name'] as String? ?? 'unnamed';
      final title = meta['title'] as String? ?? 'specialist';
      final workspaceId = meta['workspaceId'] as String?;
      if (workspaceId == null) {
        if (mounted) {
          setState(() => _busy = false);
        }
        return;
      }
      final skills =
          (meta['skills'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const <String>[];
      final persona = meta['persona'] as String?;

      final filesystem = ref.read(workspaceFilesystemPortProvider);
      final slug = _slugify(name);
      await filesystem.ensureWorkspaceDirs(workspaceId);
      const stubMd =
          '# Generated agent\n\nHired via CEO propose_hire approval.\n';
      await filesystem.writeAgentFile(workspaceId, slug, stubMd);
      final mdPath = await filesystem.agentFilePath(workspaceId, slug);
      if (skills.isNotEmpty) {
        await filesystem.syncAgentSkillLinks(workspaceId, slug, skills);
      }

      final agent = Agent(
        id: const Uuid().v4(),
        name: name,
        title: title,
        agentMdPath: mdPath,
        workspaceId: workspaceId,
        reportsTo: 'ceo',
        skills: AgentSkills(skills),
        persona: persona,
        createdAt: DateTime.now(),
      );
      await ref.read(agentRepositoryProvider).upsert(agent);

      final repo = ref.read(messagingRepositoryProvider);
      await repo.updateMessage(
        widget.message.id,
        metadata: {...meta, 'status': 'approved', 'agentId': agent.id},
      );
      await repo.sendMessage(
        channelId: widget.channelId,
        content: '✅ Hired **$name** ($title) — joined the channel.',
        senderId: 'system',
        senderType: 'agent',
        messageType: 'system',
      );
      await repo.addParticipant(widget.channelId, agent.id);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      final meta = widget.message.metadata ?? const <String, dynamic>{};
      final repo = ref.read(messagingRepositoryProvider);
      await repo.updateMessage(
        widget.message.id,
        metadata: {...meta, 'status': 'rejected'},
      );
      await repo.sendMessage(
        channelId: widget.channelId,
        content:
            '🚫 Hire proposal for **${meta['name'] ?? 'unnamed'}** rejected.',
        senderId: 'system',
        senderType: 'agent',
        messageType: 'system',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

String _slugify(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.userPlus, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'HIRE PROPOSAL',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Icon(LucideIcons.x, size: 18, color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    late final Color bg;
    late final String label;
    switch (status) {
      case 'approved':
        bg = colors.primary.withValues(alpha: 0.12);
        label = 'Approved · agent hired';
      case 'rejected':
        bg = colors.destructive.withValues(alpha: 0.12);
        label = AppLocalizations.of(context).rejected;
      default:
        bg = colors.muted;
        label = AppLocalizations.of(context).pendingApproval;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: colors.foreground),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: colors.foreground,
        ),
      ),
    );
  }
}
