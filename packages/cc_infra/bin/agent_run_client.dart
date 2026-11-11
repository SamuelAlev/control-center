import 'dart:io';

import 'package:cc_infra/agent_run_client.dart';

/// The agent run client when the server runs from source (and in tests); a
/// compiled server runs it as `cc_server agent-run <verb> …`.
Future<void> main(List<String> args) async {
  exit(await runAgentRunClient(args));
}
