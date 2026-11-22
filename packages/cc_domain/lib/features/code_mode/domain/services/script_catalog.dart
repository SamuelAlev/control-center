import 'dart:math' as math;

import 'package:cc_domain/features/code_mode/domain/services/json_schema_typescript.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_globals.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_identifiers.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/tool_index.dart';

/// One tool in a [ScriptCatalog]: its descriptor and the identifier a script
/// calls it by.
class ScriptCatalogEntry {
  /// Creates an entry.
  const ScriptCatalogEntry({required this.id, required this.tool});

  /// The JavaScript identifier (`tools.<id>`).
  final String id;

  /// The tool.
  final ScriptToolDescriptor tool;

  /// The raw tool name (`tools["<name>"]`, and what the gate looks up).
  String get name => tool.name;

  /// The namespace.
  String get namespace => tool.namespace;

  /// The `ALL_TOOLS` entry, also what the runner's `init` frame carries:
  /// `{ id, name, namespace, description }`, with the description cut to
  /// [share] UTF-16 units (ending in `…` when cut; see
  /// [ScriptCatalog.allTools]). `describeTool` has the whole description.
  Map<String, Object?> toSummaryJson({required int share}) => {
    'id': id,
    'name': name,
    'namespace': namespace,
    'description': ScriptCatalog.cutTo(tool.description, share),
  };
}

/// One namespace of a [ScriptCatalog].
class ScriptNamespaceSummary {
  /// Creates a summary.
  const ScriptNamespaceSummary({
    required this.name,
    required this.description,
    required this.toolCount,
  });

  /// `builtin`, `control-center`, or an external server's name.
  final String name;

  /// What the namespace holds.
  final String description;

  /// How many callable tools it has.
  final int toolCount;

  /// The wire form.
  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'toolCount': toolCount,
  };
}

/// The answer to a discovery call (`describeTool`, `describeNamespace`).
///
/// The host relays it to the runner as the call's `result`: [ok] is the
/// frame's `ok` and [toJson] its payload. An unknown name rejects the
/// script's promise with [ScriptCatalogUnknown.message].
sealed class ScriptCatalogAnswer {
  const ScriptCatalogAnswer();

  /// Whether the name was found.
  bool get ok;

  /// The JSON payload.
  Object? toJson();
}

/// A found tool or namespace.
final class ScriptCatalogFound extends ScriptCatalogAnswer {
  /// Creates the answer.
  const ScriptCatalogFound(this.value);

  /// The description, JSON-serialisable.
  final Map<String, Object?> value;

  @override
  bool get ok => true;

  @override
  Object? toJson() => value;
}

/// A name the catalog does not have, with the closest ones it does.
final class ScriptCatalogUnknown extends ScriptCatalogAnswer {
  /// Creates the answer.
  const ScriptCatalogUnknown({
    required this.kind,
    required this.requested,
    required this.didYouMean,
  });

  /// `tool` or `namespace`.
  final String kind;

  /// What the script asked for.
  final String requested;

  /// The closest names, best first. Tool suggestions are identifiers.
  final List<String> didYouMean;

  /// The most characters of [requested] an answer repeats.
  static const int maxEchoChars = 128;

  /// [requested] as an answer repeats it: at most [maxEchoChars] characters.
  String get echoed => requested.length <= maxEchoChars
      ? requested
      : '${requested.substring(0, maxEchoChars)}…';

  /// The error message the script's promise rejects with.
  String get message {
    final head = 'Unknown $kind "$echoed".';
    if (didYouMean.isEmpty) {
      return kind == 'tool'
          ? '$head Use searchTools(query) or ALL_TOOLS to find one.'
          : '$head Namespaces are listed by ALL_TOOLS.';
    }
    return '$head Did you mean: ${didYouMean.join(', ')}?';
  }

  @override
  bool get ok => false;

  @override
  Object? toJson() => {
    'error': message,
    'kind': kind,
    'requested': echoed,
    'didYouMean': didYouMean,
  };
}

