import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/foundation.dart';

/// Pr doc agent result.
class PrDocAgentResult {
  /// PrDocAgentResult.
  const PrDocAgentResult({
    required this.title,
    required this.body,
    required this.summary,
  });

  /// Title.
  final String title;

  /// Body.
  final String body;

  /// summary.
  final String summary;
}

/// Pr doc agent.
class PrDocAgent {
  /// Generate from diff.
  Future<PrDocAgentResult> generateFromDiff({
    required String workspacePath,
    required String branch,
    String baseBranch = 'main',
  }) async {
    final diff = await _getDiff(workspacePath, branch, baseBranch);

    final stats = countDiffStats(diff);
    final summary =
        '${stats['files']} files changed, '
        '+${stats['additions']}, -${stats['deletions']}';
    final title = 'WIP: Changes on branch $branch';
    final body = '## Summary\n\nChanges from `$branch`.\n\n```diff\n$diff\n```';

    return PrDocAgentResult(title: title, body: body, summary: summary);
  }

  /// Generate with agent.
  Future<PrDocAgentResult> generateWithAgent({
    required String workingDirectory,
    required String branch,
    String baseBranch = 'main',
  }) async {
    try {
      final diff = await _getDiff(workingDirectory, branch, baseBranch);

      if (diff.trim().isEmpty) {
        return const PrDocAgentResult(
          title: 'No changes detected',
          body: 'No diff found between branches.',
          summary: '0 files changed',
        );
      }

      final prompt = buildDocPrompt(diff);

      final process = await Process.start(
        'claude',
        ['--bare', '--output-format', 'json', '--prompt', prompt],
        workingDirectory: workingDirectory,
        runInShell: true,
      );

      final output = await process.stdout
          .transform(const SystemEncoding().decoder)
          .join();

      final jsonStart = output.indexOf('{');
      if (jsonStart == -1) {
        return fallbackResult(diff, branch);
      }

      try {
        final json =
            jsonDecode(output.substring(jsonStart)) as Map<String, dynamic>;
        final stats = countDiffStats(diff);
        return PrDocAgentResult(
          title: (json['title'] as String?) ?? 'Changes from $branch',
          body: (json['body'] as String?) ?? output,
          summary:
              '${stats['files']} files changed, +${stats['additions']}, -${stats['deletions']}',
        );
      } catch (_) {
        return fallbackResult(diff, branch);
      }
    } catch (e) {
      AppLog.e('PrDocAgent', 'Failed to generate PR doc: $e', e);
      return const PrDocAgentResult(
        title: 'Generation failed',
        body: 'Could not generate PR description automatically.',
        summary: '',
      );
    }
  }

  Future<String> _getDiff(String path, String branch, String base) async {
    try {
      final result = await Process.run(
        'git',
        ['diff', '$base...$branch', '--stat'],
        workingDirectory: path,
        runInShell: true,
      );
      return (result.stdout as String).trim();
    } catch (_) {
      return '';
    }
  }

  @visibleForTesting
  /// Count diff stats.
  Map<String, int> countDiffStats(String diff) {
    final lines = diff.split('\n');
    var files = 0;
    var additions = 0;
    var deletions = 0;

    for (final line in lines) {
      if (line.startsWith('+') && !line.startsWith('+++')) {
        additions++;
      } else if (line.startsWith('-') && !line.startsWith('---')) {
        deletions++;
      }
    }

    final lastLine = lines.isNotEmpty ? lines.last : '';
    if (lastLine.contains('changed')) {
      final match = RegExp(r'(\d+) file').firstMatch(lastLine);
      if (match != null) {
        files = int.tryParse(match.group(1)!) ?? files;
      }
    }

    return {'files': files, 'additions': additions, 'deletions': deletions};
  }

  @visibleForTesting
  /// Build doc prompt.
  String buildDocPrompt(String diff) {
    return '''
Analyze the following git diff and produce a JSON object with:
- "title": A concise, descriptive PR title (max 72 chars)
- "body": A well-structured markdown PR description summarizing the changes

Return ONLY the JSON object, no other text.

```diff
$diff
```
''';
  }

  @visibleForTesting
  /// Fallback result.
  PrDocAgentResult fallbackResult(String diff, String branch) {
    final stats = countDiffStats(diff);
    return PrDocAgentResult(
      title: 'Changes on $branch',
      body:
          'Automated PR for changes on branch `$branch`.\n\n'
          '${stats['files']} files changed, '
          '+${stats['additions']}, -${stats['deletions']}.',
      summary:
          '${stats['files']} files changed, '
          '+${stats['additions']}, -${stats['deletions']}',
    );
  }
}
