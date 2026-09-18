import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_chip.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Policy node — neutral card marked by the scale glyph, not a colored border.
class PolicyNode extends StatelessWidget {
  const PolicyNode({super.key, required this.policy, required this.onTap});

  final MemoryPolicy policy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: policy.active ? 1.0 : 0.55,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: tokens.bgPrimary,
            borderRadius: AppRadii.brMd,
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.scale, size: 12, color: tokens.fgQuaternary),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(child: MemoryMetaChip(label: policy.domain)),
                  const Spacer(),
                  if (!policy.active)
                    Icon(AppIcons.eyeOff, size: 12, color: tokens.fgQuaternary),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                policy.rule.split('\n').first,
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
      ),
    );
  }
}
