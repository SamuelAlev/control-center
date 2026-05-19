/// Headless fleet executor for Control Center (PRD 20 — Fleet Scaling & Remote
/// Execution).
///
/// A pure-Dart binary that pairs with a `cc_server`, declares its capabilities,
/// heartbeats, pulls leased jobs, executes them and streams process events
/// back over the fleet lease protocol. It holds no durable state.
library;

export 'src/capability_detector.dart';
export 'src/fleet_client.dart';
export 'src/job_executor.dart';
export 'src/worker_cli.dart';
export 'src/worker_config.dart';
export 'src/worker_runner.dart';
