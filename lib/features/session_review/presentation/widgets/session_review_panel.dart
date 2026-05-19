import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/diff_colors.dart';
import 'package:control_center/features/session_review/presentation/widgets/session_file_diff_view.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Localized labels for [SessionReviewPanel]. Defaults are English so the panel
/// works standalone (tests, gallery); the launching screen passes l10n strings.
class SessionReviewLabels {
  /// Creates [SessionReviewLabels].
  const SessionReviewLabels({
    this.title = 'Session changes',
    this.unified = 'Unified',
    this.split = 'Split',
    this.expandAll = 'Expand all',
    this.collapseAll = 'Collapse all',
    this.empty = 'No file changes in this session',
    this.added = 'Added',
    this.removed = 'Removed',
    this.renamed = 'Renamed',
    this.loading = 'Computing changes…',
  });

  /// Panel title.
  final String title;

  /// Unified toggle label.
  final String unified;

  /// Split toggle label.
  final String split;

  /// Expand-all action label.
  final String expandAll;

  /// Collapse-all action label.
  final String collapseAll;

  /// Empty-state message.
  final String empty;

  /// "Added" status label.
  final String added;

  /// "Removed" status label.
  final String removed;

  /// "Renamed" status label.
  final String renamed;

  /// Loading message.
  final String loading;
}

/// A file-by-file change-review panel: an accordion of the files an agent
/// session changed, each row showing a file icon, directory/filename split,
/// add/remove status and +/- counts, expanding to that file's diff. A header
/// carries a unified/split toggle and expand-all / collapse-all.
///
/// Answers "what did this agent session change?" before the changes are
/// committed. Pass [loading] while the changeset is being computed; the
/// no-changes case renders a built-in empty state.
class SessionReviewPanel extends StatefulWidget {
  /// Creates a [SessionReviewPanel].
  const SessionReviewPanel({
    super.key,
    required this.files,
    this.labels = const SessionReviewLabels(),
    this.loading = false,
    this.initiallyExpandedAll = false,
    this.diffColors,
  });

  /// The changed files, in display order.
  final List<PrFile> files;

  /// Localized labels.
  final SessionReviewLabels labels;

  /// Whether the changeset is still being computed.
  final bool loading;

  /// Whether every file starts expanded.
  final bool initiallyExpandedAll;

  /// Optional diff-color override (e.g. an imported VS Code theme), threaded to
  /// each file's diff so the panel matches the rest of CC's diff surfaces.
  final DiffColors? diffColors;

  @override
  State<SessionReviewPanel> createState() => _SessionReviewPanelState();
}

class _SessionReviewPanelState extends State<SessionReviewPanel> {
  late Set<String> _expanded;
  SessionDiffStyle _style = SessionDiffStyle.unified;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpandedAll
        ? widget.files.map((f) => f.filename).toSet()
        : <String>{};
  }

  void _toggle(String filename) {
    setState(() {
      if (!_expanded.remove(filename)) {
        _expanded.add(filename);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      if (_expanded.isNotEmpty) {
        _expanded = <String>{};
      } else {
        _expanded = widget.files.map((f) => f.filename).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = widget.labels;
    final hasFiles = widget.files.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          title: l.title,
          fileCount: widget.files.length,
          style: _style,
          labels: l,
          showActions: hasFiles,
          allExpanded: _expanded.isNotEmpty,
          onStyleChanged: (s) => setState(() => _style = s),
          onToggleAll: _toggleAll,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.loading)
          _LoadingState(message: l.loading)
        else if (!hasFiles)
          _EmptyState(message: l.empty)
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              primary: false,
              itemCount: widget.files.length,
              separatorBuilder: (_, _) =>
                  Container(height: 1, color: t.borderSecondary),
              itemBuilder: (context, i) {
                final file = widget.files[i];
                return _FileAccordion(
                  file: file,
                  labels: l,
                  style: _style,
                  diffColors: widget.diffColors,
                  expanded: _expanded.contains(file.filename),
                  onToggle: () => _toggle(file.filename),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.fileCount,
    required this.style,
    required this.labels,
    required this.showActions,
    required this.allExpanded,
    required this.onStyleChanged,
    required this.onToggleAll,
  });

  final String title;
  final int fileCount;
  final SessionDiffStyle style;
  final SessionReviewLabels labels;
  final bool showActions;
  final bool allExpanded;
  final ValueChanged<SessionDiffStyle> onStyleChanged;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.title.copyWith(color: t.textPrimary),
                ),
              ),
              if (fileCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                CcBadge(label: '$fileCount'),
              ],
            ],
          ),
        ),
        if (showActions) ...[
          SegmentedToggle<SessionDiffStyle>(
            value: style,
            onChanged: onStyleChanged,
            segments: [
              (value: SessionDiffStyle.unified, label: labels.unified),
              (value: SessionDiffStyle.split, label: labels.split),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: allExpanded
                ? AppIcons.chevronsDownUp
                : AppIcons.chevronsUpDown,
            onPressed: onToggleAll,
            child: Text(allExpanded ? labels.collapseAll : labels.expandAll),
          ),
        ],
      ],
    );
  }
}

