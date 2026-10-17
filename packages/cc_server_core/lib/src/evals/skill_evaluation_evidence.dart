import 'dart:convert';

import 'package:cc_domain/core/domain/services/redaction/secret_scanner.dart';

/// Bounded public evidence. Private inputs and artifacts remain server-side;
/// truncation is signalled separately from the evaluation's coverage verdict.
class SkillEvaluationEvidence {
  /// Creates a bounded projector using [secrets] to identify sensitive text.
  const SkillEvaluationEvidence({this.secrets = const SecretScanner()});

  /// Scanner used to redact credentials in public evidence.
  final SecretScanner secrets;

  /// Maximum accepted length, in UTF-16 code units, of one evidence string.
  static const maxStringLength = 8192;

  /// Maximum UTF-8 size of a projected attempt, in bytes.
  static const maxAttemptBytes = 256 * 1024;

  /// Maximum UTF-8 size of a campaign export, in bytes.
  static const maxExportBytes = 16 * 1024 * 1024;
  static const _maxEntries = 64;
  static const _priorityKeys = {
    'id',
    'workspaceId',
    'campaignId',
    'attemptId',
    'taskId',
    'armId',
    'skillKey',
    'skillSlug',
    'skillHash',
    'repoId',
    'baselineHash',
    'corpusId',
    'providerId',
    'modelId',
    'configurationHash',
    'comparison',
    'status',
    'completed',
    'verifiedSuccess',
    'success',
    'outcome',
    'coverageComplete',
    'plannedAttempts',
    'completedAttempts',
    'spentMicros',
    'budgetMicros',
    'repetitions',
    'repetition',
    'ordinal',
    'createdAt',
    'startedAt',
    'finishedAt',
    'triggeredBy',
    'error',
    'staleReason',
    'expectedTrials',
    'expectedPairs',
    'seed',
    'planId',
    'executionMode',
    'generatedAtEpochMs',
    'recommendation',
    'expectedAuthoritativeChecks',
    'metrics',
    'tokens',
    'cost',
    'latency',
    'verification',
    'identityMismatches',
    'unknowns',
    'report',
  };
  static const _maxDepth = 12;
  // Campaign admission permits at most 960 attempts. Leave room for protocol
  // growth while bounding even an incorrectly supplied lazy source.
  static const _maxExportAttempts = 1024;
  static const _summaryKeys = {
    'id',
    'workspaceId',
    'campaignId',
    'attemptId',
    'taskId',
    'armId',
    'repetition',
    'ordinal',
    'createdAt',
    'completed',
    'verifiedSuccess',
    'error',
    'cost',
    'tokens',
    'expectedAuthoritativeChecks',
    'identityMismatches',
  };
  static const _privateKeys = {
    'credential',
    'credentials',
    'secret',
    'apikey',
    'authorization',
    'systemprompt',
    'prompt',
    'messages',
    'transcript',
    'trustedscript',
    'inlinefiles',
    'files',
    'workspaceroot',
    'outputdir',
    'rundir',
    'oracle',
    'oracles',
    'hiddenchecks',
    'privatekey',
    'password',
    'token',
    'input',
    'output',
    'stdout',
    'stderr',
    'response',
    'body',
    'content',
    'arguments',
    'instructions',
    'detail',
  };
  static final _nonLetters = RegExp(r'[^a-zA-Z]');
  // A leading slash at a word boundary is a host path, regardless of its
  // root (/opt, /srv, /Applications, etc.). Embedded relative artifact paths
  // and URL paths are left intact.
  static final _hostPath = RegExp(
    r'''(?<![\w./:])(?:/(?!/)[^\s"'<>(),;]+|[A-Za-z]:\\[^\s"'<>(),;]+)''',
  );
  static final _inlineCredential = RegExp(
    r'\b(?:api[_-]?key|authorization|password|secret|token)\s*[:=]\s*\S+',
    caseSensitive: false,
  );

  /// Projects a report or campaign without traversing unbounded containers.
  Map<String, dynamic> project(Map<String, dynamic> value) =>
      _bounded(value, maxAttemptBytes);

  /// Projects one attempt, retaining its identity and accounting when traces
  /// must be shortened. `traceTruncated` is not an execution coverage verdict.
  Map<String, dynamic> attempt(Map<String, dynamic> value) =>
      _bounded(value, maxAttemptBytes);

