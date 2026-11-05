part of 'meeting_notes_tab.dart';

class _EnhancedTag extends StatelessWidget {
  const _EnhancedTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.mAccentSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.sparkles, size: 12, color: context.mAccent),
          const SizedBox(width: 5),
          Text(
            label,
            style: meetingMono(context, fontSize: 11, color: context.mAccent),
          ),
        ],
      ),
    );
  }
}
