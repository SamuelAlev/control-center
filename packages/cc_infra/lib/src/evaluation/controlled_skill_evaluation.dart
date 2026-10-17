import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/evaluation/backends/builtin_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/controlled_claude_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/controlled_claude_mcp_bridge.dart';
import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';
import 'package:cc_infra/src/evaluation/controlled_file_tools.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifacts.dart';
import 'package:cc_infra/src/evaluation/evaluation_engine.dart';
import 'package:cc_infra/src/evaluation/evaluation_verifier_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Exact, scanned package bytes supplied by the server admission boundary.
/// Its digest uses SkillBundleService's path:sha256(bytes) rollup convention.
class SkillPackageSnapshot {
  /// Freezes package bytes and rejects unsafe paths or a mismatched digest.
  SkillPackageSnapshot({
    required this.slug,
    required this.packageHash,
    required Map<String, List<int>> files,
    required this.origin,
    this.repoId,
    this.sourceCommit,
    this.scanRulesVersion,
  }) : files = UnmodifiableMapView({
         for (final entry in files.entries)
           entry.key: List<int>.unmodifiable(entry.value),
       }) {
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(slug) ||
        !this.files.containsKey('SKILL.md') ||
        this.files.isEmpty ||
        this.files.keys.any((key) => !safeRelativePath(key)) ||
        packageHash != computeHash(this.files)) {
      throw ArgumentError('unsafe or mismatched full skill package: $slug');
    }
  }

  /// Installation name used beneath the isolated skill directory.
  final String slug;

  /// Digest of all relative paths and file contents.
  final String packageHash;

  /// Immutable package-relative file bytes, including `SKILL.md`.
  final Map<String, List<int>> files;

  /// Provenance scope, such as a workspace or linked repository.
  final String origin;

  /// Owning repository for repository-scoped packages.
  final String? repoId;

  /// Source commit recorded at capture, when available.
  final String? sourceCommit;

  /// Scanner rules that admitted these exact bytes.
  final String? scanRulesVersion;

  /// Whether a normalized relative path avoids reserved or escaping segments.
  static bool safeRelativePath(String key) {
    if (key.isEmpty ||
        key.contains('\\') ||
        key.contains('\u0000') ||
        key == 'skills-lock.json' ||
        p.posix.isAbsolute(key) ||
        key != p.posix.normalize(key)) {
      return false;
    }
    return !p.posix
        .split(key)
        .any(
          (segment) =>
              segment == '..' ||
              segment == '.' ||
              segment.isEmpty ||
              segment == '.git' ||
              segment == '.agents',
        );
  }

  /// Computes the canonical sorted path/content rollup used by skill bundles.
  static String computeHash(Map<String, List<int>> files) {
    final paths = files.keys.where((key) => key != 'skills-lock.json').toList()
      ..sort();
    final rollup = paths
        .map((key) => '$key:${sha256.convert(files[key]!)}')
        .join('\n');
    return sha256.convert(utf8.encode(rollup)).toString();
  }
}

/// The deliberate intervention between baseline and candidate attempts.
enum SkillComparison {
  /// Compare no target skill against normal metadata-driven availability.
  absent,

  /// Compare the admitted previous revision against the candidate revision.
  previous,

  /// Inject the full candidate body as a diagnostic, bypassing normal routing.
  forced,

  /// Compare a pinned ambient inventory with and without the target skill.
  composition,
}

/// Enforces one budget and one immutable inventory across the paired engine's
/// counterbalanced, independently checked attempts. No replay/CLI fallback.
class ControlledSkillEvaluation {
  /// Configures an admitted, server-owned paired campaign without starting it.
  ControlledSkillEvaluation({
    required this.workspaceId,
    required this.campaignId,
    required this.corpus,
    required this.candidate,
    this.skillKey,
    this.configurationHash,
    this.previous,
    this.ambient = const [],
    required this.comparison,
    required this.providerId,
    required this.modelId,
    this.credential,
    this.priceLookup,
    this.maxCallMicros,
    this.budgetEnforcement = 'reserved_call',
    required this.budgetMicros,
    required this.repetitions,
    required this.outDir,
    required this.cancellation,
    required this.onAttempt,
    this.factory = const HarnessProviderFactory(),
    this.commandGuard,
    this.adapter = 'builtin',
    this.claudeExecutable,
    this.claudeConfigDir,
    this.claudeCapabilities = ClaudeCliCapabilities.baseline,
  });

