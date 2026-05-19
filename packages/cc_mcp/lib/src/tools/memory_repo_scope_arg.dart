/// The shared `repo` argument every memory tool accepts.
///
/// Declared once so the write tools and the read tools describe the scope
/// identically — an agent that learns the argument on `propose_fact` uses it
/// correctly on `search_memory`.
const Map<String, dynamic> kMemoryRepoArg = {
  'type': 'string',
  'description':
      'OPTIONAL. Scopes this to one repository — its id, its "owner/name", '
      'or the scope slug shown by list_memory_domains. Omit for knowledge '
      'that holds across the whole workspace (team conventions, personal '
      'preferences). Use it for anything true of ONE codebase (its '
      'architecture, its build quirks, its deploy steps).',
};

/// The `repo` argument as it reads on a READ tool, where it ranks rather than
/// filters.
///
/// Stated explicitly because the natural reading of a `repo` argument on a
/// search is "only this repo", and that is not what it does: workspace-wide
/// memory must keep surfacing or a general preference would vanish the moment
/// a caller named a repo.
const Map<String, dynamic> kMemoryRepoBoostArg = {
  'type': 'string',
  'description':
      'OPTIONAL. The repository you are working in — its id, its "owner/name", '
      'or a scope slug. This RANKS results, it does not filter them: memory '
      'scoped to this repo comes first, while workspace-wide memory and other '
      'repos\' memory are still returned below it.',
};
