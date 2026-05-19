import 'dart:convert';

/// The saveable shape of one SSO connection, with the server's own defaults.
///
/// One list, used for the dirty check, the save payload and the reset, so the
/// three can never disagree about what a field's default is.
const Map<String, Object?> kSsoConnectionDefaults = <String, Object?>{
  'enabled': false,
  'issuer': '',
  'clientId': '',
  'clientSecret': '',
  'groupsClaim': 'groups',
  'idpMetadataXml': '',
  'spEntityId': '',
  'emailAttribute': 'email',
  'displayNameAttribute': 'displayName',
  'groupsAttribute': 'groups',
  'defaultRole': 'member',
  'autoMember': true,
  'allowJit': true,
  'allowIdpInitiated': false,
  'wantResponseSigned': false,
  'clockSkewSeconds': 90,
};

/// A stable string for the saveable subset of a connection, so two maps that
/// differ only in `updatedAt` or key order compare equal.
///
/// The dirty check compares canonical strings rather than setting a flag on
/// edit: typing a character and deleting it again is not unsaved work, and a
/// save bar that says otherwise stops being believed.
String ssoCanonical(Map<String, dynamic> values) {
  final roleMap = normalizeSsoRoleMap(values['groupRoleMap']);
  final sortedKeys = roleMap.keys.toList()..sort();
  return jsonEncode({
    for (final entry in kSsoConnectionDefaults.entries)
      entry.key: values[entry.key] ?? entry.value,
    'groupRoleMap': {for (final key in sortedKeys) key: roleMap[key]},
  });
}

/// The group-to-role map as plain strings, whatever shape it arrived in.
Map<String, String> normalizeSsoRoleMap(Object? raw) => <String, String>{
  if (raw is Map)
    for (final entry in raw.entries) '${entry.key}': '${entry.value}',
};

/// The full connection payload for `sso.saveConfig`, defaults included.
///
/// A kind that has never been saved comes back from `sso.getConfig` as an EMPTY
/// map, so spreading the loaded values alone omits `enabled` — which
/// `sso.saveConfig` declares required and refuses the call over. Seeding from
/// the defaults means a first save carries every field whether or not the admin
/// happened to touch it.
Map<String, dynamic> ssoSaveArgs(String kind, Map<String, dynamic> values) => {
  ...kSsoConnectionDefaults,
  ...values,
  'kind': kind,
  'groupRoleMap': normalizeSsoRoleMap(values['groupRoleMap']),
};
