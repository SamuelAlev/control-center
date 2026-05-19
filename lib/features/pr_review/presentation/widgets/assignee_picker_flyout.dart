import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/widgets/picker_flyout.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

bool _ci(Iterable<String> set, String x) =>
    set.any((e) => e.toLowerCase() == x.toLowerCase());

/// The clickable "Assignees" section header. The whole row opens a flyout of
/// assignable users (current user first, then the already-assigned, then the
/// rest); selection saves when the flyout closes.
class AssigneePickerHeader extends ConsumerStatefulWidget {
  /// Creates an [AssigneePickerHeader].
  const AssigneePickerHeader({
    super.key,
    required this.prNumber,
    required this.current,
    required this.enabled,
  });

  /// PR number.
  final int prNumber;

  /// Currently-assigned users (seeds the selection + the top ordering).
  final List<PrUser> current;

  /// Whether editing is allowed (otherwise the header is a plain label).
  final bool enabled;

  @override
  ConsumerState<AssigneePickerHeader> createState() =>
      _AssigneePickerHeaderState();
}

class _AssigneePickerHeaderState extends ConsumerState<AssigneePickerHeader> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _overlay = OverlayPortalController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Set<String> _selected = {};
  Set<String> _originalLower = {};
  String _query = '';

  // Snapshot read during build() (when open) so the overlay builder doesn't
  // call ref.watch outside the State's build.
  List<PrUser> _allUsers = const [];
  bool _loading = false;
  String _me = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _open() {
    _selected = {for (final u in widget.current) u.login};
    _originalLower = {for (final u in widget.current) u.login.toLowerCase()};
    _query = '';
    _searchController.clear();
    _overlay.show();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocus.requestFocus();
      }
    });
    setState(() {});
  }

  void _toggleOpen() {
    if (_overlay.isShowing) {
      _close();
    } else {
      _open();
    }
  }

  Future<void> _close() async {
    if (!_overlay.isShowing) {
      return;
    }
    _overlay.hide();
    await _apply();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _apply() async {
    final current = {for (final u in widget.current) u.login};
    final add = _selected
        .where((l) => !_ci(current, l))
        .toList(growable: false);
    final remove = current
        .where((l) => !_ci(_selected, l))
        .toList(growable: false);
    if (add.isEmpty && remove.isEmpty) {
      return;
    }
    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);
    final error = await ref
        .read(prEditProvider(widget.prNumber).notifier)
        .applyAssigneeChanges(add: add, remove: remove);
    if (error != null && mounted) {
      toaster.show(
        l10n.failedToUpdateAssignees(error),
        variant: CcToastVariant.danger,
      );
    }
  }

  List<PrUser> _ordered() {
    final q = _query.trim().toLowerCase();
    final cu = <PrUser>[];
    final sel = <PrUser>[];
    final rest = <PrUser>[];
    for (final u in _allUsers) {
      if (q.isNotEmpty && !u.login.toLowerCase().contains(q)) {
        continue;
      }
      final l = u.login.toLowerCase();
      if (l == _me && _me.isNotEmpty) {
        cu.add(u);
      } else if (_originalLower.contains(l)) {
        sel.add(u);
      } else {
        rest.add(u);
      }
    }
    rest.sort((a, b) => a.login.toLowerCase().compareTo(b.login.toLowerCase()));
    return [...cu, ...sel, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_overlay.isShowing) {
      final async = ref.watch(assignableUsersProvider);
      _allUsers = async.value ?? const [];
      _loading = async.isLoading && _allUsers.isEmpty;
      _me = ref.watch(currentUserLoginProvider);
    }
    final header = PickerSectionHeader(
      icon: LucideIcons.userCheck,
      label: l10n.assignees,
      interactive: widget.enabled,
    );
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: _buildFlyout,
        child: widget.enabled
            ? CcTappable(
                onPressed: _toggleOpen,
                builder: (context, states) => header,
              )
            : header,
      ),
    );
  }

  Widget _buildFlyout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final items = _ordered();
    final Widget list;
    if (_loading) {
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
          return _AssigneeFlyoutRow(
            user: u,
            selected: _ci(_selected, u.login),
            onTap: () => setState(() {
              if (_ci(_selected, u.login)) {
                _selected.removeWhere(
                  (l) => l.toLowerCase() == u.login.toLowerCase(),
                );
              } else {
                _selected.add(u.login);
              }
            }),
          );
        },
      );
    }
    return PickerFlyoutPanel(
      link: _link,
      title: l10n.addAssignees,
      searchController: _searchController,
      searchFocus: _searchFocus,
      hintText: l10n.searchUsers,
      onQueryChanged: (v) => setState(() => _query = v),
      onClose: _close,
      list: list,
    );
  }
}

class _AssigneeFlyoutRow extends StatelessWidget {
  const _AssigneeFlyoutRow({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  final PrUser user;
  final bool selected;
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
              GitHubUserAvatar(
                login: user.login,
                avatarUrl: user.avatarUrl,
                size: 22,
                showHoverCard: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user.login,
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
