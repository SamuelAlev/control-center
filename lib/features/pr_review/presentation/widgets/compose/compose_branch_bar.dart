import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/providers/compose_pr_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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
                  child: FSelect<String>.search(
                    // Keyed on the repo set so an async-changing repo list
                    // rebuilds the searchable popover from scratch rather than
                    // rendering stale results against a new reverse-lookup map
                    // (see [_BranchSelect] for the underlying forui behaviour).
                    key: ValueKey(
                      'repo-select-${Object.hashAll(repos.map((r) => r.id))}',
                    ),
                    items: {for (final r in repos) r.fullName: r.id},
                    filter: (q) {
                      if (q.isEmpty) {
                        return repos.map((r) => r.id);
                      }
                      final lower = q.toLowerCase();
                      return repos
                          .where(
                            (r) => r.fullName.toLowerCase().contains(lower),
                          )
                          .map((r) => r.id);
                    },
                    hint: l10n.repository,
                    control: FSelectControl<String>.lifted(
                      value: repos.any((r) => r.id == activeRepo?.id)
                          ? activeRepo?.id
                          : null,
                      onChange: (id) {
                        if (id != null) {
                          ref.read(activeRepoIdProvider.notifier).setActive(id);
                        }
                      },
                    ),
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

/// A searchable single-select over branch names. Guards the lifted value so a
/// stale branch (e.g. one staged for a different repo) never reaches the
/// picker's reverse-lookup formatter — it simply renders as "unselected".
///
/// The [FSelect] is keyed on the candidate set so that swapping the branch list
/// (e.g. when the active repo changes and its branches reload) rebuilds the
/// select — and its searchable popover — from scratch. forui's search popover
/// caches the filtered result set and only re-filters on search-text changes,
/// not when `items` change underneath it; without a fresh key, an open popover
/// would render the stale results against the new reverse-lookup map and crash
/// with a null-check error on the missing keys.
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
    return FSelect<String>.search(
      key: ValueKey('branch-select-$slot-${Object.hashAll(branches)}'),
      items: {for (final b in branches) b: b},
      filter: (q) {
        if (q.isEmpty) {
          return branches;
        }
        final lower = q.toLowerCase();
        return branches.where((b) => b.toLowerCase().contains(lower));
      },
      hint: hint,
      enabled: branches.isNotEmpty,
      control: FSelectControl<String>.lifted(
        value: branches.contains(value) ? value : null,
        onChange: (b) {
          if (b != null) {
            onChanged(b);
          }
        },
      ),
    );
  }
}
