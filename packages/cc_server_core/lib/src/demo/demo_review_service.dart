import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_server_core/src/demo/demo_pr_cache.dart';
import 'package:cc_server_core/src/demo/demo_world.dart';
import 'package:uuid/uuid.dart';

/// Scripted AI review for the public demo.
///
/// `review_hub.start` runs the real `pr_review` pipeline, which spawns
/// reviewer processes. This service writes the same rows the review tab
/// watches — a pipeline run, then findings and a report — from a fixed
/// script. Nothing here calls a model, a forge, or a process.
///
/// The script for [kDemoReviewPrNumber] on [kDemoRepoFullName] is the one
/// with a bug worth seeing: `remaining` adds spend to the cap. Every other
/// open pull request gets a short clean pass so the button still answers.
class DemoReviewService {
  /// Creates the scripted reviewer.
  DemoReviewService({
    required this._runs,
    required this._templates,
    required this._messaging,
    required this._workProducts,
    required this._reviewSpaces,
    required this._axes,
    required this._databases,
    this._stepInterval = const Duration(seconds: 2),
  });

  final PipelineRunRepository _runs;
  final PipelineTemplateRepository _templates;
  final MessagingRepository _messaging;
  final WorkProductRepository _workProducts;
  final ReviewSpaceRepository _reviewSpaces;
  final ReviewAxisResultRepository _axes;
  final WorkspaceDatabaseManager _databases;
  final Duration _stepInterval;

  final _byRun = <String, _Session>{};
  final _activePr = <String, String>{};
  static const _uuid = Uuid();

  static const _agentId = 'demo-agent-reviewer';
  static const _templateId = 'pr_review';
  static const _bugPath = 'evalkit/budget.py';
  static const _bugNeedle = '+ self._ledger.spent';

  /// Whether [runId] is still walking its script.
  bool isRunning(String runId) => _byRun[runId]?.active ?? false;

  /// Starts a scripted review. The run row exists before this returns, with
  /// the first step already running, so the review tab can leave its
  /// "starting" state on the reply.
  ///
  /// A second start for the same pull request while the script is still
  /// walking returns `already_running`. Content is server-owned: caller
  /// arguments other than the pull request and the review level are ignored.
  Future<Map<String, dynamic>> start({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    String? level,
  }) async {
    final resolved = ReviewLevel.fromWire(level) ?? ReviewLevel.defaultLevel;
    final fullName = '$owner/$repo';
    final prKey = '$workspaceId/$fullName#$prNumber';
    final inFlight = _activePr[prKey];
    if (inFlight != null) {
      final session = _byRun[inFlight];
      return {
        'status': 'already_running',
        'space_id': session?.spaceId ?? '',
        'pr_external_id': session?.externalId ?? '',
        'pipeline_run_id': inFlight,
      };
    }

    final detail = await _pullRequest(workspaceId, fullName, prNumber);
    if (detail == null) {
      throw const NotFoundException('Pull request not found');
    }
    if (detail['state'] != 'open') {
      throw const ValidationException('This pull request is not open.');
    }

    final template = await _templates.getById(workspaceId, _templateId);
    if (template == null) {
      throw const ValidationException(
        'PR review is not available in this workspace yet.',
      );
    }

    final runId = '$workspaceId:demo-review-${_uuid.v4()}';
    final session = _Session(
      workspaceId: workspaceId,
      runId: runId,
      owner: owner,
      repo: repo,
      fullName: fullName,
      prNumber: prNumber,
      title: detail['title'] as String? ?? 'Pull request #$prNumber',
      headSha: detail['head_sha'] as String? ?? '',
      externalId: _externalId(detail, fullName, prNumber),
      level: resolved,
      template: template,
      bug: fullName == kDemoRepoFullName && prNumber == kDemoReviewPrNumber,
    );
    // Reserve before the next await so two clicks cannot both insert a run.
    _activePr[prKey] = runId;
    _byRun[runId] = session;
    try {
      await _bindSpace(session);
      session.replay = await _alreadyReviewed(session);
      session.bugLine = session.bug ? await _bugLine(session) : null;
      _plan(session);
      await _insertRun(session);
      await _opening(session);
      if (session.work.isEmpty) {
        await _completeRun(session);
      } else {
        await _begin(session, session.work.first);
        session.timer = Timer.periodic(_stepInterval, (_) {
          unawaited(
            advance(runId).catchError((Object error, StackTrace stack) {
              CcHostLog.warning('demo review tick failed: $error\n$stack');
            }),
          );
        });
      }
      return {
        'status': 'started',
        'space_id': session.spaceId,
        'pr_external_id': session.externalId,
        'pipeline_run_id': runId,
      };
    } catch (error) {
      session.timer?.cancel();
      session.active = false;
      _byRun.remove(runId);
      if (_activePr[prKey] == runId) {
        _activePr.remove(prKey);
      }
      rethrow;
    }
  }

