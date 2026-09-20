import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:flutter/widgets.dart';

/// Node sizes. Sized so labels stay legible without zooming.
const domainNodeSize = Size(148, 86);

/// Size of a topic node on the knowledge graph canvas.
const topicNodeSize = Size(152, 64);

/// Size of a fact node on the knowledge graph canvas.
const factNodeSize = Size(184, 116);

/// Size of a policy node on the knowledge graph canvas.
const policyNodeSize = Size(168, 96);

/// Slack between a cluster's outermost card and its hull.
const hullPadding = 26.0;

/// The type of a node in the knowledge graph.
enum NodeType {
  /// A memory domain grouping related topics.
  domain,

  /// A topic or category within a domain.
  topic,

  /// A fact assertion stored in the knowledge base.
  fact,

  /// A policy rule governing memory access or behavior.
  policy,
}

/// Data payload carried by each node in the knowledge graph.
class NodeData {
  /// Creates a [NodeData] with the required [type].
  const NodeData({
    required this.type,
    this.domainSlug,
    this.domainLabel,
    this.topic,
    this.fact,
    this.policy,
    this.factCount = 0,
    this.policyCount = 0,
    this.supersededFacts = const [],
  });

  /// The kind of knowledge graph node.
  final NodeType type;

  /// The machine-readable domain identifier.
  final String? domainSlug;

  /// The human-readable domain label.
  final String? domainLabel;

  /// The topic name.
  final String? topic;

  /// The fact associated with this node, when [type] is [NodeType.fact].
  final MemoryFact? fact;

  /// The policy associated with this node, when [type] is [NodeType.policy].
  final MemoryPolicy? policy;

  /// Number of facts grouped under this node.
  final int factCount;

  /// Number of policies grouped under this node.
  final int policyCount;

  /// Facts that were superseded by the current fact.
  final List<MemoryFact> supersededFacts;
}
