$ErrorActionPreference = 'Stop'
$candidates = @(
  (Join-Path $env:LOCALAPPDATA 'Programs\Godot\Godot_v4.7.2-stable_win64_console.exe'),
  (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe')
)
$godot = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $godot) {
  Write-Host 'Godot not found, installing.'
  & (Join-Path $PSScriptRoot 'get-godot.ps1')
  $godot = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $godot) {
  Write-Host 'UFA_EXE_FAIL no editor'
  exit 1
}
$root = Split-Path -Parent $PSScriptRoot
$project = Join-Path $root 'godot'
$release = Join-Path $root 'release'
New-Item -ItemType Directory -Force -Path $release | Out-Null
# Godot не переименовывает PCK, если в пути есть кириллица. Собираем в ASCII-папку.
$stage = Join-Path $env:LOCALAPPDATA 'Temp\UfaTransit'
New-Item -ItemType Directory -Force -Path $stage | Out-Null
$staged = Join-Path $stage 'UfaTransit.exe'
$out = Join-Path $release 'UfaTransit.exe'
if (Test-Path $staged) { Remove-Item $staged -Force }
$ErrorActionPreference = 'Continue'
& $godot --path $project --headless --export-release "Windows Desktop" $staged
if (-not (Test-Path $staged)) {
  Write-Host 'UFA_EXE_FAIL'
  exit 1
}
try {
  Copy-Item $staged $out -Force
} catch {
  $out = Join-Path $release 'UfaTransit-new.exe'
  Copy-Item $staged $out -Force
}
$mb = [math]::Round((Get-Item $out).Length / 1MB, 1)
Write-Host "UFA_EXE_OK $out ($mb MB)"
