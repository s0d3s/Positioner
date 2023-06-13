; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

;#define PositionerAppName "My Program"
;#define PositionerVersion "1.5"
;#define PositionerAuthor "My Company, Inc."
;#define PositionerAppURL "https://www.example.com/"
;#define PositionerExeName "Positioner.exe"
;#define PositionerInstallerName "positioner_installer"
;#define PositionerOutputDir "installer_build"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{A1C4CE5B-D130-4E81-ADBC-A9A121ECD924}
AppName={#PositionerAppName}
AppVersion={#PositionerVersion}
;AppVerName={#PositionerAppName} {#PositionerVersion}
AppPublisher={#PositionerAuthor}
AppPublisherURL={#PositionerAppURL}
AppSupportURL={#PositionerAppURL}
AppUpdatesURL={#PositionerAppURL}
DefaultDirName={autopf}\{#PositionerAppName}
DisableProgramGroupPage=yes
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputDir={#PositionerOutputDir}
OutputBaseFilename={#PositionerInstallerName}
SetupIconFile=src\positioner_ui\assets\favicon_positioner.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

[Dirs]
Name: {app}\configs; Permissions: everyone-modify;
Name: {app}\logs; Permissions: everyone-modify;

;[Registry]
;Root: "HKLM"; Subkey: "SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"; \
;    ValueType: String; ValueName: "{app}\{#PositionerExeName}"; ValueData: "RUNASADMIN"; \
;    Flags: uninsdeletekeyifempty uninsdeletevalue; MinVersion: 0,6.1

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\exe\{#PositionerExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\exe\python*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\exe\*.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\exe\lib\*"; DestDir: "{app}\lib"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "build\exe\src\*"; DestDir: "{app}\src"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#PositionerAppName}"; Filename: "{app}\{#PositionerExeName}"
Name: "{autodesktop}\{#PositionerAppName}"; Filename: "{app}\{#PositionerExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#PositionerExeName}"; Description: "{cm:LaunchProgram,{#StringChange(PositionerAppName, '&', '&&')}}"; Flags: runascurrentuser nowait postinstall skipifsilent

