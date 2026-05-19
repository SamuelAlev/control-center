import 'dart:convert';

import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/code_graph/domain/services/code_indexer.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/step_process_registry.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// Registers the `code.index` step body — background tree-sitter indexing that
/// builds the code graph (symbols + edges) for code search.
///
/// Reads `repoId` + `repoLocalPath` from the trigger payload and the
/// `workspaceId` from the run context, then delegates to [CodeIndexer]: walk
/// the repo, extract symbols/edges in worker isolates, and ingest them into the
/// workspace-scoped code graph. Streams progress into the step-run row, honours
/// the UI Stop
/// button via [StepProcessRegistry], and supports dry-run. Never hard-fails
/// when the tree-sitter natives are absent — [CodeIndexer] returns a skipped
/// result and this body reports it as a normal completion.
///
/// It deliberately does NOT write memory facts; the `index_code` template's
/// downstream agent step studies the indexed graph and records architecture /
/// feature facts.
void registerIndexCodeBody(
  PipelineBodyRegistry registry, {
  required CodeIndexer codeIndexer,
  required PipelineRunRepository runRepository,
  required StepProcessRegistry stepProcessRegistry,
}) {
  registry.registerBody(BuiltInBodyKeys.indexCode, (ctx) async {
    final repoId = ctx.optional<String>('repoId');
    final repoPath = ctx.optional<String>('repoLocalPath');
    if (repoId == null ||
        repoId.isEmpty ||
        repoPath == null ||
        repoPath.isEmpty) {
      return StepResult.failed(
        'index_code: missing repoId/repoLocalPath in trigger payload',
      );
    }

    if (ctx.dryRun) {
      return StepResult.ok(
        mutatedState: {'indexSummary': '[dry-run] would index $repoPath'},
      );
    }

    var cancelled = false;
    stepProcessRegistry.register(ctx.stepRunId, () => cancelled = true);

    Future<void> snapshot(CodeIndexProgress p) async {
      try {
        await runRepository.updateStepRun(
          ctx.stepRunId,
          outputJson: jsonEncode({
            'stepId': ctx.stepId,
            'filesIndexed': p.filesIndexed,
            'totalFiles': p.totalFiles,
            'symbols': p.symbols,
            'edges': p.edges,
          }),
        );
      } on Object catch (e, st) {
        AppLog.e('index_code', 'progress snapshot failed', e, st);
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
      AppLog.i('index_code', 'indexed $repoPath: ${result.toJson()}');
      return StepResult.ok(mutatedState: {'indexSummary': result.toJson()});
    } on Object catch (e, st) {
      AppLog.e('index_code', 'indexing failed for $repoPath', e, st);
      return StepResult.failed('index_code: $e');
    } finally {
      stepProcessRegistry.unregister(ctx.stepRunId);
    }
  });
}
