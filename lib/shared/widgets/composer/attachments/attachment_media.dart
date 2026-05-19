// What an attachment IS, for the two decisions that depend on it: which glyph
// its chip carries, and which renderer the preview pane reaches for.
//
// Classification is by MIME type when the platform reported one and by
// extension otherwise. A drop off the desktop usually reports nothing — macOS
// hands over a file URL and leaves the type to the receiver — so the extension
// path is the common case, not the fallback.
library;

import 'package:path/path.dart' as p;

/// The renderer family an attachment belongs to.
enum AttachmentMediaKind {
  /// A raster or vector picture.
  image,

  /// A movie container the platform player can open.
  video,

  /// A sound file.
  audio,

  /// A PDF document.
  pdf,

  /// Plain text, source code, or structured text (json/yaml/csv).
  text,

  /// Markdown, which is text but earns a rendered view.
  markdown,

  /// A compressed archive — listed, never opened.
  archive,

  /// A word processor / spreadsheet / slide deck document. Named separately
  /// from [other] because the preview says something more useful about it than
  /// "unknown file".
  document,

  /// Anything else.
  other,
}

/// MIME type for [name] inferred from its extension, or null when unknown.
///
/// Deliberately a short table rather than a full IANA map: it covers what a
/// person actually drags into a chat composer, and an unknown type degrades to
/// a generic attachment rather than to a wrong one.
String? mediaTypeForFileName(String name) {
  final ext = p.extension(name).toLowerCase();
  return switch (ext) {
    '.png' => 'image/png',
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.gif' => 'image/gif',
    '.webp' => 'image/webp',
    '.bmp' => 'image/bmp',
    '.heic' => 'image/heic',
    '.svg' => 'image/svg+xml',
    '.mp4' || '.m4v' => 'video/mp4',
    '.mov' => 'video/quicktime',
    '.webm' => 'video/webm',
    '.mkv' => 'video/x-matroska',
    '.avi' => 'video/x-msvideo',
    '.mp3' => 'audio/mpeg',
    '.m4a' => 'audio/mp4',
    '.wav' => 'audio/wav',
    '.ogg' || '.oga' => 'audio/ogg',
    '.flac' => 'audio/flac',
    '.aac' => 'audio/aac',
    '.pdf' => 'application/pdf',
    '.md' || '.markdown' => 'text/markdown',
    '.txt' || '.log' => 'text/plain',
    '.csv' => 'text/csv',
    '.json' => 'application/json',
    '.yaml' || '.yml' => 'application/yaml',
    '.xml' => 'application/xml',
    '.html' || '.htm' => 'text/html',
    '.zip' => 'application/zip',
    '.gz' || '.tgz' => 'application/gzip',
    '.tar' => 'application/x-tar',
    '.doc' || '.docx' => 'application/msword',
    '.xls' || '.xlsx' => 'application/vnd.ms-excel',
    '.ppt' || '.pptx' => 'application/vnd.ms-powerpoint',
    '.rtf' => 'application/rtf',
    _ => null,
  };
}

/// Extensions that hold source code — text, but worth syntax highlighting.
///
/// The list only has to be good enough to pick a RENDERER; the highlighter's
/// own language table (`shared/syntax/syntax_languages.dart`) decides the
/// grammar from the same filename afterwards, and an entry missing here shows
/// as plain monospaced text rather than as an unopenable file.
const Set<String> _codeExtensions = {
  '.dart',
  '.ts',
  '.tsx',
  '.js',
  '.jsx',
  '.mjs',
  '.cjs',
  '.py',
  '.rb',
  '.go',
  '.rs',
  '.java',
  '.kt',
  '.kts',
  '.swift',
  '.c',
  '.h',
  '.cc',
  '.cpp',
  '.hpp',
  '.cs',
  '.php',
  '.sh',
  '.bash',
  '.zsh',
  '.fish',
  '.sql',
  '.graphql',
  '.gql',
  '.proto',
  '.toml',
  '.ini',
  '.cfg',
  '.conf',
  '.env',
  '.gradle',
  '.lua',
  '.vim',
  '.el',
  '.ex',
  '.exs',
  '.erl',
  '.hs',
  '.ml',
  '.scala',
  '.clj',
  '.tf',
  '.dockerfile',
  '.makefile',
  '.cmake',
  '.scss',
  '.sass',
  '.less',
  '.css',
  '.vue',
  '.svelte',
  '.astro',
  '.arb',
  '.scm',
};

/// Filenames that are code with no extension at all.
const Set<String> _codeFilenames = {
  'Dockerfile',
  'Makefile',
  'Rakefile',
  'Gemfile',
  'Brewfile',
  'Procfile',
  'CMakeLists.txt',
};

/// Classifies an attachment from whatever is known about it.
///
/// [mimeType] wins when present and specific; [name] answers the (common) case
/// of a desktop drop that reported no type. Both null is [AttachmentMediaKind.other].
AttachmentMediaKind attachmentMediaKind({String? mimeType, String? name}) {
  final mime = (mimeType ?? '').toLowerCase();
  final effective = mime.isNotEmpty && mime != 'application/octet-stream'
      ? mime
      : (name == null ? '' : (mediaTypeForFileName(name) ?? ''));
  if (effective.startsWith('image/')) {
    return AttachmentMediaKind.image;
  }
  if (effective.startsWith('video/')) {
    return AttachmentMediaKind.video;
  }
  if (effective.startsWith('audio/')) {
    return AttachmentMediaKind.audio;
  }
  if (effective == 'application/pdf') {
    return AttachmentMediaKind.pdf;
  }
  if (effective == 'text/markdown') {
    return AttachmentMediaKind.markdown;
  }
  // The extension is consulted for text even when a MIME type was reported:
  // a `.dart` file dragged out of a code editor commonly arrives as
  // `text/plain`, and "plain text" and "highlight this as Dart" are the same
  // renderer with a different grammar.
  if (name != null) {
    final base = p.basename(name);
    final ext = p.extension(base).toLowerCase();
    if (ext == '.md' || ext == '.markdown') {
      return AttachmentMediaKind.markdown;
    }
    if (_codeExtensions.contains(ext) || _codeFilenames.contains(base)) {
      return AttachmentMediaKind.text;
    }
  }
  if (effective.startsWith('text/') ||
      effective == 'application/json' ||
      effective == 'application/yaml' ||
      effective == 'application/xml') {
    return AttachmentMediaKind.text;
  }
  if (effective == 'application/zip' ||
      effective == 'application/gzip' ||
      effective == 'application/x-tar') {
    return AttachmentMediaKind.archive;
  }
  if (effective.startsWith('application/msword') ||
      effective.startsWith('application/vnd.') ||
      effective == 'application/rtf') {
    return AttachmentMediaKind.document;
  }
  return AttachmentMediaKind.other;
}

/// A short, human-readable size for [bytes] (`1.4 MB`), or null when unknown.
///
/// Not localized on purpose: these are SI unit symbols, which are the same in
/// every language the app ships, and the number formatting follows the
/// ambient locale through [num.toStringAsFixed]'s ASCII output only because a
/// file size is read as a magnitude, not parsed.
String? formatAttachmentSize(int? bytes) {
  if (bytes == null || bytes < 0) {
    return null;
  }
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(bytes < 10 * 1024 ? 1 : 0)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
