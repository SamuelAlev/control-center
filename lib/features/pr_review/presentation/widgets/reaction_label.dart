import 'package:control_center/l10n/app_localizations.dart';

/// Localized name for a GitHub reaction content key (`+1`, `heart`, …).
///
/// The picker and the chips show only the emoji; this is the hover
/// explanation.
String prReactionLabel(AppLocalizations l10n, String content) {
  return switch (content) {
    '+1' => l10n.reactionThumbsUp,
    '-1' => l10n.reactionThumbsDown,
    'laugh' => l10n.reactionLaugh,
    'hooray' => l10n.reactionHooray,
    'confused' => l10n.reactionConfused,
    'heart' => l10n.reactionHeart,
    'rocket' => l10n.reactionRocket,
    'eyes' => l10n.reactionEyes,
    _ => content,
  };
}

/// Chip tooltip: the reaction name, plus who reacted when we know.
String prReactionChipTooltip(
  AppLocalizations l10n,
  String content,
  List<String> usernames,
) {
  final label = prReactionLabel(l10n, content);
  if (usernames.isEmpty) {
    return label;
  }
  return '$label · ${usernames.join(', ')}';
}
