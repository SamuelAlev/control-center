import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/source_filter_menu.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search field + source multi-select + All/Unread/Saved view segments and
/// the grid/list layout switch, both on [CcSegmentedToggle].
class NewsfeedToolbar extends ConsumerWidget {
  /// Creates a [NewsfeedToolbar].
  const NewsfeedToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(newsfeedViewProvider);
    final layout = ref.watch(newsfeedLayoutProvider);

    // Search is Flexible (it may shrink) and the source menu is not, so a
    // sibling Spacer would split the free width with the search and leave the
    // unused share as a gap after the toggles. The leading cluster takes that
    // width instead, which pins both segmented controls to the trailing edge.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const _ArticleSearchField(),
                  ),
                ),
                const SizedBox(width: 8),
                SourceFilterMenu(provider: newsfeedFilterProvider),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CcSegmentedToggle<NewsfeedView>(
            value: view,
            // Field height: these sit in the same row as the search field.
            size: CcSegmentedToggleSize.md,
            onChanged: (v) => ref.read(newsfeedViewProvider.notifier).set(v),
            segments: [
              CcSegment(value: NewsfeedView.all, label: l10n.filterAll),
              CcSegment(value: NewsfeedView.unread, label: l10n.filterUnread),
              CcSegment(value: NewsfeedView.saved, label: l10n.filterSaved),
            ],
          ),
          const SizedBox(width: 8),
          CcSegmentedToggle<NewsfeedLayout>(
            value: layout,
            size: CcSegmentedToggleSize.md,
            onChanged: (v) {
              unawaited(ref.read(newsfeedLayoutProvider.notifier).set(v));
            },
            segments: [
              CcSegment(
                value: NewsfeedLayout.grid,
                label: l10n.viewAsGrid,
                icon: AppIcons.layoutGrid,
                iconOnly: true,
              ),
              CcSegment(
                value: NewsfeedLayout.list,
                label: l10n.viewAsList,
                icon: AppIcons.list,
                iconOnly: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Search input bound to [newsfeedSearchProvider], with an inline clear
/// affordance.
class _ArticleSearchField extends ConsumerStatefulWidget {
  const _ArticleSearchField();

  @override
  ConsumerState<_ArticleSearchField> createState() =>
      _ArticleSearchFieldState();
}

class _ArticleSearchFieldState extends ConsumerState<_ArticleSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(newsfeedSearchProvider));
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    ref.read(newsfeedSearchProvider.notifier).set(_controller.text);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasText = _controller.text.isNotEmpty;
    return CcTextField(
      hintText: l10n.searchArticles,
      controller: _controller,
      prefix: const Icon(AppIcons.search, size: 16),
      suffix: hasText
          ? Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: CcIconButton(
                icon: AppIcons.x,
                size: CcButtonSize.sm,
                tooltip: l10n.clear,
                onPressed: () => _controller.clear(),
              ),
            )
          : null,
    );
  }
}
