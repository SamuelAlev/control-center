/// One node of a conversation's branch tree.
class ConversationTreeNode {
  /// Creates a [ConversationTreeNode].
  const ConversationTreeNode({
    required this.messageId,
    required this.parentMessageId,
    required this.senderType,
    required this.senderId,
    required this.preview,
    required this.createdAt,
    required this.onCurrentBranch,
    this.childCount = 0,
    this.label,
  });

  /// The message.
  final String messageId;

  /// What it continues from, or null at a root.
  final String? parentMessageId;

  /// `user` / `agent` / `system`.
  final String senderType;

  /// Who wrote it.
  final String senderId;

  /// The first line or so, for the navigator.
  final String preview;

  /// When it was written.
  final DateTime createdAt;

  /// Whether it is on the branch the conversation is currently showing.
  final bool onCurrentBranch;

  /// How many messages continue from it.
  ///
  /// The only thing that makes a node a BRANCH POINT rather than a step: a
  /// count above one is where the conversation forked, and it is the only
  /// thing a navigator has to draw differently.
  final int childCount;

  /// An optional human label, for a branch worth naming.
  final String? label;

  /// Whether this node is where the conversation forked.
  bool get isBranchPoint => childCount > 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationTreeNode &&
          other.messageId == messageId &&
          other.parentMessageId == parentMessageId &&
          other.senderType == senderType &&
          other.senderId == senderId &&
          other.preview == preview &&
          other.createdAt == createdAt &&
          other.onCurrentBranch == onCurrentBranch &&
          other.childCount == childCount &&
          other.label == label;

  @override
  int get hashCode => Object.hash(
    messageId,
    parentMessageId,
    senderType,
    senderId,
    preview,
    createdAt,
    onCurrentBranch,
    childCount,
    label,
  );
}

/// A conversation's whole tree, plus where it is currently pointing.
class ConversationTree {
  /// Creates a [ConversationTree].
  const ConversationTree({
    required this.nodes,
    required this.leafMessageId,
    required this.branchCount,
  });

  /// Every message, oldest first.
  final List<ConversationTreeNode> nodes;

  /// The tip of the branch currently shown, or null for an empty conversation.
  final String? leafMessageId;

  /// How many distinct leaves the tree has — how many paths exist.
  final int branchCount;

  /// The path from root to the current leaf.
  List<ConversationTreeNode> get currentBranch =>
      [for (final node in nodes) if (node.onCurrentBranch) node];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationTree &&
          other.leafMessageId == leafMessageId &&
          other.branchCount == branchCount &&
          _sameNodes(other.nodes, nodes);

  @override
  int get hashCode =>
      Object.hash(leafMessageId, branchCount, Object.hashAll(nodes));

  static bool _sameNodes(
    List<ConversationTreeNode> a,
    List<ConversationTreeNode> b,
  ) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
