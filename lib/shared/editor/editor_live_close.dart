// The close prompt for a tab that owns something still running.
//
// Some tabs are pure views (a file, a plan, a diff) and closing one costs
// nothing. Others hold a live thing that outlives their pane: an enclosed
// machine, a shell mid-command, an agent mid-run. Closing those used to mean
// one of two silent extremes — the machine was destroyed without asking, or
// the work carried on with no trace in the UI that it had. Both are decisions
// the person closing the tab is the only one able to make, so this asks.
//
// Deliberately feature-neutral: it knows nothing about rigs, PTYs or runs. The
// host decides WHEN a tab is live (see each kind's "actively used" test) and
// supplies the words; the vocabulary — keep it running, end it, or cancel —
// is what stays identical across all three.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// What the person chose when closing a tab with live work behind it.
enum LiveTabCloseChoice {
  /// Close the tab; leave the machine, shell or run going.
  keepRunning,

  /// Close the tab and end what it was running.
  shutDown,

  /// Do not close the tab.
  cancel,
}

/// Asks whether to keep [title]'s work running or end it, returning the
/// choice. A dismissal (Escape, scrim) is [LiveTabCloseChoice.cancel] — closing
/// a tab is undoable, ending a VM or a run is not, so an ambiguous gesture
/// must never be read as the destructive answer.
///
/// [body] says what keeps running and where to find it again; [shutDownLabel]
/// names the destructive action in that tab's own words ("Shut down", "End
/// shell", "Stop agent") rather than a generic one, because those are three
/// different consequences.
Future<LiveTabCloseChoice> confirmCloseLiveTab({
  required BuildContext context,
  required String title,
  required String body,
  required String shutDownLabel,
}) async {
  final l10n = AppLocalizations.of(context);
  final t = context.designSystem ?? DesignSystemTokens.light();
  final choice = await showCcDialog<LiveTabCloseChoice>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: title,
      content: Text(
        body,
        style: CcTypography.body.copyWith(color: t.textTertiary),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: () =>
              Navigator.pop(dialogContext, LiveTabCloseChoice.cancel),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () =>
              Navigator.pop(dialogContext, LiveTabCloseChoice.shutDown),
          child: Text(shutDownLabel),
        ),
        // Keeping it running is the primary action: it is the reversible one,
        // and the tab can always be reopened from the sidebar.
        CcButton(
          onPressed: () =>
              Navigator.pop(dialogContext, LiveTabCloseChoice.keepRunning),
          child: Text(l10n.ideCloseKeepRunning),
        ),
      ],
    ),
  );
  return choice ?? LiveTabCloseChoice.cancel;
}
