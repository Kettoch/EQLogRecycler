; EverQuest Log Recycler - Inno Setup Script
; Creates a professional installer EXE
; Version 1.0.1 - Bug Fix Release

#define MyAppName "EverQuest Log Recycler"
#define MyAppVersion "1.0.1"
#define MyAppVersionType "Bug Fix Release"
#define MyAppPublisher "TRTools"
#define MyAppURL "https://yourwebsite.com"
#define MyAppExeName "EQLogRecycler.ps1"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
AppId={{A3F8B2C1-4D5E-6F7A-8B9C-0D1E2F3A4B5C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\TRTools\EQLogRecycler
DefaultGroupName={#MyAppPublisher}
DisableProgramGroupPage=yes
LicenseFile=
OutputDir=.\Installer
OutputBaseFilename=EQLogRecycler_Setup_v{#MyAppVersion}
SetupIconFile=
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
UninstallDisplayIcon={app}\icon.ico
UninstallDisplayName={#MyAppName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableWelcomePage=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "EQLogRecycler.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\Run.vbs"; Comment: "EverQuest Log Recycler"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\Run.vbs"; Comment: "EverQuest Log Recycler"; Tasks: desktopicon
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\RunHidden.vbs"; Comment: "EverQuest Log Recycler (Auto-start)"; Tasks: startupicon
Name: "{autodesktop}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: checkedonce
Name: "startupicon"; Description: "Start automatically when Windows starts"; GroupDescription: "Startup options:"; Flags: checkedonce
Name: "runnow"; Description: "Configure and run {#MyAppName} now"; GroupDescription: "Launch:"; Flags: checkedonce

[Code]
// Create VBS launcher files during installation
procedure CreateLauncherFiles();
var
  RunVBS: TArrayOfString;
  RunHiddenVBS: TArrayOfString;
  InstallPath: string;
begin
  InstallPath := ExpandConstant('{app}');
  
  // Create Run.vbs for visible execution
  SetArrayLength(RunVBS, 2);
  RunVBS[0] := 'Set objShell = CreateObject("Wscript.Shell")';
  RunVBS[1] := 'objShell.Run "powershell.exe -ExecutionPolicy Bypass -File """ & "' + InstallPath + '\EQLogRecycler.ps1" & """, 1"';
  SaveStringsToFile(InstallPath + '\Run.vbs', RunVBS, False);
  
  // Create RunHidden.vbs for silent execution
  SetArrayLength(RunHiddenVBS, 2);
  RunHiddenVBS[0] := 'Set objShell = CreateObject("Wscript.Shell")';
  RunHiddenVBS[1] := 'objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & "' + InstallPath + '\EQLogRecycler.ps1" & """, 0"';
  SaveStringsToFile(InstallPath + '\RunHidden.vbs', RunHiddenVBS, False);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    CreateLauncherFiles();
  end;
end;

// Launch the application after install if selected
[Run]
Filename: "{app}\Run.vbs"; Description: "Configure and launch {#MyAppName}"; Flags: postinstall nowait skipifsilent; Tasks: runnow

[UninstallDelete]
Type: files; Name: "{app}\Run.vbs"
Type: files; Name: "{app}\RunHidden.vbs"
Type: filesandordirs; Name: "{app}"

[Registry]
; Store installation path for easy access
Root: HKCU; Subkey: "Software\TRTools"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\TRTools\EQLogRecycler"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletevalue

[Messages]
WelcomeLabel2=This will install [name/ver] ({#MyAppVersionType}) on your computer.%n%nThis program automatically recycles your EverQuest log files to keep them small and your game running smoothly.%n%nIt will run quietly in the background with a scroll icon in your system tray.
FinishedHeadingLabel=Installation Complete!
FinishedLabelNoIcons=Setup has finished installing [name] {#MyAppVersion} ({#MyAppVersionType}) on your computer.%n%nLook for the scroll icon in your system tray to configure settings.
FinishedLabel=Setup has finished installing [name] {#MyAppVersion} ({#MyAppVersionType}) on your computer.%n%nDouble-click the desktop shortcut to configure your log files and archive location.

[CustomMessages]
english.AdditionalInfo=After installation:%n• Configure your EverQuest log files%n• Choose an archive folder%n• Set your preferred recycle time%n%nThe program will run automatically in the background.