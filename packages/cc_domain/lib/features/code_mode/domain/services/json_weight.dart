import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';

/// Decodes UTF-8 JSON bytes without building the whole text as a string
/// first.
final Converter<List<int>, Object?> utf8JsonDecoder = utf8.decoder.fuse(
  json.decoder,
);

/// What a JSON text holds, counted without decoding it, and what it takes on
/// the heap once decoded.
///
/// Decoding builds an object per value, so the bytes of a text say little
/// about its memory: one MiB of `[{},{},…]` takes about 82 MiB of heap, of
/// `[[[]]],…` about 31, of `1.5,…` about 8, of one ASCII string one, of one
/// string with a character past Latin-1 two. [weight] is an upper bound:
/// the bytes, plus a fixed cost per object, array, object member and other
/// value, each rounded up from what the VM was measured to take
/// (cc_infra's `json_weight_test.dart` holds every measured shape under
/// it).
final class JsonShape {
  /// Creates a shape of [bytes] UTF-8 bytes with these counts.
  const JsonShape({
    required this.bytes,
    required this.objects,
    required this.arrays,
    required this.members,
    required this.scalars,
  });

  /// Heap per decoded object beyond its text (measured about 245 for `{}`
  /// in an array).
  static const int objectCost = 320;

  /// Per array (measured about 73 for each of `[[[]]]`).
  static const int arrayCost = 96;

  /// Per object member: its key and its entry in the map.
  static const int memberCost = 64;

  /// Per string, number, `true`, `false` or `null` (measured about 66 for
  /// a short string unlike the others in an array).
  static const int scalarCost = 80;

  /// UTF-8 bytes of the text.
  final int bytes;

  /// Objects (`{…}`).
  final int objects;

  /// Arrays (`[…]`).
  final int arrays;

  /// Object members (key and value pairs), at any depth.
  final int members;

  /// Strings, numbers, booleans and nulls that are values, not keys.
  final int scalars;

  /// Every object, array, member and other value.
  int get items => objects + arrays + members + scalars;

  /// An upper bound on the heap the decoded text takes, in bytes. Decoded
  /// strings take at most two bytes per UTF-8 byte (a string with one
  /// character past Latin-1 is stored two bytes per character); measured,
  /// with the allocator's own overhead, up to about 2.03, so the bytes count
  /// 2.5 times.
  int get weight =>
      bytes * 5 ~/ 2 +
      objects * objectCost +
      arrays * arrayCost +
      members * memberCost +
      scalars * scalarCost;

  /// This shape without [part], one of its values.
  JsonShape without(JsonShape part) => JsonShape(
    bytes: bytes - part.bytes,
    objects: objects - part.objects,
    arrays: arrays - part.arrays,
    members: members - part.members,
    scalars: scalars - part.scalars,
  );
}

/// One JSON text scanned before it is decoded: its shape and, when it is an
/// object, where the top-level members the caller named lie and their
/// values' shapes.
final class JsonFrameScan {
  JsonFrameScan._(this.bytes, this.shape, this.depth, this._members);

  /// The text.
  final Uint8List bytes;

  /// The whole text.
  final JsonShape shape;

  /// How deep its containers nest: 0 for a scalar, 1 for `{}` or `[]`.
  final int depth;

  final Map<String, ({int start, int end, JsonShape shape})> _members;

  /// The shape of the top-level member [key]'s value, or null when there is
  /// none.
  JsonShape? shapeOf(String key) => _members[key]?.shape;

  /// The top-level member [key]'s value decoded on its own, or null when
  /// there is none or it is not JSON. For small values (`type`): it decodes
  /// only that value.
  Object? valueOf(String key) {
    final member = _members[key];
    if (member == null) {
      return null;
    }
    try {
      return utf8JsonDecoder.convert(
        Uint8List.sublistView(bytes, member.start, member.end),
      );
    } on FormatException {
      return null;
    }
  }

