import 'package:cc_harness/tools.dart';
import 'package:collection/collection.dart';

/// The namespaces a script's tools are grouped in.
///
/// Every tool belongs to exactly one: the harness's own tools, Control
/// Center's first-party MCP tools, or one external MCP server's tools (the
/// namespace is then the server's name).
// ignore: avoid_classes_with_only_static_members
abstract final class ScriptToolNamespace {
  /// The harness's own tools (`read`, `edit`, `bash`, `search`, …).
  static const String builtin = 'builtin';

  /// Control Center's first-party MCP tools (tickets, memory, reviews, …).
  static const String controlCenter = 'control-center';

  /// The script's own functions (`store`, `models.embed`, …): the namespace
  /// the lookups answer them under. No tool is ever in it.
  static const String script = 'script';

  /// The names no external or workspace server's namespace may take.
  static const Set<String> reserved = {builtin, controlCenter, script};

  /// The prefix [external] gives a server whose name looks [reserved] (or
  /// already starts with it, so two servers cannot end up sharing a
  /// namespace through it).
  static const String externalPrefix = 'external-';

  /// The namespace of an external or workspace MCP server named [server], on
  /// both surfaces (the harness and the MCP endpoint) and in the `[server]`
  /// prefix of its tools' descriptions: [server] itself, unless it looks
  /// [reserved] or starts with [externalPrefix] (compared without regard to
  /// case or surrounding white space, so `BUILTIN`, `Control-Center` and
  /// ` script ` count), which get the prefix. So whatever a workspace admin
  /// names a server, its tools are never listed, counted or described as
  /// first-party, never under `script`, and never look like either.
  ///
  /// Two different server names never give one namespace: a name that is
  /// left as it is never starts with [externalPrefix], and a prefixed name
  /// always does, so the prefix can be taken off again.
  static String external(String server) {
    final looks = server.trim().toLowerCase();
    return reserved.contains(looks) || looks.startsWith(externalPrefix)
        ? '$externalPrefix$server'
        : server;
  }

  /// Whether [namespace] is an external MCP server's.
  ///
  /// External tools are never inlined in the `repl` description: servers
  /// connect and disconnect during a session, and the description sits in the
  /// cached prompt prefix.
  static bool isExternal(String namespace) => !reserved.contains(namespace);

  /// The fixed descriptions of the two first-party namespaces.
  static const Map<String, String> firstPartyDescriptions = {
    builtin: 'Files, search, shell and web, from the harness itself.',
    controlCenter:
        'Tickets, memory, reviews, messages, artifacts, the workspace.',
  };
}

/// The neutral description of one tool a script may call.
///
/// Both surfaces produce it: the harness from its admitted tool surface, the
/// MCP endpoint from the run's tool view. Everything a script can learn about
/// a tool (its declaration, schemas, approval tier and effects) is derived
/// from this, so introspection answers from the same set the gate enforces.
class ScriptToolDescriptor {
  /// Creates a descriptor. Throws [ArgumentError] when [name] or [namespace]
  /// is empty, or [namespace] is [ScriptToolNamespace.script].
  ScriptToolDescriptor({
    required this.name,
    required this.namespace,
    required this.description,
    required this.inputSchema,
    this.outputSchema,
    this.resultNote,
    this.tier = ToolApprovalTier.read,
    Set<ActionClass> effects = const {},
  }) : effects = Set.unmodifiable(effects) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (namespace.isEmpty) {
      throw ArgumentError.value(namespace, 'namespace', 'must not be empty');
    }
    if (namespace == ScriptToolNamespace.script) {
      throw ArgumentError.value(
        namespace,
        'namespace',
        "is the script's own functions; no tool is in it",
      );
    }
  }

  /// Rebuilds from [toJson]'s output. Throws [FormatException] when a
  /// required field is missing or has the wrong type, or the tier or an
  /// effect is not one this build knows: a descriptor read back with a
  /// lower tier or fewer effects would be gated more loosely.
  factory ScriptToolDescriptor.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final namespace = json['namespace'];
    final input = json['input_schema'];
    if (name is! String || namespace is! String || input is! Map) {
      throw const FormatException(
        'A script tool needs a name, a namespace and an input schema.',
      );
    }
    final output = json['output_schema'];
    final tierWire = json['tier'];
    final tier = ToolApprovalTier.values
        .where((t) => t.name == tierWire)
        .firstOrNull;
    if (tier == null) {
      throw FormatException('Unknown tool tier "$tierWire".');
    }
    final effects = <ActionClass>{};
    for (final raw in (json['effects'] as List?) ?? const []) {
      final effect = raw is String ? ActionClass.fromWire(raw) : null;
      if (effect == null) {
        throw FormatException('Unknown tool effect "$raw".');
      }
      effects.add(effect);
    }
    return ScriptToolDescriptor(
      name: name,
      namespace: namespace,
      description: json['description'] as String? ?? '',
      inputSchema: input.cast<String, dynamic>(),
      outputSchema: output is Map ? output.cast<String, dynamic>() : null,
      resultNote: json['result_note'] as String?,
      tier: tier,
      effects: effects,
    );
  }

  /// The tool's registered name (`read`, `create_ticket`,
  /// `mcp__github__list_issues`). What the gate looks up.
  final String name;

  /// [ScriptToolNamespace.builtin], [ScriptToolNamespace.controlCenter], or
  /// an external server's [ScriptToolNamespace.external] name; never
  /// [ScriptToolNamespace.script].
  final String namespace;

  /// The tool's model-facing description.
  final String description;

  /// The JSON Schema of the argument object.
  final Map<String, dynamic> inputSchema;

  /// The JSON Schema of the structured result, when the tool declares one.
  final Map<String, dynamic>? outputSchema;

  /// What a script receives from a completed call, in a sentence or two, when
  /// the tool states it (`HarnessTool.resultNote`, `McpTool.resultNote`).
  final String? resultNote;

  /// The approval tier the gate applies.
  final ToolApprovalTier tier;

  /// The effect classes the tool declares.
  final Set<ActionClass> effects;

  /// Whether this tool belongs to an external MCP server.
  bool get isExternal => ScriptToolNamespace.isExternal(namespace);

  /// The effect classes as sorted wire names.
  List<String> get effectWires => [for (final e in effects) e.wire]..sort();

  /// The wire form.
  Map<String, dynamic> toJson() => {
    'name': name,
    'namespace': namespace,
    'description': description,
    'input_schema': inputSchema,
    if (outputSchema != null) 'output_schema': outputSchema,
    if (resultNote != null) 'result_note': resultNote,
    'tier': tier.name,
    'effects': effectWires,
  };

  static const _deep = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScriptToolDescriptor &&
          other.name == name &&
          other.namespace == namespace &&
          other.description == description &&
          _deep.equals(other.inputSchema, inputSchema) &&
          _deep.equals(other.outputSchema, outputSchema) &&
          other.resultNote == resultNote &&
          other.tier == tier &&
          const SetEquality<ActionClass>().equals(other.effects, effects);

  @override
  int get hashCode => Object.hash(
    name,
    namespace,
    description,
    _deep.hash(inputSchema),
    _deep.hash(outputSchema),
    resultNote,
    tier,
    const SetEquality<ActionClass>().hash(effects),
  );

  @override
  String toString() => 'ScriptToolDescriptor($namespace/$name)';
}
