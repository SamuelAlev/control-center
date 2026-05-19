import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/compose_pr_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The compose-screen branch selector: the repo to open the PR in, plus the
/// `base ← compare` branch pair. Picking the repo sets the active repo (so all
/// repo-scoped providers re-resolve); picking branches stages them into
/// [composePrProvider].
///
/// Candidates come from the GitHub remote, **plus** [localBranch] — the branch
/// checked out in the launching conversation's isolated worktree. That branch is
/// created with a local `git checkout -b` and never pushed, so it is absent from
/// the remote's ref list; offering only remote refs is what made "create pull
/// request" from a chat a dead end. It is listed first, flagged as local and the
/// screen offers to publish it before the PR is opened.
///
/// Both pickers accept free text, so a branch the remote listing missed (or that
/// is still loading) can always be typed. Previously the field was hard-disabled
/// whenever the candidate list was empty, which collapsed "no branches", "still
/// loading", "GitHub timed out" and "no server token" into one inert grey box
/// with no explanation.
///
/// Layout: a labels row above a fields row that share identical column widths,
/// so everything stays on one line. The repo is a fixed-width picker while the
/// two branch pickers flex to fill the rest (selecting a long branch name never
/// shifts the layout) and the `←` is vertically centred against the picker row
/// — no fixed picker height assumed.
class ComposeBranchBar extends ConsumerWidget {
  /// Creates a [ComposeBranchBar].
  const ComposeBranchBar({super.key, this.localBranch});

  /// The launching conversation's worktree branch, when there is one. Offered as
  /// a compare candidate even though the remote has never seen it.
  final String? localBranch;

  static const double _repoWidth = 260;
  static const double _arrowWidth = 16;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final reposAsync = workspaceId == null
        ? const AsyncValue<List<Repo>>.data([])
        : ref.watch(reposForWorkspaceProvider(workspaceId));
    final repos = forgeLinkedReposOf(reposAsync)
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final activeRepo = ref.watch(activeRepoProvider);
    final branchesAsync = ref.watch(repoBranchesProvider);
    final remote = branchesAsync.value ?? const <String>[];
    // The worktree branch leads the compare list (it is what the user came here
    // to open a PR from) and is de-duplicated against the remote, which already
    // carries it once it has been published.
    final local = localBranch?.trim();
    final compareBranches = <String>[
      if (local != null && local.isNotEmpty && !remote.contains(local)) local,
      ...remote,
    ];
    final base = ref.watch(composePrProvider.select((s) => s.base));
    final head = ref.watch(composePrProvider.select((s) => s.head));
    final notifier = ref.read(composePrProvider.notifier);
    final hasRepoPicker = repos.length > 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Labels row — column widths mirror the fields row exactly.
          Row(
            children: [
              if (hasRepoPicker) ...[
                SizedBox(width: _repoWidth, child: _Label(l10n.repository)),
                const SizedBox(width: _gap),
              ],
              Expanded(child: _Label(l10n.baseBranchLabel)),
              const SizedBox(width: _gap),
              const SizedBox(width: _arrowWidth),
              const SizedBox(width: _gap),
              Expanded(child: _Label(l10n.compareBranchLabel)),
            ],
          ),
          const SizedBox(height: 6),
          // Fields row — the `←` centres against the pickers automatically.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasRepoPicker) ...[
                SizedBox(
                  width: _repoWidth,
                  child: _RepoSelect(
                    // Keyed on the repo set so an async-changing repo list
                    // rebuilds the typeahead field from scratch, re-seeding the
                    // controller with the active repo rather than rendering a
                    // stale selection against a new candidate set.
                    key: ValueKey(
                      'repo-select-${Object.hashAll(repos.map((r) => r.id))}',
                    ),
                    repos: repos,
                    activeRepoId: activeRepo?.id,
                    hint: l10n.repository,
                    onSelected: (id) =>
                        ref.read(activeRepoIdProvider.notifier).setActive(id),
                  ),
                ),
                const SizedBox(width: _gap),
              ],
              Expanded(
                child: _BranchSelect(
                  slot: 'base',
                  value: base,
                  branches: remote,
                  hint: l10n.selectBranch,
                  onChanged: notifier.setBase,
                ),
              ),
              const SizedBox(width: _gap),
              SizedBox(
                width: _arrowWidth,
                child: Center(
                  child: Icon(
                    AppIcons.arrowLeft,
                    size: 16,
                    color: t.fgQuaternary,
                  ),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _BranchSelect(
                  slot: 'head',
                  value: head,
                  branches: compareBranches,
                  localBranch: local,
                  hint: l10n.selectBranch,
                  onChanged: notifier.setHead,
                ),
              ),
            ],
          ),
          // Distinguish the failure modes the old empty list hid. A load error is
          // the user's problem to know about (a stale gh token, an offline host);
          // "still loading" is not an error at all.
          if (branchesAsync.isLoading && remote.isEmpty) ...[
            const SizedBox(height: 8),
            _Hint(l10n.composePrLoadingBranches, tone: t.textTertiary),
          ] else if (branchesAsync.hasError) ...[
            const SizedBox(height: 8),
            _Hint(l10n.composePrBranchesFailed, tone: t.textWarningPrimary),
          ],
        ],
      ),
    );
  }
}

