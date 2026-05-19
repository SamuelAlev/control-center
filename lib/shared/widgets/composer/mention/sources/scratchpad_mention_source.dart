import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';

/// Mention source that suggests the workspace scratchpad via `@task`.
class ScratchpadMentionSource extends SyncMentionSource {
  /// Creates a [ScratchpadMentionSource] scoped to an optional [workspaceId].
  ScratchpadMentionSource({this.workspaceId});

  /// The workspace whose scratchpad is suggested. When `null`, no suggestion
  /// is returned.
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
        icon: AppIcons.notebookText,
        replacement: '@task ',
        payload: {
          'scratchpadId': workspaceId,
          'workspaceId': workspaceId,
        },
      ),
    ];
  }
}
