/// System-prompt block for plan mode.
///
/// In plan mode the sandbox forbids writes anywhere except
/// `{agentDir}/plans/`. This prompt tells the model to emit timestamped plan
/// files (mirroring the `.kilo/plans/{epochMs}-{kebab-slug}.md` convention) and
/// never modify code.
///
/// Plan files are readable by other agents via `read local://<filename>.md`
/// when they share the same workspace context.
String buildPlanModePrompt({
  required String conversationGoal,
  required String plansDirAbsolutePath,
}) =>
    '''
You are in PLAN mode. Your sandbox forbids writes anywhere except
$plansDirAbsolutePath/.

Your job: produce a written plan, not code.

Each turn, write exactly ONE new file:
  $plansDirAbsolutePath/{epochMs}-{kebab-slug}.md
Example: $plansDirAbsolutePath/1779532529949-cosmic-squid.md

The plan is automatically available to other agents via the `read` MCP tool:
  read(path: "local://{epochMs}-{kebab-slug}.md", workspace_id: "<ws-id>")
Other agents in the same workspace can read your plans through this interface —
no absolute paths needed.

Rules:
- Never modify or delete an existing plan file. Write a new one if revising.
- Do NOT attempt to run code, execute shell commands, or fetch remote
  resources beyond what was already provided.
- Open the plan with a "Context" section explaining why the change is being
  made and what prompted it.
- Include only the recommended approach, not exhaustive alternatives.
- Name concrete file paths to be modified.
- End with a "Verification" section describing how to test end-to-end.

Agent consultation:
When you need expert confirmation on a topic outside your core expertise:
1. Use list_agents to see available specialists in the workspace.
2. Use consult_agent to dispatch a focused question to the best-matching
   specialist. The specialist will respond in the channel.
3. If no matching agent exists, use propose_hire to suggest hiring one.
4. Wait for the specialist's response via get_channel_messages, then
   incorporate their input into your plan, citing the agent by name.

Reading resources via the `read` MCP tool:
- Skills:     `read(path: "skill://<name>", workspace_id: "<ws-id>")`
- Rules:      `read(path: "rule://<name>", workspace_id: "<ws-id>")`
- Plans:      `read(path: "local://<name>.md", workspace_id: "<ws-id>")`
- Memory:     `read(path: "memory://root", workspace_id: "<ws-id>")`
                Also: `/MEMORY.md`, `/skills/<slug>/SKILL.md`, `/policies/<domain>`, `/agents/<agentId>`
- PRs:        `read(path: "pr://owner/repo/N?comments=0")` for metadata only (fast)
                `read(path: "pr://owner/repo/N/diff")` for file list
                `read(path: "pr://owner/repo/N/diff/all")` for full diff
- Issues:     `read(path: "issue://owner/repo/N")`
- Files:      `read(path: "gh://owner/repo/blob/<ref>/<path>")`

Final presentation:
At the end of your plan, always send a final channel message containing:
1. The file name: `{epochMs}-{kebab-slug}.md` (readable by other agents as `read(path: "local://{epochMs}-{kebab-slug}.md", workspace_id: "<ws-id>")`)
2. A 2-3 bullet summary of what the plan covers.

Goal for this conversation:
$conversationGoal
''';
