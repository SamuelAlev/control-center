import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_search_query.dart';

/// Port for resolving a [PrSearchQuery] against a backend PR search service.
///
/// Adapters translate the backend-neutral query into a concrete provider's
/// search language (GitHub today, any other forge tomorrow) and return the
/// matching open pull requests grouped by repository, best-effort enriched so
/// the queue can still classify them into decision lanes.
abstract interface class PrSearchPort {
  /// Searches open pull requests across [repos] for those matching [query].
  ///
  /// Returns one [RepoPullRequests] group per repo that has matches; repos with
  /// no matches are omitted. Implementations should fail soft per repo (a
  /// failed repo contributes no group) rather than failing the whole search.
  Future<List<RepoPullRequests>> search({
    required PrSearchQuery query,
    required List<Repo> repos,
  });
}
