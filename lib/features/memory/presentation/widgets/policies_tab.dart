import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_chip.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_error_view.dart';
import 'package:control_center/features/memory/presentation/widgets/policy_edit_dialog.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Workspace policies grouped by domain, with inactive policies demoted to a
/// trailing section.
class PoliciesTab extends ConsumerWidget {
  /// Creates a [PoliciesTab].
  const PoliciesTab({super.key, required this.workspaceId});

  /// Workspace whose policies are shown.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final policiesAsync = ref.watch(memoryPoliciesProvider(workspaceId));

    return policiesAsync.when(
      data: (policies) {
        if (policies.isEmpty) {
          return EmptyState(
            icon: LucideIcons.scale,
            message: l10n.noPolicies,
            description: l10n.policiesHint,
          );
        }

        final active = policies.where((p) => p.active).toList();
        final inactive = policies.where((p) => !p.active).toList();

        final activeDomainOrder = <String>[];
        final grouped = <String, List<MemoryPolicy>>{};
        for (final p in active) {
          grouped.putIfAbsent(p.domain, () => []).add(p);
          if (!activeDomainOrder.contains(p.domain)) {
            activeDomainOrder.add(p.domain);
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          children: [
            for (final domainSlug in activeDomainOrder)
              if (grouped[domainSlug]?.isNotEmpty ?? false) ...[
                _DomainHeader(domain: domainSlug),
                const SizedBox(height: AppSpacing.sm),
                for (final policy in grouped[domainSlug]!) ...[
                  _PolicyCard(
                    policy: policy,
                    workspaceId: workspaceId,
                    ref: ref,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            if (inactive.isNotEmpty) ...[
              _SectionHeader(label: l10n.inactive),
              const SizedBox(height: AppSpacing.sm),
              for (final policy in inactive) ...[
                _PolicyCard(
                  policy: policy,
                  workspaceId: workspaceId,
                  ref: ref,
                  inactive: true,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        );
      },
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) => MemoryErrorView(
        error: e,
        onRetry: () => ref.invalidate(memoryPoliciesProvider(workspaceId)),
      ),
    );
  }
}

class _DomainHeader extends StatelessWidget {
  const _DomainHeader({required this.domain});

  final String domain;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        Icon(LucideIcons.tag, size: 15, color: tokens.fgBrandPrimary),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            domain,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.theme.typography.sm.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      label,
      style: context.theme.typography.sm.copyWith(
        color: tokens.textTertiary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PolicyCard extends StatefulWidget {
  const _PolicyCard({
    required this.policy,
    required this.workspaceId,
    required this.ref,
    this.inactive = false,
  });

  final MemoryPolicy policy;
  final String workspaceId;
  final WidgetRef ref;
  final bool inactive;

  @override
  State<_PolicyCard> createState() => _PolicyCardState();
}

class _PolicyCardState extends State<_PolicyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final policy = widget.policy;

    return Opacity(
      opacity: widget.inactive ? 0.55 : 1.0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: _hovered ? tokens.bgPrimaryHover : tokens.bgPrimary,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      policy.rule.split('\n').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.theme.typography.sm.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (policy.requiredRole != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    MemoryMetaChip(
                      label: policy.requiredRole!.label,
                      icon: LucideIcons.user,
                    ),
                  ],
                ],
              ),
              if (policy.sourceFactIds.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final id in policy.sourceFactIds)
                      MemoryMetaChip(
                        label: id.length > 8 ? id.substring(0, 8) : id,
                        monospace: true,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton.icon(
                    onPress: () => _editPolicy(context, policy),
                    size: FButtonSizeVariant.sm,
                    child: const Icon(LucideIcons.pencil, size: 14),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FButton.icon(
                    onPress: () => _deletePolicy(context, policy),
                    size: FButtonSizeVariant.sm,
                    variant: .destructive,
                    child: const Icon(LucideIcons.trash2, size: 14),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FButton(
                    onPress: () => _toggleActive(policy),
                    size: FButtonSizeVariant.sm,
                    variant: policy.active
                        ? FButtonVariant.outline
                        : FButtonVariant.secondary,
                    prefix: Icon(
                      policy.active ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 14,
                    ),
                    child: Text(
                      policy.active ? l10n.deactivate : l10n.activate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editPolicy(BuildContext context, MemoryPolicy policy) async {
    final edited = await showDialog<MemoryPolicy>(
      context: context,
      builder: (_) => PolicyEditDialog(policy: policy),
    );
    if (edited == null) {
      return;
    }
    final repo = widget.ref.read(memoryPolicyRepositoryProvider);
    await repo.upsert(edited);
  }

  Future<void> _deletePolicy(BuildContext context, MemoryPolicy policy) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.deletePolicy),
        body: Text(l10n.deletePolicyConfirm),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.of(dialogContext).pop(false),
                  variant: FButtonVariant.outline,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                FButton(
                  onPress: () => Navigator.of(dialogContext).pop(true),
                  variant: FButtonVariant.destructive,
                  child: Text(l10n.delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final repo = widget.ref.read(memoryPolicyRepositoryProvider);
    await repo.delete(policy.id);
  }

  Future<void> _toggleActive(MemoryPolicy policy) async {
    final repo = widget.ref.read(memoryPolicyRepositoryProvider);
    await repo.upsert(policy.copyWith(active: !policy.active));
  }
}
