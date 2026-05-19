import 'dart:io';

import 'package:path/path.dart' as p;

/// One named advisor in the roster: its own model, tools and specialization.
class WatchdogRosterEntry {
  /// Creates a [WatchdogRosterEntry].
  const WatchdogRosterEntry({
    required this.name,
    this.model,
    this.tools = const [],
    this.instructions = '',
    this.everyTurns,
  });

  /// Human label, also used for the run-log attribution.
  final String name;

  /// Model override, or null to use the run's advisor model.
  final String? model;

  /// Tool names this advisor may use while investigating.
  ///
  /// Empty means the read-only default (`read`, `search`, `find`). The set is
  /// intersected with what the run actually built, never unioned — a roster
  /// entry cannot invent a tool, and it certainly cannot grant itself one the
  /// primary agent's own policy denies.
  final List<String> tools;

  /// What this advisor should watch for, appended to the shared attention.
  final String instructions;

  /// Review cadence override, or null to use the run's.
  final int? everyTurns;
}

/// The advisors a project declares, plus the guidance shared by all of them.
class WatchdogRoster {
  /// Creates a [WatchdogRoster].
  const WatchdogRoster({this.shared = '', this.advisors = const []});

  /// Instructions prepended to every advisor's prompt.
  final String shared;

  /// The declared advisors, in discovery order.
  final List<WatchdogRosterEntry> advisors;

  /// The empty roster — one default advisor, configured elsewhere.
  static const WatchdogRoster none = WatchdogRoster();

  /// Whether anything was declared.
  bool get isEmpty => advisors.isEmpty && shared.isEmpty;
}

/// Reads `WATCHDOG.yml` — the advisor roster.
///
/// **Why a roster and not one advisor.** A single reviewer has one prompt and
/// one model, so it is either broad and shallow or narrow and blind. The
/// review questions people actually care about are different in kind — "does
/// this couple modules that should not touch", "does this leak a credential",
/// "does this actually pass its own tests" — and each wants a different
/// prompt, and often a different model. One advisor asked all three produces a
/// note about whichever it noticed first.
///
/// Where `WATCHDOG.md` says what to look for, this says WHO looks.
///
/// Parsed with a small hand-rolled reader rather than a YAML dependency: the
/// shape is a list of flat maps plus one block scalar, and the failure mode
/// that matters is "one bad file must not kill the session", which a tolerant
/// reader gives directly. A malformed entry is skipped, never guessed at.
class WatchdogRosterLoader {
  /// Creates a [WatchdogRosterLoader].
  const WatchdogRosterLoader({this.maxAdvisors = 6, this.maxBytes = 32 * 1024});

  /// Cap on declared advisors — each one is a whole extra model reviewing
  /// every turn, so this is a cost ceiling as much as a sanity check.
  final int maxAdvisors;

  /// Cap on the file size.
  final int maxBytes;

  /// File names searched, in order.
  static const List<String> fileNames = ['WATCHDOG.yml', 'WATCHDOG.yaml'];

  /// Loads the roster from [cwd] and [agentConfigDir], project first.
  Future<WatchdogRoster> load(String? cwd, {String? agentConfigDir}) async {
    for (final base in [cwd, agentConfigDir]) {
      if (base == null || base.isEmpty) {
        continue;
      }
      for (final dir in [base, p.join(base, '.agents')]) {
        for (final fileName in fileNames) {
          final file = File(p.join(dir, fileName));
          if (!file.existsSync()) {
            continue;
          }
          try {
            if (await file.length() > maxBytes) {
              continue;
            }
            final roster = parseRoster(await file.readAsString());
            if (!roster.isEmpty) {
              return roster;
            }
          } on Object {
            // One unparseable project config must not take the session down;
            // the run continues with the default single advisor.
            continue;
          }
        }
      }
    }
    return WatchdogRoster.none;
  }

