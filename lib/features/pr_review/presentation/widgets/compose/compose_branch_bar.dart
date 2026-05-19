import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/features/pr_review/providers/compose_pr_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The compose-screen branch selector: the repo to open the PR in, plus the
/// `base ← compare` branch pair. Both branches come from the GitHub API, so
/// only branches that exist on the remote can be picked. Picking the repo sets
/// the active repo (so all repo-scoped providers re-resolve); picking branches
/// stages them into [composePrProvider].
///
/// Layout: a labels row above a fields row that share identical column widths,
/// so everything stays on one line. The repo is a fixed-width picker while the
/// two branch pickers flex to fill the rest (selecting a long branch name never
/// shifts the layout), and the `←` is vertically centred against the picker row
/// — no fixed picker height assumed.
class ComposeBranchBar extends ConsumerWidget {
  /// Creates a [ComposeBranchBar].
  const ComposeBranchBar({super.key});

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
    final repos = githubLinkedReposOf(reposAsync)
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final activeRepo = ref.watch(activeRepoProvider);
    final branchesAsync = ref.watch(repoBranchesProvider);
    final branches = branchesAsync.value ?? const <String>[];
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
                  branches: branches,
                  hint: l10n.selectBranch,
                  onChanged: notifier.setBase,
                ),
              ),
              const SizedBox(width: _gap),
              SizedBox(
                width: _arrowWidth,
                child: Center(
                  child: Icon(
                    LucideIcons.arrowLeft,
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
                  branches: branches,
                  hint: l10n.selectBranch,
                  onChanged: notifier.setHead,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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

/// A typeahead single-select over branch names. The field's controller is
/// seeded with the current [value] (only when it is a member of [branches], so
/// a stale branch staged for a different repo renders as empty rather than
/// surfacing an invalid selection).
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
  });

  /// Discriminates the base vs. head field so their keys never collide.
  final String slot;
  final String value;
  final List<String> branches;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Typeahead(
      key: ValueKey('branch-select-$slot-${Object.hashAll(branches)}'),
      options: [
        for (final b in branches) CcSelectOption<String>(value: b, label: b),
      ],
      initialText: branches.contains(value) ? value : '',
      hint: hint,
      enabled: branches.isNotEmpty,
      onSelected: onChanged,
    );
  }
}

/// A typeahead single-select over the workspace repos. The field's controller
/// is seeded with the active repo's full name (when it belongs to [repos]), and
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
class _Typeahead extends StatefulWidget {
  const _Typeahead({
    super.key,
    required this.options,
    required this.initialText,
    required this.hint,
    required this.onSelected,
    this.enabled = true,
  });

  final List<CcSelectOption<String>> options;
  final String initialText;
  final String hint;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  State<_Typeahead> createState() => _TypeaheadState();
}

class _TypeaheadState extends State<_Typeahead> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcAutocomplete<String>(
      controller: _controller,
      options: widget.options,
      hintText: widget.hint,
      enabled: widget.enabled,
      onSelected: widget.onSelected,
    );
  }
}