/// What a script can call and learn about: the callable set with
/// identifiers, its namespaces, the TypeScript declarations, and search.
///
/// The lookups also answer for the script's own functions
/// ([ScriptGlobals]): `describeTool` when no tool has the name,
/// `searchTools` ranked with the tools, `describeNamespace("script")`.
/// They are never entries: not in [allTools], [namespaces] or any count.
///
/// Built from the same descriptors the gate admits, so introspection never
/// advertises a tool a call would refuse. Everything it returns is
/// JSON-serialisable, because it crosses to the runner as JSON. Entries are
/// ordered by namespace (`builtin`, `control-center`, then external servers
/// by name) and then by name, whatever order the descriptors came in.
class ScriptCatalog {
  /// Builds a catalog.
  ///
  /// [namespaceDescriptions] describes external servers by name; the two
  /// first-party namespaces use
  /// [ScriptToolNamespace.firstPartyDescriptions] unless overridden. Throws
  /// [ArgumentError] when two descriptors share a name.
  factory ScriptCatalog(
    Iterable<ScriptToolDescriptor> tools, {
    Map<String, String> namespaceDescriptions = const {},
    JsonSchemaTypeScript renderer = const JsonSchemaTypeScript(),
  }) {
    final byName = <String, ScriptToolDescriptor>{};
    for (final tool in tools) {
      if (byName.containsKey(tool.name)) {
        throw ArgumentError.value(
          tool.name,
          'tools',
          'two script tools share this name',
        );
      }
      byName[tool.name] = tool;
    }
    final identifiers = ScriptIdentifierMap.build(byName.keys);
    final entries = [
      for (final tool in byName.values)
        ScriptCatalogEntry(id: identifiers.idFor(tool.name)!, tool: tool),
    ]..sort(compareEntries);
    final descriptions = {
      ...ScriptToolNamespace.firstPartyDescriptions,
      ...namespaceDescriptions,
    };
    return ScriptCatalog._(entries, identifiers, descriptions, renderer);
  }

  ScriptCatalog._(
    this.entries,
    this.identifiers,
    this._namespaceDescriptions,
    this._renderer,
  ) : _byName = {for (final e in entries) e.name: e};

  /// The callable set, in catalog order.
  final List<ScriptCatalogEntry> entries;

  /// Raw name to identifier, both ways.
  final ScriptIdentifierMap identifiers;

  final Map<String, String> _namespaceDescriptions;
  final JsonSchemaTypeScript _renderer;
  final Map<String, ScriptCatalogEntry> _byName;
  final Map<String, String> _declarations = {};
  final Map<String, String> _signatureCache = {};
  final Map<String, String> _summaries = {};
  ToolIndex? _index;

  /// The most results one `searchTools` call returns.
  static const int maxSearchResults = 50;

  /// The most "did you mean" suggestions.
  static const int maxSuggestions = 5;

  /// The most characters of a name that suggestions compare: a longer
  /// requested name, or a candidate name, is compared by its head.
  static const int maxSuggestionChars = 64;

  static final RegExp _abbreviation = RegExp(
    r'\b(e\.g|i\.e|etc|vs)\.$',
    caseSensitive: false,
  );

  /// The longest summary a search hit carries, in characters.
  static const int maxSummaryChars = 200;

  /// Renders a search hit's [signatureOf]: no JSDoc, and short, so a hit
  /// stays one line; a longer argument type falls back to argument names.
  static const JsonSchemaTypeScript _signatures = JsonSchemaTypeScript(
    maxTypeChars: 160,
    docs: false,
  );

  /// Orders namespaces: `builtin`, `control-center`, then the rest by name.
  static int compareNamespaces(String a, String b) {
    int rank(String n) => switch (n) {
      ScriptToolNamespace.builtin => 0,
      ScriptToolNamespace.controlCenter => 1,
      _ => 2,
    };
    final byRank = rank(a).compareTo(rank(b));
    return byRank != 0 ? byRank : a.compareTo(b);
  }

  /// Orders entries by namespace ([compareNamespaces]), then name.
  static int compareEntries(ScriptCatalogEntry a, ScriptCatalogEntry b) {
    final byNamespace = compareNamespaces(a.namespace, b.namespace);
    return byNamespace != 0 ? byNamespace : a.name.compareTo(b.name);
  }

  /// Number of callable tools.
  int get length => entries.length;

  /// The entry for a raw name or an identifier, or null.
  ScriptCatalogEntry? find(String nameOrId) {
    final name = identifiers.resolve(nameOrId);
    return name == null ? null : _byName[name];
  }

