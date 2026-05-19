import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A dropdown selector that lets users pick which commits to scope the diff to.
class CommitRangeSelector extends ConsumerStatefulWidget {
  /// Creates a [CommitRangeSelector].
  const CommitRangeSelector({
    super.key,
    required this.commits,
    required this.selectedShas,
    required this.onSelectionChanged,
    this.totalCommitsCount = 0,
  });

  /// Available commits for selection.
  final List<PrCommit> commits;

  /// Currently selected commit SHAs.
  final Set<String> selectedShas;

  /// Callback invoked when the selection changes.
  final void Function(Set<String> shas)? onSelectionChanged;

  /// The true total number of commits from the PR detail. When greater than
  /// `commits.length`, a notice is shown in the overlay.
  final int totalCommitsCount;
  @override
  ConsumerState<CommitRangeSelector> createState() =>
      _CommitRangeSelectorState();
}

class _CommitRangeSelectorState extends ConsumerState<CommitRangeSelector> {
  final CcOverlayController _controller = CcOverlayController();
  int? _lastClickedIndex;
  late Set<String> _selectedShas;

  bool get _isAllSelected => _selectedShas.isEmpty;

  @override
  void initState() {
    super.initState();
    _selectedShas = widget.selectedShas;
    _controller.addListener(_onOverlayChanged);
  }

