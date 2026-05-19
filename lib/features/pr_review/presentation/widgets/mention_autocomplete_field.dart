import 'dart:async';

import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/shared/widgets/focus_ring.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A multiline markdown text field with `@user` and `#issue` autocomplete.
///
/// When the caret sits on an `@`/`#` token, a dropdown of candidates appears
/// anchored under the field (`@` → assignable users, `#` → open issues/PRs,
/// debounced). Up/Down move the highlight, Enter/Tab accept, Esc dismisses;
/// any other key passes through to the field. Modifier shortcuts (e.g.
/// Cmd+Enter to save, Cmd+B to bold) are intentionally left to ancestor
/// handlers — this field only intercepts the bare navigation keys while the
/// menu is open.
class MentionAutocompleteField extends ConsumerStatefulWidget {
  /// Creates a [MentionAutocompleteField].
  const MentionAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.owner,
    required this.repo,
    required this.hintText,
    this.minLines = 8,
    this.maxLines,
  });

  /// The editor's text controller (shared with the toolbar/keyboard actions).
  final TextEditingController controller;

  /// The editor's focus node (this field installs an `onKeyEvent` handler).
  final FocusNode focusNode;

  /// Active repo owner (for `#` issue search).
  final String owner;

  /// Active repo name (for `#` issue search).
  final String repo;

  /// Placeholder shown when empty.
  final String hintText;

  /// Minimum visible lines.
  final int minLines;

  /// Maximum visible lines (null = grow unbounded).
  final int? maxLines;

  @override
  ConsumerState<MentionAutocompleteField> createState() =>
      _MentionAutocompleteFieldState();
}

class _MentionAutocompleteFieldState
    extends ConsumerState<MentionAutocompleteField> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _overlay = OverlayPortalController();

  Timer? _debounce;
  bool _active = false;
  String _trigger = '';
  String _query = '';
  String _debouncedQuery = '';
  int _tokenStart = -1;
  int _highlighted = 0;

  // Items currently shown — set during build() (where ref.watch is valid) so
  // the key handler can navigate/select them.
  List<_MentionItem> _items = const [];

  static final _tokenRegExp = RegExp(r'(?:^|[\s(])([@#])([\w./-]*)$');

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.focusNode.onKeyEvent = _onKey;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onChanged);
    if (widget.focusNode.onKeyEvent == _onKey) {
      widget.focusNode.onKeyEvent = null;
    }
    super.dispose();
  }

  void _onChanged() {
    final sel = widget.controller.selection;
    final text = widget.controller.text;
    if (!sel.isValid || !sel.isCollapsed) {
      _close();
      return;
    }
    final caret = sel.baseOffset;
    if (caret < 0 || caret > text.length) {
      _close();
      return;
    }
    final match = _tokenRegExp.firstMatch(text.substring(0, caret));
    if (match == null) {
      _close();
      return;
    }
    final trigger = match.group(1)!;
    final query = match.group(2)!;
    final tokenStart = caret - query.length - 1;
    final wasActive = _active;
    setState(() {
      _trigger = trigger;
      _query = query;
      _tokenStart = tokenStart;
      if (!wasActive) {
        _highlighted = 0;
      }
      _active = true;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _debouncedQuery = query);
      }
    });
    if (!_overlay.isShowing) {
      _overlay.show();
    }
  }

  void _close() {
    if (!_active && !_overlay.isShowing) {
      return;
    }
    _active = false;
    if (_overlay.isShowing) {
      _overlay.hide();
    }
    if (mounted) {
      setState(() {});
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_active || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_items.isNotEmpty) {
        setState(() => _highlighted = (_highlighted + 1) % _items.length);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_items.isNotEmpty) {
        setState(
          () => _highlighted = (_highlighted - 1 + _items.length) % _items.length,
        );
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab) {
      if (_items.isNotEmpty && _highlighted < _items.length) {
        _select(_items[_highlighted]);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _select(_MentionItem item) {
    final text = widget.controller.text;
    final caret = widget.controller.selection.baseOffset;
    if (_tokenStart < 0 || caret < _tokenStart || caret > text.length) {
      _close();
      return;
    }
    final insert = '${item.insertText} ';
    final newText = text.replaceRange(_tokenStart, caret, insert);
    final newCaret = _tokenStart + insert.length;
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    );
    _close();
    widget.focusNode.requestFocus();
  }

  List<_MentionItem> _computeItems() {
    if (!_active) {
      return const [];
    }
    if (_trigger == '@') {
      final users = ref.watch(assignableUsersProvider).value ?? const [];
      final q = _query.toLowerCase();
      return [
        for (final u in users)
          if (q.isEmpty || u.login.toLowerCase().contains(q))
            _MentionItem(
              insertText: '@${u.login}',
              primary: u.login,
              avatarUrl: u.avatarUrl,
              isUser: true,
            ),
      ].take(6).toList(growable: false);
    }
    final results = ref
            .watch(issueSearchProvider((
              owner: widget.owner,
              repo: widget.repo,
              query: _debouncedQuery,
            )))
            .value ??
        const [];
    return [
      for (final r in results)
        _MentionItem(
          insertText: '#${r.number}',
          primary: '#${r.number}',
          secondary: r.title,
          isUser: false,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final theme = Theme.of(context);
    _items = _computeItems();
    if (_active && _highlighted >= _items.length) {
      _highlighted = 0;
    }

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: _buildOverlay,
        child: FocusRing(
          focusNode: widget.focusNode,
          child: Container(
            decoration: BoxDecoration(
              color: t.bgSecondary,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: t.borderSecondary),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              cursorColor: t.fgBrandPrimary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.textPrimary,
                height: 1.5,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                // No themed border in any state — the FocusRing draws the focus
                // indicator as an overlay so the box never changes size.
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: t.textPlaceholder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    if (!_active || _items.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360, maxHeight: 240),
                decoration: BoxDecoration(
                  color: t.bgPrimary,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: t.borderSecondary),
                  boxShadow: AppShadows.golden,
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    final selected = i == _highlighted;
                    return _MentionRow(
                      item: item,
                      selected: selected,
                      tokens: t,
                      theme: theme,
                      onTap: () => _select(item),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MentionItem {
  const _MentionItem({
    required this.insertText,
    required this.primary,
    required this.isUser,
    this.secondary,
    this.avatarUrl,
  });

  final String insertText;
  final String primary;
  final String? secondary;
  final String? avatarUrl;
  final bool isUser;
}

/// A single autocomplete row (user or issue).
class _MentionRow extends StatelessWidget {
  const _MentionRow({
    required this.item,
    required this.selected,
    required this.tokens,
    required this.theme,
    required this.onTap,
  });

  final _MentionItem item;
  final bool selected;
  final DesignSystemTokens tokens;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? tokens.bgPrimaryHover : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (item.isUser)
              GitHubUserAvatar(
                login: item.primary,
                avatarUrl: item.avatarUrl,
                size: 18,
                showHoverCard: false,
              )
            else
              SizedBox(
                width: 18,
                child: Text(
                  '#',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.fgQuaternary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: item.primary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.secondary != null)
                      TextSpan(
                        text: '  ${item.secondary}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
