import 'dart:io';

import 'package:test/test.dart';

/// Constructor validation must survive release mode.
///
/// `assert` is a DEBUG-ONLY statement. Dart strips it from
/// `flutter build --release` and from `dart build cli`, which is precisely the
/// production `cc_server` binary — so every entity that validated with
/// `assert(name.isNotEmpty, …)` had, in production, no validation at all. Two
/// enforcement semantics coexisted in one package (`Agent` asserted;
/// `chat_space_link.dart` threw `ArgumentError`), which is the shape of a
/// rule nobody can follow because there is no rule.
///
/// The convention now: **a non-const constructor validates by throwing**, in
/// its body. 154 asserts across 73 files were converted.
///
/// A `const` constructor is the one exception, and it is a language
/// constraint rather than a preference: a const constructor cannot have a
/// body, and dropping `const` to gain one would break every `const X(...)`
/// call site — a worse trade than debug-only validation on a type whose
/// values are usually compile-time literals anyway. Those keep their asserts,
/// and this test pins that they are the ONLY ones that do.
///
/// Scope is every non-generated `lib/` in the workspace, not just this
/// package: the first version of this check used a regex whose parameter-list
/// pattern (`\([^;{]*?\)`) could not span a `{…}` named-parameter list, so it
/// silently saw only positional constructors — i.e. almost none of them — and
/// passed while eight offenders sat in other packages. It now scans with a
/// brace-balanced walk and asserts a floor on what it found.
void main() {
  test('no non-const constructor validates with assert', () {
    final roots = _libRoots();
    expect(roots, isNotEmpty, reason: 'no lib/ roots found — fix _libRoots()');

    final offenders = <String>[];
    var constCtorsSeen = 0;
    var filesScanned = 0;
    for (final root in roots) {
      for (final file in _dartFiles(root)) {
        filesScanned += 1;
        final src = file.readAsStringSync();
        if (!src.contains('assert(')) {
          continue;
        }
        for (final ctor in _constructorsWithInitializerAsserts(src)) {
          if (ctor.isConst) {
            constCtorsSeen += 1;
            continue;
          }
          offenders.add('${_short(file)}: ${ctor.name}');
        }
      }
    }

    // Non-vacuity: a detector that stopped matching would otherwise report a
    // clean bill of health forever.
    expect(
      filesScanned,
      greaterThan(1000),
      reason: 'scanned $filesScanned files — the roots are probably wrong',
    );
    expect(
      constCtorsSeen,
      greaterThan(10),
      reason:
          'found only $constCtorsSeen const constructors with asserts; the '
          'detector has probably stopped matching, which would make this test '
          'vacuous',
    );
    expect(
      offenders,
      isEmpty,
      reason:
          'These non-const constructors validate with `assert`, which is '
          'stripped in release — so they do not validate in the shipped '
          'server binary at all. Move the checks into the constructor body '
          'and throw ArgumentError:\n  ${offenders.join('\n  ')}',
    );
  });

  test('the detector recognises a named-parameter constructor', () {
    // The exact shape the first version could not see. Pinned directly
    // because "the suite is green" is not evidence a grep still greps.
    const src = '''
class Thing {
  Thing({
    required this.name,
    this.other,
  }) : assert(name.isNotEmpty, 'name must not be empty');
}
''';
    final found = _constructorsWithInitializerAsserts('\n$src');
    expect(found, hasLength(1));
    expect(found.single.name, 'Thing');
    expect(found.single.isConst, isFalse);

    const constSrc = '''
class Thing {
  const Thing({
    required this.name,
  }) : assert(name.isNotEmpty, 'name must not be empty');
}
''';
    final constFound = _constructorsWithInitializerAsserts('\n$constSrc');
    expect(constFound, hasLength(1));
    expect(constFound.single.isConst, isTrue);
  });

  test('the shared kernel throws typed errors, not a bare Exception', () {
    // cc_domain already had zero `throw Exception(` in 765 files; the
    // conversion added ~154 throws and this keeps the property true rather
    // than assuming it.
    final offenders = <String>[];
    for (final file in _dartFiles(_ccDomainLib())) {
      if (file.readAsStringSync().contains('throw Exception(')) {
        offenders.add(_short(file));
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'A bare Exception carries no type for a caller to catch. Use a typed '
          'AppException subclass, or ArgumentError for a constructor '
          'precondition:\n  ${offenders.join('\n  ')}',
    );
  });
}

/// A constructor whose initializer list contains at least one `assert`.
typedef _Ctor = ({String name, bool isConst});

final _ctorHeader = RegExp(r'\n  (const )?([A-Z]\w*)(\.\w+)?\(');

/// Index of the bracket matching the one at [open], skipping string literals.
int _closeBracket(String src, int open) {
  var depth = 0;
  var i = open;
  while (i < src.length) {
    final c = src[i];
    if (c == "'" || c == '"') {
      final quote = c;
      i += 1;
      while (i < src.length) {
        if (src[i] == r'\') {
          i += 2;
          continue;
        }
        if (src[i] == quote) {
          break;
        }
        i += 1;
      }
    } else if (c == '(' || c == '[' || c == '{') {
      depth += 1;
    } else if (c == ')' || c == ']' || c == '}') {
      depth -= 1;
      if (depth == 0) {
        return i;
      }
    }
    i += 1;
  }
  return -1;
}

List<_Ctor> _constructorsWithInitializerAsserts(String src) {
  final found = <_Ctor>[];
  for (final m in _ctorHeader.allMatches(src)) {
    final closeParen = _closeBracket(src, m.end - 1);
    if (closeParen < 0) {
      continue;
    }
    final afterParams = RegExp(r'\s*:').matchAsPrefix(src, closeParen + 1);
    if (afterParams == null) {
      continue;
    }
    // The initializer list runs to the first top-level `;` or `{`.
    var depth = 0;
    var i = afterParams.end;
    var end = -1;
    while (i < src.length) {
      final c = src[i];
      if (c == "'" || c == '"') {
        final quote = c;
        i += 1;
        while (i < src.length) {
          if (src[i] == r'\') {
            i += 2;
            continue;
          }
          if (src[i] == quote) {
            break;
          }
          i += 1;
        }
      } else if (c == '(' || c == '[') {
        depth += 1;
      } else if (c == ')' || c == ']') {
        depth -= 1;
      } else if (depth == 0 && (c == ';' || c == '{')) {
        end = i;
        break;
      }
      i += 1;
    }
    if (end < 0) {
      continue;
    }
    if (!src.substring(afterParams.end, end).contains('assert(')) {
      continue;
    }
    found.add((
      name: '${m.group(2)}${m.group(3) ?? ''}',
      isConst: m.group(1) != null,
    ));
  }
  return found;
}

Directory _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (Directory('${dir.path}/packages/cc_domain/lib').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Could not locate the repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
}

Directory _ccDomainLib() =>
    Directory('${_repoRoot().path}/packages/cc_domain/lib');

/// Every first-party `lib/` in the workspace.
///
/// Enumerated from `packages/` and `apps/` rather than listed, so a new
/// package is covered the day it exists. `apps/cc_server/data/` — a developer's
/// live run directory, which contains a full nested checkout of this repo — is
/// never reached because only `<member>/lib` is scanned.
List<Directory> _libRoots() {
  final root = _repoRoot();
  final roots = <Directory>[Directory('${root.path}/lib')];
  for (final group in ['packages', 'apps']) {
    final dir = Directory('${root.path}/$group');
    if (!dir.existsSync()) {
      continue;
    }
    for (final member in dir.listSync().whereType<Directory>()) {
      final lib = Directory('${member.path}/lib');
      if (lib.existsSync()) {
        roots.add(lib);
      }
    }
  }
  return roots.where((d) => d.existsSync()).toList();
}

Iterable<File> _dartFiles(Directory root) => root
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

String _short(File f) {
  final parts = f.uri.pathSegments;
  final i = parts.lastIndexOf('lib');
  return i <= 0 ? parts.last : parts.sublist(i - 1).join('/');
}
