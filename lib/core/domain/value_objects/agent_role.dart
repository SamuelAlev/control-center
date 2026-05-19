enum AgentRole {
  ceo('CEO', 'Chief Executive Officer — strategic direction and governance'),
  coder('Coder', 'Software engineer focused on writing and reviewing code'),
  reviewer('Reviewer', 'PR and code review specialist'),
  qa('QA', 'Quality assurance engineer focused on testing'),
  designer('Designer', 'UX/UI designer focused on user experience'),
  security('Security', 'Security engineer focused on vulnerability assessment'),
  devops('DevOps', 'Infrastructure and deployment specialist'),
  pm('PM', 'Product manager focused on requirements and prioritization'),
  general('General', 'General-purpose agent with no specialty');

  const AgentRole(this.label, this.description);

  final String label;
  final String description;

  static AgentRole? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    return AgentRole.values.where(
      (r) => r.name.toLowerCase() == value.toLowerCase(),
    ).firstOrNull;
  }
}
