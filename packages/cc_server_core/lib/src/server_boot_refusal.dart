import 'dart:io';

import 'package:cc_infra/cc_infra.dart' show redactSecrets;
import 'package:cc_infra/cc_paths.dart'
    show PrivateDirectoryException, ensurePrivateDirectory, tightenToOwnerOnly;
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/schema/converged_database.dart';
import 'package:cc_persistence/database/utils/storage_errors.dart';
import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:path/path.dart' as p;

/// A flag or variable name as a refusal quotes it: every character outside
/// printable ASCII (a control, an invisible or a non-ASCII character, and a
/// space at either end) shown as its code point, `\u{200B}`, so a name that
/// only looks like a real one reads differently from it; at most [max]
/// characters of [name], ended with an ellipsis when it is longer. Secrets
/// are redacted first ([redactSecrets]), so a cut never leaves part of a
/// token the redaction would have found whole.
String printableName(String name, {int max = 80}) {
  final runes = redactSecrets(name).runes.toList();
  final kept = runes.length > max ? runes.sublist(0, max - 1) : runes;
  final out = StringBuffer();
  for (var i = 0; i < kept.length; i++) {
    final rune = kept[i];
    final end = i == 0 || i == kept.length - 1;
    if (rune > 0x20 && rune < 0x7F || rune == 0x20 && !end) {
      out.writeCharCode(rune);
    } else {
      out.write('\\u{${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}}');
    }
  }
  if (kept.length < runes.length) {
    out.write('\u2026');
  }
  return out.toString();
}

/// The characters that do not print on their own, as the inside of a
/// regular expression character class (`unicode: true`): controls
/// (`\p{Cc}`), format characters (`\p{Cf}`: zero-width spaces and joiners,
/// the soft hyphen, bidirectional marks, U+180E), combining marks
/// (`\p{M}`: accents, the combining grapheme joiner, variation selectors
/// including the Mongolian ones, the Khmer inherent vowels), line and
/// paragraph separators, every space but the ASCII one, and the blank
/// fillers (Hangul fillers, the Braille blank U+2800). A refusal says when
/// a name it quotes holds one ([holdsUnprintable]).
const String unprintableCharacters =
    r'\p{Cc}\p{Cf}\p{M}\p{Zl}\p{Zp}\u00A0\u1680\u2000-\u200A\u202F\u205F'
    r'\u3000\u115F\u1160\u2800\u3164\uFFA0\u180B-\u180F\uFE00-\uFE0F'
    r'\u{E0100}-\u{E01EF}';

/// Whether [name] holds a character that does not print on its own
/// ([unprintableCharacters]).
bool holdsUnprintable(String name) => _unprintable.hasMatch(name);

final RegExp _unprintable = RegExp('[$unprintableCharacters]', unicode: true);

/// A value or a path as a refusal quotes it: a control, format, separator,
/// non-ASCII space or blank filler character, and half of a surrogate pair,
/// shown as its code point (`\u{1B}`), so nothing an argument, a variable
/// or a file name carries reaches the terminal raw; letters, accents and
/// symbols outside ASCII are kept, so a path still reads as that path. At
/// most [max] characters of [text], ended with an ellipsis when longer.
///
/// In that order: secrets redacted ([redactSecrets]), then made printable
/// and cut. Cut first, a token across the cut showed its head (`ghp_` and
/// up to 19 characters at a path's 1,024th), which the redaction no longer
/// recognised. Every refusal and start line quotes operator text through
/// it.
String printableText(String text, {int max = 200}) =>
    _escaped(redactSecrets(text), max);

/// [printableText] without the redaction, for a command's own output that
/// has to reach the operator whole: the deep link `pair` prints, which
/// carries the pairing key it made.
String printableUnredacted(String text, {int max = 200}) => _escaped(text, max);

