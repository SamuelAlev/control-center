import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';

/// One slash command exposed by the host feature.
@immutable
class SlashCommand {
  /// Creates a new [SlashCommand].
  const SlashCommand({
    required this.name,
    required this.description,
    this.icon,
  });

  /// Command name (e.g. 'explain', 'refactor').
  final String name;

  /// Short description shown in the popup.
  final String description;

  /// Optional icon for the command row.
  final IconData? icon;
}

/// Slash command source.
class SlashCommandSource extends SyncMentionSource {
  /// Creates a new [SlashCommandSource].
  SlashCommandSource(this._commands);

  final List<SlashCommand> _commands;

  @override
  String get kind => 'slash';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.slash};

  @override
  String? sectionLabel(BuildContext context) => AppLocalizations.of(context).commandsMentionSection;

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) {
    if (query.trigger != MentionTrigger.slash) {
      return const [];
    }
    final q = query.partial.toLowerCase();
    final matches = _commands
        .where((c) => q.isEmpty || c.name.toLowerCase().startsWith(q))
        .take(8);
    return [
      for (final c in matches)
        MentionSuggestion(
          id: 'slash:${c.name}',
          kind: kind,
          label: '/${c.name}',
          description: c.description,
          icon: c.icon ?? AppIcons.terminal,
          replacement: '/${c.name} ',
          payload: {'command': c.name},
        ),
    ];
  }
}

