class SandboxRouteRule {
  SandboxRouteRule({
    required this.method,
    required this.pathPattern,
    this.description,
  });

  final String method;
  final RegExp pathPattern;
  final String? description;
}

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

  static bool isAllowed(String method, String path) {
    for (final rule in _rules) {
      if (rule.method == method && rule.pathPattern.hasMatch(path)) {
        return true;
      }
    }
    return false;
  }

  static List<SandboxRouteRule> get rules => List.unmodifiable(_rules);
}
