import 'package:cc_domain/features/pr_review/domain/usecases/classify_ship_show_ask_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/ship_show_ask_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Advisory badge showing the suggested Ship / Show / Ask lane for a PR.
///
/// The classifier is heuristic-only — it never blocks or triggers an action.
/// The badge is hidden while data is loading and on error.
class ShipShowAskBadge extends ConsumerWidget {
  /// Creates a [ShipShowAskBadge] for [prRef].
  const ShipShowAskBadge({super.key, required this.prRef});

  /// PR number to classify.
  final PrRef prRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(shipShowAskProvider(prRef));
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
    final (label, variant) = switch (result.lane) {
      ShipShowAskLane.ship => ('Ship', CcBadgeVariant.success),
      ShipShowAskLane.show => ('Show', CcBadgeVariant.info),
      ShipShowAskLane.ask => ('Ask', CcBadgeVariant.warning),
    };

    return CcTooltip(
      message: result.reason,
      child: CcBadge(label: label, variant: variant),
    );
  }
}
