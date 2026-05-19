import 'package:nativeapi/nativeapi.dart' show WindowManager;

/// Desktop: whether one of this app's windows currently holds keyboard focus.
///
/// Keyboard focus is the right test for "the operator can see this": a key
/// window means the app is frontmost. It also selects the right windows on its
/// own — the HUDs (focus pill, meeting toolbar, mini player) are created with
/// `isFocusable = false` precisely so they can never become key, because they
/// are meant to stay up while the operator works in ANOTHER app. One of them
/// being on screen says nothing about whether this app is.
///
/// Mirrors `WindowVisibilityGuard`'s own focus probe, which is the proof that
/// class trusts to overrule the platform's lifecycle state.
bool appWindowFocused() {
  for (final window in WindowManager.instance.getAll()) {
    if (window.isVisible && !window.isMinimized && window.isFocused) {
      return true;
    }
  }
  return false;
}
