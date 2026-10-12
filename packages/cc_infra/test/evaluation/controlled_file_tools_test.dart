import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';
import 'package:cc_infra/src/evaluation/controlled_file_tools.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'controlled tools read, write, edit, find and search real files',
    () async {
      if (ControlledEvaluationProcess.capabilityReason() != null) return;
      final fixture = await _Fixture.create();
      try {
        final write = await fixture.call('write', {
          'path': 'notes/a.txt',
          'content': 'alpha\nbeta\n',
        });
        expect(write.isError, isFalse, reason: write.content);
        expect(write.content, contains('Created'));
        // A candidate file must not shadow the adapter's stdlib imports.
        await File(
          p.join(fixture.root.path, 'json.py'),
        ).writeAsString('raise RuntimeError(\"candidate module loaded\")');
        final read = await fixture.call('read', {
          'path': 'notes/a.txt',
          'offset': 2,
          'limit': 1,
        });
        expect(read.isError, isFalse, reason: read.content);
        expect(read.content, contains('2\tbeta'));
        expect(read.content, isNot(contains('1\talpha')));
        final edit = await fixture.call('edit', {
          'path': 'notes/a.txt',
          'old_text': 'beta',
          'new_text': 'gamma',
        });
        expect(edit.isError, isFalse, reason: edit.content);
        expect(
          await File(p.join(fixture.root.path, 'notes/a.txt')).readAsString(),
          'alpha\ngamma\n',
        );
        final find = await fixture.call('find', {'pattern': '**/*.txt'});
        expect(find.content, contains('notes/a.txt'));
        final search = await fixture.call('search', {
          'pattern': 'gamma',
          'path': 'notes',
          'glob': '*.txt',
        });
        expect(search.content, contains('notes/a.txt:2:gamma'));
      } finally {
        await fixture.close();
      }
    },
  );

  test(
    'controlled shell never resolves a model-supplied cwd on the host',
    () async {
      if (ControlledEvaluationProcess.capabilityReason() != null) return;
      final fixture = await _Fixture.create();
      try {
        final result = await fixture.call('bash', {
          'command': 'pwd',
          'description': 'Inspect working directory',
          'cwd': p.join(fixture.parent.path, 'outside'),
        });
        expect(result.isError, isTrue);
        expect(result.content, contains('cwd cannot be set'));
      } finally {
        await fixture.close();
      }
    },
  );

  test('dangling and changed symlinks never create a host target', () async {
    if (ControlledEvaluationProcess.capabilityReason() != null) return;
    final fixture = await _Fixture.create();
    try {
      final host = File(p.join(fixture.parent.path, 'host-target'));
      final link = Link(p.join(fixture.root.path, 'link.txt'));
      await link.create(host.path);
      final denied = await fixture.call('write', {
        'path': 'link.txt',
        'content': 'escaped',
      });
      expect(denied.isError, isTrue);
      expect(await host.exists(), isFalse);
      await link.delete();
      await File(link.path).writeAsString('safe');
      expect(
        (await fixture.call('read', {'path': 'link.txt'})).isError,
        isFalse,
      );
      await File(link.path).delete();
      await link.create(host.path);
      final changed = await fixture.call('edit', {
        'path': 'link.txt',
        'old_text': 'safe',
        'new_text': 'escaped',
      });
      expect(changed.isError, isTrue);
      expect(await host.exists(), isFalse);
      expect(
        (await fixture.call('read', {'path': 'link.txt'})).isError,
        isTrue,
      );
    } finally {
      await fixture.close();
    }
  });

  test('sparse and oversized reads and searches stay bounded', () async {
    if (ControlledEvaluationProcess.capabilityReason() != null) return;
    final fixture = await _Fixture.create();
    try {
      final sparse = File(p.join(fixture.root.path, 'sparse.txt'));
      final handle = await sparse.open(mode: FileMode.write);
      await handle.truncate(1024 * 1024 * 1024);
      await handle.close();
      final denied = await fixture.call('read', {'path': 'sparse.txt'});
      expect(denied.isError, isTrue);
      expect(denied.content, contains('1 MiB'));
      final search = await fixture.call('search', {'pattern': 'needle'});
      expect(search.isError, isFalse, reason: search.content);
      expect(search.content, contains('No matches'));
      final giantLine = File(p.join(fixture.root.path, 'giant.txt'));
      await giantLine.writeAsString('a' * 20000);
      final window = await fixture.call('read', {'path': 'giant.txt'});
      expect(window.isError, isTrue);
      expect(window.content.length, lessThan(1024));
    } finally {
      await fixture.close();
    }
  });

  test('protected skill package denies direct and aliased writes', () async {
    if (ControlledEvaluationProcess.capabilityReason() != null) return;
    final fixture = await _Fixture.create();
    try {
      final package = await Directory(
        p.join(fixture.root.path, '.agents', 'skills', 'example'),
      ).create(recursive: true);
      final body = File(p.join(package.path, 'SKILL.md'));
      await body.writeAsString('original');
      final alias = Link(p.join(fixture.root.path, 'alias.md'));
      await alias.create(body.path);
      for (final path in ['.agents/skills/example/SKILL.md', 'alias.md']) {
        expect(
          (await fixture.call('write', {
            'path': path,
            'content': 'mutated',
          })).isError,
          isTrue,
        );
        expect(
          (await fixture.call('edit', {
            'path': path,
            'old_text': 'original',
            'new_text': 'mutated',
          })).isError,
          isTrue,
        );
      }
      expect(await body.readAsString(), 'original');
      final read = await fixture.call('read', {
        'path': '.agents/skills/example/SKILL.md',
      });
      expect(read.isError, isFalse, reason: read.content);
      expect(read.content, contains('original'));
    } finally {
      await fixture.close();
    }
  });
}

class _Fixture {
  _Fixture(this.parent, this.root, this.tools);
  final Directory parent;
  final Directory root;
  final Map<String, HarnessTool> tools;

  static Future<_Fixture> create() async {
    final parent = await Directory.systemTemp.createTemp(
      'cc-controlled-tools-',
    );
    final root = await Directory(p.join(parent.path, 'work')).create();
    final home = await Directory(p.join(parent.path, 'home')).create();
    await Directory(p.join(root.path, '.agents')).create();
    final process = ControlledEvaluationProcess(
      root: root.path,
      home: home.path,
      readOnlyRoots: [p.join(root.path, '.agents')],
    );
    return _Fixture(parent, root, {
      for (final tool in controlledFileTools(process)) tool.name: tool,
      'bash': ControlledEvaluationBashTool(process),
    });
  }

  Future<HarnessToolResult> call(String name, Map<String, dynamic> args) =>
      tools[name]!.execute(
        args,
        HarnessToolContext(workingDirectory: root.path),
      );

  Future<void> close() => parent.delete(recursive: true);
}
