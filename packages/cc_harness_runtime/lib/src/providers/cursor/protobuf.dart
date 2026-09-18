import 'dart:convert';
import 'dart:typed_data';

/// Wire types used by the protobuf binary format.
abstract final class ProtoWire {
  /// Varint (int32/uint32/bool/enum).
  static const int varint = 0;

  /// Fixed 64-bit.
  static const int fixed64 = 1;

  /// Length-delimited (string/bytes/message/packed).
  static const int bytes = 2;

  /// Fixed 32-bit.
  static const int fixed32 = 5;
}

/// Encodes protobuf fields into a binary payload.
class ProtoWriter {
  final BytesBuilder _out = BytesBuilder(copy: false);

  /// Encodes a field tag.
  void tag(int field, int wire) => varint((field << 3) | wire);

  /// Encodes an unsigned varint.
  void varint(int value) {
    var n = value;
    while (n > 0x7f) {
      _out.addByte((n & 0x7f) | 0x80);
      n >>= 7;
    }
    _out.addByte(n);
  }

  /// Field [field] as a UTF-8 string.
  void string(int field, String value) {
    if (value.isEmpty) {
      return;
    }
    bytes(field, utf8.encode(value));
  }

  /// Field [field] as raw bytes.
  void bytes(int field, List<int> value) {
    tag(field, ProtoWire.bytes);
    varint(value.length);
    _out.add(value);
  }

  /// Field [field] as a nested message.
  void message(int field, List<int> value) => bytes(field, value);

  /// Field [field] as a bool (omitted when false).
  void boolean(int field, bool value) {
    if (!value) {
      return;
    }
    tag(field, ProtoWire.varint);
    varint(1);
  }

  /// Field [field] as an unsigned int (omitted when 0).
  void uint32(int field, int value) {
    if (value == 0) {
      return;
    }
    tag(field, ProtoWire.varint);
    varint(value);
  }

  /// Field [field] as a signed int32 (omitted when 0).
  void int32(int field, int value) {
    if (value == 0) {
      return;
    }
    tag(field, ProtoWire.varint);
    varint(value);
  }

  /// A protobuf map entry (`key` = field 1, `value` = field 2 as bytes).
  void mapStringBytes(int field, Map<String, List<int>> map) {
    map.forEach((key, value) {
      final entry = ProtoWriter()
        ..string(1, key)
        ..bytes(2, value);
      message(field, entry.take());
    });
  }

  /// The encoded payload.
  Uint8List take() => _out.takeBytes();
}

/// One decoded protobuf field.
class ProtoField {
  /// Creates a decoded field.
  const ProtoField(this.number, this.wire, this.varintValue, this.bytesValue);

  /// Field number.
  final int number;

  /// Wire type.
  final int wire;

  /// Varint payload, when [wire] is [ProtoWire.varint].
  final int varintValue;

  /// Bytes payload, when [wire] is [ProtoWire.bytes].
  final Uint8List bytesValue;

  /// UTF-8 string view of [bytesValue].
  String get asString => utf8.decode(bytesValue);

  /// Nested-message view of [bytesValue].
  ProtoReader get asMessage => ProtoReader(bytesValue);
}

/// Walks a protobuf payload, skipping unknown fields.
class ProtoReader {
  /// Creates a reader over [data].
  ProtoReader(List<int> data) : _data = data is Uint8List ? data : Uint8List.fromList(data);

  final Uint8List _data;
  int _offset = 0;

  /// Remaining unread bytes.
  bool get hasMore => _offset < _data.length;

  /// Reads the next field, or null at end-of-buffer / on a truncated field.
  ProtoField? next() {
    if (!hasMore) {
      return null;
    }
    final tag = _readVarint();
    if (tag == null) {
      return null;
    }
    final field = tag >> 3;
    final wire = tag & 7;
    switch (wire) {
      case ProtoWire.varint:
        final v = _readVarint();
        if (v == null) {
          return null;
        }
        return ProtoField(field, wire, v, Uint8List(0));
      case ProtoWire.fixed64:
        if (_offset + 8 > _data.length) {
          return null;
        }
        _offset += 8;
        return ProtoField(field, wire, 0, Uint8List(0));
      case ProtoWire.fixed32:
        if (_offset + 4 > _data.length) {
          return null;
        }
        _offset += 4;
        return ProtoField(field, wire, 0, Uint8List(0));
      case ProtoWire.bytes:
        final len = _readVarint();
        if (len == null || _offset + len > _data.length) {
          return null;
        }
        final slice = Uint8List.sublistView(_data, _offset, _offset + len);
        _offset += len;
        return ProtoField(field, wire, 0, slice);
      default:
        return null;
    }
  }

  /// Collects every field, grouped by number (repeated fields keep order).
  Map<int, List<ProtoField>> collect() {
    final out = <int, List<ProtoField>>{};
    while (true) {
      final field = next();
      if (field == null) {
        break;
      }
      (out[field.number] ??= []).add(field);
    }
    return out;
  }

  int? _readVarint() {
    var shift = 0;
    var result = 0;
    while (_offset < _data.length) {
      final b = _data[_offset++];
      result |= (b & 0x7f) << shift;
      if ((b & 0x80) == 0) {
        return result;
      }
      shift += 7;
      if (shift > 63) {
        return null;
      }
    }
    return null;
  }
}

/// First string of the named field, or empty.
String protoString(Map<int, List<ProtoField>> fields, int number) {
  final list = fields[number];
  if (list == null || list.isEmpty) {
    return '';
  }
  return list.first.asString;
}

/// First varint of the named field, or 0.
int protoVarint(Map<int, List<ProtoField>> fields, int number) {
  final list = fields[number];
  if (list == null || list.isEmpty) {
    return 0;
  }
  return list.first.varintValue;
}

/// First bytes of the named field, or empty.
Uint8List protoBytes(Map<int, List<ProtoField>> fields, int number) {
  final list = fields[number];
  if (list == null || list.isEmpty) {
    return Uint8List(0);
  }
  return list.first.bytesValue;
}

/// Decodes a protobuf `map<string, bytes>` stored as repeated entries.
Map<String, Uint8List> protoMapStringBytes(
  Map<int, List<ProtoField>> fields,
  int number,
) {
  final out = <String, Uint8List>{};
  for (final entry in fields[number] ?? const <ProtoField>[]) {
    final inner = entry.asMessage.collect();
    final key = protoString(inner, 1);
    if (key.isEmpty) {
      continue;
    }
    out[key] = protoBytes(inner, 2);
  }
  return out;
}
