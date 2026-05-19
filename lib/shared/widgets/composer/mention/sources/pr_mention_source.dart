import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';

/// Lightweight pull-request descriptor for the `#` mention popup.
///
/// Defined here rather than reusing the `PullRequest` domain entity because
/// `lib/shared/` must not depend on `lib/features/`. The host maps it across.
class PrMentionItem {
  /// Creates a [PrMentionItem].
  const PrMentionItem({
    required this.number,
    required this.repoFullName,
    required this.title,
  });

  /// PR number within its repository.
  final int number;

  /// `owner/repo` the PR belongs to (needed to resolve it across repos).
  final String repoFullName;

  /// PR title, shown as the suggestion's secondary text.
  final String title;
}

/// Suggests pull requests for the `#` trigger.
class PrMentionSource extends SyncMentionSource {
  /// Creates a [PrMentionSource] over a pre-loaded, workspace-scoped list.
  PrMentionSource(this._items);

  final List<PrMentionItem> _items;

  @override
  String get kind => 'pr';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.hash};

  @override
  String? sectionLabel(BuildContext context) =>
      AppLocalizations.of(context).pullRequestsMentionSection;

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) {
    if (query.trigger != MentionTrigger.hash) {
      return const [];
    }
    final q = query.partial.toLowerCase();
    final matches = _items.where(
      (p) =>
          q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          '${p.number}'.contains(q),
    ).take(8);
    return [
      for (final p in matches)
        MentionSuggestion(
          id: 'pr:${p.repoFullName}#${p.number}',
          kind: kind,
          label: '#${p.number}',
          description: p.title,
          icon: AppIcons.gitPullRequest,
          replacement: '#${p.number} ',
          payload: {
            'number': p.number,
            'repoFullName': p.repoFullName,
            'label': '#${p.number}',
          },
        ),
    ];
  }
}
