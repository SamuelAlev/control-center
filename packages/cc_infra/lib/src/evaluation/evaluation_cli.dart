import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart'
    show CodeRunnerUnavailable;
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_report_renderer.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/provider.dart'
    show ProviderCallCost, ProviderCallRecord;
import 'package:cc_harness_runtime/cc_harness_runtime.dart'
    show EnvProviderCredentialStore;
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/evaluation/backends/builtin_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/backends/claude_cli_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/backends/replay_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifacts.dart';
import 'package:cc_infra/src/evaluation/evaluation_code_runner.dart';
import 'package:cc_infra/src/evaluation/evaluation_engine.dart';
import 'package:cc_infra/src/evaluation/evaluation_verifier_runner.dart';
import 'package:cc_infra/src/model_routing/file_models_dev_source.dart';
import 'package:cc_infra/src/model_routing/model_catalog_service.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:cc_natives/cc_natives.dart' show IsolatedGit;
import 'package:path/path.dart' as p;

/// The `cc_eval` command: a runnable, auditable paired-evaluation CLI.
///
/// Commands:
///   * `list`   — print the corpus and the plan's arms;
///   * `run`    — execute a live paired campaign and write the report; it
///                spends money, so it runs only under the explicit paid-run
///                policy `--max-spend-usd` (or prints its schedule with
///                `--dry-run`, which spends nothing);
///   * `replay` — deterministically re-verify a previous campaign's recorded
///                attempts with NO model calls;
///   * `verify` — run a task's behavioral verifiers against an existing
///                workspace (corpus self-check, no model involved);
///   * `report` — re-render a previous run's report from its attempts.
///
/// Options are parsed by hand on purpose: this CLI must run from any checkout
/// without a new pub dependency.
Future<int> runEvaluationCli(
  List<String> args, {
  IOSink? out,
  IOSink? err,
}) async {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    stdoutSink.writeln(_usage);
    return 0;
  }
  final options = _Options.parse(args);
  final command = options.command;
  try {
    switch (command) {
      case 'list':
        return await _list(options, stdoutSink);
      case 'verify':
        return await _verify(options, stdoutSink, stderrSink);
      case 'report':
        return await _report(options, stdoutSink, stderrSink);
      case 'run':
      case 'replay':
        return await _run(options, command == 'replay', stdoutSink, stderrSink);
      case 'help':
      default:
        stdoutSink.writeln(_usage);
        return command == 'help' ? 0 : 2;
    }
  } on StateError catch (error) {
    stderrSink.writeln('cc_eval: ${error.message}');
    return 1;
  } on Object catch (error) {
    stderrSink.writeln('cc_eval: unexpected failure: $error');
    return 1;
  }
}

const String _usage = '''
cc_eval <list|run|replay|verify|report> [options]

  --corpus <path>        corpus JSON                (default eval/corpus.json)
  --plan <path>          plan JSON                  (default eval/plans/paired-default.json)
  --out <dir>            artifact directory         (default eval-runs)
  --fixtures <dir>       base dir for task fixtures
  --backend <id>         builtin | claude-cli       (default builtin)
  --provider <id>        provider id                (default anthropic)
  --model <id>           pinned model id
  --effort <level>       pinned effort (minimal|low|medium|high|xhigh)
  --cli-version <v>      pinned external CLI version
  --task <id>            restrict to one task
  --arm <id>             restrict to one arm
  --max-attempts <n>     stop after n trials
  --seed <n>             override the plan seed
  --keep                 keep isolated workspaces for inspection
  --dry-run              print the schedule without executing it
  --offline              refuse to run live (replay/verify only)
  --replay-from <dir>    recordings dir (replay)
  --run-dir <dir>        run dir (report/verify)
  --workspace <dir>      workspace to verify against (verify)
  --claude-path <path>   claude executable
  --claude-config-dir <d> account config dir (CLAUDE_CONFIG_DIR)
  --mcp-config <path>    --mcp-config for the Claude CLI
  --permission-mode <m>  --permission-mode for the Claude CLI
  --max-attempt-cost-usd <n> API-equivalent Claude budget per trial, all turns
  --max-spend-usd <n>    the paid-run policy: required for a live run; no
                         attempt starts once the known spend reaches it, and
                         unpriced spend stops the campaign
  --turn-timeout <min>   per-turn timeout for the Claude CLI
  --idle-minutes <n>     post-idle wait override
  --pricing-cache <path> models.dev cache JSON for cost estimation
  --help
''';

