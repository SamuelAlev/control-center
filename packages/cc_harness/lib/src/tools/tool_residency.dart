import 'package:cc_harness/src/tools/tool.dart';

/// Splits an admitted tool surface into resident schemas vs on-demand names.
/// Applied AFTER `ToolSurfaceSpec` — deferral never widens a surface; activated
/// tools still pass approval/guard. Name-based only; dispatch projects policy.
class ToolResidencySpec {
  /// Creates a residency spec.
  const ToolResidencySpec({
    this.enabled = true,
    this.residentNames = const {},
  });

  /// Everything resident — the pre-deferral behaviour, byte for byte.
  ///
  /// This is what the kill switch selects, and what every caller that has no
  /// opinion gets, so deferral is opt-in at the policy layer rather than a
  /// surprise for an embedder that only wanted a tool registry.
  const ToolResidencySpec.allResident() : this(enabled: false);

  /// Whether to defer anything at all. When false every admitted tool is
  /// resident and [partition] returns an empty deferred list.
  final bool enabled;

  /// Tools whose schemas are sent on every request.
  ///
  /// A name that matches no admitted tool is simply inert — policy names the
  /// tools it wants resident without having to know which of them a given run
  /// actually materialized (LSP tools depend on a project root, `ask_user` on a
  /// space, MCP tools on their services being wired).
  final Set<String> residentNames;

  /// Whether [tool] is sent up front.
  bool isResident(HarnessTool tool) =>
      !enabled || residentNames.contains(tool.name);

  /// Splits [admitted] into resident and deferred, preserving order in both.
  ///
  /// Order is load-bearing: the resident list is the head of the provider's
  /// prompt-cache prefix, so it has to come out of the registry the same way
  /// every time for the cache to hit.
  ToolResidencyPartition partition(Iterable<HarnessTool> admitted) {
    if (!enabled) {
      return ToolResidencyPartition(
        resident: List.unmodifiable(admitted),
        deferred: const [],
      );
    }
    final resident = <HarnessTool>[];
    final deferred = <HarnessTool>[];
    for (final tool in admitted) {
      (residentNames.contains(tool.name) ? resident : deferred).add(tool);
    }
    return ToolResidencyPartition(
      resident: List.unmodifiable(resident),
      deferred: List.unmodifiable(deferred),
    );
  }
}

/// The result of applying a [ToolResidencySpec] to an admitted tool list.
class ToolResidencyPartition {
  /// Creates a partition.
  const ToolResidencyPartition({
    required this.resident,
    required this.deferred,
  });

  /// Tools whose schemas ride every request.
  final List<HarnessTool> resident;

  /// Tools the run may call but whose schemas are withheld until first use.
  final List<HarnessTool> deferred;

  /// Every tool the run may call, resident first.
  List<HarnessTool> get all => [...resident, ...deferred];

  /// Whether anything is being withheld.
  bool get hasDeferred => deferred.isNotEmpty;
}
