/// Per-workspace egress customization for the enclosed browser.
///
/// A browser rig's egress gate is deny-by-default: the boot page is local
/// ([kBrowserRigHomeUrl]) and the only unconditionally admitted host is the
/// product's own site ([browserRigEgressAllowlist]). A workspace that wants
/// its enclosed browsers to reach anything else — an internal staging site,
/// a package mirror — names those hosts here, stored in the admin-gated
/// workspace settings store under [kRigBrowserEgressHostsSettingKey].
///
/// The value crosses from a workspace SETTING into the enclosure's egress
/// gate (`smolvm --allow-host`), so it is validated twice, exactly like the
/// custom image reference: client-side for feedback, and again at READ time
/// in [parseRigEgressHostsSetting] before the value is allowed anywhere near
/// a machine definition — the settings store is generic k/v and cannot be
/// trusted to hold a valid list.
library;

import 'dart:convert';

import 'package:cc_domain/features/rigs/domain/value_objects/browser_defaults.dart';

/// Workspace-settings key for the browser rig's extra egress hosts.
const String kRigBrowserEgressHostsSettingKey = 'rigs.browser.egressHosts';

/// The most hosts one workspace may add. The list lands on a machine-create
/// command line, so it is bounded by construction.
const int kRigEgressHostsMax = 100;

/// One entry of the rig egress vocabulary: an exact host
/// (`api.example.com`) or a subdomain wildcard (`*.example.com`). No scheme,
/// port, path or whitespace — the gate filters destinations, not URLs, and
/// smolvm's host entries already match subdomains of an exact entry.
final RegExp _kEgressHostPattern = RegExp(
  r'^(\*\.)?[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$',
);

/// Whether [entry] is safe to hand to the enclosure's egress gate: the host
/// syntax above, the DNS ceiling of 253 chars overall and 63 per label (a
/// longer label is never a real host, so it is always a typo).
bool isValidRigEgressHost(String entry) {
  if (entry.length > 253 || !_kEgressHostPattern.hasMatch(entry)) {
    return false;
  }
  final bare = entry.startsWith('*.') ? entry.substring(2) : entry;
  return bare.split('.').every((label) => label.length <= 63);
}

/// Parses the stored setting (a JSON array of host strings) into the entries
/// a rig's egress allowlist gains.
///
/// Re-validation at READ is the enforcement half of the contract (the write
/// path is a generic settings op that cannot reject a bad value per key):
/// anything that is not a valid entry is dropped rather than reaching the
/// egress gate, and blank/absent/corrupt collapses to the empty list —
/// "unconfigured" must never read as "allow everything" or as "refuse to
/// boot".
List<String> parseRigEgressHostsSetting(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const [];
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on Object {
    return const [];
  }
  if (decoded is! List) {
    return const [];
  }
  final seen = <String>{};
  for (final entry in decoded) {
    if (entry is! String) {
      continue;
    }
    final host = entry.trim().toLowerCase();
    if (isValidRigEgressHost(host)) {
      seen.add(host);
    }
    if (seen.length >= kRigEgressHostsMax) {
      break;
    }
  }
  return List.unmodifiable(seen);
}

/// Encodes [hosts] for the settings store: lowercased, trimmed, deduped,
/// capped at [kRigEgressHostsMax], as a JSON array. Invalid entries throw
/// [ArgumentError] — the write path (the settings UI) is where a typo must be
/// named, not silently dropped.
String encodeRigEgressHostsSetting(Iterable<String> hosts) {
  final seen = <String>{};
  for (final raw in hosts) {
    final host = raw.trim().toLowerCase();
    if (host.isEmpty) {
      continue;
    }
    if (!isValidRigEgressHost(host)) {
      throw ArgumentError.value(
        raw,
        'hosts',
        'Not a host or "*.subdomain" entry',
      );
    }
    seen.add(host);
    if (seen.length >= kRigEgressHostsMax) {
      break;
    }
  }
  return jsonEncode(seen.toList(growable: false));
}
