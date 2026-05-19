import 'package:cc_domain/features/pr_review/domain/value_objects/cohort_insights.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/review_studio/review_studio_cohorts.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The guided reading path through one review area.
///
/// A diff arrives in alphabetical order, which is the one order that carries
/// no information: it puts the test before the type it tests and the glue
/// before the thing it glues. This renders the order the change would actually
/// be explained in — foundations, then their consumers, then the tests — so a
/// reviewer reads a story instead of a directory listing.
class ReviewHubReadingOrder extends StatefulWidget {
  /// Creates a [ReviewHubReadingOrder].
  const ReviewHubReadingOrder({
    super.key,
    required this.cohort,
    this.onOpenInDiff,
  });

  /// The area whose reading path this renders.
  final ReviewCohort cohort;

  /// Opens a layer's file (and line range) in the diff view. Absent when the
  /// host has nowhere to jump to.
  final void Function(String filePath, int? startLine)? onOpenInDiff;

  @override
  State<ReviewHubReadingOrder> createState() => _ReviewHubReadingOrderState();
}

class _ReviewHubReadingOrderState extends State<ReviewHubReadingOrder> {
  int _selected = 0;
  final _focus = FocusNode();
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(ReviewHubReadingOrder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A recompute can shorten the path out from under the selection.
    if (_selected >= widget.cohort.layers.length) {
      _selected = 0;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final layers = widget.cohort.layers;
    if (layers.isEmpty) {
      return;
    }
    setState(() {
      _selected = (_selected + delta).clamp(0, layers.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final cohort = widget.cohort;
    final layers = cohort.layers;

    if (layers.isEmpty) {
      return _EmptyBody(
        message: l10n.reviewHubNoReadingOrder,
        summaryMarkdown: cohort.summaryMarkdown,
        cohort: cohort,
      );
    }

    return FocusableActionDetector(
      focusNode: _focus,
      // J/K mirror the diff viewer's own bindings; the arrows are there so
      // nobody has to know that.
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyJ): _NextLayerIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown): _NextLayerIntent(),
        SingleActivator(LogicalKeyboardKey.keyK): _PreviousLayerIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): _PreviousLayerIntent(),
      },
      actions: <Type, Action<Intent>>{
        _NextLayerIntent: CallbackAction<_NextLayerIntent>(
          onInvoke: (_) {
            _move(1);
            return null;
          },
        ),
        _PreviousLayerIntent: CallbackAction<_PreviousLayerIntent>(
          onInvoke: (_) {
            _move(-1);
            return null;
          },
        ),
      },
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Row(
            children: [
              Icon(AppIcons.listChecks, size: 14, color: ds.textSecondary),
              const SizedBox(width: 6),
              Text(
                l10n.reviewHubReadingOrder,
                style: TextStyle(
                  color: ds.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                l10n.reviewHubLayerPosition(_selected + 1, layers.length),
                style: TextStyle(color: ds.textTertiary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.reviewHubReadingOrderHint,
            style: TextStyle(color: ds.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < layers.length; i++)
            _LayerRow(
              index: i,
              layer: layers[i],
              selected: i == _selected,
              onTap: () => setState(() => _selected = i),
              onOpenInDiff: widget.onOpenInDiff == null
                  ? null
                  : () => widget.onOpenInDiff!(
                      layers[i].filePath,
                      layers[i].startLine,
                    ),
            ),
          if (cohort.summaryMarkdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            const CcDivider(),
            const SizedBox(height: 12),
            StyledMarkdownBody(data: cohort.summaryMarkdown, compact: true),
          ],
          for (final diagram in cohort.diagrams) ...[
            const SizedBox(height: 12),
            reviewDiagramWidget(diagram),
          ],
        ],
      ),
    );
  }
}

/// Shown when an area has no computed layers — still renders whatever
/// narrative and diagrams the area does have, rather than an empty pane.
class _EmptyBody extends StatelessWidget {
  const _EmptyBody({
    required this.message,
    required this.summaryMarkdown,
    required this.cohort,
  });

  final String message;
  final String summaryMarkdown;
  final ReviewCohort cohort;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Text(message, style: TextStyle(color: ds.textTertiary, fontSize: 12)),
        if (summaryMarkdown.isNotEmpty) ...[
          const SizedBox(height: 12),
          StyledMarkdownBody(data: summaryMarkdown, compact: true),
        ],
        for (final diagram in cohort.diagrams) ...[
          const SizedBox(height: 12),
          reviewDiagramWidget(diagram),
        ],
      ],
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.index,
    required this.layer,
    required this.selected,
    required this.onTap,
    this.onOpenInDiff,
  });

  final int index;
  final CohortLayer layer;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onOpenInDiff;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final range = layer.hasRange
        ? '${layer.filePath}:${layer.startLine}'
              '${layer.endLine == null ? '' : '–${layer.endLine}'}'
        : layer.filePath;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: CcTappable(
        onPressed: onTap,
        borderRadius: BorderRadius.circular(8),
        builder: (context, states) => DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? ds.accentSoft : const Color(0x00000000),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepChip(index: index + 1, selected: selected),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layer.title,
                        style: TextStyle(
                          color: selected ? ds.textPrimary : ds.textSecondary,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        range,
                        style: CcFonts.code(
                          textStyle: TextStyle(
                            color: ds.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (selected && layer.summaryMarkdown.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        StyledMarkdownBody(
                          data: layer.summaryMarkdown,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                ),
                if (onOpenInDiff != null) ...[
                  const SizedBox(width: 8),
                  CcTappable(
                    onPressed: onOpenInDiff,
                    borderRadius: BorderRadius.circular(6),
                    builder: (context, states) => Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        AppIcons.fileDiff,
                        size: 14,
                        color: ds.textTertiary,
                        semanticLabel: l10n.reviewHubOpenInDiff,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.index, required this.selected});

  final int index;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? ds.accent : ds.bgSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          color: selected ? ds.accentOn : ds.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NextLayerIntent extends Intent {
  const _NextLayerIntent();
}

class _PreviousLayerIntent extends Intent {
  const _PreviousLayerIntent();
}

/// The symbols this change touched inside one area, with an honesty marker
/// when the spans came from the base index rather than the PR's own.
class ReviewHubChangedSymbols extends StatelessWidget {
  /// Creates a [ReviewHubChangedSymbols].
  const ReviewHubChangedSymbols({super.key, required this.insights});

  /// The area's deterministic insights.
  final CohortInsights insights;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    if (insights.changedSymbols.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.reviewHubChangedSymbols,
              style: TextStyle(
                color: ds.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (insights.symbolSource == SymbolSource.base) ...[
              const SizedBox(width: 8),
              CcTooltip(
                message: l10n.reviewHubSymbolsFromBaseTooltip,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.info, size: 11, color: ds.textTertiary),
                    const SizedBox(width: 3),
                    Text(
                      l10n.reviewHubSymbolsFromBase,
                      style: TextStyle(color: ds.textTertiary, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final changed in insights.changedSymbols.take(12))
              _SymbolChip(
                name: changed.symbol.name,
                lines: changed.changedLines,
              ),
          ],
        ),
      ],
    );
  }
}

class _SymbolChip extends StatelessWidget {
  const _SymbolChip({required this.name, required this.lines});

  final String name;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: ds.bgSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: CcFonts.code(
              textStyle: TextStyle(color: ds.textSecondary, fontSize: 11),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            l10n.reviewHubSymbolLines(lines),
            style: TextStyle(color: ds.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
