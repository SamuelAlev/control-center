import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/suggestion_renderer.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pr inline thread block.
class PrInlineThreadBlock extends ConsumerStatefulWidget {
  /// PrInlineThreadBlock({.
  const PrInlineThreadBlock({
    super.key,
    required this.thread,
    required this.controller,
  });

  /// PrInlineThread.
  final PrInlineThread thread;

  /// In-memory controller for draft inline review threads.
  final PrInlineCommentsController controller;

  @override
  ConsumerState<PrInlineThreadBlock> createState() =>
      _PrInlineThreadBlockState();
}

class _PrInlineThreadBlockState extends ConsumerState<PrInlineThreadBlock> {
  final _replyCtrl = TextEditingController();
  final _replyFocus = FocusNode();
  bool _replying = false;
  String? _editingEntryId;

  @override
  void dispose() {
    _replyCtrl.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) {
      return;
    }

    widget.controller.reply(threadId: widget.thread.id, body: text);
    _replyCtrl.clear();
    setState(() => _replying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final thread = widget.thread;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: theme.colors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 0),
            child: Row(
              children: [
                Text(
                  thread.entries.length == 1
                      ? '1 comment'
                      : '${thread.entries.length} comments',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: theme.colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                _SyncBadge(
                  state: thread.syncState,
                  error: thread.syncError,
                  onRetry: thread.syncState == PrInlineSyncState.error
                      ? () => widget.controller.retryPost(thread.id)
                      : null,
                ),
                const Spacer(),
                FTooltip(
                  tipBuilder: (_, _) => Text(
                    thread.resolved
                        ? AppLocalizations.of(context).reopen
                        : AppLocalizations.of(context).resolve,
                  ),
                  child: FButton.icon(
                    onPress: () => widget.controller.toggleResolved(thread.id),
                    child: Icon(
                      thread.resolved
                          ? LucideIcons.checkCircle2
                          : LucideIcons.check,
                      size: 16,
                      color: thread.resolved
                          ? const Color(0xFF2DA44E)
                          : theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < thread.entries.length; i++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: _InlineEntryTile(
                entry: thread.entries[i],
                originalCode: thread.originalCode,
                filePath: thread.filePath,
                originalStartLine: thread.line,
                isEditing: _editingEntryId == thread.entries[i].id,
                onEditStart: thread.isSuggestion && i == 0
                    ? () =>
                          setState(() => _editingEntryId = thread.entries[i].id)
                    : null,
                onEditSubmit: thread.isSuggestion && i == 0
                    ? (newBody) {
                        widget.controller.updateEntry(
                          threadId: thread.id,
                          entryId: thread.entries[i].id,
                          newBody: newBody,
                        );
                        setState(() => _editingEntryId = null);
                      }
                    : null,
                onEditCancel: thread.isSuggestion && i == 0
                    ? () => setState(() => _editingEntryId = null)
                    : null,
              ),
            ),
            if (i != thread.entries.length - 1) const FDivider(),
          ],
          if (thread.isSuggestion && !thread.resolved) ...[
            const FDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  FButton(
                    onPress: () =>
                        widget.controller.acceptSuggestion(thread.id),
                    mainAxisSize: MainAxisSize.min,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.checkCheck, size: 14),
                        const SizedBox(width: 6),
                        Text(AppLocalizations.of(context).acceptAndResolve),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: () => widget.controller.dismissThread(thread.id),
                    variant: FButtonVariant.outline,
                    mainAxisSize: MainAxisSize.min,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.archive, size: 14),
                        const SizedBox(width: 6),
                        Text(AppLocalizations.of(context).dismiss),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const FDivider(),
          if (_replying)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SelectionContainer.disabled(
                      child: TextField(
                        controller: _replyCtrl,
                        focusNode: _replyFocus,
                        autofocus: true,
                        style: Theme.of(context).textTheme.bodyMedium,
                        onSubmitted: (_) => _sendReply(),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).replyEllipsis,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(2),
                            borderSide: BorderSide(color: theme.colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(2),
                            borderSide: BorderSide(color: theme.colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(2),
                            borderSide: BorderSide(color: theme.colors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SendButton(onPressed: _sendReply),
                ],
              ),
            )
          else
            InkWell(
              onTap: () {
                setState(() => _replying = true);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _replyFocus.requestFocus(),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.messageSquare,
                      size: 14,
                      color: theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).replyEllipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineEntryTile extends StatelessWidget {
  const _InlineEntryTile({
    required this.entry,
    required this.originalCode,
    this.filePath,
    this.originalStartLine,
    this.isEditing = false,
    this.onEditStart,
    this.onEditSubmit,
    this.onEditCancel,
  });

  final PrInlineEntry entry;
  final String originalCode;
  final String? filePath;
  final int? originalStartLine;
  final bool isEditing;
  final VoidCallback? onEditStart;
  final void Function(String newBody)? onEditSubmit;
  final VoidCallback? onEditCancel;

  static final RegExp _suggestionFence = RegExp(
    r'```suggestion\s*\n([\s\S]*?)\n?```',
    multiLine: true,
  );
  bool get _isSuggestionEntry => _suggestionFence.hasMatch(entry.body);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GitHubUserAvatar(
          login: entry.author,
          avatarUrl: entry.authorAvatarUrl,
          size: 24,
          showHoverCard: false,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatRelative(entry.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  if (_isSuggestionEntry && onEditStart != null) ...[
                    const SizedBox(width: 4),
                    FTooltip(
                      tipBuilder: (_, _) => Text(
                        isEditing
                            ? AppLocalizations.of(context).cancelEdit
                            : AppLocalizations.of(context).editSuggestion,
                      ),
                      child: FButton.icon(
                        onPress: () {
                          if (isEditing) {
                            onEditCancel?.call();
                          } else {
                            onEditStart?.call();
                          }
                        },
                        child: Icon(
                          isEditing ? LucideIcons.x : LucideIcons.pencil,
                          size: 16,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              if (isEditing && onEditSubmit != null)
                _SuggestionEditor(
                  initialCode: _extractSuggestedCode(),
                  onSubmit: onEditSubmit!,
                  onCancel: onEditCancel ?? () {},
                )
              else
                SuggestionAwareMarkdown(
                  body: entry.body,
                  originalCode: originalCode,
                  filePath: filePath,
                  originalStartLine: originalStartLine,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _extractSuggestedCode() {
    final match = _suggestionFence.firstMatch(entry.body);
    return match?.group(1)?.trim() ?? '';
  }
}

class _SuggestionEditor extends ConsumerStatefulWidget {
  const _SuggestionEditor({
    required this.initialCode,
    required this.onSubmit,
    required this.onCancel,
  });
  final String initialCode;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  @override
  ConsumerState<_SuggestionEditor> createState() => _SuggestionEditorState();
}

class _SuggestionEditorState extends ConsumerState<_SuggestionEditor> {
  late final _ctrl = TextEditingController(text: widget.initialCode);
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final replacement = _ctrl.text;
    if (replacement.trim().isEmpty) {
      widget.onCancel();
      return;
    }
    widget.onSubmit('```suggestion\n$replacement\n```');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: theme.colors.border),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectionContainer.disabled(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              autofocus: true,
              maxLines: null,
              minLines: 2,
              style: AppFonts.codeStyleDynamic(
                ref.watch(codeFontFamilyProvider),
                fontSize: 12,
                height: 1.55,
                color: theme.colors.foreground,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.colors.primary, width: 2),
                ),
                hintText: AppLocalizations.of(context).editSuggestedCodeHint,
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                variant: FButtonVariant.outline,
                onPress: widget.onCancel,
                child: Text(AppLocalizations.of(context).cancel),
              ),
              const SizedBox(width: 8),
              _SendButton(onPressed: _submit),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({
    required this.state,
    required this.error,
    required this.onRetry,
  });
  final PrInlineSyncState state;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final (label, color, icon) = switch (state) {
      PrInlineSyncState.local => (
        AppLocalizations.of(context).draftLabel,
        theme.colors.mutedForeground,
        LucideIcons.cloudOff,
      ),
      PrInlineSyncState.pending => (
        AppLocalizations.of(context).postingEllipsis,
        theme.colors.mutedForeground,
        LucideIcons.loader,
      ),
      PrInlineSyncState.synced => (
        AppLocalizations.of(context).synced,
        const Color(0xFF2DA44E),
        LucideIcons.cloud,
      ),
      PrInlineSyncState.error => (
        AppLocalizations.of(context).failed,
        const Color(0xFFCF222E),
        LucideIcons.alertCircle,
      ),
    };
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
    if (onRetry == null) {
      return FTooltip(tipBuilder: (_, _) => Text(error ?? label), child: pill);
    }

    return FTooltip(
      tipBuilder: (_, _) =>
          Text(error ?? AppLocalizations.of(context).clickToRetry),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onRetry, child: pill),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowUp, size: 16, color: Colors.white),
      visualDensity: VisualDensity.compact,
      tooltip: AppLocalizations.of(context).send,
      onPressed: onPressed,
      style: IconButton.styleFrom(backgroundColor: const Color(0xFF1F75FE)),
    );
  }
}
