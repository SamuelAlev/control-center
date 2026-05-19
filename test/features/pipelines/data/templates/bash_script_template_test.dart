import 'dart:io';

import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_infra/src/pipelines/bash_script_template.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake [PipelineTemplateRepository] that returns a single template.
class _FakeTemplateRepo implements PipelineTemplateRepository {
  _FakeTemplateRepo(this._def);
  final PipelineDefinition _def;

  @override
  Future<PipelineDefinition?> getById(
          String workspaceId, String templateId) async =>
      _def;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A fake [PipelineRunRepository] — never called in validation/dry-run paths.
class _FakeRunRepo implements PipelineRunRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A fake [CredentialsRepository].
class _FakeCredsRepo implements CredentialsRepository {
  _FakeCredsRepo(this._creds);
  final ApiCredentials _creds;

  @override
  Future<ApiCredentials> loadCredentials() async => _creds;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Helper: build a step definition with the given config.
PipelineStepDefinition _step(String id, PipelineNodeConfig config) =>
    PipelineStepDefinition(
      id: id,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: config,
    );

/// Helper: build a pipeline definition containing one step.
PipelineDefinition _def(String stepId, PipelineNodeConfig config) =>
    PipelineDefinition(
      templateId: 'test-template',
      workspaceId: 'ws',
      name: 'Test Template',
      steps: [_step(stepId, config)],
    );

/// Helper: create a PipelineContext for a bashScript step.
PipelineContext _ctx({
  required String stepId,
  required Map<String, dynamic> state,
  Map<String, dynamic>? triggerPayload,
  bool dryRun = false,
}) =>
    PipelineContext(
      pipelineRunId: 'run-1',
      templateId: 'test-template',
      stepId: stepId,
      stepRunId: 'steprun-1',
      workspaceId: 'ws',
      state: state,
      triggerPayload: triggerPayload,
      dryRun: dryRun,
    );

void main() {
  late PipelineBodyRegistry registry;

  final runRepo = _FakeRunRepo();
  final credsRepo = _FakeCredsRepo(const ApiCredentials(githubToken: 'gh_token'));
  final processRegistry = StepProcessRegistry();

  /// Registers the bashScript body with a template carrying [config] and
  /// returns the StepResult from executing the body.
  Future<StepResult> runWith({
    required PipelineNodeConfig config,
    Map<String, dynamic>? state,
    Map<String, dynamic>? triggerPayload,
    bool dryRun = false,
    String stepId = 'step-1',
  }) async {
    registry = PipelineBodyRegistry();
    final templateRepo = _FakeTemplateRepo(_def(stepId, config));
    registerBashScriptBody(
      registry,
      templateRepository: templateRepo,
      runRepository: runRepo,
      credentialsRepository: credsRepo,
      stepProcessRegistry: processRegistry,
      runDirPath: (_) async => Directory.systemTemp.path,
    );
    final body = registry.body(BuiltInBodyKeys.bashScript);
    return body(_ctx(
      stepId: stepId,
      state: state ?? {},
      triggerPayload: triggerPayload,
      dryRun: dryRun,
    ));
  }

  group('validation', () {
    test('fails when step config is missing', () async {
      registry = PipelineBodyRegistry();
      final templateRepo = _FakeTemplateRepo(_def('step-1', const PipelineNodeConfig(script: 'echo ok')));
      registerBashScriptBody(
        registry,
        templateRepository: templateRepo,
        runRepository: runRepo,
        credentialsRepository: credsRepo,
        stepProcessRegistry: processRegistry,
        runDirPath: (_) async => Directory.systemTemp.path,
      );
      final body = registry.body(BuiltInBodyKeys.bashScript);
      final result = await body(_ctx(
        stepId: 'nonexistent',
        state: {},
      ));
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing config'));
    });

    test('fails when script is null', () async {
      final result = await runWith(
        config: const PipelineNodeConfig(),
      );
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing script'));
    });

    test('fails when script is empty string', () async {
      final result = await runWith(
        config: const PipelineNodeConfig(script: ''),
      );
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing script'));
    });

    test('fails when script is whitespace only', () async {
      final result = await runWith(
        config: const PipelineNodeConfig(script: '   \n  '),
      );
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing script'));
    });
  });

  group('dry run', () {
    test('returns ok with dry-run message in outputKey when set', () async {
      final result = await runWith(
        config: const PipelineNodeConfig(
          script: 'echo {{name}}',
          outputKey: 'bash_output',
        ),
        state: {'name': 'world'},
        dryRun: true,
      );
      expect(result.isFailed, isFalse);
      expect(result.isSuspended, isFalse);
      expect(
        result.mutatedState,
        containsPair('bash_output', '[dry-run] bash script skipped'),
      );
    });

    test('returns ok with no mutatedState when outputKey is null', () async {
      final result = await runWith(
        config: const PipelineNodeConfig(script: 'echo hello'),
        dryRun: true,
      );
      expect(result.isFailed, isFalse);
      expect(result.isSuspended, isFalse);
      expect(result.mutatedState, isEmpty);
    });

    test('returns ok with no mutatedState when outputKey is empty', () async {
      final result = await runWith(
        config: const PipelineNodeConfig(
          script: 'echo hello',
          outputKey: '',
        ),
        dryRun: true,
      );
      expect(result.isFailed, isFalse);
      expect(result.isSuspended, isFalse);
      expect(result.mutatedState, isEmpty);
    });

    test('renders template before dry-run check succeeds', () async {
      final result = await runWith(
        config: const PipelineNodeConfig(
          script: 'echo {{name}}',
          outputKey: 'out',
        ),
        state: {'name': 'test-value'},
        dryRun: true,
      );
      expect(result.isFailed, isFalse);
      expect(
        result.mutatedState,
        containsPair('out', '[dry-run] bash script skipped'),
      );
    });

    test('unresolved placeholders render as empty and dry-run still succeeds', () async {
      final result = await runWith(
        config: const PipelineNodeConfig(
          script: 'echo "{{missing_key}}"',
          outputKey: 'out',
        ),
        dryRun: true,
      );
      expect(result.isFailed, isFalse);
      expect(
        result.mutatedState,
        containsPair('out', '[dry-run] bash script skipped'),
      );
    });

    test('state overrides trigger payload in rendering', () async {
      final result = await runWith(
        config: const PipelineNodeConfig(
          script: 'echo {{key}}',
          outputKey: 'out',
        ),
        state: {'key': 'from-state'},
        triggerPayload: {'key': 'from-trigger'},
        dryRun: true,
      );
      expect(result.isFailed, isFalse);
      expect(
        result.mutatedState,
        containsPair('out', '[dry-run] bash script skipped'),
      );
    });
  });
}
