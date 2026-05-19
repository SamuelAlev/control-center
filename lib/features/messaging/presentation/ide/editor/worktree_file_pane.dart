import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/providers/worktree_file_ops_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single repo file from a conversation's isolated worktree — view **and
/// edit**. Reads via `worktree.readFile`, saves the buffer with ⌘S/Ctrl-S via
/// `worktree.writeFile`. Used by the messaging IDE and the PR workbench (whose
/// worktree is the PR head), so quick fixes never leave the app.
///
/// This is the lightweight quick-fix editor; the code-server tab remains the
/// full-fidelity IDE surface.
class WorktreeFilePane extends ConsumerStatefulWidget {
  /// Creates a [WorktreeFilePane].
  const WorktreeFilePane({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    required this.repoId,
    required this.path,
  });

  /// Workspace owning the space/worktree (isolation enforced server-side).
  final String workspaceId;

  /// The space whose worktree holds the file.
  final String spaceId;

  /// The repo the file belongs to.
  final String repoId;

  /// Repo-relative path of the file.
  final String path;

  @override
  ConsumerState<WorktreeFilePane> createState() => _WorktreeFilePaneState();
}

class _WorktreeFilePaneState extends ConsumerState<WorktreeFilePane> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = true;
  bool _binary = false;
  bool _dirty = false;
  bool _saving = false;
  String? _error;
  String _loaded = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    final dirty = _controller.text != _loaded;
    if (dirty != _dirty) {
      setState(() => _dirty = dirty);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await readWorktreeFile(
      ref.read(rpcClientProvider),
      workspaceId: widget.workspaceId,
      spaceId: widget.spaceId,
      repoId: widget.repoId,
      path: widget.path,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      if (res == null) {
        _error = 'File is not available in this worktree.';
        return;
      }
      _binary = res.binary;
      _loaded = res.content;
      _controller.text = res.content;
      _dirty = false;
    });
  }

  Future<void> _save() async {
    if (_saving || !_dirty) {
      return;
    }
    setState(() => _saving = true);
    final res = await writeWorktreeFile(
      ref.read(rpcClientProvider),
      workspaceId: widget.workspaceId,
      spaceId: widget.spaceId,
      repoId: widget.repoId,
      path: widget.path,
      content: _controller.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      if (res != null) {
        _loaded = _controller.text;
        _dirty = false;
      }
    });
    final l10n = AppLocalizations.of(context);
    CcToastScope.maybeOf(context)?.show(
      res != null ? l10n.saved : l10n.saveFailed,
      variant: res != null ? CcToastVariant.success : CcToastVariant.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      children: [
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: t.bgSecondary,
            border: Border(bottom: BorderSide(color: t.lineStrong)),
          ),
          child: Row(
            children: [
              Icon(AppIcons.fileCode, size: 14, color: t.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.path}${_dirty ? ' •' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: t.fg,
                    fontFamily: CcFonts.codeFamily,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (!_binary)
                CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  onPressed: _dirty && !_saving ? _save : null,
                  child: Text(_saving ? l10n.saving : l10n.save),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CcSpinner())
              : _error != null
              ? Center(
                  child: Text(_error!, style: TextStyle(color: t.textTertiary)),
                )
              : _binary
              ? Center(
                  child: Text(
                    l10n.ideFileBinary,
                    style: TextStyle(color: t.textTertiary),
                  ),
                )
              : _Editor(
                  controller: _controller,
                  focusNode: _focusNode,
                  onSave: _save,
                  tokens: t,
                ),
        ),
      ],
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.controller,
    required this.focusNode,
    required this.onSave,
    required this.tokens,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSave;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): onSave,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): onSave,
      },
      child: CcTextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        textStyle: TextStyle(
          fontFamily: CcFonts.codeFamily,
          fontSize: 13,
          height: 1.5,
          color: tokens.fg,
        ),
        chromeless: true,
      ),
    );
  }
}