  /// Exports every admitted attempt's identity and accounting. Large traces
  /// become explicit summaries before the 16 MiB limit is reached.
  /// Supply `attemptCount` for a lazy source to retain exact coverage accounting.
  String export(Map<String, dynamic> value) {
    final source = value['attempts'] is Iterable
        ? value['attempts'] as Iterable
        : const <dynamic>[];
    final suppliedCount = value['attemptCount'];
    final totalCount = suppliedCount is int && suppliedCount >= 0
        ? suppliedCount
        : source is List
        ? source.length
        : null;
    final campaign = value['campaign'];
    final projectedCampaign = campaign is Map<String, dynamic>
        ? project(campaign)
        : null;
    final result = <String, dynamic>{
      'format': 'cc-skill-evaluation/1',
      'campaign': projectedCampaign,
      'attemptCount': totalCount,
      'attempts': <Map<String, dynamic>>[],
      'omittedAttemptCount': totalCount,
      'summarizedAttemptCount': 0,
      'detailsOmitted': totalCount == null || totalCount != 0,
    };
    final attempts = result['attempts'] as List<Map<String, dynamic>>;
    const encoder = JsonEncoder();
    final reservedCount = (totalCount ?? _maxExportAttempts).clamp(
      0,
      _maxExportAttempts,
    );
    var detailBudget =
        maxExportBytes -
        utf8.encode(encoder.convert(result)).length -
        4096 -
        reservedCount * 4096;
    var includeDetails = true;
    var summarized = 0;
    final iterator = source.iterator;
    for (var i = 0; i < _maxExportAttempts && iterator.moveNext(); i++) {
      final item = iterator.current;
      if (item is! Map<String, dynamic>) {
        break;
      }
      Map<String, dynamic>? projected;
      if (includeDetails) {
        final detailed = attempt(item);
        final bytes = utf8.encode(encoder.convert(detailed)).length;
        if (bytes <= detailBudget) {
          projected = detailed;
          detailBudget -= bytes;
        } else {
          includeDetails = false;
        }
      }
      if (projected == null) {
        final inner = item['evidence'];
        projected = _bounded({
          for (final key in _summaryKeys)
            if (item.containsKey(key)) key: item[key],
          if (inner is Map)
            'evidence': {
              for (final key in _summaryKeys)
                if (inner.containsKey(key)) key: inner[key],
            },
        }, 2048)..['traceTruncated'] = true;
        summarized++;
      }
      attempts.add(projected);
    }
    void updateCoverage() {
      final report = projectedCampaign?['report'];
      result['omittedAttemptCount'] =
          totalCount == null || totalCount < attempts.length
          ? null
          : totalCount - attempts.length;
      result['summarizedAttemptCount'] = summarized;
      result['detailsOmitted'] =
          result['omittedAttemptCount'] != 0 ||
          projectedCampaign?['traceTruncated'] == true ||
          (report is Map<String, dynamic> &&
              report['traceTruncated'] == true) ||
          attempts.any((row) {
            final inner = row['evidence'];
            return row['traceTruncated'] == true ||
                (inner is Map<String, dynamic> &&
                    inner['traceTruncated'] == true);
          });
    }

    updateCoverage();
    var content = encoder.convert(result);
    while (utf8.encode(content).length > maxExportBytes &&
        attempts.isNotEmpty) {
      attempts.removeLast();
      updateCoverage();
      content = encoder.convert(result);
    }
    return content;
  }

  Map<String, dynamic> _bounded(Map<String, dynamic> value, int maxBytes) {
    // Reserve half the envelope for punctuation, indentation and omission
    // markers. Only visited leaves are encoded or scanned.
    final budget = _EvidenceBudget(maxBytes ~/ 2);
    final result = _value(value, 0, budget) as Map<String, dynamic>;
    if (budget.truncated) {
      result['traceTruncated'] = true;
    }
    return result;
  }

  dynamic _value(dynamic value, int depth, _EvidenceBudget budget) {
    if (depth >= _maxDepth) {
      budget.truncated = true;
      budget.take(16);
      return '[DEPTH LIMIT]';
    }
    if (value is Map) {
      final result = <String, dynamic>{};
      var examined = 0;
      Iterable<MapEntry<dynamic, dynamic>> ordered() sync* {
        for (final key in _priorityKeys) {
          if (value.containsKey(key)) {
            yield MapEntry(key, value[key]);
          }
        }
        for (final entry in value.entries) {
          if (!_priorityKeys.contains(entry.key)) {
            yield entry;
          }
        }
      }

      for (final entry in ordered()) {
        if (examined++ >= _maxEntries || budget.remaining < 64) {
          budget.truncated = true;
          break;
        }
        final key = entry.key.toString();
        if (key.length > 256) {
          budget.truncated = true;
          continue;
        }
        final normalized = key.replaceAll(_nonLetters, '').toLowerCase();
        final numericUsage =
            entry.value is num &&
            const {'input', 'output', 'prompttokens'}.contains(normalized);
        if (!numericUsage &&
                (_privateKeys.contains(normalized) ||
                    normalized.contains('oracle') ||
                    normalized.contains('credential') ||
                    normalized.contains('secret') ||
                    normalized.contains('password') ||
                    normalized.contains('prompt') ||
                    normalized.contains('token') && entry.value is String) ||
            secrets.hasSecrets(key) ||
            _hostPath.hasMatch(key)) {
          budget.truncated = true;
          continue;
        }
        final keyBytes = utf8.encode(jsonEncode(key)).length + 2;
        if (!budget.take(keyBytes)) {
          break;
        }
        result[key] = _value(entry.value, depth + 1, budget);
      }
      if (value.length > examined) {
        budget.truncated = true;
      }
      return result;
    }
    if (value is Iterable) {
      final result = <dynamic>[];
      for (final item in value) {
        if (result.length >= _maxEntries || budget.remaining < 64) {
          budget.truncated = true;
          break;
        }
        result.add(_value(item, depth + 1, budget));
      }
      return result;
    }
    if (value is String) {
      // Do not expose a prefix of an unscanned secret or private prompt.
      if (value.length > maxStringLength) {
        budget.truncated = true;
        budget.take(32);
        return '[TRUNCATED: long text omitted]';
      }
      final safe =
          secrets.hasSecrets(value) || _inlineCredential.hasMatch(value)
          ? '[REDACTED]'
          : value.replaceAll(_hostPath, '[HOST_PATH]');
      final encoded = utf8.encode(jsonEncode(safe));
      if (encoded.length > maxStringLength || !budget.take(encoded.length)) {
        budget.truncated = true;
        return '[TRUNCATED]';
      }
      return safe;
    }
    final safe = value == null || value is num || value is bool
        ? value
        : '[REDACTED]';
    budget.take(utf8.encode(jsonEncode(safe)).length);
    return safe;
  }
}

class _EvidenceBudget {
  _EvidenceBudget(this.remaining);
  int remaining;
  bool truncated = false;

  bool take(int bytes) {
    if (bytes > remaining) {
      truncated = true;
      return false;
    }
    remaining -= bytes;
    return true;
  }
}
