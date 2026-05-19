/// Content-derived integrity hash for hashline edit anchoring.
///
/// A hashline section header carries a short fingerprint of the *whole file*
/// content. Any read of byte-identical content mints the same fingerprint, so
/// a follow-up edit anchored at any line validates whenever the live file
/// still hashes to it. The fingerprint is deliberately tiny (16 bits, 4 hex
/// chars): it is an integrity tripwire, not a cryptographic digest. A
/// collision merely degrades to a re-read prompt, never a silent wrong edit,
/// because the recovery path re-validates against the cached snapshot text.
///
/// Pure Dart with no external dependencies: the hash is FNV-1a over the UTF-8
/// bytes of the normalized text, folded to 16 bits.
library;

import 'dart:convert';

/// The number of lowercase hex characters in a content hash (16 bits).
const int contentHashLength = 4;

/// Normalizes text before hashing or applying edits.
///
/// Strips a leading UTF-8 byte-order mark (`U+FEFF`) and converts every CRLF
/// (`\r\n`) and lone CR (`\r`) line ending to LF (`\n`). The result is the
/// canonical shape every other part of the subsystem operates on, so a file
/// that differs only in BOM presence or line-ending style hashes identically
/// and edits land on the same logical lines.
String normalizeContent(String input) {
  var text = input;
  if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
    text = text.substring(1);
  }
  // Normalize CRLF first, then any remaining lone CR, to LF.
  return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}

/// FNV-1a 32-bit offset basis.
const int _fnvOffsetBasis = 0x811c9dc5;

/// FNV-1a 32-bit prime.
const int _fnvPrime = 0x01000193;

/// Computes the 4-hex content hash of [input].
///
/// The input is first run through [normalizeContent] (BOM strip + LF
/// normalization), then hashed with FNV-1a over its UTF-8 bytes. The 32-bit
/// FNV result is folded to 16 bits (`h ^ (h >> 16)`) and rendered as four
/// lowercase hex characters. Byte-identical normalized content always yields
/// the same tag.
String computeContentHash(String input) {
  final normalized = normalizeContent(input);
  final bytes = utf8.encode(normalized);
  var hash = _fnvOffsetBasis;
  for (final byte in bytes) {
    hash ^= byte;
    // Keep the running hash inside 32 bits; Dart ints are 64-bit so mask.
    hash = (hash * _fnvPrime) & 0xFFFFFFFF;
  }
  final folded = (hash ^ (hash >> 16)) & 0xFFFF;
  return folded.toRadixString(16).padLeft(contentHashLength, '0');
}
