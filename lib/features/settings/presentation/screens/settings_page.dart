import 'package:control_center/di/settings_registry.dart';
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
/// features — a page declares that it accepts cards, not which ones.
class SettingsPage extends ConsumerWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.sections,
    this.actions,
    this.slot,
  });

  /// The contribution slot this page exposes, when it exposes one.
  final SettingsSlot? slot;

  /// Page title shown in the header.
  final String title;

  /// One-line description shown under the title.
  final String? subtitle;

  /// Optional actions rendered at the right of the title/subtitle row (e.g. a
  /// page-level "new" button), matching [PageWrapper.actions].
  final List<Widget>? actions;

  /// Section cards stacked in scroll order.
  final List<Widget> sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = this.slot;
    final contributed = slot == null
        ? const <SettingsSectionContribution>[]
        : ref.watch(settingsRegistryProvider).sectionsFor(slot);
    final count = sections.length + contributed.length;

    return SettingsShortcuts(
      child: PageWrapper(
        title: title,
        subtitle: subtitle,
        actions: actions,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: count,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) => index < sections.length
              ? sections[index]
              : contributed[index - sections.length].builder(context),
        ),
      ),
    );
  }
}
