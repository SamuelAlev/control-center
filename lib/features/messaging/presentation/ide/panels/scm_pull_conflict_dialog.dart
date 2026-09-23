import 'package:cc_domain/core/domain/entities/ide_editor.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/ide_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the operator chose when a pull would conflict.
sealed class ScmPullConflictChoice {
  const ScmPullConflictChoice();
}

/// Resolve the conflict by hand in [editor].
class ScmPullConflictOpenIde extends ScmPullConflictChoice {
  /// Creates a choice that opens [editor].
  const ScmPullConflictOpenIde(this.editor, {required this.remember});

  /// The editor to launch on the space worktree.
  final IdeEditor editor;

  /// True when the operator picked this editor from the menu, so it becomes
  /// the default next time.
  final bool remember;
}

/// Hand the conflict to an agent in a new conversation.
class ScmPullConflictAskAi extends ScmPullConflictChoice {
  /// Creates the ask-AI choice.
  const ScmPullConflictAskAi();
}

/// Asks whether a conflicting pull should be finished in an editor or by an
/// agent. Returns null when the dialog is dismissed.
Future<ScmPullConflictChoice?> showScmPullConflictDialog(
  BuildContext context, {
  required int count,
  required String branch,
}) {
  return showCcDialog<ScmPullConflictChoice>(
    context: context,
    builder: (context) => ScmPullConflictDialog(count: count, branch: branch),
  );
}

/// Dialog shown when a pull would conflict with the work in this checkout.
class ScmPullConflictDialog extends ConsumerWidget {
  /// Creates a dialog for [count] incoming commits on [branch].
  const ScmPullConflictDialog({
    super.key,
    required this.count,
    required this.branch,
  });

  /// Incoming commits the pull would apply.
  final int count;

  /// Branch the pull targets. An LTR token.
  final String branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final installed = [
      for (final editor
          in ref.watch(installedEditorsProvider).value ?? const <IdeEditor>[])
        if (editor.installed) editor,
    ];
    final selectedId = ref.watch(selectedIdeProvider);
    final editor = preferredInstalledIde(installed, selectedId);

    return CcDialog(
      title: l10n.scmPullConflictTitle,
      onClose: () => Navigator.of(context).pop(),
      content: Text(
        l10n.scmPullConflictBody(count, branch),
        style: TextStyle(fontSize: 13, color: t.textSecondary, height: 1.4),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.line,
          size: CcButtonSize.sm,
          onPressed: () =>
              Navigator.of(context).pop(const ScmPullConflictAskAi()),
          child: Text(l10n.scmAskAi),
        ),
        if (editor != null)
          _OpenInIdeSplit(
            editor: editor,
            installed: installed,
            onOpen: (chosen, {required bool remember}) => Navigator.of(
              context,
            ).pop(ScmPullConflictOpenIde(chosen, remember: remember)),
          ),
      ],
    );
  }
}

class _OpenInIdeSplit extends StatelessWidget {
  const _OpenInIdeSplit({
    required this.editor,
    required this.installed,
    required this.onOpen,
  });

  final IdeEditor editor;
  final List<IdeEditor> installed;
  final void Function(IdeEditor editor, {required bool remember}) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: t.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcTappable(
            onPressed: () => onOpen(editor, remember: false),
            semanticLabel: l10n.openInIde(editor.displayName),
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(4),
              bottomStart: Radius.circular(4),
            ).resolve(Directionality.of(context)),
            builder: (context, states) => Container(
              color: states.contains(WidgetState.hovered)
                  ? t.hover
                  : const Color(0x00000000),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                l10n.openInIde(editor.displayName),
                style: TextStyle(fontSize: 13, color: t.textPrimary),
              ),
            ),
          ),
          SizedBox(
            width: 1,
            height: 28,
            child: ColoredBox(color: t.borderSecondary),
          ),
          CcMenu(
            searchable: installed.length > 8,
            semanticLabel: l10n.openInEditorPrompt,
            target: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Icon(AppIcons.chevronDown, size: 14, color: t.textTertiary),
            ),
            items: [
              for (final candidate in installed)
                CcMenuItem(
                  label: candidate.displayName,
                  selected: candidate.id == editor.id,
                  onSelected: () => onOpen(candidate, remember: true),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
