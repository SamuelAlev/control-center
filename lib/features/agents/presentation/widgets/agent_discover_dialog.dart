import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/features/agents/domain/usecases/create_agent.dart';
import 'package:control_center/features/agents/domain/value_objects/discovered_agent.dart';
import 'package:control_center/features/agents/presentation/widgets/skill_chip.dart';
import 'package:control_center/features/agents/providers/agent_form_providers.dart';
import 'package:control_center/features/agents/providers/agent_management_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Opens the discover-agents dialog, which scans the workspace's agent
/// directory for `AGENTS.md` definitions that aren't registered yet and lets
/// the operator import them.
Future<void> showDiscoverAgentsDialog({
  required BuildContext context,
  required String workspaceId,
}) {
  return showCcDialog<void>(
    context: context,
    builder: (ctx) => _DiscoverDialog(
      workspaceId: workspaceId,
    ),
  );
}

class _DiscoverDialog extends ConsumerStatefulWidget {
  const _DiscoverDialog({
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  ConsumerState<_DiscoverDialog> createState() => _DiscoverDialogState();
}

class _DiscoverDialogState extends ConsumerState<_DiscoverDialog> {
  final Set<String> _importing = {};

  Future<void> _import(DiscoveredAgent agent) async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    setState(() => _importing.add(agent.name));
    try {
      // Resolve the file's reports-to *name* to an existing agent id.
      final existing =
          ref.read(workspaceAgentsProvider(widget.workspaceId)).asData?.value ??
              const <Agent>[];
      String? managerId;
      final reportsTo = agent.reportsTo;
      if (reportsTo != null) {
        managerId = existing
            .where((a) => a.name.toLowerCase() == reportsTo.toLowerCase())
            .map((a) => a.id)
            .firstOrNull;
      }
      await ref.read(createAgentUseCaseProvider).execute(
            CreateAgentCommand(
              name: agent.name,
              title: agent.title,
              workspaceId: widget.workspaceId,
              skills: agent.skills,
              reportsTo: managerId,
              persona: agent.persona,
            ),
          );
    } catch (e) {
      toaster.show(
        l10n.errorWithDetail(e.toString()),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _importing.remove(agent.name));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem!;
    final discoverable =
        ref.watch(discoverableAgentsProvider(widget.workspaceId));

    return CcDialog(
      title: l10n.discoverAgents,
      content: SizedBox(
        width: 460,
        child: discoverable.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CcSpinner()),
          ),
          error: (e, _) => SizedBox(
            height: 100,
            child: Center(
              child: Text(
                l10n.errorWithDetail(e.toString()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ),
          data: (agents) {
            if (agents.isEmpty) {
              return _EmptyDiscovery();
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.discoverAgentsFound(agents.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: agents.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _DiscoveryRow(
                        agent: agents[i],
                        importing: _importing.contains(agents[i].name),
                        onImport: () => _import(agents[i]),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _DiscoveryRow extends StatelessWidget {
  const _DiscoveryRow({
    required this.agent,
    required this.importing,
    required this.onImport,
  });

  final DiscoveredAgent agent;
  final bool importing;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final skills = agent.skills.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  agent.title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final s in skills) SkillChip(label: s)],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          CcButton(
            onPressed: importing ? null : onImport,
            variant: CcButtonVariant.secondary,
            loading: importing,
            icon: importing ? null : LucideIcons.plus,
            child: Text(l10n.import),
          ),
        ],
      ),
    );
  }
}

class _EmptyDiscovery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.search, size: 32, color: tokens.fgQuaternary),
          const SizedBox(height: 12),
          Text(
            l10n.noAgentsToDiscover,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.noAgentsToDiscoverHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