  /// Runs the next scripted step. Tests call this directly; the timer does
  /// the same on a demo host. There is no RPC for it.
  Future<void> advance(String runId) async {
    final session = _byRun[runId];
    if (session == null) {
      return;
    }
    await _serialize(session, () async {
      if (!session.active || session.index >= session.work.length) {
        return;
      }
      try {
        await _tick(session);
      } catch (error, stack) {
        CcHostLog.warning('demo review beat failed: $error\n$stack');
        await _fail(session, '$error');
      }
    });
  }

  /// Drops in-flight scripts before a visitor workspace is deleted.
  Future<void> retireWorkspace(String workspaceId) async {
    final retired = [
      for (final session in _byRun.values)
        if (session.workspaceId == workspaceId) session,
    ];
    for (final session in retired) {
      session.timer?.cancel();
      session.active = false;
    }
    await Future.wait(retired.map((session) => session.pending));
    for (final session in retired) {
      _byRun.remove(session.runId);
      _activePr.remove(session.prKey);
    }
  }

  /// Cancels every timer. Called from tests; a process exit drops the rest.
  Future<void> dispose() async {
    for (final session in _byRun.values) {
      session.timer?.cancel();
      session.active = false;
    }
    await Future.wait(_byRun.values.map((session) => session.pending));
    _byRun.clear();
    _activePr.clear();
  }

  Future<void> _tick(_Session session) async {
    final id = session.work[session.index];
    final step = session.template.step(id);
    if (step == null) {
      session.index++;
    } else if (step.bodyKey == BuiltInBodyKeys.prReviewFinalize) {
      await _publish(session, step);
    } else if (_isReviewer(step)) {
      await _completeReviewer(session, step);
    } else {
      await _complete(
        session,
        id,
        output: {
          if (step.config.outputKey != null)
            step.config.outputKey!: session.spaceId,
          'review_space_id': session.spaceId,
        },
      );
    }
    session.index++;
    if (!session.active) {
      return;
    }
    if (session.index < session.work.length) {
      await _begin(session, session.work[session.index]);
      return;
    }
    await _completeRun(session);
  }

  Future<void> _opening(_Session session) async {
    final now = DateTime.now();
    for (final step in session.template.steps) {
      if (step.kind == StepKind.terminal) {
        continue;
      }
      final stepRunId = session.stepRunId(step.id);
      await _runs.insertStepRun(
        PipelineStepRun(
          id: stepRunId,
          pipelineRunId: session.runId,
          stepId: step.id,
          status: PipelineStepStatus.pending,
          startedAt: now,
        ),
      );
      session.stepRunIds[step.id] = stepRunId;
    }
    final trigger = session.template.steps
        .where((step) => step.kind == StepKind.trigger)
        .firstOrNull;
    if (trigger != null) {
      await _complete(session, trigger.id, output: const {'trigger': 'manual'});
    }
    for (final step in session.template.steps) {
      if (step.kind == StepKind.terminal || step.kind == StepKind.trigger) {
        continue;
      }
      final runs = _runsAt(step, session.level);
      final scheduled = session.work.contains(step.id);
      if (!runs || !scheduled) {
        await _skip(session, step);
      }
    }
  }

  void _plan(_Session session) {
    final setup = _stepWith(
      session,
      (step) => step.bodyKey == BuiltInBodyKeys.createSpace,
    );
    final consolidate = _stepWith(
      session,
      (step) => step.kind == StepKind.join,
    );
    final finalize = _stepWith(
      session,
      (step) => step.bodyKey == BuiltInBodyKeys.prReviewFinalize,
    );
    final reviewers = [
      for (final step in session.template.steps)
        if (_isReviewer(step) && _runsAt(step, session.level)) step.id,
    ];
    session.work = [
      if (setup != null) setup.id,
      ...reviewers,
      if (consolidate != null) consolidate.id,
      if (finalize != null) finalize.id,
    ];
  }

