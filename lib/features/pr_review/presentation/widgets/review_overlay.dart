import 'dart:async';
import 'dart:convert';

import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/presentation/widgets/emoji_chooser.dart';
import 'package:control_center/features/pr_review/presentation/widgets/github_reference_link_builder.dart';
import 'package:control_center/features/pr_review/presentation/widgets/klipy_gif_picker.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Button that opens the approve/review overlay.
class ReviewOverlayButton extends ConsumerStatefulWidget {
  /// ReviewOverlayButton({.
  const ReviewOverlayButton({
    super.key,
    required this.pr,
    required this.owner,
    required this.repo,
  });

  /// PullRequest.
  final PullRequest pr;

  /// GitHub repository owner.
  final String owner;

  /// GitHub repository name.
  final String repo;

  @override
  ConsumerState<ReviewOverlayButton> createState() =>
      _ReviewOverlayButtonState();
}

class _ReviewOverlayButtonState extends ConsumerState<ReviewOverlayButton> {
  final OverlayPortalController _popupCtrl = OverlayPortalController();
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final _emojiKey = GlobalKey();
  final _gifKey = GlobalKey();
  final _buttonKey = GlobalKey();
  bool _showPreview = false;
  Timer? _draftTimer;
  bool _draftLoaded = false;
  bool _saving = false;
  Offset? _overlayOffset;

