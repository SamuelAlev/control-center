part of 'transcript_segment_row.dart';

// Plain-text helpers for a row's one-line summary and expanded body.

/// Everything below the first line, or null when there is nothing.
String? _afterFirstLine(String content) {
  final i = content.trim().indexOf('\n');
  if (i == -1) {
    return null;
  }
  final rest = content.trim().substring(i + 1).trim();
  return rest.isEmpty ? null : rest;
}

String? _firstLine(String content) {
  if (content.isEmpty) {
    return null;
  }
  final i = content.indexOf('\n');
  final line = (i == -1 ? content : content.substring(0, i)).trim();
  return line.isEmpty ? null : line;
}

String _formatDuration(Duration d) {
  if (d.inMilliseconds < 1000) {
    return '<1s';
  }
  if (d.inSeconds < 60) {
    return '${d.inSeconds}s';
  }
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return s == 0 ? '${m}m' : '${m}m ${s}s';
}
