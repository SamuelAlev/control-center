import 'dart:io';

/// [text] with [knownPaths] and every other absolute path replaced by
/// `<path>`.
///
/// Known paths go first, longest first, the user's home among them, in any
/// letter case: a known path is replaced whole whatever its name holds
/// (spaces, `, `, `: `, a quote), together with what follows it by the
/// patterns' rule (a path under it, by `/` or `\`, or a longer name it
/// starts; an unrelated word that only starts like it may go too). The
/// patterns are the fallback for paths no one could name in
/// advance, such as one the runner printed on stderr: an absolute POSIX
/// path, a `file://` URL's path, a `~/` or `~user/` path, a Windows drive
/// path or a UNC path. Such a path runs to the next quote, bracket, `: `,
/// `, ` or blank, and on over a blank only when the next word holds a
/// path separator, so the words after it survive; a name with a blank or
/// one of those in it can leave its tail. A URL that is not a file's, a
/// glob (`**/*.dart`), a word with a slash (`and/or`) and a lone slash are
/// left alone; a regular expression or an HTTP path written alone is
/// shaped like a path and is replaced.
String scrubHostPaths(String text, {Iterable<String> knownPaths = const []}) {
  var out = text;
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  final known = [
    for (final path in [...knownPaths, ?home])
      if (path.length > 1) path,
  ]..sort((a, b) => b.length.compareTo(a.length));
  for (final path in known) {
    out = out.replaceAll(
      RegExp('${RegExp.escape(path)}$_pathRun', caseSensitive: false),
      '<path>',
    );
  }
  return out
      .replaceAll(_uncPath, '<path>')
      .replaceAll(_windowsPath, '<path>')
      .replaceAll(_homePath, '<path>')
      .replaceAll(_posixPath, '<path>')
      .replaceAll(_repeated, '<path>');
}

/// What a path runs over after its first separator: anything but a blank,
/// a quote or a closing bracket; a `,` or `:` not followed by a blank; and
/// a blank followed by a word that holds a path separator. Each blank's
/// look-ahead reads one word, so the match stays linear.
const String _pathRun =
    r"""(?:[^\s'"`)\],:]|[,:](?! )| (?=[^\s'"`)\]/\\]*[/\\]))*""";

/// An absolute POSIX path, after a single `:` too (`failed:/opt/x`), or
/// the path of a `file:` URL; not one inside a word (`and/or`), a number
/// (`1/2`), a tag or a glob, and not the `//` of another scheme's URL or a
/// lone slash.
final RegExp _posixPath = RegExp(
  '(?:(?<=\\bfile:)/|(?<![\\w.<:/*~])/|(?<=:)/(?!/))'
  '(?=[^\\s\'"`])$_pathRun',
);

/// A path under a home directory: `~/…` or `~user/…`.
final RegExp _homePath = RegExp(
  '(?<![\\w.<~/])~[\\w.-]*/(?=[^\\s\'"`])$_pathRun',
);

/// A Windows drive path, with either separator (`C:\\…`, `C:/…`); not a
/// scheme's `x://` and not a letter inside a word or a URL (`/a:/`).
final RegExp _windowsPath = RegExp(
  '(?<![\\w/\\\\.:-])[A-Za-z]:(?:\\\\|/(?!/))$_pathRun',
);

/// A UNC path: `\\server\share\…`.
final RegExp _uncPath = RegExp(
  '(?<![\\w\\\\])\\\\\\\\[^\\s\\\\\'"`]+\\\\$_pathRun',
);

/// Replacements that ran together (a known path, then the rest of it).
final RegExp _repeated = RegExp('(?:<path>)+');
