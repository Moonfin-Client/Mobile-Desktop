$ErrorActionPreference = 'Stop'

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

function Get-NormalizedVersion {
  param([string]$RawVersion)

  if ([string]::IsNullOrWhiteSpace($RawVersion)) {
    throw "Version string is empty."
  }

  $mainPart = ($RawVersion -split '-', 2)[0].Trim()
  $segments = $mainPart -split '\.'
  if ($segments.Count -lt 3) {
    $segments = @($segments + @('0', '0', '0'))[0..2]
  }

  return [Version]::Parse(($segments -join '.'))
}

function Assert-ToolchainVersions {
  param([string]$FlutterExe)

  $minFlutter = [Version]::Parse('3.41.0')
  $minDart = [Version]::Parse('3.11.0')

  $rawOutput = (& $FlutterExe --version --machine | Out-String)
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($rawOutput)) {
    throw "Failed to query Flutter version. Run 'flutter --version' manually and verify your SDK installation."
  }

  # Flutter can emit setup chatter (e.g. "Running pub upgrade...") before JSON.
  # Extract the JSON object from mixed output to avoid ConvertFrom-Json failures.
  $jsonMatch = [regex]::Match($rawOutput, '\{[\s\S]*\}')
  if (-not $jsonMatch.Success) {
    throw "Failed to parse Flutter --version --machine output as JSON. Raw output: $rawOutput"
  }

  $versionInfo = $jsonMatch.Value | ConvertFrom-Json
  $flutterVersion = Get-NormalizedVersion $versionInfo.frameworkVersion
  $dartVersion = Get-NormalizedVersion $versionInfo.dartSdkVersion

  if ($flutterVersion -lt $minFlutter) {
    throw "Flutter SDK $($versionInfo.frameworkVersion) is too old. Required: 3.41.0+ (README requirement)."
  }

  if ($dartVersion -lt $minDart) {
    throw "Dart SDK $($versionInfo.dartSdkVersion) is too old. Required: 3.11.0+ (README requirement)."
  }
}

function Get-VcpkgCommand {
  $candidates = @(
    (Join-Path $repoRoot "vcpkg\vcpkg.exe"),
    "C:\vcpkg\vcpkg.exe"
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) { return $candidate }
  }

  $vcpkgCmd = Get-Command vcpkg -ErrorAction SilentlyContinue
  if ($vcpkgCmd) { return $vcpkgCmd.Source }

  return $null
}

function Initialize-LibarchiveForWindows {
  if (-not [Environment]::OSVersion.Platform.ToString().Contains('Win')) {
    return
  }

  $vcpkgExe = Get-VcpkgCommand
  if (-not $vcpkgExe) {
    $bootstrapRoot = Join-Path $repoRoot "vcpkg"
    $bootstrapScript = Join-Path $bootstrapRoot "bootstrap-vcpkg.bat"

    Write-Host "vcpkg not found. Bootstrapping local copy at $bootstrapRoot..."

    if (-not (Test-Path $bootstrapRoot)) {
      $gitCmd = Get-Command git -ErrorAction SilentlyContinue
      if (-not $gitCmd) {
        throw "git not found. Install Git or install vcpkg manually, then run: vcpkg install libarchive:x64-windows"
      }

      & $gitCmd.Source clone https://github.com/microsoft/vcpkg $bootstrapRoot
      if ($LASTEXITCODE -ne 0) {
        throw "Failed to clone vcpkg repository."
      }
    }

    if (-not (Test-Path $bootstrapScript)) {
      throw "vcpkg bootstrap script not found at $bootstrapScript"
    }

    & $bootstrapScript
    if ($LASTEXITCODE -ne 0) {
      throw "vcpkg bootstrap failed with exit code $LASTEXITCODE"
    }

    $vcpkgExe = Join-Path $bootstrapRoot "vcpkg.exe"
    if (-not (Test-Path $vcpkgExe)) {
      throw "vcpkg executable not found after bootstrap: $vcpkgExe"
    }
  }

  $vcpkgRoot = Split-Path -Parent $vcpkgExe
  $libarchiveHeader = Join-Path $vcpkgRoot "installed\x64-windows\include\archive.h"
  $libarchiveLib = Join-Path $vcpkgRoot "installed\x64-windows\lib\archive.lib"

  if (-not (Test-Path $libarchiveHeader) -or -not (Test-Path $libarchiveLib)) {
    Write-Host "Installing libarchive:x64-windows via vcpkg..."
    & $vcpkgExe install libarchive:x64-windows
    if ($LASTEXITCODE -ne 0) {
      throw "vcpkg install libarchive:x64-windows failed with exit code $LASTEXITCODE"
    }
  }

  $env:VCPKG_ROOT = $vcpkgRoot
}

