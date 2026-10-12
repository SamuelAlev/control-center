import 'dart:io';

import 'package:cc_infra/src/evaluation/evaluation_cli.dart';

/// `cc_eval` — the paired evaluation CLI.
///
/// Run from this package: `fvm dart run bin/cc_eval.dart <command> [options]`.
/// It executes real agent runs (built-in harness or the Claude CLI) in real
/// isolated workspaces, verifies their output behaviorally, and writes an
/// auditable paired report; `replay` re-verifies recorded attempts offline.
Future<void> main(List<String> args) async {
  exitCode = await runEvaluationCli(args);
}
