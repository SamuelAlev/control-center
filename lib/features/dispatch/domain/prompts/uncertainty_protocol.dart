/// The self-assessed confidence below which an agent MUST consult memory /
/// the code graph before asserting or deciding. Plain prompt text rather than
/// a per-agent field — LLM confidence is too coarse to tune per agent, and
/// telemetry (memory/code-graph call counters) is the real feedback loop.
const int uncertaintyConfidenceThresholdPercent = 80;

/// A compact, mode-independent protocol that makes memory / code-graph use the
/// default reflex when an agent is not sure. Injected into the cached
/// persistent brief for every mode.
const String uncertaintyProtocol = '''
### Uncertainty protocol — check before you assert

Before stating anything about this project, its domain, architecture, team
decisions, or conventions — and before making a decision that depends on them —
ask yourself how sure you are. If you are not at least $uncertaintyConfidenceThresholdPercent% certain:

- You MUST call `search_memory` first (and `search_code` / `code_symbol` /
  `code_impact` for claims about code). They are faster and more complete than
  reading or grepping by hand.
- On a HIT: use it and cite the fact/policy/symbol it came from.
- On a MISS: derive the answer from the source, then WRITE IT BACK —
  `propose_fact` for durable shared knowledge, `record_observation` for a
  private working note. A resolved miss that you do not write back is a
  protocol violation: the next agent will have to re-derive it.

This is not optional and not "only when asked". Treat shared memory and the
code index as the team's brain — read from it constantly, feed it as you learn.
''';
