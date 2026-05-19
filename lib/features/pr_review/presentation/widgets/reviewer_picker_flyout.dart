import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/widgets/picker_flyout.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_team_avatar.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/github_user_hover_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

PrReviewerCandidate _candidateFor(PrReviewer r) => switch (r) {
  PrUserReviewer() => PrReviewerCandidate(
    kind: ReviewerKind.user,
    key: r.user.login,
    label: r.user.displayLabel,
    avatarUrl: r.user.avatarUrl,
  ),
  PrTeamReviewer() => PrReviewerCandidate(
    kind: ReviewerKind.team,
    key: r.slug,
    label: r.name,
    avatarUrl: r.avatarUrl,
  ),
};

/// The clickable "Reviewers" section header. The whole row opens a flyout of
/// requestable users + teams, grouped into the already-selected (with their
/// review status), requestable teams, then GitHub's suggested reviewers. Typing
/// a query collapses the groups into one flat filtered list. Code-owner
/// reviewers are pre-checked and locked. Selection saves when the flyout closes.
class ReviewerPickerHeader extends ConsumerStatefulWidget {
  /// Creates a [ReviewerPickerHeader].
  const ReviewerPickerHeader({
    super.key,
    required this.prNumber,
    required this.current,
    required this.enabled,
    this.compact = false,
  });

  /// PR number.
  final int prNumber;

  /// Currently-resolved reviewers (seeds selection, locking and ordering).
  final List<PrReviewer> current;

  /// Whether editing is allowed (otherwise the header is a plain label).
  final bool enabled;

  /// When true, renders only a compact `+` add affordance (no eyebrow label)
  /// suitable for a collapsible sidebar section header trailing slot. Renders
  /// nothing when [enabled] is false.
  final bool compact;

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
  Map<String, PrReviewSubmissionState> _stateByIdentity = {};
  String _query = '';

  List<PrReviewerCandidate> _candidates = const [];
  List<PrUser> _suggested = const [];
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
    _stateByIdentity = {for (final r in widget.current) r.identity: r.state};
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
    final toaster = CcToastScope.of(context);
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
      toaster.show(
        l10n.failedToUpdateReviewers(error),
        variant: CcToastVariant.danger,
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

  void _toggle(PrReviewerCandidate c) {
    setState(() {
      if (_selected.contains(c.selectionKey)) {
        _selected.remove(c.selectionKey);
      } else {
        _selected.add(c.selectionKey);
      }
    });
  }

  /// Flat, query-filtered ordering used while searching: current user first,
  /// then already-selected, then everyone else alphabetically.
  List<PrReviewerCandidate> _orderedFlat() {
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

  /// Selected reviewers in a stable order (current order first, then any newly
  /// checked candidates).
  List<PrReviewerCandidate> _selectedOrdered() {
    final byKey = {for (final c in _candidates) c.selectionKey: c};
    final seen = <String>{};
    final out = <PrReviewerCandidate>[];
    for (final r in widget.current) {
      final c = byKey[r.identity];
      if (c != null && _selected.contains(r.identity) && seen.add(r.identity)) {
        out.add(c);
      }
    }
    for (final c in _candidates) {
      if (_selected.contains(c.selectionKey) && seen.add(c.selectionKey)) {
        out.add(c);
      }
    }
    return out;
  }

  /// Unselected team candidates, alphabetical.
  List<PrReviewerCandidate> _teams() {
    final teams = _candidates
        .where(
          (c) =>
              c.kind == ReviewerKind.team &&
              !_selected.contains(c.selectionKey),
        )
        .toList();
    teams.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return teams;
  }

  /// GitHub's suggested reviewers, minus anyone already selected or the viewer.
  List<PrReviewerCandidate> _suggestedCandidates() {
    final seen = <String>{};
    final out = <PrReviewerCandidate>[];
    for (final u in _suggested) {
      final key = 'user:${u.login.toLowerCase()}';
      if (_selected.contains(key)) {
        continue;
      }
      if (_me.isNotEmpty && u.login.toLowerCase() == _me) {
        continue;
      }
      if (!seen.add(key)) {
        continue;
      }
      out.add(PrReviewerCandidate.user(u));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_overlay.isShowing) {
      final async = ref.watch(requestableReviewersProvider);
      _candidates = _combined(async.value ?? const []);
      _loading = async.isLoading && _candidates.isEmpty;
      _me = ref.watch(currentUserLoginProvider);
      _suggested =
          ref.watch(suggestedReviewersProvider(widget.prNumber)).value ??
          const [];
    }
    if (widget.compact && !widget.enabled) {
      return const SizedBox.shrink();
    }
    final Widget child;
    if (widget.compact) {
      child = CompactPickerAddButton(
        semanticLabel: l10n.addReviewers,
        onPressed: _toggleOpen,
      );
    } else {
      final header = PickerSectionHeader(
        icon: AppIcons.users,
        label: l10n.reviewers,
        interactive: widget.enabled,
      );
      child = widget.enabled
          ? CcTappable(
              onPressed: _toggleOpen,
              builder: (context, states) => header,
            )
          : header;
    }
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: _buildFlyout,
        child: child,
      ),
    );
  }

