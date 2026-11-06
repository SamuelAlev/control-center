import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_chrome.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_chip.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_excerpt.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Policy node — neutral card marked by the scale glyph, not a colored border.
class PolicyNode extends StatelessWidget {
  /// Creates a [PolicyNode].
  const PolicyNode({
    super.key,
    required this.policy,
    required this.selected,
    required this.onTap,
  });

  /// The policy rendered on this card.
  final MemoryPolicy policy;

  /// Whether the inspector is showing this node.
  final bool selected;

  /// Selects this policy.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Opacity(
      opacity: policy.active ? 1.0 : 0.55,
      child: GraphNodeSurface(
        color: tokens.bgPrimary,
        borderColor: tokens.borderSecondary,
        borderRadius: AppRadii.brMd,
        padding: const EdgeInsets.all(AppSpacing.sm),
        selected: selected,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.scale, size: 12, color: tokens.fgQuaternary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: MemoryMetaChip(
                    label: MemoryDomainScope.parse(policy.domain).name,
                  ),
                ),
                const Spacer(),
                if (!policy.active)
                  Icon(AppIcons.eyeOff, size: 12, color: tokens.fgQuaternary),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              memoryPlainExcerpt(policy.rule),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(
                color: tokens.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
