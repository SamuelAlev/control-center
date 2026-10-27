import 'dart:io';

import 'package:cc_infra/src/dispatch/host_commit_signer.dart';
import 'package:test/test.dart';

/// The host signer runs outside the sandbox on the user's global git config,
/// so what it refuses to run matters as much as what it signs.
void main() {
  late Directory home;
  late String config;
  late File planted;

  setUp(() {
    home = Directory.systemTemp.createTempSync('cc-host-signer-');
    config = '${home.path}/gitconfig';
    // Named like a trusted signer, in a directory a sandbox could write.
    planted = File('${home.path}/bin/ssh-keygen')
      ..createSync(recursive: true)
      ..writeAsStringSync('#!/bin/sh\ntouch "\$0.ran"\nexit 1\n');
    Process.runSync('/bin/chmod', ['755', planted.path]);
  });

  tearDown(() => home.deleteSync(recursive: true));

  bool plantedRan() => File('${planted.path}.ran').existsSync();

  HostCommitSigner signer(String gitconfig, {List<TrustedSshSigner>? only}) {
    File(config).writeAsStringSync(gitconfig);
    return HostCommitSigner(
      environment: {
        ...Platform.environment,
        'HOME': home.path,
        'GIT_CONFIG_GLOBAL': config,
        'GIT_CONFIG_NOSYSTEM': '1',
        // A bare program name must never be looked up here.
        'PATH': '${planted.parent.path}:${Platform.environment['PATH']}',
      },
      signers: only,
    );
  }

  final payload = 'tree ${'a' * 40}\n'.codeUnits;

  Future<String> refusal(HostCommitSigner s) async {
    try {
      await s.sign(payload);
    } on CommitSigningException catch (e) {
      return e.message;
    }
    fail('signed');
  }

  String sshConfig({String? program, String key = 'key::ssh-ed25519 AAAA'}) =>
      '[gpg]\n  format = ssh\n'
      '${program == null ? '' : '[gpg "ssh"]\n  program = $program\n'}'
      '[user]\n  signingkey = $key\n';

  test('an OpenPGP setup is refused rather than half-handled', () async {
    final message = await refusal(signer('[user]\n  signingkey = ABCDEF\n'));
    expect(message, contains('gpg.format=openpgp'));
  });

  test('a missing signing key is named', () async {
    final message = await refusal(signer('[gpg]\n  format = ssh\n'));
    expect(message, contains('user.signingkey'));
  });

  test('a signer outside the trusted list is never run', () async {
    for (final program in [planted.path, '/bin/sh', '/usr/bin/env']) {
      final message = await refusal(signer(sshConfig(program: program)));
      expect(message, contains('only runs these SSH signers'));
    }
    expect(plantedRan(), isFalse);
  });

  test('an included file cannot name the signer', () async {
    File(
      '${home.path}/included',
    ).writeAsStringSync('[gpg "ssh"]\n  program = ${planted.path}\n');
    final s = signer(
      '${sshConfig()}[include]\n  path = ${home.path}/included\n',
    );
    // Includes are ignored, so the default signer is used (and fails on the
    // bogus key) — the planted one never runs.
    await refusal(s);
    expect(plantedRan(), isFalse);
  });

  test('a bare name is the trusted signer, never a PATH lookup', () async {
    final key = '${home.path}/key';
    final keygen = Process.runSync('/usr/bin/ssh-keygen', [
      '-q',
      '-t',
      'ed25519',
      '-N',
      '',
      '-f',
      key,
    ]);
    expect(keygen.exitCode, 0, reason: keygen.stderr as String);
    final signature = await signer(
      sshConfig(program: 'ssh-keygen', key: key),
    ).sign(payload);
    expect(signature, startsWith('-----BEGIN SSH SIGNATURE-----'));
    expect(plantedRan(), isFalse);
  });

  test(
    'a look-alike at a trusted path fails the vendor signature check',
    () async {
      final message = await refusal(
        signer(
          sshConfig(program: planted.path),
          only: [TrustedSshSigner(planted.path, teamId: '2BUA8C4S2C')],
        ),
      );
      expect(message, contains('not signed by its vendor'));
      expect(plantedRan(), isFalse);
    },
    skip: Platform.isMacOS ? null : 'Code signatures are checked on macOS',
  );

  test(
    '1Password\'s signer passes the vendor check when installed',
    () async {
      const path = '/Applications/1Password.app/Contents/MacOS/op-ssh-sign';
      // Resolved only, never run: running it could prompt on this machine.
      expect(await signer(sshConfig()).trustedProgram(path), path);
      expect(await signer(sshConfig()).trustedProgram('op-ssh-sign'), path);
    },
    skip:
        File(
          '/Applications/1Password.app/Contents/MacOS/op-ssh-sign',
        ).existsSync()
        ? null
        : '1Password is not installed',
  );
}
