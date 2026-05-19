// ActiveProcessInfo was promoted to the shared kernel
// (core/domain/entities/active_process_info.dart) so the process-detection port
// can live in core/domain/ports. Re-exported here for existing dashboard call
// sites.
export 'package:cc_domain/core/domain/entities/active_process_info.dart';

/// Dashboard status.
class DashboardStatus {
  /// Creates a new [DashboardStatus].
  const DashboardStatus({
    required this.totalWorkspaces,
  }) : assert(totalWorkspaces >= 0, 'Total workspaces must not be negative');

  /// Total number of workspaces.
  final int totalWorkspaces;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardStatus &&
          runtimeType == other.runtimeType &&
          totalWorkspaces == other.totalWorkspaces;

  @override
  int get hashCode => totalWorkspaces.hashCode;

  @override
  String toString() =>
      'DashboardStatus(workspaces: $totalWorkspaces)';
}
