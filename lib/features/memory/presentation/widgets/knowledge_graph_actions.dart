part of 'knowledge_graph.dart';

extension _ActionMethods on _KnowledgeGraphState {
  /// Reconcile the [ValueNotifier] position store with the freshly computed
  /// [positions]: reuse notifiers for surviving keys (updating their value),
  /// create notifiers for new keys and dispose notifiers for removed keys.
  ///
  /// Removed notifiers are disposed in a post-frame callback so we never
  /// dispose one while a [ValueListenableBuilder] still listens to it during
  /// this frame's rebuild.
  void _syncPositions(Map<String, Offset> positions) {
    final removed = _positions.keys
        .where((key) => !positions.containsKey(key))
        .toList();
    final orphaned = <ValueNotifier<Offset>>[];
    for (final key in removed) {
      orphaned.add(_positions.remove(key)!);
      _pinned.remove(key);
    }

    for (final entry in positions.entries) {
      final existing = _positions[entry.key];
      if (existing != null) {
        // A node the operator moved keeps its place across data refreshes.
        if (!_pinned.contains(entry.key)) {
          existing.value = entry.value;
        }
      } else {
        _positions[entry.key] = ValueNotifier<Offset>(entry.value);
      }
    }

    if (orphaned.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final notifier in orphaned) {
          notifier.dispose();
        }
      });
    }
  }

  void _showNodeSheet(BuildContext context, String key) {
    final data = _nodeData[key];
    if (data == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => KnowledgeGraphNodeSheet(
        nodeData: data,
        workspaceId: widget.workspaceId,
        onEditFact: data.type == NodeType.fact
            ? () => _editFact(context, data.fact!)
            : null,
        onDeleteFact: data.type == NodeType.fact
            ? () => _deleteFact(context, data.fact!)
            : null,
        onEditPolicy: data.type == NodeType.policy
            ? () => _editPolicy(context, data.policy!)
            : null,
        onDeletePolicy: data.type == NodeType.policy
            ? () => _deletePolicy(context, data.policy!)
            : null,
        onTogglePolicy: data.type == NodeType.policy
            ? () => _togglePolicy(data.policy!)
            : null,
      ),
    );
  }

  Future<void> _editFact(BuildContext context, MemoryFact fact) async {
    final edited = await showDialog<MemoryFact>(
      context: context,
      builder: (_) => FactEditDialog(fact: fact),
    );
    if (edited == null) {
      return;
    }
    final repo = ref.read(memoryFactRepositoryProvider);
    await repo.upsert(edited);
  }

  Future<void> _deleteFact(BuildContext context, MemoryFact fact) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.deleteFact,
        content: Text(l10n.deleteTopicConfirm(fact.topic)),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final repo = ref.read(memoryFactRepositoryProvider);
    await repo.delete(fact.workspaceId, fact.id);
  }

  Future<void> _editPolicy(BuildContext context, MemoryPolicy policy) async {
    final edited = await showDialog<MemoryPolicy>(
      context: context,
      builder: (_) => PolicyEditDialog(policy: policy),
    );
    if (edited == null) {
      return;
    }
    final repo = ref.read(memoryPolicyRepositoryProvider);
    await repo.upsert(edited);
  }

  Future<void> _deletePolicy(BuildContext context, MemoryPolicy policy) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.deletePolicy,
        content: Text(l10n.deletePolicyConfirm),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final repo = ref.read(memoryPolicyRepositoryProvider);
    await repo.delete(policy.workspaceId, policy.id);
  }

  Future<void> _togglePolicy(MemoryPolicy policy) async {
    final repo = ref.read(memoryPolicyRepositoryProvider);
    await repo.upsert(policy.copyWith(active: !policy.active));
  }
}