  /// Parses roster [yaml].
  ///
  /// Recognized shape:
  /// ```yaml
  /// instructions: |
  ///   Everyone: prefer diffs that keep tests unified.
  /// advisors:
  ///   - name: Architecture
  ///     model: claude-sonnet-5
  ///     tools: [read, search]
  ///     every-turns: 2
  ///     instructions: |
  ///       Watch cross-module coupling.
  /// ```
  WatchdogRoster parseRoster(String yaml) {
    final lines = yaml.split('\n');
    final shared = StringBuffer();
    final advisors = <WatchdogRosterEntry>[];

    String? currentName;
    String? currentModel;
    var currentTools = <String>[];
    var currentInstructions = StringBuffer();
    int? currentEveryTurns;
    var inAdvisors = false;
    // Which block scalar (if any) subsequent lines belong to, and the indent
    // of the key that opened it. The indent is load-bearing: a block that
    // continues on "any indented line" swallows the NEXT list item, because
    // `  - name: Fixer` is indented too — which silently collapses a
    // three-advisor roster into one.
    var block = _Block.none;
    var blockIndent = 0;

    void flush() {
      final name = currentName;
      if (name != null && name.isNotEmpty && advisors.length < maxAdvisors) {
        advisors.add(
          WatchdogRosterEntry(
            name: name,
            model: currentModel,
            tools: currentTools,
            instructions: currentInstructions.toString().trim(),
            everyTurns: currentEveryTurns,
          ),
        );
      }
      currentName = null;
      currentModel = null;
      currentTools = <String>[];
      currentInstructions = StringBuffer();
      currentEveryTurns = null;
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().startsWith('#')) {
        continue;
      }
      final indent = line.length - line.trimLeft().length;
      final trimmed = line.trim();

      // A block scalar continues only while the line is MORE indented than the
      // key that opened it (blank lines belong to it either way).
      if (block != _Block.none) {
        if (trimmed.isEmpty || indent > blockIndent) {
          final target = block == _Block.shared ? shared : currentInstructions;
          target.writeln(trimmed);
          continue;
        }
        block = _Block.none;
      }
      if (trimmed.isEmpty) {
        continue;
      }

      if (trimmed == 'advisors:') {
        inAdvisors = true;
        continue;
      }
      if (trimmed == 'instructions: |' || trimmed == 'instructions: >') {
        block = inAdvisors && currentName != null
            ? _Block.advisor
            : _Block.shared;
        blockIndent = indent;
        continue;
      }

      if (trimmed.startsWith('- ')) {
        flush();
        final rest = trimmed.substring(2).trim();
        final pair = _pair(rest);
        if (pair != null && pair.key == 'name') {
          currentName = pair.value;
        }
        continue;
      }

      final pair = _pair(trimmed);
      if (pair == null) {
        continue;
      }
      switch (pair.key) {
        case 'name':
          if (inAdvisors) {
            currentName = pair.value;
          }
        case 'model':
          currentModel = pair.value.isEmpty ? null : pair.value;
        case 'tools':
          currentTools = _list(pair.value);
        case 'every-turns':
        case 'everyturns':
          currentEveryTurns = int.tryParse(pair.value);
        case 'instructions':
          if (inAdvisors && currentName != null) {
            currentInstructions.writeln(pair.value);
          } else {
            shared.writeln(pair.value);
          }
      }
    }
    flush();

    return WatchdogRoster(
      shared: shared.toString().trim(),
      advisors: advisors,
    );
  }

  static ({String key, String value})? _pair(String line) {
    final idx = line.indexOf(':');
    if (idx <= 0) {
      return null;
    }
    return (
      key: line.substring(0, idx).trim().toLowerCase(),
      value: line
          .substring(idx + 1)
          .trim()
          .replaceAll(RegExp(r'''^['"]|['"]$'''), ''),
    );
  }

  static List<String> _list(String value) {
    final inner = value.replaceAll(RegExp(r'^\[|\]$'), '');
    return [
      for (final item in inner.split(RegExp(r'[,\s]+')))
        if (item.trim().isNotEmpty)
          item.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), ''),
    ];
  }
}

enum _Block { none, shared, advisor }