  /// The namespaces with at least one tool, in [compareNamespaces] order.
  List<ScriptNamespaceSummary> get namespaces {
    final counts = <String, int>{};
    for (final e in entries) {
      counts[e.namespace] = (counts[e.namespace] ?? 0) + 1;
    }
    final names = counts.keys.toList()..sort(compareNamespaces);
    return [
      for (final n in names)
        ScriptNamespaceSummary(
          name: n,
          description: namespaceDescription(n),
          toolCount: counts[n]!,
        ),
    ];
  }

  /// The description of [namespace], or an empty string when none was given.
  String namespaceDescription(String namespace) =>
      _namespaceDescriptions[namespace] ?? '';

  /// The one-line TypeScript declaration of [entry]. Rendered once per
  /// catalog, when first asked for, and kept; the render is bounded
  /// ([JsonSchemaTypeScript.maxNodes]).
  String declarationOf(ScriptCatalogEntry entry) =>
      _declarations[entry.name] ??= _renderer.declaration(
        entry.id,
        entry.tool.inputSchema,
        outputSchema: entry.tool.outputSchema,
      );

  /// The compact one-line signature of [entry]:
  /// `id(args: { path: string; limit?: number; })`, or its argument names
  /// when the type is long (`id(args: { path, limit? })`).
  ///
  /// Rendered once per catalog, when first asked for, and kept.
  String signatureOf(ScriptCatalogEntry entry) =>
      _signatureCache[entry.name] ??= _signatures.signature(
        entry.id,
        entry.tool.inputSchema,
      );

  /// [summaryOf] the entry's description, computed once per catalog.
  String _summaryOf(ScriptCatalogEntry entry) =>
      _summaries[entry.name] ??= summaryOf(entry.tool.description);

  /// The first sentence of [description]'s first paragraph, whitespace
  /// collapsed, at most [maxSummaryChars] characters (cut with `…`).
  static String summaryOf(String description) {
    final paragraph = description.trim().split(RegExp(r'\n\s*\n')).first;
    final flat = paragraph.replaceAll(RegExp(r'\s+'), ' ').trim();
    // The first stop that ends a sentence, not an abbreviation (`e.g. `).
    final end = RegExp(r'[.!?](\s|$)')
        .allMatches(flat)
        .where((m) => !_abbreviation.hasMatch(flat.substring(0, m.start + 1)))
        .firstOrNull;
    final sentence = end == null ? flat : flat.substring(0, end.start + 1);
    return sentence.length <= maxSummaryChars
        ? sentence
        : '${sentence.substring(0, maxSummaryChars - 1).trimRight()}…';
  }

  /// `ALL_TOOLS`: `[{ id, name, namespace, description }]` in catalog order.
  ///
  /// The list travels whole in the runner's `init` frame, so its
  /// descriptions share [maxAllToolsDescriptionUnits] equally
  /// ([allToolsShare]): a description longer than its share is cut and ends
  /// in `…`, whatever the tool's position; `id`, `name` and `namespace` are
  /// whole. A large catalog then degrades (shorter descriptions) instead of
  /// failing every script of the run; `describeTool` still answers with the
  /// whole description.
  List<Map<String, Object?>> allTools() {
    final share = allToolsShare(entries.length);
    return [for (final e in entries) e.toSummaryJson(share: share)];
  }

  /// What the descriptions of one `ALL_TOOLS` may hold together, in UTF-16
  /// units.
  static const int maxAllToolsDescriptionUnits = 1048576;

  /// The units each of [toolCount] descriptions may take in `ALL_TOOLS`:
  /// an equal share of [maxAllToolsDescriptionUnits].
  static int allToolsShare(int toolCount) => toolCount == 0
      ? maxAllToolsDescriptionUnits
      : maxAllToolsDescriptionUnits ~/ toolCount;

  /// [text] in at most [units] UTF-16 units: whole when it fits, otherwise
  /// its head ending in `…` (never splitting a surrogate pair).
  static String cutTo(String text, int units) {
    if (text.length <= units) {
      return text;
    }
    if (units <= 0) {
      return '';
    }
    var end = units - 1;
    if (end > 0 && _isHighSurrogate(text.codeUnitAt(end - 1))) {
      end--;
    }
    return '${text.substring(0, end)}…';
  }

  static bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