  /// The top-level member [key]'s value as its text, undecoded, or null
  /// when there is none.
  Uint8List? bytesOf(String key) {
    final member = _members[key];
    return member == null
        ? null
        : Uint8List.sublistView(bytes, member.start, member.end);
  }

  /// The text with the top-level member [key]'s value replaced by `{}`, or
  /// the text itself when there is no such member.
  Uint8List withEmptyObjectFor(String key) {
    final member = _members[key];
    if (member == null) {
      return bytes;
    }
    return Uint8List(bytes.length - (member.end - member.start) + 2)
      ..setRange(0, member.start, bytes)
      ..[member.start] = 0x7b
      ..[member.start + 1] = 0x7d
      ..setRange(
        member.start + 2,
        bytes.length - member.end + member.start + 2,
        bytes,
        member.end,
      );
  }
}

/// Scans [bytes], one JSON text, counting its values without building them.
///
/// It reads strings as strings: braces, brackets, commas and escaped quotes
/// inside one are text. It does not validate; a malformed text gives counts
/// that may be off, and decoding it afterwards fails as it would have.
///
/// Only the top-level members named in [keep] are kept (for
/// [JsonFrameScan.shapeOf] and the rest), so what the scan holds does not
/// grow with the text: an object of 700,000 keys keeps at most
/// `keep.length` entries. A key is compared by its bytes; one written
/// with an escape is decoded, compared and dropped.
JsonFrameScan scanJsonFrame(Uint8List bytes, {Set<String> keep = const {}}) {
  final wanted = [
    for (final name in keep) (name: name, bytes: utf8.encode(name)),
  ];
  var objects = 0;
  var arrays = 0;
  var members = 0;
  var scalars = 0;
  // One entry per open container: true for an object.
  final open = <bool>[];
  var depth = 0;
  var inString = false;
  var escaped = false;
  var inScalar = false;
  var keyNext = false;
  var stringIsKey = false;
  var stringStart = 0;
  var stringEscaped = false;

  final top = <String, ({int start, int end, JsonShape shape})>{};
  String? memberKey;
  var memberStart = -1;
  var at = (0, 0, 0, 0);

  void beginValue(int i) {
    if (open.length == 1 && open.last && memberKey != null && memberStart < 0) {
      memberStart = i;
      at = (objects, arrays, members, scalars);
    }
  }

  void endMember(int end) {
    final key = memberKey;
    if (key != null && memberStart >= 0) {
      var last = end;
      while (last > memberStart && _isSpace(bytes[last - 1])) {
        last--;
      }
      top[key] = (
        start: memberStart,
        end: last,
        shape: JsonShape(
          bytes: last - memberStart,
          objects: objects - at.$1,
          arrays: arrays - at.$2,
          members: members - at.$3,
          scalars: scalars - at.$4,
        ),
      );
    }
    memberKey = null;
    memberStart = -1;
  }

  for (var i = 0; i < bytes.length; i++) {
    final b = bytes[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (b == 0x5c) {
        escaped = true;
        stringEscaped = true;
      } else if (b == 0x22) {
        inString = false;
        if (stringIsKey && open.length == 1) {
          memberKey = wanted.isEmpty
              ? null
              : _wantedKey(bytes, stringStart + 1, i, stringEscaped, wanted);
        }
      }
      continue;
    }
    if (inScalar) {
      if (!_isSpace(b) && b != 0x2c && b != 0x5d && b != 0x7d && b != 0x3a) {
        continue;
      }
      inScalar = false;
    }
    switch (b) {
      case 0x20 || 0x0a || 0x0d || 0x09:
        break;
      case 0x22: // "
        inString = true;
        stringStart = i;
        stringEscaped = false;
        stringIsKey = open.isNotEmpty && open.last && keyNext;
        if (stringIsKey) {
          members++;
          keyNext = false;
        } else {
          beginValue(i);
          scalars++;
        }
      case 0x7b: // {
        beginValue(i);
        objects++;
        open.add(true);
        if (open.length > depth) {
          depth = open.length;
        }
        keyNext = true;
      case 0x5b: // [
        beginValue(i);
        arrays++;
        open.add(false);
        if (open.length > depth) {
          depth = open.length;
        }
        keyNext = false;
      case 0x7d || 0x5d: // } ]
        if (open.length == 1) {
          endMember(i);
        }
        if (open.isNotEmpty) {
          open.removeLast();
        }
        keyNext = false;
      case 0x2c: // ,
        if (open.length == 1) {
          endMember(i);
        }
        keyNext = open.isNotEmpty && open.last;
      case 0x3a: // :
        keyNext = false;
      default:
        beginValue(i);
        scalars++;
        inScalar = true;
    }
  }
  return JsonFrameScan._(
    bytes,
    JsonShape(
      bytes: bytes.length,
      objects: objects,
      arrays: arrays,
      members: members,
      scalars: scalars,
    ),
    depth,
    top,
  );
}

