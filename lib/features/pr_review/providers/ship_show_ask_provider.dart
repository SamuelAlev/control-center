import 'package:cc_domain/features/pr_review/domain/usecases/classify_ship_show_ask_use_case.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _classifier = ClassifyShipShowAskUseCase();

/// Derives a [ShipShowAskResult] from the live PR detail, files and checks.
///
/// Returns null when any required stream is still loading, so the badge can
/// hide itself cleanly.
final shipShowAskProvider = Provider.autoDispose
    .family<AsyncValue<ShipShowAskResult?>, PrRef>((ref, pr) {
      final prAsync = ref.watch(prDetailProvider(pr));
      final filesAsync = ref.watch(prFilesProvider(pr));
      final checksAsync = ref.watch(prCheckRunsProvider(pr));

      if (prAsync.isLoading || filesAsync.isLoading || checksAsync.isLoading) {
        return const AsyncValue.loading();
      }

      final prEntity = prAsync.value;
      final files = filesAsync.value;
      final checks = checksAsync.value;

      if (prEntity == null || files == null || checks == null) {
        return const AsyncValue.data(null);
      }

      final result = _classifier.classify(
        pr: prEntity,
        files: files,
        checks: checks,
      );
      return AsyncValue.data(result);
    });
