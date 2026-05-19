/// The mermaid parse entry point: dialect dispatch plus a small LRU memo.
///
/// Contract: NEVER throws. Anything unparseable — an unsupported dialect, a
/// truncated body, a diagram with no drawable content — comes back as
/// [CcMermaidUnsupported] carrying a short user-facing reason, and the host
/// renders the source as a code block instead. That is the whole error model.
library;

import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:cc_markdown/src/mermaid/parse/class_parser.dart';
import 'package:cc_markdown/src/mermaid/parse/er_parser.dart';
import 'package:cc_markdown/src/mermaid/parse/flowchart_parser.dart';
import 'package:cc_markdown/src/mermaid/parse/pie_parser.dart';
import 'package:cc_markdown/src/mermaid/parse/sequence_parser.dart';
import 'package:cc_markdown/src/mermaid/parse/source.dart';
import 'package:cc_markdown/src/mermaid/parse/state_parser.dart';
import 'package:cc_markdown/src/mermaid/parse/timeline_parser.dart';

/// Dialect keywords mermaid supports that this engine deliberately does not
/// draw. They are recognized so the failure message can name them instead of
/// saying "unknown".
const Set<String> _knownUnsupported = {
  'gantt',
  'gitgraph',
  'journey',
  'mindmap',
  'quadrantchart',
  'requirementdiagram',
  'sankey-beta',
  'sankey',
  'xychart-beta',
  'xychart',
  'block-beta',
  'block',
  'c4context',
  'c4container',
  'c4component',
  'c4dynamic',
  'c4deployment',
  'zenuml',
  'architecture-beta',
  'packet-beta',
  'kanban',
  'radar-beta',
  'treemap-beta',
};

/// Parses [source] (the body of a ```` ```mermaid ```` fence).
///
/// Results are memoized by source text, so re-rendering the same diagram across
/// rebuilds, scroll recycling, and theme changes costs one map lookup.
CcMermaidParseResult parseMermaid(String source) {
  final cached = _memo.get(source);
  if (cached != null) {
    return cached;
  }
  final result = _parse(source);
  _memo.put(source, result);
  return result;
}

/// Drops every memoized parse. Tests and long-lived hosts use this; normal
/// rendering never needs it.
void clearMermaidParseCache() => _memo.clear();

CcMermaidParseResult _parse(String source) {
  final prepared = preprocessMermaid(source);
  if (prepared.header.isEmpty) {
    return const CcMermaidUnsupported('empty diagram');
  }
  final (keyword, _) = splitFirstWord(prepared.header);
  final dialect = keyword.toLowerCase().replaceAll(':', '');

  final CcMermaidDiagram diagram;
  switch (dialect) {
    case 'flowchart' || 'graph' || 'flowchart-elk':
      diagram = parseMermaidFlowchart(prepared);
    case 'statediagram' || 'statediagram-v2':
      diagram = parseMermaidState(prepared);
    case 'classdiagram' || 'classdiagram-v2':
      diagram = parseMermaidClass(prepared);
    case 'erdiagram':
      diagram = parseMermaidEr(prepared);
    case 'sequencediagram':
      diagram = parseMermaidSequence(prepared);
    case 'pie':
      diagram = parseMermaidPie(prepared);
    case 'timeline':
      diagram = parseMermaidTimeline(prepared);
    default:
      if (_knownUnsupported.contains(dialect)) {
        return CcMermaidUnsupported(
          'unsupported diagram type: $dialect',
          dialect: dialect,
        );
      }
      return CcMermaidUnsupported('unrecognized diagram type: $keyword');
  }

  final reason = _emptyReason(diagram) ?? _oversizeReason(diagram);
  if (reason != null) {
    return CcMermaidUnsupported(reason, dialect: dialect);
  }
  return CcMermaidParsed(diagram);
}

/// Ceilings past which a diagram is refused rather than drawn.
///
/// Layout runs on the UI thread, and its ordering/coordinate passes are
/// superlinear in the layer width; a machine-generated 5,000-node "diagram"
/// would freeze a frame for seconds and be illegible anyway. Above these caps
/// the source renders as a code block, which is both honest and instant.
const int kCcMermaidMaxNodes = 500;

/// Edge ceiling; see [kCcMermaidMaxNodes].
const int kCcMermaidMaxEdges = 1200;

/// Sequence-step ceiling; see [kCcMermaidMaxNodes].
const int kCcMermaidMaxSteps = 800;

/// Why a parsed diagram is refused, or null when it can be drawn.
String? _oversizeReason(CcMermaidDiagram diagram) {
  switch (diagram) {
    case final CcMermaidGraph graph:
      if (graph.nodes.length > kCcMermaidMaxNodes) {
        return 'diagram too large to draw (${graph.nodes.length} nodes)';
      }
      if (graph.edges.length > kCcMermaidMaxEdges) {
        return 'diagram too large to draw (${graph.edges.length} connections)';
      }
    case final CcMermaidSequence sequence:
      final steps = _countSteps(sequence.steps);
      if (steps > kCcMermaidMaxSteps) {
        return 'diagram too large to draw ($steps steps)';
      }
    case final CcMermaidTimeline timeline:
      if (timeline.entries.length > kCcMermaidMaxNodes) {
        return 'diagram too large to draw (${timeline.entries.length} entries)';
      }
    case CcMermaidPie():
      break;
  }
  return null;
}

int _countSteps(List<CcMermaidSequenceStep> steps) {
  var total = 0;
  for (final step in steps) {
    total++;
    if (step is CcMermaidBlock) {
      for (final section in step.sections) {
        total += _countSteps(section.steps);
      }
    }
  }
  return total;
}

/// Why a parsed diagram has nothing to draw, or null when it does.
String? _emptyReason(CcMermaidDiagram diagram) => switch (diagram) {
  CcMermaidGraph(:final nodes) when nodes.isEmpty => 'diagram has no nodes',
  CcMermaidSequence(:final participants) when participants.isEmpty =>
    'diagram has no participants',
  CcMermaidPie(:final slices) when slices.isEmpty => 'chart has no slices',
  CcMermaidPie(:final total) when total <= 0 => 'chart slices sum to zero',
  CcMermaidTimeline(:final entries) when entries.isEmpty =>
    'timeline has no entries',
  _ => null,
};

/// Small insertion-ordered LRU over parse results.
class _ParseMemo {
  _ParseMemo(this.capacity);

  final int capacity;
  final Map<String, CcMermaidParseResult> _entries = {};

  CcMermaidParseResult? get(String key) {
    final value = _entries.remove(key);
    if (value == null) {
      return null;
    }
    _entries[key] = value; // refresh recency
    return value;
  }

  void put(String key, CcMermaidParseResult value) {
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();
}

final _ParseMemo _memo = _ParseMemo(64);
