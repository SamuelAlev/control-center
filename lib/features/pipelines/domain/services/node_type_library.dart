import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// One entry in the editor sidebar — represents a kind of node the user
/// can drag onto the canvas.
class NodeType {
  /// Creates a [NodeType].
  const NodeType({
    required this.id,
    required this.displayName,
    required this.description,
    required this.defaultKind,
    required this.defaultBodyKey,
    this.defaultConfig = PipelineNodeConfig.empty,
    this.iconCodePoint,
  });

  /// Stable identifier (used as the drag payload).
  final String id;

  /// Human-readable name shown in the sidebar.
  final String displayName;

  /// One-line description shown in the sidebar.
  final String description;

  /// Default [StepKind] when dropped onto the canvas.
  final StepKind defaultKind;

  /// Default `bodyKey` the node binds to.
  final String defaultBodyKey;

  /// Default per-node config (prompt template, role hint, etc.).
  final PipelineNodeConfig defaultConfig;

  /// Optional icon code point (Material Symbols).
  final int? iconCodePoint;
}

/// Read-only catalog of [NodeType]s available in the editor.
class NodeTypeLibrary {
  /// Creates a [NodeTypeLibrary] from a list of [NodeType] entries.
  const NodeTypeLibrary(this.types);

  /// All entries, in display order.
  final List<NodeType> types;