Future<int> _list(_Options options, IOSink out) async {
  final corpus = await EvaluationCorpus.read(options.corpusPath);
  final plan = _readPlan(options);
  final tasks = plan.selectTasks(corpus.tasks);
  out
    ..writeln('corpus ${corpus.id} (${corpus.corpusHash})')
    ..writeln('tasks: ${tasks.length} of ${corpus.tasks.length}');
  for (final task in tasks) {
    out.writeln(
      '  ${task.id} [${task.kind.wire}] ${task.independentlyCheckable ? 'behavioral' : 'WEAK-EVIDENCE'}'
      ' · ${task.verifiers.length} verifier(s)'
      '${task.tags.isEmpty ? '' : ' · tags ${task.tags.join(',')}'}',
    );
  }
  out.writeln('plan ${plan.id} (seed ${plan.seed})');
  for (final arm in plan.arms) {
    out.writeln(
      '  arm ${arm.id} [${arm.axis.wire}]'
      '${arm.isBaseline ? ' (quality default)' : ''}'
      '${arm.label.isEmpty ? '' : ' — ${arm.label}'}',
    );
  }
  out.writeln('strata: ${plan.strata.map((s) => s.stratum.wire).join(', ')}');
  return 0;
}

Future<int> _verify(_Options options, IOSink out, IOSink err) async {
  final taskId = options.taskId;
  final workspace = options.workspace;
  if (taskId == null || workspace == null) {
    err.writeln('verify needs --task <id> and --workspace <dir>');
    return 2;
  }
  final corpus = await EvaluationCorpus.read(options.corpusPath);
  final task = corpus.taskById(taskId);
  if (task == null) {
    err.writeln('unknown task "$taskId"');
    return 2;
  }
  if (!Directory(workspace).existsSync()) {
    err.writeln('workspace "$workspace" does not exist');
    return 2;
  }
  final results = await const EvaluationVerifierRunner().run(
    verifiers: task.effectiveVerifiers(),
    workspaceRoot: workspace,
  );
  var failed = 0;
  for (final result in results) {
    final verdict = result.skippedReason != null
        ? 'SKIP'
        : (result.passed ? 'pass' : 'FAIL');
    if (!result.passed || result.skippedReason != null) {
      failed++;
    }
    out.writeln('$verdict  ${result.verifierId}: ${result.detail}');
  }
  out.writeln('${results.length - failed}/${results.length} checks passed');
  return failed == 0 ? 0 : 1;
}

Future<int> _report(_Options options, IOSink out, IOSink err) async {
  final runDir = options.runDir;
  if (runDir == null || !Directory(runDir).existsSync()) {
    err.writeln('report needs --run-dir <dir> pointing at a previous run');
    return 2;
  }
  final corpus = await EvaluationCorpus.read(p.join(runDir, 'corpus.json'));
  final plan = EvaluationPlan.fromJson(
    (jsonDecode(await File(p.join(runDir, 'plan.json')).readAsString()) as Map)
        .cast<String, dynamic>(),
  );
  final manifest = EvaluationManifest.fromJson(
    (jsonDecode(await File(p.join(runDir, 'manifest.json')).readAsString())
            as Map)
        .cast<String, dynamic>(),
  );
  final artifacts = await _openArtifacts(runDir);
  final attempts = await artifacts.readAttempts();
  final report = const EvaluationReportBuilder().build(
    manifest: manifest,
    plan: plan,
    tasks: corpus.tasks,
    attempts: attempts,
    generatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
  );
  await artifacts.writeReport(report);
  out.write(const EvaluationReportRenderer().render(report));
  return 0;
}

