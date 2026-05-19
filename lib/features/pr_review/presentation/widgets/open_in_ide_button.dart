import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/ide_editor.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/providers/ide_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A split button + dropdown for opening a pull request's branch in a code
/// editor / IDE.
///
/// On click the PR's head branch is lazily materialized into a fresh
/// copy-on-write worktree of [repo] (created only on demand, never pre-cloned,
/// and garbage-collected when the PR is merged/closed) and that worktree is
/// opened in the currently-selected editor. The chevron opens a menu listing
/// every editor on this platform — installed ones are selectable, the rest are
/// shown muted under a "not installed" section; picking one remembers it as the
/// default and opens immediately.
///
/// Renders nothing when no editor could be detected (only on unsupported
/// platforms).
class OpenInIdeButton extends ConsumerStatefulWidget {
  /// Creates an [OpenInIdeButton] for [pr] in [repo].
  const OpenInIdeButton({
    super.key,
    required this.pr,
    required this.repo,
    required this.workspaceId,
  });

  /// The pull request whose branch is opened.
  final PullRequest pr;

  /// The locally-registered repo the PR belongs to (the CoW source).
  final Repo repo;

  /// The active workspace that owns the ephemeral worktree.
  final String workspaceId;

  @override
  ConsumerState<OpenInIdeButton> createState() => _OpenInIdeButtonState();
}

class _OpenInIdeButtonState extends ConsumerState<OpenInIdeButton> {
  final OverlayPortalController _menuCtrl = OverlayPortalController();
  final GlobalKey _anchorKey = GlobalKey();
  Offset? _menuOffset;

  /// True while the PR branch is being checked out into its worktree (a fetch
  /// + checkout that can take a moment) — the main button shows a spinner.
  bool _preparing = false;

  static const double _menuWidth = 250;

  /// Fallback order used to pick a default editor when the user hasn't chosen
  /// one (or their choice isn't installed). The file manager is always last so
  /// a real editor wins whenever one exists.
  static const List<String> _priority = [
    'cursor',
    'vscode',
    'zed',
    'windsurf',
    'antigravity',
    'intellij',
    'webstorm',
    'pycharm',
    'sublime',
    'warp',
  ];

  @override
  void dispose() {
    if (_menuCtrl.isShowing) {
      _menuCtrl.hide();
    }
    super.dispose();
  }

  IdeEditor _effective(List<IdeEditor> installed, String? selectedId) {
    if (selectedId != null) {
      for (final e in installed) {
        if (e.id == selectedId) {
          return e;
        }
      }
    }
    for (final id in _priority) {
      for (final e in installed) {
        if (e.id == id) {
          return e;
        }
      }
    }
    return installed.first;
  }

  void _toggleMenu() {
    if (_menuCtrl.isShowing) {
      _menuCtrl.hide();
      return;
    }
    _computeMenuOffset();
    _menuCtrl.show();
    setState(() {});
  }

  void _closeMenu() {
    if (_menuCtrl.isShowing) {
      _menuCtrl.hide();
    }
  }

