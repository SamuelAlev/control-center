import 'package:cc_domain/features/changelog/domain/entities/changelog_release.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The server could not return a readable changelog.
class ChangelogUnavailable implements Exception {
  /// Creates a [ChangelogUnavailable].
  const ChangelogUnavailable();
}

/// The website's published releases, newest first, fetched by the server. Held
/// for the session; invalidate it to retry a failure. Riverpod's automatic
/// retry stays off, or the dialog would spin instead of offering its own.
final changelogProvider = FutureProvider<List<ChangelogRelease>>(
  retry: (_, _) => null,
  (ref) async {
    final data = await ref
        .read(rpcClientProvider)
        .call('changelog.get', const {});
    final markdown = data['markdown'];
    final releases = markdown is String
        ? ChangelogRelease.parseMarkdown(markdown)
        : const <ChangelogRelease>[];
    if (releases.isEmpty) {
      throw const ChangelogUnavailable();
    }
    return releases;
  },
);
