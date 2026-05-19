import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChannelMentionItem {
  const ChannelMentionItem({required this.id, required this.name, required this.isDm});
  final String id;
  final String name;
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
          icon: LucideIcons.hash,
          replacement: '#${c.name} ',
          payload: {'channelId': c.id},
        ),
    ];
  }
}