String _escaped(String text, int max) {
  final runes = text.runes.toList();
  final kept = runes.length > max ? runes.sublist(0, max - 1) : runes;
  final out = StringBuffer();
  for (final rune in kept) {
    final char = String.fromCharCode(rune);
    if (rune >= 0xD800 && rune <= 0xDFFF || _raw.hasMatch(char)) {
      out.write('\\u{${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}}');
    } else {
      out.write(char);
    }
  }
  if (kept.length < runes.length) {
    out.write('\u2026');
  }
  return out.toString();
}

/// What [printableText] escapes: [unprintableCharacters] but the combining
/// marks, which a path written decomposed (`cafe\u0301`) needs to read.
final RegExp _raw = RegExp(
  r'[\p{Cc}\p{Cf}\p{Zl}\p{Zp}\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000'
  r'\u115F\u1160\u2800\u3164\uFFA0]',
  unicode: true,
);

/// [message] as it may reach a terminal: every character [printableText]
/// escapes is escaped but a line break, which some messages hold on
/// purpose. The last pass over every refusal line the server binaries
/// print, after each value in it was already quoted with [printableText].
String terminalText(String message) => message
    .split('\n')
    .map((line) => _escaped(line, line.runes.length + 1))
    .join('\n');

/// [message] as a line the server binaries print outside their logger (a
/// refusal, the line an error before ready ends the process with, a
/// command's output): secrets redacted first ([redactSecrets]), then made
/// printable ([terminalText]). Redacting first keeps an escape from
/// splitting a token the redaction would have found.
String terminalLine(String message) => terminalText(redactSecrets(message));

/// [error] as such a line quotes it ([printableText]: redacted, then
/// printable, at most [max] characters).
String printableError(Object error, {int max = 300}) =>
    printableText('$error', max: max);

/// The first line a boot prints, naming the data directory [dataDir]
/// redacted, then printable ([printableText]), whatever the operator
/// passed. The logger redacts the whole line again.
String bootingLine(String dataDir) =>
    'cc_server: booting (data: ${_printablePath(dataDir)})\u2026';

/// The line a boot prints once the server listens on [host]:[port], with
/// the data directory [dataDir] as [bootingLine] shows it and its
/// [workspaces] count.
String readyLine({
  required String host,
  required int port,
  required String dataDir,
  required int workspaces,
}) =>
    'cc_server ready on ${printableText(host, max: 256)}:$port '
    '(data: ${_printablePath(dataDir)}, workspaces: $workspaces)';

String _printablePath(String path) => printableText(path, max: 1024);

/// [name] as a refusal quotes it ([printableName]), followed, when it holds
/// a character that does not print ([holdsUnprintable]), by a note that
/// says so.
String quotedName(String name) => holdsUnprintable(name)
    ? '${printableName(name)} (a name holding a character that does not '
          'print, shown as its code point)'
    : printableName(name);

/// A reason the server refuses to start that the operator has to resolve.
///
/// Not a crash: the server binaries print [message] and exit with status 78
/// (`EX_CONFIG`), the same way an exported provider secret ends the boot.
abstract base class ServerBootRefusal implements Exception {
  /// Creates a refusal.
  const ServerBootRefusal();

  /// What is wrong and what to do about it, for the operator's terminal.
  String get message;

  @override
  String toString() => message;
}

/// The data directory is readable by accounts other than the server's own and
/// could not be restricted.
final class DataDirNotPrivate extends ServerBootRefusal {
  /// Creates the refusal for the [cause] reported by the mode check.
  const DataDirNotPrivate(this.cause);

  /// The directory and the mode it still has.
  final PrivateDirectoryException cause;

  @override
  String get message =>
      'cc_server: cannot start \u2014 the data directory '
      '${printableText(cause.path, max: 1024)} is mode '
      '${cause.octalMode} and could not be restricted to its owner (0700). It '
      'holds the server identity, the secrets file and every database, so '
      'other accounts on this host must not be able to read it. Make the '
      'account that runs cc_server its owner (chown) and run '
      '`chmod 700 ${printableText(cause.path, max: 1024)}`, or pass a '
      'different --data-dir.';
}

