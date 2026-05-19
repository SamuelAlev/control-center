import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The checkout scope of the node that OPENS a conversation: which of the
/// workspace's repos the room checks out, and the branch each one's
/// copy-on-write worktree is cut from.
///
/// A conversation IS the checkout, so this only appears on the space node — an
/// agent node joins a room somebody else opened and a scope set there is read
/// by nothing.
///
/// **The wire format is one string per repo**, `<repoId>` or
/// `<repoId>@<branch>`, because the whole entry is `{{placeholder}}`-rendered
/// at run time and either half may come from the trigger. This widget owns the
/// split so the caller only ever sees `PipelineNodeConfig.repoIds`.
///
/// The branch is the BASE, not the working branch: the worktree still gets its
/// own branch cut from it, so nothing an agent commits lands on the branch it
/// was told to start from. Empty means the repo's own default branch, which is
/// what every space did before pinning existed.
class NodeRepoScopeField extends StatefulWidget {
  /// Creates a [NodeRepoScopeField].
  const NodeRepoScopeField({
    super.key,
    required this.configured,
    required this.workspaceRepos,
    required this.onChanged,
  });

  /// The node's configured `repoIds`. Empty means "every workspace repo", the
  /// same convention space creation uses.
  final List<String> configured;

  /// Repos in the active workspace, in display order.
  final List<Repo> workspaceRepos;

  /// Fired with the new `repoIds` whenever the selection or a branch changes.
  final void Function(List<String> repoIds) onChanged;

  @override
  State<NodeRepoScopeField> createState() => _NodeRepoScopeFieldState();
}

class _NodeRepoScopeFieldState extends State<NodeRepoScopeField> {
  late Set<String> _selected;

  /// Configured entries that are NOT workspace repo ids — `{{placeholder}}`s
  /// resolved per run. Preserved verbatim across edits, because reclassifying
  /// one as a picker selection would silently freeze a dynamic scope into a
  /// static one.
  late List<String> _dynamic;

  late Map<String, TextEditingController> _branches;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant NodeRepoScopeField old) {
    super.didUpdateWidget(old);
    // Repos resolve asynchronously: entries parked as "dynamic" because no repo
    // list had loaded yet move back into the picker once they name a real one.
    if (old.workspaceRepos.isEmpty && widget.workspaceRepos.isNotEmpty) {
      setState(_reclassify);
    }
  }

  @override
  void dispose() {
    for (final ctrl in _branches.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _init() {
    final knownIds = {for (final r in widget.workspaceRepos) r.id};
    _dynamic = [];
    _branches = {};
    final selected = <String>{};
    for (final entry in widget.configured) {
      final split = splitRepoScopeEntry(entry);
      if (!knownIds.contains(split.repoId)) {
        _dynamic.add(entry);
        continue;
      }
      selected.add(split.repoId);
      if (split.branch != null) {
        _branches[split.repoId] = TextEditingController(text: split.branch)
          ..addListener(_emit);
      }
    }
    _selected = widget.configured.isEmpty ? knownIds : selected;
  }

  void _reclassify() {
    final knownIds = {for (final r in widget.workspaceRepos) r.id};
    final stillDynamic = <String>[];
    for (final entry in _dynamic) {
      final split = splitRepoScopeEntry(entry);
      if (!knownIds.contains(split.repoId)) {
        stillDynamic.add(entry);
        continue;
      }
      _selected.add(split.repoId);
      if (split.branch != null) {
        _branches[split.repoId] = TextEditingController(text: split.branch)
          ..addListener(_emit);
      }
    }
    _dynamic = stillDynamic;
  }

  TextEditingController _branchCtrl(String repoId) => _branches.putIfAbsent(
    repoId,
    () => TextEditingController()..addListener(_emit),
  );

  void _emit() {
    final allRepoIds = {for (final r in widget.workspaceRepos) r.id};
    final selectsEverything =
        _selected.length == allRepoIds.length &&
        _selected.containsAll(allRepoIds);
    final pinned = _selected.any(
      (id) => (_branches[id]?.text.trim() ?? '').isNotEmpty,
    );
    // "Everything, unpinned, no placeholders" normalizes back to the empty
    // list — the provisioner's own default — so the config carries only real
    // subsets, pins and placeholders.
    if (_dynamic.isEmpty && selectsEverything && !pinned) {
      widget.onChanged(const []);
      return;
    }
    widget.onChanged([
      ..._dynamic,
      for (final r in widget.workspaceRepos)
        if (_selected.contains(r.id))
          switch (_branches[r.id]?.text.trim() ?? '') {
            '' => r.id,
            final branch => '${r.id}@$branch',
          },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcMultiSelect<String>(
          values: _selected,
          hintText: l10n.spaceReposHint,
          options: [
            for (final repo in widget.workspaceRepos)
              CcSelectOption(value: repo.id, label: repo.fullName),
          ],
          onChanged: (next) {
            setState(() => _selected = next);
            _emit();
          },
        ),
        // One branch field per PICKED repo — a field for a repo the room does
        // not check out would configure nothing.
        for (final repo in widget.workspaceRepos)
          if (_selected.contains(repo.id)) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    repo.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ds.textTertiary, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CcTextField(
                    controller: _branchCtrl(repo.id),
                    hintText: l10n.nodeConfigRepoBranchHint,
                  ),
                ),
              ],
            ),
          ],
        if (_selected.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            l10n.nodeConfigRepoBranchHelp,
            style: TextStyle(color: ds.textTertiary, fontSize: 11),
          ),
        ],
        if (_dynamic.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            l10n.nodeConfigReposDynamic(_dynamic.join(', ')),
            style: TextStyle(color: ds.textTertiary, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

/// Splits a repo-scope entry into its repo id and the branch the worktree is
/// cut from: `<repoId>@<branch>`, or just `<repoId>`.
///
/// Split from the RIGHT so a branch containing `@` still parses, and only when
/// both halves are non-empty — a bare `@branch` or a trailing `@` is a typo,
/// and reading it as "no repo" or "no branch" hides it. Mirrors the parse the
/// `messaging.createSpace` body does server-side.
({String repoId, String? branch}) splitRepoScopeEntry(String entry) {
  final at = entry.lastIndexOf('@');
  if (at <= 0 || at == entry.length - 1) {
    return (repoId: entry, branch: null);
  }
  return (repoId: entry.substring(0, at), branch: entry.substring(at + 1));
}
