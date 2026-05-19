import 'package:cc_harness/src/provider/llm_provider_port.dart';
import 'package:cc_harness/src/tools/tool.dart';
import 'package:cc_harness/src/tools/tool_surface.dart';

/// Holds the tools available to the agent loop and exposes them as provider
/// schemas, with per-conversation-mode filtering.
///
/// Tools are de-duplicated by name (first registration wins), so registering
/// built-in tools before bridged MCP tools lets the harness's own
/// `read`/`bash`/… take precedence over any same-named MCP tool.
class HarnessToolRegistry {
  /// Creates an empty registry.
  HarnessToolRegistry();

  /// Creates a registry pre-populated with [tools].
  factory HarnessToolRegistry.of(Iterable<HarnessTool> tools) {
    final registry = HarnessToolRegistry();
    registry.registerAll(tools);
    return registry;
  }

  final Map<String, HarnessTool> _tools = {};

  /// Registers [tool] unless a tool with the same name already exists.
  void register(HarnessTool tool) {
    _tools.putIfAbsent(tool.name, () => tool);
  }

  /// Registers all [tools] (first-wins on name collisions).
  void registerAll(Iterable<HarnessTool> tools) {
    for (final tool in tools) {
      register(tool);
    }
  }

  /// Removes the tool named [name], if present.
  void unregister(String name) => _tools.remove(name);

  /// All registered tools.
  List<HarnessTool> get tools => List.unmodifiable(_tools.values);

  /// Provider schemas for all registered tools.
  List<LlmToolSchema> get schemas => [
    for (final t in _tools.values) t.toSchema(),
  ];

  /// The tool named [name], or null.
  HarnessTool? findByName(String name) => _tools[name];

  /// Number of registered tools.
  int get length => _tools.length;

  /// Tools permitted by [surface].
  ///
  /// The surface carries every mode-specific fact as data (tier ceiling, deny
  /// list, optional allow-list above a free tier and the pinned output verbs
  /// that must always survive), so the registry itself holds no policy.
  List<HarnessTool> toolsFor(ToolSurfaceSpec surface) =>
      surface.filter(_tools.values);

  /// What [surface] admits and removes from this registry, with reasons.
  /// Feeds the generated capability preamble.
  ToolSurfaceReport describeFor(ToolSurfaceSpec surface) =>
      surface.describe(_tools.values);
}
