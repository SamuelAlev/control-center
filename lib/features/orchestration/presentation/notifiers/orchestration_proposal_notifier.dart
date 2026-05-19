import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/orchestration/providers/orchestration_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI state for orchestration-proposal actions: tracks which orchestration is
/// mid-action so the card can disable its buttons + show a spinner.
class OrchestrationProposalState {
  /// Creates an [OrchestrationProposalState].
  const OrchestrationProposalState({this.busyId, this.error});

  /// The orchestration id currently being approved/cancelled, or null.
  final String? busyId;

  /// The last error message, or null.
  final String? error;

  /// Copy helper.
  OrchestrationProposalState copyWith({String? busyId, String? error}) =>
      OrchestrationProposalState(busyId: busyId, error: error);
}

/// Drives approve / cancel actions on an orchestration proposal.
class OrchestrationProposalNotifier
    extends Notifier<OrchestrationProposalState> {
  @override
  OrchestrationProposalState build() => const OrchestrationProposalState();

  /// Approves the proposal and kicks off deterministic materialization.
  Future<void> approve({
    required String workspaceId,
    required String orchestrationId,
  }) async {
    state = OrchestrationProposalState(busyId: orchestrationId);
    try {
      await ref.read(approveOrchestrationUseCaseProvider).approve(
            workspaceId: workspaceId,
            orchestrationId: orchestrationId,
          );
      state = const OrchestrationProposalState();
    } on Object catch (e, st) {
      AppLog.e('OrchestrationProposal', 'approve failed', e, st);
      state = OrchestrationProposalState(error: '$e');
    }
  }

  /// Cancels (rejects) the proposal or a running orchestration.
  Future<void> cancel({
    required String workspaceId,
    required String orchestrationId,
  }) async {
    state = OrchestrationProposalState(busyId: orchestrationId);
    try {
      await ref.read(cancelOrchestrationUseCaseProvider).cancel(
            workspaceId: workspaceId,
            orchestrationId: orchestrationId,
          );
      state = const OrchestrationProposalState();
    } on Object catch (e, st) {
      AppLog.e('OrchestrationProposal', 'cancel failed', e, st);
      state = OrchestrationProposalState(error: '$e');
    }
  }
}

/// Provides the [OrchestrationProposalNotifier].
final orchestrationProposalNotifierProvider =
    NotifierProvider<OrchestrationProposalNotifier, OrchestrationProposalState>(
  OrchestrationProposalNotifier.new,
);
