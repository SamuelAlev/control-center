import 'package:control_center/di/settings_registry.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_page_heading.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/features/settings/settings_shortcuts.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared scaffold for a settings sub-page: keyboard shortcuts + a titled,
/// scrollable column of section cards with consistent 16px spacing.
///
/// Naming a [slot] opts the page into feature contributions: whatever other
/// features registered for that slot is appended after [sections]. Doing it
/// here rather than in each screen is what keeps the screens from importing the
/// features — a page declares that it accepts cards, not which ones. A
/// contribution whose [SettingsSectionContribution.visible] answers false is
/// left out, so it leaves no gap between its neighbours.
///
/// A page whose own cards and contributed cards are two subjects names the
/// second with a [slotHeading], and a link that is about the second opens the
/// page there ([openAtSlot]).
class SettingsPage extends ConsumerWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.sections,
    this.actions,
    this.slot,
    this.slotHeading,
    this.openAtSlot = false,
  }) : assert(slotHeading == null || slot != null, 'A heading needs a slot'),
       assert(!openAtSlot || slotHeading != null, 'Opening needs a heading');

  /// The contribution slot this page exposes, when it exposes one.
  final SettingsSlot? slot;

  /// The heading above the contributed cards. Left out, like the cards, when
  /// nothing is contributed.
  final SettingsPageHeading? slotHeading;

  /// Whether the page opens with [slotHeading] at the top instead of its own
  /// first card. The cards above stay one scroll away.
  final bool openAtSlot;

  /// Page title shown in the header.
  final String title;

  /// One-line description shown under the title.
  final String? subtitle;

  /// Optional actions rendered at the right of the title/subtitle row (e.g. a
  /// page-level "new" button), matching [PageWrapper.actions].
  final List<Widget>? actions;

  /// Section cards stacked in scroll order.
  final List<Widget> sections;

  static const double _gap = 16;
  static const double _side = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = this.slot;
    final contributed = slot == null
        ? const <SettingsSectionContribution>[]
        : [
            for (final section
                in ref.watch(settingsRegistryProvider).sectionsFor(slot))
              if (section.visible?.call(ref) ?? true) section,
          ];
    final heading = contributed.isEmpty ? null : slotHeading;
    final count = sections.length + contributed.length;

    return SettingsShortcuts(
      child: PageWrapper(
        title: title,
        subtitle: subtitle,
        actions: actions,
        child: heading == null
            ? ListView.separated(
                padding: const EdgeInsets.fromLTRB(_side, 8, _side, 24),
                itemCount: count,
                separatorBuilder: (_, _) => const SizedBox(height: _gap),
                itemBuilder: (context, index) => index < sections.length
                    ? sections[index]
                    : contributed[index - sections.length].builder(context),
              )
            : _HeadedSlotList(
                own: sections,
                heading: heading,
                contributed: contributed,
                openAtSlot: openAtSlot,
              ),
      ),
    );
  }
}

/// The page's own cards, then a heading and the contributed cards under it.
///
/// Two slivers, so the second can be where the scroll starts. Opening at the
/// heading by scrolling to it would land wrong: the cards above are still
/// loading when the page opens and push it down as they fill in. Making its
/// sliver the centre of the viewport puts the heading at offset zero and
/// everything above it at negative offsets, so what is above can grow without
/// moving what the reader came for.
class _HeadedSlotList extends StatelessWidget {
  const _HeadedSlotList({
    required this.own,
    required this.heading,
    required this.contributed,
    required this.openAtSlot,
  });

  final List<Widget> own;
  final SettingsPageHeading heading;
  final List<SettingsSectionContribution> contributed;
  final bool openAtSlot;

  static const _slotKey = ValueKey<String>('settings-page.slot');

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      center: openAtSlot ? _slotKey : null,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            SettingsPage._side,
            8,
            SettingsPage._side,
            0,
          ),
          // One box, not a list: a sliver above the centre lays its children
          // out bottom-up, which would reverse a list of cards.
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final card in own) ...[
                  card,
                  const SizedBox(height: SettingsPage._gap),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          key: _slotKey,
          padding: const EdgeInsets.fromLTRB(
            SettingsPage._side,
            0,
            SettingsPage._side,
            24,
          ),
          sliver: SliverList.separated(
            itemCount: contributed.length + 1,
            separatorBuilder: (_, _) =>
                const SizedBox(height: SettingsPage._gap),
            itemBuilder: (context, index) =>
                index == 0 ? heading : contributed[index - 1].builder(context),
          ),
        ),
      ],
    );
  }
}
