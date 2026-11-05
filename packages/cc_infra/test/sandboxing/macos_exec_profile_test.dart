import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config.dart';
import 'package:test/test.dart';

/// Pins the order of the Seatbelt `process-exec` rules. Seatbelt is
/// last-match-wins, so the order is the policy: toolchain trees re-open the
/// `$HOME` exec deny, and the always-dangerous denies after them keep `rm` and
/// `sudo` closed even when one sits inside a toolchain tree.
void main() {
  const home = '/Users/agent';
  const toolchain = '$home/.cargo/bin';
  const dangerous = '$home/.cargo/bin/rm';

  final profile = MacosSandbox.generateSeatbeltProfile(
    const SandboxConfig(
      sessionId: 's',
      network: NetworkConfig(),
      filesystem: FilesystemConfig(),
      denyExecutables: [dangerous],
      toolchainExecRoots: [toolchain],
      policy: SandboxPolicySpec(
        sessionId: 's',
        denyRead: [],
        allowWrite: [],
        denyWrite: [],
        denyExecutables: [],
        allowedDomains: [],
        deniedDomains: [],
        networkOn: false,
        homeDir: home,
      ),
    ),
  );

  int line(String rule) {
    final index = profile.split('\n').indexOf(rule);
    expect(index, isNot(-1), reason: 'missing rule: $rule');
    return index;
  }

  test('a toolchain allow follows the home exec deny', () {
    expect(
      line('(allow process-exec (subpath "$toolchain"))'),
      greaterThan(line('(deny process-exec (subpath "$home"))')),
    );
  });

  test('dangerous denies follow the toolchain allows', () {
    expect(
      line('(deny process-exec (literal "$dangerous"))'),
      greaterThan(line('(allow process-exec (subpath "$toolchain"))')),
    );
  });
}
