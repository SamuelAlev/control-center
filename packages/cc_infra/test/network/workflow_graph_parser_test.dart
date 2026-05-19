import 'package:cc_infra/src/network/workflow_graph_parser.dart';
import 'package:test/test.dart';

void main() {
  group('workflowGraphFromYaml', () {
    test('parses jobs with scalar and list needs forms', () {
      final graph = workflowGraphFromYaml('''
name: CI
on: push
jobs:
  build:
    name: Build
    runs-on: ubuntu-latest
  test:
    name: Test
    needs: build
    runs-on: ubuntu-latest
  deploy:
    needs: [build, test]
''');
      expect(graph, isNotNull);
      expect(graph!.name, 'CI');
      expect(graph.jobs, hasLength(3));
      expect(graph.jobs[0].id, 'build');
      expect(graph.jobs[0].name, 'Build');
      expect(graph.jobs[0].needs, isEmpty);
      expect(graph.jobs[1].needs, ['build']);
      expect(graph.jobs[2].needs, ['build', 'test']);
    });

    test('falls back to the job id when name: is missing', () {
      final graph = workflowGraphFromYaml('''
jobs:
  lint:
    runs-on: ubuntu-latest
''');
      expect(graph!.jobs.single.id, 'lint');
      expect(graph.jobs.single.name, 'lint');
    });

    test('ignores strategy/matrix keys and keeps only the graph fields', () {
      final graph = workflowGraphFromYaml('''
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu, macos]
    needs: setup
  setup:
    runs-on: ubuntu-latest
''');
      expect(graph!.jobs, hasLength(2));
      expect(graph.jobs[0].id, 'test');
      expect(graph.jobs[0].needs, ['setup']);
    });

    test('returns null when jobs is not a map', () {
      expect(workflowGraphFromYaml('jobs: [a, b]'), isNull);
    });

    test('returns null when there is no jobs key', () {
      expect(workflowGraphFromYaml('name: CI\non: push\n'), isNull);
    });

    test('returns null for malformed YAML', () {
      expect(workflowGraphFromYaml('jobs: [unclosed'), isNull);
    });

    test('returns null for a non-map document', () {
      expect(workflowGraphFromYaml('- just\n- a\n- list\n'), isNull);
    });

    test('skips job entries whose body is not a map', () {
      final graph = workflowGraphFromYaml('''
jobs:
  build:
    runs-on: ubuntu-latest
  weird: "just a string"
''');
      expect(graph!.jobs, hasLength(1));
      expect(graph.jobs.single.id, 'build');
    });
  });
}