Future<int> _run(_Options options, bool replay, IOSink out, IOSink err) async {
  final corpus = await EvaluationCorpus.read(options.corpusPath);
  final plan = _readPlan(options);
  if (options.offline && !replay) {
    throw StateError(
      'live evaluation is disabled by --offline; use the replay subcommand',
    );
  }
  // The paid-run policy: a live run calls a model, so it starts only with an
  // explicit spend ceiling, checked before anything is resolved or spawned.
  final ceiling = replay || options.dryRun
      ? null
      : EvaluationSpendCeiling.fromFlag(
          options.getString('max-spend-usd'),
          planUsd: plan.maxSpendUsd,
        );

  // Everything the manifest pins is resolved from the REAL artifacts BEFORE the
  // campaign: the fixture's commit, the executable's version, the tool schemas
  // and the effective instructions.
  final lookups = await _catalogLookups(options.pricingCache);
  ceiling?.requirePriceForGoals(
    plan,
    priced: lookups.priced(options.provider, options.model),
    model: '${options.provider}/${options.model ?? '(unpinned)'}',
  );
  final contextWindow =
      plan.contextWindowTokens ??
      options.getInt('context-window') ??
      lookups.contextWindowFor('${options.provider}/${options.model ?? ''}');
  // The builtin harness's attempts get `repl` when CC_CODEMODE_RUNNER names
  // a runner that passes its self-test, opened once for the campaign, and
  // none otherwise, as a server without a runner.
  final codeRunner = !replay && options.backend == 'builtin'
      ? await EvaluationCodeRunner.open()
      : null;
  if (codeRunner?.availability case CodeRunnerUnavailable(:final reason)) {
    out.writeln('cc_eval: no repl in this campaign: $reason');
  }
  try {
    return await _runCampaign(
      options,
      replay,
      out,
      corpus: corpus,
      plan: plan,
      lookups: lookups,
      contextWindow: contextWindow,
      codeRunner: codeRunner,
      ceiling: ceiling,
    );
  } finally {
    await codeRunner?.dispose();
  }
}

Future<int> _runCampaign(
  _Options options,
  bool replay,
  IOSink out, {
  required EvaluationCorpus corpus,
  required EvaluationPlan plan,
  required _CatalogLookups lookups,
  required int? contextWindow,
  required EvaluationCodeRunner? codeRunner,
  required EvaluationSpendCeiling? ceiling,
}) async {
  final backend = await _buildBackend(
    options,
    replay,
    lookups: lookups,
    contextWindowTokens: contextWindow,
    codeRunner: codeRunner,
    ceiling: ceiling,
  );
  final manifest = await _buildManifest(
    options,
    corpus,
    plan,
    replay,
    lookups: lookups,
    backend: backend,
  );

  final engine = EvaluationEngine(
    config: EvaluationEngineConfig(
      corpus: corpus,
      manifest: manifest,
      plan: plan,
      backend: backend,
      outDir: options.outDir,
      fixtureDirectory: options.fixtures,
      onlyTaskId: options.taskId,
      onlyArmId: options.armId,
      maxAttempts: options.maxAttempts,
      keepWorkspaces: options.keep,
      dryRun: options.dryRun,
      onProgress: (message) => out.writeln('• $message'),
      cancelled: ceiling?.reached,
      onAttempt: ceiling?.record,
    ),
  );
  final result = await engine.run();
  out
    ..writeln()
    ..writeln('run directory: ${result.artifacts.runDir}')
    ..writeln('attempts: ${result.artifacts.attemptsPath}')
    ..writeln('report:   ${result.artifacts.reportMarkdownPath}')
    ..writeln()
    ..write(const EvaluationReportRenderer().render(result.report));
  return 0;
}

Future<EvaluationArtifacts> _openArtifacts(String runDir) async =>
    EvaluationArtifacts.forExisting(runDir);

