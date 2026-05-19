import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';

/// A single space item available for mention suggestions.
///
/// Models a space that can be referenced via `@` mentions in the composer.
class SpaceMentionItem {
  /// Creates a [SpaceMentionItem] with the given [id] and [name].
  const SpaceMentionItem({required this.id, required this.name});

  /// Unique identifier for the space.
  final String id;

  /// Display name of the space.
  final String name;
}

/// Space mention source.
class SpaceMentionSource extends SyncMentionSource {
  /// Creates a new [SpaceMentionSource] over [_spaces].
  SpaceMentionSource(this._spaces);

  final List<SpaceMentionItem> _spaces;

  @override
  String get kind => 'space';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.at};

  @override
  String? sectionLabel(BuildContext context) =>
      AppLocalizations.of(context).spacesMentionSection;

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) {
    if (query.trigger != MentionTrigger.at) {
      return const [];
    }
    final q = query.partial.toLowerCase();
    final matches = _spaces
        .where((s) => q.isEmpty || s.name.toLowerCase().contains(q))
        .take(5);
    return [
      // No per-row description: the section header already reads "Spaces" and
      // the `#` icon carries the kind, so repeating it on every row is noise.
      for (final s in matches)
        MentionSuggestion(
          id: 'space:${s.id}',
          kind: kind,
          label: '#${s.name}',
          icon: AppIcons.hash,
          replacement: '#${s.name} ',
          payload: {'spaceId': s.id},
        ),
    ];
  }
}
