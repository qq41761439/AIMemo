$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$versionMatch = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(.+)$' | Select-Object -First 1
if (-not $versionMatch) {
  throw 'Cannot find version in pubspec.yaml.'
}

$appVersion = $versionMatch.Matches[0].Groups[1].Value.Trim().Split('+')[0]

flutter config --enable-windows-desktop
flutter pub get
flutter test
flutter build windows --release

$iscc = Get-Command 'iscc.exe' -ErrorAction SilentlyContinue
if (-not $iscc) {
  $defaultIscc = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'
  if (Test-Path $defaultIscc) {
    $iscc = [pscustomobject]@{ Source = $defaultIscc }
  }
}

if (-not $iscc) {
  throw 'Inno Setup 6 was not found. Install it from https://jrsoftware.org/isinfo.php or run: choco install innosetup -y'
}

Push-Location 'installer\windows'
try {
  & $iscc.Source 'aimemo.iss' "/DMyAppVersion=$appVersion"
} finally {
  Pop-Location
}

Write-Host "Windows installer created: dist\windows\AIMemoSetup-$appVersion.exe"
