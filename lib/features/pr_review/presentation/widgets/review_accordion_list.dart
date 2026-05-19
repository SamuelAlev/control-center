import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_disagreement.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_item.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_dispatch_bindings.dart';
import 'package:control_center/features/pr_review/providers/review_filter_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets a host run the list's batch actions from outside it, and holds the
/// checkbox selection both sides read.
///
/// The review artifact's action bar owns the "fix" / "comment" affordances
/// but not the findings, the prompt or the dispatch — duplicating those there
/// would be a second implementation of each verb that drifts from this one.
/// The selection lives here rather than in the list so the bar's labels can
/// track what the checkboxes below are doing: an EMPTY set is the default
/// scope (every open P0–P2 finding), a non-empty set is the exact subset the
/// verbs act on.
class ReviewAccordionController extends ChangeNotifier {
  /// The command a host has asked for, consumed by the list on its next build.
  _AccordionCommand? _pending;

  final Set<String> _selectedIds = <String>{};

  /// The ticked findings' message ids, in no particular order.
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  /// Ticks or unticks one finding's checkbox.
  void toggleSelected(String id, bool selected) {
    final changed = selected ? _selectedIds.add(id) : _selectedIds.remove(id);
    if (changed) {
      notifyListeners();
    }
  }

  /// Unticks everything, returning the bulk verbs to their default scope.
  void clearSelection() {
    if (_selectedIds.isEmpty) {
      return;
    }
    _selectedIds.clear();
    notifyListeners();
  }

  /// Hands the given findings to an agent that fixes them and pushes.
  ///
  /// A command rather than a method on the findings themselves, because a
  /// host button that only ARMED something further down the page read as
  /// doing nothing: the press was answered by checkboxes below the fold and
  /// the batch bar that would have run the fix was off-screen.
  void fixFindings(List<String> ids) {
    _pending = _AccordionFix(ids);
    notifyListeners();
  }

  /// Posts the given findings to the pull request as inline comments.
  void commentFindings(List<String> ids) {
    _pending = _AccordionComment(ids);
    notifyListeners();
  }

  /// Takes the pending command, leaving none behind. The list calls this on
  /// its next build; a command left in place would re-fire on the next
  /// selection notify.
  _AccordionCommand? _consumeCommand() {
    final command = _pending;
    _pending = null;
    return command;
  }
}

/// What a host asked the findings list to do.
sealed class _AccordionCommand {
  const _AccordionCommand();
}

/// Fix the findings with these message ids.
class _AccordionFix extends _AccordionCommand {
  const _AccordionFix(this.ids);
  final List<String> ids;
}

/// Comment the findings with these message ids onto the pull request.
class _AccordionComment extends _AccordionCommand {
  const _AccordionComment(this.ids);
  final List<String> ids;
}

/// The findings list: filters, batch actions and the disagreements panel.
class ReviewAccordionList extends ConsumerStatefulWidget {
  /// Creates a [ReviewAccordionList].
  const ReviewAccordionList({
    super.key,
    required this.spaceId,
    required this.pr,
    this.fetchFileContent,
    this.findingsFilter,
    this.controller,
    this.leadingSlivers = const [],
    this.scrollController,
    this.itemKeys,
  });

  /// Optional imperative hook for a host that owns a batch affordance.
  final ReviewAccordionController? controller;

  /// Space ID for fetching review messages.
  final String spaceId;

  /// The pull request being reviewed.
  final PullRequest pr;

  /// Optional callback to fetch file content for anchored code blocks.
  final Future<String> Function(String path)? fetchFileContent;

  /// Optional scope applied before the UI filters; null renders every finding
  /// of the space.
  final bool Function(ReviewFinding finding)? findingsFilter;

  /// Slivers rendered ABOVE the disagreements panel and the filter bar — the
  /// review's report, in practice.
  ///
  /// The report and the findings share ONE scroll rather than sitting in two
  /// stacked viewports: they are one document (here is what the review
  /// concluded, here is every finding behind it), and two scrollbars for one
  /// reading order is the arrangement that made the old tab feel bolted
  /// together.
  final List<Widget> leadingSlivers;

  /// Drives that shared scroll, so a host rail can bring a finding into view.
  final ScrollController? scrollController;

