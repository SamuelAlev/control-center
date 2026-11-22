import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:path/path.dart' as p;

/// Opt-in on-disk harness config. Data settings (stream rules, advisor,
/// `compaction` and `toolExecution` experiments) come from `.agents/harness.json`
/// in the working tree or the agent config dir; shell hooks come only from
/// `hooks.json` in the server's own hook folder for the agent (see [load]).
/// Absent files → defaults (stream rules, advisor, shell hooks off; text
/// compaction and post-response tool execution).
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
    this.hookStop,
    this.hookPreCompact,
    this.preToolRefused = false,
    this.refusedHooks = const [],
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

  /// Real path of the session-start hook script, if configured.
  final String? hookSessionStart;

  /// Real path of the pre-tool hook script, if configured.
  final String? hookPreTool;

  /// Real path of the post-tool hook script, if configured.
  final String? hookPostTool;

  /// Real path of the stop hook script, if configured: asked when the model
  /// would end its turn (exit 2 with text keeps the run going).
  final String? hookStop;

  /// Real path of the pre-compact hook script, if configured: its output is
  /// added to a compaction's focus.
  final String? hookPreCompact;

  /// Whether a pre-tool gate was declared but refused (see [refusedHooks]):
  /// the run then denies every tool call rather than run ungated.
  final bool preToolRefused;

  /// Why each refused hook declaration was refused, e.g.
  /// `preTool: an absolute path`.
  final List<String> refusedHooks;

  /// Whether any shell hook is configured, a refused pre-tool gate included.
  bool get hasHooks =>
      hookSessionStart != null ||
      hookPreTool != null ||
      hookPostTool != null ||
      hookStop != null ||
      hookPreCompact != null ||
      preToolRefused;

  /// The base whose `.agents/harness.json` declared hooks, which were dropped:
  /// hooks are read only from the server's hook folder (see [load]), or null.
  final String? droppedHookBase;

  /// The hook declarations file inside a hook folder.
  static const hooksFileName = 'hooks.json';

  /// Loads the data settings from the first `<base>/.agents/harness.json`
  /// found among [bases] (cwd first, then the agent config dir), and the
  /// shell hooks from `<hookBase>/hooks.json` alone. An unparsable
  /// `harness.json` gives [none]'s data settings.
  ///
  /// SHELL HOOKS are arbitrary code execution, so they are host
  /// configuration: [hookBase] is a folder the server owner fills by hand on
  /// the host, outside every workspace's storage, which no client op, run or
  /// member terminal can write. A working tree is routinely a cloned
  /// repository and the agent config dir is writable by workspace members and
  /// by runs, so a `hooks` block in either `harness.json` is dropped and
  /// reported through [droppedHookBase] rather than silently ignored.
  ///
  /// `hooks.json` maps `sessionStart`, `preTool`, `postTool`, `stop` and
  /// `preCompact` to script
  /// paths RELATIVE to [hookBase]. A path that is absolute, missing, or whose
  /// real path (links resolved) leaves [hookBase] is refused and listed in
  /// [refusedHooks]; a refused or unreadable pre-tool gate sets
  /// [preToolRefused].
  static Future<HarnessRunConfig> load(
    List<String?> bases, {
    String? hookBase,
  }) async {
    var data = none;
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
        if (json is Map<String, dynamic>) {
          data = _parse(json);
          final hooks = json['hooks'];
          if (hooks is Map && hooks.isNotEmpty) {
            data = data._withHooks(droppedHookBase: base);
          }
        }
      } on Object {
        data = none;
      }
      break;
    }
    return hookBase == null || hookBase.isEmpty
        ? data
        : data._withHooks(
            droppedHookBase: data.droppedHookBase,
            hooks: await _loadHooks(hookBase),
          );
  }

  static Future<_Hooks> _loadHooks(String hookBase) async {
    final file = File(p.join(hookBase, hooksFileName));
    if (!file.existsSync()) {
      return const _Hooks();
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on Object {
      return const _Hooks(preToolRefused: true, refused: ['not valid JSON']);
    }
    if (decoded is! Map) {
      return const _Hooks(preToolRefused: true, refused: ['not a JSON object']);
    }
    final json = decoded;
    final String realBase;
    try {
      realBase = Directory(hookBase).resolveSymbolicLinksSync();
    } on Object {
      return const _Hooks(preToolRefused: true, refused: ['folder unreadable']);
    }
    final refused = <String>[];
    String? resolve(String key) {
      final path = json[key];
      if (path == null) {
        return null;
      }
      final String? reason;
      if (path is! String || path.isEmpty) {
        reason = 'not a path';
      } else if (p.isAbsolute(path)) {
        reason = 'an absolute path';
      } else {
        final real = _realFile(p.join(realBase, path));
        if (real == null) {
          reason = 'no such file';
        } else if (!p.isWithin(realBase, real)) {
          reason = 'outside the hook folder';
        } else {
          return real;
        }
      }
      refused.add('$key: $reason');
      return null;
    }

    final preTool = resolve('preTool');
    return _Hooks(
      sessionStart: resolve('sessionStart'),
      preTool: preTool,
      postTool: resolve('postTool'),
      stop: resolve('stop'),
      preCompact: resolve('preCompact'),
      preToolRefused: preTool == null && json['preTool'] != null,
      refused: refused,
    );
  }

  static String? _realFile(String path) {
    try {
      final real = File(path).resolveSymbolicLinksSync();
      return FileSystemEntity.isFileSync(real) ? real : null;
    } on Object {
      return null;
    }
  }

  HarnessRunConfig _withHooks({
    required String? droppedHookBase,
    _Hooks hooks = const _Hooks(),
  }) => HarnessRunConfig(
    streamRules: streamRules,
    advisorEnabled: advisorEnabled,
    advisorModel: advisorModel,
    advisorEveryTurns: advisorEveryTurns,
    advisorInstructions: advisorInstructions,
    compaction: compaction,
    snapshotCompaction: snapshotCompaction,
    maxParallelToolCalls: maxParallelToolCalls,
    overlapReadOnlyTools: overlapReadOnlyTools,
    hookSessionStart: hooks.sessionStart,
    hookPreTool: hooks.preTool,
    hookPostTool: hooks.postTool,
    hookStop: hooks.stop,
    hookPreCompact: hooks.preCompact,
    preToolRefused: hooks.preToolRefused,
    refusedHooks: hooks.refused,
    droppedHookBase: droppedHookBase,
  );

  static HarnessRunConfig _parse(Map<String, dynamic> json) {
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
    );
  }
}

/// The hooks a hook folder declares, as [HarnessRunConfig._loadHooks] read
/// them.
final class _Hooks {
  const _Hooks({
    this.sessionStart,
    this.preTool,
    this.postTool,
    this.stop,
    this.preCompact,
    this.preToolRefused = false,
    this.refused = const [],
  });

  final String? sessionStart;
  final String? preTool;
  final String? postTool;
  final String? stop;
  final String? preCompact;
  final bool preToolRefused;
  final List<String> refused;
}
