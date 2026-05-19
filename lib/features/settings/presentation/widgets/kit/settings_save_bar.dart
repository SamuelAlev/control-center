import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The commit bar for a settings form that saves as a unit.
///
/// Most settings in this app apply on change, which is right for a switch. A
/// few — an SSO connection, a provider's base URL — are a set of values that
/// only make sense saved together, and those had their Save button parked at
/// the bottom of a long scroll with nothing anywhere saying the form was dirty.
/// You could edit four fields, navigate away, and lose all four without the
/// interface ever mentioning it.
///
/// So by default the bar appears when, and only when, there is something to
/// commit. It states that there is unsaved work, offers to discard it, and
/// puts Save at the end of the row where the eye lands last. When the form is
/// clean it is not a disabled button, it is nothing at all — a permanently
/// greyed Save is noise that teaches the reader to ignore that corner of the
/// card. [persistentSave] opts a surface out of that last part; see its doc
/// for the one shape where it is right.
class SettingsSaveBar extends StatelessWidget {
  /// Creates a [SettingsSaveBar].
  const SettingsSaveBar({
    super.key,
    required this.dirty,
    required this.onSave,
    this.onDiscard,
    this.busy = false,
    this.message,
    this.error,
    this.secondaryActions = const [],
    this.saveLabel,
    this.persistentSave = false,
  });

  /// Whether there is anything to commit.
  final bool dirty;

  /// Commits. Disabled while [busy].
  final VoidCallback onSave;

  /// Reverts to the last loaded values. Omit when the form cannot revert.
  final VoidCallback? onDiscard;

  /// Shows a spinner in Save and blocks both actions.
  final bool busy;

  /// Overrides the default "You have unsaved changes" line.
  final String? message;

  /// A failure from the last attempt. Shown in place of [message], in danger.
  final String? error;

  /// Actions that belong with the form but are not the commit (a connection
  /// test, a metadata copy). Always visible, dirty or not.
  final List<Widget> secondaryActions;

  /// Overrides the Save label (e.g. "Save connection").
  final String? saveLabel;

  /// Keeps the bar — and a disabled Save — on screen while the form is clean.
  ///
  /// Off by default, and the default is the right one for a card in a scroll:
  /// a permanently greyed Save is noise that teaches the reader to ignore that
  /// corner. Turn it on only where the bar is the pane's own pinned footer and
  /// the form is its whole subject (the agent registry's Settings tab), because
  /// there the reader looks for Save BEFORE editing — to find out whether this
  /// surface commits at all — and a bar that materialises on the first
  /// keystroke answers that question too late.
  final bool persistentSave;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final reducedMotion =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        (context.ccTheme?.reducedMotion ?? false);

    final hasSecondary = secondaryActions.isNotEmpty;
    if (!dirty && !hasSecondary && error == null && !persistentSave) {
      return const SizedBox.shrink();
    }

    final bar = Container(
      key: ValueKey(dirty || error != null),
      decoration: BoxDecoration(
        color: dirty ? tokens.bgSecondary : null,
        border: Border(top: BorderSide(color: tokens.borderSecondary)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      // A Wrap, not a Row: the bar carries up to four things (the status line,
      // a secondary action, Discard, Save) and it sits in a detail pane whose
      // width is whatever is left after a rail. As a Row with an `Expanded`
      // status line, a pane too narrow for the buttons collapsed that text to
      // zero width — which wraps it one character per line and blows the bar up
      // to a couple of hundred pixels tall — and then overflowed anyway.
      // Wrapping degrades instead: the actions drop to their own line, and the
      // buttons wrap among themselves if even that is not enough.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          if (error != null)
            _StatusLine(
              text: error!,
              color: tokens.textErrorPrimary,
              iconColor: tokens.textErrorPrimary,
            )
          else if (dirty)
            _StatusLine(
              text: message ?? l10n.unsavedChanges,
              color: tokens.textSecondary,
              iconColor: tokens.warn,
            )
          else
            const SizedBox.shrink(),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ...secondaryActions,
              if (dirty && onDiscard != null)
                CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  onPressed: busy ? null : onDiscard,
                  child: Text(l10n.discard),
                ),
              if (dirty || persistentSave)
                CcButton(
                  variant: CcButtonVariant.accent,
                  size: CcButtonSize.sm,
                  loading: busy,
                  onPressed: (busy || !dirty) ? null : onSave,
                  child: Text(saveLabel ?? l10n.save),
                ),
            ],
          ),
        ],
      ),
    );

    if (reducedMotion) {
      return bar;
    }
    return AnimatedSize(
      duration: CcMotion.fast,
      curve: CcMotion.standard,
      alignment: Alignment.topCenter,
      child: bar,
    );
  }
}

/// The bar's left-hand line: an alert glyph and one sentence about the form's
/// state. Sized to its content so the surrounding [Wrap] can move the actions
/// to a second line instead of squeezing it.
class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.text,
    required this.color,
    required this.iconColor,
  });

  final String text;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.circleAlert, size: 15, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: CcTypography.caption.copyWith(color: color)),
      ],
    );
  }
}
