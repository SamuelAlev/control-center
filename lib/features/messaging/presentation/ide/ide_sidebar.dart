import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/explorer_panel.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/prs_panel.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/source_control_panel.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The IDE-style sidebar for the messaging screen.
///
/// A three-tab strip — Explorer, Source Control, Pull Requests — over the
/// matching panel, with a left hairline edge so it reads as a panel boundary
/// against the editor area. The active tab is mirrored in [tabNotifier] so the
/// parent layout (e.g. a "focus source control" action from the chat header)
/// can drive the selection from the outside.
class IdeSidebar extends ConsumerStatefulWidget {
  /// Creates an [IdeSidebar].
  const IdeSidebar({
    super.key,
    required this.tabNotifier,
    required this.workspaceId,
    required this.onOpenFile,
    required this.onOpenFileDiff,
  });

  /// Drives the active sidebar tab from the parent layout.
  ///
  /// 0 = Explorer, 1 = Source Control, 2 = Pull Requests. Two-way: tapping a
  /// tab writes back here, and an external write updates the strip.
  final ValueNotifier<int> tabNotifier;

  /// The workspace whose linked repos the panels are scoped to.
  final String workspaceId;

  /// Called when an Explorer file is opened (opens a FileViewer editor tab).
  final ValueChanged<({String repoId, String path})> onOpenFile;

  /// Called when a Source Control changed file is opened (opens a diff tab).
  final ValueChanged<({String repoId, PrFile file})> onOpenFileDiff;

  @override
  ConsumerState<IdeSidebar> createState() => _IdeSidebarState();
}

class _IdeSidebarState extends ConsumerState<IdeSidebar> {
  late int _tab = _clampTab(widget.tabNotifier.value);
  late final void Function() _tabListener;

  static int _clampTab(int value) =>
      value < 0 ? 0 : (value > 2 ? 2 : value);

  @override
  void initState() {
    super.initState();
    _tabListener = () {
      if (!mounted) {
        return;
      }
      final next = _clampTab(widget.tabNotifier.value);
      if (next != _tab) {
        setState(() => _tab = next);
      }
    };
    widget.tabNotifier.addListener(_tabListener);
  }

  @override
  void dispose() {
    widget.tabNotifier.removeListener(_tabListener);
    super.dispose();
  }

  void _select(int index) {
    final clamped = _clampTab(index);
    if (clamped != _tab) {
      setState(() => _tab = clamped);
      widget.tabNotifier.value = clamped;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    return Container(
      decoration: BoxDecoration(
        color: t.bgSecondary,
        border: Border(left: BorderSide(color: t.borderPrimary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcTabs(
            tabs: [
              CcTab(l10n.ideTabExplorer, icon: AppIcons.folderTree),
              CcTab(l10n.ideTabSourceControl, icon: AppIcons.gitBranch),
              CcTab(l10n.ideTabPullRequests, icon: AppIcons.gitPullRequest),
            ],
            selectedIndex: _tab,
            onChanged: _select,
          ),
          Expanded(
            child: switch (_tab) {
              0 => ExplorerPanel(
                  workspaceId: widget.workspaceId,
                  onOpenFile: widget.onOpenFile,
                ),
              1 => SourceControlPanel(
                  workspaceId: widget.workspaceId,
                  onOpenFileDiff: widget.onOpenFileDiff,
                ),
              _ => const PrsPanel(),
            },
          ),
        ],
      ),
    );
  }
}
