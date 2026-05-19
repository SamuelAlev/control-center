/// Background-process management (PRD 01 feature 8): start/list/status/logs/
/// stop/restart long-running child processes with optional readiness probes,
/// a ring-buffered output tail, auto-stop on session exit, and a sandbox gate.
library;

export 'background_process_manager.dart';
export 'background_process_tool.dart';
