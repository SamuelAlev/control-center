import 'dart:convert';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:crypto/crypto.dart';

/// Verbs whose `text` is a key COMBINATION rather than content.
///
/// `ctrl+s` is precisely what the audit exists to record, and it is a name,
/// not something anybody types a secret into.
const Set<String> _keyComboVerbs = {'key', 'hold_key'};

/// How much serialized argument JSON one row may carry.
const int _maxArgsChars = 4096;

/// What [action] looks like once it is safe to persist.
///
/// `type`/`fill` (and take-over keystrokes) redact plaintext at this
/// chokepoint — length + hash keep "was something typed?" answerable without
/// storing the string. Hash is not a defence for short text. Summary is
/// redacted with the args (same text, next column).
({Map<String, dynamic> args, String summary}) rigAuditPayload(
  RigAction action,
) {
  final args = Map<String, dynamic>.of(action.toJson());
  var summary = action.summary;
  final text = args['text'];
  if (!_keyComboVerbs.contains(action.verb) &&
      text is String &&
      text.isNotEmpty) {
    args['text'] = {
      'textLength': text.length,
      'textSha256': sha256.convert(utf8.encode(text)).toString(),
    };
    summary = _redactQuoted(summary, text.length);
  }
  return (args: capRigAuditArgs(args, action.verb), summary: summary);
}

/// Replaces the quoted preview in [summary] with a length note.
///
/// Every summary that quotes anything quotes exactly the text just redacted
/// (`Typed "hunter2"`, `Filled #pw with "hunter2"`), so dropping what lies
/// between the first and the last quote keeps the part that carries the
/// audit — the verb, the selector — and loses the part that carries the
/// secret.
String _redactQuoted(String summary, int length) {
  final first = summary.indexOf('"');
  final last = summary.lastIndexOf('"');
  if (first < 0 || last <= first) {
    return summary;
  }
  return '${summary.substring(0, first)}$length '
      '${length == 1 ? 'character' : 'characters'} (hidden)'
      '${summary.substring(last + 1)}';
}

/// Caps one row's arguments. A `navigate` URL is caller-supplied and
/// unbounded, and a log row that costs a megabyte is a payload store rather
/// than an audit trail.
Map<String, dynamic> capRigAuditArgs(Map<String, dynamic> args, String verb) {
  final encoded = jsonEncode(args);
  if (encoded.length <= _maxArgsChars) {
    return args;
  }
  return {'action': verb, 'argsTruncated': true, 'argsChars': encoded.length};
}
