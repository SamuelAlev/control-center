import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A quiet neutral "Draft" badge shown beside a draft PR's title.
class PrDraftBadge extends StatelessWidget {
  /// Creates a [PrDraftBadge].
  const PrDraftBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return CcBadge(
      label: AppLocalizations.of(context).draft,
      icon: AppIcons.gitPullRequestDraft,
    );
  }
}
