import 'package:control_center/features/settings/presentation/widgets/settings_body_host.dart';
import 'package:flutter/widgets.dart';

/// Settings → You → Newsfeed.
///
/// Route and nav entry only: the page itself is the `newsfeed` feature's, and
/// arrives through the settings registry.
class NewsfeedSettingsScreen extends StatelessWidget {
  /// Creates a [NewsfeedSettingsScreen].
  const NewsfeedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsBodyHost(navItemId: 'you.newsfeed');
}
