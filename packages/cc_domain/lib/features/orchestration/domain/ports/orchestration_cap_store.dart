/// The one write that changes an orchestration's cost cap after it was
/// created: a raise, conditional on the cap the caller read.
abstract interface class OrchestrationCapStore {
  /// Sets the cap of orchestration [id] in [workspaceId] to [to] while it is
  /// still [from], touching no other column. False when the row is gone or
  /// its cap is no longer [from] (a raise that lost a race).
  Future<bool> raiseCap(
    String workspaceId,
    String id, {
    required int from,
    required int to,
  });
}
