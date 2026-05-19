import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Agent mention source.
class AgentMentionSource extends SyncMentionSource {
  /// Creates a new [Agent mention source].
  AgentMentionSource(this._agents);

  final List<Agent> _agents;

  @override
  String get kind => 'agent';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.at};

  @override
  String? sectionLabel(BuildContext context) => AppLocalizations.of(context).agentsMentionSection;

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) {
    if (query.trigger != MentionTrigger.at) {
      return const [];
    }
    final q = query.partial.toLowerCase();
    final matches = _agents.where((a) {
      final n = a.name.toLowerCase();
      return q.isEmpty || n.contains(q);
    }).take(8);
    return [
      for (final a in matches)
        MentionSuggestion(
          id: 'agent:${a.id}',
          kind: kind,
          label: a.name,
          description: a.title,
          icon: LucideIcons.bot,
          replacement: '@${a.name} ',
          payload: {'agentId': a.id, 'agentName': a.name},
        ),
    ];
  }
}

