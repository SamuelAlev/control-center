import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Shared unsaved-changes ("dirty") support for the embedded code-server editor,
/// used by BOTH the messaging IDE and the PR workbench so the per-tab dirty dot
/// and the Save / Don't-save / Cancel close prompt have ONE implementation.
///
/// The embedded editor owns the file buffer, so the app only learns a file is
/// dirty by being told (the bridge extension reports each dirty↔clean
/// transition). A host tracks those reports here, keyed by worktree-relative
/// path and asks [confirmCloseDirtyEditorTab] before closing a dirty tab.
///
/// Deliberately feature-neutral: it knows nothing about tab kinds, channels, or
/// the RPC save op. The host resolves those and passes an `onSave` closure — so
/// this stays in the shared editor engine layer with no feature dependency.
class EditorDirtyTracker {
  final Map<String, bool> _dirty = {};

  /// Whether the worktree-relative [path] currently has unsaved changes. A null
  /// / empty path (e.g. the bare editor tab with no file) is never dirty.
  bool isDirty(String? path) =>
      path != null && path.isNotEmpty && (_dirty[path] ?? false);

  /// Records a dirty↔clean transition for [path]. Returns true when the state
  /// actually changed (so the host can `setState` only when needed). Empty
  /// paths are ignored.
  bool set({required String path, required bool dirty}) {
    if (path.isEmpty) {
      return false;
    }
    final current = _dirty[path] ?? false;
    if (current == dirty) {
      return false;
    }
    if (dirty) {
      _dirty[path] = true;
    } else {
      _dirty.remove(path);
    }
    return true;
  }

  /// Drops all tracked state — e.g. when a host switches conversation (keys are
  /// path-only and not conversation-qualified).
  void clear() => _dirty.clear();
}

/// The user's choice in the unsaved-changes close prompt.
enum _CloseDecision { save, dontSave, cancel }

/// Close interceptor for a code-server editor tab. When the file is clean this
/// returns true immediately; when dirty it shows a Save / Don't save / Cancel
/// prompt and, on **Save**, awaits [onSave] (which asks the embedded editor to
/// persist the buffer) before returning true. Returns false to cancel the close
/// (Cancel, or scrim/Escape dismissal).
///
/// [fileName] is shown in the prompt title (typically the path's basename).
Future<bool> confirmCloseDirtyEditorTab({
  required BuildContext context,
  required bool isDirty,
  required String fileName,
  required Future<void> Function() onSave,
}) async {
  if (!isDirty) {
    return true;
  }
  final l10n = AppLocalizations.of(context);
  final t = context.designSystem ?? DesignSystemTokens.light();
  final decision = await showCcDialog<_CloseDecision>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.ideUnsavedChangesTitle(fileName),
      content: Text(
        l10n.ideUnsavedChangesBody,
        style: CcTypography.body.copyWith(color: t.textTertiary),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: () => Navigator.pop(dialogContext, _CloseDecision.cancel),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () =>
              Navigator.pop(dialogContext, _CloseDecision.dontSave),
          child: Text(l10n.ideDontSave),
        ),
        CcButton(
          onPressed: () => Navigator.pop(dialogContext, _CloseDecision.save),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  switch (decision ?? _CloseDecision.cancel) {
    case _CloseDecision.cancel:
      return false;
    case _CloseDecision.dontSave:
      return true;
    case _CloseDecision.save:
      await onSave();
      return true;
  }
}
