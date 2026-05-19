import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_infra/cc_infra_web.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';

import 'package:control_center/di/demo_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches a GitHub user's full profile (name, bio, contributions).
///
/// Resolved SERVER-SIDE over RPC (the thin client holds no GitHub token); a
/// public profile is global data keyed only by login, so the op is not
/// workspace-scoped. Auto-disposed when no widgets are listening.
/// GitHub App bots are skipped: GraphQL cannot resolve `login[bot]` as a User.
///
/// Every resolution seeds [cachedGitHubUserProfile], which is what lets a
/// surface render the display name on its FIRST frame instead of swapping it in
/// a round trip later — see [cachedGitHubUserProfile] for why that matters.
final githubUserProfileProvider = FutureProvider.autoDispose
    .family<GitHubUserProfile?, String>((ref, login) async {
      if (login.isEmpty || isGitHubBotLogin(login)) {
        return null;
      }
      // A demo server holds no forge credential and `github.*` is absent from
      // its op registry. The hovercard appears all over the PR surface, so an
      // ungated call put "Unknown op" under every avatar; a null profile is
      // the same state as a login GitHub has never heard of, which the card
      // already renders as plain initials.
      if (ref.watch(isDemoServerProvider)) {
        return null;
      }
      final data = await ref.watch(rpcClientProvider).call(
        'github.userProfile',
        {'login': login},
      );
      final profile = data['profile'];
      if (profile is! Map) {
        _rememberProfile(login, null);
        return null;
      }
      final parsed = GitHubUserProfile.fromWire(
        profile.cast<String, dynamic>(),
      );
      _rememberProfile(login, parsed);
      return parsed;
    });

/// Profiles resolved earlier in this session, keyed by lower-cased login.
///
/// The provider is `autoDispose`, so leaving a screen throws its result away
/// and the next screen showing the same person starts from nothing again. For
/// a hover card that is fine — nobody sees the gap. For anything rendered
/// INLINE it is a layout shift on every visit: the PR meta strip has only
/// `@login` to draw until the profile lands, then swaps in a name-plus-handle
/// pair roughly twice as wide, which re-wraps the strip and moves the whole
/// description down the page.
///
/// A plain module-level map rather than a `keepAlive`, because the value has to
/// be readable SYNCHRONOUSLY from `build` — a `FutureProvider` delivers
/// `AsyncLoading` on its first read no matter how warm its cache is, and that
/// first frame is precisely the one being fixed.
///
/// Never a substitute for the request: the provider still runs and still
/// overwrites this, so `ref.refresh` on the profile screen is authoritative.
final Map<String, GitHubUserProfile?> _profileMemo = {};
const int _maxMemoEntries = 256;

void _rememberProfile(String login, GitHubUserProfile? profile) {
  final key = login.toLowerCase();
  _profileMemo
    ..remove(key)
    ..[key] = profile;
  while (_profileMemo.length > _maxMemoEntries) {
    _profileMemo.remove(_profileMemo.keys.first);
  }
}

/// The profile for [login] if this session already resolved one, else null.
///
/// Read it to seed a first frame, then watch [githubUserProfileProvider] for
/// the authoritative value. A null answer means "not known yet", not "no such
/// user" — a login that genuinely has no profile memoizes as a null entry and
/// still reads back as null, which is the same rendering decision either way.
GitHubUserProfile? cachedGitHubUserProfile(String login) =>
    _profileMemo[login.toLowerCase()];

/// Drops every memoized profile.
@visibleForTesting
void resetGitHubUserProfileMemo() => _profileMemo.clear();
