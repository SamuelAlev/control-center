import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The context-window badge on a model row — a small mono capsule, the one
/// number that decides whether a model fits the job.
class ModelContextPill extends StatelessWidget {
  /// Creates a [ModelContextPill].
  const ModelContextPill({required this.tokens, super.key});

  /// The context window in tokens.
  final int tokens;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: t.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          _compactTokens(tokens),
          style: CcFonts.code(
            textStyle: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// "200K" / "1M" / "1.5M".
String _compactTokens(int tokens) {
  if (tokens >= 1000000) {
    final m = tokens / 1000000;
    return m == m.roundToDouble()
        ? '${m.toStringAsFixed(0)}M'
        : '${m.toStringAsFixed(1)}M';
  }
  if (tokens >= 1000) {
    return '${(tokens / 1000).toStringAsFixed(0)}K';
  }
  return '$tokens';
}
