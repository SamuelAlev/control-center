import 'package:cc_domain/cc_domain.dart' show BuildInfo;
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/changelog/presentation/widgets/changelog_dialog.dart';
import 'package:control_center/features/changelog/providers/changelog_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preference holding the last version this client showed the changelog for.
const String changelogLastSeenVersionKey = 'changelog.last_seen_version';

/// Opens the What's new dialog on the first launch of a new version. Renders
/// nothing.
///
/// A fresh install records its version silently, so only a real update opens
/// the dialog. A version counts as seen once the dialog can show it: when the
/// changelog is unreachable the next launch tries again, rather than opening
/// an error nobody asked for.
class ChangelogAfterUpdate extends ConsumerStatefulWidget {
  /// Creates a [ChangelogAfterUpdate].
  const ChangelogAfterUpdate({
    this.version = BuildInfo.buildVersion,
    super.key,
  });

  /// The running version.
  final String version;

  @override
  ConsumerState<ChangelogAfterUpdate> createState() =>
      _ChangelogAfterUpdateState();
}

class _ChangelogAfterUpdateState extends ConsumerState<ChangelogAfterUpdate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (!mounted) {
      return;
    }
    final prefs = ref.read(appPreferencesProvider);
    final lastSeen = prefs.getString(changelogLastSeenVersionKey);
    if (lastSeen == widget.version) {
      return;
    }
    if (lastSeen == null) {
      await prefs.setString(changelogLastSeenVersionKey, widget.version);
      return;
    }
    try {
      await ref.read(changelogProvider.future);
    } on Object {
      return;
    }
    if (!mounted) {
      return;
    }
    await prefs.setString(changelogLastSeenVersionKey, widget.version);
    if (mounted) {
      await showChangelogDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
