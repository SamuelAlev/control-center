import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ScratchpadMentionSource extends SyncMentionSource {
  ScratchpadMentionSource({this.workspaceId});

  final String? workspaceId;

  @override
  String get kind => 'scratchpad';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.at};

  @override
  String? sectionLabel(BuildContext context) => AppLocalizations.of(context).taskMentionSection;

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) {
    if (query.trigger != MentionTrigger.at) {
      return const [];
    }
    if (workspaceId == null) {
      return const [];
    }
    final partial = query.partial.toLowerCase();
    const aliases = ['notes', 'scratchpad', 'note', 'task'];
    final matchesAlias = partial.isEmpty ||
        aliases.any((a) => a.startsWith(partial));
    if (!matchesAlias) {
      return const [];
    }
    return [
      MentionSuggestion(
        id: 'scratchpad:$workspaceId',
        kind: kind,
        label: 'task',
        description: 'Workspace notes & scratchpad',
        icon: LucideIcons.notebookText,
        replacement: '@task ',
        payload: {
          'scratchpadId': workspaceId,
          'workspaceId': workspaceId,
        },
      ),
    ];
  }
}
