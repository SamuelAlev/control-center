/// URLs of the desktop in-app update surface. Kept separate from the
/// conditional-import seam so the native implementation and the stub share
/// them without a library cycle.
library;

/// The macOS appcast attached to every published release. `releases/latest/
/// download/…` redirects to the newest PUBLISHED release's asset — drafts
/// stay invisible, which is the point. Separate feeds per OS: Sparkle and
/// WinSparkle both "take the newest item", so one combined feed would let a
/// Windows install try to apply a DMG.
const String kMacAppcastUrl =
    'https://github.com/SamuelAlev/control-center/releases/latest/download/appcast.xml';

/// The Windows x64 appcast (setup.exe enclosures for WinSparkle).
const String kWindowsAppcastUrl =
    'https://github.com/SamuelAlev/control-center/releases/latest/download/appcast-windows.xml';

/// The Windows ARM64 appcast. A feed of its own because WinSparkle 0.8 only
/// matches `sparkle:os="windows"` and cannot pick an item by architecture, so
/// a shared feed would hand an ARM64 install the x64 installer (or the
/// reverse).
const String kWindowsArm64AppcastUrl =
    'https://github.com/SamuelAlev/control-center/releases/latest/download/appcast-windows-arm64.xml';

/// The human fallback: newest published release page (the Linux path and the
/// no-backend answer).
const String kDesktopReleasesUrl =
    'https://github.com/SamuelAlev/control-center/releases/latest';
