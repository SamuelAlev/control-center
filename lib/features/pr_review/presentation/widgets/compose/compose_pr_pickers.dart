import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/presentation/widgets/picker_flyout.dart';
import 'package:control_center/features/pr_review/providers/compose_pr_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The compose-screen metadata sidebar: assignee and reviewer pickers that
/// stage selections into [composePrProvider] (no live GitHub calls — they're
/// applied when the PR is created).
class ComposePrSidebar extends ConsumerWidget {
  /// Creates a [ComposePrSidebar].
  const ComposePrSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignees = ref.watch(composePrProvider.select((s) => s.assignees));
    final reviewers = ref.watch(composePrProvider.select((s) => s.reviewers));
    final notifier = ref.read(composePrProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ComposeReviewerPicker(current: reviewers),
        _SelectedChips(
          children: [
            for (final r in reviewers)
              _Chip(
                label: r.label,
                avatarUrl: r.kind == ReviewerKind.user ? r.avatarUrl : null,
                isTeam: r.kind == ReviewerKind.team,
                onRemove: () => notifier.removeReviewer(r.selectionKey),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _ComposeAssigneePicker(current: assignees),
        _SelectedChips(
          children: [
            for (final a in assignees)
              _Chip(
                label: a.login,
                avatarUrl: a.avatarUrl,
                onRemove: () => notifier.removeAssignee(a.login),
              ),
          ],
        ),
      ],
    );
  }
}

class _SelectedChips extends StatelessWidget {
  const _SelectedChips({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox(height: 4);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 6, runSpacing: 6, children: children),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onRemove,
    this.avatarUrl,
    this.isTeam = false,
  });

  final String label;
  final String? avatarUrl;
  final bool isTeam;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 6, 3),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTeam)
            Icon(LucideIcons.users, size: 14, color: t.fgQuaternary)
          else
            GitHubUserAvatar(
              login: label,
              avatarUrl: avatarUrl ?? '',
              size: 18,
              showHoverCard: false,
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(LucideIcons.x, size: 13, color: t.fgQuaternary),
          ),
        ],
      ),
    );
  }
}

bool _ciContains(Iterable<String> set, String x) =>
    set.any((e) => e.toLowerCase() == x.toLowerCase());

/// Assignee picker for the compose form. Toggling a row updates the staged
/// assignee list immediately (no GitHub call).
class _ComposeAssigneePicker extends ConsumerStatefulWidget {
  const _ComposeAssigneePicker({required this.current});

  final List<PrUser> current;

  @override
  ConsumerState<_ComposeAssigneePicker> createState() =>
      _ComposeAssigneePickerState();
}

class _ComposeAssigneePickerState
    extends ConsumerState<_ComposeAssigneePicker> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _overlay = OverlayPortalController();
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleOpen() {
    if (_overlay.isShowing) {
      _overlay.hide();
      setState(() {});
      return;
    }
    _query = '';
    _search.clear();
    _overlay.show();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocus.requestFocus();
      }
    });
    setState(() {});
  }

  void _toggleUser(PrUser u) {
    final selected = widget.current.toList();
    if (_ciContains(selected.map((e) => e.login), u.login)) {
      selected.removeWhere(
        (e) => e.login.toLowerCase() == u.login.toLowerCase(),
      );
    } else {
      selected.add(u);
    }
    ref.read(composePrProvider.notifier).setAssignees(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: _buildFlyout,
        child: CcTappable(
          onPressed: _toggleOpen,
          builder: (context, states) => PickerSectionHeader(
            icon: LucideIcons.userCheck,
            label: l10n.assignees,
            interactive: true,
          ),
        ),
      ),
    );
  }

  Widget _buildFlyout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(assignableUsersProvider);
    final all = async.value ?? const <PrUser>[];
    final q = _query.trim().toLowerCase();
    final items = [
      for (final u in all)
        if (q.isEmpty || u.login.toLowerCase().contains(q)) u,
    ]..sort((a, b) => a.login.toLowerCase().compareTo(b.login.toLowerCase()));
    final selectedLogins = widget.current.map((e) => e.login);

    final Widget list;
    if (async.isLoading && all.isEmpty) {
      list = const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (items.isEmpty) {
      list = Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            l10n.noMatchingUsers,
            style: TextStyle(fontSize: 13, color: t.textQuaternary),
          ),
        ),
      );
    } else {
      list = ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final u = items[i];
          return _UserRow(
            login: u.login,
            avatarUrl: u.avatarUrl,
            selected: _ciContains(selectedLogins, u.login),
            onTap: () => _toggleUser(u),
          );
        },
      );
    }
    return PickerFlyoutPanel(
      link: _link,
      title: l10n.addAssignees,
      searchController: _search,
      searchFocus: _searchFocus,
      hintText: l10n.searchUsers,
      onQueryChanged: (v) => setState(() => _query = v),
      onClose: () {
        _overlay.hide();
        setState(() {});
      },
      list: list,
    );
  }
}