  /// Explicit owning workspace; never inferred from a current selection.
  final String workspaceId;

  /// Persisted campaign identity used for scheduling and artifacts.
  final String campaignId;

  /// Versioned tasks and independent verifier definitions.
  final EvaluationCorpus corpus;

  /// The exact candidate package admitted by the server.
  final SkillPackageSnapshot candidate;

  /// Server-derived catalog identity, including repo-relative path.
  final String? skillKey;

  /// Server pin covering model pricing, corpus, comparison and execution policy.
  final String? configurationHash;

  /// Independently admitted historical package for a revision comparison.
  final SkillPackageSnapshot? previous;

  /// Immutable background skills shared by both arms.
  final List<SkillPackageSnapshot> ambient;

  /// Which exposure or revision difference the paired experiment measures.
  final SkillComparison comparison;

  /// Provider owning the native [modelId] and [credential].
  final String providerId;

  /// Native catalog identifier; it may contain a vendor namespace and slashes.
  /// The harness provider qualifier is added exactly once at its boundary.
  final String modelId;

  /// Only builtin uses a provider credential; native Claude owns its account.
  final ProviderCredential? credential;

  /// Prices physical calls; an unknown result stops further campaign spend.
  final ProviderCallCost? Function(ProviderCallRecord)? priceLookup;

  /// Server-derived worst-case reservation for one physical provider call.
  /// Null for a subscription's post-call usage stopping threshold.
  final int? maxCallMicros;

  /// Pinned budget semantics for the builtin adapter. Only Codex OAuth may
  /// use stop_after_call; the server validates credential kind before launch.
  final String budgetEnforcement;

  /// Maximum campaign expenditure or post-call usage threshold in micro-USD.
  final int budgetMicros;

  /// Fresh attempts per task and arm, clustered by task in the report.
  final int repetitions;

  /// Server-owned artifact directory outside the candidate's authority.
  final String outDir;

  /// Stops active guest execution and prevents subsequent attempts.
  final CancellationToken cancellation;

  /// Persists each attempt outcome before proceeding to the next one.
  final Future<void> Function(EvaluationAttempt) onAttempt;

  /// Shared provider-construction seam for admission and execution.
  final HarnessProviderFactory factory;

  /// Production server supplies the attributed ActionGuardService decision.
  final Future<String?> Function(String command)? commandGuard;

  /// Explicit adapter. No automatic fallback between builtin and Claude Code.
  final String adapter;

  /// Absolute path to the server-managed native Claude executable.
  final String? claudeExecutable;

  /// Server-owned account directory for native Claude execution.
  final String? claudeConfigDir;

  /// Verified native Claude CLI features used to select compatible flags.
  final ClaudeCliCapabilities claudeCapabilities;

  bool get _strictReservation =>
      adapter == 'builtin' && budgetEnforcement == 'reserved_call';

  /// Probes local CLI capabilities without making any paid model request.
  static Future<String?> claudeCapabilityReason({
    required String executable,
    required String configDir,
  }) => ControlledClaudeEvaluationBackend.capabilityReason(
    executable: executable,
    configDir: configDir,
  );

