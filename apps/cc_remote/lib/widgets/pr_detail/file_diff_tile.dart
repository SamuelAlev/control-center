import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/pr_thread_providers.dart';
import 'package:cc_remote/widgets/diff_view.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// One changed file: a tappable header carrying its path and churn, expanding
/// to the file's unified diff.
///
/// Collapsed by default, and that is the point rather than a compromise. The
/// header row is the scan — twenty files, what changed and by how much — and
/// expanding every one of them on open would build thousands of rows inside
/// the PR screen's own scroll view before the reader has looked at anything.
class FileDiffTile extends ConsumerStatefulWidget {
  const FileDiffTile({
    super.key,
    required this.file,
    required this.coords,
    required this.commitSha,
    required this.canComment,
    required this.commentDisabledReason,
  });

  final PrFile file;
  final PrCoords coords;
  final String commitSha;
  final bool canComment;
  final String commentDisabledReason;

  @override
  ConsumerState<FileDiffTile> createState() => _FileDiffTileState();
}

class _FileDiffTileState extends ConsumerState<FileDiffTile> {
  bool _open = false;
  int _visibleRows = kDiffRowBudget;
  DiffLine? _selected;
  final _comment = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void didUpdateWidget(FileDiffTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commitSha != widget.commitSha ||
        oldWidget.file.filename != widget.file.filename ||
        oldWidget.coords != widget.coords) {
      _selected = null;
      _comment.clear();
      _visibleRows = kDiffRowBudget;
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final l10n = AppLocalizations.of(context);
    final selected = _selected;
    final line = selected?.kind == DiffLineKind.addition
        ? selected?.newLine
        : selected?.kind == DiffLineKind.deletion
        ? selected?.oldLine
        : null;
    final body = _comment.text.trim();
    if (body.isEmpty) {
      setState(() => _error = l10n.mobilePrCommentRequired);
      return;
    }
    final repository = ref.read(prReviewRepositoryProvider(widget.coords));
    final patches = ref.read(prPatchesProvider(widget.coords));
    if (line == null ||
        line < 1 ||
        repository == null ||
        !widget.canComment ||
        widget.commitSha.isEmpty ||
        patches.hasError) {
      setState(() => _error = l10n.mobilePrCommentUnavailable);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await repository.postReviewComment(
        prNumber: widget.coords.number,
        commitSha: widget.commitSha,
        path: widget.file.filename,
        line: line,
        side: selected!.kind == DiffLineKind.addition ? 'RIGHT' : 'LEFT',
        body: body,
      );
      if (!mounted) return;
      _comment.clear();
      setState(() => _selected = null);
      ref.invalidate(prThreadCommentsProvider(widget.coords));
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final file = widget.file;
    final slash = file.filename.lastIndexOf('/');
    final dir = slash <= 0 ? '' : file.filename.substring(0, slash + 1);
    final name = slash < 0 ? file.filename : file.filename.substring(slash + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcTappable(
          onPressed: () => setState(() => _open = !_open),
          semanticLabel: _open
              ? AppLocalizations.of(context).hideDiffFor(file.filename)
              : AppLocalizations.of(context).showDiffFor(file.filename),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          builder: (context, _) => ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      _open ? AppIcons.chevronDown : AppIcons.chevronRight,
                      size: 14,
                      color: t.fgTertiary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      switch (file.status) {
                        PrFileStatus.added => AppIcons.circleCheck,
                        PrFileStatus.removed => AppIcons.minus,
                        PrFileStatus.renamed => AppIcons.arrowRight,
                        _ => AppIcons.fileText,
                      },
                      size: 14,
                      color: t.fgTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (dir.isNotEmpty)
                            TextSpan(
                              text: dir,
                              style: TextStyle(color: t.textTertiary),
                            ),
                          TextSpan(
                            text: name,
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      // RTL carve-out: file paths read LTR in every locale.
                      textDirection: TextDirection.ltr,
                      style: CcFonts.code(
                        textStyle: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    churn(file.additions, file.deletions),
                    style: TextStyle(fontSize: 11, color: t.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open) _expanded(t),
      ],
    );
  }

  Widget _expanded(DesignSystemTokens t) {
    final l10n = AppLocalizations.of(context);
    final patches = ref.watch(prPatchesProvider(widget.coords));
    final file = patches.value
        ?.where((f) => f.filename == widget.file.filename)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12, top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (file == null && patches.hasError) ...[
            Text(
              '${patches.error}',
              style: TextStyle(color: t.textErrorPrimary),
            ),
            CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => ref.invalidate(prPatchesProvider(widget.coords)),
              child: Text(l10n.retry),
            ),
          ] else if (file == null && patches.hasValue) ...[
            Text(
              l10n.mobilePrNoPatchForFile,
              style: TextStyle(color: t.textTertiary),
            ),
            CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => ref.invalidate(prPatchesProvider(widget.coords)),
              child: Text(l10n.retry),
            ),
          ] else if (file == null)
            const Center(child: CcSpinner(size: 20))
          else ...[
            if (patches.hasError) ...[
              Text(
                '${patches.error}',
                style: TextStyle(color: t.textErrorPrimary),
              ),
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: () =>
                    ref.invalidate(prPatchesProvider(widget.coords)),
                child: Text(l10n.retry),
              ),
            ],
            if (!widget.canComment || widget.commitSha.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.commitSha.isEmpty
                      ? l10n.mobilePrCommentUnavailable
                      : widget.commentDisabledReason,
                  style: TextStyle(color: t.textTertiary),
                ),
              ),
            if (file.patch.isEmpty && file.additions + file.deletions > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.mobilePrPatchUnavailable,
                  style: TextStyle(color: t.textTertiary),
                ),
              )
            else
              DiffView(
                patch: file.patch,
                maxRows: _visibleRows,
                onExpand: () => setState(() => _visibleRows += kDiffRowBudget),
                selectedLine: _selected,
                onLineSelected:
                    !patches.hasError &&
                        widget.canComment &&
                        widget.commitSha.isNotEmpty
                    ? (line) => setState(() {
                        _selected = line;
                        _error = null;
                      })
                    : null,
              ),
            if (_selected != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.mobilePrThreadLine(
                  _selected!.kind == DiffLineKind.addition
                      ? l10n.mobilePrUpdatedSide
                      : l10n.mobilePrOriginalSide,
                  NumberFormat.decimalPattern(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(
                    _selected!.kind == DiffLineKind.addition
                        ? _selected!.newLine
                        : _selected!.oldLine,
                  ),
                ),
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
              const SizedBox(height: 6),
              CcTextArea(
                controller: _comment,
                minLines: 2,
                maxLines: 5,
                enabled: !_sending,
                hintText: l10n.mobilePrInlineCommentHint,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    _error!,
                    style: TextStyle(color: t.textErrorPrimary),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CcButton(
                      variant: CcButtonVariant.secondary,
                      onPressed: _sending
                          ? null
                          : () => setState(() {
                              _selected = null;
                              _error = null;
                            }),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CcButton(
                      loading: _sending,
                      onPressed: _sending ? null : _post,
                      child: Text(l10n.mobilePrPostInlineComment),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
