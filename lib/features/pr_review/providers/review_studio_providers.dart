import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Identifies a PR across the Review Studio provider family.
class ReviewStudioTarget {
  /// Creates a [ReviewStudioTarget].
  const ReviewStudioTarget({
    required this.owner,
    required this.repo,
    required this.prNumber,
  });

  /// Repository owner.
  final String owner;

  /// Repository name.
  final String repo;

  /// PR number.
  final int prNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewStudioTarget &&
          owner == other.owner &&
          repo == other.repo &&
          prNumber == other.prNumber;

  @override
  int get hashCode => Object.hash(owner, repo, prNumber);
}

/// The Review Studio RPC repository (PRD 18) over the bound-workspace session.
final reviewStudioRepositoryProvider = Provider<RemoteReviewStudioRepository>(
  (ref) => RemoteReviewStudioRepository(ref.watch(rpcClientProvider)),
);

/// The active confidence-band floor for finding filtering (§9), 0..1.
final reviewConfidenceFloorProvider = StateProvider.autoDispose<double>(
  (ref) => 0.0,
);
