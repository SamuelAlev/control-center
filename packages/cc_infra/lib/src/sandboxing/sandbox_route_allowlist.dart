/// A rule that defines an allowed route for sandboxed agent communication.
///
/// Each rule specifies an HTTP method, a path pattern (as a [RegExp]), and an
/// optional human-readable description.
class SandboxRouteRule {
  /// Creates a [SandboxRouteRule].
  ///
  /// The [method] and [pathPattern] parameters are required; [description] is
  /// optional.
  SandboxRouteRule({
    required this.method,
    required this.pathPattern,
    this.description,
  });

  /// The HTTP method for this route rule (e.g. `GET`, `POST`).
  final String method;
  /// A regular expression that the request path must match for this rule to apply.
  final RegExp pathPattern;
  /// An optional human-readable description of this route rule.
  final String? description;
}

/// An allowlist of HTTP routes that sandboxed agents are permitted to access.
///
/// The allowlist contains a fixed set of [SandboxRouteRule] entries covering
/// common API endpoints such as GitHub REST and GraphQL, GitLab projects, and
/// the Control Center MCP endpoint.
class SandboxRouteAllowlist {
  SandboxRouteAllowlist._();
  static final List<SandboxRouteRule> _rules = [
    SandboxRouteRule(
      method: 'GET',
      pathPattern: RegExp(r'^/api/v4/projects'),
      description: 'GitLab projects',
    ),
    SandboxRouteRule(
      method: 'GET',
      pathPattern: RegExp(r'^/repos/[^/]+/[^/]+'),
      description: 'GitHub repos REST',
    ),
    SandboxRouteRule(
      method: 'POST',
      pathPattern: RegExp(r'^/repos/[^/]+/[^/]+/git/commits'),
      description: 'GitHub create commit',
    ),
    SandboxRouteRule(
      method: 'POST',
      pathPattern: RegExp(r'^/repos/[^/]+/[^/]+/git/refs'),
      description: 'GitHub create ref',
    ),
    SandboxRouteRule(
      method: 'PATCH',
      pathPattern: RegExp(r'^/repos/[^/]+/[^/]+/git/refs/'),
      description: 'GitHub update ref',
    ),
    SandboxRouteRule(
      method: 'POST',
      pathPattern: RegExp(r'^/repos/[^/]+/[^/]+/pulls'),
      description: 'GitHub create PR',
    ),
    SandboxRouteRule(
      method: 'GET',
      pathPattern: RegExp(r'^/repos/[^/]+/[^/]+/pulls'),
      description: 'GitHub list PRs',
    ),
    SandboxRouteRule(
      method: 'GET',
      pathPattern: RegExp(r'^/repos/[^/]+/[^/]+/contents/'),
      description: 'GitHub get content',
    ),
    SandboxRouteRule(
      method: 'PUT',
      pathPattern: RegExp(r'^/repos/[^/]+/[^/]+/contents/'),
      description: 'GitHub create/update content',
    ),
    SandboxRouteRule(
      method: 'GET',
      pathPattern: RegExp(r'^/repos/[^/]+/[^/]+/pulls/\d+/'),
      description: 'GitHub PR details',
    ),
    SandboxRouteRule(
      method: 'GET',
      pathPattern: RegExp(r'^/graphql'),
      description: 'GitHub GraphQL',
    ),
    SandboxRouteRule(
      method: 'POST',
      pathPattern: RegExp(r'^/graphql'),
      description: 'GitHub GraphQL',
    ),
    SandboxRouteRule(
      method: 'GET',
      pathPattern: RegExp(r'^/mcp'),
      description: 'Control Center MCP endpoint',
    ),
    SandboxRouteRule(
      method: 'POST',
      pathPattern: RegExp(r'^/mcp'),
      description: 'Control Center MCP endpoint',
    ),
  ];

  /// Checks whether the given HTTP [method] and [path] are allowed by any rule
  /// in the allowlist.
  ///
  /// Returns `true` if at least one rule matches, `false` otherwise.
  static bool isAllowed(String method, String path) {
    for (final rule in _rules) {
      if (rule.method == method && rule.pathPattern.hasMatch(path)) {
        return true;
      }
    }
    return false;
  }

  /// Returns an unmodifiable view of the current allowlist rules.
  static List<SandboxRouteRule> get rules => List.unmodifiable(_rules);
}
