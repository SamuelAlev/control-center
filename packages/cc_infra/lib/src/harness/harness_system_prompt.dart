import 'package:cc_harness_runtime/cc_harness_runtime.dart';

/// The harness system prompt, decomposed: the standing base instructions, the
/// repo's `AGENTS.md` files and the skills index — the three inputs
/// [assemble] concatenates into the exact string a run receives.
class HarnessSystemPromptParts {
  /// Creates a [HarnessSystemPromptParts].
  const HarnessSystemPromptParts({
    required this.baseInstructions,
    required this.agentsMdFiles,
    required this.skills,
  });

  /// The hardcoded base operating instructions plus the workspace line and,
  /// for a real run, the commit co-author trailer.
  final String baseInstructions;

  /// The discovered `AGENTS.md` files (root first), content included.
  final List<AgentsMdFilePart> agentsMdFiles;

  /// The skills visible to the run (frontmatter name/description + path).
  final List<HarnessSkillInfo> skills;

  /// The `AGENTS.md` block as it lands in the prompt (headers included), or an
  /// empty string when no instruction files were found.
  String get agentsMdBlock => AgentsMdContextLoader.formatParts(agentsMdFiles);

  /// The skills index as it lands in the prompt, or an empty string.
  String get skillsBlock {
    if (skills.isEmpty) {
      return '';
    }
    final buffer = StringBuffer(
      '\n\n# Available skills\n\nLoad a skill by reading its SKILL.md '
      'with the read tool.\n',
    );
    for (final skill in skills) {
      final desc = skill.description.isEmpty ? '' : ' — ${skill.description}';
      buffer.write('\n- ${skill.name}$desc (${skill.path})');
    }
    return buffer.toString();
  }

  /// The exact system-prompt string a dispatch sends.
  String assemble() {
    final buffer = StringBuffer(baseInstructions);
    final agentsMd = agentsMdBlock;
    if (agentsMd.isNotEmpty) {
      buffer
        ..write('\n\n# Repository instructions (AGENTS.md)\n\n')
        ..write(agentsMd);
    }
    buffer.write(skillsBlock);
    return buffer.toString();
  }
}

/// Assembles the harness system prompt: base operating instructions + the
/// repo's AGENTS.md hierarchy (root + nested) + available skills.
///
/// Extracted from `DispatchSession` so the context-inspection path can
/// rebuild the same prompt headlessly: there is ONE assembly, shared by the
/// run and the explorer, so the two can never drift.
class HarnessSystemPromptBuilder {
  /// Creates a [HarnessSystemPromptBuilder].
  const HarnessSystemPromptBuilder();

  /// Builds the parts for a run rooted at [workingDirectory] in [workspaceId].
  ///
  /// [agentConfigDir] is the agent's global config dir (a skill-scan base);
  /// [coAuthorTrailer] is the git-trailer line a real run appends — null on
  /// the inspection path, where no requesting human is in play.
  ///
  /// [permittedLinkRoots] are the server-managed directories whose symlinks the
  /// loaders may follow. Without them the overlay cwd yields nothing at all:
  /// its `AGENTS.md` and its attached skills are both symlinks, and a
  /// `followLinks: false` listing types a symlink as neither `File` nor
  /// `Directory`. Pass the agent config dir, the workspace `skills/` dir and
  /// the space's `repos/` dir.
  Future<HarnessSystemPromptParts> build({
    required String workspaceId,
    required String workingDirectory,
    String? agentConfigDir,
    String? coAuthorTrailer,
    List<String> permittedLinkRoots = const [],
    void Function(String message)? onWarning,
  }) async {
    final buffer = StringBuffer(
      'You are a capable coding agent running inside Control Center. '
      'Use the available tools to read, search, edit and run code to '
      'accomplish the task. Prefer the MCP tools (memory, messaging, '
      'tickets, agents, PRs) for orchestration and the built-in tools '
      '(read, write, edit, bash, search, find, search_files) for the '
      'filesystem. Work in the current directory. Be concise and report '
      'what you did.',
    );
    if (workspaceId.isNotEmpty) {
      buffer.write(' Workspace: $workspaceId.');
    }

    // Credit the requesting human on machine commits: the commit is authored
    // by the agent (per-run GIT_AUTHOR_* env) and the trailer records who
    // asked for the work.
    if (coAuthorTrailer != null) {
      buffer.write(
        '\n\nWhen you create git commits, append this trailer line to the '
        'commit message: $coAuthorTrailer',
      );
    }

    // Repo operating instructions (AGENTS.md, root + nested).
    var agentsMdFiles = const <AgentsMdFilePart>[];
    try {
      agentsMdFiles = await const AgentsMdContextLoader().loadParts(
        workingDirectory,
        permittedLinkRoots: permittedLinkRoots,
      );
    } on Object catch (e) {
      onWarning?.call('DispatchSession: AGENTS.md load failed: $e');
    }

    // Skills: autoload frontmatter; the agent reads the SKILL.md body on
    // demand.
    var skills = const <HarnessSkillInfo>[];
    try {
      skills = await const HarnessSkillScanner().scan(
        [agentConfigDir, workingDirectory],
        permittedLinkRoots: permittedLinkRoots,
      );
    } on Object catch (e) {
      onWarning?.call('DispatchSession: skill scan failed: $e');
    }

    return HarnessSystemPromptParts(
      baseInstructions: buffer.toString(),
      agentsMdFiles: agentsMdFiles,
      skills: skills,
    );
  }
}
