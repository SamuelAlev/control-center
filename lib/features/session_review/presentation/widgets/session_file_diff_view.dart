import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/diff_colors.dart';
import 'package:flutter/widgets.dart';

/// The two ways a [SessionFileDiffView] can lay a patch out.
enum SessionDiffStyle {
  /// One column: deletions then additions, interleaved as they appear.
  unified,

  /// Two columns: pre-image on the left, post-image on the right.
  split,
}

/// Above this many diff rows a file is virtualized (a scrolling viewport with
/// lazily-built rows) instead of laid out eagerly in a [Column], so a huge file
/// never blocks the frame.
const int kExtremeDiffChangedLines = 2000;

/// Fixed height of a single diff row, so the virtualized path can use a cheap
/// fixed-extent list.
const double kSessionDiffRowHeight = 18.0;

/// Renders one file's unified-diff [patch] as a read-only, syntax-free diff —
/// gutter line numbers plus add/delete/context tinting. Self-contained (no
/// Riverpod, no PR-review coupling) so it is cheap to embed in the session
/// review accordion and straightforward to test.
///
/// Two render paths, picked by row count: an eager [Column] for normal files,
/// and a virtualized fixed-extent list once a file exceeds
/// [kExtremeDiffChangedLines] rows — the large-diff case the PRD calls out.
class SessionFileDiffView extends StatelessWidget {
  /// Creates a [SessionFileDiffView] from a raw unified-diff [patch].
  const SessionFileDiffView({
    super.key,
    required this.patch,
    this.style = SessionDiffStyle.unified,
    this.maxEagerHeight = 480,
    this.diffColors,
  });

  /// The file's unified-diff text.
  final String patch;

  /// Unified or split layout.
  final SessionDiffStyle style;

  /// The height the eager path is capped to before it scrolls internally.
  final double maxEagerHeight;

  /// Optional override for the shared diff colors (e.g. an imported VS Code
  /// theme). Defaults to [DiffColors.of].
  final DiffColors? diffColors;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final c = diffColors ?? DiffColors.of(context);
    final lines = parseUnifiedDiff(
      patch,
    ).where((l) => l.kind != DiffLineKind.expandGap).toList(growable: false);

    final rows = style == SessionDiffStyle.split
        ? _buildSplitRows(lines)
        : _buildUnifiedRows(lines);

    final virtualized = rows.length > kExtremeDiffChangedLines;

    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: t.canvas,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: t.borderSecondary),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.brMd,
        child: virtualized
            ? SizedBox(
                height: maxEagerHeight,
                child: ListView.builder(
                  primary: false,
                  itemExtent: kSessionDiffRowHeight,
                  itemCount: rows.length,
                  itemBuilder: (context, i) => rows[i].build(context, t, c),
                ),
              )
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxEagerHeight),
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final r in rows) r.build(context, t, c)],
                  ),
                ),
              ),
      ),
    );

    return Semantics(
      label: virtualized
          ? 'Large diff, ${rows.length} rows (virtualized)'
          : 'Diff, ${rows.length} rows',
      child: body,
    );
  }

  List<_DiffRow> _buildUnifiedRows(List<DiffLine> lines) => [
    for (final line in lines)
      _DiffRow.unified(
        oldNo: line.oldLine,
        newNo: line.newLine,
        kind: line.kind,
        content: line.hunkHeader ?? line.content,
      ),
  ];

  /// Pairs deletions with the additions that follow them so a modified region
  /// lines up left/right; context lines occupy both columns; unmatched
  /// deletions/additions get an empty cell opposite them.
  List<_DiffRow> _buildSplitRows(List<DiffLine> lines) {
    final rows = <_DiffRow>[];
    final pendingDel = <DiffLine>[];
    final pendingAdd = <DiffLine>[];

    void flush() {
      final n = pendingDel.length > pendingAdd.length
          ? pendingDel.length
          : pendingAdd.length;
      for (var i = 0; i < n; i++) {
        final del = i < pendingDel.length ? pendingDel[i] : null;
        final add = i < pendingAdd.length ? pendingAdd[i] : null;
        rows.add(
          _DiffRow.split(
            leftNo: del?.oldLine,
            leftContent: del?.content,
            rightNo: add?.newLine,
            rightContent: add?.content,
          ),
        );
      }
      pendingDel.clear();
      pendingAdd.clear();
    }

    for (final line in lines) {
      switch (line.kind) {
        case DiffLineKind.deletion:
          pendingDel.add(line);
        case DiffLineKind.addition:
          pendingAdd.add(line);
        case DiffLineKind.hunkHeader:
          flush();
          rows.add(_DiffRow.hunk(line.hunkHeader ?? line.content));
        case DiffLineKind.context:
          flush();
          rows.add(
            _DiffRow.split(
              leftNo: line.oldLine,
              leftContent: line.content,
              rightNo: line.newLine,
              rightContent: line.content,
            ),
          );
        case DiffLineKind.expandGap:
          break;
      }
    }
    flush();
    return rows;
  }
}

/// A pre-built diff row description — cheap to hold in a list and render on
/// demand from either the eager or the virtualized path.
class _DiffRow {
  const _DiffRow._({
    required this.kind,
    this.oldNo,
    this.newNo,
    this.content,
    this.leftNo,
    this.leftContent,
    this.rightNo,
    this.rightContent,
    this.split = false,
  });