EvaluationPlan _readPlan(_Options options) {
  final file = File(options.planPath);
  if (!file.existsSync()) {
    throw StateError('plan "${options.planPath}" does not exist');
  }
  final plan = EvaluationPlan.fromJson(
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>(),
  );
  final idle = options.idleMinutes;
  final seed = options.seed;
  if (idle == null && seed == null) {
    return plan;
  }
  return EvaluationPlan(
    id: plan.id,
    hypothesis: plan.hypothesis,
    primaryOutcome: plan.primaryOutcome,
    minTasks: plan.minTasks,
    seed: seed ?? plan.seed,
    arms: plan.arms,
    strata: [
      for (final spec in plan.strata)
        StratumSpec(
          stratum: spec.stratum,
          repetitions: spec.repetitions,
          // Only a post-idle override replaces the plan's own idle duration;
          // a seed-only override must keep the configured wait.
          idleFor: spec.stratum == CacheStratum.postIdle && idle != null
              ? Duration(minutes: idle)
              : spec.idleFor,
        ),
    ],
    randomizedOrder: plan.randomizedOrder,
    alpha: plan.alpha,
    nonInferiorityMargin: plan.nonInferiorityMargin,
    interimAtTasks: plan.interimAtTasks,
    maxCostRatio: plan.maxCostRatio,
    maxSpendUsd: plan.maxSpendUsd,
    contextWindowTokens: plan.contextWindowTokens,
    caveats: plan.caveats,
    routePolicy: plan.routePolicy,
    memoryExperiment: plan.memoryExperiment,
    overlapExperiment: plan.overlapExperiment,
    taskTags: plan.taskTags,
    notes: plan.notes,
  );
}

Future<EvaluationBackendPort> _buildBackend(
  _Options options,
  bool replay, {
  required _CatalogLookups lookups,
  required int? contextWindowTokens,
  required EvaluationSpendCeiling? ceiling,
  EvaluationCodeRunner? codeRunner,
}) async {
  if (replay) {
    final source = options.replayFrom;
    if (source == null) {
      throw StateError('replay needs --replay-from <dir>');
    }
    return ReplayEvaluationBackend(recordingsDir: source);
  }
  switch (options.backend) {
    case 'builtin':
      // Resolve the credential BEFORE building anything: the factory treats a
      // null credential as unauthenticated, so a hosted provider would silently
      // send an empty key. Failing here is the honest outcome.
      final credential = await EnvProviderCredentialStore().activeCredential(
        options.provider,
      );
      // A dry run executes no attempt, so it needs no credential.
      if (credential == null &&
          !_isLocalProvider(options.provider) &&
          !options.dryRun) {
        throw StateError(
          'no credential for provider "${options.provider}": set '
          '${(EnvProviderCredentialStore.envKeys[options.provider] ?? ['its API key env var']).join(' or ')} '
          '(secrets are never accepted as command-line flags)',
        );
      }
      return BuiltinEvaluationBackend(
        credential: credential,
        priceLookup: lookups.price,
        visionLookup: lookups.vision,
        effortCapabilityLookup: lookups.effort,
        toolOutputDir: p.join(options.outDir, 'tool-output'),
        tokenCalibration: TokenCalibration(),
        contextWindowTokens: contextWindowTokens,
        codeExecutions: codeRunner?.executions,
        ceilingRemainderMicros: ceiling?.remainingMicros,
      );
    case 'claude-cli':
      final turnTimeout = options.turnTimeoutMinutes;
      final claudePath = options.claudePath ?? 'claude';
      final capabilities = await ClaudeCliBackend.detectCapabilities(
        claudePath,
      );
      return ClaudeCliEvaluationBackend(
        claudePath: claudePath,
        capabilities: capabilities,
        permissionMode: options.getString('permission-mode'),
        mcpConfigPath: options.getString('mcp-config'),
        configDir: options.getString('claude-config-dir'),
        maxAttemptCostUsd: options.getDouble('max-attempt-cost-usd'),
        turnTimeout: turnTimeout == null
            ? const Duration(minutes: 30)
            : Duration(minutes: turnTimeout),
      );
    default:
      throw StateError(
        'unknown backend "${options.backend}" (builtin | claude-cli)',
      );
  }
}

