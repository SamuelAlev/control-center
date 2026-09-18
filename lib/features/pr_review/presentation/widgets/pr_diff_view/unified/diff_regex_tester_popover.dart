import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_goto.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_goto_panel.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Live regex tester: a sample field plus Match / No match / invalid-pattern.
class DiffRegexTesterPopover extends StatefulWidget {
  /// Creates a [DiffRegexTesterPopover].
  const DiffRegexTesterPopover({super.key, required this.literal});

  /// The `/pattern/flags` (or fallback raw) text of the hovered span.
  final String literal;

  @override
  State<DiffRegexTesterPopover> createState() => _DiffRegexTesterPopoverState();
}

class _DiffRegexTesterPopoverState extends State<DiffRegexTesterPopover> {
  late final TextEditingController _sample;
  String _sampleText = '';

  @override
  void initState() {
    super.initState();
    _sample = TextEditingController();
    _sample.addListener(() {
      if (_sample.text != _sampleText) {
        setState(() => _sampleText = _sample.text);
      }
    });
  }

  @override
  void dispose() {
    _sample.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t =
        context.designSystem ??
        ((context.ccTheme?.isDark ?? false)
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final parsed = parseJsRegexLiteral(widget.literal);
    final patternLabel = parsed?.pattern ?? widget.literal;

    Object? error;
    List<Match> matches = const [];
    if (parsed != null) {
      try {
        final re = parsed.toRegExp();
        matches = parsed.global
            ? re.allMatches(_sampleText).toList()
            : () {
                final m = re.firstMatch(_sampleText);
                return m == null ? const <Match>[] : <Match>[m];
              }();
      } on FormatException catch (e) {
        error = e;
      } on Object catch (e) {
        error = e;
      }
    } else {
      try {
        final re = RegExp(widget.literal);
        final m = re.firstMatch(_sampleText);
        matches = m == null ? const [] : [m];
      } on FormatException catch (e) {
        error = e;
      } on Object catch (e) {
        error = e;
      }
    }

    final invalid = error != null;
    final hasMatch = !invalid && matches.isNotEmpty && _sampleText.isNotEmpty;
    final noMatch = !invalid && _sampleText.isNotEmpty && matches.isEmpty;

    return DiffGotoPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.regexTesterTitle,
            style: CcTypography.label.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            patternLabel,
            style: CcFonts.code(
              family: context.ccTheme?.monoFontFamily,
              textStyle: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          CcTextField(
            controller: _sample,
            hintText: l10n.regexTesterHint,
            size: CcTextFieldSize.sm,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (invalid)
            Text(
              l10n.regexInvalidPattern,
              style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
            )
          else if (_sampleText.isEmpty)
            const SizedBox.shrink()
          else if (hasMatch) ...[
            Text(
              l10n.regexMatch,
              style: CcTypography.label.copyWith(color: t.textSuccessPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            _HighlightedSample(text: _sampleText, matches: matches, tokens: t),
          ] else if (noMatch)
            Text(
              l10n.regexNoMatch,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _HighlightedSample extends StatelessWidget {
  const _HighlightedSample({
    required this.text,
    required this.matches,
    required this.tokens,
  });

  final String text;
  final List<Match> matches;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Text(text, style: CcTypography.bodySm);
    }
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      if (m.end > m.start) {
        spans.add(
          TextSpan(
            text: text.substring(m.start, m.end),
            style: TextStyle(
              backgroundColor: tokens.accentSoft,
              color: tokens.textPrimary,
            ),
          ),
        );
      }
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(
      TextSpan(style: CcTypography.bodySm, children: spans),
    );
  }
}
