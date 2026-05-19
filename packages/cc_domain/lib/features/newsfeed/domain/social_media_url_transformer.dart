final _domainRewrites = {
  'twitter.com': 'xcancel.com',
  'x.com': 'xcancel.com',
  'tiktok.com': 'vxtiktok.com',
};

/// Transform social media url.
String transformSocialMediaUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return url;
  }
  final host = uri.host.replaceFirst('www.', '');
  final rewritten = _domainRewrites[host.toLowerCase()];
  if (rewritten == null) {
    return url;
  }
  return uri.replace(host: rewritten).toString();
}
