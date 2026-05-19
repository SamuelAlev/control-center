import 'package:control_center/di/settings_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders whichever feature contributed the body for [navItemId].
///
/// Settings owns the route and the sub-sidebar entry; the feature owns what
/// fills the page. This is the whole of what settings knows about a contributed
/// destination — a string id from its own nav model, matched against whatever
/// `di/settings_registry.dart` was handed.
class SettingsBodyHost extends ConsumerWidget {
  /// Creates a [SettingsBodyHost] for the destination [navItemId].
  const SettingsBodyHost({super.key, required this.navItemId});

  /// The `SettingsNavItem.id` whose body to render.
  final String navItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = ref.watch(settingsRegistryProvider).bodyFor(navItemId);
    // Silent rather than an error surface: the only way to get here is a
    // destination whose feature was removed or never registered, which
    // `settings_registry_test.dart` fails on at build time. Rendering an error
    // to a user for a wiring mistake a test already catches is noise.
    return body?.builder(context) ?? const SizedBox.shrink();
  }
}
