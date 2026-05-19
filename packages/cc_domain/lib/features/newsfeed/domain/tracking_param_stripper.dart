/// Pure-domain URL sanitiser that strips known tracking query parameters.
///
/// The set of parameters to strip is sourced from the uBlock Origin
/// `privacy-removeparam.txt` list (downloaded and cached by the
/// filter list service) and falls back to a small hard-coded set when
/// nothing has been cached yet.
///
/// To keep the function pure and fast, the caller is responsible for
/// reading the cached parameter set once (e.g. in a provider) and passing
/// it as [knownParams].
String stripTrackingParams(String url, {required Set<String> knownParams}) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return url;
  }
  final query = uri.queryParametersAll;
  if (query.isEmpty) {
    return url;
  }

  final cleaned = Map<String, List<String>>.from(query);
  var removedAny = false;
  for (final key in query.keys) {
    if (knownParams.contains(key.toLowerCase())) {
      cleaned.remove(key);
      removedAny = true;
    }
  }
  if (!removedAny) {
    return url;
  }

  if (cleaned.isEmpty) {
    return Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.port,
      path: uri.path,
      fragment: uri.hasFragment ? uri.fragment : null,
    ).toString();
  }
  return uri.replace(queryParameters: cleaned).toString();
}

/// Hard-coded fallback set of well-known tracking parameters.
/// Used when the remote `privacy-removeparam.txt` has never been downloaded.
Set<String> defaultRemoveParams() {
  return const {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
    'utm_id',
    'utm_source_platform',
    'utm_creative_format',
    'utm_marketing_tactic',
    'fbclid',
    'gclid',
    'gclsrc',
    'dclid',
    'msclkid',
    'yclid',
    'twclid',
    'igshid',
    'igsh',
    'wt_mc',
    'wt_mc_id',
    'spm',
    '__s',
    'mc_cid',
    'mc_eid',
    'epik',
    'vero_id',
    'vero_conv',
    'hmb_campaign',
    'hmb_medium',
    'hmb_source',
    'sc_campaign',
    'sc_channel',
    'sc_content',
    'sc_medium',
    'trk_campaign',
    'trk_id',
    'tblci',
    'tpclid',
    'irclickid',
    'cvid',
    'ocid',
    'tclid',
    'guce_referrer',
    'guce_referrer_sig',
  };
}
