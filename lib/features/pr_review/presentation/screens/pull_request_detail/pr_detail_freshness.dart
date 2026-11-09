import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stamps [prRef]'s freshness on every successful (re)load — the initial
/// fetch and each poll or manual refresh — so the title row can report
/// "Checked {time}". Call from `build`.
void listenForPrDetailFreshness(WidgetRef ref, PrRef prRef) {
  ref.listen(prDetailProvider(prRef), (_, next) {
    if (next is AsyncData && !next.isLoading) {
      ref
          .read(lastCheckedProvider.notifier)
          .stamp('pr-detail:${prRef.repoFullName}#${prRef.number}');
    }
  });
}
