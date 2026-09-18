import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';

/// One definition candidate from [CodeGraphLookupPort.lookup].
class CodeGraphLookupCandidate {
  /// Creates a [CodeGraphLookupCandidate].
  const CodeGraphLookupCandidate({
    required this.id,
    required this.name,
    required this.qualifiedName,
    required this.kind,
    required this.filePath,
    required this.startLine,
    required this.endLine,
    this.parentName,
    this.signature = '',
    this.callerCount = 0,
    this.implementors = const [],
  });

  /// Symbol id.
  final String id;

  /// Unqualified name.
  final String name;

  /// Qualified name (container + name).
  final String qualifiedName;

  /// Symbol kind.
  final CodeSymbolKind kind;

  /// Repo-relative file path.
  final String filePath;

  /// Inclusive start line (1-based).
  final int startLine;

  /// Inclusive end line (1-based).
  final int endLine;

  /// Parent type/container name, if any.
  final String? parentName;

  /// Signature snippet.
  final String signature;

  /// Incoming `calls` edges (capped).
  final int callerCount;

  /// Types that implement/extend/mix-in this candidate.
  final List<CodeGraphLookupCandidate> implementors;
}

/// Result of a name-level code-graph lookup.
class CodeGraphLookupResult {
  /// Creates a [CodeGraphLookupResult].
  const CodeGraphLookupResult({
    required this.definitions,
    required this.fromBasePartition,
    this.fromDiff = false,
  });

  /// Empty lookup.
  const CodeGraphLookupResult.empty()
    : definitions = const [],
      fromBasePartition = true,
      fromDiff = false;

  /// Definition candidates sharing the queried name.
  final List<CodeGraphLookupCandidate> definitions;

  /// True when the answer came from the linked (base) checkout rather than
  /// the PR/space worktree partition.
  final bool fromBasePartition;

  /// True when [definitions] were recovered from the loaded pull-request
  /// diff rather than the code-graph index.
  final bool fromDiff;
}

/// Slim client port for the PR-diff symbol popover. The full
/// code-graph repository stays server-side.
abstract class CodeGraphLookupPort {
  /// Looks up [name] in [repoId] of [workspaceId].
  ///
  /// Optional [spaceId] selects the PR/space worktree partition (fail-open to
  /// the linked checkout when that partition is empty).
  Future<CodeGraphLookupResult> lookup({
    required String workspaceId,
    required String repoId,
    required String name,
    String? spaceId,
  });
}
