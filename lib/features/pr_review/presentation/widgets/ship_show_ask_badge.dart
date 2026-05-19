import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/domain/usecases/classify_ship_show_ask_use_case.dart';
import 'package:control_center/features/pr_review/providers/ship_show_ask_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Advisory badge showing the suggested Ship / Show / Ask lane for a PR.
///
/// The classifier is heuristic-only — it never blocks or triggers an action.
/// The badge is hidden while data is loading and on error.
class ShipShowAskBadge extends ConsumerWidget {
  /// Creates a [ShipShowAskBadge] for [prNumber].
  const ShipShowAskBadge({super.key, required this.prNumber});

  /// PR number to classify.
  final int prNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(shipShowAskProvider(prNumber));
    return result.when(
      data: (r) => r == null ? const SizedBox.shrink() : _Badge(result: r),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.result});
  final ShipShowAskResult result;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final (label, color) = switch (result.lane) {
      ShipShowAskLane.ship => (
        'Ship',
        tokens?.success ?? const Color(0xFF17A34A),
      ),
      ShipShowAskLane.show => (
        'Show',
        tokens?.accent ?? const Color(0xFFFA520F),
      ),
      ShipShowAskLane.ask => ('Ask', tokens?.warn ?? const Color(0xFFEAB308)),
    };

    return CcTooltip(
      targetAnchor: Alignment.bottomCenter,
      followerAnchor: Alignment.topCenter,
      message: result.reason,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
