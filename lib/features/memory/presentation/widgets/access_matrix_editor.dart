import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_error_view.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Role × domain permission matrix for memory access grants.
class AccessMatrixEditor extends ConsumerWidget {
  /// Creates an [AccessMatrixEditor].
  const AccessMatrixEditor({super.key, required this.workspaceId});

  /// Workspace whose access grants are shown.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grantsAsync = ref.watch(memoryAccessGrantsProvider(workspaceId));
    final domainsAsync = ref.watch(memoryDomainsProvider(workspaceId));

    void retry() {
      ref.invalidate(memoryAccessGrantsProvider(workspaceId));
      ref.invalidate(memoryDomainsProvider(workspaceId));
    }

    return grantsAsync.when(
      data: (List<MemoryAccessGrant> grants) => domainsAsync.when(
        data: (List<MemoryDomain> domains) {
          if (domains.isEmpty) {
            return EmptyState(
              icon: AppIcons.lock,
              iconSize: 40,
              message: AppLocalizations.of(context).noDomains,
              description: AppLocalizations.of(context).proposeToCreateDomain,
            );
          }

          if (grants.isEmpty) {
            return EmptyState(
              icon: AppIcons.lock,
              iconSize: 40,
              message: AppLocalizations.of(context).noAccessGrants,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            child: _buildTable(context, grants, domains),
          );
        },
        loading: () => const Center(child: CcSpinner()),
        error: (e, _) => MemoryErrorView(error: e, onRetry: retry),
      ),
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => MemoryErrorView(error: e, onRetry: retry),
    );
  }

  Widget _buildTable(BuildContext context, List<dynamic> grants, List<dynamic> domains) {
    final theme = Theme.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    const roles = AgentRole.values;

    return DataTable(
      headingRowColor: WidgetStateProperty.all(tokens.bgSecondary),
      columns: [
        DataColumn(
          label: Text(
            AppLocalizations.of(context).roleLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final domain in domains.cast<MemoryDomain>())
          DataColumn(
            label: Text(
              domain.label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
      rows: [
        for (final role in roles)
          DataRow(
            cells: [
              DataCell(Text(role.label, style: theme.textTheme.bodySmall)),
              for (final domain in domains.cast<MemoryDomain>())
                DataCell(
                  _PermissionCell(
                    permission: _getPermission(
                      grants.cast<MemoryAccessGrant>(),
                      role,
                      domain.name,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  String _getPermission(
    List<MemoryAccessGrant> grants,
    AgentRole role,
    String domainName,
  ) {
    final grant = grants
        .where((g) => g.agentRole == role && g.memoryDomain == domainName)
        .firstOrNull;
    return grant?.permission.label ?? 'read';
  }
}

class _PermissionCell extends StatelessWidget {
  const _PermissionCell({required this.permission});

  final String permission;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final color = switch (permission) {
      'write' => tokens.fgSuccessPrimary,
      'read' => tokens.fgBrandPrimary,
      _ => tokens.fgQuaternary,
    };
    final icon = switch (permission) {
      'write' => AppIcons.pencil,
      'read' => AppIcons.eye,
      _ => AppIcons.eyeOff,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          permission,
          style: CcTypography.caption.copyWith(color: color),
        ),
      ],
    );
  }
}