  @override
  void didUpdateWidget(covariant CommitRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedShas = widget.selectedShas;
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onOverlayChanged)
      ..dispose();
    super.dispose();
  }

  /// Restyles the trigger when the panel opens/closes.
  void _onOverlayChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _emit(Set<String> next) {
    _selectedShas = next;
    widget.onSelectionChanged?.call(next);
    setState(() {});
  }

  void _toggleAll() {
    if (_isAllSelected) {
      _lastClickedIndex = null;
      return;
    }
    _emit(<String>{});
    _lastClickedIndex = null;
  }

  void _toggleCommit(int index) {
    final commit = widget.commits[index];
    final sha = commit.sha;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final next = Set<String>.of(_selectedShas);
    if (shift && _lastClickedIndex != null) {
      final from = math.min(_lastClickedIndex!, index);
      final to = math.max(_lastClickedIndex!, index);
      for (var i = from; i <= to; i++) {
        next.add(widget.commits[i].sha);
      }
    } else {
      if (next.contains(sha)) {
        next.remove(sha);
      } else {
        next.add(sha);
      }
      _lastClickedIndex = index;
    }
    if (next.length == widget.commits.length) {
      next.clear();
    }
    _emit(next);
  }

  String _chipLabel() {
    final l10n = AppLocalizations.of(context);
    final commits = widget.commits;
    if (_selectedShas.isEmpty) {
      return l10n.allCommits;
    }

    if (_selectedShas.length == 1) {
      final sha = _selectedShas.first;
      final commit = commits.firstWhere(
        (c) => c.sha == sha,
        orElse: () => commits.first,
      );
      return commit.title.isEmpty ? commit.shortSha : commit.title;
    }
    return '${_selectedShas.length} commits';
  }

  String _chipVersionLabel() {
    final n = widget.commits.length;
    if (_selectedShas.isEmpty) {
      return 'v$n';
    }

    if (_selectedShas.length == 1) {
      final i = widget.commits.indexWhere((c) => c.sha == _selectedShas.first);
      if (i < 0) {
        return 'v$n';
      }

      return 'v${n - i}';
    }
    final indices = <int>[
      for (var i = 0; i < widget.commits.length; i++)
        if (_selectedShas.contains(widget.commits[i].sha)) i,
    ];
    final hi = n - indices.first;
    final lo = n - indices.last;
    return lo == hi ? 'v$hi' : 'v$lo–v$hi';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final codeFont = ref.watch(codeFontFamilyProvider);
    final isOpen = _controller.isOpen;
    return CcPopover(
      controller: _controller,
      semanticLabel: l10n.scopeDiffToCommits,
      target: CcTooltip(
        message: l10n.scopeDiffToCommits,
        child: Container(
          decoration: BoxDecoration(
            color: isOpen
                ? t.bgSecondary
                : t.bgSecondary.withValues(alpha: 0.6),
            borderRadius: AppRadii.brSm,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _VersionBadge(label: _chipVersionLabel(), codeFont: codeFont),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  _chipLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(AppIcons.chevronDown, size: 14, color: t.textTertiary),
            ],
          ),
        ),
      ),
      overlayBuilder: (context, _) => Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: _CommitMenuRow(
                versionLabel: 'v${widget.commits.length}',
                title: l10n.allCommits,
                relative: null,
                date: null,
                checked: _isAllSelected,
                onTap: _toggleAll,
                codeFont: codeFont,
              ),
            ),
            const CcDivider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.commits.length; i++)
                      _CommitMenuRow(
                        versionLabel: 'v${widget.commits.length - i}',
                        title: widget.commits[i].title.isEmpty
                            ? widget.commits[i].shortSha
                            : widget.commits[i].title,
                        relative: formatRelativeTime(
                          context,
                          widget.commits[i].date,
                        ),
                        date: widget.commits[i].date,
                        checked:
                            !_isAllSelected &&
                            _selectedShas.contains(widget.commits[i].sha),
                        onTap: () => _toggleCommit(i),
                        codeFont: codeFont,
                      ),
                  ],
                ),
              ),
            ),
            const CcDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.totalCommitsCount > widget.commits.length)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        l10n.commitsShowingLatest(
                          widget.commits.length,
                          widget.totalCommitsCount,
                        ),
                        style: TextStyle(fontSize: 11, color: t.textTertiary),
                      ),
                    ),
                  Row(
                    children: [
                      Icon(AppIcons.info, size: 12, color: t.textTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.shiftClickSelectRange,
                          style: TextStyle(fontSize: 11, color: t.textTertiary),
                        ),
                      ),
                      if (!_isAllSelected)
                        CcTappable(
                          onPressed: _toggleAll,
                          builder: (context, states) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text(
                              l10n.clear,
                              style: TextStyle(
                                fontSize: 11,
                                color: t.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The monospace `vN` version chip used in the trigger and menu rows.
class _VersionBadge extends StatelessWidget {
  const _VersionBadge({
    required this.label,
    required this.codeFont,
    this.checked = false,
  });

  final String label;
  final String codeFont;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: checked ? t.accent.withValues(alpha: 0.12) : t.bgPrimary,
        borderRadius: AppRadii.brSm,
        border: Border.all(
          color: checked ? t.accent.withValues(alpha: 0.3) : t.borderSecondary,
        ),
      ),
      child: Text(
        label,
        style: AppFonts.codeStyleDynamic(
          codeFont,
          fontSize: 11,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: checked ? t.accent : t.textSecondary,
        ),
      ),
    );
  }
}

class _CommitMenuRow extends StatelessWidget {
  const _CommitMenuRow({
    required this.versionLabel,
    required this.title,
    required this.relative,
    required this.date,
    required this.checked,
    required this.onTap,
    required this.codeFont,
  });
  final String versionLabel;
  final String title;
  final String? relative;
  final DateTime? date;
  final bool checked;
  final VoidCallback onTap;
  final String codeFont;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Container(
        color: states.contains(WidgetState.hovered)
            ? t.bgSecondary.withValues(alpha: 0.6)
            : const Color(0x00000000),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 7,
        ),
        child: Row(
          children: [
            IgnorePointer(
              child: CcCheckbox(value: checked, onChanged: (_) {}),
            ),
            const SizedBox(width: 10),
            _VersionBadge(
              label: versionLabel,
              codeFont: codeFont,
              checked: checked,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: t.textPrimary,
                  fontWeight: checked
                      ? FontWeight.w600
                      : CcTypography.regularWeight,
                ),
              ),
            ),
            if (relative != null) ...[
              const SizedBox(width: 12),
              if (date != null)
                AppTimestamp(
                  dateTime: date!,
                  child: Text(
                    relative!,
                    style: TextStyle(fontSize: 12, color: t.textTertiary),
                  ),
                )
              else
                Text(
                  relative!,
                  style: TextStyle(fontSize: 12, color: t.textTertiary),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
