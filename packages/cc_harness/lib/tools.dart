/// The tool contract: tools, registry, approval tiers, action classes, the
/// loop tool policy, the command-runner port and subagent profiles/spawning.
library;

// A tool result can carry images, so the image block is part of the tool
// contract — re-exported here so a tool author needs one import, not two.
export 'src/messages.dart' show HarnessImageBlock;
export 'src/tools/action_class.dart';
export 'src/tools/command_runner.dart';
export 'src/tools/file_search_port.dart';
export 'src/tools/staged_edit.dart';
export 'src/tools/subagent_profile.dart';
export 'src/tools/subagent_spawner.dart';
export 'src/tools/tool.dart';
export 'src/tools/tool_registry.dart';
export 'src/tools/tool_residency.dart';
export 'src/tools/tool_surface.dart';
export 'src/tools/vibe_workers.dart';
