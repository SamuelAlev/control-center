import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_mcp/src/tools/preview_trigger_tool.dart';
import 'package:test/test.dart';

void main() {
  late PreviewTriggerTool tool;

  setUp(() {
    tool = PreviewTriggerTool(
      triggerRepository: _FakeTriggers(),
      templateRepository: _FakeTemplates(),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'event_type': 'TicketAssigned'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('dry-runs an empty workspace as zero enqueues', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'event_type': 'TicketAssigned',
    });
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['will_enqueue_count'], 0);
    expect(body['runs'], isEmpty);
  });
}

class _FakeTriggers implements PipelineTriggerRepository {
  @override
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeTemplates implements PipelineTemplateRepository {
  @override
  Future<List<PipelineDefinition>> forWorkspace(String workspaceId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
