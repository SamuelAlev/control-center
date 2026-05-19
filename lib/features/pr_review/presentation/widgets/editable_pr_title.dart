import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_header_section.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR title in the content header. Renders [PrTitle] in read mode with a
/// hover-revealed edit pencil (when [canEdit]); clicking it swaps to an inline
/// text field with Save/Cancel. The `#<number>` prefix stays non-editable.
class EditablePrTitle extends ConsumerStatefulWidget {
  /// Creates an [EditablePrTitle].
  const EditablePrTitle({super.key, required this.pr, required this.canEdit});

  /// The pull request.
  final PullRequest pr;

  /// Whether the current user may edit the title.
  final bool canEdit;

  @override
  ConsumerState<EditablePrTitle> createState() => _EditablePrTitleState();
}

class _EditablePrTitleState extends ConsumerState<EditablePrTitle> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _editing = false;
  bool _hovered = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
      setState(() => _editing = false);
      return;
    }
    final notifier = ref.read(prEditProvider(widget.pr.number).notifier);
    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);
    final error = await notifier.saveTitle(text);
    if (!mounted) {
      return;
    }
    if (error == null) {
      setState(() => _editing = false);
    } else {
      toaster.show(
        l10n.failedToUpdateTitle(error),
        variant: CcToastVariant.danger,
      );
    }
  }

  void _cancel() => setState(() => _editing = false);

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
    final lineHeight =
        (titleStyle?.fontSize ?? 18) * (titleStyle?.height ?? 1.35);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
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
          Flexible(child: PrTitle(pr: widget.pr)),
          if (widget.canEdit && _hovered) ...[
            // A small, deliberate gap between the title and the edit button.
            const SizedBox(width: 6),
            SizedBox(
              height: lineHeight,
              child: Center(
                child: CcTooltip(
                  // Open the tip below the button (default opens above).
                  message: AppLocalizations.of(context).editTitle,
                  child: CcTappable(
                    onPressed: _startEdit,
                    borderRadius: AppRadii.brSm,
                    builder: (context, states) {
                      final hovered = states.contains(WidgetState.hovered);
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: hovered
                              ? t.bgPrimaryHover
                              : Colors.transparent,
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
      prEditProvider(widget.pr.number).select((s) => s.savingTitle),
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
                style: titleStyle?.copyWith(
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
                      textStyle: titleStyle?.copyWith(color: t.textPrimary),
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
