import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/space_stack_provider.dart';
import 'package:control_center/features/messaging/providers/worktree_file_ops_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/source_control/scm_view.dart';
import 'package:flutter/widgets.dart';

/// The checked-out branch in a space's source-control header. Opens a picker
/// that can switch to another branch, create one, or detach HEAD.
class ScmBranchMenu extends StatefulWidget {
  /// Creates a [ScmBranchMenu].
  const ScmBranchMenu({
    super.key,
    required this.branch,
    required this.enabled,
    required this.load,
    required this.onCheckout,
    this.layers = const [],
    this.onStartNextPart,
    this.onCheckoutLayer,
    this.onPublishStack,
  });

  /// Branch stored for this worktree. Empty means a detached HEAD.
  final String branch;

  /// False while a commit, sync or checkout is already running.
  final bool enabled;

  /// Loads the worktree's refs. Null when the server has no such op.
  final Future<WorktreeBranchList?> Function() load;

  /// Runs the chosen checkout. The menu closes first.
  final Future<void> Function(WorktreeCheckoutRequest request) onCheckout;

  /// Recorded stack layers for this repo, bottom to top.
  final List<SpaceStackLayer> layers;

  /// Prompts for a part name and cuts the next layer.
  final Future<void> Function(String name)? onStartNextPart;

  /// Checks out a recorded layer.
  final Future<void> Function(SpaceStackLayer layer)? onCheckoutLayer;

  /// Publishes the stack once it has two layers.
  final Future<void> Function()? onPublishStack;

  @override
  State<ScmBranchMenu> createState() => _ScmBranchMenuState();
}

