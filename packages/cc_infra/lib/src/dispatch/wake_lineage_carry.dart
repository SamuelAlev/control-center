import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';

/// [wake] with the lineage (chain of wakes) its causing runs are in, as
/// [resolve] names it: the one place a wake gets [WakeFields.lineageRoot]
/// (a producer's own value is dropped). The runs are its source run and
/// the run it continues ([WakeFields.continuesRunId]). A person's message,
/// a goal's wakes and a rule's own wakes (its lineage is on the rule) carry
/// none. Called by the wake queue on every insert.
Future<Wake> carryWakeLineage(
  Wake wake,
  Future<String?> Function(String workspaceId, List<String> runIds)? resolve,
) async {
  final detail = wake.detail;
  final fields = {...detail.fields}..remove(WakeFields.lineageRoot);
  final continues = fields[WakeFields.continuesRunId];
  final runIds = [
    ?detail.sourceRunId,
    if (continues is String && continues.isNotEmpty) continues,
  ];
  final carries =
      resolve != null &&
      runIds.isNotEmpty &&
      detail.goalId == null &&
      detail.ruleId == null &&
      switch (wake.reason) {
        WakeReason.userMessage ||
        WakeReason.goalContinuation ||
        WakeReason.goalVerification ||
        WakeReason.goalReview => false,
        _ => true,
      };
  final root = carries ? await resolve(wake.workspaceId, runIds) : null;
  if (root == null && !detail.fields.containsKey(WakeFields.lineageRoot)) {
    return wake;
  }
  return wake.copyWith(
    detail: detail.copyWith(fields: {...fields, WakeFields.lineageRoot: ?root}),
  );
}
