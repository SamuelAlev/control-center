import 'dart:async';
import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/quick_open/quick_open_row.dart';
import 'package:control_center/features/messaging/providers/recent_files_provider.dart';
import 'package:control_center/features/messaging/providers/repo_file_search_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_fuzzy.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the quick open picker resolved to: the file, and whether it opens in a
/// new pane to the side instead of a tab in the active one.
typedef QuickOpenChoice = ({RecentFile file, bool toSide});

/// Shows the ⌘P / Ctrl+P "go to file" picker over the conversation's
/// worktrees and resolves to the operator's pick (null when dismissed).
///
/// The empty query lists the conversation's recently opened files; typing
/// ranks those that still match first and then the server's fuzzy file
/// search — the same `repos.searchFiles` op the Explorer filters with, against
/// the same isolated worktrees. Opening is the caller's job, so the editor
/// layout is never mutated while the dialog route is up.
Future<QuickOpenChoice?> showQuickOpen(
  BuildContext context, {
  required String workspaceId,
  required String spaceId,
}) {
  return showQuickOpenDialog(
    context,
    panel: (_) => QuickOpenPanel(workspaceId: workspaceId, spaceId: spaceId),
  );
}

/// Presents a quick open [panel] in the picker's floating frame (upper third,
/// like the ⌘K palette) and resolves to whatever the panel pops with.
///
/// Split from [showQuickOpen] for hosts whose worktree is not known up front
/// — the pull request page wraps [QuickOpenPanel] in its own provisioning
/// state but keeps the same frame.
Future<QuickOpenChoice?> showQuickOpenDialog(
  BuildContext context, {
  required WidgetBuilder panel,
}) {
  return showCcDialog<QuickOpenChoice>(
    context: context,
    builder: (dialogContext) {
      final ds = dialogContext.designSystem ?? DesignSystemTokens.light();
      final size = MediaQuery.sizeOf(dialogContext);
      final width = math.min(640.0, size.width - AppSpacing.xl * 2);
      // Upper third, like the ⌘K palette: expanding the route child keeps
      // hit-testing on the panel while taps outside reach the barrier.
      final topInset = (size.height * 0.08).clamp(48.0, 120.0);
      return SizedBox.expand(
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: Padding(
            padding: EdgeInsetsDirectional.only(top: topInset),
            child: SizedBox(
              width: width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ds.panel,
                  borderRadius: AppRadii.brLg,
                  border: Border.all(color: ds.borderPrimary),
                  boxShadow: CcElevation.floating,
                ),
                child: panel(dialogContext),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// One picker row: the file and whether it came from the recent list.
typedef _Entry = ({RecentFile file, bool recent});

class _NavigateIntent extends Intent {
  const _NavigateIntent(this.delta);

  final int delta;
}

class _OpenToSideIntent extends Intent {
  const _OpenToSideIntent();
}

/// The picker's body: query field plus the ranked rows. Pops the dialog route
/// with a [QuickOpenChoice]. Public for widget tests.
class QuickOpenPanel extends ConsumerStatefulWidget {
  /// Creates the picker body for one conversation.
  const QuickOpenPanel({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    this.ready = true,
    this.status,
  });

  /// The workspace the conversation belongs to.
  final String workspaceId;

  /// The conversation whose worktrees are searched, or null while the host is
  /// still resolving it (the picker then waits, as for [ready]).
  final String? spaceId;

  /// Whether the worktrees are checked out and searchable. While false the
  /// query field is disabled and nothing is listed; once it turns true the
  /// field is enabled and focused, so typing lands without a click.
  final bool ready;

  /// What the picker is waiting on, drawn above the query field — the strip
  /// the composer shows while its space prepares. Null shows nothing.
  final Widget? status;

  @override
  ConsumerState<QuickOpenPanel> createState() => _QuickOpenPanelState();
}

class _QuickOpenPanelState extends ConsumerState<QuickOpenPanel> {
  static const _debounceDelay = Duration(milliseconds: 120);
  static const double _maxListHeight = 440;
  static const double _listVPad = AppSpacing.xs;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scroll = ScrollController();
  Timer? _debounce;

  /// What is in the field right now — the recent list filters on it per
  /// keystroke, since it is already in memory.
  String _typed = '';

  /// The debounced query the server search runs for.
  String _query = '';
  int _selected = 0;

  /// The last search page shown, kept while the next query loads so the list
  /// does not blank between keystrokes.
  List<RepoFileHit> _lastHits = const [];

  /// The rows of the last build, for keyboard actions.
  List<_Entry> _entries = const [];

  /// The recent-files key, or null until the worktrees are searchable.
  RecentFilesArgs? get _recentArgs {
    final spaceId = widget.spaceId;
    if (!widget.ready || spaceId == null) {
      return null;
    }
    return (workspaceId: widget.workspaceId, spaceId: spaceId);
  }

  @override
  void didUpdateWidget(covariant QuickOpenPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasReady = oldWidget.ready && oldWidget.spaceId != null;
    if (!wasReady && _recentArgs != null) {
      // The field is enabled by this same build; focus it once it is.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final trimmed = value.trim();
    setState(() {
      _typed = trimmed;
      _selected = 0;
      if (trimmed.isEmpty) {
        _query = '';
        _lastHits = const [];
      }
    });
    _debounce?.cancel();
    if (trimmed.isEmpty) {
      return;
    }
    _debounce = Timer(_debounceDelay, () {
      if (mounted) {
        setState(() => _query = trimmed);
      }
    });
    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  void _move(int delta) {
    if (_entries.isEmpty) {
      return;
    }
    setState(() {
      _selected = (_selected + delta) % _entries.length;
      if (_selected < 0) {
        _selected += _entries.length;
      }
    });
    _scrollSelectedIntoView();
  }

  void _open(int index, {required bool toSide}) {
    if (index < 0 || index >= _entries.length) {
      return;
    }
    Navigator.of(
      context,
    ).pop<QuickOpenChoice>((file: _entries[index].file, toSide: toSide));
  }

  void _remove(RecentFile file) {
    final args = _recentArgs;
    if (args == null) {
      return;
    }
    ref
        .read(recentFilesProvider(args).notifier)
        .remove(repoId: file.repoId, path: file.path);
    // The × may have taken focus; typing must keep landing in the query.
    _focusNode.requestFocus();
  }

  void _scrollSelectedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) {
        return;
      }
      final position = _scroll.position;
      final top = _listVPad + _selected * QuickOpenRow.height;
      final bottom = top + QuickOpenRow.height;
      double? target;
      if (top < position.pixels) {
        target = top - _listVPad;
      } else if (bottom > position.pixels + position.viewportDimension) {
        target = bottom + _listVPad - position.viewportDimension;
      }
      if (target != null) {
        _scroll.jumpTo(
          target.clamp(position.minScrollExtent, position.maxScrollExtent),
        );
      }
    });
  }

  /// Recent files first (filtered and ranked by the typed query), then the
  /// search hits that are not already listed as recent.
  List<_Entry> _buildEntries(List<RecentFile> recents, List<RepoFileHit> hits) {
    final rankedRecents = rankCommands<RecentFile>(
      _typed,
      recents,
      textOf: (f) => f.path,
      recencyOf: (f) => recents.indexOf(f).toDouble(),
    );
    bool isRecent(String repoId, String path) => rankedRecents.any(
      (f) =>
          f.path == path &&
          (f.repoId == repoId || f.repoId.isEmpty || repoId.isEmpty),
    );
    return [
      for (final f in rankedRecents) (file: f, recent: true),
      if (_typed.isNotEmpty)
        for (final h in hits)
          if (!h.hit.isDirectory && !isRecent(h.repoId, h.hit.relativePath))
            (file: (repoId: h.repoId, path: h.hit.relativePath), recent: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recentArgs = _recentArgs;
    final recents = recentArgs == null
        ? const <RecentFile>[]
        : ref.watch(recentFilesProvider(recentArgs));

    var loading = false;
    var failed = false;
    if (recentArgs != null && _typed.isNotEmpty && _query.isNotEmpty) {
      final async = ref.watch(
        repoFileSearchProvider((
          workspaceId: widget.workspaceId,
          query: _query,
          spaceId: recentArgs.spaceId,
        )),
      );
      final fresh = async.value;
      if (fresh != null) {
        _lastHits = fresh.hits;
      }
      loading = async.isLoading;
      failed = async.hasError && fresh == null;
    }
    _entries = _buildEntries(recents, _lastHits);
    if (_selected >= _entries.length) {
      _selected = math.max(0, _entries.length - 1);
    }

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowDown): _NavigateIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowUp): _NavigateIntent(-1),
        // ⌘↵ / Ctrl+↵ opens to the side, as in VS Code's picker.
        SingleActivator(LogicalKeyboardKey.enter, meta: true):
            _OpenToSideIntent(),
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            _OpenToSideIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NavigateIntent: CallbackAction<_NavigateIntent>(
            onInvoke: (intent) {
              _move(intent.delta);
              return null;
            },
          ),
          _OpenToSideIntent: CallbackAction<_OpenToSideIntent>(
            onInvoke: (_) {
              _open(_selected, toSide: true);
              return null;
            },
          ),
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.status case final status?) ...[
              status,
              const CcDivider(),
            ],
            _QueryField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: recentArgs != null,
              loading: loading,
              onChanged: _onChanged,
              // Enter flows through the field's submit, not a shortcut.
              onSubmitted: () => _open(_selected, toSide: false),
            ),
            // Nothing to list until the worktrees exist: the status above
            // says what is being waited on.
            if (recentArgs != null) ...[
              const CcDivider(),
              if (_entries.isEmpty)
                _EmptyMessage(
                  loading: loading,
                  message: _typed.isEmpty
                      ? l10n.ideQuickOpenNoRecent
                      : failed
                      ? l10n.ideFileSearchFailed
                      : l10n.noMatchingFiles,
                )
              else
                _results(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _results() {
    final extent = _entries.length * QuickOpenRow.height + _listVPad * 2;
    final fits = extent <= _maxListHeight;
    return SizedBox(
      height: fits ? extent : _maxListHeight,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(vertical: _listVPad),
        physics: fits ? const NeverScrollableScrollPhysics() : null,
        itemExtent: QuickOpenRow.height,
        itemCount: _entries.length,
        itemBuilder: (context, i) {
          final entry = _entries[i];
          return QuickOpenRow(
            repoId: entry.file.repoId,
            path: entry.file.path,
            recent: entry.recent,
            selected: i == _selected,
            query: _typed,
            onOpen: () => _open(i, toSide: false),
            onOpenToSide: () => _open(i, toSide: true),
            onRemove: entry.recent ? () => _remove(entry.file) : null,
            onHover: () {
              if (_selected != i) {
                setState(() => _selected = i);
              }
            },
          );
        },
      ),
    );
  }
}

class _QueryField extends StatelessWidget {
  const _QueryField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.loading,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool loading;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xxs,
      ),
      child: Row(
        children: [
          Icon(AppIcons.search, size: 16, color: ds.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            // Typing starts the moment the picker appears: the field owns
            // focus from its first frame.
            child: CcTextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              enabled: enabled,
              chromeless: true,
              textStyle: CcTypography.body,
              hintText: AppLocalizations.of(context).ideQuickOpenHint,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
          if (loading) const CcSpinner(size: 14, strokeWidth: 2),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.loading, required this.message});

  final bool loading;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: loading
            ? const CcSpinner(size: 16, strokeWidth: 2)
            : Text(
                message,
                style: CcTypography.bodySm.copyWith(color: ds.textTertiary),
              ),
      ),
    );
  }
}