bool _isLocalProvider(String providerId) =>
    const {'ollama', 'lmstudio', 'vllm', 'local'}.contains(providerId);

/// The model-catalog lookups a builtin arm needs: list-price cost, image
/// capability, and whether a model actually applies a reasoning effort.
///
/// All three come from the same cached models.dev document; with no cache (or
/// no network) they degrade to "unpriced", "text-only" and "no effort support",
/// which makes a snapshot or effort arm REFUSE rather than run a wire request
/// identical to its baseline.
Future<_CatalogLookups> _catalogLookups(String? explicitPath) async {
  final path = explicitPath ?? _defaultPricingCache();
  if (path == null || !File(path).existsSync()) {
    return const _CatalogLookups.empty();
  }
  final service = ModelCatalogService(
    source: FileModelsDevSource(cacheFilePath: path, allowNetwork: false),
  );
  await service.ensureLoaded();
  final catalog = service.catalogSync();
  return _CatalogLookups(
    priced: (providerId, model) =>
        model != null &&
        (catalog.modelGet(providerId, model)?.cost?.isKnown ?? false),
    price: (record) {
      final cost = catalog.modelGet(record.providerId, record.model)?.cost;
      if (cost == null || !cost.isKnown) {
        // Unpriced: return null so the run records UNKNOWN spend, never zero.
        return null;
      }
      return ProviderCallCost(
        cost.estimateMicros(
          inputTokens: record.usage.inputTokens,
          outputTokens: record.usage.outputTokens,
          cacheReadTokens: record.usage.cacheReadTokens,
          cacheWriteTokens: record.usage.cacheWriteTokens,
        ),
      );
    },
    vision: (qualifiedModel) =>
        catalog.resolve(qualifiedModel)?.supportsImageInput ?? false,
    effort: (qualifiedModel) =>
        catalog.resolve(qualifiedModel)?.thinking != null,
    contextWindow: (qualifiedModel) =>
        catalog.resolve(qualifiedModel)?.limits.context,
  );
}

/// The catalog-derived lookups, or the conservative defaults when no catalog is
/// available.
class _CatalogLookups {
  /// Creates a [_CatalogLookups].
  const _CatalogLookups({
    required this.priced,
    required this.price,
    required this.vision,
    required this.effort,
    required this.contextWindow,
  });

  /// The no-catalog defaults: unpriced, text-only, no effort support, no
  /// window — every one of which makes an experimental arm refuse rather than
  /// run an indistinguishable configuration.
  const _CatalogLookups.empty()
    : priced = _noPriced,
      price = _noPrice,
      vision = _noVision,
      effort = _noEffort,
      contextWindow = _noWindow;

  static bool _noPriced(String providerId, String? model) => false;

  static ProviderCallCost? _noPrice(ProviderCallRecord record) => null;

  static bool _noVision(String qualifiedModel) => false;

  static bool _noEffort(String qualifiedModel) => false;

  static int? _noWindow(String qualifiedModel) => null;

  /// Whether the catalog prices a provider's model (false without one).
  final bool Function(String providerId, String? model) priced;

  /// Prices a completed provider call, or null when unknown.
  final ProviderCallCost? Function(ProviderCallRecord record) price;

  /// Whether a served model can read images.
  final bool Function(String qualifiedModel) vision;

  /// Whether a served model applies a reasoning effort.
  final bool Function(String qualifiedModel) effort;

  /// The model's documented context window, when known.
  final int? Function(String qualifiedModel) contextWindow;

  /// The documented context window for a qualified model id.
  int? contextWindowFor(String qualifiedModel) => contextWindow(qualifiedModel);
}

String? _defaultPricingCache() {
  final home = Platform.environment['HOME'];
  for (final candidate in [
    if (home != null) '$home/.cc/models_dev/api.json',
    'apps/cc_server/data/models_dev/api.json',
  ]) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }
  return null;
}

