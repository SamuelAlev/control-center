import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// gen-l10n invents an extra method argument when a plural/select form body
/// is a bare suffix (`other{s}`) or an undeclared `{s}` placeholder
/// (`other{{s}}` in the ARB). That is how `agentCount` became
/// `(int count, int plural, Object s)` and broke the build.
///
/// Write a full `{count, plural, =1{1 agent} other{{count} agents}}` message
/// instead of concatenating `{count} agent{plural, plural, =1{} other{s}}`.
void main() {
  final root = _repoRoot();
  final arbDirs = [
    Directory('${root.path}/lib/l10n'),
    Directory('${root.path}/apps/cc_remote/lib/l10n'),
  ];

  test('ARB plurals do not invent extra gen-l10n placeholders', () {
    const suffixTokens = {'s', 'es', 'en', 'er', 'e', 'i'};
    final suffixPlaceholder = RegExp(
      r'^\{(' + suffixTokens.join('|') + r')\}$',
    );
    final offenders = <String>[];

    for (final dir in arbDirs) {
      for (final file in dir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.arb')) continue;
        final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final rel = file.path.substring(root.path.length + 1);
        for (final entry in data.entries) {
          final key = entry.key;
          final value = entry.value;
          if (key.startsWith('@') || value is! String) continue;
          for (final block in _icuBlocks(value)) {
            if (block.selector == 'plural') {
              offenders.add(
                '$rel $key: ICU selector is named "plural" — that is the '
                'suffix-append pattern; use the count placeholder as the '
                'plural selector',
              );
            }
            for (final form in _icuForms(block.inner)) {
              final body = form.body.trim();
              if (suffixTokens.contains(body) ||
                  suffixPlaceholder.hasMatch(body)) {
                offenders.add(
                  '$rel $key: ${form.name}{$body} is a suffix form; '
                  'gen-l10n treats `{s}` as a placeholder named s',
                );
              }
            }
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('generated l10n methods do not have unused parameters', () {
    final files = [
      File('${root.path}/lib/l10n/app_localizations_en.dart'),
      File('${root.path}/apps/cc_remote/lib/l10n/app_localizations_en.dart'),
    ];
    final method = RegExp(
      r'String (\w+)\(([^)]+)\) \{\n(.*?)\n  \}',
      dotAll: true,
    );
    final offenders = <String>[];

    for (final file in files) {
      expect(file.existsSync(), isTrue, reason: file.path);
      final rel = file.path.substring(root.path.length + 1);
      for (final match in method.allMatches(file.readAsStringSync())) {
        final name = match.group(1)!;
        final params = match.group(2)!;
        final body = match.group(3)!;
        for (final raw in params.split(',')) {
          final parts = raw.trim().split(RegExp(r'\s+'));
          if (parts.length < 2) continue;
          final param = parts.last;
          if (!RegExp(
            '(?<![A-Za-z0-9_])${RegExp.escape(param)}(?![A-Za-z0-9_])',
          ).hasMatch(body)) {
            offenders.add('$rel $name($params): unused parameter `$param`');
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

Directory _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/lib/l10n/app_en.arb').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('run this suite from the repo root');
    }
    dir = parent;
  }
}

final _icuHeader = RegExp(
  r'\{([A-Za-z_][A-Za-z0-9_]*)\s*,\s*(plural|select)\s*,',
);

class _IcuBlock {
  const _IcuBlock({required this.selector, required this.inner});
  final String selector;
  final String inner;
}

class _IcuForm {
  const _IcuForm({required this.name, required this.body});
  final String name;
  final String body;
}

Iterable<_IcuBlock> _icuBlocks(String message) sync* {
  var i = 0;
  while (true) {
    final match = _icuHeader.firstMatch(message.substring(i));
    if (match == null) return;
    final start = i + match.end;
    var depth = 1;
    var j = start;
    while (j < message.length && depth > 0) {
      final ch = message[j];
      if (ch == '{') depth++;
      if (ch == '}') depth--;
      j++;
    }
    yield _IcuBlock(selector: match.group(1)!, inner: message.substring(start, j - 1));
    i = i + match.start + 1;
  }
}

Iterable<_IcuForm> _icuForms(String inner) sync* {
  var i = 0;
  while (i < inner.length) {
    while (i < inner.length && inner[i].trim().isEmpty) {
      i++;
    }
    if (i >= inner.length) return;
    final nameStart = i;
    while (i < inner.length && inner[i] != '{') {
      i++;
    }
    if (i >= inner.length) return;
    final name = inner.substring(nameStart, i).trim();
    i++;
    var depth = 1;
    final bodyStart = i;
    while (i < inner.length && depth > 0) {
      final ch = inner[i];
      if (ch == '{') depth++;
      if (ch == '}') depth--;
      i++;
    }
    yield _IcuForm(name: name, body: inner.substring(bodyStart, i - 1));
  }
}
