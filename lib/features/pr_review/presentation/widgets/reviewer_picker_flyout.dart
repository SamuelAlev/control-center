import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/widgets/picker_flyout.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

PrReviewerCandidate _candidateFor(PrReviewer r) => switch (r) {
  PrUserReviewer() => PrReviewerCandidate(
    kind: ReviewerKind.user,
    key: r.user.login,
    label: r.user.login,
    avatarUrl: r.user.avatarUrl,
  ),
  PrTeamReviewer() => PrReviewerCandidate(
    kind: ReviewerKind.team,
    key: r.slug,
    label: r.name,
  ),
};

/// The clickable "Reviewers" section header. The whole row opens a flyout of
/// requestable users + teams (current user first, then the already-requested,
/// then the rest). Code-owner reviewers are pre-checked and locked. Selection
/// saves when the flyout closes.
class ReviewerPickerHeader extends ConsumerStatefulWidget {
  /// Creates a [ReviewerPickerHeader].
  const ReviewerPickerHeader({
    super.key,
    required this.prNumber,
    required this.current,
    required this.enabled,
  });

  /// PR number.
  final int prNumber;

  /// Currently-resolved reviewers (seeds selection, locking, and ordering).
  final List<PrReviewer> current;

  /// Whether editing is allowed (otherwise the header is a plain label).
  final bool enabled;

  @override
  ConsumerState<ReviewerPickerHeader> createState() =>
      _ReviewerPickerHeaderState();
}

class _ReviewerPickerHeaderState extends ConsumerState<ReviewerPickerHeader> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _overlay = OverlayPortalController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Set<String> _selected = {};
  Set<String> _originalKeys = {};
  Set<String> _locked = {};
  String _query = '';

  List<PrReviewerCandidate> _candidates = const [];
  bool _loading = false;
  String _me = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _open() {
    _originalKeys = {for (final r in widget.current) r.identity};
    _selected = {..._originalKeys};
    _locked = {
      for (final r in widget.current)
        if (r.isCodeOwner) r.identity,
    };
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
    final candByKey = {for (final c in _candidates) c.selectionKey: c};
    final addUsers = <String>[];
    final addTeams = <String>[];
    for (final key in _selected) {
      if (_originalKeys.contains(key)) {
        continue;
      }
      final c = candByKey[key];
      if (c == null) {
        continue;
      }
      (c.kind == ReviewerKind.user ? addUsers : addTeams).add(c.key);
    }
    final removeUsers = <String>[];
    final removeTeams = <String>[];
    for (final r in widget.current) {
      if (_selected.contains(r.identity)) {
        continue;
      }
      switch (r) {
        case PrUserReviewer():
          removeUsers.add(r.user.login);
        case PrTeamReviewer():
          removeTeams.add(r.slug);
      }
    }
    if (addUsers.isEmpty &&
        addTeams.isEmpty &&
        removeUsers.isEmpty &&
        removeTeams.isEmpty) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final error = await ref
        .read(prEditProvider(widget.prNumber).notifier)
        .applyReviewerChanges(
          addUsers: addUsers,
          addTeams: addTeams,
          removeUsers: removeUsers,
          removeTeams: removeTeams,
        );
    if (error != null && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.failedToUpdateReviewers(error))),
      );
    }
  }

  List<PrReviewerCandidate> _combined(List<PrReviewerCandidate> fromProvider) {
    final byKey = <String, PrReviewerCandidate>{
      for (final c in fromProvider) c.selectionKey: c,
    };
    for (final r in widget.current) {
      final c = _candidateFor(r);
      byKey.putIfAbsent(c.selectionKey, () => c);
    }
    return byKey.values.toList(growable: false);
  }

  List<PrReviewerCandidate> _ordered() {
    final q = _query.trim().toLowerCase();
    final cu = <PrReviewerCandidate>[];
    final sel = <PrReviewerCandidate>[];
    final rest = <PrReviewerCandidate>[];
    for (final c in _candidates) {
      if (q.isNotEmpty && !c.label.toLowerCase().contains(q)) {
        continue;
      }
      if (c.kind == ReviewerKind.user &&
          _me.isNotEmpty &&
          c.key.toLowerCase() == _me) {
        cu.add(c);
      } else if (_originalKeys.contains(c.selectionKey)) {
        sel.add(c);
      } else {
        rest.add(c);
      }
    }
    rest.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return [...cu, ...sel, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_overlay.isShowing) {
      final async = ref.watch(requestableReviewersProvider);
      _candidates = _combined(async.value ?? const []);
      _loading = async.isLoading && _candidates.isEmpty;
      _me = ref.watch(currentUserLoginProvider);
    }
    final header = PickerSectionHeader(
      icon: LucideIcons.users,
      label: l10n.reviewers,
      interactive: widget.enabled,
    );
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: _buildFlyout,
        child: widget.enabled
            ? FTappable(onPress: _toggleOpen, child: header)
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
            l10n.noMatchingReviewers,
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
          final locked = _locked.contains(c.selectionKey);
          return _ReviewerFlyoutRow(
            candidate: c,
            selected: _selected.contains(c.selectionKey),
            locked: locked,
            onTap: locked
                ? null
                : () => setState(() {
                    if (_selected.contains(c.selectionKey)) {
                      _selected.remove(c.selectionKey);
                    } else {
                      _selected.add(c.selectionKey);
                    }
                  }),
          );
        },
      );
    }
    return PickerFlyoutPanel(
      link: _link,
      title: l10n.addReviewers,
      searchController: _searchController,
      searchFocus: _searchFocus,
      hintText: l10n.searchReviewers,
      onQueryChanged: (v) => setState(() => _query = v),
      onClose: _close,
      list: list,
    );
  }
}

class _ReviewerFlyoutRow extends StatefulWidget {
  const _ReviewerFlyoutRow({
    required this.candidate,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final PrReviewerCandidate candidate;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  State<_ReviewerFlyoutRow> createState() => _ReviewerFlyoutRowState();
}

class _ReviewerFlyoutRowState extends State<_ReviewerFlyoutRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final isTeam = widget.candidate.kind == ReviewerKind.team;
    return FTappable(
      onPress: widget.onTap,
      onHoverChange: (h) => setState(() => _hovered = h),
      child: Container(
        color: _hovered && !widget.locked
            ? t.bgPrimaryHover
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            PickerCheck(selected: widget.selected, dimmed: widget.locked),
            const SizedBox(width: 8),
            if (isTeam)
              _TeamGlyph(tokens: t)
            else
              GitHubUserAvatar(
                login: widget.candidate.key,
                avatarUrl: widget.candidate.avatarUrl,
                size: 22,
                showHoverCard: false,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.candidate.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ),
            if (widget.locked) ...[
              const SizedBox(width: 8),
              FTooltip(
                tipBuilder: (_, _) => Text(l10n.requiredByCodeOwners),
                child: Icon(
                  LucideIcons.shield,
                  size: 14,
                  color: t.fgBrandPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamGlyph extends StatelessWidget {
  const _TeamGlyph({required this.tokens});

  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        shape: BoxShape.circle,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Icon(LucideIcons.users, size: 12, color: tokens.fgQuaternary),
    );
  }
}
