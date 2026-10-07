import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_comment_field.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_send_row.dart';
import 'package:control_center/features/pr_review/providers/comment_composer_mode_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Conventional comment prefixes (conventionalcomments.org).
const _conventionalPrefixes = [
  (prefix: 'nit: ', description: 'Minor nit — non-blocking'),
  (prefix: 'suggestion: ', description: 'Suggestion — non-blocking'),
  (prefix: 'issue: ', description: 'Issue — should be addressed'),
  (prefix: 'question: ', description: 'Question — needs clarification'),
  (prefix: 'praise: ', description: 'Praise — positive feedback'),
  (prefix: 'thought: ', description: 'Thought — exploratory, non-blocking'),
];

/// Pr comment composer.
class PrCommentComposer extends ConsumerStatefulWidget {
  /// PrCommentComposer({.
  const PrCommentComposer({
    super.key,
    required this.prRef,
    required this.onSubmit,
    required this.onCancel,
    this.onSubmitBatched,
    this.onSendToAgent,
    this.reviewInProgress = false,
    this.onSuggest,
    this.placeholder,
    this.autofocus = true,
    this.initialText,
  });

  /// Posts the comment on its own, right now.
  final void Function(String body) onSubmit;

  /// Queues the comment for the next review submission instead of posting it.
  /// Null hides the action (nothing here can batch — e.g. no PR connected).
  final void Function(String body)? onSubmitBatched;

  /// Hands the comment to the pull request's agent instead of the forge.
  /// The composer stays open, draft intact, until the future completes; the
  /// host closes it on success. Null hides the destination.
  final Future<void> Function(String body)? onSendToAgent;

  /// Switches this anchored comment to an editable code suggestion, preserving
  /// the comment draft already entered by the reviewer.
  final ValueChanged<String>? onSuggest;

  /// Whether comments are already queued, which is the difference between
  /// "start a review" and "add to the one you started".
  final bool reviewInProgress;

  /// The PR this composer posts to; its repo drives the `#` autocomplete.
  final PrRef? prRef;

  /// Called when the user cancels or presses Escape.
  final VoidCallback onCancel;

  /// Hint text shown in the empty composer. Null names the chosen
  /// destination ("Send to agent…", "Leave a comment…", "Add to review…").
  final String? placeholder;

  /// Whether the composer should grab focus on open.
  final bool autofocus;

  /// String?.
  final String? initialText;

  @override
  ConsumerState<PrCommentComposer> createState() => _PrCommentComposerState();
}

class _PrCommentComposerState extends ConsumerState<PrCommentComposer> {
  final _focus = FocusNode();
  late final _ctrl = TextEditingController(text: widget.initialText ?? '');
  OverlayEntry? _slashMenu;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    _closeSlashMenu();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _ctrl.text;
    if (text == '/') {
      _showSlashMenu();
    } else if (_slashMenu != null && !text.startsWith('/')) {
      _closeSlashMenu();
    }
  }

  void _showSlashMenu() {
    _closeSlashMenu();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _slashMenu = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx,
        top: position.dy - (_conventionalPrefixes.length * 40.0) - 8,
        width: size.width,
        child: Material(
          elevation: 4,
          shadowColor: const Color(0x1F7F6315),
          borderRadius: AppRadii.brMd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _conventionalPrefixes.map((p) {
              return CcTile(
                title: Text(
                  p.prefix,
                  style: CcTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(p.description, style: CcTypography.caption),
                onTap: () {
                  _ctrl.text = p.prefix;
                  _ctrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: p.prefix.length),
                  );
                  _closeSlashMenu();
                  _focus.requestFocus();
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
    overlay.insert(_slashMenu!);
  }

  void _closeSlashMenu() {
    _slashMenu?.remove();
    _slashMenu = null;
  }

  List<CommentComposerMode> get _modes => commentComposerModes(
    agent: widget.onSendToAgent != null,
    review: widget.onSubmitBatched != null,
  );

  /// Keyboard submit: sends to whatever the row currently shows.
  void _submitCurrent() => unawaited(
    _send(
      resolveCommentComposerMode(ref.read(commentComposerModeProvider), _modes),
    ),
  );

  Future<void> _send(CommentComposerMode mode) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    _closeSlashMenu();
    switch (mode) {
      case CommentComposerMode.agent:
        final toAgent = widget.onSendToAgent;
        if (toAgent == null) {
          return;
        }
        setState(() => _sending = true);
        try {
          await toAgent(text);
        } finally {
          if (mounted) {
            setState(() => _sending = false);
          }
        }
      case CommentComposerMode.review:
        widget.onSubmitBatched?.call(text);
      case CommentComposerMode.comment:
        widget.onSubmit(text);
    }
  }

  void _suggest() {
    _closeSlashMenu();
    widget.onSuggest?.call(_ctrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final repo = widget.prRef == null
        ? null
        : ref.watch(prRepoRowProvider(widget.prRef!));
    final modes = _modes;
    final mode = resolveCommentComposerMode(
      ref.watch(commentComposerModeProvider),
      modes,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            widget.onCancel();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SelectionContainer.disabled(
          child: PrCommentField(
            controller: _ctrl,
            focusNode: _focus,
            hintText:
                widget.placeholder ??
                commentComposerHint(AppLocalizations.of(context), mode),
            owner: repo?.remoteOwner ?? '',
            repo: repo?.remoteName ?? '',
            autofocus: widget.autofocus,
            minLines: 2,
            maxLines: 8,
            onSubmitted: (_) => _submitCurrent(),
            toolbarLeading: [
              if (widget.onSuggest != null)
                CcButton(
                  onPressed: _suggest,
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  child: Text(AppLocalizations.of(context).suggestion),
                ),
            ],
            footer: (context) => Padding(
              padding: const EdgeInsetsDirectional.only(top: 8, end: 6),
              child: CommentSendRow(
                modes: modes,
                mode: mode,
                reviewInProgress: widget.reviewInProgress,
                sending: _sending,
                onSend: _send,
                onCancel: widget.onCancel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pr selection toolbar.
class PrSelectionToolbar extends StatelessWidget {
  /// Creates a [PrSelectionToolbar].
  const PrSelectionToolbar({
    super.key,
    required this.onComment,
    required this.onSuggest,
    required this.onReact,
  });

  /// Called when the user taps the comment action.
  final VoidCallback onComment;

  /// Called when the user taps the suggest action.
  final VoidCallback onSuggest;

  /// Called when the user taps the react action.
  final VoidCallback onReact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: const BoxDecoration(
          color: DesignSystemPalette.gray900,
          borderRadius: BorderRadius.all(Radius.circular(999)),
          boxShadow: AppShadows.golden,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarIcon(
              icon: AppIcons.messageSquare,
              tooltip: AppLocalizations.of(context).addAComment,

              onPressed: onComment,
            ),
            _ToolbarIcon(
              icon: AppIcons.diff,
              tooltip: AppLocalizations.of(context).addASuggestion,

              onPressed: onSuggest,
            ),
            _ToolbarIcon(
              icon: AppIcons.smile,
              tooltip: AppLocalizations.of(context).addAReaction,
              onPressed: onReact,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CcIconButton(
      icon: icon,
      size: CcButtonSize.sm,
      color: const Color(0xFFFFFFFF),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
