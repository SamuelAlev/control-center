import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/loop.dart';
import 'package:path/path.dart' as p;

/// Opt-in, on-disk configuration for a harness run, read from
/// `.agents/harness.json` in the working tree (or the agent config dir).
///
/// Absent file → everything off (the default loop behavior). This is how the
/// otherwise-inert loop extensions (stream rules, advisor, shell hooks) get
/// activated without a database field.
///
/// Shape:
/// ```json
/// {
///   "streamRules": [{"pattern": "Box::leak", "reminder": "Use Arc instead."}],
///   "advisor": {
///     "enabled": true,
///     "model": "claude-haiku-4-5",
///     "everyTurns": 3,
///     "instructions": "Watch especially for missing error handling."
///   },
///   "hooks": {
///     "sessionStart": ".agents/hooks/start.sh",
///     "preTool": ".agents/hooks/pre.sh",
///     "postTool": ".agents/hooks/post.sh"
///   }
/// }
/// ```
class HarnessRunConfig {
  /// Creates a [HarnessRunConfig].
  const HarnessRunConfig({
    this.streamRules = const [],
    this.advisorEnabled = false,
    this.advisorModel,
    this.advisorEveryTurns = 3,
    this.advisorInstructions,
    this.hookSessionStart,
    this.hookPreTool,
    this.hookPostTool,
  });

  /// The empty config (all features off).
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

  /// Absolute path to the session-start hook script, if configured.
  final String? hookSessionStart;

  /// Absolute path to the pre-tool hook script, if configured.
  final String? hookPreTool;

  /// Absolute path to the post-tool hook script, if configured.
  final String? hookPostTool;

  /// Whether any shell hook is configured.
  bool get hasHooks =>
      hookSessionStart != null || hookPreTool != null || hookPostTool != null;

  /// Loads the config from the first `<base>/.agents/harness.json` found among
  /// [bases] (cwd first, then the agent config dir). Returns [none] when no
  /// file exists or it fails to parse. Hook script paths are resolved relative
  /// to the file's base.
  static Future<HarnessRunConfig> load(List<String?> bases) async {
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
        return _parse(json, base);
      } on Object {
        return none;
      }
    }
    return none;
  }

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
      hookSessionStart: resolveHook('sessionStart'),
      hookPreTool: resolveHook('preTool'),
      hookPostTool: resolveHook('postTool'),
    );
  }
}
