import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final projectRoot = Directory.current.path;

  group('MCP tool constructors must not receive Ref', () {
    test('no MCP tool receives Ref in constructor', () {
      final toolsDir = Directory(
        '$projectRoot/lib/features/mcp/application/tools',
      );
      if (!toolsDir.existsSync()) {
        return;
      }

      final violations = <String>[];
      for (final file in toolsDir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        var inClass = false;
        var className = '';
        var inConstructor = false;

        for (final line in lines) {
          if (line.trimLeft().startsWith('class ') && line.contains('Tool')) {
            inClass = true;
            className = line.trimLeft().split(' ')[1].split('(')[0];
          }

          if (inClass && line.contains(className) && line.contains('{')) {
            inConstructor = true;
          }

          if (inConstructor && line.contains('Ref')) {
            violations.add('$className in ${file.path} has Ref parameter');
            inConstructor = false;
          }

          if (inConstructor &&
              (line.trim() == ')' ||
                  line.trim().startsWith(')') ||
                  line.contains(');'))) {
            inConstructor = false;
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('Domain entities must override == and hashCode', () {
    test('all domain entity classes override == and hashCode', () {
      final entityDirs = <Directory>[];

      final coreEntitiesDir = Directory(
        '$projectRoot/lib/core/domain/entities',
      );
      if (coreEntitiesDir.existsSync()) {
        entityDirs.add(coreEntitiesDir);
      }

      final featuresDir = Directory('$projectRoot/lib/features');
      if (featuresDir.existsSync()) {
        for (final feature in featuresDir.listSync().whereType<Directory>()) {
          final dir = Directory('${feature.path}/domain/entities');
          if (dir.existsSync()) {
            entityDirs.add(dir);
          }
        }
      }

      final violations = <String>[];
      for (final entitiesDir in entityDirs) {
        for (final file in entitiesDir.listSync().whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          if (file.path.contains('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();

          final hasClass = RegExp(
            r'^(?:abstract\s+)?(?:sealed\s+)?class (\w+)',
            multiLine: true,
          ).hasMatch(content);
          if (!hasClass) {
            continue;
          }

          final hasEqualsOverride = content.contains('bool operator ==(');
          final hasHashCodeOverride = content.contains('int get hashCode');

          if (!hasEqualsOverride && !hasHashCodeOverride) {
            violations.add('${file.path}: no == or hashCode override');
          } else if (!hasEqualsOverride) {
            violations.add('${file.path}: missing == override');
          } else if (!hasHashCodeOverride) {
            violations.add('${file.path}: missing hashCode override');
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('Domain value objects must override == and hashCode', () {
    test('all value object classes with fields override == and hashCode', () {
      final valueObjectDirs = <Directory>[];

      final coreVoDir = Directory(
        '$projectRoot/lib/core/domain/value_objects',
      );
      if (coreVoDir.existsSync()) {
        valueObjectDirs.add(coreVoDir);
      }

      final featuresDir = Directory('$projectRoot/lib/features');
      if (featuresDir.existsSync()) {
        for (final feature in featuresDir.listSync().whereType<Directory>()) {
          final voDir = Directory('${feature.path}/domain/value_objects');
          if (voDir.existsSync()) {
            valueObjectDirs.add(voDir);
          }
        }
      }

      final violations = <String>[];
      for (final voDir in valueObjectDirs) {
        for (final file in voDir.listSync().whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          if (file.path.contains('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();

          final hasNonEnumClass = RegExp(
            r'^class \w+',
            multiLine: true,
          ).hasMatch(content);
          if (!hasNonEnumClass) {
            continue;
          }

          final hasInstanceFields = RegExp(
            r'^\s+final \S+ \w+[;=]',
            multiLine: true,
          ).hasMatch(content);
          if (!hasInstanceFields) {
            continue;
          }

          final hasEqualsOverride = content.contains('bool operator ==(');
          final hasHashCodeOverride = content.contains('int get hashCode');

          if (!hasEqualsOverride && !hasHashCodeOverride) {
            violations.add('${file.path}: no == or hashCode override');
          } else if (!hasEqualsOverride) {
            violations.add('${file.path}: missing == override');
          } else if (!hasHashCodeOverride) {
            violations.add('${file.path}: missing hashCode override');
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('Repository interfaces must have implementations', () {
    test('every repository interface has at least one implementation', () {
      final violations = <String>[];

      void checkRepoDir(Directory repoDir, String namespace) {
        for (final file in repoDir.listSync().whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }

          final content = file.readAsStringSync();

          final interfaceMatch = RegExp(
            r'abstract\s+(?:interface\s+)?class (\w+)',
          ).firstMatch(content);
          if (interfaceMatch == null) {
            continue;
          }

          final interfaceName = interfaceMatch.group(1)!;

          var foundImpl = false;

          final searchDirs = <Directory>[
            Directory('$projectRoot/lib/$namespace/data'),
            Directory('$projectRoot/lib/core/data'),
            Directory('$projectRoot/lib/core/database/repositories'),
          ];

          final featuresDir = Directory('$projectRoot/lib/features');
          if (featuresDir.existsSync()) {
            for (final feature
                in featuresDir.listSync().whereType<Directory>()) {
              final d = Directory('${feature.path}/data');
              if (d.existsSync()) {
                searchDirs.add(d);
              }
            }
          }

          for (final dataDir in searchDirs) {
            if (!dataDir.existsSync()) {
              continue;
            }
            for (final dataFile
                in dataDir.listSync(recursive: true).whereType<File>()) {
              if (!dataFile.path.endsWith('.dart')) {
                continue;
              }
              if (dataFile.path.contains('.g.dart')) {
                continue;
              }

              final dataContent = dataFile.readAsStringSync();
              if (dataContent.contains('implements $interfaceName') ||
                  dataContent.contains('extends $interfaceName')) {
                foundImpl = true;
                break;
              }
            }
            if (foundImpl) {
              break;
            }
          }

          if (!foundImpl) {
            violations.add(
              '$interfaceName in ${file.path} has no implementation',
            );
          }
        }
      }

      final coreRepoDir = Directory(
        '$projectRoot/lib/core/domain/repositories',
      );
      if (coreRepoDir.existsSync()) {
        checkRepoDir(coreRepoDir, 'core');
      }

      final featuresDirList = Directory('$projectRoot/lib/features');
      if (featuresDirList.existsSync()) {
        for (final feature
            in featuresDirList.listSync().whereType<Directory>()) {
          final repoDir = Directory('${feature.path}/domain/repositories');
          if (repoDir.existsSync()) {
            final featureName = feature.path.split('/').last;
            checkRepoDir(repoDir, 'features/$featureName');
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('Clean Architecture layer boundaries', () {
    test('domain layer files do not import dio', () {
      final violations = <String>[];

      void checkDir(Directory dir) {
        for (final file in dir.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          final content = file.readAsStringSync();
          if (content.contains("import 'package:dio") ||
              content.contains('import "package:dio')) {
            violations.add(file.path);
          }
        }
      }

      final coreDomainDir = Directory('$projectRoot/lib/core/domain');
      if (coreDomainDir.existsSync()) {
        checkDir(coreDomainDir);
      }

      final featuresDir = Directory('$projectRoot/lib/features');
      if (featuresDir.existsSync()) {
        for (final feature in featuresDir.listSync().whereType<Directory>()) {
          final domainDir = Directory('${feature.path}/domain');
          if (domainDir.existsSync()) {
            checkDir(domainDir);
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('presentation layer files do not import drift', () {
      final violations = <String>[];
      final featuresDir = Directory('$projectRoot/lib/features');
      if (!featuresDir.existsSync()) {
        return;
      }

      for (final feature in featuresDir.listSync().whereType<Directory>()) {
        final presDir = Directory('${feature.path}/presentation');
        if (!presDir.existsSync()) {
          continue;
        }

        for (final file
            in presDir.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          final content = file.readAsStringSync();
          if (content.contains("import 'package:drift") ||
              content.contains('import "package:drift')) {
            violations.add(file.path);
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('core layer does not import feature data', () {
      final coreDir = Directory('$projectRoot/lib/core');
      if (!coreDir.existsSync()) {
        return;
      }

      final violations = <String>[];
      for (final file in coreDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        if (file.path.contains('.g.dart')) {
          continue;
        }
        final content = file.readAsStringSync();
        if (RegExp(r'import.*features/.*/data/').hasMatch(content)) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('domain layer does not import data layer', () {
      final violations = <String>[];

      void checkDomainDir(Directory dir) {
        if (!dir.existsSync()) {
          return;
        }
        for (final file in dir.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          if (file.path.contains('.g.dart')) {
            continue;
          }
          final content = file.readAsStringSync();
          if (RegExp(r'import.*/data/').hasMatch(content)) {
            violations.add(file.path);
          }
        }
      }

      final featuresDir = Directory('$projectRoot/lib/features');
      if (featuresDir.existsSync()) {
        for (final feature in featuresDir.listSync().whereType<Directory>()) {
          checkDomainDir(Directory('${feature.path}/domain'));
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('presentation layer does not import data layer', () {
      final violations = <String>[];
      final featuresDir = Directory('$projectRoot/lib/features');
      if (!featuresDir.existsSync()) {
        return;
      }

      for (final feature in featuresDir.listSync().whereType<Directory>()) {
        final presDir = Directory('${feature.path}/presentation');
        if (!presDir.existsSync()) {
          continue;
        }

        for (final file
            in presDir.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          final content = file.readAsStringSync();
          if (RegExp(r'import.*/data/').hasMatch(content)) {
            violations.add(file.path);
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('core layer does not import features layer', () {
      final coreDir = Directory('$projectRoot/lib/core');
      if (!coreDir.existsSync()) {
        return;
      }

      final violations = <String>[];
      for (final file in coreDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        if (file.path.contains('.g.dart')) {
          continue;
        }
        final content = file.readAsStringSync();
        if (RegExp(r'import.*features/').hasMatch(content)) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('shared layer does not import features layer', () {
      final sharedDir = Directory('$projectRoot/lib/shared');
      if (!sharedDir.existsSync()) {
        return;
      }

      final violations = <String>[];
      for (final file
          in sharedDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        if (file.path.contains('.g.dart')) {
          continue;
        }
        final content = file.readAsStringSync();
        if (RegExp(r'import.*features/').hasMatch(content)) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('domain layer files do not import providers', () {
      final violations = <String>[];

      void checkDomainDir(Directory dir) {
        if (!dir.existsSync()) {
          return;
        }
        for (final file in dir.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          if (file.path.contains('.g.dart')) {
            continue;
          }
          final content = file.readAsStringSync();
          if (RegExp(r'import.*/providers/').hasMatch(content)) {
            violations.add(file.path);
          }
        }
      }

      final coreDomainDir = Directory('$projectRoot/lib/core/domain');
      if (coreDomainDir.existsSync()) {
        checkDomainDir(coreDomainDir);
      }

      final featuresDir = Directory('$projectRoot/lib/features');
      if (featuresDir.existsSync()) {
        for (final feature in featuresDir.listSync().whereType<Directory>()) {
          checkDomainDir(Directory('${feature.path}/domain'));
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('data layer does not import presentation', () {
      final violations = <String>[];
      final featuresDir = Directory('$projectRoot/lib/features');
      if (!featuresDir.existsSync()) {
        return;
      }

      for (final feature in featuresDir.listSync().whereType<Directory>()) {
        final dataDir = Directory('${feature.path}/data');
        if (!dataDir.existsSync()) {
          continue;
        }

        for (final file
            in dataDir.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          if (file.path.contains('.g.dart')) {
            continue;
          }
          final content = file.readAsStringSync();
          if (RegExp(r'import.*/presentation/').hasMatch(content)) {
            violations.add(file.path);
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('core/domain does not import database/daos', () {
      final coreDomainDir = Directory('$projectRoot/lib/core/domain');
      if (!coreDomainDir.existsSync()) {
        return;
      }

      final violations = <String>[];
      for (final file
          in coreDomainDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        if (file.path.contains('.g.dart')) {
          continue;
        }
        final content = file.readAsStringSync();
        if (RegExp(r'import.*core/database/daos/').hasMatch(content)) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('domain layer files do not import infrastructure packages', () {
      final violations = <String>[];

      void checkDomainDir(Directory dir) {
        if (!dir.existsSync()) {
          return;
        }
        for (final file in dir.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          if (file.path.contains('.g.dart')) {
            continue;
          }
          final normalized = file.path.replaceAll(r'\', '/');
          if (normalized.contains('/ports/')) {
            continue;
          }
          final content = file.readAsStringSync();
          if (content.contains("import 'package:audioplayers") ||
              content.contains('import "package:audioplayers') ||
              content.contains("import 'package:crypto") ||
              content.contains('import "package:crypto') ||
              content.contains("import 'dart:io") ||
              content.contains('import "dart:io')) {
            violations.add(file.path);
          }
        }
      }

      final coreDomainDir = Directory('$projectRoot/lib/core/domain');
      if (coreDomainDir.existsSync()) {
        checkDomainDir(coreDomainDir);
      }

      final featuresDir = Directory('$projectRoot/lib/features');
      if (featuresDir.existsSync()) {
        for (final feature in featuresDir.listSync().whereType<Directory>()) {
          checkDomainDir(Directory('${feature.path}/domain'));
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('Vendor isolation — ticketing', () {
    test('Linear transport stays inside its adapter folder', () {
      final libDir = Directory('$projectRoot/lib');
      const adapterFolder = 'features/ticketing/data/providers/linear/';
      // Symbols that must never leak outside the Linear adapter folder. The
      // rest of the codebase talks only to TicketProviderPort.
      final forbidden = <RegExp>[
        RegExp(r'\bLinearGraphQlClient\b'),
        RegExp(r'\bLinearIssueDto\b'),
        RegExp('linear_graphql_client'),
        RegExp('linear_issue_dto'),
      ];

      final violations = <String>[];
      for (final file in libDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        if (file.path.contains('.g.dart')) {
          continue;
        }
        final normalized = file.path.replaceAll(r'\', '/');
        if (normalized.contains(adapterFolder)) {
          continue;
        }
        final content = file.readAsStringSync();
        for (final pattern in forbidden) {
          if (pattern.hasMatch(content)) {
            violations.add('${file.path} matches ${pattern.pattern}');
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('Shared kernel promotions', () {
    test('feature domain layers do not import promoted types via old paths', () {
      // ChannelMessage, ThinkingEvent and ProcessDetectionPort were promoted to
      // core/domain. Re-importing them from their old feature paths (or
      // re-creating a duplicate there) is a regression — they are shared kernel.
      final featuresDir = Directory('$projectRoot/lib/features');
      final forbidden = <RegExp>[
        RegExp(r'features/messaging/domain/entities/channel_message\.dart'),
        RegExp(r'features/messaging/domain/value_objects/thinking_event\.dart'),
        RegExp(r'features/dashboard/domain/ports/process_detection_port\.dart'),
      ];
      final violations = <String>[];
      for (final feature in featuresDir.listSync().whereType<Directory>()) {
        final domainDir = Directory('${feature.path}/domain');
        if (!domainDir.existsSync()) {
          continue;
        }
        for (final file
            in domainDir.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart') || file.path.contains('.g.dart')) {
            continue;
          }
          final content = file.readAsStringSync();
          for (final pattern in forbidden) {
            if (pattern.hasMatch(content)) {
              violations.add('${file.path} matches ${pattern.pattern}');
            }
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  // ===== UI vendor isolation: purist de-Material ratchet =====
  // The app is migrating its visual layer onto the in-repo cc_ui design-system
  // package (packages/cc_ui). Material and Cupertino ratchet down via a
  // shrinking allowlist that forbids NEW imports while tracking the files
  // pending migration. Allowlists live in test/core/migration_allowlists/*.txt
  // (one relative path per line); a stale entry (allowlisted but no longer
  // importing the vendor, or deleted) also fails so the lists stay honest.

  group('UI vendor isolation — Material', () {
    test('no flutter/material.dart import outside the migration allowlist', () {
      _assertVendorRatchet(
        projectRoot: projectRoot,
        scanDir: 'lib',
        importNeedle: 'package:flutter/material.dart',
        allowlistPath: 'test/core/migration_allowlists/material_importers.txt',
        vendor: 'flutter/material.dart',
      );
    });
  });

  group('UI vendor isolation — Cupertino', () {
    test('no flutter/cupertino.dart import outside the migration allowlist', () {
      _assertVendorRatchet(
        projectRoot: projectRoot,
        scanDir: 'lib',
        importNeedle: 'package:flutter/cupertino.dart',
        allowlistPath: 'test/core/migration_allowlists/cupertino_importers.txt',
        vendor: 'flutter/cupertino.dart',
      );
    });
  });

  group('cc_ui design-system package purity', () {
    test('cc_ui imports no forbidden infrastructure', () {
      // cc_ui must be a pure-Flutter UI package: widgets layer + tokens only.
      // It may NOT import Material/Cupertino, Riverpod, go_router, l10n,
      // drift, dio, storage, or the host app. Hard rule from day one — cc_ui
      // starts empty, so a violation can only be newly introduced.
      const forbidden = <String>[
        'package:flutter/material.dart',
        'package:flutter/cupertino.dart',
        'package:flutter_riverpod',
        'package:riverpod',
        'package:go_router',
        'package:drift',
        'package:dio',
        'package:shared_preferences',
        'package:path_provider',
        'package:flutter_secure_storage',
        'package:control_center/',
        'app_localizations',
      ];
      final offenders = <String>[];
      for (final rel in _dartFilesRelative(projectRoot, 'packages/cc_ui/lib')) {
        // Only inspect actual import/export directives, so prose in doc
        // comments (which may legitimately name a forbidden package) is ignored.
        for (final line in File('$projectRoot/$rel').readAsLinesSync()) {
          final trimmed = line.trimLeft();
          if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
            continue;
          }
          for (final needle in forbidden) {
            if (trimmed.contains(needle)) {
              offenders.add('$rel → $needle');
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('cc_natives FFI package purity', () {
    test('cc_natives imports nothing from the host app (stays a leaf)', () {
      // cc_natives owns the Dart FFI bindings/loaders for the runtime-loaded
      // natives (rift/fff/tree-sitter/aec). It must NOT depend on the host app:
      // the app injects its logging sink and on-disk path resolvers (NativeLog /
      // NativeDirResolver). A `package:control_center/` import here would
      // reintroduce the dependency cycle the extraction removed, and pulling in
      // Material/Riverpod/drift would mean it stopped being a thin FFI leaf.
      const forbidden = <String>[
        'package:control_center/',
        'package:flutter/material.dart',
        'package:flutter/cupertino.dart',
        'package:flutter_riverpod',
        'package:riverpod',
        'package:drift',
      ];
      final offenders = <String>[];
      for (final rel in _dartFilesRelative(
        projectRoot,
        'packages/cc_natives/lib',
      )) {
        // Only inspect actual import/export directives, so prose in doc comments
        // (which may legitimately name a forbidden package) is ignored.
        for (final line in File('$projectRoot/$rel').readAsLinesSync()) {
          final trimmed = line.trimLeft();
          if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
            continue;
          }
          for (final needle in forbidden) {
            if (trimmed.contains(needle)) {
              offenders.add('$rel → $needle');
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('cc_natives stays a plain Dart package (never an ffiPlugin)', () {
      // Deliberate design: the natives are FETCHED + built by scripts/natives/*.sh
      // and loaded at runtime with graceful degradation. Converting this package
      // to a Flutter ffiPlugin would move native compilation into `flutter build`
      // (no continue-on-error there), make cargo/meson mandatory for every build,
      // collapse tree-sitter to one build-time dylib (killing runtime grammar
      // download), and break the install-to-app-support dev loop. Keep it plain.
      // See plans/could-all-these-scripts-synthetic-volcano.md.
      final pubspec = File(
        '$projectRoot/packages/cc_natives/pubspec.yaml',
      ).readAsStringSync();
      // Ignore comment lines so the rationale above (which names ffiPlugin in
      // prose) doesn't trip the check.
      final active = pubspec
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('#'))
          .join('\n');
      expect(
        active.contains('ffiPlugin'),
        isFalse,
        reason: 'cc_natives must not declare an ffiPlugin.',
      );
      expect(
        RegExp(r'^\s*plugin:', multiLine: true).hasMatch(active),
        isFalse,
        reason: 'cc_natives must not declare a flutter plugin section.',
      );
    });
  });
}

/// Reads a migration allowlist file into a set of normalized relative paths.
/// Blank lines and `#` comments are ignored.
Set<String> _readAllowlist(String projectRoot, String relPath) {
  final file = File('$projectRoot/$relPath');
  if (!file.existsSync()) {
    return <String>{};
  }
  return file
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}

/// All `.dart` files under [dirPath] (recursive), excluding generated files,
/// as paths relative to [projectRoot] using forward slashes.
Iterable<String> _dartFilesRelative(String projectRoot, String dirPath) sync* {
  final dir = Directory('$projectRoot/$dirPath');
  if (!dir.existsSync()) {
    return;
  }
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final path = entity.path;
    if (!path.endsWith('.dart')) {
      continue;
    }
    if (path.endsWith('.g.dart') || path.endsWith('.mocks.dart')) {
      continue;
    }
    yield path.substring(projectRoot.length + 1).replaceAll(r'\', '/');
  }
}

/// Enforces a shrinking-allowlist ratchet for a banned import [importNeedle].
///
/// Fails if any file under [scanDir] imports the vendor without being listed in
/// [allowlistPath], OR if an allowlisted entry no longer imports the vendor
/// (stale entries must be pruned so the list mirrors the real migration state).
void _assertVendorRatchet({
  required String projectRoot,
  required String scanDir,
  required String importNeedle,
  required String allowlistPath,
  required String vendor,
}) {
  final allow = _readAllowlist(projectRoot, allowlistPath);
  final stale = <String>{...allow};
  final offenders = <String>[];
  for (final rel in _dartFilesRelative(projectRoot, scanDir)) {
    final content = File('$projectRoot/$rel').readAsStringSync();
    if (content.contains(importNeedle)) {
      stale.remove(rel);
      if (!allow.contains(rel)) {
        offenders.add(rel);
      }
    }
  }
  final staleList = stale.toList()..sort();
  expect(
    offenders,
    isEmpty,
    reason:
        'New $vendor imports outside the allowlist ($allowlistPath). Migrate '
        'them to cc_ui:\n${offenders.join('\n')}',
  );
  expect(
    staleList,
    isEmpty,
    reason:
        'Stale $vendor allowlist entries (no longer import $vendor — remove '
        'from $allowlistPath):\n${staleList.join('\n')}',
  );
}
