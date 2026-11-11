import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// Registers the `code.index` step body — background tree-sitter indexing that
/// builds the code graph (symbols + edges) for code search.
///
/// Reads `repo_id` from the trigger payload and the workspace from the run
/// context, takes the checkout from that repository as [servedRepos] serves
/// it (never a path from the payload, so a run cannot index a path the server
/// refuses to serve), then delegates to [CodeIndexer]: walk
/// the repo, extract symbols/edges in worker isolates and ingest them into the
/// workspace-scoped code graph. Streams progress into the step-run row, honours
/// the UI Stop
/// button via [StepProcessRegistry] and supports dry-run. Never hard-fails
/// when the tree-sitter natives are absent — [CodeIndexer] returns a skipped
/// result and this body reports it as a normal completion.
///
/// It deliberately does NOT write memory facts; the `index_code` template's
/// downstream agent step studies the indexed graph and records architecture /
/// feature facts.
void registerIndexCodeBody(
  PipelineBodyRegistry registry, {
  required CodeIndexer codeIndexer,
  required RepoRepository servedRepos,
  required PipelineRunRepository runRepository,
  required StepProcessRegistry stepProcessRegistry,
}) {
  registry.registerBody(BuiltInBodyKeys.indexCode, (ctx) async {
    final repoId = ctx.optional<String>('repo_id');
    if (repoId == null || repoId.isEmpty) {
      return StepResult.failed('index_code: missing repo_id in trigger payload');
    }
    final String repoPath;
    try {
      final repo = await servedRepos.getById(ctx.workspaceId, repoId);
      if (repo == null) {
        return StepResult.failed('index_code: repo $repoId is not linked');
      }
      repoPath = repo.path;
    } on Object catch (e) {
      return StepResult.failed('index_code: $e');
    }

    if (ctx.dryRun) {
      return StepResult.ok(
        mutatedState: {'index_summary': '[dry-run] would index $repoPath'},
      );
    }

    var cancelled = false;
    stepProcessRegistry.register(ctx.stepRunId, () => cancelled = true);

    Future<void> snapshot(CodeIndexProgress p) async {
      try {
        await runRepository.updateStepRun(
          ctx.workspaceId,
          ctx.stepRunId,
          outputJson: jsonEncode({'stepId': ctx.stepId, ...p.toJson()}),
        );
      } on Object catch (e, st) {
        CcDomainLog.error('index_code: progress snapshot failed', e, st);
      }
    }

    try {
      final result = await codeIndexer.indexRepo(
        workspaceId: ctx.workspaceId,
        repoId: repoId,
        repoPath: repoPath,
        onProgress: snapshot,
        isCancelled: () => cancelled,
      );
      CcDomainLog.info('index_code: indexed $repoPath: ${result.toJson()}');
      return StepResult.ok(mutatedState: {'index_summary': result.toJson()});
    } on Object catch (e, st) {
      CcDomainLog.error('index_code: indexing failed for $repoPath', e, st);
      return StepResult.failed('index_code: $e');
    } finally {
      stepProcessRegistry.unregister(ctx.stepRunId);
    }
  });
}