  late final PrReviewRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(prReviewRepositoryProvider);
    _commentCtrl.addListener(_onCommentChanged);
  }

  @override
  void dispose() {
    if (_popupCtrl.isShowing) {
      _popupCtrl.hide();
    }
    unawaited(_saveDraft());
    _draftTimer?.cancel();
    _commentCtrl.removeListener(_onCommentChanged);
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _onCommentChanged() {
    _autoReplaceShortcodes();
    _scheduleDraftSave();
  }

  void _autoReplaceShortcodes() {
    final text = _commentCtrl.text;
    final pattern = RegExp(r':([a-zA-Z0-9_+-]+):');
    final match = pattern.firstMatch(text);
    if (match == null) {
      return;
    }

    final name = match.group(1)!;
    final parser = EmojiParser();
    if (!parser.hasName(name)) {
      return;
    }

    final emojiChar = parser.get(name).code;
    final start = match.start;
    final end = match.end;
    _commentCtrl.removeListener(_onCommentChanged);
    _commentCtrl.text =
        text.substring(0, start) + emojiChar + text.substring(end);
    _commentCtrl.selection = TextSelection.collapsed(
      offset: start + emojiChar.length,
    );
    _commentCtrl.addListener(_onCommentChanged);
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 800), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (_saving) {
      return;
    }

    final text = _commentCtrl.text;
    if (text.isEmpty) {
      return;
    }

    if (widget.owner.isEmpty || widget.repo.isEmpty) {
      return;
    }

    try {
      _saving = true;
      await _repo.upsertDraft(widget.pr.number, text);
    } finally {
      _saving = false;
    }
  }

  Future<void> _clearDraft() async {
    if (widget.owner.isEmpty || widget.repo.isEmpty) {
      return;
    }

    await _repo.clearDraft(widget.pr.number);
  }

  Future<void> _loadDraft() async {
    if (_draftLoaded) {
      return;
    }

    if (widget.owner.isEmpty || widget.repo.isEmpty) {
      return;
    }

    final draft = await _repo.getDraft(widget.pr.number);
    if (draft != null && draft.isNotEmpty) {
      _commentCtrl.text = draft;
      _draftLoaded = true;
    }
  }

  void _toggle() {
    if (_popupCtrl.isShowing) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _computeOverlayOffset();
    _popupCtrl.show();
    _loadDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentFocus.requestFocus();
    });
    setState(() {});
  }

  void _close() {
    _draftTimer?.cancel();
    unawaited(_saveDraft());
    _popupCtrl.hide();
    _showPreview = false;
  }

  static const _overlayWidth = 520.0;

  void _computeOverlayOffset() {
    final ctx = _buttonKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) {
      return;
    }

    final buttonBottomRight = box.localToGlobal(
      Offset(box.size.width, box.size.height),
      ancestor: overlay,
    );
    final left = (buttonBottomRight.dx - _overlayWidth).clamp(
      0.0,
      (overlay.size.width - _overlayWidth).clamp(0.0, double.infinity),
    );
    final top = buttonBottomRight.dy + 8;
    _overlayOffset = Offset(left, top);
  }

  Future<void> _approve() async {
    final scaffold = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final comment = _commentCtrl.text;
    ref
        .read(prOptimisticReviewStateProvider.notifier)
        .set(widget.pr.number, PrReviewSubmissionState.approved);
    _close();
    try {
      await _repo.submitReview(
        prNumber: widget.pr.number,
        event: 'APPROVE',
        body: comment.isEmpty ? null : comment,
      );
      unawaited(_clearDraft());
      scaffold.showSnackBar(SnackBar(content: Text(l10n.pullRequestApproved)));
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      ref
          .read(prOptimisticReviewStateProvider.notifier)
          .set(widget.pr.number, null);
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.failedToSubmitReview('$e'))),
      );
    }
  }

  Future<void> _requestChanges() async {
    final scaffold = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final comment = _commentCtrl.text;
    ref
        .read(prOptimisticReviewStateProvider.notifier)
        .set(widget.pr.number, PrReviewSubmissionState.changesRequested);
    _close();
    try {
      await _repo.submitReview(
        prNumber: widget.pr.number,
        event: 'REQUEST_CHANGES',
        body: comment.isEmpty ? null : comment,
      );
      unawaited(_clearDraft());
      scaffold.showSnackBar(SnackBar(content: Text(l10n.changesRequested)));
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      ref
          .read(prOptimisticReviewStateProvider.notifier)
          .set(widget.pr.number, null);
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.failedToSubmitReview('$e'))),
      );
    }
  }

  void _insertAtCursor(String text) {
    final ctrl = _commentCtrl;
    final selection = ctrl.selection;
    final old = ctrl.text;
    if (selection.isValid && selection.start >= 0) {
      final start = selection.start;
      final end = selection.end;
      ctrl.text = old.substring(0, start) + text + old.substring(end);
      ctrl.selection = TextSelection.collapsed(offset: start + text.length);
    } else {
      ctrl.text = old + text;
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }
  }

  Future<void> _attachFile() async {
    final owner = widget.owner;
    final repo = widget.repo;
    if (owner.isEmpty || repo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).noActiveWorkspaceGithub),
        ),
      );
      return;
    }
    final files = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(
          label: AppLocalizations.of(context).images,
          extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
        ),
      ],
    );
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final base64 = base64Encode(bytes);
        final uniqueId = DateTime.now().millisecondsSinceEpoch;
        final path = '.github/pr-assets/${uniqueId}_${file.name}';
        final url = await _repo.uploadContent(
          path,
          base64,
          'Upload image for PR review',
        );
        _insertAtCursor('![${file.name}]($url)\n');
      } on Exception catch (e) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).failedToUpload(file.name, '$e'),
            ),
          ),
        );
      }
    }
  }

  Offset? _buttonPosition(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) {
      return null;
    }

    final box = ctx.findRenderObject() as RenderBox?;
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
      onGifSelected: (gif) => _insertAtCursor('![gif](${gif.url})\n'),
      anchorPosition: _buttonPosition(_gifKey),
    );
  }

  PrReviewSubmissionState? get _myReviewState {
    final optimistic = ref.read(
      prOptimisticReviewStateProvider,
    )[widget.pr.number];
    if (optimistic != null) {
      final reviews = ref
          .read(prReviewsProvider(widget.pr.number))
          .asData
          ?.value;
      if (reviews != null) {
        final myLogin = ref.read(currentUserLoginProvider);
        if (myLogin.isNotEmpty) {
          for (final r in reviews.reversed) {
            if (r.author?.login.toLowerCase() == myLogin) {
              if (r.state == optimistic) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ref
                        .read(prOptimisticReviewStateProvider.notifier)
                        .set(widget.pr.number, null);
                  }
                });
              }
              break;
            }
          }
        }
      }
      return optimistic;
    }

    final reviews = ref.read(prReviewsProvider(widget.pr.number)).asData?.value;
    if (reviews == null || reviews.isEmpty) {
      return null;
    }
    final myLogin = ref.read(currentUserLoginProvider);
    if (myLogin.isEmpty) {
      return null;
    }
    for (final r in reviews.reversed) {
      if (r.author?.login.toLowerCase() == myLogin) {
        return r.state;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(prOptimisticReviewStateProvider);
    final myState = _myReviewState;
    final isApproved = myState == PrReviewSubmissionState.approved;
    final isChangesRequested =
        myState == PrReviewSubmissionState.changesRequested;

    final label = switch (myState) {
      PrReviewSubmissionState.approved => AppLocalizations.of(context).approved,
      PrReviewSubmissionState.changesRequested => AppLocalizations.of(
        context,
      ).requestedChanges,
      _ => AppLocalizations.of(context).review,
    };

    final icon = switch (myState) {
      PrReviewSubmissionState.approved => LucideIcons.checkCircle2,
      PrReviewSubmissionState.changesRequested => LucideIcons.xCircle,
      _ => LucideIcons.checkCircle,
    };

    final fgColor = switch (myState) {
      PrReviewSubmissionState.approved => const Color(0xFF2DA44E),
      PrReviewSubmissionState.changesRequested => const Color(0xFFCF222E),
      _ => null,
    };

    return OverlayPortal(
      controller: _popupCtrl,
      overlayChildBuilder: _buildOverlay,
      child: FButton(
        key: _buttonKey,
        onPress: _toggle,
        mainAxisSize: MainAxisSize.min,
        size: FButtonSizeVariant.sm,
        variant: isChangesRequested
            ? FButtonVariant.destructive
            : isApproved
            ? FButtonVariant.outline
            : FButtonVariant.primary,
        prefix: Icon(icon, color: fgColor),
        child: Text(label),
      ),
    );
  }

  Widget _buildOverlay(BuildContext overlayCtx) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final codeFont = ref.watch(codeFontFamilyProvider);
    final offset = _overlayOffset ?? Offset.zero;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        Positioned(
          left: offset.dx,
          top: offset.dy,
          width: _overlayWidth,
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _close();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: RepaintBoundary(
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: tokens.bgPrimary,
                child: Container(
                  width: _overlayWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.borderSecondary),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Approve changes',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: tokens.bgSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tokens.borderSecondary),
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _commentCtrl,
                              focusNode: _commentFocus,
                              minLines: 5,
                              maxLines: 10,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.textPrimary,
                              ),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: tokens.focusRing,
                                    width: 2,
                                  ),
                                ),
                                hintText:
                                    'Simply click approve, or if you\'re feeling '
                                    'spicy add a comment or reaction\u2026',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: tokens.textPlaceholder,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                FTooltip(
                                  tipBuilder: (_, _) => Text(l10n.attachImage),
                                  child: FButton.icon(
                                    onPress: _attachFile,
                                    child: Icon(
                                      LucideIcons.image,
                                      size: 16,
                                      color: tokens.fgSecondary,
                                    ),
                                  ),
                                ),
                                EmojiPopover(
                                  onEmojiSelected: _insertAtCursor,
                                  child: FTooltip(
                                    tipBuilder: (_, _) => Text(l10n.addEmoji),
                                    child: FButton.icon(
                                      key: _emojiKey,
                                      onPress: () {},
                                      child: Icon(
                                        LucideIcons.smile,
                                        size: 16,
                                        color: tokens.fgSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                FTooltip(
                                  tipBuilder: (_, _) => Text(l10n.addGif),
                                  child: FButton.icon(
                                    key: _gifKey,
                                    onPress: _addGif,
                                    child: Icon(
                                      LucideIcons.clapperboard,
                                      size: 16,
                                      color: tokens.fgSecondary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                FTooltip(
                                  tipBuilder: (_, _) => Text(
                                    _showPreview
                                        ? AppLocalizations.of(
                                            context,
                                          ).writeLabel
                                        : AppLocalizations.of(
                                            context,
                                          ).previewLabel,
                                  ),
                                  child: FButton.icon(
                                    onPress: () {
                                      setState(
                                        () => _showPreview = !_showPreview,
                                      );
                                    },
                                    child: Icon(
                                      _showPreview
                                          ? LucideIcons.pencil
                                          : LucideIcons.eye,
                                      size: 16,
                                      color: tokens.fgSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_showPreview) ...[
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: tokens.bgSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: tokens.borderSecondary),
                          ),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            child: GitHubMarkdownBody(
                              data: _commentCtrl.text.isEmpty
                                  ? 'Nothing to preview'
                                  : _commentCtrl.text,
                              repoOwner: widget.owner,
                              repoName: widget.repo,
                              githubToken: ref.watch(githubAuthTokenProvider),
                              styleSheet: MarkdownStyleSheet(
                                p: theme.textTheme.bodyMedium?.copyWith(
                                  color: tokens.textPrimary,
                                ),
                                code: AppFonts.codeStyleDynamic(
                                  codeFont,
                                  fontSize:
                                      theme.textTheme.bodySmall?.fontSize,
                                  color: tokens.textSecondary,
                                ),
                              ),
                              builders: {
                                'code': InlineCodeBuilder(),
                                'pre': CodeBlockBuilder(
                                  codeFontFamily: codeFont,
                                ),
                                'a': GitHubReferenceLinkBuilder(
                                  currentOwner: widget.owner,
                                  currentRepo: widget.repo,
                                  knownWorkspaceRepos: _activeWorkspaceRepoKeys(
                                    ref,
                                  ),
                                  onSwitchToRepo: (workspaceId, repoId) async {
                                    await ref
                                        .read(
                                          activeWorkspaceIdProvider.notifier,
                                        )
                                        .setActive(workspaceId);
                                    await ref
                                        .read(activeRepoIdProvider.notifier)
                                        .setActive(repoId);
                                  },
                                ),
                              },
                              checkboxBuilder: markdownCheckboxBuilder(context),
                              onSwitchToRepo: (workspaceId, repoId) async {
                                await ref
                                    .read(activeWorkspaceIdProvider.notifier)
                                    .setActive(workspaceId);
                                await ref
                                    .read(activeRepoIdProvider.notifier)
                                    .setActive(repoId);
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const FDivider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FButton(
                              onPress: _approve,
                              child: Text(l10n.approve),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FButton(
                              onPress: _requestChanges,
                              variant: FButtonVariant.secondary,
                              child: Text(l10n.requestChanges),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Set<String> _activeWorkspaceRepoKeys(WidgetRef ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const <String>{};
  }
  final repos =
      ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
  return repos
      .map(
        (r) =>
            '${r.githubOwner.toLowerCase()}/${r.githubRepoName.toLowerCase()}',
      )
      .toSet();
}
