part of 'artifact_chart.dart';

/// Series/category key. Always rendered — the chart never relies on color alone.
class _Legend extends StatelessWidget {
  const _Legend({required this.entries});

  final List<({String label, Color color})> entries;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final e in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: e.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                e.label,
                style: AppTextStyles.labelSmall(
                  tokens,
                ).copyWith(color: tokens.textSecondary),
              ),
            ],
          ),
      ],
    );
  }
}
