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
    this.badge,
  });

  /// Command name (e.g. 'explain', 'refactor').
  final String name;

  /// Short description shown in the popup.
  final String description;

  /// Optional icon for the command row.
  final IconData? icon;

  /// Optional provenance chip — the repo a skill came from, so two repos that
  /// each ship a `testing` are told apart in the list.
  final String? badge;
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
  String? sectionLabel(BuildContext context) =>
      AppLocalizations.of(context).commandsMentionSection;

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) {
    if (query.trigger != MentionTrigger.slash) {
      return const [];
    }
    final q = query.partial.toLowerCase();
    final matches = _commands.where((c) => _matches(c.name, q)).take(8);
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
          badge: c.badge,
        ),
    ];
  }

  /// Whether [name] matches what has been typed so far.
  ///
  /// A namespaced name matches on any of its `:`-suffixes, not just the whole
  /// string: `skill:web-app:testing` is found by typing `skill:`, `web-app:` or
  /// plain `testing`. Without the suffixes the namespace that keeps skills out
  /// of the builtin vocabulary would also hide them — you would have to know
  /// both the prefix and the repo before you could search for the skill.
  static bool _matches(String name, String query) {
    if (query.isEmpty) {
      return true;
    }
    final lower = name.toLowerCase();
    if (lower.startsWith(query)) {
      return true;
    }
    for (var i = lower.indexOf(':'); i != -1; i = lower.indexOf(':', i + 1)) {
      if (lower.startsWith(query, i + 1)) {
        return true;
      }
    }
    return false;
  }
}
