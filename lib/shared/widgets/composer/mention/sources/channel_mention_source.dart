import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';

/// A single channel item available for mention suggestions.
///
/// Models a channel that can be referenced via `@` mentions in the composer.
class ChannelMentionItem {
  /// Creates a [ChannelMentionItem] with the given [id], [name], and [isDm]
  /// flag.
  const ChannelMentionItem({required this.id, required this.name, required this.isDm});
  /// Unique identifier for the channel.
  final String id;
  /// Display name of the channel.
  final String name;
  /// Whether this channel is a direct message conversation.
  final bool isDm;
}

/// Channel mention source.
class ChannelMentionSource extends SyncMentionSource {
  /// Creates a new [Channel mention source].
  ChannelMentionSource(this._channels);

  final List<ChannelMentionItem> _channels;

  @override
  String get kind => 'channel';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.at};

  @override
  String? sectionLabel(BuildContext context) => AppLocalizations.of(context).channelsMentionSection;

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) {
    if (query.trigger != MentionTrigger.at) {
      return const [];
    }
    final q = query.partial.toLowerCase();
    final matches = _channels
        .where((c) => !c.isDm)
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q))
        .take(5);
    return [
      for (final c in matches)
        MentionSuggestion(
          id: 'channel:${c.id}',
          kind: kind,
          label: '#${c.name}',
          description: c.isDm ? 'Direct message' : 'Group channel',
          icon: AppIcons.hash,
          replacement: '#${c.name} ',
          payload: {'channelId': c.id},
        ),
    ];
  }
}

