import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/domain/value_objects/review_disagreement.dart';
import 'package:control_center/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_item.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A list of [ReviewAccordionItem]s with filtering and batch actions.
class ReviewAccordionList extends ConsumerStatefulWidget {
  /// Creates a [ReviewAccordionList].
  const ReviewAccordionList({
    super.key,
    required this.channelId,
    required this.pr,
    this.fetchFileContent,
  });

  /// Channel ID for fetching review messages.
  final String channelId;

  /// The pull request being reviewed.
  final PullRequest pr;

  /// Optional callback to fetch file content for anchored code blocks.
  final Future<String> Function(String path)? fetchFileContent;

  @override
  ConsumerState<ReviewAccordionList> createState() =>
      _ReviewAccordionListState();
}

class _ReviewAccordionListState extends ConsumerState<ReviewAccordionList> {
  final _selectedIds = <String>{};
  final _kindFilters = <ReviewNodeKind>{};
  final _statusFilters = <ReviewNodeStatus>{};
  bool _showDismissed = false;
  bool _selectionMode = false;

  @override
  Widget build(BuildContext context) {
    final asyncMessages = ref.watch(channelMessagesProvider(widget.channelId));

    return asyncMessages.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) => Center(
        child: Text(AppLocalizations.of(context).failedWithError('$e')),
      ),
      data: (messages) {
        final findings = parseAndSortFindings(messages);
        final filtered = _applyFilters(findings);
        final visible = _applyDismissedToggle(filtered);
        final disagreements = detectDisagreements(messages);

        if (findings.isEmpty) {
          return _buildEmpty(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (disagreements.isNotEmpty)
              _DisagreementsPanel(disagreements: disagreements),
            _buildFilterBar(context, findings),
            if (_selectionMode && _selectedIds.isNotEmpty)
              _buildBatchBar(context, visible),
            Expanded(
              child: ListView.builder(
                itemCount: visible.length + 1,
                itemBuilder: (context, index) {
                  if (index == visible.length) {
                    return _buildDismissedToggle(context, filtered);
                  }
                  final f = visible[index];
                  final id = f.message.id;
                  return ReviewAccordionItem(
                    key: ValueKey(id),
                    message: f.message,
                    payload: f.payload,
                    channelId: widget.channelId,
                    fetchFileContent: widget.fetchFileContent,
                    prNumber: widget.pr.number,
                    isSelected: _selectedIds.contains(id),
                    selectionMode: _selectionMode,
                    onToggleSelect: (v) => _toggleSelect(id, v),
                    onFix: () => _handleFix([f]),
                    onComment: () => _handleComment([f]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<ReviewFinding> _applyFilters(List<ReviewFinding> findings) {
    if (_kindFilters.isEmpty && _statusFilters.isEmpty) {
      return findings;
    }
    return findings.where((f) {
      if (_kindFilters.isNotEmpty && !_kindFilters.contains(f.payload.kind)) {
        return false;
      }
      if (_statusFilters.isNotEmpty &&
          !_statusFilters.contains(f.payload.status)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<ReviewFinding> _applyDismissedToggle(List<ReviewFinding> findings) {
    if (_showDismissed) {
      return findings;
    }
    return findings
        .where((f) => f.payload.status != ReviewNodeStatus.dismissed)
        .toList();
  }

  void _toggleSelect(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
        _selectionMode = true;
      } else {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _selectionMode = false;
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  void _selectAllVisible(List<ReviewFinding> visible) {
    setState(() {
      _selectedIds.clear();
      for (final f in visible) {
        _selectedIds.add(f.message.id);
      }
      _selectionMode = true;
    });
  }

  List<ReviewFinding> _selectedFindings(List<ReviewFinding> visible) {
    return visible.where((f) => _selectedIds.contains(f.message.id)).toList();
  }

  Future<void> _handleFix(List<ReviewFinding> findings) async {
    if (findings.isEmpty) {
      return;
    }
    final scaffold = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    final blocks = findings
        .map((f) {
          final p = f.payload;
          final line = p.anchor.lineEnd != null
              ? ':${p.anchor.lineNumber}-${p.anchor.lineEnd}'
              : p.anchor.lineNumber != null
              ? ':${p.anchor.lineNumber}'
              : '';
          final file = p.anchor.filePath ?? 'unknown';
          final conf = (p.confidence * 100).round();
          return '[${p.kind.name.toUpperCase()} · ${p.priority.name.toUpperCase()} · $conf%] $file$line\n${f.message.content}';
        })
        .join('\n\n');

    final prompt =
        'Please address the following review findings, then summarize what changed:\n\n$blocks';

    try {
      final dispatchService = ref.read(agentDispatchServiceProvider);
      final firstSender = findings.first.message.senderId;
      final agent = await ref.read(agentDetailProvider(firstSender).future);
      final workspace = ref.read(activeWorkspaceProvider);
      final fsPort = ref.read(workspaceFilesystemPortProvider);

      String workingDir = '/tmp';
      if (workspace != null) {
        try {
          workingDir = (await fsPort.workspaceDir(workspace.id)).path;
        } catch (_) {}
      }

      await dispatchService.dispatch(
        agentId: agent?.id ?? firstSender,
        prompt: prompt,
        workingDirectory: workingDir,
        workspaceId: workspace?.id,
        channelId: widget.channelId,
        conversationId: widget.channelId,
      );

      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.sentFindingsToAgent(findings.length))),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.failedToDispatch('$e'))),
      );
    }
  }

  Future<void> _handleComment(List<ReviewFinding> findings) async {
    final scaffold = ScaffoldMessenger.of(context);
    final useCase = ref.read(reviewPullRequestUseCaseProvider);

    var posted = 0;
    var skipped = 0;
    final errors = <String>[];

    for (final f in findings) {
      final p = f.payload;
      if (p.anchor.filePath == null || p.anchor.lineNumber == null) {
        skipped++;
        continue;
      }
      try {
        await useCase.postComment(
          prNumber: widget.pr.number,
          commitSha: widget.pr.headSha,
          path: p.anchor.filePath!,
          line: p.anchor.lineEnd ?? p.anchor.lineNumber!,
          side: 'RIGHT',
          body: f.message.content,
          startLine: p.anchor.lineEnd != null ? p.anchor.lineNumber : null,
        );
        posted++;
      } catch (e) {
        errors.add(e.toString());
      }
    }

    final parts = <String>[];
    if (posted > 0) {
      parts.add('Posted $posted comment(s)');
    }
    if (skipped > 0) {
      parts.add('$skipped skipped (no file anchor)');
    }
    if (errors.isNotEmpty) {
      parts.add('${errors.length} failed');
    }

    scaffold.showSnackBar(SnackBar(content: Text('${parts.join('. ')}.')));
  }

  Widget _buildEmpty(BuildContext context) {
    final tokens = context.designSystem!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.share2, size: 48, color: tokens.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No review findings yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Findings will appear as agents post review nodes.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, List<ReviewFinding> all) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Kind:',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: tokens.textTertiary),
          ),
          for (final kind in [
            ReviewNodeKind.bug,
            ReviewNodeKind.suggestion,
            ReviewNodeKind.recommendation,
            ReviewNodeKind.question,
          ])
            _FilterChip(
              label: kind.name[0].toUpperCase() + kind.name.substring(1),
              active: _kindFilters.contains(kind),
              onTap: () => _toggleKindFilter(kind),
            ),
          const SizedBox(width: 8),
          Text(
            'Status:',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: tokens.textTertiary),
          ),
          for (final status in [
            ReviewNodeStatus.open,
            ReviewNodeStatus.consensusReady,
            ReviewNodeStatus.resolved,
          ])
            _FilterChip(
              label: _statusLabel(status),
              active: _statusFilters.contains(status),
              onTap: () => _toggleStatusFilter(status),
            ),
          const SizedBox(width: 8),
          if (_selectionMode) ...[
            FButton(
              size: FButtonSizeVariant.sm,
              variant: FButtonVariant.outline,
              onPress: () {
                final visible = _applyDismissedToggle(_applyFilters(all));
                if (_selectedIds.length == visible.length) {
                  _clearSelection();
                } else {
                  _selectAllVisible(visible);
                }
              },
              child: Text(
                _selectedIds.length ==
                        _applyDismissedToggle(_applyFilters(all)).length
                    ? 'Clear selection'
                    : 'Select all visible',
              ),
            ),
            FButton(
              size: FButtonSizeVariant.sm,
              variant: FButtonVariant.outline,
              onPress: _clearSelection,
              child: Text(l10n.exitSelection),
            ),
          ] else
            FButton(
              size: FButtonSizeVariant.sm,
              variant: FButtonVariant.outline,
              onPress: () => setState(() => _selectionMode = true),
              prefix: const Icon(LucideIcons.checkSquare, size: 12),
              child: Text(l10n.selectLabel),
            ),
        ],
      ),
    );
  }

  String _statusLabel(ReviewNodeStatus s) => switch (s) {
    ReviewNodeStatus.open => AppLocalizations.of(context).openStatus,
    ReviewNodeStatus.consensusReady => AppLocalizations.of(context).consensus,
    ReviewNodeStatus.resolved => AppLocalizations.of(context).resolved,
    ReviewNodeStatus.dismissed => AppLocalizations.of(context).dismissed,
  };

  void _toggleKindFilter(ReviewNodeKind kind) {
    setState(() {
      if (_kindFilters.contains(kind)) {
        _kindFilters.remove(kind);
      } else {
        _kindFilters.add(kind);
      }
      _selectionMode = _selectionMode || _kindFilters.isNotEmpty;
    });
  }

  void _toggleStatusFilter(ReviewNodeStatus status) {
    setState(() {
      if (_statusFilters.contains(status)) {
        _statusFilters.remove(status);
      } else {
        _statusFilters.add(status);
      }
      _selectionMode = _selectionMode || _statusFilters.isNotEmpty;
    });
  }

  Widget _buildBatchBar(BuildContext context, List<ReviewFinding> visible) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final selected = _selectedFindings(visible);
    final canCommentAll = selected.every(
      (f) =>
          f.payload.anchor.filePath != null &&
          f.payload.anchor.lineNumber != null,
    );
    final someAnchored = selected.any(
      (f) =>
          f.payload.anchor.filePath != null &&
          f.payload.anchor.lineNumber != null,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.bgBrandPrimary.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      child: Row(
        children: [
          Text(
            '${selected.length} selected',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tokens.fgBrandPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          FButton(
            size: FButtonSizeVariant.sm,
            variant: FButtonVariant.primary,
            onPress: selected.isNotEmpty ? () => _handleFix(selected) : null,
            prefix: const Icon(LucideIcons.wrench, size: 14),
            child: Text(l10n.fixSelected),
          ),
          const SizedBox(width: 6),
          if (!someAnchored)
            FTooltip(
              tipBuilder: (_, _) => const Text(
                'No file anchor on any selected item — cannot post inline comments.',
              ),
              child: FButton(
                size: FButtonSizeVariant.sm,
                variant: FButtonVariant.outline,
                onPress: null,
                prefix: const Icon(LucideIcons.messageSquarePlus, size: 14),
                child: Text(l10n.commentSelected),
              ),
            )
          else if (!canCommentAll)
            FTooltip(
              tipBuilder: (_, _) => const Text(
                'Some selected items lack file anchors and will be skipped.',
              ),
              child: FButton(
                size: FButtonSizeVariant.sm,
                variant: FButtonVariant.outline,
                onPress: () => _handleComment(selected),
                prefix: const Icon(LucideIcons.messageSquarePlus, size: 14),
                child: Text(l10n.commentSelected),
              ),
            )
          else
            FButton(
              size: FButtonSizeVariant.sm,
              variant: FButtonVariant.outline,
              onPress: () => _handleComment(selected),
              prefix: const Icon(LucideIcons.messageSquarePlus, size: 14),
              child: Text(l10n.commentSelected),
            ),
        ],
      ),
    );
  }

  Widget _buildDismissedToggle(
    BuildContext context,
    List<ReviewFinding> filtered,
  ) {
    final dismissed = filtered
        .where((f) => f.payload.status == ReviewNodeStatus.dismissed)
        .length;
    if (dismissed == 0) {
      return const SizedBox.shrink();
    }

    final tokens = context.designSystem!;
    return GestureDetector(
      onTap: () => setState(() => _showDismissed = !_showDismissed),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        color: tokens.bgSecondary.withValues(alpha: 0.3),
        child: Center(
          child: Text(
            _showDismissed
                ? 'Hide $dismissed dismissed'
                : 'Show $dismissed dismissed',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tokens.textTertiary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? tokens.bgBrandPrimary.withValues(alpha: 0.15)
              : tokens.bgSecondary,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active ? tokens.fgBrandPrimary : tokens.borderSecondary,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: active ? tokens.fgBrandPrimary : tokens.textPrimary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _DisagreementsPanel extends StatefulWidget {
  const _DisagreementsPanel({required this.disagreements});
  final List<ReviewDisagreement> disagreements;

  @override
  State<_DisagreementsPanel> createState() => _DisagreementsPanelState();
}

class _DisagreementsPanelState extends State<_DisagreementsPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 13,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.disagreements.length} reviewer disagreement'
                    '${widget.disagreements.length == 1 ? '' : 's'} detected',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 13,
                    color: colors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            for (final d in widget.disagreements)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.anchor,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${d.nodeA.senderId} ↔ ${d.nodeB.senderId}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
