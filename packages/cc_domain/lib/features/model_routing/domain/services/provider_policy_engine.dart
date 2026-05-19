import 'package:cc_domain/features/model_routing/domain/entities/provider_policy.dart';
import 'package:cc_domain/features/model_routing/domain/services/wildcard.dart';

/// Evaluates provider-governance policy with glob allow/deny statements and
/// last-match-wins precedence.
///
/// Statements are evaluated in order (lowest-precedence layer first). The
/// *last* statement whose action **and** resource globs both match the query
/// decides the effect; if none match, a caller-supplied fallback is used.
/// Because higher layers (workspace > user > global, see [PolicyLayer]) are
/// appended last by [PolicyDocument], a workspace rule overrides a conflicting
/// global rule.
class ProviderPolicyEngine {
  /// Creates an engine over a [PolicyDocument].
  const ProviderPolicyEngine(this.document);

  /// Builds an engine from an unordered statement list.
  ProviderPolicyEngine.fromStatements(Iterable<PolicyStatement> statements)
    : document = PolicyDocument(statements);

  /// The policy document (statements ordered lowest → highest precedence).
  final PolicyDocument document;

  /// Resolves the effect for an ([action], [resource]) pair, defaulting to
  /// [fallback] when no statement matches.
  PolicyEffect evaluate(
    String action,
    String resource, {
    PolicyEffect fallback = PolicyEffect.allow,
  }) {
    PolicyEffect? result;
    for (final stmt in document.statements) {
      if (Wildcard.match(action, stmt.action) &&
          Wildcard.match(resource, stmt.resource)) {
        result = stmt.effect; // last match wins → keep overwriting
      }
    }
    return result ?? fallback;
  }

  /// Whether a provider may be used (the catalog `finalize` gate).
  bool allowsProvider(String providerId) =>
      evaluate('provider.use', providerId) == PolicyEffect.allow;
}
