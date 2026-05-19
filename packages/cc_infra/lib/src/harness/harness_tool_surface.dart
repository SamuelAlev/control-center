import 'dart:convert';

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

/// Turns a built registry into the exact tool surface one run will see: the
/// mode's filter, then the resident/deferred split, then the search tool that
/// makes the deferred half reachable.
///
/// This exists so there is ONE assembly. The dispatch path and the
/// context-inspection path both need the answer to "what would the next run
/// advertise?", and an inspection that computed it separately would drift the
/// moment either side changed — which is exactly the bug the context explorer
/// exists to catch.
///
/// The search tool is constructed HERE rather than in the registry builder
/// because it indexes the admitted surface, which does not exist until the
/// mode's filter has run. It is added only when something is actually deferred:
/// with the kill switch off there is nothing to search for, and advertising a
/// search over an already-complete list would just be a tool that wastes turns.
ToolResidencyPartition materializeHarnessToolSurface({
  required HarnessToolRegistry registry,
  required ToolSurfaceSpec surface,
  required ToolResidencySpec residency,
}) {
  final admitted = registry.toolsFor(surface);
  if (!residency.enabled) {
    return residency.partition(admitted);
  }
  final partition = residency.partition(admitted);
  if (!partition.hasDeferred) {
    return partition;
  }
  // Indexes the whole admitted surface, resident tools included: a search that
  // cannot see a resident tool would report "no match" for something the run
  // has had all along.
  final search = HarnessToolSearchTool(
    catalog: admitted,
    residency: residency,
  );
  // Deliberately FIRST and therefore stable: the resident list is the head of
  // the provider's prompt-cache prefix, so its order must not depend on what
  // else a given run happened to register.
  return ToolResidencyPartition(
    resident: List.unmodifiable([search, ...partition.resident]),
    deferred: partition.deferred,
  );
}
