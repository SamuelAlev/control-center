// Path heuristics shared by every surface that reasons about what a changed
// file *is* — the ship/show/ask classifier, the cohort layer planner (tests
// read last), the area risk score (critical-path hits) and the test-impact
// mapper (which inbound callers count as coverage).
//
// These were duplicated per call site before; a PR that touches `auth/` must
// be "critical path" to all of them or the surfaces contradict each other.

/// Path fragments that indicate high-risk production code.
const kCriticalPathFragments = [
  'auth',
  'security',
  'payment',
  'billing',
  'migration',
  'schema',
  'database',
  '/core/',
  '/api/',
  '/shared/',
];

/// Path fragments that mark a file as a test.
const kTestPathFragments = ['test/', '_test.', 'spec/', '_spec.'];

/// File extensions considered documentation-only.
const kDocExtensions = {'md', 'txt', 'rst', 'adoc'};

/// Whether [path] looks like a test file.
bool isTestPath(String path) {
  final lower = path.toLowerCase();
  return kTestPathFragments.any(lower.contains);
}

/// Whether [path] looks like high-risk production code.
bool isCriticalPath(String path) {
  final lower = path.toLowerCase();
  return kCriticalPathFragments.any(lower.contains);
}

/// The critical-path fragments [path] matches, in declaration order. Empty when
/// the path is not on a critical path.
List<String> criticalPathHits(String path) {
  final lower = path.toLowerCase();
  return [
    for (final frag in kCriticalPathFragments)
      if (lower.contains(frag)) frag,
  ];
}

/// Whether [path] is documentation-only by extension.
bool isDocPath(String path) {
  final i = path.lastIndexOf('.');
  if (i < 0 || i == path.length - 1) {
    return false;
  }
  return kDocExtensions.contains(path.substring(i + 1).toLowerCase());
}
