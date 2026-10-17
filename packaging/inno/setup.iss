#ifndef MyAppVersion
  #define MyAppVersion "0.1.0"
#endif
#ifndef StageDir
  #define StageDir "..\installer-stage"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif

#define MyAppName "随密 Slint"
#define MyAppExeName "随密-Slint.exe"
#define MyAppPublisher "swqztech"

[Setup]
AppId={{EC5D5016-D7DD-4B36-8373-31211048DB40}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppSupportURL=https://github.com/swqztech/suimi-slint
DefaultDirName={localappdata}\{#MyAppName}
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename=随密-Slint-{#MyAppVersion}-win64-setup
Compression=lzma2
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加选项:"; Flags: unchecked

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "运行"; Flags: nowait postinstall skipifsilent
