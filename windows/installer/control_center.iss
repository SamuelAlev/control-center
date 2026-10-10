; Inno Setup script for Control Center (Windows).
;
;
; Compiled by scripts/release/windows_package.sh (from release.yml), once per
; Windows architecture:
;   ISCC.exe /DAppVersion=<version> /DTargetArch=x64|arm64 windows/installer/control_center.iss
;
; TargetArch (default x64) selects the Flutter output directory, the
; architecture gate and the output name (Control-Center-<version>-<arch>-setup).
; Both variants share one AppId and install directory, so the arm64 installer
; upgrades an x64 install in place (and vice versa) rather than installing a
; second copy beside it.
;
; Packages the entire `flutter build windows --release` output (the exe, the
; Flutter runtime DLLs, the bundled native FFI DLLs and the data/ folder) into
; a per-user installer with Start-menu + optional desktop shortcuts and an
; uninstaller. The installer is unsigned unless WINDOWS_CERT is configured, so
; first-run shows a SmartScreen warning (More info -> Run anyway).

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#ifndef TargetArch
  #define TargetArch "x64"
#endif
#if TargetArch != "x64" && TargetArch != "arm64"
  #error TargetArch must be x64 or arm64
#endif

#define AppName "Control Center"
#define AppPublisher "Samuel Alev"
#define AppExeName "control_center.exe"
#define AppURL "https://github.com/SamuelAlev/control-center"
; Directory containing this .iss is <repo>\windows\installer\ — go up two levels.
#define RepoRoot SourcePath + "..\..\"

[Setup]
; Stable application identity (do not change between releases).
AppId={{8F3A6B2C-1D4E-4F5A-9C7B-2E1D3A4B5C6D}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Per-user install — no administrator elevation required.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; x64compatible, NOT x64. Inno Setup 6.3 renamed the old `x64` identifier to
; `x64os` — "native x64 Windows only, not via emulation" — so `x64` rejected
; Windows 11 on Arm (the common Apple-Silicon VM) with the unhelpfully generic
; "This program does not support the version of Windows your computer is
; running." (6.3 also retired the OnlyOnTheseArchitectures message, which is why
; an architecture refusal now reads as a Windows-version refusal.)
; `x64compatible` matches anything that can RUN x64 binaries, which is what the
; payload actually needs: x64 Windows plus Arm64 Windows 11, where the x64 exe
; and its x64 DLLs run under emulation. Installing in 64-bit mode is right on
; both — an emulated x64 app belongs in the 64-bit {autopf}, not the x86 one.
#if TargetArch == "arm64"
; Native Arm64 build: the exe and every DLL are Arm64 images, which only Arm64
; Windows can run. `arm64` is Inno's identifier for exactly that.
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64
#else
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
#endif
SourceDir={#RepoRoot}
OutputDir=dist
OutputBaseFilename=Control-Center-{#AppVersion}-{#TargetArch}-setup
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName} {#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\{#TargetArch}\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