  Future<void> _completeReviewer(
    _Session session,
    PipelineStepDefinition step,
  ) async {
    final finding = _findingFor(session, step.id);
    await _complete(
      session,
      step.id,
      output: {
        if (step.config.outputKey != null)
          step.config.outputKey!: finding?.summary ?? _cleanSummary(session),
      },
    );
    if (session.replay || finding == null || finding.payload == null) {
      return;
    }
    final line = finding.anchorsBug ? session.bugLine : null;
    final payload = finding.payload!;
    await _messaging.sendMessage(
      workspaceId: session.workspaceId,
      spaceId: session.spaceId,
      content: finding.summary,
      senderId: _agentId,
      senderType: 'agent',
      messageType: 'review_node',
      metadata: payload
          .copyWith(
            anchor: ReviewNodeAnchor(
              filePath: payload.anchor.filePath,
              lineNumber: line,
            ),
          )
          .toMetadata(),
    );
  }

  Future<void> _publish(_Session session, PipelineStepDefinition step) async {
    final script = _script(session);
    if (!session.replay) {
      final productId = _uuid.v4();
      final revisionId = _uuid.v4();
      final now = DateTime.now();
      final bugLine = session.bugLine;
      final document = ArtifactDocument(
        blocks: [
          ArtifactMarkdownBlock(text: script.walkthrough),
          if (session.bug)
            ArtifactCodeBlock(
              title: _bugPath,
              language: 'python',
              lineStart: bugLine == null ? null : bugLine - 1,
              code:
                  'def remaining(self, family, run_group_id):\n'
                  '    return self._cap(family) + self._ledger.spent(family)',
            ),
        ],
      );
      await _workProducts.upsert(
        WorkProduct(
          id: productId,
          workspaceId: session.workspaceId,
          title: 'Review: PR #${session.prNumber}',
          artifactType: WorkProductType.report,
          agentId: _agentId,
          currentRevisionId: revisionId,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _workProducts.addRevision(
        WorkProductRevision(
          id: revisionId,
          workProductId: productId,
          workspaceId: session.workspaceId,
          revisionNumber: 1,
          content: document.toEnvelopeJsonString(),
          authorType: 'agent',
          authorId: _agentId,
          summary: script.headline,
          createdAt: now,
        ),
      );
      await _messaging.sendMessage(
        workspaceId: session.workspaceId,
        spaceId: session.spaceId,
        content: script.headline,
        senderId: _agentId,
        senderType: 'agent',
        messageType: 'artifact',
        metadata: {'workProductId': productId, 'revisionId': revisionId},
      );
      await _messaging.sendMessage(
        workspaceId: session.workspaceId,
        spaceId: session.spaceId,
        content: script.walkthrough,
        senderId: _agentId,
        senderType: 'agent',
        messageType: 'review_summary',
        metadata: {
          ...script.verdict.toMetadata(),
          if (session.headSha.isNotEmpty) 'summaryHeadSha': session.headSha,
          'reviewLevel': session.level.wireName,
        },
      );
      if (session.bug) {
        await _axes.upsert(
          session.workspaceId,
          session.externalId,
          const ReviewAxisResult(
            axis: ReviewAxis.correctness,
            verdict: ReviewAxisVerdict.warn,
            findingsCount: 1,
            gated: true,
            confidence: 0.96,
            note:
                'remaining() adds spend to the cap, so the balance grows as the eval spends',
          ),
        );
      }
      if (session.associationId != null) {
        await _reviewSpaces.updateStatus(
          session.workspaceId,
          session.associationId!,
          ReviewSpaceStatus.awaitingApproval,
        );
      }
    }
    await _complete(
      session,
      step.id,
      output: {
        'review_verdict': script.verdict.overall.name,
        'blocking': script.verdict.p0Count,
      },
    );
  }

  Future<void> _bindSpace(_Session session) async {
    final existing = await _reviewSpaces
        .watchByWorkspace(session.workspaceId)
        .first;
    final match = existing
        .where(
          (association) =>
              association.repoFullName == session.fullName &&
              association.prNumber == session.prNumber,
        )
        .firstOrNull;
    if (match != null) {
      session.spaceId = match.spaceId;
      session.externalId = match.prExternalId;
      session.associationId = match.id;
      await _reviewSpaces.updateStatus(
        session.workspaceId,
        match.id,
        ReviewSpaceStatus.inProgress,
      );
      return;
    }
    final space = await _messaging.createSpace(
      session.workspaceId,
      reviewSpaceName(session.prNumber, session.title),
      const [_agentId],
      repoIds: const [],
    );
    final association = await _reviewSpaces.create(
      spaceId: space.id,
      workspaceId: session.workspaceId,
      prExternalId: session.externalId,
      prNumber: session.prNumber,
      repoFullName: session.fullName,
    );
    session.spaceId = space.id;
    session.associationId = association.id;
    await _reviewSpaces.updateStatus(
      session.workspaceId,
      association.id,
      ReviewSpaceStatus.inProgress,
    );
  }

  Future<bool> _alreadyReviewed(_Session session) async {
    final messages = await _messaging.getSpaceMessages(
      session.workspaceId,
      session.spaceId,
    );
    return messages.any(
      (message) =>
          message.messageType == MessageType.reviewNode ||
          message.messageType == MessageType.artifact,
    );
  }

  Future<Map<String, dynamic>?> _pullRequest(
    String workspaceId,
    String fullName,
    int prNumber,
  ) async {
    final raw = await _databases
        .of(workspaceId)
        .cacheDao
        .read(
          workspaceId,
          DemoPrCacheKind.detail,
          demoPrCacheKey(fullName, prNumber),
        );
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  Future<int?> _bugLine(_Session session) async {
    if (session.headSha.isEmpty) {
      return null;
    }
    final raw = await _databases
        .of(session.workspaceId)
        .cacheDao
        .read(
          session.workspaceId,
          DemoPrCacheKind.fileContent,
          demoFileContentCacheKey(session.fullName, session.headSha, _bugPath),
        );
    if (raw == null) {
      return null;
    }
    final lines = raw.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains(_bugNeedle)) {
        return i + 1;
      }
    }
    return null;
  }

  Future<void> _insertRun(_Session session) async {
    final now = DateTime.now();
    final payload = <String, dynamic>{
      'workspace_id': session.workspaceId,
      'repo_owner': session.owner,
      'repo_name': session.repo,
      'repo_full_name': session.fullName,
      'pr_number': session.prNumber,
      'pr_title': session.title,
      'pr_external_id': session.externalId,
      'head_sha': session.headSha,
      'review_space_id': session.spaceId,
      kReviewLevelStateKey: session.level.wireName,
    };
    session.run = PipelineRun(
      id: session.runId,
      templateId: _templateId,
      workspaceId: session.workspaceId,
      status: PipelineRunStatus.running,
      state: payload,
      triggerEventType: 'manual',
      triggerPayload: payload,
      startedAt: now,
      lastResumedAt: now,
    );
    await _runs.insertRun(session.run!);
  }

  Future<void> _begin(_Session session, String stepId) async {
    final stepRunId = session.stepRunIds[stepId];
    if (stepRunId == null) {
      return;
    }
    await _runs.restartStepRun(
      session.workspaceId,
      stepRunId,
      startedAt: DateTime.now(),
    );
  }

  Future<void> _complete(
    _Session session,
    String stepId, {
    Map<String, dynamic>? output,
  }) async {
    final stepRunId = session.stepRunIds[stepId];
    if (stepRunId == null) {
      return;
    }
    await _runs.updateStepRun(
      session.workspaceId,
      stepRunId,
      status: PipelineStepStatus.completed,
      outputJson: output == null ? null : jsonEncode(output),
      finishedAt: DateTime.now(),
    );
  }

  Future<void> _skip(_Session session, PipelineStepDefinition step) async {
    final stepRunId = session.stepRunIds[step.id];
    if (stepRunId == null) {
      return;
    }
    final skipped = step.config.runWhen?.skippedOutput;
    await _runs.updateStepRun(
      session.workspaceId,
      stepRunId,
      status: PipelineStepStatus.skipped,
      outputJson: jsonEncode({
        'skipReason': 'Not run at review level ${session.level.wireName}.',
        if (step.config.outputKey != null && skipped != null)
          step.config.outputKey!: skipped,
      }),
      finishedAt: DateTime.now(),
    );
  }

  Future<void> _completeRun(_Session session) async {
    final run = session.run;
    if (run != null) {
      await _runs.updateRun(
        run.copyWith(
          status: PipelineRunStatus.completed,
          finishedAt: DateTime.now(),
        ),
      );
      await _runs.incrementCost(session.runId, session.bug ? 14 : 4, 12000);
    }
    await _stop(session);
  }

  Future<void> _fail(_Session session, String message) async {
    final run = session.run;
    if (run != null) {
      await _runs.updateRun(
        run.copyWith(
          status: PipelineRunStatus.failed,
          finishedAt: DateTime.now(),
          errorMessage: message,
        ),
      );
    }
    await _stop(session);
  }

  Future<void> _stop(_Session session) async {
    session.timer?.cancel();
    session.active = false;
    _byRun.remove(session.runId);
    if (_activePr[session.prKey] == session.runId) {
      _activePr.remove(session.prKey);
    }
  }

  Future<void> _serialize(_Session session, Future<void> Function() action) {
    final next = session.pending.then((_) => action());
    session.pending = next.then((_) {}, onError: (_) {});
    return next;
  }

  bool _isReviewer(PipelineStepDefinition step) =>
      step.kind == StepKind.listen &&
      step.bodyKey == BuiltInBodyKeys.promptAgent;

  bool _runsAt(PipelineStepDefinition step, ReviewLevel level) {
    final gate = step.config.runWhen;
    if (gate == null) {
      return true;
    }
    return gate.allows(level.wireName);
  }

  PipelineStepDefinition? _stepWith(
    _Session session,
    bool Function(PipelineStepDefinition step) test,
  ) => session.template.steps.where(test).firstOrNull;

  String _externalId(
    Map<String, dynamic> detail,
    String fullName,
    int prNumber,
  ) {
    final id = detail['id'];
    if (id != null && '$id'.isNotEmpty) {
      return '$id';
    }
    final external = detail['external_id'];
    if (external is String && external.isNotEmpty) {
      return external;
    }
    return '$fullName#$prNumber';
  }

  _Finding? _findingFor(_Session session, String stepId) {
    for (final finding in _findings(session)) {
      if (finding.stepId == stepId) {
        return finding;
      }
    }
    return null;
  }

  List<_Finding> _findings(_Session session) {
    if (!session.bug) {
      return [
        _Finding(
          stepId: 'engineer_review',
          summary:
              'Nothing in this diff blocks. The changed lines agree with '
              '"${session.title}".',
        ),
        const _Finding(
          stepId: 'qa_review',
          summary:
              'The tests that shipped with this change cover the path it adds.',
        ),
        const _Finding(
          stepId: 'architect_review',
          summary:
              'The change stays inside the module it names. No new boundary.',
        ),
      ];
    }
    return [
      const _Finding(
        stepId: 'engineer_review',
        anchorsBug: true,
        summary:
            '`remaining` adds tokens spent to the cap. The line it replaces '
            'subtracted from a flat pool (`250_000 - self._spent`). After this '
            'change a Haiku eval that has spent 90,000 tokens reports 170,000 '
            'remaining.',
        payload: ReviewNodePayload(
          kind: ReviewNodeKind.bug,
          priority: ReviewNodePriority.p0,
          confidence: 0.97,
          anchor: ReviewNodeAnchor(filePath: _bugPath),
          status: ReviewNodeStatus.open,
          axis: ReviewAxis.correctness,
          category: ReviewFindingCategory.correctness,
          severity: ReviewFindingSeverity.critical,
          effort: ReviewFindingEffort.quickWin,
          fixSuggestion:
              'return self._cap(family) - self._ledger.spent(family)',
        ),
      ),
      const _Finding(
        stepId: 'qa_review',
        summary:
            '`test_a_cap_never_goes_negative` records 90,000 Haiku tokens and '
            'asserts `remaining >= 0`. That passes whether spend is added or '
            'subtracted, so the suite stays green.',
        payload: ReviewNodePayload(
          kind: ReviewNodeKind.bug,
          priority: ReviewNodePriority.p1,
          confidence: 0.9,
          anchor: ReviewNodeAnchor(filePath: 'tests/evalkit/test_budget.py'),
          status: ReviewNodeStatus.open,
          axis: ReviewAxis.testGap,
          category: ReviewFindingCategory.correctness,
          severity: ReviewFindingSeverity.major,
          effort: ReviewFindingEffort.quickWin,
        ),
      ),
      const _Finding(
        stepId: 'architect_review',
        anchorsBug: true,
        summary:
            '`run_group_id` is accepted and never read, so two evals in one '
            'group still share a family total. Secondary to the sign on the return.',
        payload: ReviewNodePayload(
          kind: ReviewNodeKind.suggestion,
          priority: ReviewNodePriority.p2,
          confidence: 0.84,
          anchor: ReviewNodeAnchor(filePath: _bugPath),
          status: ReviewNodeStatus.open,
          category: ReviewFindingCategory.maintainability,
          severity: ReviewFindingSeverity.minor,
          effort: ReviewFindingEffort.moderate,
        ),
      ),
      const _Finding(
        stepId: 'security_review',
        summary:
            'No new credential surface in this diff. The sign error is not a security finding.',
      ),
      const _Finding(
        stepId: 'perf_review',
        summary:
            'The ledger lookup is once per remaining-tokens read. The sign error is not a hotter loop.',
      ),
    ];
  }

  _Script _script(_Session session) {
    final findings = [
      for (final finding in _findings(session))
        if (finding.payload != null && session.work.contains(finding.stepId))
          finding,
    ];
    final counts = {
      for (final priority in ReviewNodePriority.values) priority: 0,
    };
    for (final finding in findings) {
      final priority = finding.payload!.priority;
      counts[priority] = (counts[priority] ?? 0) + 1;
    }
    if (!session.bug) {
      return _Script(
        headline: 'No blocking findings on #${session.prNumber}.',
        walkthrough:
            '# ${session.title}\n\n'
            'Read the diff against the pull request description. The changed '
            'lines do what that description says, and nothing in them blocks '
            'a merge.',
        verdict: ReviewVerdict(
          overall: ReviewVerdictOverall.ship,
          confidence: 0.9,
          explanation:
              'No blocking findings. The diff agrees with the pull request description.',
          counts: counts,
        ),
      );
    }
    return _Script(
      headline: 'Block: remaining tokens grow as the eval spends.',
      walkthrough:
          '# Cap eval-run token budget per model family\n\n'
          'The cap table is the change this pull request describes: Sonnet '
          '200k, Haiku 80k, Opus 400k, read from one ledger. That part is fine.\n\n'
          '`remaining` adds spend to the cap. The line it replaces subtracted '
          '(`250_000 - self._spent`). A Haiku eval that has spent 90,000 tokens '
          'now reports 170,000 remaining, and `test_a_cap_never_goes_negative` '
          'only asserts the result is at least zero, so CI stays green.\n\n'
          '`run_group_id` is also unused. That is a follow-up. The sign is the block.',
      verdict: ReviewVerdict(
        overall: ReviewVerdictOverall.block,
        confidence: 0.95,
        explanation:
            'remaining() adds spend to the cap, so the balance grows as the eval spends. The new test does not catch it.',
        counts: counts,
      ),
    );
  }

  String _cleanSummary(_Session session) =>
      'No blocking findings on #${session.prNumber}.';
}

class _Finding {
  const _Finding({
    required this.stepId,
    required this.summary,
    this.payload,
    this.anchorsBug = false,
  });