  /// Returns the entry with [id], or null if absent.
  NodeType? byId(String id) {
    for (final t in types) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// The default library shipped with the app.
///
/// Built-in nodes bind to code-registered `bodyKey`s. The "Custom prompt"
/// entry routes through the generic `pipeline.promptAgent` body, letting
/// users author arbitrary prompt-driven steps without code changes.
NodeTypeLibrary defaultNodeTypeLibrary() {
  return const NodeTypeLibrary([
    NodeType(
      id: 'bash.script',
      displayName: 'Bash script',
      description:
          'Runs a shell script with {{state}} substitution. GITHUB_TOKEN '
          'is available in env. Useful for clones, builds, gh CLI — no '
          'agent dispatched, no tokens burned.',
      defaultKind: StepKind.listen,
      defaultBodyKey: BuiltInBodyKeys.bashScript,
      defaultConfig: PipelineNodeConfig(
        label: 'Bash script',
        outputKey: 'script_output',
        script:
            'set -euo pipefail\n'
            'echo "Hello from {{prTitle}}"',
      ),
    ),
    NodeType(
      id: 'bash.clonePr',
      displayName: 'Clone PR branch',
      description:
          'Agentless setup — discovers the PR head branch via `gh pr view` '
          'then clones it into the pipeline workspace.',
      defaultKind: StepKind.listen,
      defaultBodyKey: BuiltInBodyKeys.bashScript,
      defaultConfig: PipelineNodeConfig(
        label: 'Clone PR branch',
        inputKeys: ['repoFullName', 'prNumber'],
        outputKey: 'repoLocalPath',
        script:
            'set -euo pipefail\n'
            'REPO="{{repoFullName}}"\n'
            'PR_NUMBER="{{prNumber}}"\n'
            'TARGET="repo"\n'
            'BRANCH=\$(gh pr view "\$PR_NUMBER" --repo "\$REPO" '
            "--json headRefName --jq '.headRefName')\n"
            'gh repo clone "\$REPO" "\$TARGET" -- --branch "\$BRANCH" '
            '--depth 50 --single-branch\n'
            'echo -n "\$(pwd)/\$TARGET"',
      ),
    ),
    NodeType(
      id: 'prReview.comment',
      displayName: 'Post PR comment',
      description:
          'Posts the consolidated findings to the PR as a GitHub review '
          'comment.',
      defaultKind: StepKind.listen,
      defaultBodyKey: BuiltInBodyKeys.prReviewComment,
      defaultConfig: PipelineNodeConfig(
        label: 'Post PR comment',
        inputKeys: ['consolidatedFindings', 'prNumber', 'repoFullName'],
      ),
    ),
    NodeType(
      id: 'prompt.reviewer',
      displayName: 'Reviewer (prompt)',
      description:
          'Dispatches a specialist reviewer agent with a customizable '
          'prompt. Suspends until the agent calls complete_task.',
      defaultKind: StepKind.listen,
      defaultBodyKey: BuiltInBodyKeys.promptAgent,
      defaultConfig: PipelineNodeConfig(
        label: 'Reviewer',
        inputKeys: ['repoLocalPath', 'prTitle', 'prNumber'],
        outputKey: 'reviewer_findings',
        prompt:
            'You are a specialist reviewer. The PR branch is checked out '
            'at `{{repoLocalPath}}`. PR #{{prNumber}} — {{prTitle}}.\n\n'
            'Return a bulleted list of findings with `path:line` references.',
      ),
    ),
    NodeType(
      id: 'prompt.join',
      displayName: 'Consolidate (join)',
      description:
          'Joins multiple upstream branches and asks an agent to '
          'consolidate their outputs into a single artefact.',
      defaultKind: StepKind.join,
      defaultBodyKey: BuiltInBodyKeys.promptAgent,
      defaultConfig: PipelineNodeConfig(
        label: 'Consolidate',
        outputKey: 'consolidatedFindings',
        prompt:
            'Consolidate the upstream findings into a single report.\n\n'
            '{{qa_findings}}\n\n{{architect_findings}}\n\n'
            '{{engineer_findings}}',
      ),
    ),
    NodeType(
      id: 'prompt.custom',
      displayName: 'Custom prompt',
      description:
          'Generic prompt-driven node. Pick a role, write a prompt, list '
          'inputs/output key. Routed through the promptAgent body.',
      defaultKind: StepKind.listen,
      defaultBodyKey: BuiltInBodyKeys.promptAgent,
      defaultConfig: PipelineNodeConfig(
        label: 'Custom prompt',
        outputKey: 'custom_output',
        prompt: 'Write your prompt here. Use {{state_key}} placeholders.',
      ),
    ),
    NodeType(
      id: 'hello.greet',
      displayName: 'Hello: greet',
      description: 'Demo body that writes a greeting into state.',
      defaultKind: StepKind.listen,
      defaultBodyKey: BuiltInBodyKeys.helloGreet,
    ),
    NodeType(
      id: 'hello.world',
      displayName: 'Hello: world',
      description: 'Demo body that appends to the greeting.',
      defaultKind: StepKind.listen,
      defaultBodyKey: BuiltInBodyKeys.helloWorld,
    ),
    NodeType(
      id: 'messaging.postChannel',
      displayName: 'Post to channel',
      description:
          'Sends a message to a messaging channel. Reads channelId and '
          'content from pipeline state. Useful for digest/notification '
          'steps at the end of a pipeline.',
      defaultKind: StepKind.listen,
      defaultBodyKey: BuiltInBodyKeys.messagingPostChannel,
      defaultConfig: PipelineNodeConfig(
        label: 'Post to channel',
        inputKeys: ['channelId', 'content'],
        outputKey: 'postedChannelId',
      ),
    ),
    NodeType(
      id: 'pipeline.condition',
      displayName: 'Condition / switch (router)',
      description:
          'Branches the flow. Switch mode routes on a state key value; '
          'comparison mode routes true/false. Outgoing edges carry a route '
          'key that must match.',
      defaultKind: StepKind.router,
      defaultBodyKey: BuiltInBodyKeys.condition,
      defaultConfig: PipelineNodeConfig(
        label: 'Condition',
        extras: {
          'switchKey': 'category',
          'cases': ['a', 'b'],
          'default': 'a',
        },
      ),
    ),
    NodeType(
      id: 'condition.fileExists',
      displayName: 'If file exists (router)',
      description:
          'Routes "true" when a file/dir exists under the clone (repoLocalPath), '
          'else "false" — e.g. gate the Rust audit on Cargo.toml. Wire the '
          '"true" edge to the work to run only when present.',
      defaultKind: StepKind.router,
      defaultBodyKey: BuiltInBodyKeys.condition,
      defaultConfig: PipelineNodeConfig(
        label: 'If file exists',
        extras: {
          'predicate': {
            'type': 'fileExists',
            'paths': ['Cargo.toml'],
            'baseKey': 'repoLocalPath',
          },
        },
      ),
    ),
    NodeType(
      id: 'condition.anyOf',
      displayName: 'Any file exists (OR router)',
      description:
          'Routes "true" when ANY of the listed files exists — e.g. a Node repo '
          'detected via package.json OR yarn.lock OR pnpm-lock.yaml. One path '
          'per line in the config.',
      defaultKind: StepKind.router,
      defaultBodyKey: BuiltInBodyKeys.condition,
      defaultConfig: PipelineNodeConfig(
        label: 'Any file exists',
        extras: {
          'predicate': {
            'type': 'fileExists',
            'paths': ['package.json', 'yarn.lock', 'pnpm-lock.yaml'],
            'baseKey': 'repoLocalPath',
          },
        },
      ),
    ),
    NodeType(
      id: 'condition.allOf',
      displayName: 'All conditions (AND router)',
      description:
          'Routes "true" only when EVERY listed file exists — e.g. a TypeScript '
          'project needs both package.json AND tsconfig.json. One path per line.',
      defaultKind: StepKind.router,
      defaultBodyKey: BuiltInBodyKeys.condition,
      defaultConfig: PipelineNodeConfig(
        label: 'All conditions',
        extras: {
          'predicate': {
            'type': 'and',
            'of': [
              {
                'type': 'fileExists',
                'paths': ['package.json'],
                'baseKey': 'repoLocalPath',
              },
              {
                'type': 'fileExists',
                'paths': ['tsconfig.json'],
                'baseKey': 'repoLocalPath',
              },
            ],
          },
        },
      ),
    ),
    NodeType(
      id: 'team.dispatch',
      displayName: 'Team dispatch',
      description:
          'Dispatches a whole team — one task per member in parallel, or via '
          'a leader who delegates. Suspends until the team finishes. Set a '
          "reducer of 'append' on the output to collect each member's result.",
      defaultKind: StepKind.listen,
      defaultBodyKey: BuiltInBodyKeys.teamDispatch,
      defaultConfig: PipelineNodeConfig(
        label: 'Team dispatch',
        dispatchMode: 'allParallel',
        outputKey: 'team_findings',
        reducer: 'append',
        prompt: 'Review the work and report your findings.',
      ),
    ),
    NodeType(
      id: 'human.gate',
      displayName: 'Approval gate',
      description:
          'Pauses the pipeline for human / lead approval. The approver calls '
          'approve_step or reject_step; pair with a router to branch on the '
          'decision.',
      defaultKind: StepKind.listen,
      defaultBodyKey: BuiltInBodyKeys.humanGate,
      defaultConfig: PipelineNodeConfig(
        label: 'Approval gate',
        outputKey: 'approvalDecision',
        prompt: 'Review the findings and approve or reject before proceeding.',
      ),
    ),
    NodeType(
      id: 'flow.forEach',
      displayName: 'For each (map)',
      description:
          'Runs an agent task once per item in a state collection, in '
          'parallel, then aggregates the results into a list. Set '
          "extras.iterableKey and a reducer of 'append'.",
      defaultKind: StepKind.forEach,
      defaultBodyKey: BuiltInBodyKeys.forEach,
      defaultConfig: PipelineNodeConfig(
        label: 'For each',
        outputKey: 'items_results',
        reducer: 'append',
        extras: {'iterableKey': 'items', 'itemKey': 'item'},
        prompt: 'Process this item: {{item}}',
      ),
    ),
    NodeType(
      id: 'flow.callPipeline',
      displayName: 'Call sub-pipeline',
      description:
          'Runs another pipeline template as a nested step and merges its '
          'final state back under the output key. Set extras.templateId.',
      defaultKind: StepKind.listen,
      defaultBodyKey: BuiltInBodyKeys.callFlow,
      defaultConfig: PipelineNodeConfig(
        label: 'Call sub-pipeline',
        outputKey: 'subflow_result',
        extras: {'templateId': ''},
      ),
    ),
  ]);
}
