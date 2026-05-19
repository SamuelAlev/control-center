import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_error_view.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/widgets.dart';
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

  Widget _buildTable(
    BuildContext context,
    List<dynamic> grants,
    List<dynamic> domains,
  ) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    const roles = AgentRole.values;

    // `Table` (flutter/widgets.dart) gives the real column alignment this
    // matrix needs without Material's DataTable — the header uses the design
    // system's eyebrow `label` token rather than Material's bold, since the
    // system carries no weight above 600.
    return Table(
      border: TableBorder.all(color: tokens.borderSecondary),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(color: tokens.bgSecondary),
          children: [
            _headerCell(AppLocalizations.of(context).roleLabel, tokens),
            for (final domain in domains.cast<MemoryDomain>())
              _headerCell(domain.label, tokens),
          ],
        ),
        for (final role in roles)
          TableRow(
            children: [
              _bodyCell(
                Text(
                  role.label,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              for (final domain in domains.cast<MemoryDomain>())
                _bodyCell(
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

  /// A column header cell — the design system's tracked eyebrow label.
  Widget _headerCell(String label, DesignSystemTokens tokens) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    child: Text(
      label,
      style: CcTypography.label.copyWith(color: tokens.textSecondary),
    ),
  );

  /// A body cell, padded to match the header.
  Widget _bodyCell(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    child: child,
  );

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
        Text(permission, style: CcTypography.caption.copyWith(color: color)),
      ],
    );
  }
}
