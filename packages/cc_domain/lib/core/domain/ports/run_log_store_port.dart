/// Port for writing and reading agent run logs. Enables swappable storage
/// backends (file-based, DB-backed, cloud-backed) without changing dispatch logic.
abstract interface class RunLogStorePort {
  /// Writes a chunk of run output to the log identified by [runId].
  Future<void> writeChunk(String runId, String chunk);

  /// Reads the complete log for [runId].
  Future<String> readLog(String runId);

  /// Compacts an oversized log by preserving head (60%) + tail (25%) and
  /// inserting a truncation marker.
  Future<void> compact(String runId);
}