/// A native library the server needs is missing from its bundle (the code
/// mode runner among them). Natives ship inside the bundle and there is no
/// degraded mode, so the server ends with one line naming each missing
/// library and where it was searched.
final class NativeLibrariesMissing extends ServerBootRefusal {
  /// Creates the refusal for [missing] (each says what it is and where it
  /// was searched), looked for also in [searched] and the server bundle.
  const NativeLibrariesMissing(this.missing, {required this.searched});

  /// What is missing, one entry per library.
  final List<String> missing;

  /// The places looked in besides each library's own candidates.
  final List<String> searched;

  @override
  String get message {
    String oneLine(Iterable<String> parts, String separator) => parts
        .map(
          (part) =>
              printableText(part.replaceAll(RegExp(r'\s+'), ' '), max: 1024),
        )
        .join(separator);
    return 'cc_server: cannot start \u2014 required native libraries are missing: '
        '${oneLine(missing, '; ')}. Looked in ${oneLine(searched, ', ')} and '
        'the server bundle. Stage them with scripts/natives/build_natives.sh '
        'and rebuild the server with scripts/build_server.sh (`dart build '
        'cli` bundles build/natives into <bundle>/lib/ but not media/ into '
        '<bundle>/bin/media/), or drop them into the data dir. Refusing to '
        'boot with a degraded feature set.';
  }
}

/// Secures [dataDir] before anything in it is opened.
///
/// Creates it `0700`, or tightens an existing one to `0700`, and throws
/// [DataDirNotPrivate] when it still is not owner-only. Then tightens to `0600`
/// the secret-bearing files that sit directly in it (`global.db` with its WAL
/// and shared-memory files, `server_identity.json`, `secrets.json`) and to
/// `0700` each workspace directory (a subdirectory holding a `workspace.db`).
/// Files are created under the umask by SQLite, so this pass is what keeps
/// an install made before the directory was private from staying readable.
///
/// POSIX only: on Windows the directory is created and secrecy rests on the
/// ACL it inherits, as there are no mode bits to check.
///
/// A data directory that cannot be created, is not a directory or cannot
/// be listed is refused too ([DataDirUnusable]).
void secureDataDirectory(String dataDir) {
  try {
    ensurePrivateDirectory(dataDir);
  } on PrivateDirectoryException catch (e) {
    throw DataDirNotPrivate(e);
  } on FileSystemException catch (e) {
    throw DataDirUnusable(dataDir, e);
  }
  if (Platform.isWindows) {
    return;
  }
  try {
    for (final name in secretFileNames) {
      tightenToOwnerOnly(p.join(dataDir, name));
    }
    for (final entry in Directory(dataDir).listSync(followLinks: false)) {
      if (entry is Directory &&
          File(p.join(entry.path, 'workspace.db')).existsSync()) {
        tightenToOwnerOnly(entry.path);
      }
    }
  } on FileSystemException catch (e) {
    throw DataDirUnusable(dataDir, e);
  }
}

/// Creates the data directory [dataDir] for a command that writes into it
/// (`pair`, `connect`), refusing ([DataDirUnusable]) one that cannot be
/// created or is not a directory.
void createDataDirectory(String dataDir) {
  try {
    Directory(dataDir).createSync(recursive: true);
  } on FileSystemException catch (e) {
    throw DataDirUnusable(dataDir, e);
  }
}

/// The data directory cannot be created or used: a regular file has its
/// name, a parent cannot be written, or it cannot be listed.
final class DataDirUnusable extends ServerBootRefusal {
  /// Creates the refusal for [path], which failed with [cause].
  const DataDirUnusable(this.path, this.cause);

  /// The data directory given.
  final String path;

  /// What the file system reported.
  final FileSystemException cause;

  @override
  String get message {
    final reason = cause.osError?.message ?? cause.message;
    return 'cc_server: cannot start \u2014 the data directory '
        '${printableText(path, max: 1024)} cannot be used '
        '(${printableText(reason, max: 300)}). Pass a --data-dir that is a '
        'directory, or a path where this account can create one.';
  }
}