class _FileAccordion extends StatelessWidget {
  const _FileAccordion({
    required this.file,
    required this.labels,
    required this.style,
    required this.expanded,
    required this.onToggle,
    this.diffColors,
  });

  final PrFile file;
  final SessionReviewLabels labels;
  final SessionDiffStyle style;
  final bool expanded;
  final VoidCallback onToggle;
  final DiffColors? diffColors;

  ({String dir, String name}) get _split {
    final i = file.filename.lastIndexOf('/');
    if (i < 0) {
      return (dir: '', name: file.filename);
    }
    return (
      dir: file.filename.substring(0, i + 1),
      name: file.filename.substring(i + 1),
    );
  }

  bool get _expandable => file.additions != 0 || file.deletions != 0;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final parts = _split;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcTappable(
          onPressed: _expandable ? onToggle : null,
          builder: (context, states) {
            final hovered = states.contains(WidgetState.hovered);
            return Container(
              color: hovered ? t.hover : null,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    _expandable
                        ? (expanded
                              ? AppIcons.chevronDown
                              : AppIcons.chevronRight)
                        : AppIcons.minus,
                    size: 14,
                    color: t.fgQuaternary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(AppIcons.file, size: 14, color: t.fgTertiary),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          if (parts.dir.isNotEmpty)
                            TextSpan(
                              text: parts.dir,
                              style: CcTypography.bodySm.copyWith(
                                color: t.textQuaternary,
                              ),
                            ),
                          TextSpan(
                            text: parts.name,
                            style: CcTypography.bodySm.copyWith(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatusLabel(status: file.status, labels: labels),
                  const SizedBox(width: AppSpacing.sm),
                  _ChangeCounts(
                    additions: file.additions,
                    deletions: file.deletions,
                  ),
                ],
              ),
            );
          },
        ),
        if (expanded && _expandable)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: SessionFileDiffView(
              patch: file.patch,
              style: style,
              diffColors: diffColors,
            ),
          ),
      ],
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status, required this.labels});

  final PrFileStatus status;
  final SessionReviewLabels labels;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      PrFileStatus.added => (labels.added, CcStatusTone.positive),
      PrFileStatus.removed => (labels.removed, CcStatusTone.negative),
      PrFileStatus.renamed => (labels.renamed, CcStatusTone.info),
      _ => (null, CcStatusTone.neutral),
    };
    if (label == null) {
      return const SizedBox.shrink();
    }
    return CcStatusTag(label: label, tone: tone, dot: false);
  }
}

class _ChangeCounts extends StatelessWidget {
  const _ChangeCounts({required this.additions, required this.deletions});

  final int additions;
  final int deletions;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (additions > 0)
          Text(
            '+$additions',
            style: CcTypography.caption.copyWith(
              color: t.textSuccessPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (additions > 0 && deletions > 0)
          const SizedBox(width: AppSpacing.xs),
        if (deletions > 0)
          Text(
            '-$deletions',
            style: CcTypography.caption.copyWith(
              color: t.textErrorPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CcSpinner(size: 16),
          const SizedBox(width: AppSpacing.sm),
          Text(
            message,
            style: CcTypography.bodySm.copyWith(color: t.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: CcTypography.bodySm.copyWith(color: t.textTertiary),
        ),
      ),
    );
  }
}
