import 'package:cc_harness/src/tools/tool.dart';

/// Splits an admitted tool surface into what the model sees up front and what
/// it can pull in on demand.
///
/// The problem this solves is not cost, it is ATTENTION. A catalogue of ~130
/// tools costs ~24k tokens of every request, but the measured damage is to
/// tool-selection accuracy: published evaluations put the cliff at 30-50 tools
/// and report accuracy RISING when the surplus is deferred rather than shown.
/// So the resident set is deliberately small and the rest stays one step away.
///
/// Residency is applied AFTER `ToolSurfaceSpec` filtering, never instead of it.
/// A deferred tool is one the run is already allowed to call — deferral hides a
/// schema, it never widens a surface. Everything a mode denies stays denied,
/// and an activated tool still passes the approval callback and the action
/// guard exactly like a resident one.
///
/// Name-based data only, like `ToolSurfaceSpec`: the kernel knows nothing about
/// Control Center's modes. Dispatch projects its policy onto one of these.
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
