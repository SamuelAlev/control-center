; Inno Setup script for Control Center (Windows).
;
; Compiled by .github/workflows/release.yml:
;   ISCC.exe /DAppVersion=<version> windows/installer/control_center.iss
;
; Packages the entire `flutter build windows --release` output (the exe, the
; Flutter runtime DLLs, the bundled native FFI DLLs, and the data/ folder) into
; a per-user installer with Start-menu + optional desktop shortcuts and an
; uninstaller. The installer is unsigned unless WINDOWS_CERT is configured, so
; first-run shows a SmartScreen warning (More info -> Run anyway).

#ifndef AppVersion
  #define AppVersion "0.0.0"
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
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
SourceDir={#RepoRoot}
OutputDir=dist
OutputBaseFilename=Control-Center-{#AppVersion}-x64-setup
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
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
