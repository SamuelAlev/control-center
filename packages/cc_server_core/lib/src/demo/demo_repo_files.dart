/// Short, readable trees the demo writes under each linked checkout.
///
/// Demo mode never clones git, so the IDE, file search and the PR file viewer
/// would otherwise open empty. These files are the after-state the open PRs
/// talk about — enough to click through, not a real repo.
library;

/// Repo name → relative path → UTF-8 body.
const Map<String, Map<String, String>> kDemoSnapshotFiles = {
  'evalkit': {
    'README.md': '''
# evalkit

LLM evaluation harness: budgets, graders, run groups.

Caps live on `EvalBudget`. Spend is recorded on `TokenLedger` so the run
card, the grader and the tests share one definition of remaining tokens.
''',
    'evalkit/__init__.py':
        'from evalkit.budget import EvalBudget, TokenLedger\n',
    'evalkit/budget.py': r'''from datetime import datetime, timezone


class EvalBudget:
    """All spend math goes through the ledger so the run card, the
    grader and the tests share one definition of remaining tokens."""

    def __init__(self, ledger):
        self._ledger = ledger

    def remaining(self, family, run_group_id):
        return self._cap(family) - self._ledger.spent(family)

    def _cap(self, family):
        return {
            "sonnet": 200_000,
            "haiku": 80_000,
            "opus": 400_000,
        }[family]


class TokenLedger:
    """One definition of spend, injectable for tests."""

    def __init__(self, now=None):
        self._now = now or (lambda: datetime.now(timezone.utc))
        self._rows = []

    def record(self, family, tokens):
        self._rows.append((family, tokens, self._now()))

    def spent(self, family):
        return sum(t for f, t, _ in self._rows if f == family)
''',
  },
  'retriever': {
    'README.md': '''
# retriever

Hybrid BM25 + embedding retrieval. Identifier queries (dataset ids,
citation keys) miss on dense-only search; RRF recovers them.
''',
    'retriever/hybrid.py': '''
class Retriever:
    def search(self, query, k=8):
        dense = self._dense.search(query, k * 2)
        sparse = self._bm25.search(query, k * 2)
        return rrf(dense, sparse)[:k]
''',
    'retriever/rrf.py': '''
def rrf(*rankings, k=60):
    scores = {}
    for ranking in rankings:
        for i, doc in enumerate(ranking):
            scores[doc.id] = scores.get(doc.id, 0) + 1 / (k + i + 1)
    return sorted(scores, key=scores.get, reverse=True)
''',
    'retriever/rerank.py': '''
class RerankTimeout(Exception):
    pass


class Reranker:
    def rerank(self, hits, query):
        pairs = [(query, h.text) for h in hits]
        try:
            return self._model.predict(pairs, timeout=self._timeout)
        except TimeoutError:
            raise RerankTimeout(self._timeout) from None
''',
  },
  'features': {
    'README.md': '''
# features

Online feature store. Late-arriving features backfill on read from the
offline store; lineage names every serving path a transform hits.
''',
    'features/store.py': '''
class FeatureStore:
    def get(self, name, entity, at):
        value = self._online.get(name, entity, at)
        if value is not None:
            return value
        return self._offline.get(name, entity, at, budget_ms=50)
''',
    'features/lineage.py': '''
class LineageGraph:
    def consumers(self, feature):
        return list(self._edges.get(feature, ()))
''',
  },
  'finetune': {
    'README.md': '''
# finetune

LoRA / QLoRA adapter training. Merge is keyed on the adapter hash so
two merges of the same adapter byte-compare.
''',
    'finetune/merge.py': '''
def merge_adapter(base, adapter):
    key = adapter.hash()
    if key in _cache:
        return _cache[key]
    merged = base.merge(adapter)
    _cache[key] = merged
    return merged
''',
  },
};