  /// Preflight MUST finish before a campaign is admitted as paid. It runs
  /// real denied host-file and egress probes, not an executable-presence check.
  Future<String?> capabilityReason() async {
    final reason = ControlledEvaluationProcess.capabilityReason();
    if (reason != null) {
      return reason;
    }
    if (workspaceId.isEmpty ||
        campaignId.isEmpty ||
        corpus.tasks.isEmpty ||
        !corpus.idsAreUnique ||
        providerId.isEmpty ||
        modelId.isEmpty ||
        budgetMicros <= 0 ||
        repetitions < 1 ||
        (adapter != 'builtin' && adapter != 'claude-cli')) {
      return 'invalid campaign identity, corpus, budget, or provider/model';
    }
    if (adapter == 'claude-cli') {
      if ((providerId != 'anthropic' && providerId != 'claude-code') ||
          claudeExecutable == null ||
          claudeConfigDir == null) {
        return 'controlled Claude needs a Claude model and server-owned account';
      }
      final nativeReason = await claudeCapabilityReason(
        executable: claudeExecutable!,
        configDir: claudeConfigDir!,
      );
      if (nativeReason != null) {
        return nativeReason;
      }
    } else if ((budgetEnforcement != 'reserved_call' &&
            budgetEnforcement != 'stop_after_call') ||
        (budgetEnforcement == 'reserved_call' &&
            (maxCallMicros == null ||
                maxCallMicros! <= 0 ||
                maxCallMicros! > budgetMicros)) ||
        (budgetEnforcement == 'stop_after_call' &&
            (providerId != 'codex' ||
                credential?.method != HarnessAuthMethod.oauth ||
                maxCallMicros != null)) ||
        credential == null ||
        priceLookup == null) {
      return 'builtin evaluation needs verified credential, pricing and budget enforcement';
    }
    if (comparison == SkillComparison.previous && previous == null) {
      return 'previous comparison needs an admitted previous snapshot';
    }
    if (ambient.any((s) => s.slug == candidate.slug) ||
        ambient.map((s) => s.slug).toSet().length != ambient.length) {
      return 'target and ambient inventory overlap';
    }
    if (adapter == 'builtin') {
      if (credential!.providerId != providerId) {
        return 'provider credential does not match selected provider';
      }
      try {
        final parsed = factory.parseModel('$providerId/$modelId');
        if (parsed.providerId != providerId ||
            parsed.model == null ||
            parsed.model!.trim().isEmpty) {
          return 'selected model is not pinned to the selected provider';
        }
        factory.create(
          providerId: providerId,
          model: parsed.model,
          credential: credential,
        );
      } on Object catch (error) {
        return 'selected builtin provider cannot be created: $error';
      }
      final quoted = priceLookup!(
        ProviderCallRecord(
          requestId: 'preflight',
          purpose: LlmCallPurpose.main,
          providerId: providerId,
          model: modelId,
          attempt: 1,
          outcome: ProviderCallOutcome.success,
          usage: const LlmUsage(inputTokens: 1000000, outputTokens: 1000000),
        ),
      );
      if (quoted == null ||
          quoted.micros <= 0 ||
          quoted.basis != ProviderCallCostBasis.estimated) {
        return 'trustworthy positive provider list pricing is unavailable';
      }
    }
    if ([candidate, ?previous, ...ambient].any((s) {
      try {
        utf8.decode(s.files['SKILL.md']!);
        return false;
      } on FormatException {
        return true;
      }
    })) {
      return 'skill routing metadata must be UTF-8';
    }
    if (corpus.tasks.any(
      (t) =>
          t.fixtureRef != null ||
          t.verifiers.any(
            (v) =>
                v.kind == EvaluationVerifierKind.diffApplies ||
                v.kind == EvaluationVerifierKind.noWrites ||
                ((v.kind == EvaluationVerifierKind.tests ||
                        v.kind == EvaluationVerifierKind.commandExit) &&
                    !EvaluationVerifierRunner.supportsContainedOracle(v)),
          ),
    )) {
      return 'corpus uses an unsupported fixture or executable verifier';
    }
    for (final task in corpus.tasks) {
      if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(task.id) ||
          (task.workspaceSubpath != '.' &&
              !SkillPackageSnapshot.safeRelativePath(task.workspaceSubpath)) ||
          task.inlineFiles.keys.any(
            (path) => !SkillPackageSnapshot.safeRelativePath(path),
          )) {
        return 'corpus has an unsafe task, fixture, or work directory path';
      }
    }
    return ControlledEvaluationProcess.probeCapability();
  }

  /// Rechecks admission, runs fresh paired attempts and writes bounded evidence.
  Future<EvaluationRunResult> run() async {
    final refusal = await capabilityReason();
    if (refusal != null) {
      throw UnsupportedError(refusal);
    }
    if (cancellation.isCancelled) {
      throw StateError('evaluation cancelled');
    }
    final nativeVersion = adapter == 'claude-cli'
        ? await ControlledClaudeEvaluationBackend.probeVersion(
            executable: claudeExecutable!,
            configDir: claudeConfigDir!,
          )
        : null;
    if (adapter == 'claude-cli' && nativeVersion == null) {
      throw UnsupportedError('Claude version changed or cannot be pinned');
    }
    final hashes = <String, String>{
      'candidate': candidate.packageHash,
      if (previous != null) 'previous': previous!.packageHash,
      for (final skill in ambient) 'ambient/${skill.slug}': skill.packageHash,
    };
    final toolCatalog = adapter == 'builtin'
        ? BuiltinEvaluationBackend(
            includeWebFetch: false,
            controlledFileToolsFactory: controlledFileTools,
          ).toolCatalogFingerprints()
        : ControlledClaudeMcpBridge(
            root: '.',
            cancellation: CancellationToken.none,
            visibleSkillHashes: const {},
          ).toolCatalog;
    Map<String, String> revisionMetadata(String arm, SkillPackageSnapshot s) =>
        {
          '$arm.origin': s.origin,
          if (s.repoId != null) '$arm.repoId': s.repoId!,
          if (s.sourceCommit != null) '$arm.sourceCommit': s.sourceCommit!,
          if (s.scanRulesVersion != null)
            '$arm.scanRulesVersion': s.scanRulesVersion!,
        };
    final manifest = EvaluationManifest(
      corpusId: corpus.id,
      corpusHash: corpus.corpusHash,
      adapter: adapter,
      providerId: providerId,
      modelId: modelId,
      cliVersion: nativeVersion,
      notes: adapter == 'claude-cli'
          ? 'Native Claude max-budget-usd is checked after each model call; '
                'one in-flight call may overshoot. Cost is an API-equivalent '
                'estimate, not subscription quota or billed spend.'
          : adapter == 'builtin' && !_strictReservation
          ? 'Codex OAuth uses an API-equivalent usage stopping threshold '
                'checked after every physical model call. One in-flight call '
                'may overshoot; this is not billed subscription spend.'
          : '',
      toolCatalog: toolCatalog,
      toolCatalogHash: canonicalHash(toolCatalog),
      skillKey:
          skillKey ??
          '${candidate.origin}:${candidate.repoId ?? workspaceId}:${candidate.slug}',
      skillHash: candidate.packageHash,
      baselineSkillHash: previous?.packageHash,
      ambientSkillHashes: {for (final s in ambient) s.slug: s.packageHash},
      skillComparison: comparison.name,
      skillSnapshotMetadata: {
        ...revisionMetadata('candidate', candidate),
        if (previous != null) ...revisionMetadata('previous', previous!),
        for (final skill in ambient)
          ...revisionMetadata('ambient/${skill.slug}', skill),
      },
      configHash:
          configurationHash ??
          canonicalHash({
            'protocolVersion': 'cc-skill/1',
            'adapter': adapter,
            'budgetEnforcement': adapter == 'claude-cli'
                ? 'stop_after_call'
                : budgetEnforcement,
            'workspaceId': workspaceId,
            'providerId': providerId,
            'modelId': modelId,
            'corpusHash': corpus.corpusHash,
            'comparison': comparison.name,
            'repetitions': repetitions,
            'budgetMicros': budgetMicros,
            'maxCallMicros': maxCallMicros,
            'skills': hashes,
            'tools': toolCatalog,
          }),
    );
    final baseline = EvaluationArm(
      id: 'baseline',
      axis: EvaluationAxis.baseline,
      skillExposure: comparison == SkillComparison.previous
          ? SkillExposure.available
          : SkillExposure.absent,
    );
    final treatment = EvaluationArm(
      id: 'candidate',
      axis: EvaluationAxis.skillIntervention,
      skillExposure: comparison == SkillComparison.forced
          ? SkillExposure.forced
          : SkillExposure.available,
    );
    final plan = EvaluationPlan(
      id: campaignId,
      arms: [baseline, treatment],
      strata: [
        StratumSpec(stratum: CacheStratum.cold, repetitions: repetitions),
      ],
      minPairs: 2,
    );
    var spent = 0;
    var priceUnknown = false;
    final backend = _SkillBackend(
      (request) {
        if (priceUnknown ||
            spent >= budgetMicros ||
            (_strictReservation && spent + maxCallMicros! > budgetMicros)) {
          throw StateError('campaign budget exhausted or spend unknown');
        }
        final snapshot = request.arm.id == 'baseline' ? previous : candidate;
        final exposure = request.effective.skillExposure;
        final visible = [
          ...ambient,
          if (exposure != SkillExposure.absent && snapshot != null) snapshot,
        ];
        final root = request.workspaceRoot;
        final skillRoots = visible.isEmpty
            ? <String>[]
            : [p.join(root, '.agents')];
        if (adapter == 'claude-cli') {
          return ControlledClaudeEvaluationBackend(
            executable: claudeExecutable!,
            configDir: claudeConfigDir!,
            cancellation: cancellation,
            budgetMicros: budgetMicros - spent,
            capabilities: claudeCapabilities,
            visibleSkillHashes: {
              for (final skill in visible) skill.slug: skill.packageHash,
            },
            visibleSkillFiles: {
              for (final skill in visible) skill.slug: skill.files.keys.toSet(),
            },
            commandGuard: commandGuard,
            systemPrompt: [
              BuiltinEvaluationBackend.defaultSystemPrompt,
              'The only tools permitted are the cc_controlled MCP tools. All paths refer to your isolated attempt workspace; do not infer other files or skills.',
              if (visible.isNotEmpty)
                'Available skills (metadata only; read SKILL.md and related files with tools when relevant):',
              for (final skill in visible)
                '- ${_routingDescription(skill)} (.agents/skills/${skill.slug}/SKILL.md)',
              if (exposure == SkillExposure.forced && snapshot != null)
                'The target skill is explicitly loaded for this diagnostic run. Its full instructions follow:\n${utf8.decode(snapshot.files['SKILL.md']!)}',
            ].join('\n'),
          );
        }
        return BuiltinEvaluationBackend(
          factory: factory,
          credential: credential,
          includeWebFetch: false,
          maxToolCalls: 100,
          cancel: cancellation,
          controlledFileToolsFactory: controlledFileTools,
          costLimitMicros: budgetMicros - spent,
          maxCallMicros: maxCallMicros,
          stopAfterCall: !_strictReservation,
          priceLookup: priceLookup,
          systemPrompt: [
            BuiltinEvaluationBackend.defaultSystemPrompt,
            if (visible.isNotEmpty)
              'Available skills (metadata only; read SKILL.md and related files with tools when relevant):',
            for (final skill in visible)
              '- ${_routingDescription(skill)} (.agents/skills/${skill.slug}/SKILL.md)',
            if (exposure == SkillExposure.forced && snapshot != null)
              'The target skill is explicitly loaded for this diagnostic run. Its full instructions follow:\n${utf8.decode(snapshot.files['SKILL.md']!)}',
          ].join('\n'),
          approvalCallbackFactory: (request) => (tool, arguments) async {
            if (tool.name != 'write' && tool.name != 'edit') {
              return const ToolGateDecision.allow();
            }
            final paths = <String>[
              if (arguments['path'] is String) arguments['path'] as String,
              for (final entry in arguments['edits'] as List? ?? const [])
                if (entry is Map && entry['path'] is String)
                  entry['path'] as String,
            ];
            for (final path in paths) {
              // Lexical guard only: the host must never inspect a candidate path.
              // The guest adapter enforces both lexical and resolved boundaries;
              // the OS sandbox remains the final race-safe boundary.
              final normalized = p.normalize(
                p.isAbsolute(path) ? p.relative(path, from: root) : path,
              );
              if (normalized == '..' ||
                  normalized.startsWith('../') ||
                  p.isAbsolute(normalized)) {
                return const ToolGateDecision.deny(reason: 'outside workspace');
              }
              if (normalized == '.agents' ||
                  normalized.startsWith('.agents/')) {
                return const ToolGateDecision.deny(
                  reason: 'immutable evaluation skill assets',
                );
              }
            }
            return const ToolGateDecision.allow();
          },
          commandRunnerFactory: (request) => ControlledEvaluationProcess(
            root: request.workspaceRoot,
            home: '${request.workspaceRoot}-home',
            readOnlyRoots: skillRoots,
            cancellation: cancellation,
            commandGuard: commandGuard,
          ),
          skillEventsForTool: (request, name, toolUseId, arguments, result) {
            if (result.isError) {
              return null;
            }
            if (name == 'bash' && arguments['command'] is String) {
              final command = arguments['command'] as String;
              for (final skill in visible) {
                final match = RegExp(
                  r'^\s*(?:bash|python3)\s+(?:\./)?\.agents/skills/' +
                      RegExp.escape(skill.slug) +
                      r'/([^\s;&|]+)\s*$',
                ).firstMatch(command);
                if (match == null || !skill.files.containsKey(match.group(1))) {
                  continue;
                }
                return EvaluationSkillEvent(
                  kind: 'script_execution',
                  skillHash: skill.packageHash,
                  atEpochMs: DateTime.now().millisecondsSinceEpoch,
                  origin: 'shell',
                  path: '.agents/skills/${skill.slug}/${match.group(1)}',
                  toolUseId: toolUseId,
                );
              }
              // A shell read remains unknown, never a claimed body/reference load.
              return null;
            }
            if (name != 'read' || arguments['path'] is! String) {
              return null;
            }
            final requested = arguments['path'] as String;
            // This marker is returned only after the guest read yielded content.
            // A successful out-of-range read has no body and is not a load.
            if (!result.content.startsWith('[file $requested lines=')) {
              return null;
            }
            final path = p
                .normalize(
                  p.isAbsolute(requested)
                      ? p.relative(requested, from: root)
                      : requested,
                )
                .replaceAll(p.separator, '/');
            for (final skill in visible) {
              final prefix = '.agents/skills/${skill.slug}/';
              if (!path.startsWith(prefix)) {
                continue;
              }
              final relative = path.substring(prefix.length);
              if (!skill.files.containsKey(relative)) {
                continue;
              }
              return EvaluationSkillEvent(
                kind: relative == 'SKILL.md' ? 'body_load' : 'reference_load',
                skillHash: skill.packageHash,
                atEpochMs: DateTime.now().millisecondsSinceEpoch,
                origin: 'tool_read',
                path: path,
                toolUseId: toolUseId,
              );
            }
            // Only exact, successfully observed Read results count as loads.
            return null;
          },
        );
      },
      ambient: ambient,
      targetSlug: candidate.slug,
      adapter: adapter,
    );
    return EvaluationEngine(
      config: EvaluationEngineConfig(
        corpus: corpus,
        manifest: manifest,
        plan: plan,
        backend: backend,
        outDir: outDir,
        controlled: true,
        cancellation: cancellation,
        cancelled: () =>
            cancellation.isCancelled ||
            priceUnknown ||
            spent >= budgetMicros ||
            (_strictReservation && spent + maxCallMicros! > budgetMicros),
        onAttempt: (attempt) async {
          final cost = attempt.attemptCostMicros;
          if (cost == null) {
            priceUnknown = true;
          } else {
            spent += cost;
          }
          await onAttempt(attempt);
        },
        prepareWorkspace: (request) async {
          final snapshot = request.arm.id == 'baseline' ? previous : candidate;
          final exposure = request.effective.skillExposure;
          final visible = [
            ...ambient,
            if (exposure != SkillExposure.absent && snapshot != null) snapshot,
          ];
          for (final skill in visible) {
            final dir = Directory(
              p.join(request.workspaceRoot, '.agents', 'skills', skill.slug),
            );
            for (final entry in skill.files.entries) {
              final file = File(p.join(dir.path, entry.key));
              await file.parent.create(recursive: true);
              await file.writeAsBytes(entry.value);
            }
          }
        },
        validateWorkspace: (request) async {
          final snapshot = request.arm.id == 'baseline' ? previous : candidate;
          final visible = [
            ...ambient,
            if (request.effective.skillExposure != SkillExposure.absent &&
                snapshot != null)
              snapshot,
          ];
          final mismatches = <String>[];
          for (final skill in visible) {
            final root = Directory(
              p.join(request.workspaceRoot, '.agents', 'skills', skill.slug),
            );
            final actual = <String, List<int>>{};
            try {
              await for (final entity in root.list(
                recursive: true,
                followLinks: false,
              )) {
                if (entity is Link) {
                  throw StateError('symlink in skill asset');
                }
                if (entity is File) {
                  final key = p
                      .relative(entity.path, from: root.path)
                      .replaceAll(p.separator, '/');
                  actual[key] = await entity.readAsBytes();
                }
              }
              if (actual.length != skill.files.length ||
                  SkillPackageSnapshot.computeHash(actual) !=
                      skill.packageHash) {
                mismatches.add('skill ${skill.slug}: mounted bytes changed');
              }
            } on Object {
              mismatches.add('skill ${skill.slug}: mounted bytes inaccessible');
            }
          }
          return mismatches;
        },
      ),
    ).run();
  }

  static String _routingDescription(SkillPackageSnapshot skill) {
    final metadata = HarnessSkillScanner.parseContents(
      utf8.decode(skill.files['SKILL.md']!),
      slug: skill.slug,
      path: '.agents/skills/${skill.slug}/SKILL.md',
    );
    return '${metadata.name}: ${metadata.description}';
  }
}

