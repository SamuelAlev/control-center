import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/harness_tool_search_tool.dart';

/// Estimated tokens [tools] occupy as definitions on the wire.
///
/// Mirrors `AgentLoopRunner`'s own overhead accounting exactly (same estimator,
/// same `name description schema` shape) so the number in a run log, the number
/// the context explorer reports and the number compaction budgets against are
/// the same number. Three plausible answers to "how big is the tool block?" is
/// how a regression hides.
int estimateToolSchemaTokens(Iterable<HarnessTool> tools) {
  const est = TokenEstimator.instance;
  var total = 0;
  for (final t in tools) {
    total += est.estimate(
      '${t.name} ${t.description} ${jsonEncode(t.inputSchema)}',
    );
  }
  return total;
}

/// The tool surface one run gets, in the three lists the loop takes.
class HarnessToolSurface {
  /// Creates a surface.
  const HarnessToolSurface({
    required this.resident,
    required this.deferred,
    this.scriptOnly = const [],
  });

  /// Tools whose schemas ride every request.
  final List<HarnessTool> resident;

  /// Tools the run may call directly but whose schemas are withheld until the
  /// model calls one or finds it through `search_tools`. With `repl`, only
  /// tools a script may not call are here.
  final List<HarnessTool> deferred;

  /// Tools callable only from a `repl` script. They never appear in a provider
  /// request; a direct call to one is answered with how to call it from a
  /// script. Empty without `repl`.
  final List<HarnessTool> scriptOnly;

  /// Whether the surface has `repl`.
  bool get hasRepl =>
      resident.any((tool) => tool.name == ReplToolDescription.toolName);

  /// Every tool the run may call, resident first.
  List<HarnessTool> get all => [...resident, ...deferred, ...scriptOnly];

  /// Whether anything waits to be searched for.
  bool get hasDeferred => deferred.isNotEmpty;
}

/// The tools of the MCP endpoint that no harness surface offers:
/// `search_tool_bm25`, the endpoint's catalogue search, whose place the
/// harness's own `search_tools` takes.
const Set<String> endpointOnlyTools = {'search_tool_bm25'};

