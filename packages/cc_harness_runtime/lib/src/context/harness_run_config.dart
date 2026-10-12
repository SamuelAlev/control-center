import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:path/path.dart' as p;

/// Opt-in on-disk harness config from `.agents/harness.json` (working tree or
/// agent config dir). Absent file → defaults (stream rules, advisor, shell hooks
/// off). Also accepts `compaction` and `toolExecution` experiments; defaults
/// preserve text compaction and post-response tool execution.
class HarnessRunConfig {
  /// Creates a [HarnessRunConfig].
  const HarnessRunConfig({
    this.streamRules = const [],
    this.advisorEnabled = false,
    this.advisorModel,
    this.advisorEveryTurns = 3,
    this.advisorInstructions,
    this.compaction = CompactionConfig.defaults,
    this.snapshotCompaction = false,
    this.maxParallelToolCalls = 4,
    this.overlapReadOnlyTools = false,
    this.hookSessionStart,
    this.hookPreTool,
    this.hookPostTool,
    this.droppedHookBase,
  });

  /// Baseline configuration; experimental features are off.
  static const HarnessRunConfig none = HarnessRunConfig();

  /// Course-correction rules.
  final List<StreamRule> streamRules;

  /// Whether the secondary advisor (watchdog) is enabled.
  final bool advisorEnabled;

  /// Optional reviewer-model override (a bare id the run's provider serves,
  /// typically a cheaper/faster sibling). Null → the run's default model.
  final String? advisorModel;

  /// How often (in tool-bearing turns) the advisor is prompted. Defaults to 3.
  final int advisorEveryTurns;

  /// Optional extra instructions appended to the advisor's system prompt.
  final String? advisorInstructions;

  /// Text observation and summary policy.
  final CompactionConfig compaction;

  /// Explicit screenshot-compaction experiment. Never enabled by overflow.
  final bool snapshotCompaction;

  /// Bounded concurrency within independent tool regions.
  final int maxParallelToolCalls;

  /// Opt-in overlap of audited read-only tools with model streaming.
  final bool overlapReadOnlyTools;

  /// Absolute path to the session-start hook script, if configured.
  final String? hookSessionStart;

  /// Absolute path to the pre-tool hook script, if configured.
  final String? hookPreTool;

  /// Absolute path to the post-tool hook script, if configured.
  final String? hookPostTool;

  /// Whether any shell hook is configured.
  bool get hasHooks =>
      hookSessionStart != null || hookPreTool != null || hookPostTool != null;

  /// The base whose `.agents/harness.json` declared hooks that were REFUSED
  /// because that base is not hook-trusted (see [load]), or null.
  final String? droppedHookBase;

  /// Loads the config from the first `<base>/.agents/harness.json` found among
  /// [bases] (cwd first, then the agent config dir). Returns [none] when no
  /// file exists or it fails to parse. Hook script paths are resolved relative
  /// to the file's base.
  ///
  /// SHELL HOOKS are honored only when the winning base is in
  /// [hookTrustedBases]. Everything else in the file is DATA (patterns, a
  /// model name, instructions); hooks are arbitrary code execution, and this
  /// file is routinely read out of the agent's WORKING TREE — i.e. out of a
  /// cloned repository. Cloning a hostile repo and dispatching an agent in it
  /// must not run that repo's scripts on the host, which is exactly what the
  /// project's own fail-closed skills gate exists to prevent for skill
  /// content. A repo-declared hook is dropped and reported through
  /// [droppedHookBase] rather than silently ignored, so the operator can move
  /// it into their own agent config dir if they actually want it.
  static Future<HarnessRunConfig> load(
    List<String?> bases, {
    List<String?> hookTrustedBases = const [],
  }) async {
    final trusted = {
      for (final b in hookTrustedBases)
        if (b != null && b.isNotEmpty) p.normalize(p.absolute(b)),
    };
    for (final base in bases) {
      if (base == null || base.isEmpty) {
        continue;
      }
      final file = File(p.join(base, '.agents', 'harness.json'));
      if (!file.existsSync()) {
        continue;
      }
      try {
        final json = jsonDecode(await file.readAsString());
        if (json is! Map<String, dynamic>) {
          return none;
        }
        final parsed = _parse(json, base);
        if (trusted.contains(p.normalize(p.absolute(base)))) {
          return parsed;
        }
        return parsed.hasHooks
            ? parsed.withoutHooks(droppedHookBase: base)
            : parsed;
      } on Object {
        return none;
      }
    }
    return none;
  }

