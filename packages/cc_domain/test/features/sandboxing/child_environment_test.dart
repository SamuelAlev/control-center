import 'package:cc_domain/features/sandboxing/domain/child_environment.dart';
import 'package:test/test.dart';

void main() {
  const host = {
    'PATH': '/usr/bin:/bin',
    'HOME': '/home/op',
    'USER': 'op',
    'SHELL': '/bin/zsh',
    'TERM': 'xterm-256color',
    'TMPDIR': '/tmp/op',
    'LANG': 'en_US.UTF-8',
    'LC_ALL': 'en_US.UTF-8',
    'https_proxy': 'http://proxy.corp:3128',
    'NIX_SSL_CERT_FILE': '/etc/ssl/certs/ca-certificates.crt',
    // Secrets and ambient identity that must never reach a child.
    'GH_TOKEN': 'ghp_host',
    'GITHUB_TOKEN': 'ghp_host',
    'GH_ENTERPRISE_TOKEN': 'ghe',
    'GITHUB_APP_PRIVATE_KEY': '-----BEGIN RSA PRIVATE KEY-----',
    'GITHUB_APP_ID': '42',
    'GITHUB_CLIENT_SECRET': 'shh',
    'GITHUB_CLIENT_ID': 'Iv1',
    'GOOGLE_OAUTH_CLIENT_SECRET': 'shh',
    'LINEAR_API_KEY': 'lin_api_x',
    'SLACK_SIGNING_SECRET': 'shh',
    'KLIPY_APP_KEY': 'k',
    'CC_CONNECT_URL': 'https://connect.example',
    'SSH_AUTH_SOCK': '/tmp/agent.sock',
    'LD_PRELOAD': '/evil.so',
    'DYLD_INSERT_LIBRARIES': '/evil.dylib',
    'NODE_OPTIONS': '--require /evil.js',
    'BASH_ENV': '/evil.sh',
    // Not secrets, but nobody asked for them.
    'AWS_PROFILE': 'prod',
    'OPENAI_API_KEY': 'sk-host',
    'NVM_DIR': '/home/op/.nvm',
    'XDG_CONFIG_HOME': '/home/op/.config',
    'DISPLAY': ':0',
  };

  group('ChildEnvironment.build', () {
    test('starts from the allowlist, never the host wholesale', () {
      final env = ChildEnvironment.build(host);
      expect(env, {
        'PATH': '/usr/bin:/bin',
        'HOME': '/home/op',
        'USER': 'op',
        'SHELL': '/bin/zsh',
        'TERM': 'xterm-256color',
        'TMPDIR': '/tmp/op',
        'LANG': 'en_US.UTF-8',
        'LC_ALL': 'en_US.UTF-8',
        'https_proxy': 'http://proxy.corp:3128',
        'NIX_SSL_CERT_FILE': '/etc/ssl/certs/ca-certificates.crt',
      });
    });

    test('strips every secret family even when a caller asks for it', () {
      final env = ChildEnvironment.build(
        host,
        inherit: host.keys,
        toolchain: true,
        display: true,
      );
      for (final key in [
        'GH_TOKEN',
        'GITHUB_TOKEN',
        'GH_ENTERPRISE_TOKEN',
        'GITHUB_APP_PRIVATE_KEY',
        'GITHUB_APP_ID',
        'GITHUB_CLIENT_SECRET',
        'GITHUB_CLIENT_ID',
        'GOOGLE_OAUTH_CLIENT_SECRET',
        'LINEAR_API_KEY',
        'SLACK_SIGNING_SECRET',
        'KLIPY_APP_KEY',
        'CC_CONNECT_URL',
        'SSH_AUTH_SOCK',
        'LD_PRELOAD',
        'DYLD_INSERT_LIBRARIES',
        'NODE_OPTIONS',
        'BASH_ENV',
      ]) {
        expect(env, isNot(contains(key)), reason: key);
      }
      // What the caller named and is allowed does come through.
      expect(env['AWS_PROFILE'], 'prod');
      expect(env['NVM_DIR'], '/home/op/.nvm');
      expect(env['DISPLAY'], ':0');
    });

    test('inherits only the named extras', () {
      final env = ChildEnvironment.build(host, inherit: const ['aws_profile']);
      expect(env['AWS_PROFILE'], 'prod');
      expect(env, isNot(contains('OPENAI_API_KEY')));
      expect(env, isNot(contains('NVM_DIR')));
    });

    test('toolchain and display groups are opt-in', () {
      expect(ChildEnvironment.build(host), isNot(contains('NVM_DIR')));
      final tools = ChildEnvironment.build(host, toolchain: true);
      expect(tools['NVM_DIR'], '/home/op/.nvm');
      expect(tools['XDG_CONFIG_HOME'], '/home/op/.config');
      expect(tools, isNot(contains('DISPLAY')));
      expect(ChildEnvironment.build(host, display: true)['DISPLAY'], ':0');
    });

    test('explicit overrides win and are never filtered', () {
      final env = ChildEnvironment.build(
        host,
        overrides: const {'GH_TOKEN': 'ghs_minted_one_repo', 'PATH': '/x'},
      );
      expect(env['GH_TOKEN'], 'ghs_minted_one_repo');
      expect(env['PATH'], '/x');
    });

    test('inheritBase false keeps only what the caller names', () {
      final env = ChildEnvironment.build(
        host,
        inheritBase: false,
        overrides: const {'LANG': 'C'},
      );
      expect(env, {'LANG': 'C'});
    });

    test('Windows spellings match case-insensitively', () {
      final env = ChildEnvironment.build(const {
        'Path': r'C:\Windows',
        'SystemRoot': r'C:\Windows',
        'Gh_Token': 'ghp_host',
      });
      expect(env, {'Path': r'C:\Windows', 'SystemRoot': r'C:\Windows'});
    });

    test('isStripped covers the strip list', () {
      expect(ChildEnvironment.isStripped('github_token'), isTrue);
      expect(ChildEnvironment.isStripped('SLACK_BOT_TOKEN'), isTrue);
      expect(ChildEnvironment.isStripped('PATH'), isFalse);
    });
  });
}
