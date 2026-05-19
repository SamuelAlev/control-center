import 'package:cc_domain/features/agents/domain/value_objects/discovered_agent.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/util/agents_md_parser.dart';

/// Scans a workspace's own agent directory for `AGENTS.md` files that have not
/// yet been registered, so the operator can import them.
///
/// This reads only the workspace's managed agents directory (via
/// [WorkspaceFilesystemPort]), never arbitrary paths, so it stays within the
/// workspace isolation boundary.
class AgentDiscoveryService {
  /// Creates an [AgentDiscoveryService].
  AgentDiscoveryService({
    required WorkspaceFilesystemPort filesystem,
    AgentsMdParser? parser,
  })  : _filesystem = filesystem,
        _parser = parser ?? AgentsMdParser();

  final WorkspaceFilesystemPort _filesystem;
  final AgentsMdParser _parser;

  /// Returns the agents defined on disk whose name is not already in
  /// [existingNamesLower] (lower-cased). Malformed or unreadable files are
  /// skipped silently; duplicates within the scan are de-duplicated by name.
  Future<List<DiscoveredAgent>> findImportable({
    required String workspaceId,
    required Set<String> existingNamesLower,
  }) async {
    final slugs = await _filesystem.listAgentSlugs(workspaceId);
    final found = <DiscoveredAgent>[];
    final seen = <String>{};
    for (final slug in slugs) {
      final path = await _filesystem.agentFilePath(workspaceId, slug);
      try {
        final parsed = _parser.parseAgentFile(path);
        final key = parsed.name.toLowerCase();
        if (existingNamesLower.contains(key) || seen.contains(key)) {
          continue;
        }
        seen.add(key);
        found.add(
          DiscoveredAgent(
            name: parsed.name,
            title: parsed.title,
            skills: parsed.skills,
            agentMdPath: parsed.agentMdPath,
            reportsTo: parsed.reportsTo,
            persona: parsed.personaMarkdown.isEmpty
                ? null
                : parsed.personaMarkdown,
          ),
        );
      } catch (_) {
        // Skip files that don't parse — discovery is best-effort.
      }
    }
    return found;
  }
}
