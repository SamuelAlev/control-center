/// The role an agent fills within a workspace — determines its specialty and capabilities.
enum AgentRole {
/// CEO — strategic direction and governance.
  ceo('CEO', 'Chief Executive Officer — strategic direction and governance'),
/// Coder — writes and reviews code.
  coder('Coder', 'Software engineer focused on writing and reviewing code'),
/// Reviewer — PR and code review specialist.
  reviewer('Reviewer', 'PR and code review specialist'),
/// QA — quality assurance and testing.
  qa('QA', 'Quality assurance engineer focused on testing'),
/// Designer — UX/UI design.
  designer('Designer', 'UX/UI designer focused on user experience'),
/// Security — vulnerability assessment and hardening.
  security('Security', 'Security engineer focused on vulnerability assessment'),
/// DevOps — infrastructure and deployment.
  devops('DevOps', 'Infrastructure and deployment specialist'),
/// PM — product management, requirements, and prioritization.
  pm('PM', 'Product manager focused on requirements and prioritization'),
/// General-purpose agent with no specialty.
  general('General', 'General-purpose agent with no specialty');

/// Creates an [AgentRole] with a display label and description.

  const AgentRole(this.label, this.description);

/// Human-readable display label.
  final String label;

/// Longer descriptive text for tooltips and onboarding.
  final String description;

/// Parses a string value (case-insensitive) into an [AgentRole], or `null`
/// if no match is found.
  static AgentRole? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    return AgentRole.values.where(
      (r) => r.name.toLowerCase() == value.toLowerCase(),
    ).firstOrNull;
  }
}