/// Reviewer picker for the compose form (users + teams).
class _ComposeReviewerPicker extends ConsumerStatefulWidget {
  const _ComposeReviewerPicker({required this.current});

  final List<PrReviewerCandidate> current;

  @override
  ConsumerState<_ComposeReviewerPicker> createState() =>
      _ComposeReviewerPickerState();
}

class _ComposeReviewerPickerState
    extends ConsumerState<_ComposeReviewerPicker> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _overlay = OverlayPortalController();
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleOpen() {
    if (_overlay.isShowing) {
      _overlay.hide();
      setState(() {});
      return;
    }
    _query = '';
    _search.clear();
    _overlay.show();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocus.requestFocus();
      }
    });
    setState(() {});
  }

  void _toggle(PrReviewerCandidate c) {
    final selected = widget.current.toList();
    final idx = selected.indexWhere((e) => e.selectionKey == c.selectionKey);
    if (idx >= 0) {
      selected.removeAt(idx);
    } else {
      selected.add(c);
    }
    ref.read(composePrProvider.notifier).setReviewers(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: _buildFlyout,
        child: CcTappable(
          onPressed: _toggleOpen,
          builder: (context, states) => PickerSectionHeader(
            icon: LucideIcons.users,
            label: l10n.reviewers,
            interactive: true,
          ),
        ),
      ),
    );
  }

  Widget _buildFlyout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(requestableReviewersProvider);
    final all = async.value ?? const <PrReviewerCandidate>[];
    final q = _query.trim().toLowerCase();
    final items = [
      for (final c in all)
        if (q.isEmpty || c.label.toLowerCase().contains(q)) c,
    ];
    final selectedKeys = widget.current.map((e) => e.selectionKey).toSet();

    final Widget list;
    if (async.isLoading && all.isEmpty) {
      list = const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (items.isEmpty) {
      list = Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            l10n.noMatchingUsers,
            style: TextStyle(fontSize: 13, color: t.textQuaternary),
          ),
        ),
      );
    } else {
      list = ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final c = items[i];
          return _UserRow(
            login: c.label,
            avatarUrl: c.avatarUrl ?? '',
            isTeam: c.kind == ReviewerKind.team,
            selected: selectedKeys.contains(c.selectionKey),
            onTap: () => _toggle(c),
          );
        },
      );
    }
    return PickerFlyoutPanel(
      link: _link,
      title: l10n.addReviewers,
      searchController: _search,
      searchFocus: _searchFocus,
      hintText: l10n.searchUsers,
      onQueryChanged: (v) => setState(() => _query = v),
      onClose: () {
        _overlay.hide();
        setState(() {});
      },
      list: list,
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.login,
    required this.avatarUrl,
    required this.selected,
    required this.onTap,
    this.isTeam = false,
  });

  final String login;
  final String avatarUrl;
  final bool selected;
  final bool isTeam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          color: hovered ? t.bgPrimaryHover : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: [
              PickerCheck(selected: selected),
              const SizedBox(width: 8),
              if (isTeam)
                Icon(LucideIcons.users, size: 18, color: t.fgQuaternary)
              else
                GitHubUserAvatar(
                  login: login,
                  avatarUrl: avatarUrl,
                  size: 22,
                  showHoverCard: false,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  login,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