  void _computeMenuOffset() {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) {
      return;
    }
    final bottomRight = box.localToGlobal(
      Offset(box.size.width, box.size.height),
      ancestor: overlay,
    );
    final left = (bottomRight.dx - _menuWidth).clamp(
      0.0,
      (overlay.size.width - _menuWidth).clamp(0.0, double.infinity),
    );
    _menuOffset = Offset(left, bottomRight.dy + 6);
  }

  Future<void> _open(IdeEditor editor) async {
    if (_preparing) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    final worktrees = ref.read(prWorktreePortProvider);
    final launcher = ref.read(editorLauncherProvider);

    setState(() => _preparing = true);
    try {
      // Lazily check out the PR's branch into a CoW worktree (created on
      // demand, GC'd on merge/close), then open that directory.
      final path = await worktrees.ensureWorktree(
        workspaceId: widget.workspaceId,
        repo: widget.repo,
        prNumber: widget.pr.number,
        prHeadRef: widget.pr.headRef,
      );
      await launcher.openDirectory(editorId: editor.id, directoryPath: path);
    } on AppException catch (e) {
      toaster.show(
        l10n.failedToOpenInIde(editor.displayName, e.message),
        variant: CcToastVariant.danger,
      );
    } on Object catch (e) {
      toaster.show(
        l10n.failedToOpenInIde(editor.displayName, '$e'),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _preparing = false);
      }
    }
  }

  Future<void> _selectAndOpen(IdeEditor editor) async {
    _closeMenu();
    await ref.read(selectedIdeProvider.notifier).set(editor.id);
    if (!mounted) {
      return;
    }
    await _open(editor);
  }

  @override
  Widget build(BuildContext context) {
    final editors =
        ref.watch(installedEditorsProvider).value ?? const <IdeEditor>[];
    final installed = [
      for (final e in editors)
        if (e.installed) e,
    ];
    if (installed.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedId = ref.watch(selectedIdeProvider);
    final effective = _effective(installed, selectedId);
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final bundledLogos =
        ref.watch(ideLogoAssetsProvider).value ?? const <String>{};

    final splitButton = SizedBox(
      key: _anchorKey,
      // Matches the height of the primary `sm` buttons in this action row
      // (Review / Merge): 18px content padding + Manrope's ~20px line box at the
      // sm font size = 38px under this theme.
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bgPrimary,
          borderRadius: AppRadii.brSm,
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HoverSegment(
              onTap: () => unawaited(_open(effective)),
              tooltip: l10n.openInIde(effective.displayName),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(1),
                bottomLeft: Radius.circular(1),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: _preparing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tokens.fgSecondary,
                          ),
                        ),
                      )
                    : _buildLogo(
                        effective.id,
                        size: 18,
                        tintColor: tokens.fgSecondary,
                        bundledLogos: bundledLogos,
                      ),
              ),
            ),
            SizedBox(
              width: 1,
              child: ColoredBox(color: tokens.borderSecondary),
            ),
            _HoverSegment(
              onTap: _toggleMenu,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(1),
                bottomRight: Radius.circular(1),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: tokens.fgTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return OverlayPortal(
      controller: _menuCtrl,
      overlayChildBuilder: (_) =>
          _buildMenu(installed, editors, selectedId, bundledLogos),
      child: splitButton,
    );
  }

  Widget _buildMenu(
    List<IdeEditor> installed,
    List<IdeEditor> all,
    String? selectedId,
    Set<String> bundledLogos,
  ) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final notInstalled = [
      for (final e in all)
        if (!e.installed) e,
    ];
    final offset = _menuOffset ?? Offset.zero;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeMenu,
          ),
        ),
        Positioned(
          left: offset.dx,
          top: offset.dy,
          width: _menuWidth,
          child: RepaintBoundary(
            child: Material(
              color: tokens.bgPrimary,
              elevation: 0,
              borderRadius: BorderRadius.circular(4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.bgPrimary,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: tokens.borderSecondary),
                  boxShadow: AppShadows.golden,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 440),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(
                          l10n.openInEditorPrompt,
                          tokens,
                          theme,
                          muted: false,
                        ),
                        for (final e in installed)
                          _menuRow(
                            e,
                            enabled: true,
                            selected: e.id == selectedId,
                            tokens: tokens,
                            theme: theme,
                            bundledLogos: bundledLogos,
                          ),
                        if (notInstalled.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                            child: SizedBox(
                              height: 1,
                              child: ColoredBox(color: tokens.borderSecondary),
                            ),
                          ),
                          _header(
                            l10n.ideNotInstalled.toUpperCase(),
                            tokens,
                            theme,
                            muted: true,
                          ),
                          for (final e in notInstalled)
                            _menuRow(
                              e,
                              enabled: false,
                              selected: false,
                              tokens: tokens,
                              theme: theme,
                              bundledLogos: bundledLogos,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(
    String text,
    DesignSystemTokens tokens,
    ThemeData theme, {
    required bool muted,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: muted ? tokens.textQuaternary : tokens.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: muted ? 0.6 : 0.2,
        ),
      ),
    );
  }

  Widget _menuRow(
    IdeEditor e, {
    required bool enabled,
    required bool selected,
    required DesignSystemTokens tokens,
    required ThemeData theme,
    required Set<String> bundledLogos,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          Opacity(
            opacity: enabled ? 1 : 0.45,
            child: _buildLogo(
              e.id,
              size: 20,
              tintColor: enabled ? tokens.fgSecondary : tokens.fgDisabled,
              bundledLogos: bundledLogos,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              e.displayName,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: enabled ? tokens.textSecondary : tokens.textDisabled,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (selected) Icon(LucideIcons.check, size: 15, color: tokens.accent),
        ],
      ),
    );
    if (!enabled) {
      return row;
    }
    return _MenuItem(onTap: () => unawaited(_selectAndOpen(e)), child: row);
  }
}