  factory _DiffRow.unified({
    required DiffLineKind kind,
    required String content,
    int? oldNo,
    int? newNo,
  }) => _DiffRow._(kind: kind, content: content, oldNo: oldNo, newNo: newNo);

  factory _DiffRow.hunk(String content) =>
      _DiffRow._(kind: DiffLineKind.hunkHeader, content: content, split: true);

  factory _DiffRow.split({
    int? leftNo,
    String? leftContent,
    int? rightNo,
    String? rightContent,
  }) => _DiffRow._(
    kind: DiffLineKind.context,
    split: true,
    leftNo: leftNo,
    leftContent: leftContent,
    rightNo: rightNo,
    rightContent: rightContent,
  );

  final DiffLineKind kind;
  final bool split;
  final int? oldNo;
  final int? newNo;
  final String? content;
  final int? leftNo;
  final String? leftContent;
  final int? rightNo;
  final String? rightContent;

  Widget build(BuildContext context, DesignSystemTokens t, DiffColors c) {
    if (!split) {
      return _UnifiedRow(
        kind: kind,
        content: content ?? '',
        oldNo: oldNo,
        newNo: newNo,
        colors: c,
      );
    }
    if (kind == DiffLineKind.hunkHeader) {
      return _HunkRow(content: content ?? '', colors: c);
    }
    return _SplitRow(
      leftNo: leftNo,
      leftContent: leftContent,
      rightNo: rightNo,
      rightContent: rightContent,
      colors: c,
    );
  }
}

TextStyle _codeStyle(Color color) =>
    CcFonts.code(textStyle: TextStyle(fontSize: 12, height: 1.4, color: color));

TextStyle _gutterStyle(Color color) =>
    CcFonts.code(textStyle: TextStyle(fontSize: 11, height: 1.4, color: color));

Color _rowBg(DiffColors c, DiffLineKind kind) => switch (kind) {
  DiffLineKind.addition => c.additionBg,
  DiffLineKind.deletion => c.deletionBg,
  DiffLineKind.hunkHeader => c.hunkBg,
  _ => const Color(0x00000000),
};

String _marker(DiffLineKind kind) => switch (kind) {
  DiffLineKind.addition => '+',
  DiffLineKind.deletion => '-',
  _ => ' ',
};

class _UnifiedRow extends StatelessWidget {
  const _UnifiedRow({
    required this.kind,
    required this.content,
    required this.colors,
    this.oldNo,
    this.newNo,
  });

  final DiffLineKind kind;
  final String content;
  final DiffColors colors;
  final int? oldNo;
  final int? newNo;

  @override
  Widget build(BuildContext context) {
    if (kind == DiffLineKind.hunkHeader) {
      return _HunkRow(content: content, colors: colors);
    }
    final fg = switch (kind) {
      DiffLineKind.addition => colors.additionAccent,
      DiffLineKind.deletion => colors.deletionAccent,
      _ => colors.contextFg,
    };
    return Container(
      color: _rowBg(colors, kind),
      height: kSessionDiffRowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Gutter(number: oldNo, color: colors.gutterFg),
          _Gutter(number: newNo, color: colors.gutterFg),
          const SizedBox(width: 6),
          SizedBox(
            width: 12,
            child: Text(_marker(kind), style: _codeStyle(fg)),
          ),
          Expanded(
            child: Text(
              content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _codeStyle(fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.colors,
    this.leftNo,
    this.leftContent,
    this.rightNo,
    this.rightContent,
  });

  final DiffColors colors;
  final int? leftNo;
  final String? leftContent;
  final int? rightNo;
  final String? rightContent;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final isDelete = leftContent != null && rightContent != leftContent;
    final isAdd = rightContent != null && rightContent != leftContent;
    return SizedBox(
      height: kSessionDiffRowHeight,
      child: Row(
        children: [
          Expanded(
            child: _SplitCell(
              number: leftNo,
              content: leftContent,
              bg: isDelete && leftContent != null
                  ? colors.deletionBg
                  : const Color(0x00000000),
              fg: isDelete && leftContent != null
                  ? colors.deletionAccent
                  : colors.contextFg,
              gutterColor: colors.gutterFg,
            ),
          ),
          Container(width: 1, color: t.borderSecondary),
          Expanded(
            child: _SplitCell(
              number: rightNo,
              content: rightContent,
              bg: isAdd && rightContent != null
                  ? colors.additionBg
                  : const Color(0x00000000),
              fg: isAdd && rightContent != null
                  ? colors.additionAccent
                  : colors.contextFg,
              gutterColor: colors.gutterFg,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitCell extends StatelessWidget {
  const _SplitCell({
    required this.number,
    required this.content,
    required this.bg,
    required this.fg,
    required this.gutterColor,
  });

  final int? number;
  final String? content;
  final Color bg;
  final Color fg;
  final Color gutterColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Row(
        children: [
          _Gutter(number: number, color: gutterColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              content ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _codeStyle(fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _HunkRow extends StatelessWidget {
  const _HunkRow({required this.content, required this.colors});

  final String content;
  final DiffColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.hunkBg,
      height: kSessionDiffRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _codeStyle(colors.gutterFg),
      ),
    );
  }
}

class _Gutter extends StatelessWidget {
  const _Gutter({required this.number, required this.color});

  final int? number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          number?.toString() ?? '',
          textAlign: TextAlign.right,
          maxLines: 1,
          style: _gutterStyle(color),
        ),
      ),
    );
  }
}
