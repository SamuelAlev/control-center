/// Block plugins for AI chat constructs: `<thinking>` reasoning spans,
/// `<artifact>` blocks and `<tool_call>` invocations. Ports of the
/// flutter_smooth_markdown plugins onto the cc_markdown plugin API.
///
/// These ship in the package (they are engine-agnostic) with neutral default
/// builders; apps override the rendering via the builder registry.
library;

import 'package:cc_markdown/src/plugins/ai/ai_nodes.dart';
import 'package:cc_markdown/src/plugins/plugin.dart';

/// Parses `<thinking>…</thinking>`, `<think>…</think>` and
/// `<|thinking|>…<|/thinking|>` blocks into [CcThinkingNode]s.
final class CcThinkingPlugin extends CcBlockPlugin {
  /// Creates a [CcThinkingPlugin].
  const CcThinkingPlugin();

  static final RegExp _open = RegExp(
    r'^\s*(?:<(thinking|think)>|<\|thinking\|>)\s*$',
  );

  @override
  String get id => 'thinking';

  @override
  int get priority => 10;

  @override
  bool canParse(String line, List<String> lines, int index) =>
      _open.hasMatch(line);

  @override
  CcBlockParseResult? parse(List<String> lines, int startIndex) {
    final open = _open.firstMatch(lines[startIndex]);
    if (open == null) {
      return null;
    }
    final tag = open.group(1);
    final close = tag == null
        ? RegExp(r'^\s*<\|/thinking\|>\s*$')
        : RegExp('^\\s*</$tag>\\s*\$');
    final content = <String>[];
    for (var i = startIndex + 1; i < lines.length; i++) {
      if (close.hasMatch(lines[i])) {
        return CcBlockParseResult(
          CcThinkingNode(content: content.join('\n').trim()),
          i - startIndex + 1,
        );
      }
      content.add(lines[i]);
    }
    // Unclosed (still streaming): consume to the end, render as thinking.
    return CcBlockParseResult(
      CcThinkingNode(content: content.join('\n').trim(), isCollapsed: false),
      lines.length - startIndex,
    );
  }
}

/// Parses `artifact` tag blocks (with `identifier`/`type`/`title`/`language`
/// attributes) into [CcArtifactNode]s.
final class CcArtifactPlugin extends CcBlockPlugin {
  /// Creates a [CcArtifactPlugin].
  const CcArtifactPlugin();

  static final RegExp _open = RegExp(r'^\s*<artifact\b([^>]*)>\s*$');
  static final RegExp _close = RegExp(r'^\s*</artifact>\s*$');
  static final RegExp _attr = RegExp('([a-zA-Z_]+)="([^"]*)"');

  @override
  String get id => 'artifact';

  @override
  int get priority => 10;

  @override
  bool canParse(String line, List<String> lines, int index) =>
      _open.hasMatch(line);

  @override
  CcBlockParseResult? parse(List<String> lines, int startIndex) {
    final open = _open.firstMatch(lines[startIndex]);
    if (open == null) {
      return null;
    }
    final attrs = <String, String>{
      for (final m in _attr.allMatches(open.group(1)!))
        m.group(1)!: m.group(2)!,
    };
    final content = <String>[];
    var consumed = lines.length - startIndex;
    for (var i = startIndex + 1; i < lines.length; i++) {
      if (_close.hasMatch(lines[i])) {
        consumed = i - startIndex + 1;
        break;
      }
      content.add(lines[i]);
    }
    return CcBlockParseResult(
      CcArtifactNode(
        identifier: attrs['identifier'] ?? '',
        artifactType: attrs['type'] ?? 'text',
        content: content.join('\n'),
        title: attrs['title'],
        language: attrs['language'],
      ),
      consumed,
    );
  }
}

/// Parses `<tool_call name="…" id="…">…</tool_call>` blocks into
/// [CcToolCallNode]s. The body may carry `<arguments>`, `<result>` and
/// `<error>` sections.
final class CcToolCallPlugin extends CcBlockPlugin {
  /// Creates a [CcToolCallPlugin].
  const CcToolCallPlugin();

  static final RegExp _open = RegExp(r'^\s*<tool_call\b([^>]*)>\s*$');
  static final RegExp _close = RegExp(r'^\s*</tool_call>\s*$');
  static final RegExp _attr = RegExp('([a-zA-Z_]+)="([^"]*)"');
  static final RegExp _section = RegExp(
    r'<(arguments|result|error)>([\s\S]*?)</\1>',
  );

  @override
  String get id => 'tool_call';

  @override
  int get priority => 10;

  @override
  bool canParse(String line, List<String> lines, int index) =>
      _open.hasMatch(line);

  @override
  CcBlockParseResult? parse(List<String> lines, int startIndex) {
    final open = _open.firstMatch(lines[startIndex]);
    if (open == null) {
      return null;
    }
    final attrs = <String, String>{
      for (final m in _attr.allMatches(open.group(1)!))
        m.group(1)!: m.group(2)!,
    };
    final body = <String>[];
    var consumed = lines.length - startIndex;
    for (var i = startIndex + 1; i < lines.length; i++) {
      if (_close.hasMatch(lines[i])) {
        consumed = i - startIndex + 1;
        break;
      }
      body.add(lines[i]);
    }
    final joined = body.join('\n');
    String? section(String name) {
      for (final m in _section.allMatches(joined)) {
        if (m.group(1) == name) {
          return m.group(2)!.trim();
        }
      }
      return null;
    }

    return CcBlockParseResult(
      CcToolCallNode(
        toolName: attrs['name'] ?? 'tool',
        toolId: attrs['id'],
        arguments: section('arguments'),
        result: section('result'),
        errorMessage: section('error'),
      ),
      consumed,
    );
  }
}
