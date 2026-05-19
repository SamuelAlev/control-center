#!/usr/bin/env python3
"""Regenerates the deferred grammar packs under lib/shared/syntax/grammar_packs/.

Run after a shiki_flutter upgrade (the pack files import
`package:shiki_flutter/src/langs/*.dart` directly, so an upgrade that renames
grammar files breaks the COMPILE; this script re-derives the imports from the
resolved package).

    python3 tool/gen_grammar_packs.py

The curated set below must stay in sync with
lib/shared/syntax/curated_grammars.dart — packs carry everything else.
"""

import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CURATED = {
    'dart', 'json', 'jsonc', 'json5', 'jsonl', 'yaml', 'toml', 'ini', 'dotenv',
    'typescript', 'tsx', 'jsx', 'javascript', 'html', 'xml', 'css', 'scss',
    'sass', 'less',
    'shellscript', 'shellsession', 'powershell', 'bat',
    'python', 'go', 'rust', 'java', 'kotlin', 'swift', 'objective-c', 'c',
    'cpp', 'csharp', 'php', 'ruby', 'scala', 'groovy', 'lua', 'r', 'perl',
    'sql', 'graphql', 'proto', 'docker', 'make', 'cmake', 'diff', 'regexp',
    'csv', 'log',
}

N_PACKS = 5

HEADER = """\
// GENERATED-STYLE FILE (hand-managed): one deferred grammar pack for the web
// registry. Imports `package:shiki_flutter/src/langs/*.dart` directly —
// deliberate implementation imports (info-level lint): the per-grammar
// libraries are not re-exported publicly and a shiki upgrade that renames
// them breaks this COMPILE, not runtime. Regenerate with
// tool/gen_grammar_packs.py after a shiki_flutter upgrade.
//
// ignore_for_file: implementation_imports

import 'package:shiki_flutter/src/core/code_language.dart';
"""

INDEX_HEADER = """\
// GENERATED-STYLE FILE (hand-managed): the deferred-pack index and loader.
// Which pack owns which non-curated grammar id, plus the `deferred as`
// loaders. dart2js emits one loading unit per pack; shared embedded grammars
// land in shared units automatically. Regenerate with
// tool/gen_grammar_packs.py after a shiki_flutter upgrade.
"""


def shiki_root() -> str:
    config = json.load(open(os.path.join(REPO, '.dart_tool/package_config.json')))
    uri = next(p['rootUri'] for p in config['packages']
               if p['name'] == 'shiki_flutter')
    if not uri.startswith('file://'):
        sys.exit(f'unexpected shiki_flutter rootUri: {uri} (run flutter pub get)')
    return uri.removeprefix('file://')


def main() -> None:
    langs_dir = os.path.join(shiki_root(), 'lib/src/langs')
    grammars = {}  # id -> (file stem, const name)
    for fn in sorted(os.listdir(langs_dir)):
        if not fn.endswith('.dart'):
            continue
        src = open(os.path.join(langs_dir, fn)).read()
        const = re.search(r'const CodeLanguage (\w+) = CodeLanguage\(', src)
        gid = re.search(r"id: '([^']+)'", src)
        if const and gid:
            grammars[gid.group(1)] = (fn[:-5], const.group(1))

    missing = CURATED - set(grammars)
    if missing:
        sys.exit(f'curated ids not in the shiki bundle: {sorted(missing)}')

    rest = sorted(set(grammars) - CURATED)
    per = (len(rest) + N_PACKS - 1) // N_PACKS
    packs = {f'pack_{chr(ord("a") + k)}': rest[k * per:(k + 1) * per]
             for k in range(N_PACKS)}

    out_dir = os.path.join(REPO, 'lib/shared/syntax/grammar_packs')
    for pack, ids in packs.items():
        lines = [HEADER]
        for gid in ids:
            stem, _ = grammars[gid]
            lines.append(
                f"import 'package:shiki_flutter/src/langs/{stem}.dart' as l_{stem};")
        lines += ['', '/// The grammars this pack carries.',
                  'final List<CodeLanguage> grammars = [']
        for gid in ids:
            stem, const = grammars[gid]
            lines.append(f'  l_{stem}.{const},')
        lines += ['];', '']
        open(os.path.join(out_dir, f'{pack}.dart'), 'w').write('\n'.join(lines))

    idx = [INDEX_HEADER]
    for pack in packs:
        idx.append(
            f"import 'package:control_center/shared/syntax/grammar_packs/{pack}.dart'\n"
            f'    deferred as {pack};')
    idx += ["import 'package:shiki_flutter/langs.dart';", '',
            '/// Which pack owns which non-curated grammar id.',
            'const Map<String, String> packOfId = <String, String>{']
    for pack, ids in packs.items():
        for gid in ids:
            idx.append(f"  '{gid}': '{pack}',")
    idx += ['};', '', '''\
/// Loads pack [name] and hands its grammars to [register]. Returns whether
/// the pack loaded. Unknown names resolve false (defensive; the index above
/// is the only caller's source of names).
Future<bool> loadPack(
  String name,
  void Function(Iterable<CodeLanguage>) register,
) async {
  switch (name) {''']
    for pack in packs:
        idx.append(f'''    case '{pack}':
      await {pack}.loadLibrary();
      register({pack}.grammars);
      return true;''')
    idx += ['  }', '  return false;', '}', '']
    open(os.path.join(out_dir, 'pack_index.dart'), 'w').write('\n'.join(idx))

    print(f'total={len(grammars)} curated={len(CURATED)} deferred={len(rest)}')
    print('packs:', {k: len(v) for k, v in packs.items()})


if __name__ == '__main__':
    main()
