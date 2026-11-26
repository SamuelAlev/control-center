// The folder browser inside the add-repo dialog: the current path, the
// browse-root chips and the folder list with its selectable checkouts.

import 'package:cc_domain/core/domain/entities/directory_listing.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The current path with a button to navigate to the parent directory.
class RepoBrowserPathBar extends StatelessWidget {
  /// Creates a [RepoBrowserPathBar].
  const RepoBrowserPathBar({
    required this.listing,
    required this.onUp,
    required this.upLabel,
    super.key,
  });

  /// The folder being shown, or null while the first listing loads.
  final DirectoryListing? listing;

  /// Opens the parent folder; null disables the button.
  final VoidCallback? onUp;

  /// The up button's label.
  final String upLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Row(
      children: [
        CcButton(
          onPressed: onUp,
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          icon: CcIcons.cornerLeftUp,
          child: Text(upLabel),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            listing?.path ?? '…',
            style: CcFonts.code(
              textStyle: TextStyle(color: tokens?.textSecondary, fontSize: 13),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );
  }
}

/// Quick-jump chips for the configured browse roots (shown when there is more
/// than one).
class RepoBrowserRootChips extends StatelessWidget {
  /// Creates a [RepoBrowserRootChips].
  const RepoBrowserRootChips({
    required this.roots,
    required this.current,
    required this.onSelect,
    super.key,
  });

  /// The configured browse roots.
  final List<String> roots;

  /// The folder being shown; its chip is not tappable.
  final String current;

  /// Opens a root; null disables every chip.
  final void Function(String path)? onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final root in roots)
          CcButton(
            onPressed: root == current || onSelect == null
                ? null
                : () => onSelect!(root),
            variant: root == current
                ? CcButtonVariant.line
                : CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            icon: CcIcons.house,
            child: Text(_lastSegment(root)),
          ),
      ],
    );
  }

  static String _lastSegment(String path) {
    final trimmed = path.replaceAll(RegExp(r'[\\/]+$'), '');
    final parts = trimmed.split(RegExp(r'[\\/]'));
    final last = parts.isEmpty ? '' : parts.last;
    return last.isEmpty ? path : last;
  }
}

/// The scrollable list of subdirectories — folders navigate in, git checkouts
/// carry a selection checkbox.
class RepoFolderList extends StatelessWidget {
  /// Creates a [RepoFolderList].
  const RepoFolderList({
    required this.loading,
    required this.error,
    required this.listing,
    required this.selected,
    required this.enabled,
    required this.emptyLabel,
    required this.onOpen,
    required this.onToggle,
    super.key,
  });

  /// Whether a listing is loading.
  final bool loading;

  /// Why the last listing failed, or null.
  final String? error;

  /// The folder being shown, or null while the first listing loads.
  final DirectoryListing? listing;

  /// The selected checkout paths.
  final Set<String> selected;

  /// Whether the list accepts input.
  final bool enabled;

  /// Shown when the folder has no subfolders.
  final String emptyLabel;

  /// Opens a folder; null disables navigation.
  final void Function(String path)? onOpen;

  /// Toggles a checkout's selection; null disables selection.
  final void Function(String path)? onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: tokens?.panel,
        borderRadius: AppRadii.brLg,
        border: Border.all(
          color: tokens?.borderSecondary ?? const Color(0x1A000000),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildBody(context, tokens),
    );
  }

  Widget _buildBody(BuildContext context, DesignSystemTokens? tokens) {
    if (loading) {
      return const Center(child: CcSpinner());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens?.danger),
          ),
        ),
      );
    }
    final entries = listing?.entries ?? const <DirectoryEntry>[];
    if (entries.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: TextStyle(color: tokens?.textTertiary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _FolderRow(
          entry: entry,
          selected: selected.contains(entry.path),
          onOpen: onOpen == null ? null : () => onOpen!(entry.path),
          onToggle: entry.isGitRepo && onToggle != null
              ? () => onToggle!(entry.path)
              : null,
        );
      },
    );
  }
}

/// A single folder row: tap the body to navigate in; git checkouts carry a
/// selection checkbox with its own tap target (checking never navigates).
class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.entry,
    required this.selected,
    required this.onOpen,
    required this.onToggle,
  });

  final DirectoryEntry entry;
  final bool selected;
  final VoidCallback? onOpen;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return CcTappable(
      onPressed: onOpen,
      semanticLabel: entry.name,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: hovered ? tokens?.hover : null,
          child: Row(
            children: [
              Icon(
                entry.isGitRepo ? CcIcons.folderGit : CcIcons.folder,
                size: 16,
                color: entry.isGitRepo
                    ? (tokens?.accent ?? const Color(0xFFE2570F))
                    : (tokens?.muted ?? const Color(0xFF6B7280)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.name,
                  style: TextStyle(color: tokens?.textPrimary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onToggle != null)
                // The padded target is the control; the checkbox inside is
                // only its picture, so it is no Tab stop or node of its own.
                CcTappable(
                  onPressed: onToggle,
                  semanticLabel: AppLocalizations.of(context).selectThisFolder,
                  semanticChecked: selected,
                  builder: (context, _) => Padding(
                    padding: const EdgeInsets.all(6),
                    child: ExcludeFocus(
                      child: ExcludeSemantics(
                        child: IgnorePointer(
                          child: CcCheckbox(value: selected, onChanged: (_) {}),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Icon(
                  CcIcons.chevronRight,
                  size: 16,
                  color: tokens?.idle ?? const Color(0xFF9CA3AF),
                ),
            ],
          ),
        );
      },
    );
  }
}