  /// `describeTool(nameOrId)`: `{ id, name, namespace, description,
  /// declaration, inputSchema, outputSchema, resultNote, tier, effects }`,
  /// or the closest names when it is unknown. `resultNote` is what a script
  /// receives from a completed call, in the tool's own words, or null.
  ///
  /// A tool wins. With no tool of that name, a script function answers
  /// ([ScriptGlobal.toJson]: `kind: "global"`, namespace `script`, no `id`,
  /// no tier), and an object of them (`models`) answers with its
  /// `members`.
  ScriptCatalogAnswer describeTool(String nameOrId) {
    final entry = find(nameOrId);
    if (entry == null) {
      final globals = ScriptGlobals.named(nameOrId);
      if (globals.length == 1 && globals.single.name == nameOrId) {
        return ScriptCatalogFound(globals.single.toJson());
      }
      if (globals.isNotEmpty) {
        return ScriptCatalogFound({
          'kind': ScriptGlobals.kind,
          'name': nameOrId,
          'namespace': ScriptGlobals.namespace,
          'members': [for (final g in globals) g.toJson()],
        });
      }
      return ScriptCatalogUnknown(
        kind: 'tool',
        requested: nameOrId,
        didYouMean: suggestTools(nameOrId),
      );
    }
    return ScriptCatalogFound({
      'id': entry.id,
      'name': entry.name,
      'namespace': entry.namespace,
      'description': entry.tool.description,
      'declaration': declarationOf(entry),
      'inputSchema': entry.tool.inputSchema,
      'outputSchema': entry.tool.outputSchema,
      'resultNote': entry.tool.resultNote,
      'tier': entry.tool.tier.name,
      'effects': entry.tool.effectWires,
    });
  }

  /// `describeNamespace(name)`: `{ name, description, tools }`, where each
  /// tool is `{ id, name, description }`, or the closest namespace names.
  ///
  /// `script`, when no tool namespace has that name, answers with the
  /// script's own functions: `{ name, description, kind: "global",
  /// globals }`.
  ScriptCatalogAnswer describeNamespace(String name) {
    final tools = [
      for (final e in entries)
        if (e.namespace == name)
          {'id': e.id, 'name': e.name, 'description': e.tool.description},
    ];
    if (tools.isEmpty && name == ScriptGlobals.namespace) {
      return ScriptCatalogFound({
        'name': name,
        'description': ScriptGlobals.namespaceDescription,
        'kind': ScriptGlobals.kind,
        'globals': [for (final g in ScriptGlobals.all) g.toJson()],
      });
    }
    if (tools.isEmpty) {
      return ScriptCatalogUnknown(
        kind: 'namespace',
        requested: name,
        didYouMean: _closest(name, [for (final n in namespaces) n.name]),
      );
    }
    return ScriptCatalogFound({
      'name': name,
      'description': namespaceDescription(name),
      'tools': tools,
    });
  }

  /// `searchTools(query, { limit, namespace })`: BM25 over names,
  /// descriptions and argument names, using the shared [ToolIndex], as
  /// `[{ id, name, namespace, summary, signature, score }]`, best first:
  /// [summaryOf] the description and [signatureOf] the tool. A hit is
  /// enough to pick a tool; `describeTool` has the rest.
  ///
  /// The script's own functions are ranked with the tools. Their hits are
  /// `{ kind: "global", name, namespace: "script", summary, signature,
  /// score }` with the call form as `signature` and no `id`.
  ///
  /// [limit] is clamped to 1..[maxSearchResults]. A [namespace] filter
  /// ranks over the whole catalog and keeps that namespace's hits, so scores
  /// mean the same with and without it. An unknown namespace finds nothing.
  List<Map<String, Object?>> searchTools(
    String query, {
    int limit = 8,
    String? namespace,
  }) {
    final capped = limit.clamp(1, maxSearchResults);
    // Shared by every catalog with the same indexed content: each script
    // builds a catalog, and building the index per script would repeat the
    // same work for every script of a run.
    final index = _index ??= ToolIndex.shared(
      [
        for (final e in entries)
          ToolDef(
            name: e.name,
            description: e.tool.description,
            inputSchema: e.tool.inputSchema,
          ),
      ],
      // Constant rows of known size, indexed whole whatever the tools'
      // share, so a large catalog never cuts a global out of the search.
      whole: [
        for (final g in ScriptGlobals.all)
          ToolDef(
            name: g.name,
            description: _globalText(g),
            inputSchema: const {},
          ),
      ],
    );
    final hits = index.search(
      query,
      limit: namespace == null ? capped : index.length,
    );
    final results = <Map<String, Object?>>[];
    for (final hit in hits) {
      // A global's document is told from a tool of the same name by its
      // text, which no tool description repeats.
      final global = ScriptGlobals.byName(hit.name);
      if (global != null && hit.description == _globalText(global)) {
        if (namespace == null || namespace == ScriptGlobals.namespace) {
          results.add({
            'kind': ScriptGlobals.kind,
            'name': global.name,
            'namespace': ScriptGlobals.namespace,
            'summary': global.summary,
            'signature': global.call,
            'score': double.parse(hit.score.toStringAsFixed(4)),
          });
        }
      } else {
        final entry = _byName[hit.name];
        if (entry == null ||
            (namespace != null && entry.namespace != namespace)) {
          continue;
        }
        results.add({
          'id': entry.id,
          'name': entry.name,
          'namespace': entry.namespace,
          'summary': _summaryOf(entry),
          'signature': signatureOf(entry),
          'score': double.parse(hit.score.toStringAsFixed(4)),
        });
      }
      if (results.length >= capped) {
        break;
      }
    }
    return results;
  }

