part of 'meeting_notes_tab.dart';

class _EnhancedTag extends StatelessWidget {
  const _EnhancedTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return CcBadge(
      label: label,
      icon: AppIcons.sparkles,
      variant: CcBadgeVariant.info,
    );
  }
}