function Copy-VcpkgRuntimeDlls {
  param(
    [string]$VcpkgRoot,
    [string]$ReleaseDir
  )

  if ([string]::IsNullOrWhiteSpace($VcpkgRoot) -or -not (Test-Path $VcpkgRoot)) {
    return
  }

  $binDir = Join-Path $VcpkgRoot "installed\x64-windows\bin"
  if (-not (Test-Path $binDir)) {
    return
  }

  $dlls = Get-ChildItem -Path $binDir -Filter *.dll -File -ErrorAction SilentlyContinue
  if (-not $dlls) {
    return
  }

  foreach ($dll in $dlls) {
    Copy-Item -Path $dll.FullName -Destination (Join-Path $ReleaseDir $dll.Name) -Force
  }
}

function Get-AppVersion {
  $pubspecPath = Join-Path $repoRoot "pubspec.yaml"
  if (-not (Test-Path $pubspecPath)) {
    throw "pubspec.yaml not found at $pubspecPath"
  }

  $versionLine = Select-String -Path $pubspecPath -Pattern '^version\s*:\s*' | Select-Object -First 1 -ExpandProperty Line
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

function Invoke-CheckedCommand {
  param(
    [string]$Name,
    [string]$FilePath,
    [string[]]$Arguments = @()
  )

  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$Name failed with exit code $LASTEXITCODE"
  }
}

function New-InnoScript {
  param(
    [string]$AppVersion,
    [string]$InstallerBaseName,
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
DefaultDirName={autopf}\Moonfin
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=$OutputDir
OutputBaseFilename=$InstallerBaseName
SetupIconFile=$IconPath
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
UsePreviousPrivileges=yes
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
$installerBaseName = "Moonfin_Windows_v$appVersion"

Push-Location $repoRoot
try {
  Write-Host "Moonfin version: $appVersion"

  Assert-ToolchainVersions -FlutterExe $flutterExe

  Initialize-LibarchiveForWindows

  Write-Host "Cleaning previous Flutter outputs..."
  Invoke-CheckedCommand -Name "flutter clean" -FilePath $flutterExe -Arguments @("clean")

  Write-Host "Resolving Dart and Flutter packages..."
  Invoke-CheckedCommand -Name "flutter pub get" -FilePath $flutterExe -Arguments @("pub", "get")

  Write-Host "Building Windows x64 release..."
  Invoke-CheckedCommand -Name "flutter build windows" -FilePath $flutterExe -Arguments @("build", "windows", "--release")

  $releaseDir = Join-Path $repoRoot "build\windows\x64\runner\Release"
  $releaseExe = Join-Path $releaseDir "moonfin.exe"
  if (-not (Test-Path $releaseExe)) {
    throw "Missing release binary: $releaseExe"
  }

  Copy-VcpkgRuntimeDlls -VcpkgRoot $env:VCPKG_ROOT -ReleaseDir $releaseDir

  $outputDir = Join-Path $repoRoot "build\windows\installer"
  $iconPath = Join-Path $repoRoot "windows\runner\resources\app_icon.ico"
  $issPath = Join-Path $outputDir "moonfin.generated.iss"
  $outputExe = Join-Path $outputDir "$installerBaseName.exe"
  $rootExe = Join-Path $repoRoot "$installerBaseName.exe"

  New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

  if (-not (Test-Path $iconPath)) {
    throw "Missing app icon: $iconPath"
  }

  New-InnoScript -AppVersion $appVersion -InstallerBaseName $installerBaseName -OutputDir $outputDir -IconPath $iconPath -ReleaseDir $releaseDir -IssPath $issPath

  Write-Host "Building installer EXE..."
  Invoke-CheckedCommand -Name "ISCC" -FilePath $isccExe -Arguments @($issPath)

  if (-not (Test-Path $outputExe)) {
    throw "Installer not found at expected path: $outputExe"
  }

  Copy-Item -Path $outputExe -Destination $rootExe -Force

  Write-Host "Installer created:" $outputExe
  Write-Host "Installer copied to root:" $rootExe
}
finally {
  Pop-Location
}