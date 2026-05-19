import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';

/// Quiet metadata chip for an agent skill.
///
/// Per DESIGN.md's chip spec: Fog/secondary background, 1px Mist border,
/// Slate/tertiary text — deliberately *not* the brand-blue fill, so Command
/// Blue stays reserved for action, selection and live state.
class SkillChip extends StatelessWidget {
  /// Creates a [SkillChip].
  const SkillChip({super.key, required this.label});

  /// The skill name.
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tokens.textTertiary,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }
}

/// A small "+N" overflow chip for skills hidden in a compact row.
class SkillOverflowChip extends StatelessWidget {
  /// Creates a [SkillOverflowChip].
  const SkillOverflowChip({super.key, required this.count});

  /// How many skills are hidden.
  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return Text(
      '+$count',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: tokens.textQuaternary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