  final String stepId;
  final String summary;
  final ReviewNodePayload? payload;
  final bool anchorsBug;
}

class _Script {
  const _Script({
    required this.headline,
    required this.walkthrough,
    required this.verdict,
  });

  final String headline;
  final String walkthrough;
  final ReviewVerdict verdict;
}

class _Session {
  _Session({
    required this.workspaceId,
    required this.runId,
    required this.owner,
    required this.repo,
    required this.fullName,
    required this.prNumber,
    required this.title,
    required this.headSha,
    required this.externalId,
    required this.level,
    required this.template,
    required this.bug,
  });

  final String workspaceId;
  final String runId;
  final String owner;
  final String repo;
  final String fullName;
  final int prNumber;
  final String title;
  final String headSha;
  String externalId;
  final ReviewLevel level;
  final PipelineDefinition template;
  final bool bug;

  String spaceId = '';
  String? associationId;
  bool replay = false;
  int? bugLine;
  PipelineRun? run;
  List<String> work = const [];
  int index = 0;
  final stepRunIds = <String, String>{};
  Timer? timer;
  Future<void> pending = Future<void>.value();
  bool active = true;

  String get prKey => '$workspaceId/$fullName#$prNumber';

  String stepRunId(String stepId) => '$runId:$stepId';
}
