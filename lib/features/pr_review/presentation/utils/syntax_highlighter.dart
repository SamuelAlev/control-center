import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/shared/utils/diff_parser.dart';
import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' as hl;

/// Maps a file extension to a highlight.dart language id.
String? languageForExtension(String ext) {
  switch (ext) {
    case 'dart':
      return 'dart';
    case 'ts':
    case 'tsx':
      return 'typescript';
    case 'js':
    case 'jsx':
    case 'mjs':
    case 'cjs':
      return 'javascript';
    case 'py':
      return 'python';
    case 'rb':
      return 'ruby';
    case 'go':
      return 'go';
    case 'rs':
      return 'rust';
    case 'java':
      return 'java';
    case 'kt':
    case 'kts':
      return 'kotlin';
    case 'swift':
      return 'swift';
    case 'cs':
      return 'cs';
    case 'cpp':
    case 'cc':
    case 'cxx':
    case 'hpp':
    case 'hh':
      return 'cpp';
    case 'c':
    case 'h':
      return 'c';
    case 'json':
      return 'json';
    case 'yaml':
    case 'yml':
      return 'yaml';
    case 'toml':
      return 'toml';
    case 'xml':
    case 'svg':
      return 'xml';
    case 'html':
    case 'htm':
      return 'xml';
    case 'css':
      return 'css';
    case 'scss':
    case 'sass':
      return 'scss';
    case 'sh':
    case 'bash':
    case 'zsh':
      return 'bash';
    case 'sql':
      return 'sql';
    case 'md':
    case 'mdx':
      return 'markdown';
    case 'graphql':
    case 'gql':
      return 'graphql';
    case 'php':
      return 'php';
    case 'lua':
      return 'lua';
    case 'r':
      return 'r';
    default:
      return null;
  }
}

/// Color used as the base text color in diff content lines.
Color diffCodeColor(BuildContext context) =>
    (context.designSystem ?? DesignSystemTokens.light()).textPrimary;

/// Synchronously tokenizes a single line of [code] using `highlight.dart`,
/// returning [DiffToken]s coloured by [palette]. Exposed so widgets that
/// render small inline diffs (suggestions, hover previews) can match the PR
/// diff's syntax-highlighting without round-tripping through the isolate.
List<DiffToken> highlightLineTokens(
  String code,
  String? language,
  Map<String, int> palette,
) {
  if (language == null || code.isEmpty) {
    return [DiffToken(code, null)];
  }
  hl.Result result;
  try {
    result = hl.highlight.parse(code, language: language);
  } catch (_) {
    return [DiffToken(code, null)];
  }
  final tokens = <DiffToken>[];
  void walk(hl.Node node, int? inheritedColor) {
    final color = node.className != null
        ? (palette[node.className!] ?? inheritedColor)
        : inheritedColor;
    if (node.value != null) {
      tokens.add(DiffToken(node.value!, color));
    } else if (node.children != null) {
      for (final child in node.children!) {
        walk(child, color);
      }
    }
  }

  for (final node in result.nodes ?? const <hl.Node>[]) {
    walk(node, null);
  }
  if (tokens.isEmpty) {
    tokens.add(DiffToken(code, null));
  }
  return tokens;
}

/// ARGB-int syntax-highlighting palette used by both the full PR diff and the
/// inline suggestion mini-diff. Kept as plain ints so the isolate doesn't need
/// to import anything from `flutter/material`. Delegates to [DiffPalette].
Map<String, int> diffSyntaxPalette({required bool isDark}) =>
    DiffPalette.forBrightness(
      isDark ? Brightness.dark : Brightness.light,
    ).syntax;
