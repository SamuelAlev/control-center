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
        if (!file.path.endsWith('.dart')) continue;
        if (file.path.contains('.g.dart')) continue;
        final normalized = file.path.replaceAll(r'\', '/');
        if (normalized.contains(adapterFolder)) continue;
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
}
