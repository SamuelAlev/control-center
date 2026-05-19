import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Skill assignment section.
class SkillAssignmentSection extends StatelessWidget {
  /// Creates a new [SkillAssignmentSection].
  const SkillAssignmentSection({
    super.key,
    required this.selectedSkills,
    required this.availableSkills,
    required this.onChanged,
  });

  /// Skills currently assigned to the agent.
  final Set<String> selectedSkills;
  /// All skill slugs available in the current workspace.
  final List<String> availableSkills;
  /// Called when the user toggles a skill selection.
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (availableSkills.isEmpty) {
      return Text(
        'No skills available. Create skills in Settings → Skills first.',
        style: TextStyle(
          fontSize: 12,
          color: context.theme.colors.mutedForeground,
        ),
      );
    }
    final tokens = context.designSystem;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final skill in availableSkills)
          InputChip(
            label: Text(
              skill,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: selectedSkills.contains(skill)
                    ? (tokens?.textWhite ?? Colors.white)
                    : (tokens?.textTertiary ?? DesignSystemPalette.gray500),
              ),
            ),
            selected: selectedSkills.contains(skill),
            onSelected: (selected) {
              final updated = Set<String>.from(selectedSkills);
              if (selected) {
                updated.add(skill);
              } else {
                updated.remove(skill);
              }
              onChanged(updated);
            },
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

/// Agent form field.
class AgentFormField extends StatelessWidget {
  /// Creates a new [AgentFormField].
  const AgentFormField({super.key, required this.label, required this.child});
  /// Field label shown above the child widget.
  final String label;
  /// The form control widget to render.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

