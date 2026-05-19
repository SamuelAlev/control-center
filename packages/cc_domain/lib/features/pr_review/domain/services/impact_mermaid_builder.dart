// Renders a cohort's merged reverse-dependency subgraph as mermaid flowchart
// source (PRD 18 §6 — "what can this break?").
//
// A depth-grouped LIST answers "how many things depend on this". Only a drawn
// graph answers "does the payment path reach this", which is the question a
// reviewer actually has. cc_markdown draws mermaid natively (no WebView, no
// JS), so this is a pure string build with no new dependency.
//
// Emphasis is STRUCTURAL, not chromatic: `CcMermaidView` deliberately ignores
// author theming (`classDef`, `style`, `%%{init}%%`) so diagrams stay legible
// in both themes and above the contrast floor. A builder that leaned on color
// would render as a flat monochrome graph.
//
// ignore_for_file: sort_constructors_first

/// One node of an impact subgraph.
class ImpactNode {
  /// Creates an [ImpactNode].
  const ImpactNode({
    required this.id,
    required this.name,
    required this.filePath,
    required this.depth,
    this.kind = '',
    this.qualifiedName = '',
  });

  /// Code-graph symbol id.
  final String id;

  /// Short symbol name.
  final String name;

  /// Repository-relative file.
  final String filePath;

  /// Hop distance from the nearest changed (root) symbol; 0 = changed itself.
  final int depth;

  /// Symbol kind wire name.
  final String kind;

  /// Fully-qualified name, when known.
  final String qualifiedName;

  /// Builds from the `review_studio.cohortImpact` wire shape, or null when the
  /// row is unusable.
  static ImpactNode? fromWire(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) {
      return null;
    }
    return ImpactNode(
      id: id,
      name: name,
      filePath: json['filePath'] as String? ?? '',
      depth: (json['depth'] as num?)?.toInt() ?? 0,
      kind: json['kind'] as String? ?? '',
      qualifiedName: json['qualifiedName'] as String? ?? '',
    );
  }
}

/// One edge of an impact subgraph.
class ImpactEdge {
  /// Creates an [ImpactEdge].
  const ImpactEdge({
    required this.source,
    required this.target,
    this.kind = '',
  });

  /// Source symbol id.
  final String source;

  /// Target symbol id.
  final String target;

  /// Edge kind wire name (`calls`, `extendsType`, …).
  final String kind;

  /// Builds from the wire shape, or null when unusable.
  static ImpactEdge? fromWire(Map<String, dynamic> json) {
    final source = json['source'];
    final target = json['target'];
    if (source is! String || target is! String) {
      return null;
    }
    return ImpactEdge(
      source: source,
      target: target,
      kind: json['kind'] as String? ?? '',
    );
  }
}

/// A parsed `review_studio.cohortImpact` payload.
class CohortImpactGraph {
  /// Creates a [CohortImpactGraph].
  const CohortImpactGraph({
    required this.indexed,
    this.roots = const [],
    this.nodes = const [],
    this.edges = const [],
  });

  /// Whether the repo was indexed — false means the graph is genuinely
  /// unavailable, not empty.
  final bool indexed;

  /// Symbol ids of the changed (root) symbols.
  final List<String> roots;

  /// All nodes, including the roots.
  final List<ImpactNode> nodes;

  /// Edges between [nodes].
  final List<ImpactEdge> edges;

  /// Whether there is anything to draw.
  bool get isEmpty => nodes.isEmpty;

  /// Parses the RPC payload defensively.
  factory CohortImpactGraph.fromWire(Map<String, dynamic> json) {
    final nodes = <ImpactNode>[];
    for (final raw in (json['nodes'] as List? ?? const [])) {
      if (raw is! Map) {
        continue;
      }
      final node = ImpactNode.fromWire(raw.cast<String, dynamic>());
      if (node != null) {
        nodes.add(node);
      }
    }
    final edges = <ImpactEdge>[];
    for (final raw in (json['edges'] as List? ?? const [])) {
      if (raw is! Map) {
        continue;
      }
      final edge = ImpactEdge.fromWire(raw.cast<String, dynamic>());
      if (edge != null) {
        edges.add(edge);
      }
    }
    // `roots` is served as full node objects, but a caller that already has
    // ids should not have to wrap them. Accept both rather than making the
    // shape a trap.
    final roots = <String>[];
    for (final raw in (json['roots'] as List? ?? const [])) {
      if (raw is String) {
        roots.add(raw);
      } else if (raw is Map) {
        final id = raw['id'];
        if (id is String) {
          roots.add(id);
        }
      }
    }

    return CohortImpactGraph(
      indexed: json['indexed'] as bool? ?? false,
      roots: roots,
      nodes: nodes,
      edges: edges,
    );
  }
}

/// Labels for the hop groups, supplied by the caller so they can be localized.
class ImpactGraphLabels {
  /// Creates an [ImpactGraphLabels].
  const ImpactGraphLabels({
    required this.changed,
    required this.hop,
    required this.more,
  });

  /// Title of the depth-0 group ("Changed in this PR").
  final String changed;

