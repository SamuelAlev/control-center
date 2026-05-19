import 'dart:async';
import 'dart:convert';

import 'package:control_center/features/newsfeed/domain/repositories/site_allowlist_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed [SiteAllowlistRepository].
///
/// Stores the allowlist as a JSON-encoded array under
/// `newsfeed.adblock.allowed_domains`. Pushes updates through a broadcast
/// [Stream] so widgets can react without polling.
class SharedPrefsSiteAllowlistRepository implements SiteAllowlistRepository {
  /// Creates a new [SharedPrefsSiteAllowlistRepository].
  SharedPrefsSiteAllowlistRepository(this._prefs)
    : _controller = StreamController<Set<String>>.broadcast() {
    // Seed late subscribers with the current value via [watch], not here.
  }

  static const _kAllowlistKey = 'newsfeed.adblock.allowed_domains';

  final SharedPreferences _prefs;
  final StreamController<Set<String>> _controller;

  Set<String> _readRaw() {
    final raw = _prefs.getString(_kAllowlistKey);
    if (raw == null || raw.isEmpty) {
      return const <String>{};
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => e as String).toSet();
    } on Object {
      return const <String>{};
    }
  }

  Future<void> _writeRaw(Set<String> domains) async {
    await _prefs.setString(_kAllowlistKey, jsonEncode(domains.toList()));
    _controller.add(Set<String>.unmodifiable(domains));
  }

  @override
  Stream<Set<String>> watch() async* {
    yield Set<String>.unmodifiable(_readRaw());
    yield* _controller.stream;
  }

  @override
  Future<Set<String>> read() async {
    return Set<String>.unmodifiable(_readRaw());
  }

  @override
  Future<void> add(String domain) async {
    final normalised = normalizeDomain(domain);
    if (normalised.isEmpty) {
      return;
    }
    final current = _readRaw();
    if (current.contains(normalised)) {
      return;
    }
    await _writeRaw({...current, normalised});
  }

  @override
  Future<void> remove(String domain) async {
    final normalised = normalizeDomain(domain);
    final current = _readRaw();
    if (!current.contains(normalised)) {
      return;
    }
    await _writeRaw(current.difference({normalised}));
  }

  @override
  bool isAllowedUrl(String url, Set<String> allowedDomains) {
    if (allowedDomains.isEmpty) {
      return false;
    }
    final host = hostOf(url);
    if (host.isEmpty) {
      return false;
    }
    for (final allowed in allowedDomains) {
      if (host == allowed || host.endsWith('.$allowed')) {
        return true;
      }
    }
    return false;
  }

  @override
  String hostOf(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.toLowerCase();
    } on FormatException {
      return '';
    }
  }

  @override
  String normalizeDomain(String input) {
    var s = input.trim().toLowerCase();
    if (s.isEmpty) {
      return '';
    }
    // Strip scheme.
    final schemeIdx = s.indexOf('://');
    if (schemeIdx >= 0) {
      s = s.substring(schemeIdx + 3);
    }
    // Strip path / query / fragment.
    final slashIdx = s.indexOf('/');
    if (slashIdx >= 0) {
      s = s.substring(0, slashIdx);
    }
    final queryIdx = s.indexOf('?');
    if (queryIdx >= 0) {
      s = s.substring(0, queryIdx);
    }
    final hashIdx = s.indexOf('#');
    if (hashIdx >= 0) {
      s = s.substring(0, hashIdx);
    }
    // Strip port.
    final colonIdx = s.indexOf(':');
    if (colonIdx >= 0) {
      s = s.substring(0, colonIdx);
    }
    // Strip a leading `www.` for friendlier UX — `www.example.com` and
    // `example.com` should resolve to the same allowlist entry.
    if (s.startsWith('www.')) {
      s = s.substring(4);
    }
    // Reject anything that doesn't look like a domain.
    if (!_domainLike.hasMatch(s)) {
      return '';
    }
    if (!s.contains('.')) {
      return '';
    }
    return s;
  }

  static final RegExp _domainLike = RegExp(r'^[a-z0-9.\-]+$');
}