/// The pinned manifest, built from OBSERVED identities wherever one exists.
Future<EvaluationManifest> _buildManifest(
  _Options options,
  EvaluationCorpus corpus,
  EvaluationPlan plan,
  bool replay, {
  required _CatalogLookups lookups,
  required EvaluationBackendPort backend,
}) async {
  final adapter = replay ? 'replay' : options.backend;
  final toolCatalog = backend is BuiltinEvaluationBackend
      ? backend.toolCatalogFingerprints()
      : const <List<String>>[];
  final systemPrompt = switch (backend) {
    BuiltinEvaluationBackend(:final systemPrompt) => systemPrompt,
    ClaudeCliEvaluationBackend(:final systemPrompt) => systemPrompt,
    _ => BuiltinEvaluationBackend.defaultSystemPrompt,
  };
  final fixtureRef = options.fixtures;
  final fixtureHead = fixtureRef == null ? null : await _gitHead(fixtureRef);
  final cliVersion =
      options.cliVersion ??
      (adapter == 'claude-cli' ? await _cliVersion(options) : null);
  return EvaluationManifest(
    corpusId: corpus.id,
    corpusHash: corpus.corpusHash,
    adapter: adapter,
    providerId: options.provider,
    modelId: options.model ?? '',
    effortLevel: options.effort,
    repoRef: fixtureRef,
    baseCommit: fixtureHead ?? options.getString('base-commit'),
    repoWorktreeSha: fixtureHead,
    cliVersion: cliVersion,
    cliPath: adapter == 'claude-cli' ? options.claudePath : null,
    toolCatalog: toolCatalog,
    toolCatalogHash: canonicalHash(toolCatalog),
    instructionsHash: canonicalHash(systemPrompt),
    systemPromptHash: canonicalHash(systemPrompt),
    configHash: canonicalHash({
      'permissionMode': options.getString('permission-mode'),
      'claudeConfigDir': options.getString('claude-config-dir'),
      'maxAttemptCostUsd': options.getDouble('max-attempt-cost-usd'),
      'turnTimeoutMinutes': options.turnTimeoutMinutes,
      if (options.getString('mcp-config') case final path?)
        'mcpConfigHash': canonicalHash(await File(path).readAsString()),
    }),
    harnessVersion: options.getString('harness-version') ?? '',
    temperature: options.getDouble('temperature'),
    notes:
        'cc_eval $adapter; context window ${plan.contextWindowTokens ?? lookups.contextWindowFor('${options.provider}/${options.model ?? ''}') ?? 'unknown'}',
  );
}

Future<String?> _gitHead(String repository) async {
  try {
    final result = await IsolatedGit.run([
      '-C',
      repository,
      'rev-parse',
      'HEAD',
    ]);
    if (result.exitCode != 0) {
      return null;
    }
    final head = '${result.stdout}'.trim();
    return head.isEmpty ? null : head;
  } on ProcessException {
    return null;
  }
}

Future<String?> _cliVersion(_Options options) async {
  try {
    final result = await ChildProcess.run(options.claudePath ?? 'claude', [
      '--version',
    ], toolchain: true);
    if (result.exitCode != 0) {
      return null;
    }
    final version = '${result.stdout}'.trim();
    return version.isEmpty ? null : version;
  } on ProcessException {
    return null;
  }
}

/// The paid-run policy of a live campaign: its spend ceiling in micro-USD.
///
/// Checked between attempts, so the attempt in flight may pass it; an attempt
/// whose spend could not be priced stops the campaign, because unknown spend
/// cannot be held under a ceiling.
class EvaluationSpendCeiling {
  /// Creates an [EvaluationSpendCeiling] of [micros].
  EvaluationSpendCeiling(this.micros);

  /// Parses `--max-spend-usd`, refusing a live run without a positive value.
  /// A plan's own `maxSpendUsd` (its owner's ceiling) lowers it, never
  /// raises it.
  factory EvaluationSpendCeiling.fromFlag(
    String? raw, {
    required double? planUsd,
  }) {
    final usd = raw == null ? null : double.tryParse(raw);
    if (usd == null || !usd.isFinite || usd <= 0) {
      throw StateError(
        'a live campaign spends money and needs the paid-run policy: pass '
        '--max-spend-usd <n> (the campaign ceiling), or --dry-run to print '
        'the schedule without spending',
      );
    }
    final held = planUsd != null && planUsd < usd ? planUsd : usd;
    return EvaluationSpendCeiling((held * 1000000).round());
  }