  /// Title of a depth-N group; receives the hop count.
  final String Function(int hops) hop;

  /// Label for a collapsed file node; receives the file name and hidden count.
  final String Function(String fileName, int hidden) more;
}

/// Builds mermaid flowchart source from an impact subgraph.
class ImpactMermaidBuilder {
  /// Creates an [ImpactMermaidBuilder].
  const ImpactMermaidBuilder();

  /// Renders [graph] as `flowchart RL` source.
  ///
  /// Direction is right-to-left so dependents flow back toward the changed
  /// code — the arrow points the way the breakage travels.
  ///
  /// Beyond [maxNodes], the deepest hops collapse into one node per file
  /// ("3 more in auth_service.dart") rather than truncating silently: a graph
  /// that quietly drops half its nodes reads as "nothing else depends on this",
  /// which is the opposite of the truth.
  String buildFlowchart(
    CohortImpactGraph graph, {
    required ImpactGraphLabels labels,
    int maxNodes = 60,
  }) {
    if (graph.isEmpty) {
      return '';
    }
    final rootIds = graph.roots.toSet();

    final sorted = [...graph.nodes]
      ..sort((a, b) {
        final byDepth = a.depth.compareTo(b.depth);
        if (byDepth != 0) {
          return byDepth;
        }
        final byFile = a.filePath.compareTo(b.filePath);
        if (byFile != 0) {
          return byFile;
        }
        return a.name.compareTo(b.name);
      });

    final kept = sorted.take(maxNodes).toList();
    final dropped = sorted.skip(maxNodes).toList();
    final keptIds = {for (final n in kept) n.id};

    // Collapsed stand-ins for what did not fit, one per file.
    final hiddenByFile = <String, int>{};
    final hiddenDepth = <String, int>{};
    for (final node in dropped) {
      hiddenByFile[node.filePath] = (hiddenByFile[node.filePath] ?? 0) + 1;
      final existing = hiddenDepth[node.filePath];
      if (existing == null || node.depth < existing) {
        hiddenDepth[node.filePath] = node.depth;
      }
    }

    final byDepth = <int, List<ImpactNode>>{};
    for (final node in kept) {
      byDepth.putIfAbsent(node.depth, () => []).add(node);
    }

    final buffer = StringBuffer('flowchart RL\n');
    final ids = <String, String>{};
    var counter = 0;

    String idFor(String symbolId) =>
        ids.putIfAbsent(symbolId, () => 'n${counter++}');

    final depths = byDepth.keys.toList()..sort();
    for (final depth in depths) {
      final group = byDepth[depth]!;
      final title = depth == 0 ? labels.changed : labels.hop(depth);
      buffer
        ..write('  subgraph g$depth["')
        ..write(_escape(title))
        ..write('"]\n');
      for (final node in group) {
        final nodeId = idFor(node.id);
        final label = _escape(_labelFor(node));
        // Roots get the stadium shape so "what changed" is readable without
        // relying on a fill color the renderer will not honor.
        buffer
          ..write('    ')
          ..write(nodeId)
          ..write(rootIds.contains(node.id) ? '(["' : '["')
          ..write(label)
          ..write(rootIds.contains(node.id) ? '"])' : '"]')
          ..write('\n');
      }
      buffer.write('  end\n');
    }

    // Collapsed remainder, grouped with the shallowest hop it hides.
    if (hiddenByFile.isNotEmpty) {
      final files = hiddenByFile.keys.toList()..sort();
      for (final file in files) {
        final nodeId = 'more${counter++}';
        ids['__more__$file'] = nodeId;
        final label = _escape(
          labels.more(_basename(file), hiddenByFile[file]!),
        );
        buffer
          ..write('  ')
          ..write(nodeId)
          ..write('["')
          ..write(label)
          ..write('"]\n');
      }
    }

    // Edges between kept nodes only — an edge to a collapsed node would point
    // at a stand-in that does not represent that specific symbol.
    final seen = <String>{};
    for (final edge in graph.edges) {
      if (!keptIds.contains(edge.source) || !keptIds.contains(edge.target)) {
        continue;
      }
      if (edge.source == edge.target) {
        continue;
      }
      final line = '  ${idFor(edge.source)} --> ${idFor(edge.target)}';
      if (seen.add(line)) {
        buffer
          ..write(line)
          ..write('\n');
      }
    }

    return buffer.toString();
  }

  String _labelFor(ImpactNode node) {
    final file = _basename(node.filePath);
    return file.isEmpty ? node.name : '${node.name}\n$file';
  }

  String _basename(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }

  /// Neutralizes characters that would terminate a mermaid node label or open
  /// a nested shape. Newlines become `<br/>`, which mermaid renders as a line
  /// break inside the label.
  String _escape(String raw) => raw
      .replaceAll('"', "'")
      .replaceAll('[', '(')
      .replaceAll(']', ')')
      .replaceAll('{', '(')
      .replaceAll('}', ')')
      .replaceAll('<', '‹')
      .replaceAll('>', '›')
      .replaceAll('|', '/')
      .replaceAll('\n', '<br/>');
}
