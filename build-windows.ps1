$ErrorActionPreference = 'Continue'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-IsccPath {
  $candidates = @(
    "C:\Users\$env:USERNAME\AppData\Local\Programs\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) { return $candidate }
  }

  $regPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1"
  )

  foreach ($regPath in $regPaths) {
    if (Test-Path $regPath) {
      $appPath = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue)."Inno Setup: App Path"
      if ($appPath) {
        $iscc = Join-Path $appPath "ISCC.exe"
        if (Test-Path $iscc) { return $iscc }
      }
    }
  }

  throw "ISCC.exe not found. Install Inno Setup 6 first."
}

function Get-FlutterCommand {
  $candidate = "C:\flutter\bin\flutter.bat"
  if (Test-Path $candidate) { return $candidate }

  $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($flutterCmd) { return $flutterCmd.Source }

  throw "Flutter not found. Install Flutter or add it to PATH."
}

function Get-AppVersion {
  $pubspecPath = Join-Path $repoRoot "pubspec.yaml"
  if (-not (Test-Path $pubspecPath)) {
    throw "pubspec.yaml not found at $pubspecPath"
  }

  $versionLine = Get-Content $pubspecPath | Where-Object { $_ -match '^version\s*:\s*' } | Select-Object -First 1
  if (-not $versionLine) {
    throw "Could not find version in pubspec.yaml"
  }

  $fullVersion = ($versionLine -split ':', 2)[1].Trim()
  $appVersion = ($fullVersion -split '\+', 2)[0].Trim()
  if ([string]::IsNullOrWhiteSpace($appVersion)) {
    throw "Invalid version value in pubspec.yaml: $fullVersion"
  }

  return $appVersion
}

function New-InnoScript {
  param(
    [string]$AppVersion,
    [string]$OutputDir,
    [string]$IconPath,
    [string]$ReleaseDir,
    [string]$IssPath
  )

  $iss = @"
#define MyAppName "Moonfin"
#define MyAppVersion "$AppVersion"
#define MyAppPublisher "Moonfin"
#define MyAppExeName "moonfin.exe"

[Setup]
AppId={{2B684544-2B56-47BE-B52F-6F7A94BCA4E1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Moonfin
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=$OutputDir
OutputBaseFilename=Moonfin-Setup-x64
SetupIconFile=$IconPath
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "$ReleaseDir\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
"@

  Set-Content -Path $IssPath -Value $iss -Encoding UTF8
}

$flutterExe = Get-FlutterCommand
$isccExe = Get-IsccPath
$appVersion = Get-AppVersion

Push-Location $repoRoot
try {
  Write-Host "Moonfin version: $appVersion"

  Write-Host "Cleaning previous Flutter outputs..."
  & $flutterExe clean
  if ($LASTEXITCODE -ne 0) {
    throw "flutter clean failed with exit code $LASTEXITCODE"
  }

  Write-Host "Resolving Dart and Flutter packages..."
  & $flutterExe pub get
  if ($LASTEXITCODE -ne 0) {
    throw "flutter pub get failed with exit code $LASTEXITCODE"
  }

  Write-Host "Building Windows x64 release..."
  & $flutterExe build windows --release
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows failed with exit code $LASTEXITCODE"
  }

  $releaseDir = Join-Path $repoRoot "build\windows\x64\runner\Release"
  $releaseExe = Join-Path $releaseDir "moonfin.exe"
  if (-not (Test-Path $releaseExe)) {
    throw "Missing release binary: $releaseExe"
  }

  $outputDir = Join-Path $repoRoot "build\windows\installer"
  $iconPath = Join-Path $repoRoot "windows\runner\resources\app_icon.ico"
  $issPath = Join-Path $outputDir "moonfin.generated.iss"
  $outputExe = Join-Path $outputDir "Moonfin-Setup-x64.exe"
  $rootExe = Join-Path $repoRoot "Moonfin-Setup-x64.exe"

  New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

  if (-not (Test-Path $iconPath)) {
    throw "Missing app icon: $iconPath"
  }

  New-InnoScript -AppVersion $appVersion -OutputDir $outputDir -IconPath $iconPath -ReleaseDir $releaseDir -IssPath $issPath

  Write-Host "Building installer EXE..."
  & $isccExe $issPath
  if ($LASTEXITCODE -ne 0) {
    throw "ISCC failed with exit code $LASTEXITCODE"
  }

  if (-not (Test-Path $outputExe)) {
    throw "Installer not found at expected path: $outputExe"
  }

  Copy-Item -Path $outputExe -Destination $rootExe -Force

  Write-Host ""
  Write-Host "Installer created:" $outputExe
  Write-Host "Installer copied to root:" $rootExe
}
finally {
  Pop-Location
}