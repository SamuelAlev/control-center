import 'dart:io';

import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:cc_domain/features/auth/domain/ports/github_cli_port.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';

/// Process-based implementation of the GitHub CLI port.
///
/// Probes the local `gh` command to detect installation, authentication
/// status, username, and token.
class ProcessGitHubCliService implements GitHubCliPort {
  /// Creates a [ProcessGitHubCliService].
  ProcessGitHubCliService();

  String? _resolvedBinary;

  /// Probes the local `gh` CLI and returns the resolved status.
  ///
  /// Returns an empty status (not installed) if `gh` is missing or any
  /// invocation throws — callers can treat this as "fall back to PAT".
  @override
  Future<GitHubCliStatus> probe() async {
    final binary = await _resolveBinary();
    if (binary == null) {
      return const GitHubCliStatus();
    }

    final statusResult = await _run(binary, ['auth', 'status']);
    final isAuthenticated = statusResult.exitCode == 0;
    if (!isAuthenticated) {
      return const GitHubCliStatus(isInstalled: true);
    }

    final username = _parseUsername(
      '${statusResult.stdout}\n${statusResult.stderr}',
    );
    final token = await _readToken(binary);

    return GitHubCliStatus(
      isInstalled: true,
      isAuthenticated: true,
      username: username,
      token: token,
    );
  }

  Future<String?> _resolveBinary() async {
    final cached = _resolvedBinary;
    if (cached != null) {
      return cached;
    }
    final resolved = await resolveBinaryPath('gh');
    _resolvedBinary = resolved;
    return resolved;
  }

  Future<ProcessResult> _run(String binary, List<String> args) async {
    try {
      return await Process.run(binary, args);
    } on ProcessException catch (e) {
      return ProcessResult(0, 1, '', e.message);
    }
  }

  Future<String> _readToken(String binary) async {
    final result = await _run(binary, ['auth', 'token']);
    if (result.exitCode != 0) {
      return '';
    }

    return (result.stdout as String).trim();
  }

  /// Extracts the GitHub username from `gh auth status` output.
  ///
  /// `gh` writes the human-readable status to stderr; the line looks like:
  ///   `✓ Logged in to github.com account samuel.alev (keyring)`
  String _parseUsername(String output) {
    final match = RegExp(
      r'(?:Logged in to\s*[^\s]+\s+(?:as|account)\s+)([^\s]+)',
    ).firstMatch(output);
    return match?.group(1) ?? '';
  }
}

