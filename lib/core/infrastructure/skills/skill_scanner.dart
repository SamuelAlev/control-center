import 'dart:io';

import 'package:path/path.dart' as p;

class DiscoveredSkill {
  const DiscoveredSkill({
    required this.slug,
    required this.directory,
    required this.skillFilePath,
    this.name,
    this.description,
    this.framework,
  });

  final String slug;
  final String directory;
  final String skillFilePath;
  final String? name;
  final String? description;
  final String? framework;
}

class SkillScanner {
  static const _scanRoots = <(String, String)>[
    ('.agents/skills', 'agents'),
    ('.agent/skills', 'agent'),
    ('.claude/skills', 'claude'),
    ('.kilo/skills', 'kilo'),
    ('.pi/skills', 'pi'),
    ('.augment/skills', 'augment'),
    ('.continue/skills', 'continue'),
    ('.cursor/skills', 'cursor'),
    ('.windsurf/skills', 'windsurf'),
    ('.roo/skills', 'roo'),
    ('.opencode/skills', 'opencode'),
    ('.codebuddy/skills', 'codebuddy'),
    ('.goose/skills', 'goose'),
    ('.junie/skills', 'junie'),
    ('.kiro/skills', 'kiro'),
    ('.kode/skills', 'kode'),
    ('.trae/skills', 'trae'),
    ('.zencoder/skills', 'zencoder'),
    ('.neovate/skills', 'neovate'),
    ('.adal/skills', 'adal'),
  ];

  Future<List<DiscoveredSkill>> scan(String projectRoot) async {
    final root = Directory(projectRoot);
    if (!root.existsSync()) {
      return [];
    }

    final skills = <DiscoveredSkill>[];
    for (final (relPath, framework) in _scanRoots) {
      final dir = Directory(p.join(projectRoot, relPath));
      if (!dir.existsSync()) {
        continue;
      }
      await _scanDirectory(dir, framework, skills);
    }
    return skills;
  }

  Future<void> _scanDirectory(
    Directory dir,
    String framework,
    List<DiscoveredSkill> skills,
  ) async {
    await for (final entity in dir.list()) {
      if (entity is! Directory) {
        continue;
      }
      final slug = p.basename(entity.path);
      final skillFile = File(p.join(entity.path, 'SKILL.md'));
      if (skillFile.existsSync()) {
        final metadata = _parseFrontmatter(skillFile);
        skills.add(DiscoveredSkill(
          slug: slug,
          directory: entity.path,
          skillFilePath: skillFile.path,
          name: metadata['name'],
          description: metadata['description'],
          framework: framework,
        ));
      }
    }
  }

  Map<String, String> _parseFrontmatter(File file) {
    final content = file.readAsStringSync();
    final result = <String, String>{};
    if (!content.startsWith('---')) {
      return result;
    }
    final end = content.indexOf('---', 3);
    if (end < 0) {
      return result;
    }
    final frontmatter = content.substring(3, end).trim();
    for (final line in frontmatter.split('\n')) {
      final colon = line.indexOf(':');
      if (colon < 0) {
        continue;
      }
      final key = line.substring(0, colon).trim();
      var value = line.substring(colon + 1).trim();
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      if (value.startsWith("'") && value.endsWith("'")) {
        value = value.substring(1, value.length - 1);
      }
      result[key] = value;
    }
    return result;
  }
}
