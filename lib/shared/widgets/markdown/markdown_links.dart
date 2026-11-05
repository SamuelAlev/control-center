import 'package:control_center/shared/utils/open_url.dart';

/// The `onTapLink` for markdown that isn't bound to a GitHub repo (chat
/// transcripts, artifacts, notes): hands an openable link to the system
/// browser and ignores everything else.
///
/// A top-level function on purpose: the markdown widgets memoize on the
/// handler's identity, so a fresh closure per build would defeat the cache.
void openMarkdownLink(String url) {
  if (isOpenableMarkdownLink(url)) {
    openExternalUrl(url);
  }
}

/// Whether [url] is safe to hand to the OS handler. Link targets come from
/// agent output and other untrusted text, so only web and mail links pass;
/// `file:`, `javascript:` and custom app schemes could launch local software,
/// and relative or fragment-only targets have nothing to resolve against.
bool isOpenableMarkdownLink(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return false;
  }
  return switch (uri.scheme.toLowerCase()) {
    'http' || 'https' => uri.host.isNotEmpty,
    'mailto' => uri.path.isNotEmpty,
    _ => false,
  };
}