/// A one-line status note under the pickers.
class _Hint extends StatelessWidget {
  const _Hint(this.text, {required this.tone});

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: 11.5, color: tone));
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: t.textTertiary,
      ),
    );
  }
}

/// A typeahead single-select over branch names, with free text allowed.
///
/// The controller is seeded with the current [value] whenever it is a real
/// selection — a member of [branches]. A value that is neither (a branch staged
/// for a previously-active repo) renders empty rather than showing an invalid
/// selection.
///
/// [localBranch] is annotated in the list as unpublished, so the one candidate
/// that does not yet exist on GitHub is visibly different from the ones that do.
/// The annotation lives in the option's label only: [_Typeahead] writes the bare
/// `value` into the field, so the staged branch name is never polluted with UI
/// text.
///
/// Never disabled. An empty candidate list means the remote listing is empty,
/// still loading, or failed — in all three the user must still be able to type a
/// branch name and [CcAutocomplete] refuses to even open its panel when
/// disabled, so the old `enabled: branches.isNotEmpty` produced a field that
/// silently did nothing on click.
///
/// The field is keyed on the candidate set so that swapping the branch list
/// (e.g. when the active repo changes and its branches reload) rebuilds the
/// field from scratch, re-seeding the controller against the new candidates.
class _BranchSelect extends StatelessWidget {
  const _BranchSelect({
    required this.slot,
    required this.value,
    required this.branches,
    required this.hint,
    required this.onChanged,
    this.localBranch,
  });

  /// Discriminates the base vs. head field so their keys never collide.
  final String slot;
  final String value;
  final List<String> branches;
  final String? localBranch;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Typeahead(
      key: ValueKey('branch-select-$slot-${Object.hashAll(branches)}'),
      options: [
        for (final b in branches)
          CcSelectOption<String>(
            value: b,
            label: b == localBranch ? '$b — ${l10n.branchNotPushed}' : b,
          ),
      ],
      initialText: branches.contains(value) ? value : '',
      hint: hint,
      // The field text is the bare branch name, never the annotated label, so
      // the staged value stays a valid ref. It also makes the built-in filter
      // match on the branch name rather than on the annotation.
      displayString: (option) => option.value,
      onSelected: onChanged,
      // Free text is staged as typed, so a branch the remote listing missed is
      // still reachable. Nothing is committed to GitHub here — an unknown ref
      // simply produces an empty comparison below.
      onTextChanged: onChanged,
    );
  }
}

/// A typeahead single-select over the workspace repos. The field's controller
/// is seeded with the active repo's full name (when it belongs to [repos]) and
/// selecting a row sets the active repo by id.
class _RepoSelect extends StatelessWidget {
  const _RepoSelect({
    super.key,
    required this.repos,
    required this.activeRepoId,
    required this.hint,
    required this.onSelected,
  });

  final List<Repo> repos;
  final String? activeRepoId;
  final String hint;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    var initialText = '';
    for (final r in repos) {
      if (r.id == activeRepoId) {
        initialText = r.fullName;
        break;
      }
    }
    return _Typeahead(
      options: [
        for (final r in repos)
          CcSelectOption<String>(value: r.id, label: r.fullName),
      ],
      initialText: initialText,
      hint: hint,
      onSelected: onSelected,
    );
  }
}

/// A [CcAutocomplete] whose controller is owned here and seeded once with
/// [initialText], so the field shows the current selection before the user
/// types. Recreated (re-seeded) when its key changes.
///
/// [onTextChanged], when set, reports every edit to the field — which turns the
/// picker into a free-text-plus-suggestions input. It is opt-in because the repo
/// picker's values are ids, not display text: reporting raw keystrokes there
/// would try to activate a repo id the user is halfway through typing.
class _Typeahead extends StatefulWidget {
  const _Typeahead({
    super.key,
    required this.options,
    required this.initialText,
    required this.hint,
    required this.onSelected,
    this.displayString,
    this.onTextChanged,
  });

  final List<CcSelectOption<String>> options;
  final String initialText;
  final String hint;
  final ValueChanged<String> onSelected;
  final String Function(CcSelectOption<String> option)? displayString;
  final ValueChanged<String>? onTextChanged;

  @override
  State<_Typeahead> createState() => _TypeaheadState();
}

class _TypeaheadState extends State<_Typeahead> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  /// Last value reported upward, so re-entrant controller notifications (and the
  /// one CcAutocomplete fires when it writes the chosen option into the field)
  /// don't re-stage an identical value.
  late String _reported = widget.initialText;

  @override
  void initState() {
    super.initState();
    if (widget.onTextChanged != null) {
      _controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _controller.dispose();
    super.dispose();
  }

  void _onText() {
    final text = _controller.text.trim();
    if (text == _reported) {
      return;
    }
    _reported = text;
    widget.onTextChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    return CcAutocomplete<String>(
      controller: _controller,
      options: widget.options,
      hintText: widget.hint,
      displayString: widget.displayString,
      onSelected: (value) {
        _reported = value;
        widget.onSelected(value);
      },
    );
  }
}