/// The secret-bearing files kept directly in the data directory.
const List<String> secretFileNames = [
  'global.db',
  'global.db-wal',
  'global.db-shm',
  'server_identity.json',
  'secrets.json',
];

/// The server-global database (`global.db`) cannot be served.
///
/// Everything the server does starts from this file (the workspace
/// registry, paired devices, the owner, the pre-auth routes), and unlike a
/// workspace it has no read-only mode: a server that ran on top of it would
/// spread the damage into every later snapshot, or rewrite a newer build's
/// file with an older schema. So the boot stops and tells the operator which
/// of the three it is.
sealed class GlobalDatabaseUnusable extends ServerBootRefusal {
  /// Creates the refusal for the file at [path].
  const GlobalDatabaseUnusable(this.path);

  /// The `global.db` the server tried to open.
  final String path;
}

/// `global.db` failed SQLite's integrity check, or is not readable as a
/// database at all.
final class GlobalDatabaseDamaged extends GlobalDatabaseUnusable {
  /// Creates the refusal with SQLite's [finding].
  const GlobalDatabaseDamaged(super.path, this.finding);

  /// What SQLite reported.
  final String finding;

  @override
  String get message =>
      'cc_server: cannot start \u2014 ${printableText(path, max: 1024)} is '
      'damaged (${printableText(finding, max: 300)}). Stop every '
      'process using this data directory and restore global.db from a '
      'snapshot (the newest copy in its backups directory, or a pre_upgrade/ '
      'copy beside it), then start the server again.';
}

/// `global.db` was written by a newer server build than this one.
final class GlobalDatabaseNewer extends GlobalDatabaseUnusable {
  /// Creates the refusal for the two schema versions.
  const GlobalDatabaseNewer(super.path, this.fileVersion, this.binaryVersion);

  /// The schema version stamped on the file.
  final int fileVersion;

  /// The schema version this build declares.
  final int binaryVersion;

  @override
  String get message =>
      'cc_server: cannot start \u2014 ${printableText(path, max: 1024)} is at '
      'schema v$fileVersion and this '
      'build knows only v$binaryVersion. Run the newer server build that '
      'wrote it; this one will not downgrade the file.';
}

/// `global.db` is an SQLite file this server did not write as its global
/// database.
final class GlobalDatabaseForeign extends GlobalDatabaseUnusable {
  /// Creates the refusal for the [applicationId] found in the file.
  const GlobalDatabaseForeign(super.path, this.applicationId);

  /// The `application_id` the file carries.
  final int applicationId;

  @override
  String get message =>
      'cc_server: cannot start \u2014 ${printableText(path, max: 1024)} is not '
      'a Control Center global '
      'database (application id $applicationId). Move it aside, or pass the '
      '--data-dir that holds this install.';
}

/// Opens [db] (the global database at [path]) now, so a file the server
/// cannot serve stops the boot with a [GlobalDatabaseUnusable] instead of
/// failing the first request that reaches it.
Future<void> openGlobalDatabaseOrRefuse(GlobalDatabase db, String path) async {
  try {
    await db.customSelect('SELECT 1').get();
  } on Object catch (e) {
    // The file opens in drift's background isolate, which hands the open
    // failure back wrapped, sometimes more than once.
    var cause = e;
    for (var depth = 0; depth < 8; depth++) {
      cause = switch (cause) {
        DriftRemoteException(:final remoteCause) => remoteCause,
        DriftWrappedException(:final Object cause) => cause,
        _ => cause,
      };
    }
    throw switch (cause) {
      DatabaseDamagedException() => GlobalDatabaseDamaged(path, cause.finding),
      DatabaseNewerThanBinaryException() => GlobalDatabaseNewer(
        path,
        cause.fileVersion,
        cause.binaryVersion,
      ),
      ForeignDatabaseFileException() => GlobalDatabaseForeign(
        path,
        cause.applicationId,
      ),
      _ when storageFailureOf(cause) == StorageFailure.damaged =>
        GlobalDatabaseDamaged(path, describeStorageError(cause) ?? '$cause'),
      _ => e,
    };
  }
}
