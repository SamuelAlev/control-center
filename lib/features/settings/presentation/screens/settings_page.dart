import 'package:control_center/features/settings/presentation/widgets/settings_shortcuts.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';

/// Shared scaffold for a settings sub-page: keyboard shortcuts + a titled,
/// scrollable column of section cards with consistent 16px spacing.
class SettingsPage extends StatelessWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.sections,
    this.actions,
  });

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
  Widget build(BuildContext context) {
    return SettingsShortcuts(
      child: PageWrapper(
        title: title,
        subtitle: subtitle,
        actions: actions,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, index) => sections[index],
        ),
      ),
    );
  }
}
