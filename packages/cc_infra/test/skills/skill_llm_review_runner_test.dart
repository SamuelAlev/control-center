import 'dart:async';

import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/model_routing/domain/services/model_catalog.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/skills/skill_llm_review_runner.dart';
import 'package:test/test.dart';

/// Exercises [SkillLlmReviewRunner] with a fake provider factory that streams
/// canned LLM replies. Covers: pass/warn/quarantine verdict tightening, JSON
/// extraction from fenced prose, findings synthesis, unparseable-reply fallback
/// to warn, error-stream → fail-OPEN behavior, and the tighten-only guarantee
/// (an LLM pass cannot lower a static quarantine).
void main() {
  late _FakeFactory factory;
  late _FakeCredStore creds;
  late ModelCatalog catalog;

  setUp(() {
    factory = _FakeFactory();
    creds = _FakeCredStore();
    catalog = _CatalogWithSmall();
  });

  SkillLlmReviewRunner runner({
    Duration timeout = const Duration(seconds: 5),
  }) => SkillLlmReviewRunner(
    credentials: creds,
    catalog: catalog,
    factory: factory,
    timeout: timeout,
  );

  SkillScanResult staticPass() => const SkillScanResult(
    verdict: SkillScanVerdict.pass,
    findings: [],
    manifest: SkillCapabilityManifest(),
    rulesVersion: 1,
  );

  SkillScanResult staticQuarantine() => const SkillScanResult(
    verdict: SkillScanVerdict.quarantine,
    findings: [
      SkillScanFinding(
        ruleId: 'curl_pipe_bash',
        verdict: SkillScanVerdict.quarantine,
        message: 'curl|bash',
        file: 'SKILL.md',
      ),
    ],
    manifest: SkillCapabilityManifest(needsBash: true),
    rulesVersion: 1,
  );

  group('SkillLlmReviewRunner.review — verdict parsing', () {
    test('LLM pass keeps a static pass as pass and sets llmReviewed', () async {
      factory.provider = _CannedProvider([
        const LlmTextDelta('{"verdict":"pass"}'),
      ]);
      final result = await runner().review(
        SkillBundle.single('s', 'hi'),
        staticPass(),
      );
      expect(result.verdict, SkillScanVerdict.pass);
      expect(result.llmReviewed, isTrue);
    });

    test('LLM warn tightens a static pass to warn', () async {
      factory.provider = _CannedProvider([
        const LlmTextDelta('{"verdict":"warn","reason":"suspicious wording"}'),
      ]);
      final result = await runner().review(
        SkillBundle.single('s', 'hi'),
        staticPass(),
      );
      expect(result.verdict, SkillScanVerdict.warn);
      // warn on no findings → synthesizes a finding from the reason.
      expect(
        result.findings.any((f) => f.message.contains('suspicious wording')),
        isTrue,
      );
    });

    test('LLM quarantine tightens a static pass to quarantine', () async {
      factory.provider = _CannedProvider([
        const LlmTextDelta('{"verdict":"quarantine","reason":"exfil"}'),
      ]);
      final result = await runner().review(
        SkillBundle.single('s', 'hi'),
        staticPass(),
      );
      expect(result.verdict, SkillScanVerdict.quarantine);
    });

    test('tighten-only: LLM pass cannot lower a static quarantine', () async {
      factory.provider = _CannedProvider([
        const LlmTextDelta('{"verdict":"pass"}'),
      ]);
      final result = await runner().review(
        SkillBundle.single('s', 'hi'),
        staticQuarantine(),
      );
      expect(result.verdict, SkillScanVerdict.quarantine);
      // The static finding is preserved.
      expect(result.findings.any((f) => f.ruleId == 'curl_pipe_bash'), isTrue);
    });
  });

  group('SkillLlmReviewRunner.review — JSON extraction', () {
    test(
      'extracts the JSON object from fenced/markdown-wrapped replies',
      () async {
        factory.provider = _CannedProvider([
          const LlmTextDelta(
            'Here is my review:\n```json\n{"verdict":"warn",'
            '"reason":"r","findings":[{"message":"m","file":"f.md"}]}\n```\nthanks',
          ),
        ]);
        final result = await runner().review(
          SkillBundle.single('s', 'hi'),
          staticPass(),
        );
        expect(result.verdict, SkillScanVerdict.warn);
        expect(
          result.findings.any((f) => f.file == 'f.md' && f.message == 'm'),
          isTrue,
        );
      },
    );

    test('unparseable reply falls back to warn (tighten-only)', () async {
      factory.provider = _CannedProvider([
        const LlmTextDelta('no json here at all'),
      ]);
      final result = await runner().review(
        SkillBundle.single('s', 'hi'),
        staticPass(),
      );
      expect(result.verdict, SkillScanVerdict.warn);
      expect(result.llmReviewed, isTrue);
      expect(
        result.findings.any((f) => f.message.contains('unparseable')),
        isTrue,
      );
    });

    test(
      'warn verdict with empty findings synthesizes one from reason',
      () async {
        factory.provider = _CannedProvider([
          const LlmTextDelta('{"verdict":"warn","reason":""}'),
        ]);
        final result = await runner().review(
          SkillBundle.single('s', 'hi'),
          staticPass(),
        );
        expect(result.verdict, SkillScanVerdict.warn);
        expect(
          result.findings.any((f) => f.message == 'Flagged by LLM review.'),
          isTrue,
        );
      },
    );
  });

  group('SkillLlmReviewRunner.review — error / timeout', () {
    test('provider error stream surfaces as a thrown StateError', () async {
      factory.provider = _CannedProvider([
        const LlmError('boom', retryable: false),
      ]);
      await expectLater(
        runner().review(SkillBundle.single('s', 'hi'), staticPass()),
        throwsA(isA<StateError>()),
      );
    });

    test('timeout throws TimeoutException', () async {
      // A provider that never emits → drains forever → hits the timeout.
      factory.provider = _HangingProvider();
      await expectLater(
        runner(
          timeout: const Duration(milliseconds: 50),
        ).review(SkillBundle.single('s', 'hi'), staticPass()),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('SkillLlmReviewRunner.review — prompt rendering', () {
    test('bundles files are included and truncated past 8000 chars', () async {
      factory.provider = _CannedProvider([
        const LlmTextDelta('{"verdict":"pass"}'),
      ]);
      final long = 'x' * 9000;
      await runner().review(
        SkillBundle(
          slug: 'big',
          files: {'SKILL.md': long, 'lib.dart': 'short'},
        ),
        staticPass(),
      );
      final prompt = factory.lastPrompt;
      expect(prompt, contains('--- SKILL.md ---'));
      expect(prompt, contains('--- lib.dart ---'));
      expect(prompt, contains('…')); // truncation marker
    });
  });
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// A [HarnessProviderFactory] that returns a single canned provider.
class _FakeFactory extends HarnessProviderFactory {
  LlmProviderPort provider = _CannedProvider(const []);

  String lastPrompt = '';

  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) => _PromptCapture(provider, this);
}

/// Wraps the canned provider and records the rendered user prompt.
class _PromptCapture implements LlmProviderPort {
  _PromptCapture(this._inner, this._factory);

  final LlmProviderPort _inner;
  final _FakeFactory _factory;

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) {
    if (messages.isNotEmpty) {
      _factory.lastPrompt = messages.first.textContent;
    }
    _factory.provider = _inner;
    return _inner.complete(messages: messages, tools: tools, config: config);
  }

  @override
  String get displayName => 'fake';

  @override
  String get defaultModel => 'fake-model';

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

/// A provider that streams a fixed list of events then completes.
class _CannedProvider implements LlmProviderPort {
  _CannedProvider(this.events);
  final List<LlmEvent> events;

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) => Stream.fromIterable(events);

  @override
  String get displayName => 'canned';

  @override
  String get defaultModel => 'canned';

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

/// A provider that never emits and never completes — drives the runner into
/// its timeout.
class _HangingProvider implements LlmProviderPort {
  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) {
    // Intentionally never closed: the stream must hang until the runner's
    // timeout fires.
    // ignore: close_sinks
    final ctrl = StreamController<LlmEvent>();
    return ctrl.stream;
  }

  @override
  String get displayName => 'hanging';

  @override
  String get defaultModel => 'hanging';

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

/// A [ProviderCredentialStore] returning null for every provider.
class _FakeCredStore implements ProviderCredentialStore {
  @override
  Future<ProviderCredential?> activeCredential(String providerId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

/// A [ModelCatalog] whose `modelSmall()` returns a fixed Anthropic model.
class _CatalogWithSmall implements ModelCatalog {
  @override
  ModelInfo? modelSmall({String? providerId, DateTime? now}) => const ModelInfo(
    id: 'claude-haiku',
    providerId: 'anthropic',
    name: 'Claude Haiku',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
