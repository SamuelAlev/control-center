import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/space_stack_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Opens any published part of the repository's stack, in dependency order.
class ScmStackPullRequests extends StatefulWidget {
  /// Creates a stack picker using recorded or branch-discovered PR numbers.
  const ScmStackPullRequests({
    super.key,
    required this.layers,
    required this.prNumbers,
    required this.onOpen,
  });

  /// Stack layers for one repository, including unpublished parts.
  final List<SpaceStackLayer> layers;

  /// Known PR numbers, keyed by the stack layer's branch.
  final Map<String, int> prNumbers;

  /// Opens the selected part's PR in the current workspace.
  final ValueChanged<int> onOpen;

  @override
  State<ScmStackPullRequests> createState() => _ScmStackPullRequestsState();
}

class _ScmStackPullRequestsState extends State<ScmStackPullRequests> {
  final _menu = CcOverlayController();

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final published = [
      for (final layer in widget.layers)
        if (widget.prNumbers.containsKey(layer.branch)) layer,
    ]..sort((a, b) => a.position.compareTo(b.position));
    if (published.isEmpty) {
      return const SizedBox.shrink();
    }
    return CcMenu(
      controller: _menu,
      toggleOnTargetTap: false,
      maxWidth: 440,
      target: CcButton(
        onPressed: _menu.toggle,
        icon: AppIcons.layers,
        size: CcButtonSize.sm,
        variant: CcButtonVariant.line,
        fullWidth: true,
        child: Text('${l10n.stackedPullRequests} (${published.length})'),
      ),
      items: [
        for (final layer in published)
          CcMenuItem(
            label: '#${widget.prNumbers[layer.branch]} · ${layer.label}',
            icon: AppIcons.gitPullRequest,
            selected: layer.current,
            trailingChild: CcTooltip(
              message: l10n.partOfStack(
                layer.position + 1,
                widget.layers.length,
              ),
              child: Text('${layer.position + 1}/${widget.layers.length}'),
            ),
            onSelected: () => widget.onOpen(widget.prNumbers[layer.branch]!),
          ),
      ],
    );
  }
}
