import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/emoji_chooser.dart';
import 'package:control_center/features/pr_review/presentation/widgets/github_reference_link_builder.dart';
import 'package:control_center/features/pr_review/presentation/widgets/klipy_gif_picker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/mention_autocomplete_field.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:control_center/shared/widgets/markdown/markdown_editor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// THE input for every PR comment — inline diff comments, thread replies and
/// the review body alike.
///
/// Before this existed, the review overlay had emoji, GIFs, image upload and a
/// preview toggle all inlined into it and reachable from nowhere else, while
/// every actual comment box was a bare `CcTextField` with a send button. Same
/// act, three different affordances depending on where you happened to click.
/// One widget now carries the whole vocabulary:
///
///  * Write/Preview and the formatting toolbar, from the shared
///    [MarkdownEditor] (so ⌘B/⌘I/⌘K work here exactly as in a PR body);
///  * `@user` / `#issue` autocomplete, from [MentionAutocompleteField];
///  * emoji, GIF and (where the host can upload) image, as toolbar inserters;
///  * `:shortcode:` → emoji as you type;
///  * a preview rendered by the SAME renderer the posted comment will use, so
///    what the preview shows is what GitHub will show.
///
/// The host still owns submission: buttons, keyboard shortcuts, drafts and
/// what "send" means all vary per surface and stay outside.
class PrCommentField extends ConsumerStatefulWidget {
  /// Creates a [PrCommentField].
  const PrCommentField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.owner = '',
    this.repo = '',
    this.minLines = 3,
    this.maxLines = 10,
    this.autofocus = false,
    this.onSubmitted,
    this.onAttachImage,
    this.previewMaxHeight = 240,
    this.footer,
  });

  /// The comment's text controller, owned by the host (which reads it on send
  /// and may restore a draft into it).
  final TextEditingController controller;

  /// The field's focus node.
  final FocusNode focusNode;

  /// Placeholder shown when empty.
  final String hintText;

  /// Repo owner, for `#issue` autocomplete and reference links in the preview.
  /// Empty disables both rather than erroring — a comment surface with no repo
  /// context is still a usable text field.
  final String owner;

  /// Repo name; see [owner].
  final String repo;

  /// Minimum visible lines.
  final int minLines;

  /// Maximum visible lines.
  final int? maxLines;

  /// Whether the field takes focus on mount.
  final bool autofocus;

  /// Invoked on the field's submit action.
  final ValueChanged<String>? onSubmitted;

  /// Uploads an image and returns its URL, or null to offer no image button.
  /// Only hosts with repo write access can supply one.
  final Future<void> Function()? onAttachImage;

  /// Cap on the preview's height before it scrolls.
  final double previewMaxHeight;

  /// Built beneath the field in both Write and Preview — the host's submit
  /// row, which must not vanish when the reader flips to Preview.
  final WidgetBuilder? footer;

  @override
  ConsumerState<PrCommentField> createState() => _PrCommentFieldState();
}

class _PrCommentFieldState extends ConsumerState<PrCommentField> {
  final GlobalKey _gifKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(PrCommentField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => _autoReplaceShortcodes();

  /// Turns a completed `:shortcode:` into its emoji as it is typed. The
  /// listener is detached across the rewrite: setting `text` fires it again,
  /// and re-entering here would match the same region a second time.
  void _autoReplaceShortcodes() {
    final text = widget.controller.text;
    final match = _shortcode.firstMatch(text);
    if (match == null) {
      return;
    }
    final name = match.group(1)!;
    final parser = EmojiParser();
    if (!parser.hasName(name)) {
      return;
    }
    final emoji = parser.get(name).code;
    widget.controller.removeListener(_onChanged);
    widget.controller.text =
        text.substring(0, match.start) + emoji + text.substring(match.end);
    widget.controller.selection = TextSelection.collapsed(
      offset: match.start + emoji.length,
    );
    widget.controller.addListener(_onChanged);
  }

  /// Inserts [text] at the caret, or appends when there is no valid caret (the
  /// field has never been focused — picking an emoji first is legal).
  void _insertAtCursor(String text) {
    final ctrl = widget.controller;
    final selection = ctrl.selection;
    final old = ctrl.text;
    if (selection.isValid && selection.start >= 0) {
      final next = old.replaceRange(selection.start, selection.end, text);
      ctrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(
          offset: selection.start + text.length,
        ),
      );
    } else {
      ctrl.value = TextEditingValue(
        text: old + text,
        selection: TextSelection.collapsed(offset: old.length + text.length),
      );
    }
    widget.focusNode.requestFocus();
  }

