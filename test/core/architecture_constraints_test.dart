import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final projectRoot = Directory.current.path;

  group('MCP tool constructors must not receive Ref', () {
    test('no MCP tool receives Ref in constructor', () {
      // The MCP tool surface moved to `packages/cc_mcp` in the backend
      // exodus. This guard kept scanning `lib/features/mcp/application/tools`,
      // which no longer exists — and RETURNED on the missing directory, so it
      // passed vacuously for months. Fail loudly on a missing scan root
      // instead: a guard that cannot find its subject is broken, not satisfied.
      final toolsDir = Directory('$projectRoot/packages/cc_mcp/lib/src/tools');
      expect(
        toolsDir.existsSync(),
        isTrue,
        reason:
            'MCP tool scan root is missing: ${toolsDir.path}. If the tools '
            'moved again, re-aim this guard rather than letting it pass.',
      );

      final violations = <String>[];
      for (final file in toolsDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        // `Ref` as a TYPE, not as a substring. The previous `contains('Ref')`
        // flagged `RefreshFeedsTool` and every `refresh…` parameter, which is
        // the kind of noise that gets a guard disabled rather than obeyed.
        final refType = RegExp(r'(?<![A-Za-z0-9_])Ref[?\s]');

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

          if (inConstructor && refType.hasMatch(line)) {
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
      // Entities live in the SHARED KERNEL now, not under `lib/`. This guard
      // kept scanning `lib/core/domain/entities` + `lib/features/*/domain/
      // entities`, both emptied by the backend exodus, and passed on an empty
      // list — so `packages/cc_domain`'s entities were unpoliced entirely.
      final entityDirs = _domainDirs(projectRoot, 'entities');
      expect(
        entityDirs,
        isNotEmpty,
        reason:
            'No domain entity directories found under packages/cc_domain — '
            're-aim this guard rather than letting it pass vacuously.',
      );

      final allow = _readAllowlist(
        projectRoot,
        'test/core/migration_allowlists/domain_entities_without_equality.txt',
      );
      final stale = <String>{...allow};
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
          if (hasEqualsOverride && hasHashCodeOverride) {
            continue;
          }
          final rel = file.path
              .substring(projectRoot.length + 1)
              .replaceAll(r'\', '/');
          stale.remove(rel);
          if (allow.contains(rel)) {
            continue;
          }
          if (!hasEqualsOverride && !hasHashCodeOverride) {
            violations.add('$rel: no == or hashCode override');
          } else if (!hasEqualsOverride) {
            violations.add('$rel: missing == override');
          } else {
            violations.add('$rel: missing hashCode override');
          }
        }
      }

      expect(violations..sort(), isEmpty, reason: violations.join('\n'));
      expect(
        stale.toList()..sort(),
        isEmpty,
        reason:
            'Stale entries in domain_entities_without_equality.txt (these now '
            'override both, or no longer exist) — prune them:\n'
            '${(stale.toList()..sort()).join('\n')}',
      );
    });
  });

  group('Domain value objects must override == and hashCode', () {
    test('all value object classes with fields override == and hashCode', () {
      // Same exodus, same fix as the entity guard above.
      final valueObjectDirs = _domainDirs(projectRoot, 'value_objects');
      expect(
        valueObjectDirs,
        isNotEmpty,
        reason:
            'No domain value-object directories found under '
            'packages/cc_domain — re-aim this guard rather than letting it '
            'pass vacuously.',
      );

      final allow = _readAllowlist(
        projectRoot,
        'test/core/migration_allowlists/'
            'domain_value_objects_without_equality.txt',
      );
      final stale = <String>{...allow};
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
          if (hasEqualsOverride && hasHashCodeOverride) {
            continue;
          }
          final rel = file.path
              .substring(projectRoot.length + 1)
              .replaceAll(r'\', '/');
          stale.remove(rel);
          if (allow.contains(rel)) {
            continue;
          }
          if (!hasEqualsOverride && !hasHashCodeOverride) {
            violations.add('$rel: no == or hashCode override');
          } else if (!hasEqualsOverride) {
            violations.add('$rel: missing == override');
          } else {
            violations.add('$rel: missing hashCode override');
          }
        }
      }

      expect(violations..sort(), isEmpty, reason: violations.join('\n'));
      expect(
        stale.toList()..sort(),
        isEmpty,
        reason:
            'Stale entries in domain_value_objects_without_equality.txt '
            '(these now override both, or no longer exist) — prune them:\n'
            '${(stale.toList()..sort()).join('\n')}',
      );
    });
  });

  group('Repository interfaces must have implementations', () {
    test('every repository interface has at least one implementation', () {
      final violations = <String>[];

      // Interfaces live in the shared kernel; implementations live in the
      // adapter packages (`cc_persistence` DAO-backed, `cc_data` RPC-backed,
      // `cc_infra` VM adapters) — NOT under `lib/**/data`, which is where this
      // guard was still looking. Both halves had moved, so it scanned nothing
      // and asserted nothing.
      final implSources = <String>[
        for (final pkg in const [
          'cc_persistence',
          'cc_data',
          'cc_infra',
          'cc_server_core',
        ])
          ...(Directory('$projectRoot/packages/$pkg/lib').existsSync()
              ? _dartFilesRelative(projectRoot, 'packages/$pkg/lib')
              : const <String>[]),
        // A handful of ports are implemented client-side (UI-only adapters).
        ..._dartFilesRelative(projectRoot, 'lib'),
      ];
      expect(
        implSources,
        isNotEmpty,
        reason: 'No implementation sources found — re-aim this guard.',
      );
      final implBlob = StringBuffer();
      for (final rel in implSources) {
        implBlob.writeln(File('$projectRoot/$rel').readAsStringSync());
      }
      final allImpls = implBlob.toString();

      final allow = _readAllowlist(
        projectRoot,
        'test/core/migration_allowlists/'
            'domain_repositories_without_implementations.txt',
      );
      final stale = <String>{...allow};

      void checkRepoDir(Directory repoDir) {
        for (final file in repoDir.listSync().whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          final content = file.readAsStringSync();
          // EVERY interface in the file, not just the first — a file
          // declaring three ports used to be judged by one of them.
          final names = RegExp(r'abstract\s+(?:interface\s+)?class (\w+)')
              .allMatches(content)
              .map((m) => m.group(1)!)
              .toList();
          if (names.isEmpty) {
            continue;
          }
          final rel = file.path
              .substring(projectRoot.length + 1)
              .replaceAll(r'\', '/');
          for (final name in names) {
            final implemented =
                allImpls.contains('implements $name') ||
                allImpls.contains('extends $name') ||
                allImpls.contains(', $name') ||
                allImpls.contains('implements $name,');
            if (implemented) {
              continue;
            }
            stale.remove(rel);
            if (allow.contains(rel)) {
              continue;
            }
            violations.add('$name in $rel has no implementation');
          }
        }
      }

      final repoDirs = _domainDirs(projectRoot, 'repositories');
      expect(
        repoDirs,
        isNotEmpty,
        reason:
            'No domain repository directories found under packages/cc_domain '
            '— re-aim this guard rather than letting it pass vacuously.',
      );
      for (final dir in repoDirs) {
        checkRepoDir(dir);
      }

      expect(violations..sort(), isEmpty, reason: violations.join('\n'));
      expect(
        stale.toList()..sort(),
        isEmpty,
        reason:
            'Stale entries in domain_repositories_without_implementations.txt '
            '(these now have an implementation, or no longer exist) — prune '
            'them:\n${(stale.toList()..sort()).join('\n')}',
      );
    });
  });

  group('Clean Architecture layer boundaries', () {
    test('domain layer files do not import dio', () {
      final violations = <String>[];

      void checkDir(Directory dir) {
        if (!dir.existsSync()) {
          return;
        }
        final relDir = dir.path
            .substring(projectRoot.length + 1)
            .replaceAll(r'\', '/');
        for (final rel in _dartFilesRelative(projectRoot, relDir)) {
          final content = File('$projectRoot/$rel').readAsStringSync();
          if (content.contains("import 'package:dio") ||
              content.contains('import "package:dio')) {
            violations.add('$projectRoot/$rel');
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
        final relDir = presDir.path
            .substring(projectRoot.length + 1)
            .replaceAll(r'\', '/');
        for (final rel in _dartFilesRelative(projectRoot, relDir)) {
          final content = File('$projectRoot/$rel').readAsStringSync();
          if (content.contains("import 'package:drift") ||
              content.contains('import "package:drift')) {
            violations.add('$projectRoot/$rel');
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
      for (final rel in _dartFilesRelative(projectRoot, 'lib/core')) {
        final content = File('$projectRoot/$rel').readAsStringSync();
        if (RegExp(r'import.*features/.*/data/').hasMatch(content)) {
          violations.add(rel);
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
        final relDir = dir.path
            .substring(projectRoot.length + 1)
            .replaceAll(r'\', '/');
        for (final rel in _dartFilesRelative(projectRoot, relDir)) {
          final content = File('$projectRoot/$rel').readAsStringSync();
          if (RegExp(r'import.*/data/').hasMatch(content)) {
            violations.add(rel);
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

    // These three cross-layer bans use a shrinking allowlist (same philosophy
    // as the Material/Cupertino ratchets below): the seed lists capture the
    // pre-existing debt and the ratchet fails on any NEW violation or on a
    // stale entry. Migrating a listed file out of the wrong layer + pruning its
    // allowlist line is the way to shrink these to zero.
    test('presentation layer does not import data layer', () {
      _assertImportRegexRatchet(
        projectRoot: projectRoot,
        scanDir: 'lib/features',
        pattern: RegExp(r'import.*/data/'),
        allowlistPath:
            'test/core/migration_allowlists/presentation_data_importers.txt',
        description: 'presentation layer imports a feature data/ layer',
        includeFile: (rel) => rel.contains('/presentation/'),
      );
    });

    // `package:control_center/features/`, not a bare `features/`: the shared
    // kernel files its subdomains under `package:cc_domain/features/…` too, and
    // depending on a domain entity is not a layering inversion — it is the
    // whole point of a shared kernel. The looser pattern put eight files on
    // these two allowlists for a violation they do not commit, where they could
    // never be "migrated out" and so would have sat forever.
    const appFeatureImport = r"import 'package:control_center/features/";

    test('core layer does not import features layer', () {
      _assertImportRegexRatchet(
        projectRoot: projectRoot,
        scanDir: 'lib/core',
        pattern: appFeatureImport,
        allowlistPath:
            'test/core/migration_allowlists/core_features_importers.txt',
        description: 'core layer imports the features layer',
      );
    });

    test('shared layer does not import features layer', () {
      _assertImportRegexRatchet(
        projectRoot: projectRoot,
        scanDir: 'lib/shared',
        pattern: appFeatureImport,
        allowlistPath:
            'test/core/migration_allowlists/shared_features_importers.txt',
        description: 'shared layer imports the features layer',
      );
    });

    // Deliberately ONE-DIRECTIONAL. A feature importing settings' card
    // vocabulary (`settings_shared.dart`, `scope_badge.dart`, `SettingsPage`)
    // is the hub PROVIDING a design language, which is what makes a contributed
    // card look native; settings importing a feature's widgets is the hub
    // CONSUMING its spokes, which is how it became the app's de-facto
    // integration point in the first place. Contributions come through
    // `settings_extensions.dart` + `di/settings_registry.dart` instead.
    test('settings does not import another feature presentation dir', () {
      _assertImportRegexRatchet(
        projectRoot: projectRoot,
        scanDir: 'lib/features/settings',
        pattern: RegExp(
          r"import 'package:control_center/features/(?!settings/)[a-z_]+/"
          r'presentation/',
        ),
        allowlistPath:
            'test/core/migration_allowlists/settings_feature_importers.txt',
        description:
            "the settings feature imports another feature's presentation "
            'layer instead of receiving it through the settings registry',
      );
    });

    // The seam only works if it stays a seam. A contract that reached back into
    // `settings/presentation/` would drag the whole settings UI into every
    // feature that declared a contribution, and the inversion would be a
    // rename.
    test('the settings extension contract stays contract-only', () {
      final file = File(
        '$projectRoot/lib/features/settings/settings_extensions.dart',
      );
      expect(file.existsSync(), isTrue);
      final offenders = RegExp(r"^import '([^']+)';", multiLine: true)
          .allMatches(file.readAsStringSync())
          .map((m) => m.group(1)!)
          .where(
            (uri) =>
                uri.contains('/presentation/') ||
                uri.contains('/providers/') ||
                uri.contains('control_center/di/'),
          )
          .toList();
      expect(
        offenders,
        isEmpty,
        reason:
            'settings_extensions.dart must stay importable by any feature '
            'without pulling in UI or providers:\n${offenders.join('\n')}',
      );
    });

    test('domain layer files do not import providers', () {
      final violations = <String>[];

      void checkDomainDir(Directory dir) {
        if (!dir.existsSync()) {
          return;
        }
        final relDir = dir.path
            .substring(projectRoot.length + 1)
            .replaceAll(r'\', '/');
        for (final rel in _dartFilesRelative(projectRoot, relDir)) {
          final content = File('$projectRoot/$rel').readAsStringSync();
          if (RegExp(r'import.*/providers/').hasMatch(content)) {
            violations.add(rel);
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
        final relDir = dataDir.path
            .substring(projectRoot.length + 1)
            .replaceAll(r'\', '/');
        for (final rel in _dartFilesRelative(projectRoot, relDir)) {
          final content = File('$projectRoot/$rel').readAsStringSync();
          if (RegExp(r'import.*/presentation/').hasMatch(content)) {
            violations.add(rel);
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
      for (final rel in _dartFilesRelative(projectRoot, 'lib/core/domain')) {
        final content = File('$projectRoot/$rel').readAsStringSync();
        if (RegExp(r'import.*core/database/daos/').hasMatch(content)) {
          violations.add(rel);
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
        final relDir = dir.path
            .substring(projectRoot.length + 1)
            .replaceAll(r'\', '/');
        for (final rel in _dartFilesRelative(projectRoot, relDir)) {
          final content = File('$projectRoot/$rel').readAsStringSync();
          final normalized = rel.replaceAll(r'\', '/');
          if (normalized.contains('/ports/')) {
            continue;
          }
          if (content.contains("import 'package:media_kit") ||
              content.contains('import "package:media_kit') ||
              content.contains("import 'package:crypto") ||
              content.contains('import "package:crypto') ||
              content.contains("import 'dart:io") ||
              content.contains('import "dart:io')) {
            violations.add(rel);
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

    test('cc_domain package is pure-Dart (no dart:io/infra deps)', () {
      final violations = <String>[];
      final dir = Directory('$projectRoot/packages/cc_domain/lib');
      if (!dir.existsSync()) {
        return;
      }

      for (final rel in _dartFilesRelative(
        projectRoot,
        'packages/cc_domain/lib',
      )) {
        final content = File('$projectRoot/$rel').readAsStringSync();
        if (content.contains("import 'dart:io") ||
            content.contains('import "dart:io') ||
            content.contains("import 'package:cc_infra") ||
            content.contains('import "package:cc_infra') ||
            content.contains("import 'package:drift") ||
            content.contains('import "package:drift') ||
            content.contains("import 'package:dio") ||
            content.contains('import "package:dio') ||
            content.contains("import 'package:flutter") ||
            content.contains('import "package:flutter') ||
            content.contains("import 'package:media_kit") ||
            content.contains('import "package:media_kit')) {
          violations.add(rel);
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('Vendor isolation — ticketing', () {
    test('Linear transport stays inside its adapter folder', () {
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
      for (final rel in _dartFilesRelative(projectRoot, 'lib')) {
        final content = File('$projectRoot/$rel').readAsStringSync();
        final normalized = rel.replaceAll(r'\', '/');
        if (normalized.contains(adapterFolder)) {
          continue;
        }
        for (final pattern in forbidden) {
          if (pattern.hasMatch(content)) {
            violations.add('$rel matches ${pattern.pattern}');
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('Shared kernel promotions', () {
    test('feature domain layers do not import promoted types via old paths', () {
      // Message, ThinkingEvent and ProcessDetectionPort were promoted to
      // core/domain. Re-importing them from their old feature paths (or
      // re-creating a duplicate there) is a regression — they are shared kernel.
      final featuresDir = Directory('$projectRoot/lib/features');
      final forbidden = <RegExp>[
        RegExp(r'features/messaging/domain/entities/message\.dart'),
        RegExp(r'features/messaging/domain/value_objects/thinking_event\.dart'),
      ];
      final violations = <String>[];
      for (final feature in featuresDir.listSync().whereType<Directory>()) {
        final domainDir = Directory('${feature.path}/domain');
        if (!domainDir.existsSync()) {
          continue;
        }
        final relDir = domainDir.path
            .substring(projectRoot.length + 1)
            .replaceAll(r'\', '/');
        for (final rel in _dartFilesRelative(projectRoot, relDir)) {
          final content = File('$projectRoot/$rel').readAsStringSync();
          for (final pattern in forbidden) {
            if (pattern.hasMatch(content)) {
              violations.add('$rel matches ${pattern.pattern}');
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
    test(
      'no flutter/cupertino.dart import outside the migration allowlist',
      () {
        _assertVendorRatchet(
          projectRoot: projectRoot,
          scanDir: 'lib',
          importNeedle: 'package:flutter/cupertino.dart',
          allowlistPath:
              'test/core/migration_allowlists/cupertino_importers.txt',
          vendor: 'flutter/cupertino.dart',
        );
      },
    );
  });

  // The import ratchet above is deliberately coarse: a file that legitimately
  // still imports material.dart (usually only for `Theme.of(context)`) could
  // quietly grow a NEW Material widget without tripping it — which is exactly
  // how a raw `TextButton` reached the failed-run "Retry" affordance while the
  // rest of that bubble was already on cc_ui. This guard closes that hole by
  // banning the Material COMPONENTS that have a cc_ui counterpart, everywhere
  // under lib/, independent of what a file imports. Use the `Cc*` widget
  // instead (see the mapping in the failure message).
  group('UI vendor isolation — Material components', () {
    test('no Material component widgets outside the allowlist', () {
      _assertNoMaterialComponents(projectRoot: projectRoot, scanDir: 'lib');
    });
  });

  // ===== Web-safe compute: dart:isolate ban =====
  // `dart:isolate` does not exist on the web. Web-reachable code (the thin
  // client + the web-safe packages it bundles) must offload heavy work through
  // `isolate_manager` (real isolates on native, generated Web Workers on web)
  // rather than importing `dart:isolate` directly — otherwise `flutter build
  // web` breaks. The VM-only server/FFI packages (cc_infra, cc_natives,
  // cc_persistence, cc_host, cc_server_core, cc_mcp*) are intentionally out of
  // scope: they never build for web and their FFI-handle/callback isolates do
  // not fit isolate_manager's persistent-worker model. The allowlist starts
  // empty — a hard ban; an entry would mark a temporary migration exception.
  group('Web-safe compute — no dart:isolate in web-reachable code', () {
    test('no dart:isolate import outside the allowlist', () {
      const webReachableDirs = <String>[
        'lib',
        'packages/cc_rpc/lib',
        'packages/cc_data/lib',
        'packages/cc_domain/lib',
        'packages/cc_ui/lib',
        'packages/cc_markdown/lib',
        'apps/cc_remote/lib',
      ];
      // Directive-precise: only real `import`/`export 'dart:isolate'` lines, so
      // a doc comment mentioning dart:isolate is not a false positive and
      // `package:isolate_manager` (the sanctioned wrapper) is never matched.
      final directive = RegExp(r'''(?:import|export)\s+['"]dart:isolate['"]''');
      const allowlistPath =
          'test/core/migration_allowlists/dart_isolate_importers.txt';
      final allow = _readAllowlist(projectRoot, allowlistPath);
      final stale = <String>{...allow};
      final offenders = <String>[];
      for (final dir in webReachableDirs) {
        for (final rel in _dartFilesRelative(projectRoot, dir)) {
          // Strip comments first so a doc comment that quotes the literal
          // `import 'dart:isolate'` is not mistaken for a real directive.
          final content = _stripDartComments(
            File('$projectRoot/$rel').readAsStringSync(),
          );
          if (content.contains(directive)) {
            stale.remove(rel);
            if (!allow.contains(rel)) {
              offenders.add(rel);
            }
          }
        }
      }
      offenders.sort();
      final staleList = stale.toList()..sort();
      expect(
        offenders,
        isEmpty,
        reason:
            'New dart:isolate import in web-reachable code (breaks `flutter '
            'build web`). Offload via isolate_manager instead:\n'
            '${offenders.join('\n')}',
      );
      expect(
        staleList,
        isEmpty,
        reason:
            'Stale dart:isolate allowlist entries (no longer import it — remove '
            'from $allowlistPath):\n${staleList.join('\n')}',
      );
    });
  });

  // ===== Web Worker cores must be Flutter-free =====
  // Worker entry files (and the Flutter-free islands they pull in) are compiled
  // by `dart compile js` (tool/gen_workers.sh), which cannot see Flutter. A
  // stray flutter/dart:ui/dart:io import breaks that compile. This is the fast
  // floor; the byte-diff drift guard (tool/check_workers.sh) catches transitive
  // regressions by actually recompiling.
  group('Web Worker cores are Flutter-free', () {
    test(
      'worker-reachable source files import no Flutter / dart:ui / dart:io',
      () {
        const workerSources = <String>[
          'lib/features/pr_review/presentation/utils/diff_worker_core.dart',
          'lib/features/pr_review/presentation/utils/word_diff.dart',
          'lib/shared/widgets/markdown/markdown_worker_core.dart',
          'packages/cc_markdown/lib/parser.dart',
          'packages/cc_markdown/lib/src/codec/markdown_ast_codec.dart',
          // The shiki tokenizer island the diff worker compiles in
          // (package:shiki_flutter/engine.dart itself is the package's
          // documented Flutter-free entrypoint).
          'lib/shared/syntax/cc_shiki_theme.dart',
          'lib/shared/syntax/cc_shiki_theme_json.dart',
          'lib/shared/syntax/token_lines.dart',
          'lib/shared/syntax/worker_grammars.dart',
          'lib/shared/syntax/worker_grammars_io.dart',
          'lib/shared/syntax/worker_grammars_web.dart',
          'lib/shared/syntax/curated_grammars.dart',
          'lib/shared/syntax/grammar_registry_io.dart',
        ];
        const forbidden = <String>['package:flutter/', 'dart:ui', 'dart:io'];
        final offenders = <String>[];
        for (final rel in workerSources) {
          final file = File('$projectRoot/$rel');
          expect(
            file.existsSync(),
            isTrue,
            reason: 'missing worker source $rel',
          );
          for (final line in file.readAsLinesSync()) {
            final trimmed = line.trimLeft();
            if (!trimmed.startsWith('import ') &&
                !trimmed.startsWith('export ')) {
              continue;
            }
            for (final needle in forbidden) {
              if (trimmed.contains(needle)) {
                offenders.add('$rel → $needle');
              }
            }
          }
        }
        expect(
          offenders,
          isEmpty,
          reason:
              'Web Worker source imports Flutter — this breaks `dart compile js` '
              'worker generation:\n${offenders.join('\n')}',
        );
      },
    );
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
        'package:nativeapi',
        'package:path_provider',
        'package:control_center/',
        'app_localizations',
      ];
      final offenders = <String>[];
      for (final rel in _dartFilesRelative(projectRoot, 'packages/cc_ui/lib')) {
        // Only inspect actual import/export directives, so prose in doc
        // comments (which may legitimately name a forbidden package) is ignored.
        for (final line in File('$projectRoot/$rel').readAsLinesSync()) {
          final trimmed = line.trimLeft();
          if (!trimmed.startsWith('import ') &&
              !trimmed.startsWith('export ')) {
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

  group('cc_markdown engine package purity', () {
    test('cc_markdown imports no forbidden infrastructure', () {
      // cc_markdown is a self-contained markdown engine. Parser/AST/plugins are
      // pure Dart; render/selection build on package:flutter/widgets.dart. It
      // must NOT depend on the host app, cc_ui, Riverpod, a syntax highlighter
      // (highlighting is injected via codeBuilder — `package:highlight` is the
      // removed predecessor, kept as a tombstone; `package:shiki_flutter` is
      // the current engine and equally forbidden here), or l10n.
      const forbidden = <String>[
        'package:flutter/cupertino.dart',
        'package:flutter_riverpod',
        'package:riverpod',
        'package:go_router',
        'package:drift',
        'package:dio',
        'package:highlight',
        'package:shiki_flutter',
        'package:cc_ui/',
        'package:control_center/',
        'app_localizations',
      ];
      // Material is the deliberate selection island: allowed ONLY in the two
      // selection files that need SelectionArea / AdaptiveTextSelectionToolbar.
      const materialAllowed = <String>[
        'packages/cc_markdown/lib/src/selection/selection_region.dart',
        'packages/cc_markdown/lib/src/selection/context_menu.dart',
      ];
      final offenders = <String>[];
      for (final rel in _dartFilesRelative(
        projectRoot,
        'packages/cc_markdown/lib',
      )) {
        for (final line in File('$projectRoot/$rel').readAsLinesSync()) {
          final trimmed = line.trimLeft();
          if (!trimmed.startsWith('import ') &&
              !trimmed.startsWith('export ')) {
            continue;
          }
          for (final needle in forbidden) {
            if (trimmed.contains(needle)) {
              offenders.add('$rel → $needle');
            }
          }
          if (trimmed.contains('package:flutter/material.dart') &&
              !materialAllowed.contains(rel)) {
            offenders.add(
              '$rel → package:flutter/material.dart (not allowed '
              'outside the selection island)',
            );
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
      // reintroduce the dependency cycle the extraction removed and pulling in
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
          if (!trimmed.startsWith('import ') &&
              !trimmed.startsWith('export ')) {
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
      // download) and break the install-to-app-support dev loop. Keep it plain.
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

  group('cc_harness kernel package purity (PRD 26)', () {
    test('cc_harness imports only dart core + collection/meta', () {
      // The harness kernel is the embeddable agent-loop engine: contracts,
      // loop, compaction, steering, verifiers, strategies. It must stay pure —
      // no dart:io/ffi, no Flutter, no other cc_* package, no infra. This is
      // what makes it runnable in tests, on web, in cc_worker and (eventually)
      // as a standalone OSS package.
      final allowed = RegExp(
        r"^(import|export)\s+'(dart:(async|collection|convert|math|typed_data)"
        r'|package:collection/'
        r'|package:meta/'
        r'|package:cc_harness/'
        r'|src/|\.\./|[a-z_]+(/|\.dart))',
      );
      final offenders = <String>[];
      for (final rel in _dartFilesRelative(
        projectRoot,
        'packages/cc_harness/lib',
      )) {
        for (final line in File('$projectRoot/$rel').readAsLinesSync()) {
          final trimmed = line.trimLeft();
          if (!trimmed.startsWith('import ') &&
              !trimmed.startsWith('export ')) {
            continue;
          }
          if (!allowed.hasMatch(trimmed)) {
            offenders.add('$rel → $trimmed');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the cc_harness barrel dartdoc names only topics that exist', () {
      // The barrel used to advertise a `refinement.dart` topic (HarnessSession /
      // StrategyRunner / Verifier) that did not exist in code. An agent
      // grepping for it found the promise and built against a void, which is a
      // documentation lie with teeth. Every topic named in the library dartdoc
      // must be a real file.
      final barrel = File(
        '$projectRoot/packages/cc_harness/lib/cc_harness.dart',
      );
      final doc = barrel
          .readAsLinesSync()
          .takeWhile((l) => !l.startsWith('library'))
          .join(' ');
      final topics = RegExp(
        r'`([a-z_]+\.dart)`',
      ).allMatches(doc).map((m) => m.group(1)!).toSet();
      expect(topics, isNotEmpty, reason: 'the dartdoc names no topics');
      final missing = [
        for (final t in topics)
          if (!File('$projectRoot/packages/cc_harness/lib/$t').existsSync()) t,
      ];
      expect(
        missing,
        isEmpty,
        reason:
            'cc_harness.dart advertises topics that do not exist: '
            '${missing.join(', ')}',
      );
    });

    test('no deep package:cc_harness/src/ imports from outside the kernel', () {
      // Consumers must go through the public entrypoints (cc_harness.dart or
      // the topic libraries: loop / provider / tools / context / messages /
      // slash_command / cancellation). Deep src imports would
      // freeze internal layout into every consumer.
      final offenders = <String>[];
      for (final root in ['lib', 'test', 'packages', 'apps']) {
        for (final rel in _dartFilesRelative(projectRoot, root)) {
          if (rel.startsWith('packages/cc_harness/')) {
            continue;
          }
          for (final line in File('$projectRoot/$rel').readAsLinesSync()) {
            final trimmed = line.trimLeft();
            if (!trimmed.startsWith('import ') &&
                !trimmed.startsWith('export ')) {
              continue;
            }
            if (trimmed.contains('package:cc_harness/src/')) {
              offenders.add('$rel → $trimmed');
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the old cc_domain harness paths stay dead (no resurrection)', () {
      // PRD 26.1 moved the harness feature out of cc_domain wholesale — no
      // delegating re-export shims were left behind. A new import of the old
      // paths means someone re-created a file there; the kernel is the only
      // home now.
      const tombstones = <String>[
        'package:cc_domain/features/harness/',
        'package:cc_domain/features/dispatch/domain/steering/',
        'package:cc_domain/core/utils/cancellation_token.dart',
        'package:cc_domain/features/model_routing/domain/value_objects/reasoning_effort.dart',
        'package:cc_domain/features/guardrails/domain/value_objects/action_class.dart',
      ];
      final offenders = <String>[];
      for (final root in ['lib', 'test', 'packages', 'apps']) {
        for (final rel in _dartFilesRelative(projectRoot, root)) {
          for (final line in File('$projectRoot/$rel').readAsLinesSync()) {
            final trimmed = line.trimLeft();
            if (!trimmed.startsWith('import ') &&
                !trimmed.startsWith('export ')) {
              continue;
            }
            for (final dead in tombstones) {
              if (trimmed.contains(dead)) {
                offenders.add('$rel → $trimmed');
              }
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the kernel facade stays curated (every export shows ≤45 symbols)', () {
      // lib/cc_harness.dart is a curated facade, not a dump: every export must
      // carry an explicit `show` list and the total stays small. The long tail
      // belongs in the topic entrypoints.
      final src = File(
        '$projectRoot/packages/cc_harness/lib/cc_harness.dart',
      ).readAsStringSync();
      // Strip comments, then collect export directives.
      final code = src.replaceAll(RegExp(r'///.*|//.*'), '');
      final exports = RegExp(
        r"export\s+'[^']+'\s*(show\s+([^;]+))?;",
      ).allMatches(code);
      expect(exports, isNotEmpty, reason: 'facade should export something');
      var symbols = 0;
      for (final m in exports) {
        expect(
          m.group(1),
          isNotNull,
          reason: 'facade export without a show list: ${m.group(0)}',
        );
        symbols += m.group(2)!.split(',').length;
      }
      expect(
        symbols,
        lessThanOrEqualTo(45),
        reason:
            'the facade grew to $symbols symbols — move the long tail to '
            'a topic entrypoint instead',
      );
    });
  });

  group('cc_harness_runtime package layering (PRD 26)', () {
    test('cc_harness_runtime imports only dart + cc_harness + crypto/path', () {
      // The runtime is "batteries for the kernel", VM-only but Control-Center
      // free: raw dart:io HTTP providers, OAuth/PKCE, credential stores, the
      // generic tool set. It must never import cc_domain/cc_infra/cc_natives —
      // CC-coupled adapters (sandboxed bash, MCP bridge, apply_patch, the
      // cc_natives file-search port) live in cc_infra instead.
      final allowed = RegExp(
        r"^(import|export)\s+'(dart:"
        r'|package:crypto/'
        r'|package:path/'
        r'|package:meta/'
        r'|package:cc_harness/'
        r'|package:cc_harness_runtime/'
        r'|src/|\.\./|[a-z_]+(/|\.dart))',
      );
      final offenders = <String>[];
      for (final rel in _dartFilesRelative(
        projectRoot,
        'packages/cc_harness_runtime/lib',
      )) {
        for (final line in File('$projectRoot/$rel').readAsLinesSync()) {
          final trimmed = line.trimLeft();
          if (!trimmed.startsWith('import ') &&
              !trimmed.startsWith('export ')) {
            continue;
          }
          if (!allowed.hasMatch(trimmed)) {
            offenders.add('$rel → $trimmed');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('clients never import the harness runtime (server-side only)', () {
      // The runtime executes commands and dials LLM providers — thin clients
      // must reach it only through server RPC. lib/ (the Flutter client),
      // cc_ui, cc_markdown, cc_rpc, cc_data and cc_remote stay runtime-free.
      final offenders = <String>[];
      for (final root in [
        'lib',
        'packages/cc_ui/lib',
        'packages/cc_markdown/lib',
        'packages/cc_rpc/lib',
        'packages/cc_data/lib',
        'apps/cc_remote/lib',
      ]) {
        for (final rel in _dartFilesRelative(projectRoot, root)) {
          for (final line in File('$projectRoot/$rel').readAsLinesSync()) {
            final trimmed = line.trimLeft();
            if (!trimmed.startsWith('import ') &&
                !trimmed.startsWith('export ')) {
              continue;
            }
            if (trimmed.contains('package:cc_harness_runtime/')) {
              offenders.add('$rel → $trimmed');
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('web build must not transitively reach native (FFI) code', () {
    test('no web-reachable library imports cc_natives / onnxruntime / dart:ffi', () {
      // The deployed web build (`flutter build web`) compiles the WEB branch of
      // every conditional import, starting at lib/main.dart. If any web-reachable
      // library imports dart:ffi — directly, or via `package:cc_natives` (which
      // owns the FFI bindings/loaders, including the cc_inference ones) — the CFE
      // aborts with "library 'dart:ffi' is not available on this platform" and
      // the whole web build fails. The error only names a package-level chain
      // (control_center => cc_natives), never the file, so it is painful to
      // diagnose by hand.
      //
      // This guard reproduces that exact reachability (BFS from lib/main.dart,
      // following the web branch of every conditional import/export) and fails
      // with the precise import chain, catching the leak in CI instead of in a
      // deploy. The classic cause: importing the `package:cc_infra/cc_infra.dart`
      // barrel (which re-exports code_extractor → cc_natives) from web-reachable
      // presentation/provider code. `show` does NOT help — the barrel is still
      // compiled. Fix: import the specific `package:cc_infra/src/<file>.dart`.
      final chains = _webReachableNativeSinks(projectRoot);
      expect(
        chains,
        isEmpty,
        reason:
            'The web build leaks native (FFI) code. Each chain below is a path '
            'from lib/main.dart (web branch) to a dart:ffi/onnxruntime/'
            'cc_natives import. Break the first app-owned edge that crosses into '
            'native code:\n\n${chains.join('\n\n')}',
      );
    });
  });

  group('file search runs on the server, never in a client', () {
    test('no library under lib/ constructs a cc_natives file searcher', () {
      // `cc_server` owns the repo checkouts, so it owns the search: the client
      // calls `repos.searchFiles` / `worktree.searchFiles` and renders the hits
      // (cc_domain's web-safe `FileSearchHit`). A client-side `FffFileSearch`
      // regressed this once — the composer's `@`-mention source searched
      // in-process, so every keystroke logged `FffUnavailable: libfff_c could
      // not be loaded` on a desktop whose app-support dylib was missing, while
      // the IDE Explorer (already server-backed) worked fine. A native the
      // client has no business loading must not be on the client's path at all.
      final offenders = <String>[];
      final searcher = RegExp(r'\b(Fff|Dart)FileSearch\b');
      for (final rel in _dartFilesRelative(projectRoot, 'lib')) {
        if (searcher.hasMatch(File('$projectRoot/$rel').readAsStringSync())) {
          offenders.add(rel);
        }
      }
      offenders.sort();
      expect(
        offenders,
        isEmpty,
        reason:
            'These client libraries reach a cc_natives file searcher. File '
            'search belongs to cc_server — call `repos.searchFiles` (see '
            'lib/features/messaging/providers/repo_file_search_provider.dart) '
            'instead:\n${offenders.join('\n')}',
      );
    });
  });

  group('enclosures (rigs) run on the server, never in a client', () {
    test('no library under lib/ imports the rig infrastructure', () {
      // A rig is a hypervisor process, a QMP socket and a per-session disk
      // overlay — all of it `dart:io` work that belongs to `cc_server`. The
      // client drives rigs through the `rig.*` RPC ops and watches frames over
      // `/rig/stream/<id>`; it must never construct a backend, a QMP client or
      // an ADB client itself. A hit here means the enclosure stack has crept
      // into the Flutter app, where it would fail on web outright and would
      // put a VM on the user's machine that no server knows about.
      // DERIVED from the source, not hand-listed. The hand-written regex named
      // nine symbols and `packages/cc_infra/lib/src/rigs/` exports far more:
      // `SmolvmEnclosureBackend`, `CdpClient`, `RigPortService`, `RigMachine`,
      // `HostFfmpeg` and `buildSmolvmCreateArgs` all passed the ratchet
      // untouched. A ban list that has to be updated by the same person adding
      // the thing it should ban is a ban list that drifts, so the set is read
      // off disk: every public top-level name in that directory is banned in
      // `lib/`, and a new file is covered the moment it exists.
      final banned = _publicTopLevelNames(
        Directory('$projectRoot/packages/cc_infra/lib/src/rigs'),
      );
      expect(
        banned,
        contains('QemuEnclosureBackend'),
        reason: 'the scan itself must be finding names',
      );
      final rigInfra = RegExp('\\b(${banned.join('|')})\\b');
      final offenders = <String>[];
      for (final rel in _dartFilesRelative(projectRoot, 'lib')) {
        // Comments are stripped first. A doc comment that NAMES a rig type to
        // explain why the client does not use it is exactly the sort of
        // helpful sentence this check should not punish, and punishing it
        // teaches people to stop writing them.
        final source = _withoutCommentLines(
          File('$projectRoot/$rel').readAsStringSync(),
        );
        final hit = rigInfra.firstMatch(source);
        if (hit != null) {
          offenders.add('$rel (${hit.group(1)})');
        }
      }
      offenders.sort();
      expect(
        offenders,
        isEmpty,
        reason:
            'These client libraries reach rig infrastructure. Enclosures '
            'belong to cc_server — use the `rig.*` RPC ops through '
            'RemoteRigRepository instead:\n${offenders.join('\n')}',
      );
    });

    test('the rig domain layer stays free of dart:io', () {
      // Same rule the rest of cc_domain lives under: the shared kernel is
      // imported by the Flutter client AND the Flutter-free server binary, so
      // a `dart:io` import in the rig domain would break the web build for a
      // feature the web can legitimately watch.
      final offenders = <String>[];
      final rigDomain = Directory(
        '$projectRoot/packages/cc_domain/lib/features/rigs',
      );
      if (rigDomain.existsSync()) {
        for (final file in rigDomain
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
          final src = file.readAsStringSync();
          if (src.contains("import 'dart:io'") ||
              src.contains("import 'dart:ffi'") ||
              src.contains("import 'package:flutter/")) {
            offenders.add(file.path.replaceFirst('$projectRoot/', ''));
          }
        }
      }
      offenders.sort();
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('desktop must not host the MCP server or own a database', () {
    test('no desktop-reachable library imports cc_server_core / cc_host / '
        'cc_persistence / cc_mcp', () {
      // The desktop is a thin client exactly like web: it spawns/connects to a
      // `cc_server` over RPC and never builds the MCP tool registry, the
      // in-process RPC catalog, or a Drift database itself. This guard
      // reproduces the same BFS as the web guard above, but over the DEFAULT
      // (desktop/io) branch of every conditional import starting at
      // lib/main.dart and flags the four server-only packages instead of the
      // native-code sinks. A hit here means the in-process server stack has
      // crept back into the Flutter app.
      final chains = _ioReachableServerSinks(projectRoot);
      expect(
        chains,
        isEmpty,
        reason:
            'The desktop build reaches server-only code. Each chain below is a '
            'path from lib/main.dart (desktop/io branch) to a cc_server_core/'
            'cc_host/cc_persistence/cc_mcp import. That code belongs in the '
            'spawned cc_server, reached over rpcClientProvider — break the '
            'first app-owned edge that crosses into it:\n\n${chains.join('\n\n')}',
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

/// All first-party `.dart` files under `dirPath` (recursive), excluding
/// generated files, as paths relative to `projectRoot` using forward slashes.
///
/// A manual walk, NOT `listSync(recursive: true)`: the recursive form follows
/// symlinks and the tree contains cyclic/huge link farms that made this test
/// consume tens of GB of RAM — agent skill symlinks and repo worktrees under
/// `apps/cc_server/data/` (live server data), plugin `.symlinks` under
/// `ephemeral/` and pub/tool state under dot-directories. Those are pruned:
/// none of them are first-party sources this suite should ratchet.
/// [source] with whole-line `//` comments and `/* … */` blocks removed.
///
/// Deliberately only WHOLE-LINE comments: stripping a trailing `//` would also
/// cut everything after the `//` in a URL string literal, which could hide a
/// real hit on that line. A pure comment line has no code to lose.
String _withoutCommentLines(String source) {
  final withoutBlocks = source.replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    ' ',
  );
  return [
    for (final line in withoutBlocks.split('\n'))
      if (!line.trimLeft().startsWith('//')) line,
  ].join('\n');
}

/// Every PUBLIC top-level declaration in the `.dart` files directly under
/// [dir], as a sorted, de-duplicated name list.
///
/// Deliberately source-level regex rather than the analyzer: this runs in the
/// app's own test suite, where pulling in `package:analyzer` to read a
/// neighbouring package would be a heavier dependency than the check.
/// Over-matching is safe here (an extra banned name can only make the ratchet
/// stricter); under-matching is what the hand-written list already did.
List<String> _publicTopLevelNames(Directory dir) {
  if (!dir.existsSync()) {
    return const [];
  }
  final declaration = RegExp(
    r'^(?:abstract\s+|final\s+|base\s+|interface\s+|sealed\s+|mixin\s+)*'
    r'(?:class|enum|extension|mixin|typedef)\s+([A-Z]\w*)',
    multiLine: true,
  );
  // Top-level functions and constants: a return type / `const` / `final` at
  // column zero followed by an identifier and `(` or `=`.
  final topLevelValue = RegExp(
    r'^(?:const|final|[A-Za-z_][\w<>,\s?]*?)\s+([a-z]\w*)\s*(?:\(|=)',
    multiLine: true,
  );
  final names = <String>{};
  for (final file in dir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.dart')) {
      continue;
    }
    final source = file.readAsStringSync();
    for (final match in declaration.allMatches(source)) {
      names.add(match.group(1)!);
    }
    for (final match in topLevelValue.allMatches(source)) {
      final name = match.group(1)!;
      // Skip Dart keywords that can start a line-anchored match.
      if (const {'return', 'if', 'for', 'while', 'switch', 'await', 'yield'}
          .contains(name)) {
        continue;
      }
      names.add(name);
    }
  }
  final sorted = names.where((n) => !n.startsWith('_')).toList()..sort();
  return sorted;
}

Iterable<String> _dartFilesRelative(String projectRoot, String dirPath) sync* {
  final root = Directory('$projectRoot/$dirPath');
  if (!root.existsSync()) {
    return;
  }
  String relOf(String path) =>
      path.substring(projectRoot.length + 1).replaceAll(r'\', '/');
  final pending = <Directory>[root];
  while (pending.isNotEmpty) {
    final dir = pending.removeLast();
    // followLinks: false — symlinks come back as Link entities (skipped), so
    // a link cycle can never recurse.
    for (final entity in dir.listSync(followLinks: false)) {
      final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (entity is Directory) {
        // Never source: hidden dirs (.git/.dart_tool/.agents/…), build
        // output, Flutter's ephemeral plugin scaffolding and the server's
        // runtime data root (agent homes, worktrees, skill links).
        if (name.startsWith('.') || name == 'build' || name == 'ephemeral') {
          continue;
        }
        if (relOf(entity.path) == 'apps/cc_server/data') {
          continue;
        }
        pending.add(entity);
      } else if (entity is File) {
        final path = entity.path;
        if (!path.endsWith('.dart') ||
            path.endsWith('.g.dart') ||
            path.endsWith('.mocks.dart')) {
          continue;
        }
        yield relOf(path);
      }
    }
  }
}

/// Every `packages/cc_domain` directory named `leaf` under a domain layer:
/// `core/domain/<leaf>` plus `features/*/domain/<leaf>`.
///
/// The shared kernel is where entities, value objects and repository
/// interfaces actually live since the backend exodus; the guards that still
/// pointed at `lib/` were scanning directories that no longer exist.
List<Directory> _domainDirs(String projectRoot, String leaf) {
  final dirs = <Directory>[];
  final core = Directory('$projectRoot/packages/cc_domain/lib/core/domain/$leaf');
  if (core.existsSync()) {
    dirs.add(core);
  }
  final features = Directory('$projectRoot/packages/cc_domain/lib/features');
  if (features.existsSync()) {
    for (final feature in features.listSync().whereType<Directory>()) {
      final dir = Directory('${feature.path}/domain/$leaf');
      if (dir.existsSync()) {
        dirs.add(dir);
      }
    }
  }
  return dirs;
}

/// Enforces a shrinking-allowlist ratchet for imports matching [pattern].
///
/// Like [_assertVendorRatchet] but matches a RegExp (used for the cross-layer
/// import bans, e.g. `import ... /data/` or `import ... features/`). Fails on a
/// NEW offender outside [allowlistPath], or on a STALE allowlist entry that no
/// longer matches (so the list mirrors the real migration state).
void _assertImportRegexRatchet({
  required String projectRoot,
  required String scanDir,
  required Pattern pattern,
  required String allowlistPath,
  required String description,
  bool Function(String rel)? includeFile,
}) {
  final allow = _readAllowlist(projectRoot, allowlistPath);
  final stale = <String>{...allow};
  final offenders = <String>[];
  for (final rel in _dartFilesRelative(projectRoot, scanDir)) {
    if (includeFile != null && !includeFile(rel)) {
      continue;
    }
    final content = File('$projectRoot/$rel').readAsStringSync();
    if (content.contains(pattern)) {
      stale.remove(rel);
      if (!allow.contains(rel)) {
        offenders.add(rel);
      }
    }
  }
  offenders.sort();
  final staleList = stale.toList()..sort();
  expect(
    offenders,
    isEmpty,
    reason:
        'New violation of "$description" outside the allowlist '
        '($allowlistPath):\n${offenders.join('\n')}',
  );
  expect(
    staleList,
    isEmpty,
    reason:
        'Stale allowlist entries for "$description" (no longer violate — remove '
        'from $allowlistPath):\n${staleList.join('\n')}',
  );
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

/// Material component widgets that have a cc_ui counterpart, mapped to the
/// replacement named in the failure message. Keys are matched as whole Dart
/// identifiers followed by `(` or `.`, so `CcDivider(`, `_SkillsListTile(` and
/// `TextButtonThemeData` never trip — but `TextButton(`, `Divider(` and
/// `CircularProgressIndicator.adaptive(` all do.
const _materialComponentReplacements = <String, String>{
  'TextButton': 'CcButton(variant: CcButtonVariant.ghost)',
  'ElevatedButton': 'CcButton',
  'OutlinedButton': 'CcButton(variant: CcButtonVariant.secondary)',
  'FilledButton': 'CcButton',
  'IconButton': 'CcIconButton',
  'Card': 'CcCard',
  'Chip': 'CcChip',
  'InputChip': 'CcChip(selected:, onPressed:)',
  'ActionChip': 'CcChip(onPressed:)',
  'FilterChip': 'CcChip(selected:)',
  'ChoiceChip': 'CcChip(selected:)',
  'Divider': 'CcDivider',
  'VerticalDivider': 'CcDivider(axis: Axis.vertical)',
  'ListTile': 'CcTile',
  'CircularProgressIndicator': 'CcSpinner',
  'LinearProgressIndicator': 'CcProgressBar',
  'Switch': 'CcSwitch',
  'Checkbox': 'CcCheckbox',
  'Radio': 'CcRadio',
  'Tooltip': 'CcTooltip',
  'AlertDialog': 'showCcDialog / CcDialog',
  'SimpleDialog': 'showCcDialog / CcDialog',
  'PopupMenuButton': 'CcMenu',
  'DropdownButton': 'CcSelect',
  'SegmentedButton': 'CcSegmentedToggle',
  'ExpansionTile': 'CcTile + a disclosure row',
  'DataTable': 'Table (flutter/widgets.dart) with token-styled cells',
  'ToggleButtons': 'CcSegmentedToggle',
  'TextField': 'CcTextField (pass chromeless: true for an undecorated input)',
  'TextFormField': 'CcTextFormField',
  'InputDecoration': 'CcTextField hintText/label/prefix/suffix + chromeless',
  'Slider': 'CcSlider',
  'RangeSlider': 'two CcSliders, or extend CcSlider',
};

/// Bans Material component widgets under [scanDir], allowing only the files
/// listed in `material_components.txt` (each with a documented reason).
void _assertNoMaterialComponents({
  required String projectRoot,
  required String scanDir,
}) {
  const allowlistPath =
      'test/core/migration_allowlists/material_components.txt';
  final allow = _readAllowlist(projectRoot, allowlistPath);
  final patterns = <String, RegExp>{
    for (final name in _materialComponentReplacements.keys)
      name: RegExp('(?<![A-Za-z0-9_\$])$name(?![A-Za-z0-9_])\\s*[(.]'),
  };
  final stale = <String>{...allow};
  final offenders = <String>[];
  for (final rel in _dartFilesRelative(projectRoot, scanDir)) {
    // Generated localizations are not hand-authored UI.
    if (rel.startsWith('lib/l10n/')) {
      continue;
    }
    final source = File('$projectRoot/$rel').readAsStringSync();
    // Strip line comments and string literals so prose and copy never trip.
    final body = source
        .replaceAll(RegExp('//[^\n]*'), '')
        .replaceAll(RegExp(r"'(?:[^'\\\n]|\\.)*'"), "''")
        .replaceAll(RegExp(r'"(?:[^"\\\n]|\\.)*"'), '""');
    final found = <String>[];
    patterns.forEach((name, pattern) {
      if (pattern.hasMatch(body)) {
        found.add(name);
      }
    });
    if (found.isEmpty) {
      continue;
    }
    stale.remove(rel);
    if (!allow.contains(rel)) {
      found.sort();
      offenders.add(
        '$rel\n'
        '${found.map((n) => '    $n -> use ${_materialComponentReplacements[n]}').join('\n')}',
      );
    }
  }
  final staleList = stale.toList()..sort();
  expect(
    offenders,
    isEmpty,
    reason:
        'Material components must come from cc_ui. Replace these with their '
        'design-system counterpart (or, if cc_ui genuinely has no equivalent, '
        'add the file to $allowlistPath with a reason):\n'
        '${offenders.join('\n')}',
  );
  expect(
    staleList,
    isEmpty,
    reason:
        'Stale $allowlistPath entries (no longer use a banned Material '
        'component — remove them so the list stays honest):\n'
        '${staleList.join('\n')}',
  );
}

// ---------------------------------------------------------------------------
// Web-reachability guard: detect any native (FFI) import the web build pulls in.
// ---------------------------------------------------------------------------

/// `dart.library.*` conditions that resolve to TRUE on a web (js) target, so the
/// conditional-import branch guarded by one of these is the one the web build
/// actually compiles.
const _webTrueConditions = <String>{
  'dart.library.js_interop',
  'dart.library.html',
  'dart.library.js',
  'dart.library.web',
};

/// Import-directive URIs that, if imported by any web-reachable library, break
/// `flutter build web` with "library 'dart:ffi' is not available". These are the
/// actual compile-breakers. `cc_natives` is the FFI leaf package, but it also
/// holds a few genuinely FFI-free files (e.g. `native_library_paths.dart`), so
/// the package boundary itself is NOT the sink — the BFS walks INTO cc_natives
/// and flags only the files that truly reach one of these. Importing the
/// `cc_natives.dart` / `cc_infra.dart` barrels is still caught, because those
/// barrels transitively re-export files that import `dart:ffi`.
bool _isNativeSinkUri(String uri) =>
    uri == 'dart:ffi' ||
    // Kept after the pub packages were replaced by the in-repo Rust crate: a
    // reintroduced dependency on either would put an FFI sink back on the web
    // graph and the failure (a CFE abort naming only a package chain) is
    // painful enough to be worth guarding against permanently.
    uri.startsWith('package:onnxruntime') ||
    uri.startsWith('package:sherpa_onnx');

/// Maps each workspace package name to the absolute path of its `lib/` dir,
/// read from `.dart_tool/package_config.json`. External (pub-cache) packages are
/// omitted — they are never traversed; a native import inside them is still
/// caught by [_isNativeSinkUri] on the directive that names the package.
Map<String, String> _workspacePackageLibDirs(String projectRoot) {
  final cfg = File('$projectRoot/.dart_tool/package_config.json');
  final json = jsonDecode(cfg.readAsStringSync()) as Map<String, dynamic>;
  final configDir = Uri.directory('$projectRoot/.dart_tool/');
  final out = <String, String>{};
  for (final entry in (json['packages'] as List)) {
    final pkg = entry as Map<String, dynamic>;
    final name = pkg['name'] as String;
    final rootUri = pkg['rootUri'] as String;
    final packageUri = (pkg['packageUri'] as String?) ?? 'lib/';
    // rootUri/packageUri are directories relative to the package_config.json
    // location (.dart_tool/); normalize trailing slashes so resolution does not
    // produce doubled separators (e.g. rootUri '../' for the root package).
    String dir(String u) => u.endsWith('/') ? u : '$u/';
    final root = configDir.resolveUri(Uri.parse(dir(rootUri)));
    final libDir = root.resolveUri(Uri.parse(dir(packageUri)));
    final libPath = libDir.toFilePath();
    // Only keep packages that live inside the repo (the workspace). External
    // packages resolve into the pub cache and must not be walked.
    if (libPath.startsWith('$projectRoot/')) {
      out[name] = libPath.endsWith('/')
          ? libPath.substring(0, libPath.length - 1)
          : libPath;
    }
  }
  return out;
}

/// Strips `//` line comments and `/* */` block comments so directive prose in
/// doc comments cannot be mistaken for real imports.
String _stripDartComments(String src) {
  final noBlock = src.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return noBlock.replaceAll(RegExp(r'//[^\n]*'), '');
}

// Group numbering (named groups count): 1=outer quote, 2=main, 3=conds,
// 4=inner quote. The inner-quote backref must be \4, not \3.
final _directiveRe = RegExp(
  r'''(?:import|export)\s+(['"])(?<main>[^'"]+)\1'''
  r'''(?<conds>(?:\s+if\s*\([^)]*\)\s*(['"])[^'"]+\4)*)''',
);
final _condRe = RegExp(
  r'''if\s*\(\s*(?<cond>[^)]*?)\s*\)\s*(['"])(?<uri>[^'"]+)\2''',
);

/// The URI a single import/export directive resolves to on a WEB target: the
/// first conditional branch whose condition is web-true, else the default URI.
String _webResolvedUri(RegExpMatch directive) {
  final conds = directive.namedGroup('conds') ?? '';
  for (final cm in _condRe.allMatches(conds)) {
    if (_webTrueConditions.contains(cm.namedGroup('cond'))) {
      return cm.namedGroup('uri')!;
    }
  }
  return directive.namedGroup('main')!;
}

/// Resolves an import URI from [fromFile] to an absolute on-disk path of a
/// workspace `.dart` file, or `null` if it is a `dart:`/external/unresolvable
/// URI (those are not traversed; sinks among them are caught separately).
String? _resolveToWorkspaceFile(
  String uri,
  String fromFile,
  Map<String, String> pkgLibDirs,
) {
  if (uri.startsWith('dart:')) {
    return null;
  }
  if (uri.startsWith('package:')) {
    final body = uri.substring('package:'.length);
    final slash = body.indexOf('/');
    if (slash < 0) {
      return null;
    }
    final pkg = body.substring(0, slash);
    final rest = body.substring(slash + 1);
    final libDir = pkgLibDirs[pkg];
    if (libDir == null) {
      return null; // external package — not walked
    }
    return Uri.file('$libDir/').resolve(rest).toFilePath();
  }
  // Relative import — resolve against the importing file's directory.
  final fromUri = Uri.file(fromFile);
  return fromUri.resolve(uri).toFilePath();
}

/// BFS from `lib/main.dart` over the WEB import graph. Returns one rendered
/// chain string per file that imports a native sink, e.g.:
///
///     lib/main.dart
///       → lib/bootstrap/bootstrap_web.dart
///       → ... → lib/features/foo.dart
///       ⇒ package:cc_natives/... (native sink)
///
/// Empty list means the web build pulls in zero native code.
List<String> _webReachableNativeSinks(String projectRoot) {
  final pkgLibDirs = _workspacePackageLibDirs(projectRoot);
  final start = '$projectRoot/lib/main.dart';
  final parent = <String, String?>{start: null};
  final queue = <String>[start];
  final sinks = <String, String>{}; // file -> the native URI it imports

  var head = 0;
  while (head < queue.length) {
    final file = queue[head++];
    final raw = File(file).existsSync()
        ? _stripDartComments(File(file).readAsStringSync())
        : '';
    var isSink = false;
    final children = <String>[];
    for (final directive in _directiveRe.allMatches(raw)) {
      final uri = _webResolvedUri(directive);
      if (_isNativeSinkUri(uri)) {
        sinks[file] = uri;
        isSink = true;
        break; // this file already fails to compile on web; stop here
      }
      final child = _resolveToWorkspaceFile(uri, file, pkgLibDirs);
      if (child != null) {
        children.add(child);
      }
    }
    if (isSink) {
      continue; // do not expand past a sink
    }
    for (final child in children) {
      if (!parent.containsKey(child) && File(child).existsSync()) {
        parent[child] = file;
        queue.add(child);
      }
    }
  }

  String rel(String abs) => abs.startsWith('$projectRoot/')
      ? abs.substring(projectRoot.length + 1)
      : abs;

  final rendered = <String>[];
  for (final entry in sinks.entries) {
    final steps = <String>[];
    String? cur = entry.key;
    while (cur != null) {
      steps.add(rel(cur));
      cur = parent[cur];
    }
    final chain = steps.reversed.toList();
    final buf = StringBuffer();
    for (var i = 0; i < chain.length; i++) {
      buf.writeln(i == 0 ? chain[i] : '  ${'  ' * i}→ ${chain[i]}');
    }
    buf.write('  ${'  ' * chain.length}⇒ ${entry.value}  (native sink)');
    rendered.add(buf.toString());
  }
  rendered.sort();
  return rendered;
}

// ---------------------------------------------------------------------------
// Desktop-reachability guard: detect any server-only package the desktop
// (default/io) branch pulls in — the in-process MCP/RPC/database stack.
// ---------------------------------------------------------------------------

/// Import-directive URIs that, if imported by any desktop-reachable library,
/// mean the in-process server stack (MCP registry, RPC catalog, or Drift
/// database) has crept back into the Flutter app. These four packages are
/// reserved for the headless `cc_server` binary.
bool _isServerSinkUri(String uri) =>
    uri.startsWith('package:cc_server_core') ||
    uri.startsWith('package:cc_host') ||
    uri.startsWith('package:cc_persistence') ||
    uri.startsWith('package:cc_mcp');

/// The URI a single import/export directive resolves to on the DESKTOP (io)
/// target: every conditional branch in this codebase guards a WEB override
/// (`if (dart.library.js_interop) '..._web.dart'`), so the desktop/io branch
/// is always the unconditioned default URI — no condition needs evaluating.
String _ioResolvedUri(RegExpMatch directive) => directive.namedGroup('main')!;

/// BFS from `lib/main.dart` over the DESKTOP (io) import graph — the same
/// walk as [_webReachableNativeSinks], but resolving the default branch of
/// each conditional import and flagging [_isServerSinkUri] hits instead of
/// native-code sinks. Empty list means the desktop build pulls in zero
/// server-only code.
List<String> _ioReachableServerSinks(String projectRoot) {
  final pkgLibDirs = _workspacePackageLibDirs(projectRoot);
  final start = '$projectRoot/lib/main.dart';
  final parent = <String, String?>{start: null};
  final queue = <String>[start];
  final sinks = <String, String>{}; // file -> the server-only URI it imports

  var head = 0;
  while (head < queue.length) {
    final file = queue[head++];
    final raw = File(file).existsSync()
        ? _stripDartComments(File(file).readAsStringSync())
        : '';
    var isSink = false;
    final children = <String>[];
    for (final directive in _directiveRe.allMatches(raw)) {
      final uri = _ioResolvedUri(directive);
      if (_isServerSinkUri(uri)) {
        sinks[file] = uri;
        isSink = true;
        break; // this file already reaches server-only code; stop here
      }
      final child = _resolveToWorkspaceFile(uri, file, pkgLibDirs);
      if (child != null) {
        children.add(child);
      }
    }
    if (isSink) {
      continue; // do not expand past a sink
    }
    for (final child in children) {
      if (!parent.containsKey(child) && File(child).existsSync()) {
        parent[child] = file;
        queue.add(child);
      }
    }
  }

  String rel(String abs) => abs.startsWith('$projectRoot/')
      ? abs.substring(projectRoot.length + 1)
      : abs;

  final rendered = <String>[];
  for (final entry in sinks.entries) {
    final steps = <String>[];
    String? cur = entry.key;
    while (cur != null) {
      steps.add(rel(cur));
      cur = parent[cur];
    }
    final chain = steps.reversed.toList();
    final buf = StringBuffer();
    for (var i = 0; i < chain.length; i++) {
      buf.writeln(i == 0 ? chain[i] : '  ${'  ' * i}→ ${chain[i]}');
    }
    buf.write('  ${'  ' * chain.length}⇒ ${entry.value}  (server sink)');
    rendered.add(buf.toString());
  }
  rendered.sort();
  return rendered;
}
