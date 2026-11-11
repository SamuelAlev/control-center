/// The `data.kind` (with the unauthorized code) and environment error code of
/// a refusal to run a definition on the server itself that the current server
/// owner has not approved.
///
/// Distinct from `server_owner_required`: the owner meets it too, for a
/// definition saved before approvals were recorded, by someone else, or under
/// a previous owner. The owner approves one by saving it.
const String environmentHostUnapprovedKind = 'environment.host_unapproved';
