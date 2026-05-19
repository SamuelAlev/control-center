import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';

/// Lightweight ticket descriptor for the `#` mention popup.
///
/// Defined here rather than reusing the `Ticket` domain entity because
/// `lib/shared/` must not depend on `lib/features/` (architecture constraint).
/// The host (a messaging input bar) maps `Ticket` → [TicketMentionItem].
class TicketMentionItem {
  /// Creates a [TicketMentionItem].
  const TicketMentionItem({
    required this.id,
    required this.token,
    required this.title,
  });

  /// The ticket's real id (travels in the mention payload).
  final String id;

  /// A short, space-free reference label inserted inline (e.g. `LIN-123`).
  final String token;

  /// The ticket title, shown as the suggestion's secondary text.
  final String title;
}

/// Suggests tickets for the `#` trigger.
class TicketMentionSource extends SyncMentionSource {
  /// Creates a [TicketMentionSource] over a pre-loaded, workspace-scoped list.
  TicketMentionSource(this._items);

  final List<TicketMentionItem> _items;

  @override
  String get kind => 'ticket';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.hash};

  @override
  String? sectionLabel(BuildContext context) =>
      AppLocalizations.of(context).ticketsMentionSection;

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) {
    if (query.trigger != MentionTrigger.hash) {
      return const [];
    }
    final q = query.partial.toLowerCase();
    final matches = _items.where(
      (t) =>
          q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          t.token.toLowerCase().contains(q),
    ).take(8);
    return [
      for (final t in matches)
        MentionSuggestion(
          id: 'ticket:${t.id}',
          kind: kind,
          label: t.token,
          description: t.title,
          icon: AppIcons.ticket,
          replacement: '#${t.token} ',
          payload: {'ticketId': t.id, 'label': t.token},
        ),
    ];
  }
}