  /// This config with every shell hook removed, recording where they came
  /// from so the caller can tell the operator instead of failing silently.
  HarnessRunConfig withoutHooks({required String droppedHookBase}) =>
      HarnessRunConfig(
        streamRules: streamRules,
        advisorEnabled: advisorEnabled,
        advisorModel: advisorModel,
        advisorEveryTurns: advisorEveryTurns,
        advisorInstructions: advisorInstructions,
        compaction: compaction,
        snapshotCompaction: snapshotCompaction,
        maxParallelToolCalls: maxParallelToolCalls,
        overlapReadOnlyTools: overlapReadOnlyTools,
        droppedHookBase: droppedHookBase,
      );

  static HarnessRunConfig _parse(Map<String, dynamic> json, String base) {
    final rules = <StreamRule>[];
    final rawRules = json['streamRules'];
    if (rawRules is List) {
      for (final r in rawRules) {
        if (r is Map &&
            r['pattern'] is String &&
            r['reminder'] is String &&
            (r['pattern'] as String).isNotEmpty) {
          rules.add(
            StreamRule(
              pattern: RegExp(r['pattern'] as String),
              reminder: r['reminder'] as String,
            ),
          );
        }
      }
    }
    final advisor = json['advisor'];
    final advisorEnabled = advisor is Map && advisor['enabled'] == true;
    final advisorModelRaw = advisor is Map ? advisor['model'] : null;
    final advisorModel =
        advisorModelRaw is String && advisorModelRaw.trim().isNotEmpty
        ? advisorModelRaw.trim()
        : null;
    final advisorEveryRaw = advisor is Map ? advisor['everyTurns'] : null;
    final advisorEveryTurns = advisorEveryRaw is int && advisorEveryRaw >= 1
        ? advisorEveryRaw
        : 3;
    final advisorInstructionsRaw = advisor is Map
        ? advisor['instructions']
        : null;
    final advisorInstructions =
        advisorInstructionsRaw is String &&
            advisorInstructionsRaw.trim().isNotEmpty
        ? advisorInstructionsRaw.trim()
        : null;

    final compaction = json['compaction'];
    final policy = switch (compaction is Map ? compaction['policy'] : null) {
      'masking' => CompactionPolicy.masking,
      'hybrid' => CompactionPolicy.hybrid,
      _ => CompactionPolicy.current,
    };
    final execution = json['toolExecution'];
    final parallel = execution is Map ? execution['maxParallel'] : null;

    final hooks = json['hooks'];
    String? resolveHook(String key) {
      if (hooks is! Map) {
        return null;
      }
      final path = hooks[key];
      if (path is! String || path.isEmpty) {
        return null;
      }
      return p.isAbsolute(path) ? path : p.join(base, path);
    }

    return HarnessRunConfig(
      streamRules: rules,
      advisorEnabled: advisorEnabled,
      advisorModel: advisorModel,
      advisorEveryTurns: advisorEveryTurns,
      advisorInstructions: advisorInstructions,
      compaction: CompactionConfig.defaults.copyWith(policy: policy),
      snapshotCompaction: compaction is Map && compaction['snapshots'] == true,
      maxParallelToolCalls: parallel is int && parallel > 0 ? parallel : 4,
      overlapReadOnlyTools:
          execution is Map && execution['overlapReadOnly'] == true,
      hookSessionStart: resolveHook('sessionStart'),
      hookPreTool: resolveHook('preTool'),
      hookPostTool: resolveHook('postTool'),
    );
  }
}
