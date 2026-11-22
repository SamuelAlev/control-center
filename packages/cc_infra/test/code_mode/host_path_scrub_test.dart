// What reaches a model or a workspace member names no host path: the scrub
// replaces a path whole, whatever it holds, and keeps the words after it.
import 'package:cc_infra/src/code_mode/host_path_scrub.dart';
import 'package:test/test.dart';

void main() {
  String scrub(String text) => scrubHostPaths(text);

  test('a path with spaces is replaced whole', () {
    final out = scrub(
      'cannot open /Users/someone/Library/Application Support/Control '
      'Center/codemode/cc_codemode',
    );
    expect(out, 'cannot open <path>');
  });

  test('a path with a non-ASCII component is replaced whole', () {
    final out = scrub('at /srv/données/Contrôle/runner, errno = 2');
    expect(out, 'at <path>, errno = 2');
  });

  test('a Windows path with a space is replaced whole', () {
    final out = scrub(
      r'C:\Users\someone\AppData\Local\Control Center\cc_codemode.exe: '
      'not found',
    );
    expect(out, '<path>: not found');
  });

  test('a file URL loses its path', () {
    final out = scrub(
      'reading file:///Users/someone/Application Support/x.json',
    );
    expect(out, 'reading file:<path>');
  });

  test('a quoted OS error keeps everything but the path', () {
    final out = scrub(
      "FileSystemException: Cannot open file, path = '/srv/a b/c.json' "
      '(OS Error: No such file or directory, errno = 2)',
    );
    expect(
      out,
      "FileSystemException: Cannot open file, path = '<path>' "
      '(OS Error: No such file or directory, errno = 2)',
    );
  });

  test('the words after a path and a colon survive', () {
    final out = scrub(
      'the runner at /opt/Control Center/cc_codemode: exited with code 4',
    );
    expect(out, 'the runner at <path>: exited with code 4');
  });

  test('known paths go first, and what follows them is replaced too', () {
    final out = scrubHostPaths(
      'cannot open /data dir/Application Support/x: denied',
      knownPaths: ['/data dir'],
    );
    expect(out, 'cannot open <path>: denied');
  });

  test('slashes that are not paths are left alone', () {
    const text = 'and/or 1/2 a / b </div> done';
    expect(scrub(text), text);
  });

  group('what is not a host path survives (review)', () {
    for (final text in [
      'see https://example.com/docs/code-mode for the limits, then retry',
      'glob **/*.dart matched nothing',
      'call tools and/or scripts, 1/2 of them',
      'namespace mcp__linear/save_issue is unknown',
    ]) {
      test(text, () => expect(scrub(text), text));
    }

    test('a regular expression or an HTTP path is replaced, and the words '
        'after it survive', () {
      expect(
        scrub('match /foo.*bar/ against the text'),
        'match <path> against the text',
      );
      expect(
        scrub('GET /api/v1/runs returned 404 so stop'),
        'GET <path> returned 404 so stop',
      );
    });
  });

  test('a UNC path is replaced whole', () {
    expect(
      scrub(r'cannot open \\fileserver\share\someone\cc_codemode now'),
      'cannot open <path> now',
    );
  });

  test('a ~user and a ~ path are replaced whole', () {
    expect(
      scrub('cannot open ~someone/bin/cc_codemode now'),
      'cannot open <path> now',
    );
    expect(
      scrub('cannot open ~/bin/cc_codemode now'),
      'cannot open <path> now',
    );
  });

  test('a known path whose name holds ", " and a quote leaves no tail', () {
    const known = "/opt/a, b/o'brien: x";
    expect(
      scrubHostPaths(
        "cannot open $known/codemode/cc_codemode now, and '$known' too",
        knownPaths: [known],
      ),
      "cannot open <path> now, and '<path>' too",
    );
  });

  group('review round 4', () {
    test('a path right after a single ":" is replaced', () {
      expect(scrub('failed:/opt/someone/cc_codemode now'), 'failed:<path> now');
    });

    test('a known path in another letter case leaves no tail', () {
      expect(
        scrubHostPaths(
          "cannot open /OPT/O'BRIEN, X: Y/bundle/codemode/cc_codemode now",
          knownPaths: ["/opt/o'brien, x: y/bundle"],
        ),
        'cannot open <path> now',
      );
    });

    test('a Windows drive path with forward slashes is replaced whole, and '
        'a URL is not', () {
      expect(
        scrub('cannot open C:/Users/some one/bundle/cc_codemode.exe now'),
        'cannot open <path> now',
      );
      const url = 'see https://example.com/docs and C://x then';
      expect(scrub(url), url);
    });

    test('what follows a known Windows path goes with it', () {
      expect(
        scrubHostPaths(
          r'cannot open C:\Users\some one\bundle\cc_codemode.exe now',
          knownPaths: [r'C:\Users\some one\bundle'],
        ),
        'cannot open <path> now',
      );
    });

    test('a known path that starts a longer name takes the rest of it', () {
      expect(
        scrubHostPaths('cannot open /tmpfoo/bar now', knownPaths: ['/tmp']),
        'cannot open <path> now',
      );
      expect(
        scrubHostPaths(
          'cannot open /Users/samuel.alevb/secret now',
          knownPaths: ['/Users/samuel.alev'],
        ),
        'cannot open <path> now',
      );
    });
  });
}
