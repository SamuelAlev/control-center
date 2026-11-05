import 'package:rhttp/rhttp.dart';

/// The website's changelog as Markdown, generated from the same data as its
/// changelog page.
const String changelogMarkdownUrl = 'https://usectrl.dev/changelog.md';

/// Fetches the published changelog.
class ChangelogService {
  /// Creates a [ChangelogService] using the given [RhttpClient].
  ChangelogService(this._httpClient);

  final RhttpClient _httpClient;

  /// Fetches the raw Markdown. The `changelog.get` RPC op returns it verbatim
  /// so the thin client parses it with `ChangelogRelease.parseMarkdown`.
  Future<String> fetchMarkdown() async {
    final response = await _httpClient.getText(changelogMarkdownUrl);
    return response.body;
  }
}