class _SkillBackend implements EvaluationBackendPort {
  _SkillBackend(
    this.create, {
    required this.ambient,
    required this.targetSlug,
    required this._adapter,
  });
  final EvaluationBackendPort Function(EvaluationAttemptRequest) create;
  final List<SkillPackageSnapshot> ambient;
  final String targetSlug;
  final String _adapter;
  @override
  String get id => _adapter;
  @override
  bool get callsModel => true;
  @override
  String? unsupportedReason(EvaluationEffectiveConfig effective) =>
      effective.adapter != _adapter || effective.skillExposure == null
      ? '$_adapter skill exposure is required'
      : null;
  @override
  Future<EvaluationAttempt> execute(EvaluationAttemptRequest request) async {
    final backend = create(request);
    var attempt = await backend.execute(request);
    final baseline = request.arm.id == 'baseline';
    final pinnedHash = baseline
        ? request.manifest.baselineSkillHash
        : request.manifest.skillHash;
    final visible = <EvaluationSkillEvent>[
      for (final skill in ambient)
        EvaluationSkillEvent(
          kind: 'available',
          skillHash: skill.packageHash,
          atEpochMs: attempt.startedAtEpochMs,
          origin: 'catalog',
        ),
      if (request.effective.skillExposure != SkillExposure.absent &&
          pinnedHash != null)
        EvaluationSkillEvent(
          kind: request.effective.skillExposure == SkillExposure.forced
              ? 'forced'
              : 'available',
          skillHash: pinnedHash,
          atEpochMs: attempt.startedAtEpochMs,
          origin: request.effective.skillExposure == SkillExposure.forced
              ? 'explicit'
              : 'catalog',
        ),
      if (request.effective.skillExposure == SkillExposure.forced &&
          pinnedHash != null &&
          (_adapter != 'claude-cli' ||
              (attempt.metrics.modelRoundTrips > 0 &&
                  (attempt.cost.estimatedApiMicros ?? 0) > 0)))
        EvaluationSkillEvent(
          kind: 'body_load',
          skillHash: pinnedHash,
          atEpochMs: attempt.startedAtEpochMs,
          origin: 'explicit',
          path: '.agents/skills/$targetSlug/SKILL.md',
        ),
    ];
    attempt = attempt.copyWith(
      skillEvents: [...visible, ...attempt.skillEvents],
    );
    return attempt;
  }
}
