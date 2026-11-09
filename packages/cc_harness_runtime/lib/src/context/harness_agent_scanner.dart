import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/context/markdown_frontmatter.dart';
import 'package:path/path.dart' as p;

/// Discovers file-defined subagents (markdown + YAML-ish frontmatter: base,
/// description, specialization prompt) under `.agents/agents/`.
///
/// A definition picks a built-in base and may only narrow it (tools, prompt,
/// model). Tiers come from the base and are never widened. Must not shadow a
/// built-in name.
class HarnessAgentScanner {
  /// Creates a [HarnessAgentScanner].
  const HarnessAgentScanner({
    this.maxAgents = 40,
    this.maxBodyBytes = 64 * 1024,
  });

  /// Cap on how many definitions are returned.
  final int maxAgents;

  /// Cap on a single definition's size.
  final int maxBodyBytes;

  /// Directories (relative to a search base) holding `<name>.md`.
  ///
  /// The cross-tool paths are read too, but note the deliberate asymmetry with
  /// the skill scanner: another harness's agent frontmatter is NOT this
  /// contract, so a file that does not name a `base` we understand is skipped
  /// rather than guessed at. Half-understanding an agent definition is how a
  /// read-only reviewer quietly becomes a writer.
  static const List<String> agentDirs = [
    '.agents/agents',
    '.agent/agents',
    '.claude/agents',
    '.cc/agents',
  ];

  /// Scans each of [bases], de-duplicated by name (first base wins).
  Future<List<CustomSubagentProfile>> scan(List<String?> bases) async {
    final byName = <String, CustomSubagentProfile>{};
    for (final base in bases) {
      if (base == null || base.isEmpty) {
        continue;
      }
      for (final relative in agentDirs) {
        final dir = Directory(p.join(base, relative));
        if (!dir.existsSync()) {
          continue;
        }
        final List<FileSystemEntity> entries;
        try {
          entries = dir.listSync(followLinks: false);
        } on FileSystemException {
          continue;
        }
        for (final entry in entries) {
          if (byName.length >= maxAgents) {
            return byName.values.toList();
          }
          if (entry is! File || p.extension(entry.path) != '.md') {
            continue;
          }
          final agent = await _parse(entry);
          if (agent != null) {
            byName.putIfAbsent(agent.name, () => agent);
          }
        }
      }
    }
    return byName.values.toList();
  }

  Future<CustomSubagentProfile?> _parse(File file) async {
    String raw;
    try {
      if (await file.length() > maxBodyBytes) {
        return null;
      }
      raw = await file.readAsString();
    } on Object {
      return null;
    }
    final frontmatter = MarkdownFrontmatter.parse(raw);
    if (!frontmatter.hasHeader) {
      return null;
    }
    final body = frontmatter.body.trim();
    if (body.isEmpty) {
      return null;
    }

    final name = p.basenameWithoutExtension(file.path).toLowerCase();
    // A definition may not shadow a built-in: redefining `general` with a
    // different tier would be privilege escalation dressed up as config.
    if (name.isEmpty || SubagentType.values.any((t) => t.name == name)) {
      return null;
    }

    var description = '';
    var base = SubagentType.explore;
    var sawBase = false;
    var tools = const <String>[];
    String? model;
    int? maxTurns;
    var readSummarize = true;

    for (final MapEntry(:key, :value) in frontmatter.fields.entries) {
      switch (key) {
        case 'description':
          description = value;
        case 'base':
          final parsed = SubagentType.values
              .where((t) => t.name == value.toLowerCase())
              .firstOrNull;
          if (parsed != null) {
            base = parsed;
            sawBase = true;
          }
        case 'tools':
          tools = [
            for (final t in value.split(RegExp(r'[,\s]+')))
              if (t.trim().isNotEmpty) t.trim(),
          ];
        case 'model':
          model = value.isEmpty ? null : value;
        case 'max-turns':
        case 'maxturns':
          maxTurns = int.tryParse(value);
        case 'read-summarize':
        case 'readsummarize':
          readSummarize = value.toLowerCase() != 'false';
      }
    }

    // No recognizable base means this is another harness's format. Default to
    // the SAFEST built-in rather than guessing: an agent that turns out to be
    // read-only when its author wanted more is a complaint; one that turns out
    // to write when its author did not is an incident.
    if (!sawBase) {
      base = SubagentType.explore;
    }
    if (description.isEmpty) {
      description = 'Custom $name subagent';
    }

    return CustomSubagentProfile(
      name: name,
      description: description,
      base: base,
      systemPrompt: body,
      toolAllowlist: tools,
      model: model,
      maxTurns: maxTurns,
      readSummarize: readSummarize,
    );
  }
}
