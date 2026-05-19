import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_header_section.dart';
import 'package:control_center/features/pr_review/presentation/widgets/markdown_syntax_actions.dart';
import 'package:control_center/features/pr_review/presentation/widgets/markdown_toolbar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/mention_autocomplete_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The PR description block: renders [readChild] (the collapsible markdown) in
/// read mode with a hover-revealed edit pencil (when [canEdit]), and a
/// GitHub-style Write/Preview markdown editor in edit mode. Editing operates on
/// raw markdown — Preview reuses the exact same renderer as the read view, so
/// there is no GFM round-trip loss.
class PrBodyEditor extends ConsumerStatefulWidget {
  /// Creates a [PrBodyEditor].
  const PrBodyEditor({
    super.key,
    required this.prNumber,
    required this.initialMarkdown,
    required this.repoFullName,
    required this.githubToken,
    required this.canEdit,
    required this.readChild,
    this.bodyHtml,
  });

  /// PR number (for the edit notifier).
  final int prNumber;

  /// Current raw markdown body (seeds the editor when entering edit mode).
  final String initialMarkdown;

  /// owner/repo (for the preview renderer + `#` autocomplete).
  final String repoFullName;

  /// GitHub token forwarded to authenticated image fetches in the preview.
  final String githubToken;

  /// Whether the current user may edit the body.
  final bool canEdit;

  /// The read-mode widget (collapsible markdown) shown when not editing.
  final Widget readChild;

  /// GitHub-rendered HTML for the body (passed through to the preview).
  final String? bodyHtml;

  @override
  ConsumerState<PrBodyEditor> createState() => _PrBodyEditorState();
}

class _PrBodyEditorState extends ConsumerState<PrBodyEditor> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _editing = false;
  bool _showPreview = false;
  bool _hovered = false;

  String get _owner =>
      widget.repoFullName.contains('/') ? widget.repoFullName.split('/')[0] : '';
  String get _repo =>
      widget.repoFullName.contains('/') ? widget.repoFullName.split('/')[1] : '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _controller.text = widget.initialMarkdown;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _editing = true;
      _showPreview = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _applyFormat(TextEditingValue Function(TextEditingValue) transform) {
    _controller.value = transform(_controller.value);
    _focusNode.requestFocus();
  }

  Future<void> _save() async {
    final notifier = ref.read(prEditProvider(widget.prNumber).notifier);
    final scaffold = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final error = await notifier.saveBody(_controller.text);
    if (!mounted) {
      return;
    }
    if (error == null) {
      setState(() => _editing = false);
    } else {
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.failedToUpdateDescription(error))),
      );
    }
  }

  Future<void> _cancel() async {
    if (_controller.text == widget.initialMarkdown) {
      setState(() => _editing = false);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final discard = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.discardChangesConfirm),
        actions: [
          FButton(
            onPress: () => Navigator.pop(ctx, false),
            variant: FButtonVariant.ghost,
            mainAxisSize: MainAxisSize.min,
            child: Text(l10n.cancel),
          ),
          FButton(
            onPress: () => Navigator.pop(ctx, true),
            variant: FButtonVariant.destructive,
            mainAxisSize: MainAxisSize.min,
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return _buildRead(context);
    }
    return _buildEdit(context);
  }

  Widget _buildRead(BuildContext context) {
    if (!widget.canEdit) {
      return widget.readChild;
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    // An empty body renders as a single faint line ("No description
    // provided."), which gives the hover-revealed pencil almost no surface to
    // appear over — in practice it's unreachable, so there's no way to add a
    // first description. Swap in an explicit, always-visible affordance that
    // opens the editor on tap.
    if (isMarkdownBodyEffectivelyEmpty(widget.initialMarkdown)) {
      return _buildEmptyAffordance(context, t);
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        children: [
          widget.readChild,
          if (_hovered)
            Positioned(
              top: 0,
              right: 0,
              child: FTooltip(
                tipBuilder: (_, _) =>
                    Text(AppLocalizations.of(context).editDescription),
                child: FTappable(
                  onPress: _startEdit,
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.bgPrimary,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: t.borderSecondary),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      LucideIcons.pencil,
                      size: 14,
                      color: t.fgQuaternary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The empty-body read state when the user may edit: the
  /// "No description provided." placeholder paired with an always-visible
  /// "Add a description" action. Tapping anywhere opens the editor.
  Widget _buildEmptyAffordance(BuildContext context, DesignSystemTokens t) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: FTappable(
        onPress: _startEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.noDescriptionProvided,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: t.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Icon(LucideIcons.pencil, size: 13, color: t.textBrandPrimary),
              const SizedBox(width: 5),
              Text(
                l10n.addDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: t.textBrandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEdit(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final saving = ref.watch(
      prEditProvider(widget.prNumber).select((s) => s.savingBody),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
            _applyFormat((v) => wrapSelection(v, '**', '**')),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            _applyFormat((v) => wrapSelection(v, '**', '**')),
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
            _applyFormat((v) => wrapSelection(v, '_', '_')),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            _applyFormat((v) => wrapSelection(v, '_', '_')),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _applyFormat(insertLink),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _applyFormat(insertLink),
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _SegChip(
                label: l10n.write,
                selected: !_showPreview,
                tokens: t,
                onTap: () => setState(() => _showPreview = false),
              ),
              const SizedBox(width: 4),
              _SegChip(
                label: l10n.preview,
                selected: _showPreview,
                tokens: t,
                onTap: () => setState(() => _showPreview = true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_showPreview) ...[
            MarkdownToolbar(controller: _controller, focusNode: _focusNode),
            const SizedBox(height: 8),
            MentionAutocompleteField(
              controller: _controller,
              focusNode: _focusNode,
              owner: _owner,
              repo: _repo,
              hintText: l10n.prBodyPlaceholder,
            ),
          ] else
            _PreviewBox(
              tokens: t,
              child: PrBodyMarkdown(
                body: _controller.text,
                repoFullName: widget.repoFullName,
                githubToken: widget.githubToken,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                onPress: saving ? null : _cancel,
                variant: FButtonVariant.outline,
                size: FButtonSizeVariant.sm,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: saving ? null : _save,
                size: FButtonSizeVariant.sm,
                mainAxisSize: MainAxisSize.min,
                child: saving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: t.textWhite,
                        ),
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.tokens, required this.child});

  final DesignSystemTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: tokens.borderSecondary),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: child,
    );
  }
}

class _SegChip extends StatelessWidget {
  const _SegChip({
    required this.label,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final DesignSystemTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FTappable(
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? tokens.bgSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: selected ? tokens.borderSecondary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? tokens.textPrimary : tokens.textSecondary,
          ),
        ),
      ),
    );
  }
}
