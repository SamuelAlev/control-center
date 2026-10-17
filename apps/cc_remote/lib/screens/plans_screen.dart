import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/plan_goal_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Workspace-wide, live plan documents; proposed work takes priority.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final workspace = ref.watch(activeWorkspaceIdProvider);
    final workspaceId = workspace.value;
    if (workspace.hasError) {
      return CcEmptyState(
        icon: AppIcons.triangleAlert,
        message: l10n.mobilePlansLoadFailed,
        description: workspace.error.toString(),
      );
    }
    if (workspaceId == null) {
      return const Center(child: CcSpinner(size: 24));
    }
    final plans = ref.watch(phonePlansProvider(workspaceId));
    return ColoredBox(
      color: t.canvas,
      child: plans.when(
        loading: () => const Center(child: CcSpinner(size: 24)),
        error: (e, _) => CcEmptyState(
          icon: AppIcons.triangleAlert,
          message: l10n.mobilePlansLoadFailed,
          description: e.toString(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return CcEmptyState(
              icon: AppIcons.fileText,
              message: l10n.mobilePlansEmpty,
              description: l10n.mobilePlansEmptyDescription,
            );
          }
          final ordered = [...items]
            ..sort((a, b) {
              final priority = (a.status == PlanDocumentStatus.proposed ? 0 : 1)
                  .compareTo(b.status == PlanDocumentStatus.proposed ? 0 : 1);
              return priority != 0
                  ? priority
                  : b.updatedAt.compareTo(a.updatedAt);
            });
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ordered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final plan = ordered[i];
              return CcCard(
                interactive: true,
                semanticLabel: plan.goal,
                onPressed: () => context.push(
                  remoteWorkspaceLocation(
                    '/plans/${Uri.encodeComponent(plan.id)}',
                    workspaceId,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(AppIcons.fileText, size: 20, color: t.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.goal,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              CcBadge(
                                label: planStatusLabel(l10n, plan.status),
                                variant:
                                    plan.status == PlanDocumentStatus.proposed
                                    ? CcBadgeVariant.warning
                                    : CcBadgeVariant.neutral,
                              ),
                              Text(
                                l10n.mobilePlanStepCount(
                                  plan.graph.workNodes.length,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: t.textSecondary,
                                ),
                              ),
                              Text(
                                shortDate(context, plan.updatedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: t.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      AppIcons.chevronRight,
                      size: 16,
                      color: t.textSecondary,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