class _ScmBranchMenuState extends State<ScmBranchMenu> {
  final _menu = CcOverlayController();
  WorktreeBranchList? _list;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _menu.addListener(_onMenu);
  }

  @override
  void dispose() {
    _menu.removeListener(_onMenu);
    _menu.dispose();
    super.dispose();
  }

  void _onMenu() {
    if (_menu.isOpen) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final list = await widget.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _list = list;
      _loading = false;
    });
  }

  Future<void> _startNextPart() async {
    final start = widget.onStartNextPart;
    if (start == null) {
      return;
    }
    final name = await _askBranchName(
      context,
      title: AppLocalizations.of(context).stackPartNameTitle,
      hint: AppLocalizations.of(context).stackPartNameHint,
    );
    if (name == null || !mounted) {
      return;
    }
    await start(name);
  }

  Future<void> _create({String? startPoint}) async {
    final name = await _askBranchName(context, from: startPoint);
    if (name == null || !mounted) {
      return;
    }
    await widget.onCheckout((
      branch: name,
      startPoint: startPoint,
      create: true,
      detach: false,
    ));
  }

  Future<void> _createFrom() async {
    final l10n = AppLocalizations.of(context);
    final refs = _list?.refs ?? const <WorktreeRefEntry>[];
    final start = await _pickRef(context, l10n.scmPickStartPoint, refs);
    if (start == null || !mounted) {
      return;
    }
    await _create(startPoint: start.name);
  }

  Future<void> _detach() async {
    final l10n = AppLocalizations.of(context);
    final refs = _list?.refs ?? const <WorktreeRefEntry>[];
    final start = await _pickRef(context, l10n.scmCheckoutDetached, refs);
    if (start == null || !mounted) {
      return;
    }
    await widget.onCheckout((
      branch: null,
      startPoint: start.name,
      create: false,
      detach: true,
    ));
  }

  Future<void> _checkout(WorktreeRefEntry ref) async {
    if (ref.current) {
      return;
    }
    switch (ref.kind) {
      case 'tag':
        await widget.onCheckout((
          branch: null,
          startPoint: ref.name,
          create: false,
          detach: true,
        ));
      case 'remote':
        final local = ref.localName;
        final hasLocal =
            _list?.refs.any((r) => r.kind == 'branch' && r.name == local) ??
            false;
        if (hasLocal) {
          await widget.onCheckout((
            branch: local,
            startPoint: null,
            create: false,
            detach: false,
          ));
        } else {
          await widget.onCheckout((
            branch: local,
            startPoint: ref.name,
            create: true,
            detach: false,
          ));
        }
      default:
        await widget.onCheckout((
          branch: ref.name,
          startPoint: null,
          create: false,
          detach: false,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = widget.branch.isEmpty ? l10n.scmDetachedHead : widget.branch;
    final target = ScmHeaderChip(
      semanticLabel: l10n.scmSwitchBranch,
      enabled: widget.enabled,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The chip caps the row. The name yields so the chevron stays inside
          // that cap instead of painting past it.
          Flexible(
            child: Text(
              label,
              // RTL carve-out: a branch name is an LTR token.
              textDirection: TextDirection.ltr,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(AppIcons.chevronDown),
        ],
      ),
    );
    if (!widget.enabled) {
      return target;
    }
    final refs = _list?.refs ?? const <WorktreeRefEntry>[];
    final locals = [
      for (final r in refs)
        if (r.kind == 'branch') r,
    ];
    final remotes = [
      for (final r in refs)
        if (r.kind == 'remote') r,
    ];
    final tags = [
      for (final r in refs)
        if (r.kind == 'tag') r,
    ];
    final loaded = _list != null && !_loading;
    return CcMenu(
      controller: _menu,
      searchable: true,
      searchHint: l10n.scmSelectBranch,
      emptySearchLabel: l10n.scmNoBranches,
      semanticLabel: l10n.scmSwitchBranch,
      minWidth: 280,
      maxWidth: 440,
      target: target,
      items: [
        CcMenuItem(
          label: l10n.scmCreateBranch,
          icon: AppIcons.plus,
          onSelected: _create,
        ),
        if (widget.onStartNextPart != null)
          CcMenuItem(
            label: l10n.stackStartNextPart,
            icon: AppIcons.gitBranch,
            onSelected: () {
              unawaited(_startNextPart());
            },
          ),
        if (widget.onPublishStack != null && widget.layers.length >= 2)
          CcMenuItem(
            label: l10n.stackPublish,
            icon: AppIcons.gitPullRequestCreate,
            onSelected: () {
              final publish = widget.onPublishStack;
              if (publish != null) {
                unawaited(publish());
              }
            },
          ),
        CcMenuItem(
          label: l10n.scmCreateBranchFrom,
          icon: AppIcons.gitBranch,
          enabled: loaded && refs.isNotEmpty,
          onSelected: _createFrom,
        ),
        CcMenuItem(
          label: l10n.scmCheckoutDetached,
          icon: AppIcons.gitCommit,
          enabled: loaded && refs.isNotEmpty,
          onSelected: _detach,
        ),
        const CcMenuItem.divider(),
        if (_loading && _list == null)
          CcMenuItem(
            label: l10n.loadingEllipsis,
            enabled: false,
            onSelected: () {},
          )
        else ...[
          if (widget.layers.length >= 2) ...[
            CcMenuItem.section(l10n.stackSection),
            for (final layer in _stackInOrder(widget.layers))
              CcMenuItem(
                label: layer.prNumber == null
                    ? layer.label
                    : '${layer.label} #${layer.prNumber}',
                icon: AppIcons.gitBranch,
                selected: layer.current,
                trailingChild: _StackIndexBadge(
                  position: layer.position + 1,
                  total: widget.layers.length,
                ),
                searchText:
                    '${layer.branch} ${layer.position + 1}/${widget.layers.length}',
                onSelected: () {
                  final checkout = widget.onCheckoutLayer;
                  if (checkout != null) {
                    unawaited(checkout(layer));
                  }
                },
              ),
          ],
          if (locals.isNotEmpty) ...[
            CcMenuItem.section(l10n.scmBranches),
            for (final ref in locals) _refItem(context, ref),
          ],
          if (remotes.isNotEmpty) ...[
            CcMenuItem.section(l10n.scmRemoteBranches),
            for (final ref in remotes) _refItem(context, ref),
          ],
          if (tags.isNotEmpty) ...[
            CcMenuItem.section(l10n.scmTags),
            for (final ref in tags) _refItem(context, ref),
          ],
        ],
      ],
    );
  }

  CcMenuItem _refItem(BuildContext context, WorktreeRefEntry ref) {
    final when = ref.committedAt == null
        ? ''
        : formatRelativeTime(context, ref.committedAt);
    return CcMenuItem(
      label: ref.name,
      icon: switch (ref.kind) {
        'remote' => AppIcons.cloud,
        'tag' => AppIcons.tag,
        _ => AppIcons.gitBranch,
      },
      selected: ref.current,
      trailing: when.isEmpty ? null : when,
      searchText: '${ref.sha} ${ref.subject}',
      onSelected: () => _checkout(ref),
    );
  }
}

/// Bottom of the stack first, so the badge reads 1/N, then 2/N.
List<SpaceStackLayer> _stackInOrder(List<SpaceStackLayer> layers) {
  final ordered = [...layers]..sort((a, b) => a.position.compareTo(b.position));
  return ordered;
}

/// Layers glyph plus `position/total`, the same hairline pill the pull-request
/// stack badge uses.
class _StackIndexBadge extends StatelessWidget {
  const _StackIndexBadge({required this.position, required this.total});

  /// 1-based place in the stack. 1 is the bottom.
  final int position;

  /// How many layers the stack has.
  final int total;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcTooltip(
      message: l10n.partOfStack(position, total),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: tokens.panel,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: tokens.borderSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.layers, size: 12, color: tokens.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$position/$total',
              // RTL carve-out: a stack index is a number pair.
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: tokens.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _askBranchName(
  BuildContext context, {
  String? from,
  String? title,
  String? hint,
}) {
  return showCcDialog<String>(
    context: context,
    builder: (context) =>
        _BranchNameDialog(from: from, title: title, hint: hint),
  );
}

Future<WorktreeRefEntry?> _pickRef(
  BuildContext context,
  String title,
  List<WorktreeRefEntry> refs,
) {
  return showCcDialog<WorktreeRefEntry>(
    context: context,
    builder: (context) => _RefPickDialog(title: title, refs: refs),
  );
}

class _BranchNameDialog extends StatefulWidget {
  const _BranchNameDialog({this.from, this.title, this.hint});

  final String? from;
  final String? title;
  final String? hint;

  @override
  State<_BranchNameDialog> createState() => _BranchNameDialogState();
}

class _BranchNameDialogState extends State<_BranchNameDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return AnimatedBuilder(
      animation: _name,
      builder: (context, _) {
        final ready = _name.text.trim().isNotEmpty;
        return CcDialog(
          title: widget.title ?? l10n.scmCreateBranchTitle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.from != null && widget.from!.isNotEmpty) ...[
                Text(
                  l10n.scmFromRef(widget.from!),
                  // RTL carve-out: the ref is an LTR token inside the sentence,
                  // and the ARB isolates it.
                  style: TextStyle(fontSize: 12, color: t.textTertiary),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              CcTextField(
                controller: _name,
                autofocus: true,
                size: CcTextFieldSize.sm,
                hintText: widget.hint ?? l10n.scmBranchName,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CcButton(
                    variant: CcButtonVariant.line,
                    size: CcButtonSize.sm,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CcButton(
                    variant: CcButtonVariant.primary,
                    size: CcButtonSize.sm,
                    onPressed: ready ? _submit : null,
                    child: Text(l10n.create),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RefPickDialog extends StatelessWidget {
  const _RefPickDialog({required this.title, required this.refs});

  final String title;
  final List<WorktreeRefEntry> refs;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcDialog(
      title: title,
      content: SizedBox(
        height: 280,
        child: ListView(
          children: [
            for (final ref in refs)
              CcTappable(
                onPressed: () => Navigator.of(context).pop(ref),
                semanticLabel: ref.name,
                builder: (context, states) => Container(
                  color: states.contains(WidgetState.hovered)
                      ? t.hover
                      : const Color(0x00000000),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    ref.name,
                    // RTL carve-out: a ref name is an LTR token.
                    textDirection: TextDirection.ltr,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: t.textPrimary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