  Widget _buildFlyout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final searching = _query.trim().isNotEmpty;

    final Widget list;
    if (_loading) {
      list = const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CcSpinner()),
      );
    } else {
      final rows = searching ? _searchRows() : _groupedRows(l10n, t);
      if (rows.isEmpty) {
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
        list = ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: rows,
        );
      }
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

  List<Widget> _searchRows() {
    return [for (final c in _orderedFlat()) _row(c)];
  }

  List<Widget> _groupedRows(AppLocalizations l10n, DesignSystemTokens t) {
    final rows = <Widget>[];
    for (final c in _selectedOrdered()) {
      rows.add(_row(c));
    }
    final teams = _teams();
    if (teams.isNotEmpty) {
      if (rows.isNotEmpty) {
        rows.add(_groupDivider(t));
      }
      rows.add(PickerGroupHeader(label: l10n.teamsSectionLabel));
      for (final c in teams) {
        rows.add(_row(c));
      }
    }
    final suggested = _suggestedCandidates();
    if (suggested.isNotEmpty) {
      if (rows.isNotEmpty && teams.isEmpty) {
        rows.add(_groupDivider(t));
      }
      rows.add(PickerGroupHeader(label: l10n.suggestedReviewers));
      for (final c in suggested) {
        rows.add(_row(c));
      }
    } else {
      // No GitHub suggestions for this PR — fall back to the full requestable
      // people list so the picker is never empty/unusable without a search.
      final people = _remainingUsers();
      if (people.isNotEmpty) {
        if (rows.isNotEmpty && teams.isEmpty) {
          rows.add(_groupDivider(t));
        }
        rows.add(PickerGroupHeader(label: l10n.usersSectionLabel));
        for (final c in people) {
          rows.add(_row(c));
        }
      }
    }
    return rows;
  }

  /// Unselected user candidates (current user first, then alphabetical). Used as
  /// the no-query fallback when GitHub returns no suggested reviewers.
  List<PrReviewerCandidate> _remainingUsers() {
    final users = _candidates
        .where(
          (c) =>
              c.kind == ReviewerKind.user &&
              !_selected.contains(c.selectionKey),
        )
        .toList();
    users.sort((a, b) {
      final am = _me.isNotEmpty && a.key.toLowerCase() == _me;
      final bm = _me.isNotEmpty && b.key.toLowerCase() == _me;
      if (am != bm) {
        return am ? -1 : 1;
      }
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return users;
  }

  Widget _groupDivider(DesignSystemTokens t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Container(height: 1, color: t.borderSecondary),
  );

  Widget _row(PrReviewerCandidate c) {
    final locked = _locked.contains(c.selectionKey);
    final selected = _selected.contains(c.selectionKey);
    return _ReviewerFlyoutRow(
      candidate: c,
      selected: selected,
      locked: locked,
      state: selected ? _stateByIdentity[c.selectionKey] : null,
      onTap: locked ? null : () => _toggle(c),
    );
  }
}

class _ReviewerFlyoutRow extends StatelessWidget {
  const _ReviewerFlyoutRow({
    required this.candidate,
    required this.selected,
    required this.locked,
    required this.state,
    required this.onTap,
  });

  final PrReviewerCandidate candidate;
  final bool selected;
  final bool locked;
  final PrReviewSubmissionState? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final isTeam = candidate.kind == ReviewerKind.team;
    final statusLabel = state == null ? null : _statusLabel(state!, l10n);

    final row = CcTappable(
      onPressed: onTap,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          color: hovered && !locked ? t.bgPrimaryHover : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: [
              PickerCheckBox(
                selected: selected,
                hovered: hovered,
                locked: locked,
              ),
              const SizedBox(width: 10),
              if (isTeam)
                GitHubTeamAvatar(
                  name: candidate.label,
                  avatarUrl: candidate.avatarUrl ?? '',
                  size: 22,
                )
              else
                GitHubUserAvatar(
                  login: candidate.key,
                  avatarUrl: candidate.avatarUrl,
                  size: 22,
                  showHoverCard: false,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  candidate.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ),
              if (statusLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(fontSize: 12, color: t.textTertiary),
                ),
              ],
              if (locked) ...[
                const SizedBox(width: 8),
                CcTooltip(
                  message: l10n.requiredByCodeOwners,
                  child: Icon(
                    AppIcons.shield,
                    size: 14,
                    color: t.fgBrandPrimary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );

    if (isTeam) {
      return row;
    }
    return GitHubUserHoverTarget(login: candidate.key, child: row);
  }

  String? _statusLabel(PrReviewSubmissionState s, AppLocalizations l10n) =>
      switch (s) {
        PrReviewSubmissionState.approved => l10n.approved,
        PrReviewSubmissionState.changesRequested => l10n.changesRequested,
        PrReviewSubmissionState.commented => l10n.commented,
        PrReviewSubmissionState.pending => null,
      };
}
