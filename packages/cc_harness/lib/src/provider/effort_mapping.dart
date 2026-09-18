/// Maps the unified [ReasoningEffort] knob onto each provider's wire vocabulary.
///
/// The harness speaks one effort scale (`minimal → xhigh`); every provider
/// expresses reasoning depth differently, so these pure functions translate at
/// the provider boundary. Kept together (and unit-tested) so no provider
/// reinvents the mapping.
library;

import 'package:cc_harness/src/provider/reasoning_effort.dart';

/// Anthropic `output_config.effort` value for [effort].
///
/// Current Anthropic models accept `low | medium | high | xhigh | max` and
/// reject a fixed `budget_tokens`; the harness pairs this with
/// `thinking:{type:'adaptive'}`. There is no `minimal` tier upstream, so the
/// lightest harness effort maps to `low`.
String anthropicEffort(ReasoningEffort effort) => switch (effort) {
  ReasoningEffort.minimal => 'low',
  ReasoningEffort.low => 'low',
  ReasoningEffort.medium => 'medium',
  ReasoningEffort.high => 'high',
  ReasoningEffort.xhigh => 'xhigh',
};

/// OpenAI `reasoning_effort` value for [effort].
///
/// The OpenAI reasoning scale is `minimal | low | medium | high`; the harness's
/// `xhigh` collapses onto `high`.
String openAiEffort(ReasoningEffort effort) => switch (effort) {
  ReasoningEffort.minimal => 'minimal',
  ReasoningEffort.low => 'low',
  ReasoningEffort.medium => 'medium',
  ReasoningEffort.high => 'high',
  ReasoningEffort.xhigh => 'high',
};

/// Google Gemini `thinkingConfig.thinkingLevel` token for [effort].
///
/// Only used by a native Gemini transport; the OpenAI-compatible Gemini path
/// leaves reasoning to the endpoint. Gemini's public levels are coarse, so the
/// harness scale is bucketed. verify: current Gemini thinkingLevel vocabulary.
String googleThinkingLevel(ReasoningEffort effort) => switch (effort) {
  ReasoningEffort.minimal => 'low',
  ReasoningEffort.low => 'low',
  ReasoningEffort.medium => 'medium',
  ReasoningEffort.high => 'high',
  ReasoningEffort.xhigh => 'high',
};

/// The effort vocabulary to assume for a reasoning model whose catalog entry
/// documents none, keyed by the models.dev provider id.
///
/// This is the picker-side reflection of the wire mappings above: the levels a
/// provider can actually DISTINGUISH. [anthropicEffort] maps `minimal` onto
/// `low`, so offering `minimal` on an Anthropic model would be a second knob
/// position with identical behavior — but `xhigh` is real and was silently
/// clamped to `high` by `ThinkingConfig.resolve` when the flat low/medium/high
/// fallback stood in for every provider. [openAiEffort] is the mirror image:
/// `minimal` is a real OpenAI tier, `xhigh` collapses onto `high`. Providers
/// with no dedicated mapping keep the conventional three-step knob.
List<ReasoningEffort> defaultProviderEfforts(String providerId) =>
    switch (providerId) {
      'anthropic' => const [
        ReasoningEffort.low,
        ReasoningEffort.medium,
        ReasoningEffort.high,
        ReasoningEffort.xhigh,
      ],
      'openai' => const [
        ReasoningEffort.minimal,
        ReasoningEffort.low,
        ReasoningEffort.medium,
        ReasoningEffort.high,
      ],
      _ => const [
        ReasoningEffort.low,
        ReasoningEffort.medium,
        ReasoningEffort.high,
      ],
    };