/// The name in [wanted] that the key between [start] and [end] (the bytes
/// inside its quotes) spells, or null.
String? _wantedKey(
  Uint8List bytes,
  int start,
  int end,
  bool escaped,
  List<({String name, Uint8List bytes})> wanted,
) {
  if (escaped) {
    try {
      final key = utf8JsonDecoder.convert(
        Uint8List.sublistView(bytes, start - 1, end + 1),
      );
      for (final w in wanted) {
        if (w.name == key) {
          return w.name;
        }
      }
    } on FormatException {
      return null;
    }
    return null;
  }
  outer:
  for (final w in wanted) {
    if (w.bytes.length != end - start) {
      continue;
    }
    for (var k = 0; k < w.bytes.length; k++) {
      if (bytes[start + k] != w.bytes[k]) {
        continue outer;
      }
    }
    return w.name;
  }
  return null;
}

bool _isSpace(int b) => b == 0x20 || b == 0x0a || b == 0x0d || b == 0x09;

/// What a script receives for a tool's text result: the JSON object or
/// array the text holds, decoded, when the text is at most twice
/// [CodeModeLimits.maxNestedResultBytes] and holds at most
/// [CodeModeLimits.maxNestedResultItems] values; otherwise the text. The
/// text is weighed before it is decoded, so a result decoded for a script
/// takes at most about 60 MiB, however its JSON is shaped.
Object? scriptValueOfText(String text) {
  final trimmed = text.trim();
  if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
    return text;
  }
  final bytes = utf8.encode(trimmed);
  if (bytes.length > 2 * CodeModeLimits.maxNestedResultBytes ||
      scanJsonFrame(bytes).shape.items > CodeModeLimits.maxNestedResultItems) {
    return text;
  }
  try {
    final parsed = utf8JsonDecoder.convert(bytes);
    if (parsed is Map || parsed is List) {
      return parsed;
    }
  } on FormatException {
    // Not JSON after all: the text is the value.
  }
  return text;
}

/// What a surface hands the script host for a tool's text result: a
/// [ScriptJsonText] when the text looks like a JSON object or array, the
/// text itself otherwise.
Object scriptResultOfText(String text) {
  final trimmed = text.trimLeft();
  return trimmed.startsWith('{') || trimmed.startsWith('[')
      ? ScriptJsonText(text)
      : text;
}

/// A tool's text result that may hold a JSON object or array, kept as the
/// text until it is encoded for the script.
///
/// It is decoded only inside `jsonEncode`, which calls [toJson]: the
/// decoded value lives for that one synchronous encode and no longer, so
/// however many calls settle together at most one decoded result is alive
/// at a time per isolate.
final class ScriptJsonText {
  /// Wraps [text].
  const ScriptJsonText(this.text);

  /// The tool's text.
  final String text;

  /// What the script receives ([scriptValueOfText]): the decoded object or
  /// array, or the text when it is not JSON or is past the limits.
  Object? toJson() => scriptValueOfText(text);

  @override
  bool operator ==(Object other) =>
      other is ScriptJsonText && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'ScriptJsonText(${text.length} chars)';
}
