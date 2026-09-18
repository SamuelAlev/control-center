/// Builds the sanitized argument snapshot stored on a `user_activity` row.
///
/// The trail used to keep only a single conventional id (`ticket_id`,
/// `path`, …), so `rig.destroy` said nothing about which machine or which
/// space and `workspace_settings.set` said nothing about which key. This
/// walks the call args (and a few contextual result fields) and keeps
/// every primitive that is useful to an investigation, dropping secrets
/// and blobs.
library;

/// Keys that name a credential — stored as `[REDACTED]` so the trail
/// records that a secret moved, not what it was.
const Set<String> kAuditRedactedKeys = {
  'token',
  'access_token',
  'refresh_token',
  'api_key',
  'apikey',
  'password',
  'secret',
  'private_key',
  'client_secret',
  'credential',
  'authorization',
  'bearer',
  'psk',
  'pairing_key',
};

/// Keys that name a blob (base64 PTY bytes, file bodies). Omitted
/// entirely — they are not accountability, they are noise.
const Set<String> kAuditOmittedKeys = {
  'data',
  'bytes',
  'payload',
  'image',
  'content',
};

/// Result fields that name the thing acted on (or where) rather than the
/// mutation's return payload. Merged in only when the args did not already
/// carry the same key.
const Set<String> kAuditResultContextKeys = {
  'conversation_id',
  'space_id',
  'command',
  'surface',
  'backend',
  'name',
  'title',
  'reason',
};

const int _maxValueChars = 200;
const int _maxEntries = 24;

/// Sanitized `{key: value}` snapshot of [args] plus contextual [result]
/// fields, or null when nothing worth recording survived.
Map<String, Object?>? auditDetailsOf({
  required Map<String, dynamic> args,
  Map<String, dynamic>? result,
}) {
  final out = <String, Object?>{};
  void take(String key, Object? value, {required bool redactSecrets}) {
    if (out.length >= _maxEntries) {
      return;
    }
    if (key == 'workspace_id' ||
        key == 'sent' ||
        key == 'ok' ||
        kAuditOmittedKeys.contains(key.toLowerCase())) {
      return;
    }
    if (redactSecrets && _isSecretKey(key)) {
      out[key] = '[REDACTED]';
      return;
    }
    final sanitized = _sanitizeValue(value);
    if (sanitized == null && value != null) {
      return;
    }
    out[key] = sanitized;
  }

  for (final entry in args.entries) {
    take(entry.key, entry.value, redactSecrets: true);
  }
  if (result != null) {
    for (final key in kAuditResultContextKeys) {
      if (out.containsKey(key) || !result.containsKey(key)) {
        continue;
      }
      take(key, result[key], redactSecrets: false);
    }
  }
  return out.isEmpty ? null : out;
}

bool _isSecretKey(String key) {
  final k = key.toLowerCase().replaceAll('-', '_');
  if (kAuditRedactedKeys.contains(k)) {
    return true;
  }
  // `key` itself is a settings name, not a credential.
  return k.endsWith('_token') ||
      k.endsWith('_secret') ||
      k.endsWith('_password') ||
      (k.endsWith('_key') && k != 'key');
}

Object? _sanitizeValue(Object? value) {
  if (value == null || value is bool || value is num) {
    return value;
  }
  if (value is String) {
    if (value.length <= _maxValueChars) {
      return value;
    }
    return '${value.substring(0, _maxValueChars)}…';
  }
  if (value is List) {
    if (value.length > 8) {
      return '[${value.length} items]';
    }
    final items = <Object?>[];
    for (final item in value) {
      final sanitized = _sanitizeValue(item);
      if (sanitized == null && item != null) {
        return '[${value.length} items]';
      }
      items.add(sanitized);
    }
    return items;
  }
  if (value is Map) {
    if (value.length > 8) {
      return '{${value.length} keys}';
    }
    final out = <String, Object?>{};
    for (final entry in value.entries) {
      final sanitized = _sanitizeValue(entry.value);
      if (sanitized == null && entry.value != null) {
        continue;
      }
      out['${entry.key}'] = sanitized;
    }
    return out;
  }
  return null;
}
