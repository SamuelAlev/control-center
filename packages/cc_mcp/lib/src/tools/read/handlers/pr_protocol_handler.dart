import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:cc_infra/src/network/models/github_issue_comment.dart';
import 'package:cc_infra/src/network/models/github_pull_request_file.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:cc_infra/src/network/models/github_review_comment.dart';
import 'package:cc_mcp/src/tools/read/internal_url.dart';
import 'package:cc_mcp/src/tools/read/internal_url_router.dart';
import 'package:cc_mcp/src/tools/read/rendering/diff_segmenter.dart';
import 'package:cc_mcp/src/tools/read/rendering/pr_markdown_renderer.dart';

/// Handles `pr://owner/repo/<n>[/diff[/all|<n>]]` URLs by calling
/// [GitHubPrClient] and rendering the result for the agent.
class PrProtocolHandler {
  /// Creates a [PrProtocolHandler].
  PrProtocolHandler({required GitHubPrClient client}) : _client = client;

  final GitHubPrClient _client;

  /// Resolves [url] against GitHub and returns a [CallResult].
  Future<CallResult> handle(PrUrl url, ReadContext context) async {
    final owner = url.owner;
    final repo = url.repo;
    final number = url.number;

    try {
      switch (url.diffMode) {
        case PrDiffMode.none:
          final pr = await _client.getPullRequest(owner, repo, number);
          if (pr == null) {
            return CallResult.error(
              'PR not found: pr://$owner/$repo/$number',
            );
          }
          final checkRuns = await _safeListCheckRuns(owner, repo, pr.headSha);
          final reviews = url.includeComments
              ? await _client.listPullRequestReviews(owner, repo, number)
              : const <GitHubReview>[];
          final reviewComments = url.includeComments
              ? await _client.listPullRequestReviewComments(owner, repo, number)
              : const <GitHubReviewComment>[];
          final issueComments = url.includeComments
              ? await _client.listIssueComments(owner, repo, number)
              : const <GitHubIssueComment>[];
          final markdown = const PrMarkdownRenderer().render(
            pr: pr,
            checkRuns: checkRuns,
            reviews: reviews,
            reviewComments: reviewComments,
            issueComments: issueComments,
          );
          return CallResult.success(markdown);

        case PrDiffMode.fileList:
          // The unified-diff endpoint caps at 300 files. The files endpoint
          // paginates up to 3000, so prefer it — we only need filenames here.
          final files = await _client.listPullRequestFiles(owner, repo, number);
          final body = StringBuffer('# PR #$number files\n\n');
          if (files.isEmpty) {
            body.writeln('(no files)');
          } else {
            for (var i = 0; i < files.length; i++) {
              body.writeln('${i + 1}. ${files[i].filename}');
            }
          }
          return CallResult.success(body.toString());

        case PrDiffMode.full:
          final diff = await _getDiffWithFallback(owner, repo, number);
          return CallResult.success(diff);

        case PrDiffMode.singleFile:
          final idx = url.diffFileIndex!;
          try {
            final diff = await _client.getPullRequestDiff(owner, repo, number);
            final segs = const DiffSegmenter().segments(diff);
            if (idx < 1 || idx > segs.length) {
              return CallResult.error(
                'pr:// diff index $idx out of range (1..${segs.length})',
              );
            }
            return CallResult.success(segs[idx - 1].text);
          } on NetworkException catch (e) {
            if (e.statusCode != 406) {
              rethrow;
            }
            final files = await _client.listPullRequestFiles(owner, repo, number);
            if (idx < 1 || idx > files.length) {
              return CallResult.error(
                'pr:// diff index $idx out of range (1..${files.length})',
              );
            }
            return CallResult.success(_synthesizeDiff([files[idx - 1]]));
          }
      }
    } on NetworkException catch (e) {
      if (e.statusCode == 404) {
        return CallResult.error(
          'Repository not found or not accessible: $owner/$repo (HTTP 404)\n'
          'This can mean:\n'
          '1. The repository is private — verify you have a GitHub token configured.\n'
          '   Open Settings → GitHub in the Control Center app, or run `gh auth status`.\n'
          '   The token must have the `repo` scope for private repositories.\n'
          '2. The owner or repo name is misspelled (case-sensitive).\n'
          '3. PR #$number does not exist in this repository.\n'
          'If you confirmed auth is set up, the repository or PR may genuinely not exist.',
        );
      }
      if (e.statusCode == 406) {
        return CallResult.error(_format406Error(e, owner, repo, number));
      }
      return CallResult.error('${e.message} (HTTP ${e.statusCode})');
    } catch (e) {
      return CallResult.error('$e');
    }
  }

