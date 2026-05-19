import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:uuid/uuid.dart';

/// MCP tool that adds a structured review node (finding) to a review space.
///
/// Posts a `Message` with `messageType: 'review_node'` and structured
/// metadata containing node type, file path, line number, P0–P3 priority,
/// reviewer confidence and confirmation tracking.
class AddReviewNodeTool extends McpTool {
  /// Creates a new [AddReviewNodeTool].
  ///
  /// [runLogs] resolves which conversation the finding is filed into — see
  /// [run]. Null keeps the pre-thread behavior (the space's standing
  /// conversation), which is what the tool did before reviewers had streams of
  /// their own.
  AddReviewNodeTool({
    required MessagingRepository repository,
    AgentRunLogRepository? runLogs,
  }) : _repository = repository,
       _runLogs = runLogs;

  final MessagingRepository _repository;
  final AgentRunLogRepository? _runLogs;

  @override
  String get name => 'add_review_node';

  @override
  String get description =>
      'Adds a structured review finding to a review space. The finding '
      'appears as a review node in the space with metadata for file path, '
      'line number, P0–P3 priority, reviewer confidence (0..1) and '
      'confirmation tracking. Classify it on the three triage axes — '
      'category, severity and effort. The body is a bold imperative '
      'one-sentence title followed by AT MOST THREE SENTENCES (what the code '
      'does, what goes wrong, the fix); bodies over 900 characters of prose '
      'are rejected. Put patches in `fix_diff`, not in the body.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the review space belongs to.',
      },
      'space_id': {'type': 'string', 'description': 'The review space ID.'},
      'sender_id': {
        'type': 'string',
        'description': 'The agent ID adding this finding.',
      },
      'node_type': {
        'type': 'string',
        'description':
            'Type of finding: bug, suggestion, recommendation, question, or ticket.',
        'enum': ['bug', 'suggestion', 'recommendation', 'question', 'ticket'],
      },
      // Ordered BEFORE `content` deliberately: a model fills a JSON object in
      // the order the schema presents it, so putting the analysis first makes
      // the finding conditioned on it rather than rationalized after it.
      'reasoning': {
        'type': 'string',
        'description':
            'Your analysis, written BEFORE the finding: what the code does, '
            'what you checked, and why you concluded there is a defect. Never '
            'shown to a human — it exists so the finding follows from the '
            'analysis, and so a wrong finding can be traced later.',
      },
      'content': {
        'type': 'string',
        'description':
            'The finding (markdown). A bold imperative one-sentence title, '
            'then at most three sentences. Rejected over 900 characters of '
            'prose — evidence and patches belong in `fix_diff`, not here.',
      },
      'priority': {
        'type': 'string',
        'description':
            'Action-ordering priority. p0=blocks release, p1=fix next cycle, '
            'p2=fix eventually, p3=nice-to-have.',
        'enum': ['p0', 'p1', 'p2', 'p3'],
      },
      'confidence': {
        'type': 'number',
        'description':
            'Your honest self-assessed confidence in this finding, in '
            '[0.0, 1.0]. This is GATED: below the workspace review level\'s '
            'floor the finding is grouped away from the main report rather '
            'than shown, so an inflated score buys nothing and a careful one '
            'is what keeps the review worth reading. Critical and major '
            'findings are always reported whatever their confidence.',
        'minimum': 0,
        'maximum': 1,
      },
      'file_path': {
        'type': 'string',
        'description': 'Optional file path the finding refers to.',
      },
      'line_number': {
        'type': 'integer',
        'description': 'Optional starting line number.',
      },
      'line_end': {
        'type': 'integer',
        'description': 'Optional ending line number.',
      },
      'cohort_key': {
        'type': 'string',
        'description':
            'Optional semantic-cohort key (PRD 18) this finding belongs to, '
            'so it routes to the right Review Studio cohort.',
      },
      'axis': {
        'type': 'string',
        'description': 'Optional review axis that produced this finding.',
        'enum': [
          'correctness',
          'security',
          'test_gap',
          'performance',
          'visual',
          'api_contract',
        ],
      },
      'category': {
        'type': 'string',
        'description':
            'What this finding is about. Shown as the first of three triage '
            'labels on the finding.',
        'enum': [
          'security',
          'stability',
          'data_integrity',
          'correctness',
          'performance',
          'maintainability',
        ],
      },
      'severity': {
        'type': 'string',
        'description':
            'How much this finding matters. Takes precedence over "priority" '
            'when both are given: critical maps to p0, major to p1, minor to '
            'p2, trivial and info to p3. Findings below the workspace review '
            "level's threshold are grouped into a collapsed nitpick section "
            'rather than dropped.',
        'enum': ['critical', 'major', 'minor', 'trivial', 'info'],
      },
      'effort': {
        'type': 'string',
        'description':
            'Roughly what acting on this finding costs. This is the axis that '
            'lets a reader decide what to fix now.',
        'enum': ['quick_win', 'moderate', 'heavy_lift'],
      },
      'fix_suggestion': {
        'type': 'string',
        'description':
            'The exact replacement lines for the anchored range — no diff '
            'markers, no surrounding context, just the code that should be '
            'there. Rendered as a committable suggestion the author can apply '
            'in one click, so it must be correct in isolation and cover '
            'exactly the anchored lines. Omit it unless the fix is small and '
            'you are certain.',
      },
      'fix_diff': {
        'type': 'string',
        'description':
            'Optional minimal unified diff proposing the fix. Rendered as a '
            'diff block and, on publish, as a suggested change. Omit it rather '
            'than guessing — a wrong patch costs more than no patch.',
      },
      'ai_prompt': {
        'type': 'string',
        'description':
            'Optional one-paragraph instruction for handing this finding to a '
            'coding agent, naming the file and line range. A standing '
            'untrusted-input warning is prepended automatically; do not write '
            'your own.',
      },
    },
    'required': [
      'workspace_id',
      'space_id',
      'sender_id',
      'node_type',
      'content',
      'priority',
      'confidence',
    ],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String || rawWorkspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawSpaceId = arguments['space_id'];
    if (rawSpaceId is! String) {
      return CallResult.error(
        'Missing or invalid argument: space_id (expected string)',
      );
    }
    final rawSenderId = arguments['sender_id'];
    if (rawSenderId is! String) {
      return CallResult.error(
        'Missing or invalid argument: sender_id (expected string)',
      );
    }
    final rawNodeType = arguments['node_type'];
    if (rawNodeType is! String) {
      return CallResult.error(
        'Missing or invalid argument: node_type (expected string)',
      );
    }
    final rawContent = arguments['content'];
    if (rawContent is! String) {
      return CallResult.error(
        'Missing or invalid argument: content (expected string)',
      );
    }
    // Length is enforced here, not asked for in the prompt.
    //
    // A reviewer told to be brief writes at whatever length it finds
    // satisfying, and the result is inline comments several paragraphs long
    // that nobody reads in the margin of a diff. Length is one of the few
    // properties of a comment that can be checked mechanically, so it is —
    // and the error says exactly how to get under the limit rather than just
    // refusing. Fenced blocks are excluded: a short body with a patch in it
    // is fine, a wall of prose is not.
    final prose = _proseLength(rawContent);
    if (prose > _maxProseChars) {
      return CallResult.error(
        'Finding body is too long: $prose characters of prose '
        '(limit $_maxProseChars). An inline review comment is read in the '
        'margin of a diff. Keep it to a bold one-sentence title plus at most '
        'three sentences: what the code does, what goes wrong, and the fix. '
        'Move any shell output, tables, derivations or quoted diff into '
        '`fix_diff` (collapsed when rendered) or drop them. If the body covers '
        'two separate problems, file it as two findings.',
      );
    }
    final rawPriorityArg = arguments['priority'];
    // Accept any case (`P0` → `p0`); a pure-case mismatch is not worth bouncing
    // an agent turn over.
    final rawPriority = rawPriorityArg is String
        ? rawPriorityArg.toLowerCase()
        : rawPriorityArg;
    if (rawPriority is! String ||
        !const {'p0', 'p1', 'p2', 'p3'}.contains(rawPriority)) {
      return CallResult.error(
        'Missing or invalid argument: priority (expected one of p0,p1,p2,p3)',
      );
    }
    final rawConfidence = arguments['confidence'];
    if (rawConfidence is! num) {
      return CallResult.error(
        'Missing or invalid argument: confidence (expected number in [0,1])',
      );
    }
    final confidence = rawConfidence.toDouble();
    if (confidence.isNaN || confidence < 0.0 || confidence > 1.0) {
      return CallResult.error(
        'Invalid argument: confidence out of range [0,1]: $confidence',
      );
    }
    // The three triage axes are optional and independently validated: an
    // unrecognized value is dropped rather than failing the call, because a
    // mislabelled finding is still a finding and bouncing the turn would lose
    // the expensive part of the work.
    final severity = ReviewFindingSeverity.fromName(
      arguments['severity'] as String?,
    );
    final category = ReviewFindingCategory.fromName(
      arguments['category'] as String?,
    );
    final effort = ReviewFindingEffort.fromName(arguments['effort'] as String?);

    final rawFilePath = arguments['file_path'];
    final rawLineNumber = arguments['line_number'];
    final rawLineEnd = arguments['line_end'];
    final spaceId = rawSpaceId;
    final senderId = rawSenderId;
    final nodeType = rawNodeType;
    final content = rawContent;
    // Severity is the finer axis and the one reviewers are briefed to set, so
    // it wins when the two disagree. Keeping them consistent here — rather
    // than letting both be stored independently — is what stops a finding
    // rendering as "critical" while the verdict counts it as a p3.
    final priority = severity?.toPriority().wireName ?? rawPriority;
    final filePath = rawFilePath is String ? rawFilePath : null;
    final lineNumber = rawLineNumber is int ? rawLineNumber : null;
    final lineEnd = rawLineEnd is int ? rawLineEnd : null;

    final messageId = const Uuid().v4();

    final metadata = <String, dynamic>{
      'nodeType': nodeType,
      'priority': priority,
      'confidence': confidence,
      'confirmedBy': <String>[],
      'status': 'open',
    };
    if (filePath != null) {
      metadata['filePath'] = filePath;
    }
    if (lineNumber != null) {
      metadata['lineNumber'] = lineNumber;
    }
    if (lineEnd != null) {
      metadata['lineEnd'] = lineEnd;
    }
    final rawCohortKey = arguments['cohort_key'];
    if (rawCohortKey is String && rawCohortKey.isNotEmpty) {
      metadata['cohortKey'] = rawCohortKey;
    }
    final rawAxis = arguments['axis'];
    if (rawAxis is String && rawAxis.isNotEmpty) {
      metadata['axis'] = rawAxis;
    }
    if (category != null) {
      metadata['category'] = category.wireName;
    }
    if (severity != null) {
      metadata['severity'] = severity.wireName;
    }
    if (effort != null) {
      metadata['effort'] = effort.wireName;
    }
    final fixDiff = _trimmedOrNull(arguments['fix_diff']);
    if (fixDiff != null) {
      metadata['fixDiff'] = fixDiff;
    }
    final aiPrompt = _trimmedOrNull(arguments['ai_prompt']);
    if (aiPrompt != null) {
      metadata['aiPrompt'] = aiPrompt;
    }
    final fixSuggestion = _trimmedOrNull(arguments['fix_suggestion']);
    if (fixSuggestion != null) {
      metadata['fixSuggestion'] = fixSuggestion;
    }
    final reasoning = _trimmedOrNull(arguments['reasoning']);
    if (reasoning != null) {
      metadata['reasoning'] = reasoning;
    }

    // File the finding in the REVIEWER'S OWN stream, not the space's standing
    // conversation.
    //
    // The standing conversation is the consolidate lane: the lead's report and
    // the artifact the PR's review tab renders. Every reviewer writing its
    // findings there buried that report under dozens of nodes, and left each
    // reviewer's own thread showing its narration with none of the findings it
    // was narrating — the operator watching the "Architect review" tab saw the
    // architect say "filed 14 findings" and no findings.
    //
    // Resolved from the run rather than taken as an argument: the agent should
    // not have to be told which thread it is in, and an argument is a thing a
    // model can get wrong. Falls back to the standing conversation when there
    // is no active run (nothing is lost — that is where these went before), and
    // every space-wide reader now gathers across conversations, so a finding is
    // found wherever it was filed.
    final conversationId = await _reviewerConversation(
      workspaceId: rawWorkspaceId,
      agentId: senderId,
    );
    await _repository.sendMessage(
      workspaceId: rawWorkspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      content: content,
      senderId: senderId,
      senderType: 'agent',
      messageType: 'review_node',
      metadata: metadata,
      id: messageId,
    );

    return CallResult.success(
      jsonEncode({
        'message_id': messageId,
        'space_id': spaceId,
        'node_type': nodeType,
        'priority': priority,
        if (severity != null) 'severity': severity.wireName,
        if (category != null) 'category': category.wireName,
        if (effort != null) 'effort': effort.wireName,
        'confidence': confidence,
        'status': 'open',
      }),
    );
  }

  /// The ceiling on a finding's prose, in characters.
  ///
  /// Deliberately well above the three-sentence target the brief asks for
  /// (~400 characters): this is a backstop against bodies that have become
  /// reports, not a style checker. Comments that tripped it in practice ran
  /// 1300-1900 characters.
  static const int _maxProseChars = 900;

  /// The body's length with fenced code blocks removed.
  ///
  /// A patch inside the body is evidence, not prose, and counting it would
  /// punish the finding that includes its own fix — the opposite of what this
  /// limit is for.
  static int _proseLength(String body) {
    final withoutFences = body.replaceAll(
      RegExp(r'^[ \t]*```.*?^[ \t]*```', multiLine: true, dotAll: true),
      '',
    );
    return withoutFences.trim().length;
  }

  /// A trimmed non-empty string, or null. A blank argument carries no more
  /// than an absent one and would render as an empty block.
  static String? _trimmedOrNull(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// The conversation the calling agent's active run is working in, or null to
  /// let the repository fall back to the space's standing conversation.
  ///
  /// Never throws: a finding is the expensive part of a review pass, and losing
  /// one because a bookkeeping lookup failed would be a far worse trade than
  /// filing it in the room's main stream.
  Future<String?> _reviewerConversation({
    required String workspaceId,
    required String agentId,
  }) async {
    final runLogs = _runLogs;
    if (runLogs == null) {
      return null;
    }
    try {
      final run = await runLogs.activeRunForAgent(workspaceId, agentId);
      // The workspace check is the same one the artifact path makes: the run
      // decides the destination, so a run from another workspace must not.
      if (run == null || run.workspaceId != workspaceId) {
        return null;
      }
      // No aliasing — a conversation id is always its own uuid, so a run that
      // recorded only a space names no conversation to write into.
      final conversationId = run.conversationId;
      return (conversationId == null || conversationId.isEmpty)
          ? null
          : conversationId;
    } on Object catch (_) {
      return null;
    }
  }
}
