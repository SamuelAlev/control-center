/// Web: there is no native windowing layer to ask, and the OS-notification
/// path this gates is desktop-only, so this answers "focused".
///
/// That is the conservative answer: it preserves the pre-focus-gating
/// behaviour (a notification whose surface is already on screen is suppressed)
/// rather than making a browser tab noisier than it was.
bool appWindowFocused() => true;
