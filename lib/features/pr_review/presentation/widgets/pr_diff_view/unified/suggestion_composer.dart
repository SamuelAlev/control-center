import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/syntax/grammar_registry.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Inline "suggest a change" composer: the original line(s) are shown read-only
/// with deletion styling above an editable replacement field with addition
/// styling, plus an optional comment and post/cancel actions — mirroring the
/// GitHub/Pierre suggestion flow (original row + editable replacement row).
class SuggestionComposer extends StatefulWidget {
  /// Creates a suggestion composer.
  const SuggestionComposer({
    super.key,
    required this.originalCode,
    required this.baseStyle,
    this.filePath,
    required this.onSubmit,
    required this.onCancel,
    this.initialComment = '',
    this.onSubmitBatched,
    this.reviewInProgress = false,
  });

  /// The original code being replaced (shown read-only as a deletion row).
  final String originalCode;

  /// Monospace base style shared with the diff body.
  final TextStyle baseStyle;

  /// Called with every replacement block and the surrounding comment when the
  /// suggestion is posted on its own, right now.
  final void Function(List<String> suggestions, String comment) onSubmit;

  /// Comment draft carried over when a line comment becomes a suggestion.
  final String initialComment;

  /// Queues the suggestion blocks for the next review submission. Null hides
  /// the action.
  final void Function(List<String> suggestions, String comment)?
  onSubmitBatched;

  /// File whose selected code is being replaced, used to resolve its grammar.
  final String? filePath;

  /// Whether comments are already queued for this review.
  final bool reviewInProgress;

  /// Called on cancel or Escape.
  final VoidCallback onCancel;

  @override
  State<SuggestionComposer> createState() => _SuggestionComposerState();
}

class _SuggestionComposerState extends State<SuggestionComposer> {
  late final List<DiffSyntaxTextEditingController> _codes = [
    DiffSyntaxTextEditingController(
      text: widget.originalCode,
      languageId: _language,
    ),
  ];
  late final List<FocusNode> _codeFocus = [FocusNode()];
  late final TextEditingController _comment = TextEditingController(
    text: widget.initialComment,
  );
  final Set<String> _warmed = <String>{};
  bool _dark = false;

  String? get _language {
    final path = widget.filePath;
    return path == null ? null : shikiLangForPath(path);
  }

  @override
  void initState() {
    super.initState();
    _warmGrammar();
  }

  @override
  void didUpdateWidget(covariant SuggestionComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _warmGrammar();
    }
  }

  void _warmGrammar() {
    final language = _language;
    if (language == null || !_warmed.add(language)) {
      return;
    }
    unawaited(
      ensureLanguageAvailable(language).then((available) {
        if (!available || !mounted) {
          return;
        }
        setState(() {
          for (final controller in _codes) {
            controller.refreshHighlighting();
          }
        });
      }),
    );
  }

  void _addSuggestion() {
    final controller = DiffSyntaxTextEditingController(
      text: widget.originalCode,
      languageId: _language,
      dark: _dark,
    );
    final focus = FocusNode();
    setState(() {
      _codes.add(controller);
      _codeFocus.add(focus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focus.requestFocus();
      }
    });
  }

  void _removeSuggestion(int index) {
    if (_codes.length == 1) {
      return;
    }
    final controller = _codes.removeAt(index);
    final focus = _codeFocus.removeAt(index);
    controller.dispose();
    focus.dispose();
    setState(() {});
  }

  List<String> get _suggestions => [for (final code in _codes) code.text];

  @override
  void dispose() {
    for (final controller in _codes) {
      controller.dispose();
    }
    for (final focus in _codeFocus) {
      focus.dispose();
    }
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        context.designSystem ??
        ((context.ccTheme?.isDark ?? false)
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final palette = DiffPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final codeStyle = widget.baseStyle.copyWith(fontSize: 12, height: 1.5);
    _dark = context.ccTheme?.isDark ?? false;
    for (final controller in _codes) {
      controller.configure(languageId: _language, dark: _dark);
    }
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: tokens.bgPrimary,
          borderRadius: AppRadii.brMd,
          border: Border.all(color: tokens.borderSecondary),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: palette.deletionBg,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: SelectionContainer.disabled(
                child: Text.rich(
                  highlightedDiffTextSpan(
                    text: widget.originalCode,
                    languageId: _language,
                    dark: _dark,
                    baseStyle: codeStyle,
                  ),
                  style: codeStyle,
                ),
              ),
            ),
            for (var i = 0; i < _codes.length; i++) ...[
              if (i > 0) const CcDivider(),
              Container(
                color: palette.additionBg,
                padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
                child: SelectionContainer.disabled(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CcTextField(
                          controller: _codes[i],
                          focusNode: _codeFocus[i],
                          autofocus: i == 0,
                          minLines: 1,
                          maxLines: 12,
                          textStyle: codeStyle,
                          chromeless: true,
                        ),
                      ),
                      if (_codes.length > 1)
                        CcIconButton(
                          onPressed: () => _removeSuggestion(i),
                          icon: AppIcons.x,
                          variant: CcButtonVariant.ghost,
                          size: CcButtonSize.sm,
                          tooltip: l10n.remove,
                        ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: CcButton(
                  onPressed: _addSuggestion,
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  child: Text(l10n.addASuggestion),
                ),
              ),
            ),
            const CcDivider(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectionContainer.disabled(
                    child: CcTextField(
                      controller: _comment,
                      minLines: 1,
                      maxLines: 3,
                      textStyle: CcTypography.body.copyWith(
                        color: context.ds.textTertiary,
                      ),
                      hintText: l10n.leaveACommentEllipsis,
                      chromeless: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      CcButton(
                        onPressed: widget.onCancel,
                        variant: CcButtonVariant.secondary,
                        size: CcButtonSize.sm,
                        child: Text(l10n.cancel),
                      ),
                      CcButton(
                        onPressed: () =>
                            widget.onSubmit(_suggestions, _comment.text),
                        size: CcButtonSize.sm,
                        variant: widget.onSubmitBatched == null
                            ? CcButtonVariant.primary
                            : CcButtonVariant.secondary,
                        child: Text(
                          widget.onSubmitBatched == null
                              ? l10n.suggestAChange
                              : l10n.addSingleComment,
                        ),
                      ),
                      if (widget.onSubmitBatched != null)
                        CcButton(
                          onPressed: () => widget.onSubmitBatched!(
                            _suggestions,
                            _comment.text,
                          ),
                          size: CcButtonSize.sm,
                          child: Text(
                            widget.reviewInProgress
                                ? l10n.addToReview
                                : l10n.startAReview,
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
