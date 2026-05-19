import 'dart:convert';

import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live progress of the `index` step for a pipeline run id, parsed from the
/// step's streamed `outputJson`. Defaults to zeros until the first snapshot.
final repoIndexProgressProvider =
    StreamProvider.family<({int done, int total, int symbols}), String>((
      ref,
      runId,
    ) {
      return ref
          .watch(pipelineRunRepositoryProvider)
          .watchStepRunsForPipeline(runId)
          .map((steps) {
            for (final step in steps) {
              final output = step.outputJson;
              if (step.stepId == 'index' && output != null) {
                try {
                  final json = jsonDecode(output) as Map<String, dynamic>;
                  final done = json['filesIndexed'];
                  final total = json['totalFiles'];
                  final symbols = json['symbols'];
                  return (
                    done: done is int ? done : 0,
                    total: total is int ? total : 0,
                    symbols: symbols is int ? symbols : 0,
                  );
                } catch (_) {
                  // Ignore partially-written snapshots.
                }
              }
            }
            return (done: 0, total: 0, symbols: 0);
          });
    });
