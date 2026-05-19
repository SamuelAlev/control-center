/// Web variant of the identity-probe HTTP client factory: browser TLS
/// validation cannot (and must not) be bypassed, so the probe keeps the
/// default strict client. Mirrors `identity_probe_client.dart`.
library;

import 'package:http/http.dart' as http;

/// Returns the default (strict-TLS) client factory.
http.Client Function() identityProbeClientFactory(Uri httpBase) =>
    http.Client.new;