  /// What a global is indexed by: its summary and what it returns.
  static String _globalText(ScriptGlobal global) =>
      '${global.summary} ${global.returns}';

  /// The identifiers of the tools closest to [nameOrId], best first: close
  /// spellings of a raw name or identifier, compared by name only (never a
  /// search), each name by its first [maxSuggestionChars] characters, so the
  /// cost is bounded by the catalog's size whatever was asked for. At most
  /// [maxSuggestions].
  List<String> suggestTools(String nameOrId) {
    final byId = _suggestionIds;
    final out = <String>[];
    for (final s in _closest(nameOrId, _suggestionNames)) {
      final id = byId[s]!;
      if (!out.contains(id)) {
        out.add(id);
      }
    }
    return out.take(maxSuggestions).toList();
  }

  /// Every name and identifier a suggestion compares, to its identifier:
  /// built once per catalog, when first needed.
  late final Map<String, String> _suggestionIds = {
    for (final e in entries) ...{e.id: e.id, e.name: e.id},
  };
  late final List<String> _suggestionNames = _suggestionIds.keys.toList();

  /// Candidates within a small edit distance of [query] (case-insensitive),
  /// or containing it, best first, ties by name.
  ///
  /// Both sides are compared by their first [maxSuggestionChars] characters,
  /// so one candidate costs at most that squared.
  static List<String> _closest(String query, List<String> candidates) {
    final q = _head(query, maxSuggestionChars).toLowerCase();
    if (q.isEmpty) {
      return const [];
    }
    final threshold = math.max(2, q.length ~/ 3);
    final scored = <(String, int)>[];
    for (final c in candidates) {
      final lower = _head(c, maxSuggestionChars).toLowerCase();
      var distance = _levenshtein(q, lower, threshold);
      if (distance > threshold &&
          q.length >= 3 &&
          (lower.contains(q) || q.contains(lower))) {
        distance = threshold;
      }
      if (distance <= threshold) {
        scored.add((c, distance));
      }
    }
    scored.sort((a, b) {
      final byDistance = a.$2.compareTo(b.$2);
      return byDistance != 0 ? byDistance : a.$1.compareTo(b.$1);
    });
    return [for (final s in scored.take(maxSuggestions)) s.$1];
  }

  static String _head(String text, int max) =>
      text.length > max ? text.substring(0, max) : text;

  /// Edit distance between [a] and [b], or a value above [cap] as soon as it
  /// is known to exceed it.
  static int _levenshtein(String a, String b, int cap) {
    if ((a.length - b.length).abs() > cap) {
      return cap + 1;
    }
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      var rowMin = current[0];
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        current[j] = math.min(
          math.min(current[j - 1] + 1, previous[j] + 1),
          previous[j - 1] + cost,
        );
        rowMin = math.min(rowMin, current[j]);
      }
      if (rowMin > cap) {
        return cap + 1;
      }
      previous = current;
    }
    return previous[b.length];
  }
}
