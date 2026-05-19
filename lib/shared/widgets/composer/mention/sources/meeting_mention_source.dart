import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';

/// Lightweight meeting descriptor for the `#` mention popup.
///
/// Defined here rather than reusing the `Meeting` domain entity because
/// `lib/shared/` must not depend on `lib/features/`. The host maps it across.
class MeetingMentionItem {
  /// Creates a [MeetingMentionItem].
  const MeetingMentionItem({
    required this.id,
    required this.token,
    required this.title,
  });

  /// The meeting's real id (travels in the mention payload).
  final String id;

  /// A short, space-free reference label inserted inline (a title slug).
  final String token;

  /// The meeting title, shown as the suggestion's primary text.
  final String title;
}

/// Suggests meetings for the `#` trigger.
class MeetingMentionSource extends SyncMentionSource {
  /// Creates a [MeetingMentionSource] over a pre-loaded, workspace-scoped list.
  MeetingMentionSource(this._items);

  final List<MeetingMentionItem> _items;

  @override
  String get kind => 'meeting';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.hash};

  @override
  String? sectionLabel(BuildContext context) =>
      AppLocalizations.of(context).meetingsMentionSection;

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) {
    if (query.trigger != MentionTrigger.hash) {
      return const [];
    }
    final q = query.partial.toLowerCase();
    final matches = _items.where(
      (m) =>
          q.isEmpty ||
          m.title.toLowerCase().contains(q) ||
          m.token.toLowerCase().contains(q),
    ).take(8);
    return [
      for (final m in matches)
        MentionSuggestion(
          id: 'meeting:${m.id}',
          kind: kind,
          label: m.title,
          icon: AppIcons.audioLines,
          replacement: '#${m.token} ',
          payload: {'meetingId': m.id, 'label': m.title},
        ),
    ];
  }
}
