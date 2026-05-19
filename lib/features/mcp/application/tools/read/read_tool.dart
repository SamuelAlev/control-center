import 'package:control_center/features/mcp/application/tools/read/internal_url.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url_router.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

/// Unified `read` MCP tool. Accepts a `path` URL in one of the supported
/// schemes and dispatches to the matching [InternalUrlRouter] handler.
///
/// Replaces the per-resource GitHub tools (`get_pr_diff`,
/// `get_pr_check_runs`, `list_github_pr_reviews`, `get_github_file_content`).
class ReadTool extends McpTool {
  /// Creates a [ReadTool].
  ReadTool({required InternalUrlRouter router}) : _router = router;

  final InternalUrlRouter _router;

  @override
  String get name => 'read';

  @override
  String get description =>
      'Read files, directories, archives, SQLite databases, images, documents, '
      'internal resources, and web URLs through a single `path` string. '
      '\n\n'
      '### Supported URL schemes\n'
      'Use these internal protocol URLs for all resource access — do NOT construct '
      'raw filesystem paths or GitHub API URLs.\n\n'
      '**pr://owner/repo/N[/diff[/all|N]][?comments=0|false]** — GitHub pull request.\n'
      '- Bare `pr://owner/repo/N`: full PR view (metadata, description, check runs, '
      'reviews, inline comments, issue comments). Use `?comments=0` to skip comments '
      'and speed up the response when you only need the PR summary.\n'
      '- `/diff`: numbered file list (compact).\n'
      '- `/diff/all`: full unified diff of all files.\n'
      '- `/diff/N`: diff of the Nth file only (1-indexed, from the file list).\n\n'
      '**issue://owner/repo/N** — GitHub issue with all comments.\n\n'
      '**gh://owner/repo/blob/ref/path** — raw file content from a GitHub repository '
      'at a specific ref (branch, tag, or commit SHA).\n\n'
      '**skill://<name>** — read a skill\'s SKILL.md from the workspace. '
      'REQUIRES workspace_id.\n\n'
      '**rule://<name>** — read memory policies by domain. '
      'REQUIRES workspace_id.\n\n'
      '**local://<name>.md** — read a plan artifact or contract shared with subagents. '
      'Resolves from the conversation plans/ dir or workspace root. '
      'REQUIRES workspace_id.\n\n'
      '**agent://<id>[/json-path]** — read an agent\'s output artifact. '
      'The id can be a run log ID or an agent ID (returns the latest completed run). '
      'Append a `/`-separated JSON path to extract a specific field '
      '(e.g. `agent://reviewer_0/findings/0/path`).\n\n'
      '**artifact://<id>** — read a captured artifact (log, trace, raw output). '
      'The id is numeric.\n\n'
      '**memory://root[/MEMORY.md|/skills/<slug>/SKILL.md|/policies/<domain>|/agents/<agentId>]** '
      '— workspace memory system. REQUIRES workspace_id.\n'
      '- `memory://root`: compact summary (fact/policy counts, topics, domains).\n'
      '- `memory://root/MEMORY.md`: full curated index.\n'
      '- `memory://root/skills/<slug>/SKILL.md`: a specific skill file.\n'
      '- `memory://root/policies/<domain>`: policies for a domain.\n'
      '- `memory://root/agents/<agentId>`: an agent\'s private working memory.\n\n'
      '**mcp://<uri>** — list MCP tools matching the URI (empty or * returns all).\n\n'
      '### Common mistakes to AVOID\n'
      '- NEVER forget workspace_id on skill://, rule://, local://, memory:// URLs.\n'
      '- NEVER use issue:// for PRs — use pr:// for PRs.\n'
      '- NEVER omit /blob/ in gh:// URLs.\n'
      '- NEVER construct raw GitHub API URLs (api.github.com) — use pr://, issue://, gh:// instead.\n'
      '- Use `?comments=0` to skip comments when you only need PR metadata or diffs.\n'
      '- AVOID using file:// (not yet implemented).';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description':
            'URL to read. See tool description for all supported schemes and formats. '
            'REQUIRED. Common patterns: '
            'pr://owner/repo/N for PRs, issue://owner/repo/N for issues, '
            'gh://owner/repo/blob/ref/path for file content.',
      },
      'workspace_id': {
        'type': 'string',
        'description':
            'REQUIRED for skill://, rule://, local://, and memory:// schemes. '
            'Not needed for pr://, issue://, gh://, agent://, artifact://, mcp://.',
      },
    },
    'required': ['path'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawPath = arguments['path'];
    if (rawPath is! String) {
      return CallResult.error(
        'Missing or invalid argument: path (expected string)',
      );
    }
    final rawWorkspaceId = arguments['workspace_id'];
    final result = InternalUrl.parse(rawPath);
    return result.fold(
      onError: (e) => CallResult.error('Invalid URL: ${e.message}'),
      onOk: (url) => _router.dispatch(
        url,
        ReadContext(
          workspaceId: rawWorkspaceId is String ? rawWorkspaceId : null,
        ),
      ),
    );
  }
}
