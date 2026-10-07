/// A `claude setup-token` credential kept in one account's config dir.
///
/// The interactive login (`claude auth login`) hands out a short-lived access
/// token plus a ROTATING refresh token: every refresh mints a new one and
/// revokes the old. Two copies of that credential (the keychain item and the
/// mirrored `.credentials.json`, or the operator's own `~/.claude` and an
/// account seeded from it) cannot both survive — whichever refreshes first
/// signs the other out, which is what logged the operator out every morning.
///
/// A setup token has no refresh step at all. The CLI takes it from
/// `CLAUDE_CODE_OAUTH_TOKEN`, it lasts about a year, and nothing on disk
/// changes when a run uses it — so there is nothing to race. When an account
/// directory holds one it IS the account's credential, and the keychain mirror
/// is skipped.
///
/// It lives inside the account directory, beside the credential it replaces:
/// the directory is the account (removing it removes the token too), and the
/// sandbox already exposes that directory to the run.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// The file inside an account directory that holds the token.
const String claudeLongLivedTokenFileName = '.cc-long-lived-token.json';

/// The environment variable the CLI reads the token from.
const String claudeLongLivedTokenEnvKey = 'CLAUDE_CODE_OAUTH_TOKEN';

/// The shape `claude setup-token` prints: an OAuth token, URL-safe, no
/// whitespace. Strict on purpose — the value becomes an environment variable
/// on every run, and a pasted line with a stray newline or the CLI's
/// surrounding prose would authenticate nothing while looking configured.
final RegExp _tokenShape = RegExp(r'^sk-ant-oat01-[A-Za-z0-9_\-]{20,400}$');

/// Whether [token] looks like a `claude setup-token` token.
bool isWellFormedClaudeLongLivedToken(String token) =>
    _tokenShape.hasMatch(token);

/// The token file for [configDir].
File claudeLongLivedTokenFile(String configDir) =>
    File(p.join(configDir, claudeLongLivedTokenFileName));

Map<dynamic, dynamic>? _readEnvelope(String configDir) {
  if (configDir.isEmpty) {
    return null;
  }
  try {
    final file = claudeLongLivedTokenFile(configDir);
    if (!file.existsSync()) {
      return null;
    }
    final decoded = jsonDecode(file.readAsStringSync());
    return decoded is Map ? decoded : null;
  } on Object {
    return null;
  }
}

/// The token stored in [configDir], or null when there is none.
///
/// An unreadable or malformed file reads as absent, so the account falls back
/// to whatever else its directory holds rather than exporting garbage.
String? readClaudeLongLivedToken(String configDir) {
  final token = _readEnvelope(configDir)?['token'];
  return token is String && isWellFormedClaudeLongLivedToken(token)
      ? token
      : null;
}

/// When [configDir]'s token was saved, or null when there is none.
///
/// The CLI does not say when a setup token expires, so this is the only date
/// there is; Settings shows it so a year-old token is not a surprise.
DateTime? claudeLongLivedTokenSavedAt(String configDir) {
  if (readClaudeLongLivedToken(configDir) == null) {
    return null;
  }
  final at = _readEnvelope(configDir)?['saved_at'];
  return at is String ? DateTime.tryParse(at) : null;
}

/// Writes [token] into [configDir], replacing any previous one.
///
/// Write-then-rename so a crash never leaves a half-written token that reads
/// as absent and silently drops the account back to its old credential.
void writeClaudeLongLivedToken(
  String configDir,
  String token, {
  required DateTime at,
}) {
  final file = claudeLongLivedTokenFile(configDir);
  final tmp = File('${file.path}.tmp');
  tmp.writeAsStringSync(
    jsonEncode({'token': token, 'saved_at': at.toUtc().toIso8601String()}),
    flush: true,
  );
  tmp.renameSync(file.path);
}

/// Removes [configDir]'s token. A missing file is not an error.
void deleteClaudeLongLivedToken(String configDir) {
  final file = claudeLongLivedTokenFile(configDir);
  if (file.existsSync()) {
    file.deleteSync();
  }
}
