import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_header_section.dart';
import 'package:control_center/features/pr_review/presentation/widgets/mention_autocomplete_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:control_center/shared/widgets/markdown/markdown_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The PR description block: renders [readChild] (the collapsible markdown) in
/// read mode with a hover-revealed edit pencil (when [canEdit]), and the shared
/// GitHub-style Write/Preview [MarkdownEditor] in edit mode (with `@`/`#`
/// autocomplete). Editing operates on raw markdown — Preview reuses the exact
/// same renderer as the read view, so there is no GFM round-trip loss.
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
  bool _hovered = false;

  String get _owner => widget.repoFullName.contains('/')
      ? widget.repoFullName.split('/')[0]
      : '';
  String get _repo => widget.repoFullName.contains('/')
      ? widget.repoFullName.split('/')[1]
      : '';

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
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
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
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MarkdownEditor(
            controller: _controller,
            focusNode: _focusNode,
            fieldBuilder: (context) => MentionAutocompleteField(
              controller: _controller,
              focusNode: _focusNode,
              owner: _owner,
              repo: _repo,
              hintText: l10n.prBodyPlaceholder,
            ),
            previewBuilder: (context) => PrBodyMarkdown(
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
