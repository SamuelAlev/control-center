import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlay;
  int? _lastClickedIndex;
  late Set<String> _selectedShas;

  bool get _isAllSelected => _selectedShas.isEmpty;

  @override
  void initState() {
    super.initState();
    _selectedShas = widget.selectedShas;
  }

  @override
  void didUpdateWidget(covariant CommitRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedShas = widget.selectedShas;
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    if (_overlay != null) {
      _closeOverlay();
    } else {
      _openOverlay();
    }
  }

  void _openOverlay() {
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
    _focusNode.requestFocus();
  }

  void _closeOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) {
      setState(() {});
    }
  }

  void _emit(Set<String> next) {
    _selectedShas = next;
    widget.onSelectionChanged?.call(next);
    setState(() {});
    _overlay?.markNeedsBuild();
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
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final codeFont = ref.watch(codeFontFamilyProvider);
    final isOpen = _overlay != null;
    return CompositedTransformTarget(
      link: _layerLink,
      child: CcTooltip(
        message: AppLocalizations.of(context).scopeDiffToCommits,
        child: InkWell(
          onTap: _toggleOverlay,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isOpen
                  ? tokens.bgSecondary
                  : tokens.bgSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.bgPrimary,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: tokens.borderSecondary),
                  ),
                  child: Text(
                    _chipVersionLabel(),
                    style: AppFonts.codeStyleDynamic(
                      codeFont,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    _chipLabel(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  AppIcons.chevronDown,
                  size: 14,
                  color: tokens.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext overlayCtx) {
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final codeFont = ref.read(codeFontFamilyProvider);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeOverlay,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 6),
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _closeOverlay();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(10),
              color: tokens.bgPrimary,
              child: Container(
                width: 380,
                constraints: const BoxConstraints(maxHeight: 420),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderSecondary),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CommitMenuRow(
                      versionLabel: 'v${widget.commits.length}',
                      title: AppLocalizations.of(context).allCommits,
                      relative: null,
                      checked: _isAllSelected,
                      onTap: _toggleAll,
                      codeFont: codeFont,
                    ),
                    const CcDivider(),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < widget.commits.length; i++)
                              _CommitMenuRow(
                                versionLabel: 'v${widget.commits.length - i}',
                                title: widget.commits[i].title.isEmpty
                                    ? widget.commits[i].shortSha
                                    : widget.commits[i].title,
                                relative: formatRelative(
                                  widget.commits[i].date,
                                ),
                                checked:
                                    !_isAllSelected &&
                                    _selectedShas.contains(
                                      widget.commits[i].sha,
                                    ),
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
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.totalCommitsCount > widget.commits.length)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).commitsShowingLatest(
                                  widget.commits.length,
                                  widget.totalCommitsCount,
                                ),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: tokens.textTertiary,
                                    ),
                              ),
                            ),
                          Row(
                            children: [
                              Icon(
                                AppIcons.info,
                                size: 12,
                                color: tokens.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Shift-click to select a range',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: tokens.textTertiary,
                                      ),
                                ),
                              ),
                              if (!_isAllSelected)
                                InkWell(
                                  onTap: _toggleAll,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context).clear,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: const Color(0xFF1F75FE),
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
            ),
          ),
        ),
      ],
    );
  }
}

class _CommitMenuRow extends StatelessWidget {
  const _CommitMenuRow({
    required this.versionLabel,
    required this.title,
    required this.relative,
    required this.checked,
    required this.onTap,
    required this.codeFont,
  });
  final String versionLabel;
  final String title;
  final String? relative;
  final bool checked;
  final VoidCallback onTap;
  final String codeFont;

  @override
  Widget build(BuildContext context) {
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            IgnorePointer(
              child: CcCheckbox(value: checked, onChanged: (_) {}),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: checked
                    ? const Color(0xFF1F75FE).withValues(alpha: 0.15)
                    : tokens.bgSecondary,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                versionLabel,
                style: AppFonts.codeStyleDynamic(
                  codeFont,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: checked
                      ? const Color(0xFF1F75FE)
                      : tokens.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: checked ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (relative != null) ...[
              const SizedBox(width: 12),
              Text(
                relative!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