  Offset? _gifAnchor() {
    final box = _gifKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return null;
    }
    return box.localToGlobal(
      Offset.zero,
      ancestor: Overlay.of(context).context.findRenderObject(),
    );
  }

  Future<void> _addGif() async {
    await showGifPicker(
      anchor: context,
      rpcClient: ref.read(rpcClientProvider),
      onGifSelected: (gif) => _insertAtCursor('![gif](${gif.url})\n'),
      anchorPosition: _gifAnchor(),
    );
  }

  /// `owner/name` for every repo in the active workspace — lets the preview's
  /// link builder tell an in-app reference from an outbound one.
  Set<String> _workspaceRepoKeys() {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const <String>{};
    }
    final repos =
        ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
    return {
      for (final r in repos)
        '${r.remoteOwner.toLowerCase()}/${r.remoteName.toLowerCase()}',
    };
  }

  Future<void> _switchToRepo(String workspaceId, String repoId) async {
    await ref.read(activeWorkspaceIdProvider.notifier).setActive(workspaceId);
    await ref.read(activeRepoIdProvider.notifier).setActive(repoId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasRepo = widget.owner.isNotEmpty && widget.repo.isNotEmpty;

    return MarkdownEditor(
      controller: widget.controller,
      focusNode: widget.focusNode,
      onAttach: widget.onAttachImage,
      toolbarTrailing: [
        EmojiPopover(
          onEmojiSelected: _insertAtCursor,
          child: CcIconButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () {},
            icon: AppIcons.smile,
            tooltip: l10n.addEmoji,
          ),
        ),
        CcIconButton(
          key: _gifKey,
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          onPressed: _addGif,
          icon: AppIcons.clapperboard,
          tooltip: l10n.addGif,
        ),
      ],
      fieldBuilder: (context) => MentionAutocompleteField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        owner: widget.owner,
        repo: widget.repo,
        hintText: widget.hintText,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        autofocus: widget.autofocus,
        onSubmitted: widget.onSubmitted,
      ),
      previewBuilder: (context) {
        final text = widget.controller.text.trim();
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.previewMaxHeight),
          child: SingleChildScrollView(
            child: text.isEmpty
                ? Text(
                    l10n.nothingToPreview,
                    style: CcTypography.body.copyWith(
                      color: context.ds.textTertiary,
                    ),
                  )
                : GitHubMarkdownBody(
                    data: text,
                    repoOwner: hasRepo ? widget.owner : null,
                    repoName: hasRepo ? widget.repo : null,
                    compact: true,
                    codeFontFamily: ref.watch(codeFontFamilyProvider),
                    codeLigatures: ref.watch(codeFontLigaturesProvider),
                    linkBuilder: hasRepo
                        ? GitHubReferenceLinkBuilder(
                            currentOwner: widget.owner,
                            currentRepo: widget.repo,
                            knownWorkspaceRepos: _workspaceRepoKeys(),
                            onSwitchToRepo: _switchToRepo,
                          )
                        : null,
                    onSwitchToRepo: _switchToRepo,
                  ),
          ),
        );
      },
      footer: widget.footer,
    );
  }
}

final RegExp _shortcode = RegExp(r':([a-zA-Z0-9_+-]+):');
