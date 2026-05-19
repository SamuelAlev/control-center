import 'package:cc_domain/core/domain/entities/active_process_info.dart';

/// Port for detecting and killing local agent processes.
abstract interface class ProcessDetectionPort {
  /// Returns a list of currently running agent processes.
  Future<List<ActiveProcessInfo>> detect();
  /// Kill process.
  Future<void> killProcess(int pid);
}