  /// The ceiling in micro-USD.
  final int micros;
  int _spent = 0;
  bool _unpriced = false;

  /// Whether no further attempt may start.
  bool reached() => _unpriced || _spent >= micros;

  /// What is left of the ceiling: a goal attempt's cost limit.
  int remainingMicros() => _spent >= micros ? 0 : micros - _spent;

  /// Refuses a live campaign with a goal arm whose [model] the pricing cache
  /// does not price. A goal attempt runs several loops (segments and
  /// reviews), and unpriced spend cannot be held under the ceiling: without
  /// a price it would be bounded only by turns.
  void requirePriceForGoals(
    EvaluationPlan plan, {
    required bool priced,
    required String model,
  }) {
    if (priced || !plan.arms.any((arm) => arm.goalVerification != null)) {
      return;
    }
    throw StateError(
      'a live goal-verification campaign needs a price for its model, and '
      'the pricing cache (--pricing-cache) has none for $model: its spend '
      'could not be held under --max-spend-usd; nothing was spent',
    );
  }

  /// Adds a finished attempt's spend.
  Future<void> record(EvaluationAttempt attempt) async {
    final spent = attempt.cost.allAttemptMicros;
    if (spent == null) {
      _unpriced = true;
    } else {
      _spent += spent;
    }
  }
}

/// A tiny, dependency-free flag parser.
class _Options {
  _Options(this.command, this._values, this._flags);

  final String command;
  final Map<String, String> _values;
  final Set<String> _flags;

  static _Options parse(List<String> args) {
    final values = <String, String>{};
    final flags = <String>{};
    var command = 'run';
    var index = 0;
    if (args.isNotEmpty && !args.first.startsWith('-')) {
      command = args.first;
      index = 1;
    }
    while (index < args.length) {
      final token = args[index];
      if (!token.startsWith('--')) {
        index++;
        continue;
      }
      final key = token.substring(2);
      final next = index + 1 < args.length ? args[index + 1] : null;
      if (next != null && !next.startsWith('--')) {
        values[key] = next;
        index += 2;
      } else {
        flags.add(key);
        index++;
      }
    }
    return _Options(command, values, flags);
  }

  String? getString(String key) => _values[key];

  double? getDouble(String key) {
    final raw = _values[key];
    return raw == null ? null : double.tryParse(raw);
  }

  int? getInt(String key) {
    final raw = _values[key];
    return raw == null ? null : int.tryParse(raw);
  }

  bool has(String key) => _flags.contains(key);

  String get corpusPath => _values['corpus'] ?? 'eval/corpus.json';

  String get planPath => _values['plan'] ?? 'eval/plans/paired-default.json';

  String get outDir => _values['out'] ?? 'eval-runs';

  String get backend => _values['backend'] ?? 'builtin';

  String get provider => _values['provider'] ?? 'anthropic';

  String? get model => _values['model'];

  String? get effort => _values['effort'];

  String? get cliVersion => _values['cli-version'];

  String? get fixtures => _values['fixtures'];

  String? get taskId => _values['task'];

  String? get armId => _values['arm'];

  int? get maxAttempts => getInt('max-attempts');

  int? get seed => getInt('seed');

  bool get keep => has('keep');

  bool get dryRun => has('dry-run');

  bool get offline => has('offline');

  String? get replayFrom => _values['replay-from'];

  String? get runDir => _values['run-dir'];

  String? get workspace => _values['workspace'];

  String? get claudePath => _values['claude-path'];

  String? get pricingCache => _values['pricing-cache'];

  int? get idleMinutes => getInt('idle-minutes');

  int? get turnTimeoutMinutes => getInt('turn-timeout');
}
