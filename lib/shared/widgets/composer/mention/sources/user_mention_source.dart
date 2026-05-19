import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/agent_mention_source.dart';
import 'package:flutter/widgets.dart';

/// A workspace member the composer can suggest for a human `@mention` (PRD
/// 16 §15 — mentions resolve to principals, humans as well as agents).
class UserMentionItem {
  /// Creates a new [UserMentionItem].
  const UserMentionItem({
    required this.id,
    required this.handle,
    required this.displayName,
  });

  /// The user's id.
  final String id;

  /// The user's unique handle — what `@token` matches against server-side
  /// (see `UserMentionParser`).
  final String handle;

  /// The user's display name, shown as the suggestion's description.
  final String displayName;
}

/// User (human) mention source — the human-mention counterpart to
/// [AgentMentionSource]. Suggests the active workspace's members by handle;
/// selecting one inserts `@handle`, which the server's `UserMentionParser`
/// resolves against the same workspace's members.
///
/// A human mention never dispatches anything (unlike an agent mention) — it
/// exists purely so the notification router (PRD 16 §7) can ping the
/// mentioned person.
class UserMentionSource extends SyncMentionSource {
  /// Creates a new [UserMentionSource].
  UserMentionSource(this._members);

  final List<UserMentionItem> _members;

  @override
  String get kind => 'user';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.at};

  @override
  String? sectionLabel(BuildContext context) =>
      AppLocalizations.of(context).usersMentionSection;

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) {
    if (query.trigger != MentionTrigger.at) {
      return const [];
    }
    final q = query.partial.toLowerCase();
    final matches = _members
        .where((m) {
          final handle = m.handle.toLowerCase();
          final name = m.displayName.toLowerCase();
          return q.isEmpty || handle.contains(q) || name.contains(q);
        })
        .take(8);
    return [
      for (final m in matches)
        MentionSuggestion(
          id: 'user:${m.id}',
          kind: kind,
          label: m.handle,
          description: m.displayName,
          icon: AppIcons.user,
          replacement: '@${m.handle} ',
          payload: {'userId': m.id, 'handle': m.handle},
        ),
    ];
  }
}