  /// Per-finding keys the host uses to scroll to one. Populated during build.
  final Map<String, GlobalKey>? itemKeys;

  @override
  ConsumerState<ReviewAccordionList> createState() =>
      _ReviewAccordionListState();
}

class _ReviewAccordionListState extends ConsumerState<ReviewAccordionList> {
  /// The selection/command bus, owned here when the host did not hand one in.
  late final ReviewAccordionController _ownedController =
      ReviewAccordionController();

  ReviewAccordionController get _controller =>
      widget.controller ?? _ownedController;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(ReviewAccordionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownedController).removeListener(
        _onControllerChanged,
      );
      _controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _ownedController.dispose();
    }
    super.dispose();
  }

  /// Selection toggles and host commands both arrive as notifies; the rebuild
  /// reads the new checkbox states and consumes any pending command.
  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMessages = ref.watch(spaceWideMessagesProvider(widget.spaceId));

    return asyncMessages.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => Center(
        child: Text(AppLocalizations.of(context).failedWithError('$e')),
      ),
      data: (messages) {
        final scope = widget.findingsFilter;
        final findings = scope == null
            ? parseAndSortFindings(messages)
            : parseAndSortFindings(messages).where(scope).toList();
        final visible = _visible(findings);
        final disagreements = detectDisagreements(messages);

        final command = _controller._consumeCommand();
        if (command != null) {
          final targets = switch (command) {
            _AccordionFix(:final ids) => ids,
            _AccordionComment(:final ids) => ids,
          };
          final targetsSet = targets.toSet();
          final selected = [
            for (final f in findings)
              if (targetsSet.contains(f.message.id)) f,
          ];
          if (selected.isNotEmpty) {
            // Applied after this frame: running a dispatch during build would
            // be a setState-in-build.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              switch (command) {
                case _AccordionFix():
                  unawaited(_handleFix(selected));
                case _AccordionComment():
                  unawaited(_handleComment(selected));
              }
            });
          }
        }

        if (findings.isEmpty) {
          return _buildEmpty(context);
        }

        final keys = widget.itemKeys;
        if (keys != null) {
          // Keys are STABLE per finding: the row mounts its key inside a
          // pinned-header delegate build, which runs during LAYOUT — a fresh
          // key per build would unmount and remount the row's subtree
          // mid-layout on every streamed message.
          final visibleIds = {for (final f in visible) f.message.id};
          keys.removeWhere((id, _) => !visibleIds.contains(id));
        }

        return CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            // The report, when a host supplied one.
            ...widget.leadingSlivers,
            // Disagreements sit between the report and the findings: they are
            // about the findings below, and a reader who has just read the
            // conclusion needs to know two reviewers did not agree on it
            // BEFORE working down the list.
            if (disagreements.isNotEmpty)
              SliverToBoxAdapter(
                child: _DisagreementsPanel(disagreements: disagreements),
              ),
            // ONE SLIVER PER FINDING rather than rows inside a single
            // SliverList: each finding pins its own header over its own body,
            // so the row telling you which finding you are reading stays put
            // while a screenful of code and discussion scrolls under it. The
            // diff does the same thing with a file header over its hunks.
            for (final f in visible)
              ReviewAccordionItem(
                key: ValueKey(f.message.id),
                anchorKey: keys?.putIfAbsent(f.message.id, GlobalKey.new),
                sliver: true,
                message: f.message,
                payload: f.payload,
                spaceId: widget.spaceId,
                fetchFileContent: widget.fetchFileContent,
                prNumber: widget.pr.number,
                isSelected: _controller.selectedIds.contains(f.message.id),
                onToggleSelect: (v) =>
                    _controller.toggleSelected(f.message.id, v),
                onFix: () => _handleFix([f]),
                onComment: () => _handleComment([f]),
              ),
            SliverToBoxAdapter(child: _buildDismissedToggle(context, findings)),
          ],
        );
      },
    );
  }

  /// The space's filters, applied through the shared helper so the rail's
  /// counts and these rows can never disagree about what is showing.
  List<ReviewFinding> _visible(List<ReviewFinding> findings) =>
      applyReviewFilters(
        findings,
        kindOf: (f) => f.payload.kind,
        statusOf: (f) => f.payload.status,
        kinds: ref.watch(reviewKindFilterProvider(widget.spaceId)),
        statuses: ref.watch(reviewStatusFilterProvider(widget.spaceId)),
        showDismissed: ref.watch(reviewShowDismissedProvider(widget.spaceId)),
      );

  Future<void> _handleFix(List<ReviewFinding> findings) async {
    if (findings.isEmpty) {
      return;
    }
    final toaster = CcToastScope.of(context);
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
          // The id travels with the finding because the agent needs it to
          // close the loop below — without it the fix lands and the finding
          // stays open forever, which is how a review's action rate ends up
          // measuring how diligent a human was about bookkeeping.
          return '[${p.kind.name.toUpperCase()} · ${p.priority.name.toUpperCase()} · $conf%] $file$line\n'
              'finding id: ${f.message.id}\n${f.message.content}';
        })
        .join('\n\n');

    // The agent runs in the review space's worktree, which IS the PR branch
    // checked out at its head — so finishing the job means landing the fix on
    // the PR, not leaving edits in a directory nobody looks at. Pushing is
    // spelled out because "address these findings" had produced exactly that:
    // a correct fix that never reached the pull request.
    final prompt =
        'Address the following review findings in the checked-out worktree.\n\n'
        '$blocks\n\n'
        'When the fixes are done and the project builds:\n'
        '1. Commit them with a message naming what the findings were.\n'
        '2. Push to the pull request branch this worktree is on (it is already '
        'the PR head — do NOT create a new branch or open a second PR).\n'
        '3. Reply with a summary of what changed and what you pushed.\n\n'
        'If a finding is wrong or you disagree, do not change the code for it — '
        'say so in your reply and leave it for the reviewer.\n\n'
        'Then close each finding out, using its "finding id" above:\n'
        '- `resolve_review_node` for every one you actually fixed.\n'
        '- `dismiss_review_node` for one that does not apply, with the general '
        'rule as the reason so future reviews stop raising it.\n'
        'Leave anything you neither fixed nor rejected alone — an open finding '
        'is the honest state for work you did not do.';

    try {
      final firstSender = findings.first.message.senderId;
      final agent = await ref.read(agentDetailProvider(firstSender).future);
      final workspace = ref.read(activeWorkspaceProvider);
      final fsPort = ref.read(workspaceFilesystemPortProvider);

      String workingDir = '/tmp';
      if (workspace != null) {
        try {
          workingDir = await fsPort.workspaceDir(workspace.id);
        } catch (_) {
          // Fall back to the /tmp default set above.
        }
      }

      // Branch the fix into a fresh conversation (N3) so it stays off the main
      // review conversation — the user can watch/steer it in the PR chat tab's
      // conversation switcher. Falls back to main if the workspace is unknown.
      String? conversationId;
      if (workspace != null) {
        final anchor = findings.first.payload.anchor.filePath;
        final loc = anchor != null
            ? anchor.split('/').last
            : l10n.reviewFindings;
        final title = l10n.fixFindingTitle(loc);
        final conv = await ref
            .read(conversationRepositoryProvider)
            .create(
              workspaceId: workspace.id,
              spaceId: widget.spaceId,
              title: title,
            );
        conversationId = conv.id;
      }

      // Agent dispatch is desktop-only (spawns a local sandboxed process); the
      // seam throws an honest "not available on web" on the web target.
      await dispatchReviewFeedbackAgent(
        ref,
        agentId: agent?.id ?? firstSender,
        prompt: prompt,
        workingDir: workingDir,
        workspaceId: workspace?.id,
        spaceId: widget.spaceId,
        conversationId: conversationId,
      );

      toaster.show(
        l10n.sentFindingsToAgent(findings.length),
        variant: CcToastVariant.success,
      );
    } catch (e) {
      toaster.show(l10n.failedToDispatch('$e'), variant: CcToastVariant.danger);
    }
  }

  /// Posts findings to the pull request as inline comments, under the app
  /// identity.
  ///
  /// One server call rather than one per finding, and the bodies are read
  /// SERVER-side from the stored review nodes: the comments are an agent's
  /// words, so they go out as the app rather than under the account of whoever
  /// pressed the button. Sending the text from here would make that attribution
  /// a claim the client makes about itself.
  Future<void> _handleComment(List<ReviewFinding> findings) async {
    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final parts = widget.pr.repoFullName.split('/');
    if (workspaceId == null || findings.isEmpty || parts.length < 2) {
      return;
    }
    try {
      final result = await ref.read(rpcClientProvider).call(
        'pr_review.commentFindings',
        {
          'workspace_id': workspaceId,
          'space_id': widget.spaceId,
          'owner': parts.first,
          'repo': parts.sublist(1).join('/'),
          'pr_number': widget.pr.number,
          'commit_sha': widget.pr.headSha,
          'message_ids': [for (final f in findings) f.message.id],
        },
      );
      if (!mounted) {
        return;
      }
      toaster.show(
        l10n.reviewCommentsPosted(
          (result['posted'] as num?)?.toInt() ?? 0,
          (result['skipped'] as num?)?.toInt() ?? 0,
          (result['failed'] as num?)?.toInt() ?? 0,
        ),
      );
      // Reported separately from `failed`, because it is not a failure and it
      // has a fix the reviewer can act on: GitHub hangs an inline comment only
      // on the diff, so a finding about code the PR leaves alone has nowhere to
      // go. Naming the files is the whole point — "2 failed" sent the operator
      // to the server log to find out which.
      final outOfDiff = (result['outOfDiff'] as num?)?.toInt() ?? 0;
      if (outOfDiff > 0) {
        final paths = [
          for (final p in (result['outOfDiffPaths'] as List? ?? const []))
            if (p is String) p,
        ];
        toaster.show(
          l10n.reviewFindingsOutOfDiff(outOfDiff, paths.join(', ')),
          variant: CcToastVariant.warning,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      toaster.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
    }
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcEmptyState(
      icon: AppIcons.share2,
      message: l10n.reviewNoFindingsTitle,
      description: l10n.reviewNoFindingsHint,
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

    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem!;
    final showDismissed = ref.watch(
      reviewShowDismissedProvider(widget.spaceId),
    );
    // A real hoverable control rather than a tinted strip with link text in it:
    // the strip gave no hover feedback and no focus ring, so the one affordance
    // at the foot of a fifty-row list looked like a caption.
    return CcTappable(
      onPressed: () => ref
          .read(reviewShowDismissedProvider(widget.spaceId).notifier)
          .update((v) => !v),
      semanticLabel: showDismissed
          ? l10n.reviewHideDismissed(dismissed)
          : l10n.reviewShowDismissed(dismissed),
      builder: (context, states) => ColoredBox(
        color: states.contains(WidgetState.hovered)
            ? tokens.hover
            : tokens.hover.withValues(alpha: 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          child: Center(
            child: Text(
              showDismissed
                  ? l10n.reviewHideDismissed(dismissed)
                  : l10n.reviewShowDismissed(dismissed),
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
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
    final tokens = context.designSystem!;
    // Token warn, not `Colors.amber`: the raw Material swatch is a cool-shifted
    // yellow that belongs to no theme here, it never darkened for dark mode,
    // and at 0.06 alpha its own label sat well under the contrast floor.
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        color: tokens.warnSoft,
        border: Border.all(color: tokens.warn.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcTappable(
            onPressed: () => setState(() => _expanded = !_expanded),
            builder: (context, states) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(AppIcons.alertTriangle, size: 14, color: tokens.warn),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).reviewDisagreementsDetected(
                        widget.disagreements.length,
                      ),
                      style: CcTypography.bodySm.copyWith(color: tokens.warn),
                    ),
                  ),
                  Icon(
                    _expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                    size: 14,
                    color: tokens.warn,
                  ),
                ],
              ),
            ),
          ),
          // Rows inside the panel, separated by rules rather than boxed one by
          // one: a card inside a card is exactly what the design system rules
          // out, and three of them stacked read as a pile rather than a list.
          if (_expanded)
            for (final d in widget.disagreements) ...[
              CcDivider(color: tokens.warn.withValues(alpha: 0.25)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.anchor,
                      style: CcFonts.code(
                        textStyle: CcTypography.caption,
                      ).copyWith(color: tokens.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      d.description,
                      style: CcTypography.bodySm.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${d.nodeA.senderId} ↔ ${d.nodeB.senderId}',
                      style: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
