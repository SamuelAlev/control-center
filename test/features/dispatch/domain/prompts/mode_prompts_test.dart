import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/mode_prompts.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ModePromptContext
  // ---------------------------------------------------------------------------

  group('ModePromptContext', () {
    test('constructor stores all fields', timeout: const Timeout.factor(2), () {
      const ctx = ModePromptContext(
        planGoal: 'Design auth system',
        prNumber: 42,
        repoFullName: 'acme/widget',
        prTitle: 'Add login',
        prBody: 'Implements OAuth flow',
        priority: 'high',
      );

      expect(ctx.planGoal, 'Design auth system');
      expect(ctx.prNumber, 42);
      expect(ctx.repoFullName, 'acme/widget');
      expect(ctx.prTitle, 'Add login');
      expect(ctx.prBody, 'Implements OAuth flow');
      expect(ctx.priority, 'high');
    });

    test(
      'all fields nullable, defaults to null',
      timeout: const Timeout.factor(2),
      () {
        const ctx = ModePromptContext();

        expect(ctx.planGoal, isNull);
        expect(ctx.prNumber, isNull);
        expect(ctx.repoFullName, isNull);
        expect(ctx.prTitle, isNull);
        expect(ctx.prBody, isNull);
        expect(ctx.priority, isNull);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // buildModeSystemBlock
  // ---------------------------------------------------------------------------

  group('buildModeSystemBlock', () {
    test(
      'chat returns buildChatModePrompt result (empty string)',
      timeout: const Timeout.factor(2),
      () {
        final result = buildModeSystemBlock(Mode.chat);
        expect(result, isEmpty);
      },
    );

    test(
      'review returns non-empty review-specific text',
      timeout: const Timeout.factor(2),
      () {
        final result = buildModeSystemBlock(Mode.review);
        expect(result, isNotEmpty);
        // Review-specific content should mention review-mode concepts.
        expect(result.contains('review'), isTrue);
      },
    );

    test(
      'plan names its output verb and carries the goal',
      timeout: const Timeout.factor(2),
      () {
        const ctx = ModePromptContext(planGoal: 'Refactor database layer');

        final result = buildModeSystemBlock(Mode.plan, ctx: ctx);

        expect(result, isNotEmpty);
        expect(result, contains('Refactor database layer'));
        // The deliverable is a `submit_plan` call, not a file. There is no
        // plans directory (the sandbox carve-out was removed) and no write tool
        // in this mode, so a path here would be a promise nothing can keep.
        expect(result, contains('submit_plan'));
        expect(result, isNot(contains('plans directory')));
      },
    );

    test(
      'plan with null context handles null gracefully',
      timeout: const Timeout.factor(2),
      () {
        final result = buildModeSystemBlock(Mode.plan);

        expect(result, isNotEmpty);
        // Should not throw and should produce a plan-mode prompt.
        expect(result, contains('Plan mode'));
        expect(result, contains('submit_plan'));
      },
    );

    test(
      'plan with empty context fields produces sensible output',
      timeout: const Timeout.factor(2),
      () {
        const ctx = ModePromptContext();
        final result = buildModeSystemBlock(Mode.plan, ctx: ctx);

        expect(result, isNotEmpty);
        // Should still be a valid plan prompt, just with empty values.
        expect(result, contains('Plan mode'));
        expect(result, contains('submit_plan'));
      },
    );

    test(
      'all Mode values handled by switch',
      timeout: const Timeout.factor(2),
      () {
        // Every enum value must produce a non-null result.
        for (final mode in Mode.values) {
          final result = buildModeSystemBlock(mode);
          // result is String (non-nullable), so a switch exhaustiveness
          // error would manifest at compile time. Verify runtime.
          expect(result, isNotNull);
          // Chat returns empty; others return non-empty.
          if (mode == Mode.chat) {
            expect(result, isEmpty);
          } else {
            expect(result, isNotEmpty);
          }
        }
      },
    );
  });
}
