import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_header_section.dart';
import 'package:control_center/features/pr_review/presentation/widgets/hover_focus_reveal.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR title in the content header. Renders [PrTitle] in read mode with an
/// edit pencil (when [canEdit]) shown on hover or keyboard focus; activating it
/// swaps to an inline text field with Save/Cancel, and leaving the editor puts
/// focus back on the pencil. The `#<number>` prefix stays non-editable.
class EditablePrTitle extends ConsumerStatefulWidget {
  /// Creates an [EditablePrTitle].
  const EditablePrTitle({
    super.key,
    required this.pr,
    required this.prRef,
    required this.canEdit,
  });

  /// The pull request.
  final PullRequest pr;

  /// The PR's identity key (repo coords + number) for the edit notifier.
  final PrRef prRef;

  /// Whether the current user may edit the title.
  final bool canEdit;

  @override
  ConsumerState<EditablePrTitle> createState() => _EditablePrTitleState();
}

class _EditablePrTitleState extends ConsumerState<EditablePrTitle> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _editButtonFocus = FocusNode(debugLabel: 'edit-pr-title');
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _editButtonFocus.dispose();
    super.dispose();
  }

  /// Leaves the editor. Focus goes back to the pencil that opened it rather
  /// than falling to the top of the page with the unmounted field.
  void _finishEdit() {
    // The field or one of its Save/Cancel buttons — anything in this editor.
    final hadFocus =
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorStateOfType<_EditablePrTitleState>() ==
        this;
    setState(() => _editing = false);
    if (!hadFocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _editButtonFocus.requestFocus();
      }
    });
  }

  void _startEdit() {
    setState(() {
      _controller.text = widget.pr.title;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      _editing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text == widget.pr.title) {
      _finishEdit();
      return;
    }
    final notifier = ref.read(prEditProvider(widget.prRef).notifier);
    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);
    final error = await notifier.saveTitle(text);
    if (!mounted) {
      return;
    }
    if (error == null) {
      _finishEdit();
    } else {
      toaster.show(
        l10n.failedToUpdateTitle(error),
        variant: CcToastVariant.danger,
      );
    }
  }

  void _cancel() => _finishEdit();

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return _buildEdit(context);
    }
    return _buildRead(context);
  }

  Widget _buildRead(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Height of the title's first text line, used to vertically center the
    // edit affordance against the first line (not the whole block, which can
    // wrap to two lines). Derived from the title style so it tracks the font.
    final titleStyle = PrTitle.styleOf(context);
    final lineHeight = titleStyle.fontSize! * titleStyle.height!;
    final l10n = AppLocalizations.of(context);
    return HoverFocusReveal(
      builder: (context, revealed) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status glyph (draft/open/closed/merged) leading the title — the
          // same mapping the breadcrumb uses. Centered against the title's
          // first text line via [lineHeight], like the edit affordance.
          SizedBox(
            height: lineHeight,
            child: Center(child: PrStatusIcon(pr: widget.pr)),
          ),
          const SizedBox(width: 8),
          // The page's top heading, for the screen reader's heading rotor.
          Flexible(
            child: Semantics(header: true, child: PrTitle(pr: widget.pr)),
          ),
          // Always mounted so Tab and screen readers can reach it; painted
          // only on hover or while it has keyboard focus.
          if (widget.canEdit) ...[
            // A small, deliberate gap between the title and the edit button.
            const SizedBox(width: 6),
            SizedBox(
              height: lineHeight,
              child: Center(
                child: HoverFocusReveal.fade(
                  revealed: revealed,
                  child: CcTooltip(
                    // Open the tip below the button (default opens above).
                    message: l10n.editTitle,
                    child: CcTappable(
                      focusNode: _editButtonFocus,
                      onPressed: _startEdit,
                      semanticLabel: l10n.editTitle,
                      borderRadius: AppRadii.brSm,
                      builder: (context, states) {
                        final hovered = states.contains(WidgetState.hovered);
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: hovered
                                ? t.bgPrimaryHover
                                : const Color(0x00000000),
                            borderRadius: AppRadii.brSm,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              AppIcons.pencil,
                              size: 16,
                              color: hovered ? t.fgTertiary : t.fgQuaternary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEdit(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final titleStyle = PrTitle.styleOf(context);
    final l10n = AppLocalizations.of(context);
    final saving = ref.watch(
      prEditProvider(widget.prRef).select((s) => s.savingTitle),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _save,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PrStatusIcon(pr: widget.pr),
              const SizedBox(width: 8),
              Text(
                '#${widget.pr.number} ',
                style: titleStyle.copyWith(
                  fontWeight: CcTypography.regularWeight,
                  color: t.textTertiary,
                ),
              ),
              Expanded(
                child: FocusRing(
                  focusNode: _focusNode,
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.bgSecondary,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: t.borderSecondary),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: CcTextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textStyle: titleStyle.copyWith(color: t.textPrimary),
                      hintText: l10n.prTitlePlaceholder,
                      chromeless: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CcButton(
                onPressed: saving ? null : _cancel,
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              CcButton(
                onPressed: saving ? null : _save,
                size: CcButtonSize.sm,
                child: saving
                    ? CcSpinner(size: 16, color: t.textWhite)
                    : Text(l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
