import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_infra/src/dispatch/pushed_commit_inspector.dart';
import 'package:cc_infra/src/git/ssh_commit_signature.dart';
import 'package:test/test.dart';

/// Whether `ssh-keygen` (OpenSSH 8.2+ for `-Y`) is on this machine. The
/// interop tests need it; the pure-Dart ones do not.
final bool _hasSshKeygen = () {
  try {
    return Process.runSync('ssh-keygen', ['-Y', 'sign']).exitCode != 127;
  } on ProcessException {
    return false;
  }
}();

void main() {
  group('SshSigningKey', () {
    test('a seed is the whole key: the same seed is the same key', () async {
      final key = await SshSigningKey.generate();
      final again = await SshSigningKey.fromSeed(key.seed);

      expect(key.seed, hasLength(32));
      expect(again.publicKey, key.publicKey);
      expect(key.publicKey, startsWith('ssh-ed25519 AAAAC3NzaC1lZDI1NTE5'));
      expect(key.publicKey.split(' '), hasLength(2), reason: 'no comment');
      expect(key.fingerprint, matches(RegExp(r'^SHA256:[A-Za-z0-9+/]{43}$')));
      expect((await SshSigningKey.generate()).publicKey, isNot(key.publicKey));
    });

    test('a seed of any other length is refused', () {
      expect(
        () => SshSigningKey.fromSeed(List.filled(31, 1)),
        throwsArgumentError,
      );
    });

    test(
      'its public key is accepted as a commit identity signing key',
      () async {
        final key = await SshSigningKey.generate();
        expect(
          AgentCommitIdentity.person((
            name: 'Ada',
            email: 'ada@example.com',
          ), signingKey: key.publicKey).signingKey,
          key.publicKey,
        );
      },
    );
  });

  group('SshSignature', () {
    test('a signature verifies for exactly the message it signed, and names '
        'its key', () async {
      final key = await SshSigningKey.generate();
      final message = utf8.encode('tree 1\nauthor A <a@x> 1 +0000\n\nm\n');
      final signature = await key.sign(message);

      expect(signature, startsWith('-----BEGIN SSH SIGNATURE-----\n'));
      expect(signature, endsWith('-----END SSH SIGNATURE-----\n'));
      expect(await SshSignature.signerOf(signature, message), key.publicKey);
      expect(
        await SshSignature.signerOf(signature, [...message, 0x0a]),
        isNull,
        reason: 'one more byte is another message',
      );
    });

    test(
      'signing is deterministic, so re-signing a commit changes nothing',
      () async {
        final key = await SshSigningKey.generate();
        final message = utf8.encode('same bytes');
        expect(await key.sign(message), await key.sign(message));
      },
    );

    test('anything that is not a well-formed Ed25519 signature in the git '
        'namespace has no signer', () async {
      final key = await SshSigningKey.generate();
      final message = utf8.encode('m');
      final good = await key.sign(message);
      final body = base64.decode(
        const LineSplitter()
            .convert(good)
            .where((l) => !l.startsWith('-----'))
            .join(),
      );
      String armor(List<int> bytes) =>
          '-----BEGIN SSH SIGNATURE-----\n${base64.encode(bytes)}\n'
          '-----END SSH SIGNATURE-----\n';

      // Flip one signature bit.
      final tampered = [...body]..[body.length - 1] ^= 1;
      // Another namespace: replace "git" (length-prefixed) with "abc".
      final git = [0, 0, 0, 3, ...ascii.encode('git')];
      var at = -1;
      for (var i = 0; i + git.length <= body.length; i++) {
        if (List.generate(
          git.length,
          (j) => body[i + j] == git[j],
        ).every((x) => x)) {
          at = i;
          break;
        }
      }
      expect(at, greaterThan(0));
      final otherNamespace = [...body]
        ..setRange(at + 4, at + 7, ascii.encode('abc'));

      for (final (name, bad) in [
        ('empty', ''),
        (
          'pgp',
          '-----BEGIN PGP SIGNATURE-----\nAAAA\n-----END PGP SIGNATURE-----\n',
        ),
        (
          'not base64',
          '-----BEGIN SSH SIGNATURE-----\n!!!!\n-----END SSH SIGNATURE-----\n',
        ),
        ('truncated', armor(body.sublist(0, body.length - 10))),
        ('trailing bytes', armor([...body, 0])),
        ('tampered', armor(tampered)),
        ('other namespace', armor(otherNamespace)),
      ]) {
        expect(await SshSignature.signerOf(bad, message), isNull, reason: name);
      }
    });

    test('a public key line is normalized to its type and key, comment '
        'dropped; anything else is not a key', () async {
      final key = await SshSigningKey.generate();
      expect(
        SshSignature.normalizePublicKey('  ${key.publicKey}   ada@laptop \n'),
        key.publicKey,
      );
      for (final bad in [
        '',
        'ssh-ed25519',
        'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ== x',
        'ssh-ed25519 AAAA',
        'ssh-ed25519 not-base64!',
      ]) {
        expect(SshSignature.normalizePublicKey(bad), isNull, reason: bad);
      }
    });
  });

  group('interop with OpenSSH and git', () {
    late Directory scratch;

    setUp(() async {
      scratch = await Directory.systemTemp.createTemp('cc-sshsig-test-');
    });

    tearDown(() => scratch.delete(recursive: true));

    test('ssh-keygen verifies a signature made here', () async {
      final key = await SshSigningKey.generate();
      final message = utf8.encode('hello from control center\n');
      File(
        '${scratch.path}/msg.sig',
      ).writeAsStringSync(await key.sign(message));
      File('${scratch.path}/allowed').writeAsStringSync(
        'ada@example.com namespaces="git" ${key.publicKey}\n',
      );
      final verify = await Process.start('ssh-keygen', [
        '-Y',
        'verify',
        '-f',
        '${scratch.path}/allowed',
        '-I',
        'ada@example.com',
        '-n',
        'git',
        '-s',
        '${scratch.path}/msg.sig',
      ]);
      verify.stdin.add(message);
      await verify.stdin.close();
      final out = await verify.stdout.transform(utf8.decoder).join();
      final err = await verify.stderr.transform(utf8.decoder).join();
      expect(await verify.exitCode, 0, reason: '$out$err');
      expect(out, contains('Good "git" signature'));
    }, skip: _hasSshKeygen ? false : 'ssh-keygen is not installed');

    test(
      'a signature made by ssh-keygen verifies here, under its key',
      () async {
        final keyFile = '${scratch.path}/id';
        final gen = await Process.run('ssh-keygen', [
          '-q',
          '-t',
          'ed25519',
          '-N',
          '',
          '-C',
          'test',
          '-f',
          keyFile,
        ]);
        expect(gen.exitCode, 0, reason: '${gen.stderr}');
        final message = utf8.encode('signed by openssh\n');
        File('${scratch.path}/msg').writeAsBytesSync(message);
        final sign = await Process.run('ssh-keygen', [
          '-Y',
          'sign',
          '-n',
          'git',
          '-f',
          keyFile,
          '${scratch.path}/msg',
        ]);
        expect(sign.exitCode, 0, reason: '${sign.stderr}');
        final publicKey = SshSignature.normalizePublicKey(
          File('$keyFile.pub').readAsStringSync(),
        );
        expect(publicKey, isNotNull);
        expect(
          await SshSignature.signerOf(
            File('${scratch.path}/msg.sig').readAsStringSync(),
            message,
          ),
          publicKey,
        );
      },
      skip: _hasSshKeygen ? false : 'ssh-keygen is not installed',
    );

    test('the inspector verifies a commit git signed with ssh-keygen, and '
        'does not when one byte of it changes', () async {
      final keyFile = '${scratch.path}/id';
      expect(
        (await Process.run('ssh-keygen', [
          '-q', '-t', 'ed25519', '-N', '', '-f', keyFile, //
        ])).exitCode,
        0,
      );
      final repo = Directory('${scratch.path}/repo')..createSync();
      final env = {
        'GIT_CONFIG_GLOBAL': (File(
          '${scratch.path}/gitconfig',
        )..writeAsStringSync('')).path,
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_AUTHOR_NAME': 'Ada',
        'GIT_AUTHOR_EMAIL': 'ada@example.com',
        'GIT_COMMITTER_NAME': 'Ada',
        'GIT_COMMITTER_EMAIL': 'ada@example.com',
        'HOME': scratch.path,
        // Git writes the buffer it signs to a temporary file. With no parent
        // environment, Git for Windows has no TEMP to find one with.
        'TMPDIR': scratch.path,
        if (Platform.isWindows) ...{
          'TEMP': scratch.path,
          'TMP': scratch.path,
          'SystemRoot': Platform.environment['SystemRoot'] ?? r'C:\Windows',
        },
      };
      Future<ProcessResult> git(List<String> args, {Encoding? out = utf8}) =>
          Process.run(
            'git',
            args,
            workingDirectory: repo.path,
            environment: env,
            includeParentEnvironment: false,
            stdoutEncoding: out,
          );
      // PATH is needed for git to find ssh-keygen.
      env['PATH'] = Platform.environment['PATH'] ?? '/usr/bin:/bin';
      expect((await git(['init', '--quiet', '-b', 'main'])).exitCode, 0);
      File('${repo.path}/a.txt').writeAsStringSync('a');
      expect((await git(['add', 'a.txt'])).exitCode, 0);
      final commit = await git([
        '-c', 'gpg.format=ssh', //
        '-c', 'user.signingkey=$keyFile.pub',
        'commit', '--quiet', '-S', '-m', 'signed\n\nbody',
      ]);
      expect(commit.exitCode, 0, reason: '${commit.stderr}');
      final raw =
          (await git(['cat-file', 'commit', 'HEAD'], out: null)).stdout
              as List<int>;
      final publicKey = SshSignature.normalizePublicKey(
        File('$keyFile.pub').readAsStringSync(),
      )!;

      final object = await PushedCommitInspector.read('commit', 'c1', raw);
      expect(object.signed, isTrue);
      expect(object.signedBy, publicKey);

      // The same signature over a commit whose message changed by one byte.
      final forged = [...raw]..[raw.length - 2] ^= 1;
      final other = await PushedCommitInspector.read('commit', 'c2', forged);
      expect(other.signed, isTrue);
      expect(other.signedBy, isNull);
    }, skip: _hasSshKeygen ? false : 'ssh-keygen is not installed');
  });
}
