import 'package:cc_infra/cc_infra.dart' show AgentPushAncestryCheck;
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/forge/github_client_types.dart'
    show GitHubRefusal;
import 'package:cc_server_core/src/forge/github_minter.dart'
    show classifyGitHubRepoRead;
import 'package:cc_server_core/src/forge/github_rest.dart';

final RegExp _owner = RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})$');
final RegExp _name = RegExp(r'^[A-Za-z0-9._-]{1,100}$');
final RegExp _oid = RegExp(r'^(?:[0-9a-f]{40}|[0-9a-f]{64})$');

/// The agent run gateway's question of whether GitHub already has `oid`
/// published in `owner/name` below `base`, asked with the push's own write
/// token through `GET /repos/{owner}/{repo}/compare/{base}...{oid}`.
///
/// `oid` is reachable from `base` exactly when GitHub answers 200 with
/// `ahead_by` 0: an ancestor answers `behind`, the tip itself `identical`.
/// A commit only a fork (or nothing) reaches answers `ahead`, an id the
/// repository does not know 404, and both are false, as is any other
/// refusal. A transport failure, an outage or a rate limit is null (GitHub
/// was not asked), written to the forge audit trail. `base` is `HEAD` (the
/// default branch) or an object id; a malformed argument is false without a
/// request.
AgentPushAncestryCheck githubPushAncestry(GitHubRest rest) =>
    ({
      required owner,
      required name,
      required base,
      required oid,
      required token,
    }) async {
      if (!_owner.hasMatch(owner) ||
          !_name.hasMatch(name) ||
          name == '.' ||
          name == '..' ||
          !_oid.hasMatch(oid) ||
          (base != 'HEAD' && !_oid.hasMatch(base))) {
        return false;
      }
      final response = await rest.send(
        'GET',
        '/repos/$owner/$name/compare/$base...$oid',
        query: const {'per_page': '1'},
        bearer: token,
      );
      bool? unanswered() {
        forgeAudit(ForgeAuditEvent.githubPushAncestryUnanswered, {
          'owner': owner,
          'repo': name,
          'base': base,
          'oid': oid,
          'status': response.status,
        }, token: token);
        return null;
      }

      if (response.status == 200) {
        final json = response.json;
        final ahead = json is Map ? json['ahead_by'] : null;
        return ahead is int ? ahead == 0 : unanswered();
      }
      if (response.status == 404) {
        return false;
      }
      if (response.unavailable ||
          classifyGitHubRepoRead(response) == GitHubRefusal.rateLimited) {
        return unanswered();
      }
      return false;
    };