  /// Fetches the unified PR diff. If GitHub returns 406 (PRs with >300 files
  /// are rejected by the diff endpoint), falls back to synthesising a diff
  /// from the per-file patches returned by the files endpoint.
  Future<String> _getDiffWithFallback(
    String owner,
    String repo,
    int number,
  ) async {
    try {
      return await _client.getPullRequestDiff(owner, repo, number);
    } on NetworkException catch (e) {
      if (e.statusCode != 406) {
        rethrow;
      }
      final files = await _client.listPullRequestFiles(owner, repo, number);
      return _synthesizeDiff(files);
    }
  }

  /// Builds a unified-diff-shaped string from [files]. GitHub's per-file
  /// `patch` field contains only hunk lines (`@@`, ` `, `+`, `-`), so we
  /// prepend `diff --git` + `---`/`+++` headers ourselves to keep the
  /// existing [DiffSegmenter] and downstream renderers working. Binary
  /// files and files over GitHub's size threshold come back with an empty
  /// patch — emit a placeholder so they remain visible in the listing.
  String _synthesizeDiff(List<GitHubPullRequestFile> files) {
    final out = StringBuffer();
    for (final f in files) {
      final aPath = f.previousFilename ?? f.filename;
      final bPath = f.filename;
      out.writeln('diff --git a/$aPath b/$bPath');
      out.writeln('--- a/$aPath');
      out.writeln('+++ b/$bPath');
      if (f.patch.isEmpty) {
        out.writeln(
          '@@ patch unavailable @@ (status=${f.status}, '
          '+${f.additions} -${f.deletions})',
        );
      } else {
        out.writeln(f.patch);
      }
    }
    return out.toString();
  }

  /// Formats a 406 error with the actual GitHub response body when
  /// available (typically the "diff exceeded the maximum number of files"
  /// message), plus actionable hints for the agent.
  String _format406Error(
    NetworkException e,
    String owner,
    String repo,
    int number,
  ) {
    final githubMessage = _extractGitHubMessage(e.responseBody);
    final buf = StringBuffer(
      'GitHub rejected the diff request (HTTP 406) for pr://$owner/$repo/$number.\n',
    );
    if (githubMessage != null) {
      buf.writeln('GitHub said: $githubMessage');
    }
    buf.writeln('Try one of:');
    buf.writeln('- pr://$owner/$repo/$number/diff (file list only — works regardless of PR size)');
    buf.writeln('- pr://$owner/$repo/$number/diff/<N> (a single file by index from the list)');
    buf.writeln('- gh://$owner/$repo/blob/<ref>/<path> (read a specific file at a given ref)');
    return buf.toString().trimRight();
  }

  /// Pulls the `message` field out of a GitHub error JSON body. Returns
  /// null when the body isn't valid JSON or the field is missing.
  String? _extractGitHubMessage(String? body) {
    if (body == null || body.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'];
        if (msg is String && msg.isNotEmpty) {
          return msg;
        }
      }
    } catch (_) {
      // Body wasn't JSON — fall through.
    }
    return null;
  }

  Future<List<GitHubCheckRun>> _safeListCheckRuns(
    String owner,
    String repo,
    String sha,
  ) async {
    if (sha.isEmpty) {
      return const [];
    }
    try {
      return await _client.listCheckRuns(owner, repo, sha);
    } catch (_) {
      return const [];
    }
  }
}
