import 'package:cc_infra/src/rigs/environment_rig_compose.dart';
import 'package:test/test.dart';

void main() {
  group('interpolateCompose follows compose', () {
    const vars = {'TAG': '1.2', 'EMPTY': '', 'NAME': 'web'};

    String run(String text) => interpolateCompose(text, vars);

    test(r'$VAR and ${VAR}', () {
      expect(run(r'node:$TAG'), 'node:1.2');
      expect(run(r'node:${TAG}-alpine'), 'node:1.2-alpine');
      expect(run(r'node:$UNSET'), 'node:');
    });

    test(r'$$ is a literal dollar', () {
      expect(run(r'echo $$TAG'), r'echo $TAG');
    });

    test(':- defaults when unset or empty, - only when unset', () {
      expect(run(r'${UNSET:-x}'), 'x');
      expect(run(r'${EMPTY:-x}'), 'x');
      expect(run(r'${UNSET-x}'), 'x');
      expect(run(r'${EMPTY-x}'), '');
      expect(run(r'${TAG:-x}'), '1.2');
    });

    test(':+ and + substitute only when set', () {
      expect(run(r'${TAG:+set}'), 'set');
      expect(run(r'${EMPTY:+set}'), '');
      expect(run(r'${EMPTY+set}'), 'set');
      expect(run(r'${UNSET+set}'), '');
    });

    test('defaults nest', () {
      expect(run(r'${UNSET:-${NAME}:${TAG}}'), 'web:1.2');
    });

    test(':? and ? refuse a missing value', () {
      expect(
        () => run(r'${UNSET:?needs a tag}'),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
      expect(
        () => run(r'${EMPTY:?needs a tag}'),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
      expect(run(r'${EMPTY?needs a tag}'), '');
    });

    test('an unknown operator is refused, not guessed at', () {
      expect(
        () => run(r'${TAG%x}'),
        throwsA(isA<EnvironmentRigImagesUnresolved>()),
      );
    });
  });

  group('parseDotEnv follows compose', () {
    test('comments, blank lines and export prefixes', () {
      expect(
        parseDotEnv('''
# a comment

export A=1
B = 2
'''),
        {'A': '1', 'B': '2'},
      );
    });

    test('an unquoted value ends at a spaced #', () {
      expect(parseDotEnv('A=one # two\nB=a#b'), {'A': 'one', 'B': 'a#b'});
    });

    test('single quotes are literal', () {
      expect(parseDotEnv(r"A='$HOME \n x'"), {'A': r'$HOME \n x'});
    });

    test('double quotes escape and may span lines', () {
      expect(parseDotEnv(r'A="one\ntwo \"q\" \$x"'), {'A': 'one\ntwo "q" \$x'});
      expect(parseDotEnv('A="first\nsecond"\nB=3'), {
        'A': 'first\nsecond',
        'B': '3',
      });
    });

    test('values interpolate earlier keys and the environment', () {
      expect(
        parseDotEnv(
          r'''
BASE=node
IMAGE=${BASE}:${TAG:-latest}
''',
          environment: const {'TAG': '20'},
        ),
        {'BASE': 'node', 'IMAGE': 'node:20'},
      );
    });
  });
}