/// Turns a built registry into the exact tool surface one run will see: the
/// mode's filter, then the one surface rule.
///
/// This exists so there is ONE assembly. The dispatch path and the
/// context-inspection path both need the answer to "what would the next run
/// advertise?", and an inspection that computed it separately would drift the
/// moment either side changed — which is exactly the bug the context explorer
/// exists to catch.
///
/// The mode's filter always runs first, so a script can never widen a
/// surface: it reaches only tools the mode already admitted. The direct set
/// is [residency]'s resident names without the discovery tools
/// ([ModeToolPolicy.residentDiscovery]), plus the surface's pinned verbs and
/// the interaction verbs. Then, for the admitted tools:
///
/// - **With `repl`** (the registry has one): `repl` first, then
///   `search_tools` when something is deferred, then every admitted tool of
///   the direct set in registry order. Every other tool a script may call is
///   script-only; every other tool a script may not call
///   ([HarnessTool.scriptCallable] false) is deferred, so it is never
///   script-only, where nothing could reach it. `list_my_tools` is not
///   offered: a script's `ALL_TOOLS` and the prompt's name index replace it.
/// - **Without `repl`**: the same direct set and the discovery tools are
///   resident, everything else is deferred, and the search tool goes in
///   front when something is.
///
/// The MCP endpoint's own catalogue search ([endpointOnlyTools]) is never on
/// a harness surface, in any mode, with `repl` or without: the harness has
/// `search_tools`, which ranks the same index, loads what it finds and says
/// which hits a run reaches only from a script, while the endpoint's search
/// knows nothing of a run's scripts.
///
/// With deferral switched off ([ToolResidencySpec.enabled] false) nothing is
/// deferred: without `repl` every admitted tool is resident, with `repl` a
/// tool a script may not call is resident instead of deferred.
///
/// The search tool is constructed HERE rather than in the registry builder
/// because it indexes the admitted surface, which does not exist until the
/// mode's filter has run. It is added only when something is actually deferred:
/// with the kill switch off there is nothing to search for, and advertising a
/// search over an already-complete list would just be a tool that wastes turns.
HarnessToolSurface materializeHarnessToolSurface({
  required HarnessToolRegistry registry,
  required ToolSurfaceSpec surface,
  required ToolResidencySpec residency,
}) {
  final admitted = [
    for (final tool in registry.toolsFor(surface))
      if (!endpointOnlyTools.contains(tool.name)) tool,
  ];
  HarnessTool? repl;
  for (final tool in admitted) {
    if (tool.name == ReplToolDescription.toolName) {
      repl = tool;
      break;
    }
  }
  final withoutRepl = [
    for (final tool in admitted)
      if (tool.name != ReplToolDescription.toolName) tool,
  ];
  bool isDiscovery(HarnessTool tool) =>
      ModeToolPolicy.residentDiscovery.contains(tool.name);
  final direct = <String>{
    for (final name in residency.residentNames)
      if (!ModeToolPolicy.residentDiscovery.contains(name)) name,
    ...surface.pinnedNames,
    ...ModeCapabilityProfile.interactionVerbs,
  };
  if (repl == null) {
    return _surfaceWithoutRepl(
      withoutRepl,
      ToolResidencySpec(
        enabled: residency.enabled,
        residentNames: {...direct, ...ModeToolPolicy.residentDiscovery},
      ),
    );
  }
  final residentNames = <String>{};
  final deferred = <HarnessTool>[];
  final scriptOnly = <HarnessTool>[];
  for (final tool in withoutRepl) {
    if (isDiscovery(tool)) {
      continue;
    }
    if (direct.contains(tool.name)) {
      residentNames.add(tool.name);
    } else if (tool.scriptCallable) {
      scriptOnly.add(tool);
    } else if (residency.enabled) {
      deferred.add(tool);
    } else {
      residentNames.add(tool.name);
    }
  }
  // Registry order, so the list comes out the same way every time: it is the
  // head of the provider's prompt-cache prefix. The discovery tools are left
  // out: the search tool is built below over this surface, and a run with
  // `repl` has no `list_my_tools`.
  final tail = [
    for (final tool in withoutRepl)
      if (residentNames.contains(tool.name)) tool,
  ];
  // `repl` goes FIRST and the search tool right behind it: their order must
  // not depend on where a given registry happened to register either.
  final resident = <HarnessTool>[
    repl,
    if (deferred.isNotEmpty)
      HarnessToolSearchTool(
        // What a direct call can reach. A script-only tool is indexed apart,
        // so a search that finds one says to call it from a script instead
        // of loading a schema the run must not send.
        catalog: [...tail, ...deferred],
        residency: ToolResidencySpec(
          residentNames: {for (final t in tail) t.name},
        ),
        scriptOnly: scriptOnly,
      ),
    ...tail,
  ];
  return HarnessToolSurface(
    resident: List.unmodifiable(resident),
    deferred: List.unmodifiable(deferred),
    scriptOnly: List.unmodifiable(scriptOnly),
  );
}

/// The surface of a run without `repl`: the resident/deferred split and, when
/// something is deferred, the search tool in front.
HarnessToolSurface _surfaceWithoutRepl(
  List<HarnessTool> admitted,
  ToolResidencySpec residency,
) {
  final partition = residency.partition(admitted);
  if (!residency.enabled || !partition.hasDeferred) {
    return HarnessToolSurface(
      resident: partition.resident,
      deferred: partition.deferred,
    );
  }
  // Indexes the whole admitted surface, resident tools included: a search that
  // cannot see a resident tool would report "no match" for something the run
  // has had all along.
  final search = HarnessToolSearchTool(catalog: admitted, residency: residency);
  // Deliberately FIRST and therefore stable: the resident list is the head of
  // the provider's prompt-cache prefix, so its order must not depend on what
  // else a given run happened to register.
  return HarnessToolSurface(
    resident: List.unmodifiable([search, ...partition.resident]),
    deferred: partition.deferred,
  );
}
