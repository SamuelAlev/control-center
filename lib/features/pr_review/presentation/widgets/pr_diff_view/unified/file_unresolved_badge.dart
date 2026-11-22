import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// The file header's count of open review conversations on that file.
///
/// A conversation only shows inside the file's body, so a collapsed file, or
/// one whose thread sits below the fold, gave no sign it had anything waiting.
/// Read-only: it says how many, the threads themselves are where to act.
class FileUnresolvedBadge extends StatelessWidget {
  /// Creates the badge for [count] open conversations (must be positive).
  const FileUnresolvedBadge({super.key, required this.count})
    : assert(count > 0, 'nothing to badge');

  /// Open conversations on the file.
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = l10n.diffFileUnresolvedConversations(count);
    // Its own node: without one the label folds into the header's.
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(
        child: CcTooltip(
          message: label,
          child: CcBadge(
            label: NumberFormat.decimalPattern(l10n.localeName).format(count),
            variant: CcBadgeVariant.brand,
            icon: AppIcons.messageSquare,
          ),
        ),
      ),
    );
  }
}
