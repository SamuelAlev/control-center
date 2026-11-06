/// Whether [path] matches any of [globs].
///
/// `*` stays inside one path segment and `**` crosses segments. These are
/// matched against repo-relative changed paths.
bool environmentGlobMatches(Iterable<String> globs, String path) =>
    globs.any((glob) => _compile(glob).hasMatch(path));

/// Whether any of [paths] matches any of [globs].
bool environmentAnyPathMatches(
  Iterable<String> globs,
  Iterable<String> paths,
) => paths.any((path) => environmentGlobMatches(globs, path));

RegExp _compile(String glob) {
  final out = StringBuffer('^');
  var index = 0;
  while (index < glob.length) {
    final char = glob[index];
    if (char == '*') {
      final doubled = index + 1 < glob.length && glob[index + 1] == '*';
      if (doubled) {
        final slash = index + 2 < glob.length && glob[index + 2] == '/';
        out.write(slash ? '(?:.*/)?' : '.*');
        index += slash ? 3 : 2;
        continue;
      }
      out.write('[^/]*');
    } else if (char == '?') {
      out.write('[^/]');
    } else {
      out.write(RegExp.escape(char));
    }
    index += 1;
  }
  out.write(r'$');
  return RegExp(out.toString());
}