/// One half of the split button: a tappable area that tints on hover.
class _HoverSegment extends StatefulWidget {
  const _HoverSegment({
    required this.onTap,
    required this.borderRadius,
    required this.child,
    this.tooltip,
  });

  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Widget child;
  final String? tooltip;

  @override
  State<_HoverSegment> createState() => _HoverSegmentState();
}

class _HoverSegmentState extends State<_HoverSegment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    Widget content = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _hovered ? tokens.bgSecondaryHover : Colors.transparent,
            borderRadius: widget.borderRadius,
          ),
          child: Center(widthFactor: 1, child: widget.child),
        ),
      ),
    );
    final tooltip = widget.tooltip;
    if (tooltip != null) {
      content = Tooltip(message: tooltip, child: content);
    }
    return content;
  }
}

/// A dropdown menu row that tints on hover.
class _MenuItem extends StatefulWidget {
  const _MenuItem({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: ColoredBox(
          color: _hovered ? tokens.bgSecondaryHover : Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Brand logos that are a single flat color and so must be tinted to the theme
/// foreground to read in both light and dark mode. Full-color logos (VS Code,
/// IntelliJ, …) are left untouched.
const Set<String> _monochromeLogos = {'cursor', 'zed', 'windsurf'};

IconData _fallbackIconFor(String id) {
  switch (id) {
    case 'warp':
      return LucideIcons.terminal;
    default:
      return LucideIcons.code;
  }
}

/// Renders the editor's brand logo from `assets/ide_logos/`, honoring whichever
/// format ships for it — a crisp, auto-scaling vector `.svg` (preferred) or a
/// raster `.png` fallback. [bundledLogos] is the set of bundled logo asset paths
/// (from [ideLogoAssetsProvider]); until it has loaded (empty set) we assume the
/// historical `.svg` path and let the renderer's own error fallback cover a
/// genuine miss. Monochrome logos are tinted to [tintColor] so they follow the
/// theme; full-color logos keep their own palette. Falls back to a Lucide glyph
/// (also in [tintColor]) when no asset is bundled or it fails to parse.
Widget _buildLogo(
  String id, {
  required double size,
  required Color tintColor,
  required Set<String> bundledLogos,
}) {
  final svgPath = 'assets/ide_logos/$id.svg';
  final pngPath = 'assets/ide_logos/$id.png';
  final monochrome = _monochromeLogos.contains(id);
  final fallback = Icon(_fallbackIconFor(id), size: size, color: tintColor);

  // Prefer the vector logo; use the raster PNG only when that is the format
  // actually bundled for this editor.
  final usePng =
      !bundledLogos.contains(svgPath) && bundledLogos.contains(pngPath);

  if (usePng) {
    return Image.asset(
      pngPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      color: monochrome ? tintColor : null,
      colorBlendMode: monochrome ? BlendMode.srcIn : null,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  return SvgPicture.asset(
    svgPath,
    width: size,
    height: size,
    fit: BoxFit.contain,
    colorFilter: monochrome
        ? ColorFilter.mode(tintColor, BlendMode.srcIn)
        : null,
    placeholderBuilder: (_) => SizedBox(width: size, height: size),
    errorBuilder: (context, error, stackTrace) => fallback,
  );
}
