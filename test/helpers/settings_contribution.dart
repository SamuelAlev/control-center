import 'package:control_center/di/settings_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The registered settings section [id] as its page builds it: the card while
/// the contribution's `visible` predicate holds, nothing otherwise.
///
/// For tests of a card that is only sometimes relevant: whether it shows is
/// decided by its contribution, not by the widget, so the widget alone would
/// not say.
class ContributedSection extends ConsumerWidget {
  /// Creates the section registered as [id].
  const ContributedSection(this.id, {super.key});

  /// The contribution's `<feature>.<section>` id.
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref
        .watch(settingsRegistryProvider)
        .sections
        .singleWhere((s) => s.id == id);
    return section.visible?.call(ref) ?? true
        ? section.builder(context)
        : const SizedBox.shrink();
  }
}
